#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
team_file="${repo_root}/TEAM.md"
yo_file="${repo_root}/commands/yo.md"
discuss_file="${repo_root}/commands/discuss.md"
adapter_file="${repo_root}/ADAPTER.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_contains() {
  local file="$1"
  local expected="$2"

  if ! grep -qF "${expected}" "${file}"; then
    fail "${file#${repo_root}/} must contain: ${expected}"
  fi
}

[[ -f "${team_file}" ]] || fail "TEAM.md must exist"
[[ -f "${yo_file}" ]] || fail "commands/yo.md must exist"
[[ -f "${discuss_file}" ]] || fail "commands/discuss.md must exist"
[[ -f "${adapter_file}" ]] || fail "ADAPTER.md must exist"

assert_file_contains "${team_file}" "| Agent | File | Role | Model Class |"
assert_file_contains "${team_file}" "| Agent | File | Skills | Model Class |"
assert_file_contains "${adapter_file}" "## Model Classes"
assert_file_contains "${team_file}" "Model classes are defined in \`ADAPTER.md\`."
assert_file_contains "${team_file}" "| balanced |"
assert_file_contains "${team_file}" "| build |"
assert_file_contains "${team_file}" "| deep-reasoning |"
assert_file_contains "${adapter_file}" "| balanced |"
assert_file_contains "${adapter_file}" "| build |"
assert_file_contains "${adapter_file}" "| deep-reasoning |"

python3 - "${team_file}" "${adapter_file}" "${repo_root}" <<'PY'
import re
import sys
from pathlib import Path

team_file = Path(sys.argv[1])
adapter_file = Path(sys.argv[2])
repo_root = Path(sys.argv[3])

# `\|` is the markdown escape for a literal pipe inside a table cell, so it is not a
# column separator. Split on unescaped pipes only, then unescape — downstream code
# treats these cells as human-readable text.
CELL_SEPARATOR = re.compile(r"(?<!\\)\|")


def split_cells(line):
    cells = CELL_SEPARATOR.split(line.strip())
    # A well-formed row yields an empty cell before the leading and after the trailing pipe.
    if cells and not cells[0].strip():
        cells = cells[1:]
    if cells and not cells[-1].strip():
        cells = cells[:-1]
    return [cell.replace("\\|", "|").strip() for cell in cells]


adapter_classes = set()
# Model Classes table columns: | Model Class | Intent | Claude Code | Codex |.
# Column 2 is the backticked Claude Code model a class resolves to. Nothing on disk
# is derived from it any more — agents/*.md declares no model (asserted below) — so
# this cell is what the orchestrator resolves and passes at spawn time per
# ADAPTER.md's Agent Spawning step 4. An unparseable or duplicated cell is therefore
# a live routing defect, not just stale documentation.
adapter_class_models = {}
adapter_class_model_lines = {}
for lineno, line in enumerate(adapter_file.read_text().splitlines(), start=1):
    if not line.startswith("|"):
        continue
    cols = split_cells(line)
    if len(cols) >= 1 and re.fullmatch(r"[a-z][a-z-]+", cols[0]):
        adapter_classes.add(cols[0])
        if len(cols) >= 3:
            claude_model = re.fullmatch(r"`([a-z][a-z0-9.\-]*)`", cols[2])
            if claude_model:
                # Assigning without checking would let a duplicate class row resolve
                # last-write-wins, silently picking one of two models with no signal.
                if cols[0] in adapter_class_models:
                    raise SystemExit(
                        f"FAIL: ADAPTER.md declares model class '{cols[0]}' more than once "
                        f"(ADAPTER.md:{adapter_class_model_lines[cols[0]]} -> "
                        f"{adapter_class_models[cols[0]]}, ADAPTER.md:{lineno} -> "
                        f"{claude_model.group(1)}); each class must resolve to exactly one "
                        "Claude Code model"
                    )
                adapter_class_models[cols[0]] = claude_model.group(1)
                adapter_class_model_lines[cols[0]] = lineno

required = {"balanced", "deep-reasoning", "build"}
if not required.issubset(adapter_classes):
    missing = ", ".join(sorted(required - adapter_classes))
    raise SystemExit(f"FAIL: ADAPTER.md missing model classes: {missing}")

missing_models = sorted(required - set(adapter_class_models))
if missing_models:
    raise SystemExit(
        "FAIL: ADAPTER.md Model Classes table must give a backticked Claude Code model "
        f"for every class; missing for: {', '.join(missing_models)}"
    )

validated_rows = 0
# An agent may hold more than one roster row (observability-engineer and
# security-engineer each appear under Specialists and again under Reviewers), so
# collect rows per file and reconcile once rather than per row.
rows_by_agent_file = {}
for lineno, line in enumerate(team_file.read_text().splitlines(), start=1):
    if not line.startswith("|") or "agents/" not in line:
        continue

    cols = split_cells(line)
    if len(cols) != 4:
        raise SystemExit(f"FAIL: TEAM.md:{lineno} roster row must have 4 columns: {line}")

    agent, file_col, _role_or_skills, model_class = cols
    if not agent:
        raise SystemExit(f"FAIL: TEAM.md:{lineno} roster row missing agent name: {line}")
    if not re.fullmatch(r"`agents/[^`]+\.md`", file_col):
        raise SystemExit(f"FAIL: TEAM.md:{lineno} file column must be a backticked agents/*.md path: {line}")
    if model_class not in adapter_classes:
        raise SystemExit(
            f"FAIL: TEAM.md:{lineno} roster row must use a provider-neutral model class, got '{model_class}': {line}"
        )
    validated_rows += 1
    rows_by_agent_file.setdefault(file_col.strip("`"), []).append((lineno, model_class))

if validated_rows == 0:
    raise SystemExit("FAIL: TEAM.md must contain at least one validated agent roster row")

# Per-agent-file checks. Row-agreement is asserted first and separately: if two rows
# for one agent ever disagree, the defect is in TEAM.md, and blaming the agent file
# for whichever row lost would point the reader at the wrong file.
#
# The model itself is NOT compared against the agent file, because agent files must
# not declare one. Model selection happens at spawn time (ADAPTER.md, Agent Spawning
# step 4): the orchestrator resolves the TEAM.md class through the Model Classes
# table and passes the result on the spawn. So the assertions here are:
#   1. every agent's TEAM.md class resolves to a real, parseable model, and
#   2. no agent file declares `model:` at all.
# A re-added `model:` would override the spawn parameter on Claude Code and put the
# role back on a model nothing coordinates — hence a hard failure, not a warning.
#
# The forbid-check deliberately matches the KEY and ignores the VALUE. Matching values
# ('model: opus') would let any malformed or quoted variant slip through and produce a
# misleading blame message; keying on `model:` alone cannot be evaded that way. The key
# itself may be quoted — '"model": opus' is legal YAML — so optional quotes match too.
MODEL_KEY = re.compile(r"""^\s*["']?model["']?\s*:""", re.IGNORECASE)

for rel_path, rows in sorted(rows_by_agent_file.items()):
    classes = {model_class for _, model_class in rows}
    if len(classes) != 1:
        locations = ", ".join(f"TEAM.md:{lineno} -> {cls}" for lineno, cls in rows)
        raise SystemExit(
            f"FAIL: TEAM.md rows for {rel_path} disagree on model class ({locations}); "
            "every roster row for one agent file must name the same class"
        )

    model_class = classes.pop()
    if model_class not in adapter_class_models:
        raise SystemExit(
            f"FAIL: model class '{model_class}' ({rel_path}) has no backticked Claude Code "
            "model in ADAPTER.md's Model Classes table"
        )

    agent_path = repo_root / rel_path
    if not agent_path.is_file():
        raise SystemExit(f"FAIL: TEAM.md references a missing agent file: {rel_path}")

# Assertion 2 — the forbid-check. This globs agents/*.md directly rather than
# reusing the roster-derived paths above: a file mentioned only in TEAM.md prose,
# or not mentioned at all, is still checked. Coverage rests on the filesystem
# alone and needs no chain through agent-inventory.test.sh's mention semantics.
roster_classes = {path: rows[0][1] for path, rows in rows_by_agent_file.items()}
agent_files_on_disk = sorted((repo_root / "agents").glob("*.md"))
if not agent_files_on_disk:
    raise SystemExit(
        "FAIL: agents/ yielded no agent files to verify are free of `model:` declarations"
    )

for agent_path in agent_files_on_disk:
    rel_path = agent_path.relative_to(repo_root).as_posix()
    model_class = roster_classes.get(rel_path)
    class_note = f"its TEAM.md class ('{model_class}')" if model_class else "its TEAM.md class"
    for lineno, agent_line in enumerate(agent_path.read_text().splitlines(), start=1):
        if MODEL_KEY.match(agent_line):
            raise SystemExit(
                f"FAIL: {rel_path}:{lineno} declares a model ({agent_line.strip()!r}); "
                "agent files must declare no `model:` at all. The role's model comes from "
                f"{class_note} resolved through ADAPTER.md and passed "
                "on the spawn — see ADAPTER.md, Agent Spawning step 4. A `model:` here "
                "overrides that spawn parameter and silently wins."
            )
PY

# Provider-neutrality applies to every command that talks about models. discuss.md
# is where the spawn blocks live; yo.md stays on the list as cheap insurance against
# provider names creeping back into the front door.
for command_file in "${yo_file}" "${discuss_file}"; do
  if grep -qE 'model: (sonnet|opus|haiku|fable|gpt)' "${command_file}"; then
    fail "${command_file#${repo_root}/} must route by provider-neutral model class, not provider-specific model names"
  fi
done

# Model-class routing itself is asserted against discuss.md: it owns the PM/TL/DE
# spawns. yo.md triages and routes only — it spawns nothing and names no model class.
assert_file_contains "${discuss_file}" "model class: balanced"
assert_file_contains "${discuss_file}" "model class: deep-reasoning"

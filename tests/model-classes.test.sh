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
assert_file_contains "${team_file}" "| deep-reasoning |"
assert_file_contains "${adapter_file}" "| balanced |"
assert_file_contains "${adapter_file}" "| deep-reasoning |"

python3 - "${team_file}" "${adapter_file}" <<'PY'
import re
import sys
from pathlib import Path

team_file = Path(sys.argv[1])
adapter_file = Path(sys.argv[2])

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
for line in adapter_file.read_text().splitlines():
    if not line.startswith("|"):
        continue
    cols = split_cells(line)
    if len(cols) >= 1 and re.fullmatch(r"[a-z][a-z-]+", cols[0]):
        adapter_classes.add(cols[0])

required = {"balanced", "deep-reasoning"}
if not required.issubset(adapter_classes):
    missing = ", ".join(sorted(required - adapter_classes))
    raise SystemExit(f"FAIL: ADAPTER.md missing model classes: {missing}")

validated_rows = 0
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

if validated_rows == 0:
    raise SystemExit("FAIL: TEAM.md must contain at least one validated agent roster row")
PY

# Provider-neutrality applies to every command that talks about models. discuss.md
# is where the spawn blocks live; yo.md stays on the list as cheap insurance against
# provider names creeping back into the front door.
for command_file in "${yo_file}" "${discuss_file}"; do
  if grep -qE 'model: (sonnet|opus|haiku|gpt)' "${command_file}"; then
    fail "${command_file#${repo_root}/} must route by provider-neutral model class, not provider-specific model names"
  fi
done

# Model-class routing itself is asserted against discuss.md: it owns the PM/TL/DE
# spawns. yo.md triages and routes only — it spawns nothing and names no model class.
assert_file_contains "${discuss_file}" "model class: balanced"
assert_file_contains "${discuss_file}" "model class: deep-reasoning"

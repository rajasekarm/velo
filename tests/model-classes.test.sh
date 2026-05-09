#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
team_file="${repo_root}/TEAM.md"
yo_file="${repo_root}/commands/yo.md"
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
[[ -f "${adapter_file}" ]] || fail "ADAPTER.md must exist"

assert_file_contains "${team_file}" "| Agent | File | Role | Model Class |"
assert_file_contains "${team_file}" "| Agent | File | Skills | Model Class |"
assert_file_contains "${adapter_file}" "## Model Classes"
assert_file_contains "${team_file}" "Model classes are defined in \`ADAPTER.md\`."
assert_file_contains "${team_file}" "| balanced |"
assert_file_contains "${team_file}" "| deep-reasoning |"
assert_file_contains "${team_file}" "| external-review |"
assert_file_contains "${adapter_file}" "| balanced |"
assert_file_contains "${adapter_file}" "| deep-reasoning |"
assert_file_contains "${adapter_file}" "| external-review |"

python3 - "${team_file}" "${adapter_file}" <<'PY'
import re
import sys
from pathlib import Path

team_file = Path(sys.argv[1])
adapter_file = Path(sys.argv[2])

adapter_classes = set()
for line in adapter_file.read_text().splitlines():
    if not line.startswith("|"):
        continue
    cols = [part.strip() for part in line.strip().strip("|").split("|")]
    if len(cols) >= 1 and re.fullmatch(r"[a-z][a-z-]+", cols[0]):
        adapter_classes.add(cols[0])

required = {"balanced", "deep-reasoning", "external-review"}
if not required.issubset(adapter_classes):
    missing = ", ".join(sorted(required - adapter_classes))
    raise SystemExit(f"FAIL: ADAPTER.md missing model classes: {missing}")

validated_rows = 0
for lineno, line in enumerate(team_file.read_text().splitlines(), start=1):
    if not line.startswith("|") or "agents/" not in line:
        continue

    cols = [part.strip() for part in line.strip().strip("|").split("|")]
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

if grep -qE 'model: (sonnet|opus|haiku|gpt)' "${yo_file}"; then
  fail "commands/yo.md must route by provider-neutral model class, not provider-specific model names"
fi

assert_file_contains "${yo_file}" "model class: balanced"
assert_file_contains "${yo_file}" "model class: deep-reasoning"

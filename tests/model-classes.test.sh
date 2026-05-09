#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
team_file="${repo_root}/TEAM.md"
yo_file="${repo_root}/commands/yo.md"

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

assert_file_contains "${team_file}" "| Agent | File | Role | Model Class |"
assert_file_contains "${team_file}" "| Agent | File | Skills | Model Class |"
assert_file_contains "${team_file}" "## Model Classes"
assert_file_contains "${team_file}" "| balanced |"
assert_file_contains "${team_file}" "| deep-reasoning |"
assert_file_contains "${team_file}" "| external-review |"

while IFS= read -r row; do
  model_class="$(awk -F'|' '{ value=$(NF-1); gsub(/^[[:space:]]+|[[:space:]]+$/, "", value); print value }' <<< "${row}")"

  case "${model_class}" in
    balanced|deep-reasoning|external-review) ;;
    *)
      fail "TEAM.md roster row must use a provider-neutral model class, got '${model_class}' in: ${row}"
      ;;
  esac
done < <(grep -E '\| \*\*[^|]+\*\* \| `agents/[^`]+\.md` \|' "${team_file}")

if grep -qE 'model: (sonnet|opus|haiku|gpt)' "${yo_file}"; then
  fail "commands/yo.md must route by provider-neutral model class, not provider-specific model names"
fi

assert_file_contains "${yo_file}" "model class: balanced"
assert_file_contains "${yo_file}" "model class: deep-reasoning"

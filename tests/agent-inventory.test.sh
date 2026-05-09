#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
team_file="${repo_root}/TEAM.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "${team_file}" ]] || fail "TEAM.md must exist"

while IFS= read -r agent_file; do
  agent_rel="${agent_file#${repo_root}/}"

  if ! grep -qF "\`${agent_rel}\`" "${team_file}"; then
    fail "${agent_rel} must be listed in TEAM.md"
  fi
done < <(find "${repo_root}/agents" -name '*.md' | sort)

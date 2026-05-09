#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin_file="${repo_root}/.codex-plugin/plugin.json"

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

[[ -f "${plugin_file}" ]] || fail ".codex-plugin/plugin.json must exist for the local Codex plugin"

python3 -m json.tool "${plugin_file}" >/dev/null

assert_file_contains "${plugin_file}" '"name": "velo"'
assert_file_contains "${plugin_file}" '"skills": "./.agents/skills/"'
assert_file_contains "${plugin_file}" '"displayName": "Velo"'
assert_file_contains "${plugin_file}" '"shortDescription": "Agentic engineering team workflow for Codex"'

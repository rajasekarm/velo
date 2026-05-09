#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
agents_file="${repo_root}/AGENTS.md"

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

[[ -f "${agents_file}" ]] || fail "AGENTS.md must exist as the Codex-native repo entrypoint"

assert_file_contains "${agents_file}" "AGENTS.md is the Codex-native entrypoint for this repo."
assert_file_contains "${agents_file}" "Keep the existing Claude assets intact."
assert_file_contains "${agents_file}" "Treat .agents/skills/velo/SKILL.md as the general Codex-discoverable wrapper for the Velo workflow."
assert_file_contains "${agents_file}" 'Treat `.agents/skills/velo-{new,task,yo,hunt}/SKILL.md` as path-specific Codex wrapper files whose skill names expose `velo:new`, `velo:task`, `velo:yo`, and `velo:hunt`.'
assert_file_contains "${agents_file}" "Treat commands/*.md as workflow playbooks, not automatic Codex slash commands."
assert_file_contains "${agents_file}" "Use Codex slash commands for session control only."
assert_file_contains "${agents_file}" "Do not commit or push without explicit per-action approval."

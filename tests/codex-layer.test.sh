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
assert_file_contains "${agents_file}" "Keep Claude compatibility explicit through \`ADAPTER.md\`"
assert_file_contains "${agents_file}" "Treat \`ADAPTER.md\` as the runtime compatibility contract"
assert_file_contains "${agents_file}" "Treat \`TEAM.md\` model classes as provider-neutral routing intent;"
assert_file_contains "${agents_file}" "Treat \`agents/*.md\` as carrying no model routing information:"
assert_file_contains "${agents_file}" 'Do not add a generic `.agents/skills/velo/SKILL.md`; the visible Codex command surface is mode-only.'
# The wrapper sentence — `.agents/skills/velo-{...}/SKILL.md` and the `velo:<mode>`
# names it exposes — is deliberately NOT pinned here as a literal. A hand-copied
# copy of the mode set is a fourth place for it to drift, and pinning the whole
# sentence locks editorial prose that carries no invariant. Ownership of that
# assertion lives in tests/codex-wrapper-parity.test.sh, which derives the
# expected mode set from .agents/skills/ and compares it as an unordered set.
assert_file_contains "${agents_file}" 'Treat `.codex-plugin/plugin.json` as the local Codex plugin manifest.'
assert_file_contains "${agents_file}" "Treat commands/*.md as workflow playbooks, not automatic Codex slash commands."
assert_file_contains "${agents_file}" "Use Codex slash commands for session control only."
assert_file_contains "${agents_file}" "Do not commit or push without explicit per-action approval."

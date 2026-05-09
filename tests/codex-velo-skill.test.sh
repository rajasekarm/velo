#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skill_file="${repo_root}/.agents/skills/velo/SKILL.md"

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

[[ -f "${skill_file}" ]] || fail ".agents/skills/velo/SKILL.md must exist so Codex can expose Velo as a repo skill"

assert_file_contains "${skill_file}" "name: velo"
assert_file_contains "${skill_file}" "description: Use when the user asks for Velo"
assert_file_contains "${skill_file}" "Load AGENTS.md first."
assert_file_contains "${skill_file}" "Treat commands/*.md as playbooks"
assert_file_contains "${skill_file}" "Do not implement directly when the Velo workflow requires delegation or review gates."

assert_wrapper_skill() {
  local skill_dir="$1"
  local skill_name="$2"
  local playbook="$3"
  local trigger="$4"
  local wrapper_file="${repo_root}/.agents/skills/${skill_dir}/SKILL.md"

  [[ -f "${wrapper_file}" ]] || fail ".agents/skills/${skill_dir}/SKILL.md must exist so Codex can expose velo:${skill_name}"

  assert_file_contains "${wrapper_file}" "name: ${skill_name}"
  assert_file_contains "${wrapper_file}" "description: ${trigger}"
  assert_file_contains "${wrapper_file}" "Load AGENTS.md first."
  assert_file_contains "${wrapper_file}" "Read \`${playbook}\`"
  assert_file_contains "${wrapper_file}" "Treat this as a Codex wrapper around the existing Velo playbook."
  assert_file_contains "${wrapper_file}" "Do not treat this wrapper as an automatic Codex slash command."
}

assert_wrapper_skill "velo-new" "new" "commands/new.md" "Use when the user asks for /velo:new"
assert_wrapper_skill "velo-task" "task" "commands/task.md" "Use when the user asks for /velo:task"
assert_wrapper_skill "velo-yo" "yo" "commands/yo.md" "Use when the user asks for /velo:yo"
assert_wrapper_skill "velo-hunt" "hunt" "commands/hunt.md" "Use when the user asks for /velo:hunt"

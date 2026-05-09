#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
generic_skill_file="${repo_root}/.agents/skills/velo/SKILL.md"

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

assert_order() {
  local file="$1"
  local first="$2"
  local second="$3"
  local first_line
  local second_line

  first_line="$(grep -nF "${first}" "${file}" | head -1 | cut -d: -f1)"
  second_line="$(grep -nF "${second}" "${file}" | head -1 | cut -d: -f1)"

  [[ -n "${first_line}" ]] || fail "${file#${repo_root}/} must contain: ${first}"
  [[ -n "${second_line}" ]] || fail "${file#${repo_root}/} must contain: ${second}"
  if (( first_line >= second_line )); then
    fail "${file#${repo_root}/} must load '${first}' before '${second}'"
  fi
}

if [[ -e "${generic_skill_file}" ]]; then
  fail ".agents/skills/velo/SKILL.md must not exist; generic Velo should stay hidden from slash commands"
fi

assert_wrapper_skill() {
  local skill_dir="$1"
  local skill_name="$2"
  local playbook="$3"
  local trigger="$4"
  local wrapper_file="${repo_root}/.agents/skills/${skill_dir}/SKILL.md"

  [[ -f "${wrapper_file}" ]] || fail ".agents/skills/${skill_dir}/SKILL.md must exist so Codex can expose velo:${skill_name}"

  assert_file_contains "${wrapper_file}" "name: ${skill_name}"
  assert_file_contains "${wrapper_file}" "description: ${trigger}"
  assert_file_contains "${wrapper_file}" 'Velo workflow root: resolve by walking up from this `SKILL.md`'
  assert_file_contains "${wrapper_file}" "Load AGENTS.md first."
  assert_file_contains "${wrapper_file}" "Read \`ADAPTER.md\`"
  assert_file_contains "${wrapper_file}" "Read \`${playbook}\`"
  assert_order "${wrapper_file}" "Load AGENTS.md first." "Read \`ADAPTER.md\`"
  assert_order "${wrapper_file}" "Read \`ADAPTER.md\`" "Read \`${playbook}\`"
  assert_file_contains "${wrapper_file}" "Treat this as a Codex wrapper around the existing Velo playbook."
  assert_file_contains "${wrapper_file}" "Do not treat this wrapper as an automatic Codex slash command."

  if grep -qE 'AskUserQuestion|ToolSearch|TodoWrite|Agent tool|request_user_input|update_plan|tool_search|spawn_agent|Codex CLI|codex exec|sonnet|opus|haiku|gpt-[0-9]' "${wrapper_file}"; then
    fail ".agents/skills/${skill_dir}/SKILL.md must not contain runtime-specific mappings"
  fi
}

assert_wrapper_skill "velo-new" "new" "commands/new.md" "Use when the user asks for /velo:new"
assert_wrapper_skill "velo-task" "task" "commands/task.md" "Use when the user asks for /velo:task"
assert_wrapper_skill "velo-yo" "yo" "commands/yo.md" "Use when the user asks for /velo:yo"
assert_wrapper_skill "velo-hunt" "hunt" "commands/hunt.md" "Use when the user asks for /velo:hunt"

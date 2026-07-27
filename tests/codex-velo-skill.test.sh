#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_dir="${repo_root}/.agents/skills"
generic_skill_file="${skills_dir}/velo/SKILL.md"

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

frontmatter_value() {
  # Prints the value of a YAML frontmatter key, or nothing if the key is absent.
  # Scoped to the leading --- block so a `name:` further down the body cannot
  # satisfy a frontmatter assertion.
  local file="$1"
  local key="$2"

  awk -v key="${key}" '
    NR == 1 { in_frontmatter = ($0 == "---"); next }
    in_frontmatter && $0 == "---" { in_frontmatter = 0; next }
    in_frontmatter && substr($0, 1, length(key) + 2) == key ": " {
      print substr($0, length(key) + 3)
      in_frontmatter = 0
    }
  ' "${file}"
}

canonical_set() {
  # stdin: one member per line. stdout: members blank-stripped, deduped, sorted
  # and space-joined — a canonical form for comparing collections as sets.
  awk 'NF { print }' | sort -u | tr '\n' ' ' | sed 's/ $//'
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

# Every skill_dir passed to assert_wrapper_skill, reconciled against the
# filesystem after the call list below.
asserted_dirs=()

assert_wrapper_skill() {
  local skill_dir="$1"
  local skill_name="$2"
  local playbook="$3"
  local trigger="$4"
  local wrapper_file="${repo_root}/.agents/skills/${skill_dir}/SKILL.md"
  local actual_name
  local actual_description
  local description_tail

  asserted_dirs+=("${skill_dir}")

  [[ -f "${wrapper_file}" ]] || fail ".agents/skills/${skill_dir}/SKILL.md must exist so Codex can expose velo:${skill_name}"

  # Matched as a whole value, not a substring: `name: planning` and `name: plan-v2`
  # both satisfy a substring check for `name: plan` while exposing the wrong
  # Codex command.
  actual_name="$(frontmatter_value "${wrapper_file}" "name")"
  if [[ "${actual_name}" != "${skill_name}" ]]; then
    fail ".agents/skills/${skill_dir}/SKILL.md frontmatter name must be exactly '${skill_name}' so Codex exposes velo:${skill_name}, but it is '${actual_name}'"
  fi

  # Same weakness, and it needs both halves of the fix. The description
  # legitimately continues past the trigger, so this is a prefix match rather
  # than an equality one — but a bare prefix match is not enough: a trigger for
  # /velo:planning still starts with "...asks for /velo:plan". Anchor the front
  # to the start of the frontmatter value, and require the mode name to end at
  # the boundary rather than run on into a longer name.
  actual_description="$(frontmatter_value "${wrapper_file}" "description")"
  description_tail="${actual_description#"${trigger}"}"
  if [[ "${description_tail}" == "${actual_description}" ]]; then
    fail ".agents/skills/${skill_dir}/SKILL.md frontmatter description must start with '${trigger}', but it is '${actual_description}'"
  fi
  if [[ "${description_tail}" == [a-z0-9_-]* ]]; then
    fail ".agents/skills/${skill_dir}/SKILL.md frontmatter description must trigger on exactly '${trigger}', but it runs on into '${trigger}${description_tail%%[^a-z0-9_-]*}' — a different mode name"
  fi

  assert_file_contains "${wrapper_file}" 'Velo workflow root: resolve by walking up from this `SKILL.md`'
  assert_file_contains "${wrapper_file}" "Load AGENTS.md first."
  assert_file_contains "${wrapper_file}" "Read \`ADAPTER.md\`"
  # Safe as a substring: the closing backtick anchors the end of the path, so
  # `commands/plan.md` cannot be satisfied by `commands/planning.md`.
  assert_file_contains "${wrapper_file}" "Read \`${playbook}\`"
  assert_order "${wrapper_file}" "Load AGENTS.md first." "Read \`ADAPTER.md\`"
  assert_order "${wrapper_file}" "Read \`ADAPTER.md\`" "Read \`${playbook}\`"
  assert_file_contains "${wrapper_file}" "Treat this as a Codex wrapper around the existing Velo playbook."
  assert_file_contains "${wrapper_file}" "Do not treat this wrapper as an automatic Codex slash command."

  if grep -qE 'AskUserQuestion|ToolSearch|TodoWrite|Agent tool|request_user_input|update_plan|tool_search|spawn_agent|Codex CLI|codex exec|sonnet|opus|haiku|fable|gpt-[0-9]' "${wrapper_file}"; then
    fail ".agents/skills/${skill_dir}/SKILL.md must not contain runtime-specific mappings"
  fi
}

assert_wrapper_skill "velo-task" "task" "commands/task.md" "Use when the user asks for /velo:task"
assert_wrapper_skill "velo-yo" "yo" "commands/yo.md" "Use when the user asks for /velo:yo"
assert_wrapper_skill "velo-hunt" "hunt" "commands/hunt.md" "Use when the user asks for /velo:hunt"
assert_wrapper_skill "velo-discuss" "discuss" "commands/discuss.md" "Use when the user asks for /velo:discuss"
assert_wrapper_skill "velo-plan" "plan" "commands/plan.md" "Use when the user asks for /velo:plan"

# The call list above is hand-written, so it can fall behind the filesystem the
# same way any hardcoded mode list does. Reconcile the two: "added a wrapper,
# forgot the call site" leaves a wrapper whose contents nothing above verified,
# and that must fail here rather than pass silently.
shopt -s nullglob

filesystem_dirs=()
for wrapper_file in "${skills_dir}"/velo-*/SKILL.md; do
  filesystem_dirs+=("$(basename "$(dirname "${wrapper_file}")")")
done

shopt -u nullglob

# bash 3.2 errors on "${arr[@]}" for an empty array under `set -u`, and an empty
# filesystem_dirs is a real state (every wrapper deleted), so guard the expansion.
asserted_set=""
filesystem_set=""
if (( ${#asserted_dirs[@]} > 0 )); then
  asserted_set="$(printf '%s\n' "${asserted_dirs[@]}" | canonical_set)"
fi
if (( ${#filesystem_dirs[@]} > 0 )); then
  filesystem_set="$(printf '%s\n' "${filesystem_dirs[@]}" | canonical_set)"
fi

if [[ "${asserted_set}" != "${filesystem_set}" ]]; then
  fail "the assert_wrapper_skill call list in tests/codex-velo-skill.test.sh covers [${asserted_set}] but .agents/skills/ provides wrappers for [${filesystem_set}]; every wrapper must have a call so its contents are verified. Add or remove assert_wrapper_skill calls to match."
fi

#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

body_without_frontmatter() {
  local file="$1"

  awk '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { in_frontmatter = 0; next }
    !in_frontmatter { print }
  ' "${file}"
}

runtime_leak_pattern='AskUserQuestion|ToolSearch|TodoWrite|ExitPlanMode|Agent tool|`Read`|`Grep`|`Glob`|`Bash`|request_user_input|update_plan|tool_search|spawn_agent|Codex CLI|codex exec|runtime interaction prompt adapter|runtime agent adapter|runtime todo adapter|runtime deferred-tool adapter|runtime file access adapter|runtime shell adapter|runtime mode handoff adapter|runtime cost adapter|sonnet|opus|haiku|gpt-[0-9]|model: (sonnet|opus|haiku|gpt)'

while IFS= read -r file; do
  if grep -qE "${runtime_leak_pattern}" "${file}"; then
    fail "${file#${repo_root}/} must use ADAPTER.md concept names instead of runtime-specific tool/model names"
  fi
done < <(
  {
    find "${repo_root}/commands" "${repo_root}/.agents/skills" "${repo_root}/skills" -name '*.md'
    printf '%s\n' \
      "${repo_root}/AGENTS.md" \
      "${repo_root}/PERSONA.md" \
      "${repo_root}/README.md" \
      "${repo_root}/TEAM.md"
  } | sort
)

while IFS= read -r file; do
  if body_without_frontmatter "${file}" | grep -qE "${runtime_leak_pattern}"; then
    fail "${file#${repo_root}/} body must use ADAPTER.md concept names instead of runtime-specific tool/model names"
  fi
done < <(find "${repo_root}/agents" -name '*.md' | sort)

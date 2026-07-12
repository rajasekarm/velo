#!/usr/bin/env bash
# No ghost employees: every agent named in README's team tables must exist as
# an agent file and be rostered in TEAM.md — and vice versa. (A "Spec Writer"
# row once survived in README for months after the agent was retired.)
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readme_file="${repo_root}/README.md"
team_file="${repo_root}/TEAM.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# README display name → agent slug ("-" = orchestrator persona, no agent file).
# Adding a team member means adding it here too — that is the point.
declare -A ROSTER=(
  ["Velo"]="-"
  ["Distinguished Engineer"]="distinguished-engineer"
  ["Product Manager"]="product-manager"
  ["Tech Lead"]="tech-lead"
  ["Observability Engineer"]="observability-engineer"
  ["Security Engineer"]="security-engineer"
  ["Frontend Engineer"]="fe-engineer"
  ["Backend Engineer"]="be-engineer"
  ["Database Engineer"]="db-engineer"
  ["Infrastructure Engineer"]="infra-engineer"
  ["Automation Engineer"]="automation-engineer"
  ["Frontend Reviewer"]="fe-reviewer"
  ["Backend Reviewer"]="be-reviewer"
  ["Database Reviewer"]="db-reviewer"
  ["Infrastructure Reviewer"]="infra-reviewer"
  ["Automation Reviewer"]="automation-reviewer"
  ["Commit"]="commit"
  ["Learnings Agent"]="learnings-agent"
)

# --- README roster rows → known agents with real files ------------------------
readme_names="$(sed -n '/^## The team/,/^## How it works/p' "${readme_file}" \
  | grep -E '^\| \*\*' | sed -E 's/^\| \*\*([^*]+)\*\*.*/\1/')"

[[ -n "${readme_names}" ]] || fail "no roster rows found in README's team section"

while IFS= read -r name; do
  if [[ -z "${ROSTER[${name}]+x}" ]]; then
    fail "README lists '${name}' but no such agent is known — ghost employee (update the roster map if this is a real new agent)"
  fi
  slug="${ROSTER[${name}]}"
  [[ "${slug}" == "-" ]] && continue
  [[ -f "${repo_root}/agents/${slug}.md" ]] \
    || fail "README lists '${name}' but agents/${slug}.md does not exist"
  grep -qF "agents/${slug}.md" "${team_file}" \
    || fail "README lists '${name}' but agents/${slug}.md is not rostered in TEAM.md"
done <<< "${readme_names}"

# --- Every agent file → rostered in TEAM.md and named in README ---------------
declare -A SLUG_TO_NAME=()
for name in "${!ROSTER[@]}"; do
  SLUG_TO_NAME["${ROSTER[${name}]}"]="${name}"
done

for agent_file in "${repo_root}"/agents/*.md; do
  slug="$(basename "${agent_file}" .md)"
  grep -qF "agents/${slug}.md" "${team_file}" \
    || fail "agents/${slug}.md exists but is not rostered in TEAM.md"
  if [[ -z "${SLUG_TO_NAME[${slug}]+x}" ]]; then
    fail "agents/${slug}.md exists but has no README roster entry (update the roster map and README's team tables)"
  fi
  name="${SLUG_TO_NAME[${slug}]}"
  echo "${readme_names}" | grep -qxF "${name}" \
    || fail "agents/${slug}.md exists but '${name}' is missing from README's team tables"
done

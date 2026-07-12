#!/usr/bin/env bash
# WORKFLOW.md must not describe states that no command defines. The diagrams
# once showed SPEC_AUDIT and COMMIT/PUSH gates long after the commands had
# retired them — this pins every snake-case token in WORKFLOW.md to a live
# `## State:` heading (or a known STATUS string) in commands/*.md.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflow_file="${repo_root}/WORKFLOW.md"
commands_dir="${repo_root}/commands"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# Agent output-contract strings — legitimate in diagrams without being states.
STATUS_STRINGS="SPEC_OK SPEC_REWORK_NEEDED"

tokens="$(grep -oE '[A-Z][A-Z0-9]*(_[A-Z0-9]+)+' "${workflow_file}" | sort -u)"

[[ -n "${tokens}" ]] || exit 0

while IFS= read -r token; do
  is_status=0
  for status in ${STATUS_STRINGS}; do
    [[ "${token}" == "${status}" ]] && is_status=1
  done

  if [[ ${is_status} -eq 1 ]]; then
    grep -qrF "${token}" "${commands_dir}" \
      || fail "WORKFLOW.md uses status string ${token} but no command mentions it"
  else
    grep -qrE "^## State: ${token}\$" "${commands_dir}" \
      || fail "WORKFLOW.md references ${token} but no command defines '## State: ${token}' — stale diagram or missing state"
  fi
done <<< "${tokens}"

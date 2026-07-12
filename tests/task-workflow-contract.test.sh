#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
task_file="${repo_root}/commands/task.md"
readme_file="${repo_root}/README.md"
workflow_file="${repo_root}/WORKFLOW.md"

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

assert_file_not_contains() {
  local file="$1"
  local unexpected="$2"

  if grep -qF "${unexpected}" "${file}"; then
    fail "${file#${repo_root}/} must not contain stale task workflow claim: ${unexpected}"
  fi
}

# --- Current contract: task mode is a single adaptive delegated flow ---------
assert_file_contains "${task_file}" "single adaptive delegated flow"
assert_file_contains "${task_file}" "Assumptions ledger"
assert_file_contains "${task_file}" "escalated-to-new"
assert_file_contains "${readme_file}" "adaptive delegated flow"

# --- Retired spec-based flow must not resurface -------------------------------
# Task mode has no spec sub-system: no SPEC_AUDIT/SPEC_APPROVAL states and no
# task-spec authorship modes anywhere in the coordination layer.
# (commands/task.md is allowed to mention SPEC_AUDIT in negative statements
# such as "Task mode has no SPEC_AUDIT" — only the mode strings are banned.)
assert_file_not_contains "${task_file}" "No planning phase"
assert_file_not_contains "${task_file}" "Mode: task-spec"
assert_file_not_contains "${readme_file}" "No planning phase"
assert_file_not_contains "${readme_file}" "transient task-spec"
assert_file_not_contains "${workflow_file}" "SPEC_AUDIT"
assert_file_not_contains "${workflow_file}" "No planning phase"

for file in "${repo_root}/TEAM.md" "${repo_root}"/agents/*.md \
  "${repo_root}/skills/spec-quality-check.md" \
  "${repo_root}/skills/velo-parallelism.md" \
  "${repo_root}/skills/velo-failure-modes.md"; do
  assert_file_not_contains "${file}" "Mode: task-spec"
  assert_file_not_contains "${file}" "SPEC_AUDIT"
done

# --- Single source of truth ----------------------------------------------------
# commands/task.md is the only task command definition. A stale pre-refactor
# copy once resurfaced as cmd/task.md; guard against that class of drift.
if [[ -e "${repo_root}/cmd" ]]; then
  fail "cmd/ must not exist — commands/ is the single source of truth for command definitions"
fi

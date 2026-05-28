#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
task_file="${repo_root}/commands/task.md"
readme_file="${repo_root}/README.md"

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

assert_file_not_contains "${task_file}" "No planning phase"
assert_file_not_contains "${readme_file}" "No planning phase"
assert_file_not_contains "${task_file}" "no contract gate"

assert_file_contains "${task_file}" "lightweight delegated flow"
assert_file_contains "${task_file}" "inline transient task-spec"
assert_file_contains "${readme_file}" "Lightweight delegated flow"

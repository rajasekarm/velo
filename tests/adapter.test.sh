#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
adapter_file="${repo_root}/ADAPTER.md"

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

[[ -f "${adapter_file}" ]] || fail "ADAPTER.md must exist as the runtime compatibility contract"

assert_file_contains "${adapter_file}" "# Velo — Runtime Adapter"
assert_file_contains "${adapter_file}" "## Concept Names"
assert_file_contains "${adapter_file}" '| `resolve-model` |'
assert_file_contains "${adapter_file}" '| `ask-options` |'
assert_file_contains "${adapter_file}" '| `spawn-agent` |'
assert_file_contains "${adapter_file}" '| `track-tasks` |'
assert_file_contains "${adapter_file}" '| `load-tool` |'
assert_file_contains "${adapter_file}" '| `read-files` |'
assert_file_contains "${adapter_file}" '| `run-shell` |'
assert_file_contains "${adapter_file}" '| `handoff-mode` |'
assert_file_contains "${adapter_file}" '| `run-external-review` |'
assert_file_contains "${adapter_file}" '| `report-cost` |'
assert_file_contains "${adapter_file}" "## Model Classes"
assert_file_contains "${adapter_file}" "| balanced |"
assert_file_contains "${adapter_file}" "| deep-reasoning |"
assert_file_contains "${adapter_file}" "| external-review |"
assert_file_contains "${adapter_file}" "## Interaction Prompts"
assert_file_contains "${adapter_file}" "## Agent Spawning"
assert_file_contains "${adapter_file}" "## Todo State"
assert_file_contains "${adapter_file}" "## Deferred Tool Lookup"
assert_file_contains "${adapter_file}" "## File and Shell Access"
assert_file_contains "${adapter_file}" "## Mode Handoff"
assert_file_contains "${adapter_file}" "## Cost Reporting"

#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
task_file="${repo_root}/commands/task.md"
readme_file="${repo_root}/README.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# Negative guards are case-INSENSITIVE (grep -qiF), so sentence-start
# capitalization flips ("Lightweight delegated flow") and lowercase paraphrases
# don't slip past the guard. Patterns stay full phrases — false-positive risk
# lives in shortened patterns, not in the case flag.
assert_file_not_contains() {
  local file="$1"
  local unexpected="$2"

  if grep -qiF "${unexpected}" "${file}"; then
    fail "${file#${repo_root}/} must not contain stale task workflow claim (case-insensitive): ${unexpected}"
  fi
}

# Positive identifier pins: case-SENSITIVE (grep -qF) — these are literal
# machine-facing tokens with cross-file consumers, so a case change IS a
# break. They close the gutting gap: emptying commands/task.md (or deleting
# its integration surface) passes every negative guard above; these fail it.
assert_file_contains() {
  local file="$1"
  local expected="$2"
  local why="$3"

  if ! grep -qF "${expected}" "${file}"; then
    fail "${file#${repo_root}/} must contain integration token: ${expected} — ${why}"
  fi
}

# Subject files must exist — a missing file would make every grep-based
# negative check below pass vacuously.
[[ -f "${task_file}" ]] || fail "commands/task.md is missing; remaining checks would pass vacuously"
[[ -f "${readme_file}" ]] || fail "README.md is missing; remaining checks would pass vacuously"

# Retired-claim guards only. This test does not pin current prose to disk
# state (that mechanism produced the rot fixed in 761128a and again after
# f891b27/0618a29); it guards specific retired claims from creeping back.

# Task mode has a planning/announce step and a contract gate.
assert_file_not_contains "${task_file}" "No planning phase"
assert_file_not_contains "${readme_file}" "No planning phase"
assert_file_not_contains "${task_file}" "no contract gate"

# The inline transient task-spec sub-system was retired (f891b27, completed
# in 0618a29): task mode has no spec states; underspecified work escalates
# to /velo:plan. This phrase returning means the dead sub-system is being
# resurrected in prose.
assert_file_not_contains "${task_file}" "inline transient task-spec"
assert_file_not_contains "${readme_file}" "inline transient task-spec"

# "lightweight delegated flow" is the retired name for task mode (renamed in
# f891b27; commands/task.md is the authority and calls it "a single adaptive
# delegated flow"). The old name returning in either file recreates the
# naming drift between README and task.md.
assert_file_not_contains "${task_file}" "lightweight delegated flow"
assert_file_not_contains "${readme_file}" "Lightweight delegated flow"

# Integration-token pins for commands/task.md. The existence checks above
# close file *deletion*; these close content *gutting* — an emptied or
# hollowed-out task.md passes every negative guard, but cannot pass these.
# Each token is a machine-facing identifier other files dispatch on, so its
# disappearance is an integration break, not benign rewording.

# `Planned-via:` — the plan->task dispatch key (frozen header contract,
# skills/velo-plan-package.md; producer commands/plan.md). task.md's
# escalation Hard Rule carries an explicit Planned-via exception; if task.md
# loses the token, package-bearing invocations re-escalate to /velo:plan in
# a loop.
assert_file_contains "${task_file}" "Planned-via:" \
  "plan->task dispatch key; without it, planned work re-escalates to /velo:plan in a loop"

# `handoff-mode` — ADAPTER.md-defined routing concept (ADAPTER.md:
# concept table). task.md's escalation rule and VALIDATE redirect route to
# /velo:plan through it; if task.md loses the token, escalation has no
# routing mechanism.
assert_file_contains "${task_file}" "handoff-mode" \
  "ADAPTER.md routing concept; without it, escalation to /velo:plan has no mechanism"

# `Task-folder` — plan-package header key (frozen contract,
# skills/velo-plan-package.md; consumed by skills/velo-task-status.md and
# commands/plan.md). task.md reuses a carried Task-folder for breadcrumb and
# resume continuity; if the token vanishes, task mode derives a fresh slug
# and orphans the plan's status.md and index row.
assert_file_contains "${task_file}" "Task-folder" \
  "plan-package folder-continuity key; without it, handoff orphans the plan's status breadcrumbs"

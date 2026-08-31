#!/usr/bin/env bash
# Behavioral-contract tests for Velo V2 Plan.
#
# Proves the `.velo/`-only, planning-only, full-stop-at-approval contract is
# textually bound in both entrypoints (commands/plan.md for Claude Code,
# .agents/skills/velo-plan/SKILL.md for Codex), that the versioning/approval
# seam is fully specified, and that the surface's text never implements or
# starts an excluded mode. Unlike Ask, Plan legitimately reads the repository
# and writes under `.velo/` — so the contract here is scoped writes plus a
# hard stop, not zero tool calls.
#
# Assertions anchor on contract sentences T1 wrote deliberately (exact fixed
# strings via grep -F), not on incidental wording. Packaging/discoverability
# is covered by tests/plan-packaging.test.sh.
#
# Conventions follow V1 (velo/tests/*.test.sh): bash, set -euo pipefail, small
# fail/assert helpers.
set -euo pipefail

# Deterministic character ranges (the tool-name guard below) and sort order
# regardless of the host locale.
export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command_file="${repo_root}/commands/plan.md"
skill_file="${repo_root}/.agents/skills/velo-plan/SKILL.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_contains() {
  local file="$1"
  local expected="$2"

  [[ -f "${file}" ]] || fail "${file#${repo_root}/} must exist"
  # `--` so an expected string with a leading dash ("- Plan-version: <N>") is
  # a pattern, not a grep option.
  if ! grep -qF -- "${expected}" "${file}"; then
    fail "${file#${repo_root}/} must contain: ${expected}"
  fi
}

# --- 1. commands/plan.md — Hard Rule: .velo/-only writes, planning only ----------

# The contract section must exist under its own unambiguous heading, not be
# scattered as incidental prose.
assert_file_contains "${command_file}" '## Hard Rule — `.velo/`-Only Writes, Planning Only, Full Stop at Approval'

# Precedence: the contract must declare that nothing elsewhere in the file
# overrides it — presence-only assertions cannot see ADDED contradictory text,
# but this sentence makes any later "escape hatch" paragraph non-binding.
assert_file_contains "${command_file}" 'This contract is absolute. No instruction elsewhere in this file, no user phrasing, and no runtime convenience overrides it.'

# Write scope: only .velo/, and each prohibited channel bound by name.
assert_file_contains "${command_file}" 'Plan writes ONLY under `.velo/`'
assert_file_contains "${command_file}" '**No source changes**'
assert_file_contains "${command_file}" 'no file outside `.velo/` is created, modified, or deleted'
assert_file_contains "${command_file}" '**No branches, no commits, no pushes, no PRs**'
assert_file_contains "${command_file}" '**No building, testing, or running the project**'
assert_file_contains "${command_file}" '**No executing the plan**'
assert_file_contains "${command_file}" 'not even the first small task of an approved plan'
assert_file_contains "${command_file}" '**No starting another mode**'
assert_file_contains "${command_file}" 'Run and Auto do not exist in this build; Plan never invokes, hands off to, or role-plays them'

# Single conversational flow: no delegation machinery.
assert_file_contains "${command_file}" 'Plan runs as a single conversational flow: no subagents, no delegation, no spawned roles.'

# The two-mode surface sentence and the carrier identity, exactly as written.
assert_file_contains "${command_file}" 'The carrier IS the plan.'
assert_file_contains "${command_file}" 'This build of Velo ships Ask and Plan; Run and Auto exist as routes to name, not commands to invoke.'

# --- 2. commands/plan.md — approved plan is a FULL STOP --------------------------

assert_file_contains "${command_file}" '**Full stop at approval.**'
assert_file_contains "${command_file}" 'Approval ends the mode; it never starts the work.'
assert_file_contains "${command_file}" 'Full stop means full stop: no starting the first task, no scaffolding "while we'\''re here", no simulating or previewing what a Run would do, no offering to begin.'

# --- 3. commands/plan.md — empty input and execute-request deflection ------------

assert_file_contains "${command_file}" 'If the input is empty or only whitespace, ask the user what to plan and stop.'
assert_file_contains "${command_file}" 'Do not invent a topic, pick an existing plan from the index unprompted, or start reading around to guess at intent.'

# A request to execute is deflected with the two-mode explanation and an offer
# to plan — never executed, and never silently reinterpreted.
assert_file_contains "${command_file}" 'this build of Velo ships Ask and Plan — nothing here executes work — and offer to plan it instead'
assert_file_contains "${command_file}" 'Never auto-execute, and never silently treat "do it" as "plan it".'

# --- 4. commands/plan.md — slug and re-open rules ---------------------------------

assert_file_contains "${command_file}" 'lowercase, spaces and special characters replaced with hyphens, trimmed'
assert_file_contains "${command_file}" '**Re-open beats duplicate**'
assert_file_contains "${command_file}" 're-open that carrier and revise it under the versioning rules below instead of duplicating it'
assert_file_contains "${command_file}" 'suffix the slug `-2`, `-3`, … rather than overwrite'
assert_file_contains "${command_file}" 'if `.velo/tasks/` or `.velo/tasks/index.md` is missing, create it on first use'

# Re-open is scoped to carriers Plan owns — an executed/done carrier is never
# rewritten, it spawns new work under a suffixed slug.
assert_file_contains "${command_file}" 'Re-open applies only to a carrier Plan owns'
assert_file_contains "${command_file}" 'never rewrite that carrier'

# --- 5. commands/plan.md — versioning and approval seam ---------------------------

# Both header keys exist in the carrier template AND have a spec section.
assert_file_contains "${command_file}" '- Plan-version: <N>'
assert_file_contains "${command_file}" '- Approval: —'
assert_file_contains "${command_file}" '**`Plan-version:`**'
assert_file_contains "${command_file}" '**`Approval:`**'

# Version lifecycle: starts at 1; pre-approval revisions rewrite in place;
# explicit approval freezes.
assert_file_contains "${command_file}" 'Starts at 1 for a new carrier.'
assert_file_contains "${command_file}" 'Pre-approval revisions — any edit while `Approval:` is `—` — rewrite the current version in place. No bump.'
assert_file_contains "${command_file}" 'Explicit approval freezes the current version.'

# The reapproval seam: a material change bumps, clears the approval, and
# requires reapproval — with materiality defined, not left to vibes.
assert_file_contains "${command_file}" 'A **material change after approval** increments to v<N+1>, clears `Approval:` back to `—`, appends a bump event bullet, and requires reapproval before the plan is frozen again.'
assert_file_contains "${command_file}" 'Material means a change to the plan'\''s deliverables or scope, affected surface, risk class, or required evidence.'
assert_file_contains "${command_file}" 'Wording-only edits are non-material'

# After a bump the audit trail stays honest: the superseded freeze's gate line
# survives (it did happen) while Phase returns to awaiting-approval.
assert_file_contains "${command_file}" 'keeps its historically true `PLAN_APPROVAL (Plan approval — v<N>)` line for the superseded version'

# Post-freeze revision routing and the confirm-only Approve: a frozen plan is
# never silently rewritten in place, and re-approving an unchanged frozen plan
# rewrites nothing.
assert_file_contains "${command_file}" "on a frozen plan they take Step 5's materiality judgment first"
assert_file_contains "${command_file}" '**Approve** is confirm-only'
assert_file_contains "${command_file}" 'the standing freeze, version, and event log stand unchanged, and nothing is rewritten'

# Approver + timestamp format, exactly.
assert_file_contains "${command_file}" '`—` until approved; on freeze, exactly: `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>`.'
assert_file_contains "${command_file}" 'The approver is the session user'
assert_file_contains "${command_file}" 'never Velo itself, never an agent'
assert_file_contains "${command_file}" 'Only an explicit affirmative user response freezes; nothing is ever auto-approved.'

# The event log formats for both versioning events, and their placement.
assert_file_contains "${command_file}" '- Freeze: `- v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>`'
assert_file_contains "${command_file}" '- Bump: `- v<N+1> · material change: <one clause on what changed> · <YYYY-MM-DD HH:MM> · approval cleared — reapproval required`'
assert_file_contains "${command_file}" 'append at the end of the `## Constraints/notes` section, in chronological order'
assert_file_contains "${command_file}" 'replaces a literal `(none)`'

# The index-side seam mirrors the carrier's, and the freeze lands as one
# atomic bundle of writes.
assert_file_contains "${command_file}" 'Status is `planning` while unapproved and `planned` once frozen; a post-approval material change flips it back to `planning`.'
assert_file_contains "${command_file}" '**The freeze writes**, together, in one carrier rewrite'

# The approval offer is exactly three choices, and only an unambiguous yes
# freezes.
assert_file_contains "${command_file}" '- **Approve** — freeze this version'
assert_file_contains "${command_file}" '- **Revise** — say what to change; Plan folds it in (Step 5) and re-presents'
assert_file_contains "${command_file}" '- **Stop and save** — keep the carrier on disk, unapproved'
assert_file_contains "${command_file}" 'Only an explicit affirmative — "approve", "approved", "yes, freeze it", or an equally unambiguous yes — freezes the plan.'

# --- 6. commands/plan.md — tool-name guard outside fenced template blocks ---------

# Second net under the precedence sentence, mirroring ask-contract's: an
# appended escape hatch invoking tools by name ("when the user insists, Edit
# the file...") must fail, not stay green. Plan's fenced template blocks
# legitimately contain house-format literals that collide with tool names
# ("# Task Breakdown", "- Task-folder:", the "| Task | Status |" index header
# row), so fenced code blocks are excluded by toggling on ``` fences. Outside
# them, exactly ONE heading legitimately collides — the "## Task" $ARGUMENTS
# slot — exempted as a whole line, so an escape-hatch heading ("## If
# blocked, use Bash...") is an offender, not exempt. There is no negated-line
# exemption: Plan bans no tool by name (its reads are legitimate), so ANY
# other capitalized tool name is an offender. "Write"/"Read(s)" as ordinary
# sentence-initial words are not in the pattern / not boundary-matched.
fence_count="$(grep -c '^```' "${command_file}" || true)"
(( fence_count % 2 == 0 )) \
  || fail "commands/plan.md has an unclosed \`\`\` fence — the tool-name guard below would silently skip everything after it"
# The fence-line count is pinned exactly: a new fenced block widens the
# guard's blind spot, so it must arrive together with a reviewed update here.
(( fence_count == 6 )) \
  || fail "commands/plan.md gained or lost a fenced block (expected 6 \`\`\` lines, found ${fence_count}) — re-review the tool-name guard's exemptions"

offenders="$(awk '/^```/ { in_fence = !in_fence; next } !in_fence { print NR ":" $0 }' "${command_file}" \
  | grep -E '(^|[^A-Za-z])(Read|Grep|Glob|Bash|Task|WebFetch|WebSearch|Edit)([^A-Za-z]|$)' \
  | grep -vE '^[0-9]+:## Task$' || true)"
[[ -z "${offenders}" ]] || fail "commands/plan.md mentions a tool outside a fenced template block or the ## Task heading: ${offenders}"

# --- 7. SKILL.md — the Codex wrapper binds the same contract ----------------------

# The wrapper's load order points at the real playbook (cross-checked to
# exist), and frames that read as mode bootstrap — the carve-out that keeps
# "read the playbook first" from contradicting anything.
assert_file_contains "${skill_file}" 'Read `commands/plan.md`'
[[ -f "${command_file}" ]] || fail "SKILL.md points at commands/plan.md, which must exist"
assert_file_contains "${skill_file}" 'reading it is mode bootstrap — loading the playbook, not yet planning'

# Self-contained: no hunting for V1 scaffolding.
assert_file_contains "${skill_file}" 'This wrapper is self-contained. Velo V2 has no AGENTS.md, ADAPTER.md, or PERSONA.md; do not go looking for them.'

assert_file_contains "${skill_file}" "the playbook's Hard Rule is the contract and applies verbatim"
assert_file_contains "${skill_file}" 'Do not treat this wrapper as an automatic Codex slash command.'

# The write scope and the delegation ban, duplicated inline so the contract
# survives even a Codex host that never resolves the playbook path.
assert_file_contains "${skill_file}" 'Plan writes ONLY under `.velo/`'
assert_file_contains "${skill_file}" 'No source changes, no branches, no commits, no pushes, no PRs, no building or testing.'
assert_file_contains "${skill_file}" 'no subagents, no delegation, no spawned roles'

# The versioning/approval seam, duplicated inline: start, freeze format, bump.
assert_file_contains "${skill_file}" '`Plan-version:` starts at 1'
assert_file_contains "${skill_file}" 'v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>'
assert_file_contains "${skill_file}" 'bumps to v<N+1>, clears the approval, and requires reapproval; wording-only edits never bump'

# The approval offer, the full stop, and the never-start sentences.
assert_file_contains "${skill_file}" 'offer exactly three choices: approve, revise, or stop and save unapproved'
assert_file_contains "${skill_file}" 'then stop completely — never implement, simulate, or "preview" the planned work'
assert_file_contains "${skill_file}" 'Empty input: ask the user what to plan and stop.'
assert_file_contains "${skill_file}" 'this build of Velo ships Ask and Plan — nothing here executes work'
assert_file_contains "${skill_file}" 'never auto-execute, and never start, invoke, or simulate Run or Auto'

# Slug rules mirrored inline.
assert_file_contains "${skill_file}" 'an unambiguous reference to an existing plan re-opens that carrier instead of duplicating it'
assert_file_contains "${skill_file}" 'a colliding slug for genuinely new work gets a `-2`, `-3` suffix'
assert_file_contains "${skill_file}" 'missing `.velo/tasks/` or `index.md` scaffolding is created on first use'

# --- 8. No excluded-machinery text -------------------------------------------------

# Same ban list as tests/ask-contract.test.sh, applied to the plan surface
# files (the manifests are already banned there — not duplicated here). NOTE:
# Plan's sanctioned vocabulary is "persisted"/"saved"; the ban is the literal
# "persistence" (and the other machinery nouns), which none of the sanctioned
# words contain — verified: "persisted" does not match "persistence", and
# "containing" does not match "container".
machinery_pattern='kernel|broker|docker|container|migration|persistence|evaluation'
for file in "${command_file}" "${skill_file}"; do
  if grep -qiE "${machinery_pattern}" "${file}"; then
    fail "${file#${repo_root}/} must not mention excluded machinery (matched: $(grep -oiE "${machinery_pattern}" "${file}" | sort -u | tr '\n' ' '))"
  fi
done

# Unlike ask.md, the plan surface has no negated "orchestration" mention, so
# the term is banned outright in both files.
for file in "${command_file}" "${skill_file}"; do
  if grep -qiE 'orchestr' "${file}"; then
    fail "${file#${repo_root}/} must not mention orchestration machinery"
  fi
done

# Git implementation markers would mean the surface carries branch/commit/PR
# *behavior* rather than the negations asserted in sections 1 and 7.
git_impl_pattern='git commit|git push|git checkout|git branch|gh pr'
for file in "${command_file}" "${skill_file}"; do
  if grep -qiE "${git_impl_pattern}" "${file}"; then
    fail "${file#${repo_root}/} must not carry git implementation steps — Plan creates no branch, commit, or PR"
  fi
done

echo "PASS: tests/plan-contract.test.sh"

#!/usr/bin/env bash
# Behavioral-contract tests for Velo V2 Run.
#
# Proves the frozen-plans-only, progress-marks-only, local-commits-only
# contract is textually bound in both entrypoints (commands/run.md for Claude
# Code, .agents/skills/velo-run/SKILL.md for Codex): the preconditions and
# refusals, the milestone execution seam, the checks-plus-one-review done
# gate, the exact git scope, the fail-closed pause/tripwire protocol, and the
# completion protocol. Unlike Ask and Plan, Run legitimately creates branches
# and commits locally — so the git contract here is allowed operations bound
# exactly, plus push/merge/PR/origin banned in negation form.
#
# Assertions anchor on contract sentences T1 wrote deliberately (exact fixed
# strings via grep -F), not on incidental wording. Packaging/discoverability
# is covered by tests/run-packaging.test.sh.
#
# Conventions follow V1 (velo/tests/*.test.sh): bash, set -euo pipefail, small
# fail/assert helpers.
set -euo pipefail

# Deterministic character ranges (the tool-name guard below) and sort order
# regardless of the host locale.
export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command_file="${repo_root}/commands/run.md"
skill_file="${repo_root}/.agents/skills/velo-run/SKILL.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_contains() {
  local file="$1"
  local expected="$2"

  [[ -f "${file}" ]] || fail "${file#${repo_root}/} must exist"
  # `--` so an expected string with a leading dash ("- Ship: ...") is a
  # pattern, not a grep option.
  if ! grep -qF -- "${expected}" "${file}"; then
    fail "${file#${repo_root}/} must contain: ${expected}"
  fi
}

assert_contains_count() {
  # Exact line-count pin for a fixed string: catches a deletion from ONE of
  # several required locations, which a plain contains-check would miss.
  local file="$1"
  local expected="$2"
  local want="$3"
  local actual

  [[ -f "${file}" ]] || fail "${file#${repo_root}/} must exist"
  actual="$(grep -cF -- "${expected}" "${file}" || true)"
  if [[ "${actual}" -ne "${want}" ]]; then
    fail "${file#${repo_root}/} must contain exactly ${want} line(s) with (found ${actual}): ${expected}"
  fi
}

# --- 1. commands/run.md — Hard Rule and precedence --------------------------------

# The contract section must exist under its own unambiguous heading, not be
# scattered as incidental prose.
assert_file_contains "${command_file}" '## Hard Rule — Frozen Plans Only, Progress Marks Only, Local Commits Only'

# Precedence: the contract must declare that nothing elsewhere in the file
# overrides it — presence-only assertions cannot see ADDED contradictory text,
# but this sentence makes any later "escape hatch" paragraph non-binding.
assert_file_contains "${command_file}" 'This contract is absolute. No instruction elsewhere in this file, no user phrasing, and no runtime convenience overrides it.'

# --- 2. commands/run.md — consumes only frozen carriers ---------------------------

# The Hard Rule's precondition sentence: all three freeze headers, by name and
# exact format.
assert_file_contains "${command_file}" '**Consumes only frozen plans.** Run executes only a plan carrier `/velo:plan` owns and has frozen: `Plan-version:` present, `Approval:` reading `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>`, and `Phase:` reading `PLAN (Plan — v<N> approved)`'

# The ONLY widening of that precondition, pinned in full so it cannot silently
# widen further: a carrier THIS MODE has already been executing (its own RUN
# marks on top of the intact freeze headers) re-enters through the resume
# rules — and anything else is refused, not worked around.
assert_file_contains "${command_file}" '— or a carrier this mode has already been executing, resumed per **Pauses, tripwires, and resume** below. Anything else is refused with a plain explanation, never worked around.'
assert_file_contains "${command_file}" "A carrier already carrying this mode's own marks — \`Phase:\` reading \`RUN\` — re-enters per the resume rules in **Pauses, tripwires, and resume**; recorded progress is picked up, never redone."

# Step 2's first-entry qualification: the same three requirements as checkable
# bullets.
assert_file_contains "${command_file}" 'A carrier qualifies on first entry only when all three hold:'
assert_file_contains "${command_file}" '- `Plan-version:` is present with a version number'
assert_file_contains "${command_file}" '- `Approval:` reads `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>` for that version'
assert_file_contains "${command_file}" '- `Phase:` reads `PLAN (Plan — v<N> approved)`'

# The refusals: unapproved routes to /velo:plan (Run never approves), done is
# finished work, an unrecognized shape is refused.
assert_file_contains "${command_file}" 'the plan is not frozen; suggest `/velo:plan` to review and approve it. Run never approves a plan itself and never runs an unapproved one.'
assert_file_contains "${command_file}" '**Done** — `Phase:` reads `DONE`, or the index row reads `done` → finished work; refuse and say so. A request to redo it is new work for `/velo:plan`.'
assert_file_contains "${command_file}" '**Not a plan carrier** — no `Plan-version:` key, or a shape Run does not recognize → refuse; Run consumes only carriers in the house format Plan writes.'

# Step 1: empty input lists the planned rows and asks — never an unprompted
# pick; ambiguous asks; missing/no-match stops without hunting.
assert_file_contains "${command_file}" '**Empty or whitespace-only input** → ask which plan to run, list the rows whose status is `planned` from `.velo/tasks/index.md`, and stop. Never pick a plan unprompted, however obvious the choice looks.'
assert_file_contains "${command_file}" '**Ambiguous** — the reference maps to more than one row → ask which one, and stop.'
assert_file_contains "${command_file}" '**No match, or the carrier is missing or unreadable** → say so plainly and stop. Do not hunt for a near-match to run instead.'

# --- 3. commands/run.md — the execution seam --------------------------------------

# Milestone-at-a-time, in carrier order — and "shipped" has exactly one
# marker, the ship bullet, so a milestone with all-done task lines but no ship
# bullet resumes at the gate (Step 6), never skipped past and never re-built.
assert_file_contains "${command_file}" 'Milestones run one at a time, in carrier order; the current milestone `M<i>` is the first not yet shipped'
assert_file_contains "${command_file}" "The ship bullet is the sole ship marker; a milestone whose task lines already all read \`done\` but whose ship bullet is missing resumes at Step 6's gate, not at Step 5."

# Execution-line batching is followed exactly, with needs: gating later
# batches.
assert_file_contains "${command_file}" "Follow \`M<i>\`'s \`Execution:\` line exactly: batch 1 first, a later batch only when the task lines its \`needs:\` name are \`done\`."
assert_file_contains "${command_file}" "On an agent host, task lines in the same batch may run in parallel; on a single-flow host they run in the batch's written order."

# Delegation to real subagents, with <agent> and skills: as ADVISORY labels —
# not machinery to hunt for.
assert_file_contains "${command_file}" 'Run delegates every task line to a real subagent.'
assert_file_contains "${command_file}" "The task line's \`<agent>\` label advises the kind of builder to use; its \`skills:\` labels advise the briefing. Both are advisory labels, not machinery to hunt for."

# The single-flow fallback is DISCLOSED before work starts — the exact
# disclosure sentence — and delegation is never faked.
assert_file_contains "${command_file}" 'Run states the fallback plainly before work starts: it will execute the task lines itself, in the same batch order, and the milestone review will therefore not be independent (recorded as such, per Step 6).'
assert_file_contains "${command_file}" 'Never pretend delegation happened when it did not.'

# The briefing never widens a task line beyond what the plan wrote.
assert_file_contains "${command_file}" 'The briefing never widens the line: a builder gets what the plan wrote, not improvised extras.'

# Plan body read-only + the exact allowed-writes list: Run's whole carrier
# write surface, enumerated in one sentence, and everything else read-only.
assert_file_contains "${command_file}" '**The plan body is read-only.**'
assert_file_contains "${command_file}" "Run writes ONLY progress marks: task-line \`Status:\` values, \`Phase:\`, \`Last gate passed:\`, \`Rework cycles:\`, \`Updated:\`, event bullets in \`## Constraints/notes\`, and the task's row in \`.velo/tasks/index.md\` — exact values per **Progress marks** below. Nothing else in the carrier, and nothing else under \`.velo/\`, changes in Run."
assert_file_contains "${command_file}" 'Everything else — every header key not named above, the brief, the assumptions, the constraints text, the milestones and task-line text, the `## Artifacts` section — is read-only in Run.'

# --- 4. commands/run.md — the done gate --------------------------------------------

# (a) checks run green — never assumed, inferred, or taken on a builder's word.
assert_file_contains "${command_file}" '**(a) Every executable check runs green.**'
assert_file_contains "${command_file}" "Green means run and observed, in this run, on this milestone's work — never assumed, never inferred from an earlier run, never taken from a builder's word."

# (b) exactly one independent adversarial review, with independence bound.
assert_file_contains "${command_file}" '**(b) One independent adversarial review passes.**'
assert_file_contains "${command_file}" 'Independence is the point: never reuse a builder as its own reviewer.'

# The single-flow variant is recorded as NOT independent, in the carrier and
# in the ship bullet.
assert_file_contains "${command_file}" 'records in the carrier that the review was NOT independent'
assert_file_contains "${command_file}" 'review passed (not independent — single flow)'

# Findings drive rework, recorded in the carrier header — and a check that
# stays red after in-scope rework is a tripwire, never ground through.
assert_file_contains "${command_file}" '`Rework cycles:` advances by one in the carrier header'
assert_file_contains "${command_file}" 'A required check that stays red after in-scope rework is a tripwire — pause; do not keep grinding, and do not widen scope to force green.'

# --- 5. commands/run.md — git scope, exactly ---------------------------------------

# The stack-when-unmerged branch-base sentence (the maintainer-decided v2
# delta), verbatim, in BOTH places it governs — the Hard Rule and Step 4's
# branch creation. An exact count so deleting it from either location fails,
# PLUS one location anchor per copy (a line-join substring tying the sentence
# to its surrounding contract text), so the sentence cannot drift out of the
# Hard Rule or Step 4 while a copy elsewhere keeps the count at 2.
stack_sentence="M1's branch cuts from the repository's default branch; M<i>'s branch cuts from the previous milestone's tip when that work is not yet on the default branch, else from the default branch."
assert_contains_count "${command_file}" "${stack_sentence}" 2
# Hard Rule anchor: the sentence follows the local-commit-with-evidence clause.
assert_file_contains "${command_file}" "commits that milestone's work locally with evidence in the message. M1's branch cuts from the repository's default branch;"
# Step 4 anchor: the sentence follows the create-and-switch instruction.
assert_file_contains "${command_file}" '(`<slug>-m<i>`) and switch to it. M1'\''s branch cuts from the repository'\''s default branch;'

# The allowed operations, bound exactly: the carrier-named milestone branch
# plus a local commit with evidence in the message.
assert_file_contains "${command_file}" "commits that milestone's work locally with evidence in the message"
assert_file_contains "${command_file}" '**Commit locally** on the milestone branch, with evidence in the message'

# The push/merge/PR/origin ban, in negation form — the entire git surface
# stops at the local commit.
assert_file_contains "${command_file}" "That is the entire git surface. Run never pushes, never merges, never opens a PR, and never touches origin in any way — shipping past the local commit is the maintainer's explicit call, made outside Run."

# Foreign history is a tripwire, a stacked base is not — and unrelated local
# changes are never stashed, reverted, or swept into a milestone commit.
assert_file_contains "${command_file}" "A branch already carrying that name that this run has no record of creating is a tripwire — pause and name it; never adopt foreign history (a stacked base — a tip the carrier's ship bullet records — is expected history, not foreign)."
assert_file_contains "${command_file}" "Unrelated local changes stay untouched: Run never stashes, reverts, or commits work that is not this milestone's."

# GIT-BIGRAM RESCOPE (carrier Constraints/notes): run.md legitimately
# DESCRIBES branching and committing in prose ("Create the branch", "Commit
# locally") — the contract above binds the allowed operations exactly. What
# stays banned, same as the ask/plan surfaces, is literal command bigrams:
# their presence would turn description into implementation steps. The set is
# the full widened list — the carrier explicitly requires `git merge` banned
# (task-breakdown.md Constraints/notes), and rebase/switch/remote close the
# same channel; every run surface file is verified clean of all nine.
git_impl_pattern='git commit|git push|git checkout|git branch|git merge|gh pr|git rebase|git switch|git remote'
for file in "${command_file}" "${skill_file}"; do
  if grep -qiE "${git_impl_pattern}" "${file}"; then
    fail "${file#${repo_root}/} must not carry literal git command bigrams — Run describes its git scope in prose and binds it by contract, not by command steps (matched: $(grep -oiE "${git_impl_pattern}" "${file}" | sort -u | tr '\n' ' '))"
  fi
done

# --- 5b. commands/run.md + SKILL.md — push/merge/PR/origin co-occurrence guard ------

# Closes the added-permissive-sentence channel for the one mode that runs git:
# presence pins above cannot see an ADDED sentence granting push/merge/PR/
# origin rights ("Run may also push to origin after the final ship."). Every
# line in either run surface file that mentions a push/merge/PR/origin concept
# must carry negation or ownership context on the same line — never/no/
# nothing/yours to call/maintainer — which every legitimate mention today does
# (they are all negations or maintainer-ownership statements). A permissive
# sentence has neither and fails.
git_concept_pattern='push|merg|origin|(^|[^A-Za-z])PRs?([^A-Za-z]|$)'
git_context_pattern='never|no |nothing|yours to call|maintainer'
for file in "${command_file}" "${skill_file}"; do
  offenders="$(grep -niE "${git_concept_pattern}" "${file}" | grep -viE "${git_context_pattern}" || true)"
  [[ -z "${offenders}" ]] \
    || fail "${file#${repo_root}/} mentions push/merge/PR/origin outside negation or maintainer-ownership context: ${offenders}"
done

# --- 6. commands/run.md — pauses, tripwires, and resume -----------------------------

# Material means what the Plan seam says it means — one shared definition.
assert_file_contains "${command_file}" "**Material means what the Plan seam says it means**: a change to the plan's deliverables or scope, affected surface, risk class, or required evidence."

# The Hard Rule's fail-closed summary: no silent widening, no improvising past
# a blocker, no resuming a material-change pause without a new freeze.
assert_file_contains "${command_file}" 'Run never widens scope silently, never improvises past a blocker, and never resumes a material-change pause without a newly frozen plan version.'

# The pause protocol, step by step: blocked mark, pause event bullet, paused
# Phase, and the route to /velo:plan.
assert_file_contains "${command_file}" '1. Mark the current task line `Status: blocked` (when one is in flight).'
assert_file_contains "${command_file}" '2. Append the pause event bullet naming the reason.'
assert_file_contains "${command_file}" '3. Set `Phase: RUN (Run — M<i> paused: <one clause>)` and advance `Updated:`.'
assert_file_contains "${command_file}" '4. Tell the user what paused, why, and the route: a material change goes to `/velo:plan` for a version bump and reapproval; a tripwire names the blocker to clear. Then stop.'

# The tripwire family, each bound by name.
assert_file_contains "${command_file}" '- a required check that stays red after in-scope rework'
assert_file_contains "${command_file}" '- the carrier missing, unreadable, or edited out from under the run mid-execution'
assert_file_contains "${command_file}" '- a conflicting dirty working tree, or a pre-existing branch carrying a milestone-branch name this run has no record of creating'

# Pausing preserves state — nothing discarded or rolled back.
assert_file_contains "${command_file}" 'Pausing preserves state: commits already made stay on their branches, `done` marks stay `done`, nothing is discarded or rolled back.'

# Resume, both gates in full. The material-change gate carries the
# freeze-header requirement (version bumped AND approval re-frozen through
# /velo:plan) — pinned as the whole sentence so the requirement cannot be
# quietly broadened away. The marks-survival sentence is the intentional seam
# with Plan: Plan's rule ("Status: is always pending when Plan writes a line",
# pinned in tests/plan-contract.test.sh) governs lines Plan writes; Run's rule
# here governs the recorded marks on lines a version bump carries forward.
assert_file_contains "${command_file}" 'A **material-change pause** resumes only on a newly frozen version: `Plan-version:` bumped and `Approval:` re-frozen through `/velo:plan`.'
assert_file_contains "${command_file}" 'The recorded marks survive the bump; a `blocked` line whose task text the new version kept returns to `pending` and re-enters the batch order.'
assert_file_contains "${command_file}" "A **tripwire pause** resumes once the recorded blocker is gone — the tree clean, the carrier intact, the red check's cause fixed within scope."
assert_file_contains "${command_file}" "If clearing it changed the plan's deliverables, surface, risk class, or required evidence, that is a material change: the Plan route first, then resume."
assert_file_contains "${command_file}" 'Never resume past a pause bullet whose cause still stands.'

# --- 7. commands/run.md — progress marks and completion -----------------------------

# The Status value set is closed, and the rest of the task line never changes.
# The rework transition (done → in-flight on gate findings) is named as a move
# WITHIN the same four values — not a fifth value.
assert_file_contains "${command_file}" '**task-line `Status:`** — moves `pending` → `in-flight` → `done`, or from `pending`/`in-flight` to `blocked` on a pause; a valid resume returns a `blocked` line to `pending`. Those four values, nothing else — and the rest of the task line never changes.'
assert_file_contains "${command_file}" 'Gate findings return a `done` line to `in-flight` (Step 6) — a rework transition within the same four values.'

# The Phase value set is closed: building, paused, DONE.
assert_file_contains "${command_file}" '- `RUN (Run — M<i> building)` — from the milestone'\''s open through its gate and any rework'
assert_file_contains "${command_file}" '- `RUN (Run — M<i> paused: <one clause>)` — a fail-closed pause, the clause naming the reason'
assert_file_contains "${command_file}" '- `DONE (Done — delivered-and-committed on <slug>-m<final>)` — after the final ship'

# The gate line written at each ship.
assert_file_contains "${command_file}" '`MILESTONE_SHIP (Milestone ship — M<i>)`, written at each ship.'

# Both event bullet formats, exactly — the ship bullet carries the commit
# reference, the pause bullet the blocked task and reason.
assert_file_contains "${command_file}" '- Ship: `- M<i> shipped · commit <short-hash> on <slug>-m<i> · checks green · review passed · <YYYY-MM-DD HH:MM>`'
assert_file_contains "${command_file}" '- Pause: `- M<i> paused · T<n> blocked · <one clause naming the reason> · <YYYY-MM-DD HH:MM>`'

# The index-row lifecycle: in-progress at the first open, done at the final
# ship, still in-progress while paused — and the flip is CONDITIONAL on the
# row still reading `planned`, so a resumed run never re-flips or resets it.
assert_file_contains "${command_file}" '**The index row** — `planned` → `in-progress` when the first milestone opens, → `done` at the final ship'
assert_file_contains "${command_file}" 'the flip to `in-progress` happens when a milestone opens and the row still reads `planned` — a resumed run leaves an `in-progress` row alone'
assert_file_contains "${command_file}" 'A paused run stays `in-progress`.'

# Completion: the DONE flip plus the index flip land together, and push/PR
# remain the maintainer's — announced, then a full stop.
assert_file_contains "${command_file}" 'the index row flipped to `done`'
assert_file_contains "${command_file}" 'Pushing, merging, or opening a PR is yours to call; nothing here ships past the local commits.'
assert_file_contains "${command_file}" 'Full stop means full stop: no pushing "since we'\''re done", no PR drafts, no starting another plan, no suggesting Auto.'

# No other mode: Auto stays out, and Run never plans — gaps route back to
# /velo:plan.
assert_file_contains "${command_file}" '**No other mode.** Auto does not exist in this build; Run never starts, simulates, or role-plays it. Run also never plans: a gap in the plan routes back to `/velo:plan`, never gets filled in on the fly.'

# --- 8. commands/run.md — fence pin and tool-name guard -----------------------------

# run.md's own fence-aware guard with its own pinned count (per the carrier:
# file-specific guards, never loosening plan.md's). T1 wrote run.md with ZERO
# fenced blocks — the bullet-format literals above live in inline code spans,
# not fences — so the pin is 0 and the guard below needs no fence exemptions.
# A new fenced block would open a blind spot in the guard, so it must arrive
# together with a reviewed update here.
fence_count="$(grep -c '^```' "${command_file}" || true)"
(( fence_count == 0 )) \
  || fail "commands/run.md gained a fenced block (expected 0 \`\`\` lines, found ${fence_count}) — re-review this tool-name guard's exemptions before accepting it"

# Second net under the precedence sentence, mirroring ask/plan's guards: an
# appended escape hatch invoking host tools by name ("when blocked, Edit the
# carrier...") must fail, not stay green. Exactly ONE line legitimately
# collides with a tool name — the "## Task" $ARGUMENTS slot, exempted as a
# whole line. There is no negated-line exemption: run.md names no tool even in
# negation (its delegation language is "subagent"/"builder", its git scope is
# prose), so ANY other capitalized tool name is an offender.
offenders="$(grep -nE '(^|[^A-Za-z])(Read|Grep|Glob|Bash|Task|WebFetch|WebSearch|Edit)([^A-Za-z]|$)' "${command_file}" \
  | grep -vE '^[0-9]+:## Task$' || true)"
[[ -z "${offenders}" ]] || fail "commands/run.md mentions a tool outside the ## Task heading: ${offenders}"

# --- 9. SKILL.md — the Codex wrapper binds the same contract -------------------------

# The wrapper's load order points at the real playbook (cross-checked to
# exist), and frames that read as mode bootstrap — the carve-out that keeps
# "read the playbook first" from contradicting anything.
assert_file_contains "${skill_file}" 'Read `commands/run.md`'
[[ -f "${command_file}" ]] || fail "SKILL.md points at commands/run.md, which must exist"
assert_file_contains "${skill_file}" 'reading it is mode bootstrap — loading the playbook, not yet running the plan'

# Self-contained: no hunting for V1 scaffolding.
assert_file_contains "${skill_file}" 'This wrapper is self-contained. Velo V2 has no AGENTS.md, ADAPTER.md, or PERSONA.md; do not go looking for them.'

assert_file_contains "${skill_file}" "the playbook's Hard Rule is the contract and applies verbatim"
assert_file_contains "${skill_file}" 'Do not treat this wrapper as an automatic Codex slash command.'

# The frozen-carrier preconditions and every refusal, duplicated inline so the
# contract survives even a Codex host that never resolves the playbook path.
assert_file_contains "${skill_file}" 'Run consumes ONLY a plan carrier Plan has frozen: `Plan-version:` present, `Approval:` reading `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>`, and `Phase:` reading `PLAN (Plan — v<N> approved)`.'
assert_file_contains "${skill_file}" 'An unapproved carrier gets a plain refusal and a suggestion to approve it via `/velo:plan`; a done carrier is finished work; a missing or ambiguous reference gets a question, not a guess; empty input gets the list of `planned` rows from `.velo/tasks/index.md` and a question — never an unprompted pick.'

# The read-only plan body and the progress-marks write surface, inline.
assert_file_contains "${skill_file}" 'The plan body is read-only: the brief, assumptions, constraints, milestones, and task-line text never change here.'
assert_file_contains "${skill_file}" 'Run writes only progress marks — task-line `Status:` (`pending` → `in-flight` → `done`/`blocked`), `Phase:`, `Last gate passed:`, `Rework cycles:`, `Updated:`, event bullets in `## Constraints/notes`, and the task'\''s index row (`planned` → `in-progress` → `done`) — with the exact values the playbook pins.'

# Codex is a single-flow host: the fallback disclosure applies, stated before
# any work starts, and the review is recorded as not independent.
assert_file_contains "${skill_file}" "Codex has no subagent mechanism, so the playbook's single-flow fallback applies: state plainly, before any work starts, that the task lines will be executed in this flow itself, in the same batch order, and that the milestone review will therefore not be independent."
assert_file_contains "${skill_file}" 'every executable check the plan or the repository defines runs green — run and observed, never assumed — plus one adversarial review of the milestone'\''s work against the carrier'
assert_file_contains "${skill_file}" "On Codex that review is a structured adversarial self-review, and the carrier's ship bullet records it as not independent (single flow)."

# The git scope inline: the stack-when-unmerged branch base verbatim, and the
# negation-form ban.
assert_file_contains "${skill_file}" "${stack_sentence}"
assert_file_contains "${skill_file}" "Never push, never merge, never open a PR, never touch origin — shipping past the local commit is the maintainer's explicit call."

# Pause fail-closed inline: the protocol, the no-silent-widening rule, and the
# tripwires.
assert_file_contains "${skill_file}" 'mark the current task line `blocked`, append a pause event bullet naming the reason, tell the user, and route to `/velo:plan` for a version bump and reapproval'
assert_file_contains "${skill_file}" 'Never widen scope silently; never resume a material-change pause without a newly frozen version.'
assert_file_contains "${skill_file}" 'a required check that stays red after in-scope rework, a carrier missing, unreadable, or edited out from under the run, and a conflicting dirty working tree'
# The branch-name-collision tripwire, appended to the wrapper's inline list in
# rework. Pinned as-is, double-"and" list tail included — the wording is
# cosmetic and T1's files are frozen this cycle; the pin tracks the file.
assert_file_contains "${skill_file}" 'and a pre-existing branch carrying a milestone-branch name the run has no record of creating'
assert_file_contains "${skill_file}" 'Pausing preserves state; nothing is discarded.'

# Completion inline: DONE phase, index flip, push/PR remain the maintainer's,
# full stop — and Auto stays out.
assert_file_contains "${skill_file}" 'set `Phase: DONE (Done — delivered-and-committed on <slug>-m<final>)`, flip the index row to `done`, announce that pushing, merging, and PRs remain the maintainer'\''s, and stop completely'
assert_file_contains "${skill_file}" 'Auto does not exist in this build; never start, invoke, simulate, or role-play it.'

# --- 10. No excluded-machinery text --------------------------------------------------

# Same ban list as the ask/plan suites, applied to the run surface files (the
# manifests are already banned in tests/ask-contract.test.sh — not duplicated
# here). Run's sanctioned vocabulary is "persisted"/"saved" and
# "subagent"/"builder"; the banned literals have no legitimate use, even
# negated, anywhere in this surface.
machinery_pattern='kernel|broker|docker|container|migration|persistence|evaluation'
for file in "${command_file}" "${skill_file}"; do
  if grep -qiE "${machinery_pattern}" "${file}"; then
    fail "${file#${repo_root}/} must not mention excluded machinery (matched: $(grep -oiE "${machinery_pattern}" "${file}" | sort -u | tr '\n' ' '))"
  fi
done

# Like the plan surface, the run surface has no negated "orchestration"
# mention, so the term is banned outright in both files.
for file in "${command_file}" "${skill_file}"; do
  if grep -qiE 'orchestr' "${file}"; then
    fail "${file#${repo_root}/} must not mention orchestration machinery"
  fi
done

echo "PASS: tests/run-contract.test.sh"

#!/usr/bin/env bash
# Behavioral-contract tests for Velo V2 Auto.
#
# Proves the span-not-pipeline, one-approval, quorum-gated contract is
# textually bound in both entrypoints (commands/auto.md for Claude Code,
# .agents/skills/velo-auto/SKILL.md for Codex): Auto as a span over the Plan
# and Run playbooks that forks nothing, the single explicit approval with no
# user relay after the freeze, the three-cold-reviewer 2-of-3 quorum gate with
# blocking-finding handling, the no-single-flow refusal (a refusal, not a
# fallback), the tripwire downgrade-to-Plan protocol, Run-parity git scope,
# and the completion protocol. Unlike Run's own suite, nothing here loosens a
# Run pin — Auto executes THROUGH the Run seam, so its git surface is bound
# the same way: prose descriptions allowed, command bigrams banned, and every
# push/merge/PR/origin mention forced into negation or ownership context.
#
# Assertions anchor on contract sentences T1 wrote deliberately (exact fixed
# strings via grep -F), not on incidental wording. Packaging/discoverability
# is covered by tests/auto-packaging.test.sh.
#
# Conventions follow V1 (velo/tests/*.test.sh): bash, set -euo pipefail, small
# fail/assert helpers.
set -euo pipefail

# Deterministic character ranges (the tool-name guard below) and sort order
# regardless of the host locale.
export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command_file="${repo_root}/commands/auto.md"
skill_file="${repo_root}/.agents/skills/velo-auto/SKILL.md"

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

# --- 1. commands/auto.md — Hard Rule and precedence ---------------------------------

# The contract section must exist under its own unambiguous heading, not be
# scattered as incidental prose.
assert_file_contains "${command_file}" '## Hard Rule — One Approval, Quorum-Gated Milestones, Never a Silent Continue'

# Precedence: the contract must declare that nothing elsewhere in the file
# overrides it — presence-only assertions cannot see ADDED contradictory text,
# but this sentence makes any later "escape hatch" paragraph non-binding.
assert_file_contains "${command_file}" 'This contract is absolute. No instruction elsewhere in this file, no user phrasing, and no runtime convenience overrides it.'

# --- 2. commands/auto.md — a span over the shipped seams, not a third pipeline ------

# The identity sentence: Auto drives the Plan playbook to a frozen carrier,
# then the Run playbook across every milestone — and both playbook paths are
# cross-checked to exist, so the span cannot dangle.
assert_file_contains "${command_file}" 'Auto is a span over the two shipped seams, not a third pipeline: it drives the Plan playbook (`commands/plan.md`) to a versioned, frozen plan carrier, then drives the Run playbook (`commands/run.md`) across every milestone of that plan.'
[[ -f "${repo_root}/commands/plan.md" ]] || fail "commands/auto.md spans the Plan playbook at commands/plan.md, which must exist"
[[ -f "${repo_root}/commands/run.md" ]] || fail "commands/auto.md spans the Run playbook at commands/run.md, which must exist"

# Exactly two deltas, and nothing forked — the sentence that keeps Auto from
# growing a third behavioral difference silently.
assert_file_contains "${command_file}" 'Auto adds exactly two deltas: no user relay after the freeze, and a stricter per-milestone review gate — the quorum. Nothing else differs, and Auto forks nothing.'

# The Hard Rule's span bullet: contracts, refusals, write scopes, and pause
# rules apply verbatim; autonomous never means quieter; nothing invented.
assert_file_contains "${command_file}" '**A span, not a pipeline.** Auto invokes the Plan playbook and the Run playbook and never forks them: their contracts, refusals, write scopes, and pause rules apply verbatim inside Auto.'
assert_file_contains "${command_file}" 'Where a playbook says pause and tell the user, Auto pauses and tells the user — that IS the downgrade; autonomous never means quieter.'
assert_file_contains "${command_file}" 'Auto invents no carrier format, no header keys, and no progress marks of its own.'

# Step 4's "two differences and no others" neighborhood: the execution leg is
# the Run playbook exactly as written, the review delta is the ONLY behavioral
# delta, and everything else is Run's verbatim.
assert_file_contains "${command_file}" 'Execute the frozen carrier through the Run playbook, exactly as written, with two differences and no others:'
assert_file_contains "${command_file}" 'Run'\''s one-independent-review gate is replaced by the three-cold-reviewer quorum in **The quorum gate** below — the ONLY behavioral delta from Run.'
assert_file_contains "${command_file}" 'This gate replaces Run'\''s one-reviewer gate and is the ONLY behavioral delta Auto brings to execution.'
assert_file_contains "${command_file}" 'Auto forks nothing: where the Run playbook says pause and tell the user, Auto pauses and tells the user.'

# The four-mode surface sentence and the one-span-per-invocation scope.
assert_file_contains "${command_file}" 'This build of Velo ships Ask, Plan, Run, and Auto — the complete surface; every mode is a command to invoke.'
assert_file_contains "${command_file}" 'Auto executes exactly one span per invocation — the request or plan the user names.'

# --- 3. commands/auto.md — routing: empty input, pure questions, frozen carriers ----

# Empty input asks and stops — never invented work, never an unprompted pick.
assert_file_contains "${command_file}" '**Empty or whitespace-only input** → ask what to deliver autonomously and stop'
assert_file_contains "${command_file}" 'Never invent work, pick a plan unprompted, or start reading around to guess at intent.'

# A pure question is SUGGESTED to /velo:ask — named as the route, never
# invoked, and never answered in Ask's place.
assert_file_contains "${command_file}" '**A pure question** — conceptual, answerable without delivering anything → name `/velo:ask` as the route, in a sentence, and stop.'
assert_file_contains "${command_file}" 'Auto delivers work; it never turns a question into work unasked, and it never answers in Ask'\''s place.'

# Frozen-carrier intake, pinned as written: the standing freeze IS the one
# approval, and naming the frozen plan is the user's instruction to deliver it
# — Auto skips the planning leg and asks for no second confirmation. This is
# the carrier's deliberate reading (assumption "empty input"), not a loophole:
# the freeze verification is Run's, verbatim, and every non-frozen shape falls
# out below.
assert_file_contains "${command_file}" 'skip the planning leg: the standing freeze is the one approval, and naming the frozen plan to Auto is the user'\''s instruction to deliver it.'
assert_file_contains "${command_file}" '(`Plan-version:` present, `Approval:` reading `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>` for that version, `Phase:` reading `PLAN (Plan — v<N> approved)`)'
assert_file_contains "${command_file}" 'Say in one line which plan and version is about to be delivered autonomously, then take Step 2 and continue at Step 4.'

# ...and the non-frozen shapes: ambiguous asks, unapproved plans (naming is
# never approving), done carriers refuse.
assert_file_contains "${command_file}" 'An ambiguous reference gets a question, not a guess.'
assert_file_contains "${command_file}" 'An unapproved carrier takes the planning leg instead — Auto never treats naming a plan as approving it.'
assert_file_contains "${command_file}" 'A done carrier is finished work — refuse, per the Run playbook.'

# --- 4. commands/auto.md — the no-single-flow refusal --------------------------------

# The host check happens before either leg, and an agent host is disclosed per
# Run's disclosure rule.
assert_file_contains "${command_file}" 'Before either leg starts, confirm what the host allows, once per span:'
assert_file_contains "${command_file}" '**Agent host** — the host offers a real subagent mechanism → say so in one line, per the Run playbook'\''s disclosure, and proceed.'

# The refusal, in BOTH places it lives — the Hard Rule bullet and Step 2 —
# each anchored to its own surrounding text, plus exact counts on the two
# load-bearing clauses so deleting either copy (or rewriting one into fallback
# language) fails. A mutation replacing "refuses" with a fallback cannot keep
# these pins green: "This is a refusal, not a fallback" must appear exactly
# twice, and "single-flow Auto does not exist" exactly twice. NOTE the counts'
# limit: they catch deletions and rewrites of the existing copies, but an
# ADDED contradictory sentence elsewhere ("on a constrained host a single-flow
# Auto may proceed with self-review") is not caught mechanically — it is
# mitigated by the precedence pin in section 1, which makes any later
# escape-hatch paragraph non-binding. The single-flow line-count pin below
# narrows that window: any NEW line mentioning single-flow moves the count and
# forces a review here.
assert_file_contains "${command_file}" '**No single-flow Auto.** On a host without a real subagent mechanism, Auto refuses autonomous execution outright — a single flow cannot provide three independent cold reviews, so single-flow Auto does not exist.'
assert_file_contains "${command_file}" 'This is a refusal, not a fallback: refuse plainly and offer `/velo:plan` or an attended `/velo:run` instead.'
assert_file_contains "${command_file}" '**Host without subagents** → refuse autonomous execution outright, in a sentence or two: a single flow cannot provide three independent cold reviews, so single-flow Auto does not exist. This is a refusal, not a fallback.'
assert_contains_count "${command_file}" 'This is a refusal, not a fallback' 2
assert_contains_count "${command_file}" 'single-flow Auto does not exist' 2

# Exactly TWO lines in auto.md may mention single-flow at all (the Hard Rule
# bullet and Step 2's host check — verified). A third line talking about
# single-flow behavior, whatever it says, arrives only together with a
# reviewed update to this pin.
single_flow_lines="$(grep -icE 'single.flow' "${command_file}" || true)"
(( single_flow_lines == 2 )) \
  || fail "commands/auto.md must mention single-flow on exactly 2 lines (found ${single_flow_lines}) — a new single-flow sentence must arrive with a reviewed update here"

# The refusal's teeth: no thinned quorum, no substituted self-review, no faked
# delegation — and the attended routes offered instead.
assert_file_contains "${command_file}" 'Never quietly thin the quorum, substitute self-review, or pretend delegation happened.'
assert_file_contains "${command_file}" 'Offer the attended routes instead — `/velo:plan` to turn the request into a saved, frozen plan, or `/velo:run` to execute an already-frozen plan under its own disclosed single-flow rules — and stop.'

# --- 5. commands/auto.md — the one approval, and no relay after the freeze -----------

# The Hard Rule bullet: the approval is Plan's explicit affirmative, verbatim,
# and nothing is ever auto-approved. "nothing is ever auto-approved" must hold
# in BOTH locations (Hard Rule + Step 3) — exact count.
assert_file_contains "${command_file}" '**The one approval.** Auto presents the plan and waits for the explicit affirmative exactly as Plan does; only an unambiguous yes freezes the version, and nothing is ever auto-approved.'
assert_file_contains "${command_file}" 'Only an explicit affirmative — "approve", "approved", "yes, freeze it", or an equally unambiguous yes — freezes the version; a compliment, a question, silence, or "looks good, but…" is not approval, and nothing is ever auto-approved.'
assert_contains_count "${command_file}" 'nothing is ever auto-approved' 2

# The planning leg is Plan's, end to end — its rules verbatim, its three
# choices offered — and the presentation says what approval starts, so the
# user approves the plan and the autonomy knowingly.
assert_file_contains "${command_file}" 'Drive the Plan playbook end to end, exactly as written'
assert_file_contains "${command_file}" 'offer Plan'\''s three choices — approve, revise, stop and save'
assert_file_contains "${command_file}" 'Every Plan rule holds verbatim inside Auto: `.velo/`-only writes, the carrier format, versioning, materiality.'
assert_file_contains "${command_file}" 'approving this plan starts autonomous delivery — every milestone, without further check-ins, under the quorum gate'
assert_file_contains "${command_file}" 'stop-and-save keeps the carrier on disk unapproved and ends the span — nothing runs.'

# The freeze announcement is Auto's, not Plan's: it announces delivery
# starting, never a run awaiting the user — Plan's ready-to-start wording
# belongs to a user-started Plan, and under Auto nothing awaits starting.
assert_file_contains "${command_file}" '**The freeze announces delivery, not readiness.** On the freeze, the announcement says autonomous delivery is starting — not that a run awaits the user'
assert_file_contains "${command_file}" 'Plan'\''s ready-to-start wording belongs to a user-started Plan, and under Auto nothing awaits starting.'

# The no-relay half, pinned separately from the approval half: after the
# freeze Auto proceeds through ALL milestones without pausing for user input,
# the approval is the SINGLE point of user relay, and the user can always
# interrupt.
assert_file_contains "${command_file}" 'After the freeze there is no further user relay: Auto proceeds through ALL milestones without pausing between handoffs or between milestones for user input.'
assert_file_contains "${command_file}" 'The user may interrupt at any time, and any tripwire re-involves them.'
assert_file_contains "${command_file}" 'The approval is the single point of user relay in an Auto span.'
assert_file_contains "${command_file}" '**No relay between milestones.**'
assert_file_contains "${command_file}" 'it just never waits for permission the freeze already granted'

# RELAY CO-OCCURRENCE NET: presence pins cannot see an ADDED courtesy check-in
# sentence ("Between milestones, Auto offers a brief check-in..."). Every line
# in auto.md that mentions a relay concept — a check-in, a confirmation, or
# waiting for the user — must carry negation context on the same line (never/
# no/without), which the one legitimate mention today does ("without further
# check-ins"). Step 2's host check ("confirm what the host allows") does not
# match the concept pattern today; it is excluded by name anyway so a future
# widening of the concept set cannot misfire on it.
relay_concept_pattern='check-?in|confirmation|wait for the user'
relay_context_pattern='never|no |without'
relay_offenders="$(grep -niE "${relay_concept_pattern}" "${command_file}" \
  | grep -viE "${relay_context_pattern}" \
  | grep -viE 'confirm what the host' || true)"
[[ -z "${relay_offenders}" ]] \
  || fail "commands/auto.md mentions a user check-in/confirmation/wait outside negation context — the freeze is the single point of user relay: ${relay_offenders}"

# The Planned-via seam: a carrier the planning leg creates records the Auto
# span through Plan's own header key — set at creation, never rewritten — and
# the What-Auto-writes section repeats it as a Plan-authored value.
assert_file_contains "${command_file}" 'A carrier this planning leg creates records `Planned-via: /velo:auto (Plan seam)` — the same header key the Plan playbook always writes'
assert_file_contains "${command_file}" 'a re-opened carrier keeps its standing value, since the key is set at creation and never rewritten'
assert_file_contains "${command_file}" 'Plan-authored values at plan time (including `Planned-via: /velo:auto (Plan seam)` on a carrier the planning leg created)'

# --- 6. commands/auto.md — the quorum gate --------------------------------------------

# The Hard Rule bullet: green checks AND three independent cold reviews, at
# least 2 of 3, no unresolved blocking finding from ANY reviewer — the
# dissenter's blocking finding still blocks.
assert_file_contains "${command_file}" '**The quorum gate.** A milestone is done only when every executable check runs green — run and observed, never assumed — AND three independent cold reviews pass at least 2 of 3 with no unresolved blocking finding from ANY reviewer; a blocking finding from the dissenting third still blocks.'

# The checks half is Run's rule unchanged — never assumed, never inferred,
# never taken from a builder's word.
assert_file_contains "${command_file}" '**(a) Every executable check runs green** — the Run playbook'\''s rule, unchanged'
assert_file_contains "${command_file}" 'never assumed, never inferred from an earlier run, never taken from a builder'\''s word.'

# The review half, with cold and independent defined OPERATIONALLY: no builder
# overlap, carrier+evidence-only briefs, three separately spawned reviewers,
# verdicts collected before compared.
assert_file_contains "${command_file}" '**(b) Three independent cold reviews pass at least 2 of 3, with no unresolved blocking finding.**'
assert_file_contains "${command_file}" 'Cold and independent mean something operational, not a mood:'
assert_file_contains "${command_file}" '**Cold** — the reviewer had no hand in building the milestone: never a builder of any of this milestone'\''s task lines, and briefed ONLY from the frozen carrier and the milestone'\''s evidence'
assert_file_contains "${command_file}" 'Never from a builder'\''s reasoning, another reviewer'\''s verdict, or the running conversation.'
assert_file_contains "${command_file}" '**Independent** — three separately spawned reviewer subagents, one per review, each with its own isolated brief; no reviewer sees another'\''s verdict, findings, or existence before all three have submitted.'
assert_file_contains "${command_file}" 'Verdicts are collected first and compared only after the third arrives — no shared verdicts before all three submit.'

# Each review is one adversarial pass against the carrier, with findings
# marked blocking or advisory.
assert_file_contains "${command_file}" 'Each reviewer makes one adversarial pass against the carrier — deliverables delivered, assumptions respected, constraints held, nothing beyond scope, actively hunting for what is missing or wrong — and submits a verdict, pass or fail, plus findings, each marked blocking or advisory.'

# The pass rule: 2-of-3 AND no unresolved blocking finding — even from the
# dissenting third, even at 2 of 3.
assert_file_contains "${command_file}" '**The gate passes** only when at least 2 of the 3 passes are a pass AND no blocking finding from ANY reviewer stands unresolved — a blocking finding from the dissenting third still blocks, even at 2 of 3.'

# The fail rule: rework (recorded) or a pause, NEVER a silent continue — and a
# rework re-review is a FRESH quorum of three newly spawned reviewers, never a
# revote by the previous three.
assert_file_contains "${command_file}" 'A failed quorum or an unresolved blocking finding is rework (recorded) or a pause — never a silent continue.'
assert_file_contains "${command_file}" '**The gate fails** into rework or a pause, never a silent continue:'
assert_file_contains "${command_file}" '`Rework cycles:` advanced by one in the carrier header, the checks re-run — then a fresh quorum: three newly spawned cold reviewers, never a revote by the previous three.'
assert_file_contains "${command_file}" 'is a pause per **Pauses, downgrades, and resume**, its reason recorded as `quorum failed (<n>/3)`'
assert_file_contains "${command_file}" 'an unresolved blocking finding can fail the gate at any count.'

# Verdict recording, inside Run's own event-bullet formats — no new formats
# invented, only the review clause replaced.
assert_file_contains "${command_file}" 'The one Auto-specific text is the review clause inside the Run playbook'\''s own event-bullet formats:'
assert_file_contains "${command_file}" 'the bullet'\''s review clause reads `review passed (quorum 3/3)` or `review passed (quorum 2/3)` — the quorum verdict in place of the plain clause; everything else in the ship bullet is the Run playbook'\''s format, unchanged'
assert_file_contains "${command_file}" '- Pause on quorum failure: the bullet'\''s reason clause reads `quorum failed (<n>/3)`'

# Auto writes nothing of its own — carriers change only through the playbooks
# it drives.
assert_file_contains "${command_file}" 'Nothing of its own. Auto writes carriers only through the playbooks it drives:'
assert_file_contains "${command_file}" 'no new header keys, no new statuses, no new phases.'

# QUORUM DENOMINATOR NET: the format pins above fix the sanctioned verdict
# strings, but an ADDED sentence carrying a different quorum arithmetic
# ("a quorum 2/2 also satisfies the gate") would ride past presence pins.
# Every literal `quorum <a>/<b>` in either auto surface file must have
# denominator 3, and no line may pair "quorum" with a one- or two-reviewer
# panel — the quorum is three reviewers, always.
for file in "${command_file}" "${skill_file}"; do
  bad_denominators="$(grep -noiE 'quorum [0-9]+/[0-9]+' "${file}" | grep -v '/3$' || true)"
  [[ -z "${bad_denominators}" ]] \
    || fail "${file#${repo_root}/} carries a quorum verdict whose denominator is not 3 — the quorum is three cold reviewers, always: ${bad_denominators}"
  bad_panels="$(grep -niE 'quorum' "${file}" | grep -iE '(two|one) reviewers?([^A-Za-z]|$)' || true)"
  [[ -z "${bad_panels}" ]] \
    || fail "${file#${repo_root}/} pairs the quorum with a one- or two-reviewer panel — the quorum is three cold reviewers, always: ${bad_panels}"
done

# --- 7. commands/auto.md — tripwires, downgrade to Plan, and resume -------------------

# The Hard Rule bullet: Run's pause family unchanged plus quorum failure, and
# every pause downgrades to the Plan seam.
assert_file_contains "${command_file}" '**Fail-closed, downgraded to Plan.** Auto inherits Run'\''s pause family unchanged, plus quorum failure.'

# The full family, enumerated — Run's five tripwires plus Auto's own quorum
# failure.
assert_file_contains "${command_file}" 'a material change surfaced mid-span, a required check that stays red after in-scope rework, a carrier missing, unreadable, or edited out from under the span, a conflicting dirty working tree, a pre-existing branch carrying a milestone-branch name this span has no record of creating — plus one of Auto'\''s own: **quorum failure**'

# The downgrade protocol is Run's own pause protocol, routed to /velo:plan for
# an informed decision — bump and reapproval when material.
assert_file_contains "${command_file}" 'Every pause downgrades to the Plan seam, through the Run playbook'\''s own protocol: the current task line marked `Status: blocked` (when one is in flight), the pause event bullet naming the reason, the paused `Phase:`, `Updated:` advanced'
assert_file_contains "${command_file}" '`/velo:plan` re-opens the paused carrier for an informed decision, with a version bump and reapproval when the change is material.'

# Pausing preserves state, and a user interruption is honored the same way.
assert_file_contains "${command_file}" 'Pausing preserves state; nothing is discarded or rolled back.'
assert_file_contains "${command_file}" 'A user interruption is honored the same way: stop cleanly, record where the span stood, lose nothing.'

# Never-resume-past-an-unsatisfied-gate, in BOTH locations (Hard Rule + the
# Resume section) — exact count — plus both resume gates in full and the
# closing rule.
assert_contains_count "${command_file}" 'Auto never resumes past a pause without the recorded gate satisfied' 2
assert_file_contains "${command_file}" 'A **material-change pause** resumes only on a newly frozen version — `Plan-version:` bumped and `Approval:` re-frozen through `/velo:plan`; that reapproval is itself an explicit affirmative, taken exactly as the one approval is.'
assert_file_contains "${command_file}" 'A **tripwire or quorum pause** resumes once the recorded blocker is gone'
assert_file_contains "${command_file}" 'If clearing it changed the plan'\''s deliverables, surface, risk class, or required evidence, that is a material change: the Plan route first, then resume.'
assert_file_contains "${command_file}" 'Never resume past a pause bullet whose cause still stands.'

# Resume picks up recorded state, done work is never redone, and the carrier
# belongs to the seams — an attended Run may equally resume it.
assert_file_contains "${command_file}" '`done` work is never redone'
assert_file_contains "${command_file}" 'The user may equally resume a paused carrier through an attended `/velo:run`; the carrier belongs to the seams, not to Auto.'

# --- 8. commands/auto.md — git scope, exactly Run's -----------------------------------

# The Hard Rule bullet: carrier-named branches per Run's base rule, local
# commits with evidence — the ENTIRE git surface — and the push/merge/PR/
# origin ban in negation form.
assert_file_contains "${command_file}" '**Repository scope, exactly Run'\''s.** Carrier-named milestone branches, cut per the Run playbook'\''s base rule, and local commits with evidence in the message — that is the entire git surface. Auto never pushes, never merges, never opens a PR, and never touches origin in any way; shipping past the local commits is the maintainer'\''s explicit call, made outside Auto.'

# Step 4 carries Run's branch-base rule inline — the stack-when-unmerged rule
# in Auto's own words, tied to the carrier-named milestone branch.
assert_file_contains "${command_file}" 'the milestone branch the carrier names — M1'\''s cut from the repository'\''s default branch, a later milestone'\''s from the previous milestone'\''s tip when that work is not yet on the default branch, else from the default branch'

# GIT-BIGRAM BAN (same set as tests/run-contract.test.sh): auto.md and the
# wrapper legitimately DESCRIBE branching and committing in prose; literal
# command bigrams would turn description into implementation steps. All nine
# banned in both files.
git_impl_pattern='git commit|git push|git checkout|git branch|git merge|gh pr|git rebase|git switch|git remote'
for file in "${command_file}" "${skill_file}"; do
  if grep -qiE "${git_impl_pattern}" "${file}"; then
    fail "${file#${repo_root}/} must not carry literal git command bigrams — Auto executes through the Run seam and binds its git scope by contract, not by command steps (matched: $(grep -oiE "${git_impl_pattern}" "${file}" | sort -u | tr '\n' ' '))"
  fi
done

# PUSH/MERGE/PR/ORIGIN CO-OCCURRENCE NET (the run-contract 5b pattern,
# extended to the auto surface): presence pins above cannot see an ADDED
# permissive sentence ("Auto may also push to origin after the final ship.").
# Every line in either auto surface file that mentions a push/merge/PR/origin
# concept must carry negation or ownership context on the same line — never /
# a git-negation ("no push"/"no pushing"/"no PR(s)") / nothing / yours to
# call / maintainer — which every legitimate mention today does. The context
# set is deliberately NARROW: a bare "no " once counted as context, which let
# a permissive sentence ride on an incidental negation elsewhere in the line
# ("...once there are no unresolved findings" — mutant B5); the git-scoped
# forms close that. A permissive sentence has none of these and fails.
git_concept_pattern='push|merg|origin|(^|[^A-Za-z])PRs?([^A-Za-z]|$)'
git_context_pattern='never|no push|no pushing|no PRs?|nothing|yours to call|maintainer'
for file in "${command_file}" "${skill_file}"; do
  offenders="$(grep -niE "${git_concept_pattern}" "${file}" | grep -viE "${git_context_pattern}" || true)"
  [[ -z "${offenders}" ]] \
    || fail "${file#${repo_root}/} mentions push/merge/PR/origin outside negation or maintainer-ownership context: ${offenders}"
done

# --- 9. commands/auto.md — completion protocol ----------------------------------------

# Completion is Run's: ship bullets with commit references and quorum
# verdicts, the DONE phase, the index flip — then announce and a full stop.
assert_file_contains "${command_file}" 'Completion is identical to Run'\''s.'
assert_file_contains "${command_file}" '`Phase: DONE (Done — delivered-and-committed on <slug>-m<final>)`'
assert_file_contains "${command_file}" 'the index row flipped to `done`'
assert_file_contains "${command_file}" 'all <n> milestones shipped under the quorum gate, each committed locally on its own branch'
assert_file_contains "${command_file}" 'Pushing, merging, or opening a PR is yours to call; nothing here ships past the local commits.'
assert_file_contains "${command_file}" 'Full stop means full stop: no pushing "since we'\''re done", no PR drafts, no starting another plan, no planning follow-on work unasked.'
assert_file_contains "${command_file}" 'The conversation may continue; the span is over.'

# --- 10. commands/auto.md — fence pin and tool-name guard ------------------------------

# auto.md's own fence-aware guard with its own pinned count (per the carrier:
# file-specific guards, never loosening plan.md's). T1 wrote auto.md with ZERO
# fenced blocks — every format literal lives in inline code spans — so the pin
# is 0 and the guard below needs no fence exemptions. A new fenced block would
# open a blind spot in the guard, so it must arrive together with a reviewed
# update here.
fence_count="$(grep -c '^```' "${command_file}" || true)"
(( fence_count == 0 )) \
  || fail "commands/auto.md gained a fenced block (expected 0 \`\`\` lines, found ${fence_count}) — re-review this tool-name guard's exemptions before accepting it"

# Second net under the precedence sentence, mirroring the run guard: an
# appended escape hatch invoking host tools by name ("when blocked, Edit the
# carrier...") must fail, not stay green. Exactly ONE line legitimately
# collides with a tool name — the "## Task" $ARGUMENTS slot, exempted as a
# whole line. There is no negated-line exemption: auto.md names no tool even
# in negation (its delegation language is "subagent"/"reviewer"/"builder", its
# git scope is prose), so ANY other capitalized tool name is an offender.
# "Write" is in the alternation: auto.md has no capitalized Write (verified),
# so an appended "Write the carrier..." escape hatch fails here.
offenders="$(grep -nE '(^|[^A-Za-z])(Read|Grep|Glob|Bash|Task|WebFetch|WebSearch|Edit|Write)([^A-Za-z]|$)' "${command_file}" \
  | grep -vE '^[0-9]+:## Task$' || true)"
[[ -z "${offenders}" ]] || fail "commands/auto.md mentions a tool outside the ## Task heading: ${offenders}"

# --- 11. SKILL.md — the Codex wrapper binds the same contract --------------------------

# The wrapper's load order points at the real playbook (cross-checked to
# exist), frames that read as mode bootstrap, and extends the same carve-out
# to the Plan and Run playbooks Auto drives.
assert_file_contains "${skill_file}" 'Read `commands/auto.md`'
[[ -f "${command_file}" ]] || fail "SKILL.md points at commands/auto.md, which must exist"
assert_file_contains "${skill_file}" 'reading it is mode bootstrap — loading the playbook, not yet delivering anything'
assert_file_contains "${skill_file}" 'The Auto playbook drives the Plan playbook (`commands/plan.md`) and the Run playbook (`commands/run.md`) from the same plugin root; loading each of those when Auto reaches its leg is the same bootstrap carve-out'

# Self-contained: no hunting for V1 scaffolding.
assert_file_contains "${skill_file}" 'This wrapper is self-contained. Velo V2 has no AGENTS.md, ADAPTER.md, or PERSONA.md; do not go looking for them.'

assert_file_contains "${skill_file}" "the playbook's Hard Rule is the contract and applies verbatim"
assert_file_contains "${skill_file}" 'Do not treat this wrapper as an automatic Codex slash command.'

# THE bold Codex bullet: Codex has no subagent mechanism, so velo:auto refuses
# autonomous execution — a refusal, not a fallback — with the quorum never
# thinned, never simulated inside one flow, delegation never faked, and the
# attended routes offered instead.
assert_file_contains "${skill_file}" '**Codex has no subagent mechanism, so on Codex velo:auto must refuse autonomous execution — say that plainly and offer plan or attended run instead.**'
assert_file_contains "${skill_file}" 'a single flow cannot provide independent cold review, so single-flow Auto does not exist'
assert_file_contains "${skill_file}" 'This is a refusal, not a fallback: never quietly thin the quorum to a self-review, never simulate three reviewers inside one flow, never pretend delegation happened.'
assert_file_contains "${skill_file}" 'Offer `/velo:plan` (turn the request into a saved, frozen plan) or an attended `/velo:run` (execute an already-frozen plan under Run'\''s own disclosed single-flow rules) instead, and stop.'

# The span rule inline: not a third pipeline, both playbooks verbatim, nothing
# forked or invented.
assert_file_contains "${skill_file}" 'Auto is a span over the Plan and Run seams, not a third pipeline.'
assert_file_contains "${skill_file}" 'both playbooks'\'' contracts apply verbatim inside Auto, and Auto forks neither, invents no carrier format, and writes no marks of its own beyond what those playbooks pin.'

# The one approval and the no-relay-after rule inline — both halves.
assert_file_contains "${skill_file}" 'The one approval: Auto presents the plan and waits for the explicit affirmative exactly as Plan does — only an unambiguous yes freezes the version, and nothing is ever auto-approved.'
assert_file_contains "${skill_file}" 'After the freeze there is no further user relay: Auto proceeds through every milestone without pausing between handoffs or between milestones for user input'

# Intake inline: empty input, pure questions to /velo:ask, frozen carriers
# skipping the planning leg (host permitting), unapproved carriers taking the
# planning leg — never a silent approval.
assert_file_contains "${skill_file}" 'Intake: empty input → ask what to deliver autonomously and stop; a pure conceptual question → name `/velo:ask` as the route and stop'
assert_file_contains "${skill_file}" 'a request naming an existing frozen carrier → skip the planning leg and — on a host that can run Auto at all — execute it under Auto'\''s gate, since the standing freeze is the one approval'
assert_file_contains "${skill_file}" 'an unapproved carrier takes the planning leg and the explicit approval, never a silent one'

# The quorum gate inline: threshold, dissenter's blocking finding, operational
# cold/independent definitions, rework recording, fresh quorum — and the
# verdict formats.
assert_file_contains "${skill_file}" 'every executable check runs green — run and observed, never assumed — PLUS three independent cold reviews passing at least 2 of 3 with no unresolved blocking finding from ANY reviewer; a blocking finding from the dissenting third still blocks.'
assert_file_contains "${skill_file}" 'Cold means the reviewer had no hand in building the milestone and is briefed only from the frozen carrier and the milestone'\''s evidence; independent means separately spawned, with no shared verdicts before all three submit.'
assert_file_contains "${skill_file}" 'A failed quorum or an unresolved blocking finding is rework (recorded — `Rework cycles:` advances) or a pause, never a silent continue; a rework re-review is a fresh quorum, never a revote.'
assert_file_contains "${skill_file}" 'ship bullets carry `review passed (quorum 3/3)` or `review passed (quorum 2/3)`; a quorum pause names `quorum failed (<n>/3)`.'

# Tripwires and downgrade inline: Run's family plus quorum failure, the
# downgrade to the Plan seam, and never resuming past an unsatisfied gate.
assert_file_contains "${skill_file}" 'Tripwires and downgrade: Run'\''s fail-closed pause family unchanged plus quorum failure; every pause downgrades to the Plan seam — pause bullet, `blocked` mark, route to `/velo:plan` for an informed decision, a version bump and reapproval when the change is material — and Auto never resumes past a pause without the recorded gate satisfied.'

# Git scope inline: identical to Run's, ban in negation form.
assert_file_contains "${skill_file}" 'Repository scope, identical to Run'\''s: carrier-named milestone branches and local commits with evidence in the message; Auto never pushes, never merges, never opens a PR, never touches origin — shipping past the local commit is the maintainer'\''s explicit call.'

# Completion inline: Run's protocol, the maintainer's call, a complete stop.
assert_file_contains "${skill_file}" 'Completion, identical to Run'\''s: ship bullets per milestone with commit references, then `Phase: DONE (Done — delivered-and-committed on <slug>-m<final>)`, the index row flipped to `done`, an announcement that pushing, merging, and PRs remain the maintainer'\''s — and a complete stop.'

# The Codex-mapping escape stays closed for the subagent requirement itself:
# no native mapping exists, so the answer stays the refusal.
assert_file_contains "${skill_file}" 'except the subagent requirement itself, which has no Codex-native mapping: on Codex the answer stays the refusal above.'

# --- 12. No excluded-machinery text -----------------------------------------------------

# Same ban list as the ask/plan/run suites, applied to the auto surface files
# (the manifests are already banned in tests/ask-contract.test.sh — not
# duplicated here). Auto's sanctioned vocabulary is "span"/"seam"/"subagent"/
# "reviewer"; the banned literals have no legitimate use, even negated,
# anywhere in this surface.
machinery_pattern='kernel|broker|docker|container|migration|persistence|evaluation'
for file in "${command_file}" "${skill_file}"; do
  if grep -qiE "${machinery_pattern}" "${file}"; then
    fail "${file#${repo_root}/} must not mention excluded machinery (matched: $(grep -oiE "${machinery_pattern}" "${file}" | sort -u | tr '\n' ' '))"
  fi
done

# Like the plan and run surfaces, the auto surface has no negated
# "orchestration" mention, so the term is banned outright in both files.
for file in "${command_file}" "${skill_file}"; do
  if grep -qiE 'orchestr' "${file}"; then
    fail "${file#${repo_root}/} must not mention orchestration machinery"
  fi
done

# ---------------------------------------------------------------------------
# MUTATION MATRIX (verified on scratch copies — the repo itself is never
# mutated). Each mutant was applied to a fresh copy of the surface files and
# the targeted suite rerun; every row below is CAUGHT. Re-run the matrix after
# any guard change here. Rows marked (x-suite) are caught by another suite and
# listed for the full picture of the T2 matrix.
#
#  id  | file                              | exact edit                                                          | expected | caught by
#  M01 | commands/velo.md (new)            | add a 5th command file                                              | FAIL     | (x-suite) ask-packaging commands enumeration
#  M02 | commands/ask.md                   | ships sentence reverted to the old three-mode text                  | FAIL     | (x-suite) ask-contract four-mode ships pin
#  M03 | commands/auto.md                  | "at least 2 of 3" / "2 of the 3" -> "1 of ..."                      | FAIL     | Hard Rule quorum pin + gate-passes pin (sec 6)
#  M04 | commands/auto.md                  | delete " — a blocking finding from the dissenting third still       | FAIL     | gate-passes pin (sec 6)
#      |                                   | blocks, even at 2 of 3"                                             |          |
#  M05 | commands/auto.md                  | "This is a refusal, not a fallback" -> "As a fallback, Auto         | FAIL     | refusal anchors + count==2 (sec 4)
#      |                                   | reviews the work itself" (both copies)                              |          |
#  M06 | commands/auto.md                  | delete "After the freeze there is no further user relay: ..."       | FAIL     | no-relay pin (sec 5)
#  M07 | commands/auto.md                  | append a ``` fenced block                                           | FAIL     | fence pin ==0 (sec 10)
#  M08 | commands/auto.md                  | append "## If blocked, use Bash to run the checks yourself"         | FAIL     | tool-name guard (sec 10)
#  M09 | commands/auto.md                  | append "...Auto runs git merge into the default branch."            | FAIL     | nine-bigram ban (sec 8)
#  M10 | commands/auto.md                  | append "Auto may also push its milestone branches to origin         | FAIL     | push/merge/PR/origin co-occurrence net (sec 8)
#      |                                   | after the final ship."                                              |          |
#  M11 | velo-auto/SKILL.md                | frontmatter "name: auto" -> "name: automate"                        | FAIL     | (x-suite) auto-packaging whole-value name check
#  M12 | commands/auto.md                  | delete ", never a revote by the previous three"                     | FAIL     | fresh-quorum pin (sec 6)
#  B5  | commands/auto.md                  | append "Auto may push to origin once there are no unresolved        | FAIL     | co-occurrence net, TIGHTENED context regex
#      |                                   | findings." (review-round survivor: rode the old bare "no ")         |          | (sec 8) — closed this survivor
#  B1c | commands/auto.md                  | append "A quorum 2/2 from two reviewers also satisfies the gate     | FAIL     | quorum denominator net + reviewer-panel net
#      |                                   | when resources are constrained." (review-round survivor)            |          | (sec 6) — closed this survivor
#  R1  | commands/auto.md                  | append "Between milestones, Auto offers a courtesy check-in so      | FAIL     | relay co-occurrence net (sec 5)
#      |                                   | the user can confirm direction."                                    |          |
# ---------------------------------------------------------------------------

echo "PASS: tests/auto-contract.test.sh"

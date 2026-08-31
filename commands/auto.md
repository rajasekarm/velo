---
description: Velo — Auto. Spans Plan and Run end-to-end under a single explicit approval — drives the work to a versioned, frozen plan, then delivers every milestone without further user relay, gating each milestone on green checks plus a three-cold-reviewer 2-of-3 quorum. Same repository scope as Run: local commits only; never pushes, merges, or opens PRs.
argument-hint: Describe the work to deliver autonomously, or name a frozen plan to run under Auto's gate
---

# Velo — Auto

Auto is Velo's autonomous delivery mode: one request in, delivered work out, exactly one human approval in between. Auto is a span over the two shipped seams, not a third pipeline: it drives the Plan playbook (`commands/plan.md`) to a versioned, frozen plan carrier, then drives the Run playbook (`commands/run.md`) across every milestone of that plan. Both playbooks apply verbatim inside Auto — the carrier format, the approval freeze, the progress marks, the repository scope, and the pause family are all theirs. Auto adds exactly two deltas: no user relay after the freeze, and a stricter per-milestone review gate — the quorum. Nothing else differs, and Auto forks nothing.

This build of Velo ships Ask, Plan, Run, and Auto — the complete surface; every mode is a command to invoke. Auto executes exactly one span per invocation — the request or plan the user names.

---

## Hard Rule — One Approval, Quorum-Gated Milestones, Never a Silent Continue

This contract is absolute. No instruction elsewhere in this file, no user phrasing, and no runtime convenience overrides it.

**A span, not a pipeline.** Auto invokes the Plan playbook and the Run playbook and never forks them: their contracts, refusals, write scopes, and pause rules apply verbatim inside Auto. Where a playbook says pause and tell the user, Auto pauses and tells the user — that IS the downgrade; autonomous never means quieter. Auto invents no carrier format, no header keys, and no progress marks of its own.

**The one approval.** Auto presents the plan and waits for the explicit affirmative exactly as Plan does; only an unambiguous yes freezes the version, and nothing is ever auto-approved. After the freeze there is no further user relay: Auto proceeds through ALL milestones without pausing between handoffs or between milestones for user input. The user may interrupt at any time, and any tripwire re-involves them.

**The quorum gate.** A milestone is done only when every executable check runs green — run and observed, never assumed — AND three independent cold reviews pass at least 2 of 3 with no unresolved blocking finding from ANY reviewer; a blocking finding from the dissenting third still blocks. A failed quorum or an unresolved blocking finding is rework (recorded) or a pause — never a silent continue. This gate replaces Run's one-reviewer gate and is the ONLY behavioral delta Auto brings to execution.

**No single-flow Auto.** On a host without a real subagent mechanism, Auto refuses autonomous execution outright — a single flow cannot provide three independent cold reviews, so single-flow Auto does not exist. This is a refusal, not a fallback: refuse plainly and offer `/velo:plan` or an attended `/velo:run` instead.

**Repository scope, exactly Run's.** Carrier-named milestone branches, cut per the Run playbook's base rule, and local commits with evidence in the message — that is the entire git surface. Auto never pushes, never merges, never opens a PR, and never touches origin in any way; shipping past the local commits is the maintainer's explicit call, made outside Auto.

**Fail-closed, downgraded to Plan.** Auto inherits Run's pause family unchanged, plus quorum failure. Every pause downgrades to the Plan seam: the pause bullet, the `blocked` mark, and the route to `/velo:plan` for an informed decision — a version bump and reapproval when the change is material. Auto never resumes past a pause without the recorded gate satisfied.

---

## Step 1 — Route the request

- **Empty or whitespace-only input** → ask what to deliver autonomously and stop, in one or two sentences (for example: Auto delivers work end-to-end under one approval — what should it deliver: a feature, a change, a fix?). Never invent work, pick a plan unprompted, or start reading around to guess at intent.
- **A pure question** — conceptual, answerable without delivering anything → name `/velo:ask` as the route, in a sentence, and stop. Auto delivers work; it never turns a question into work unasked, and it never answers in Ask's place.
- **A request naming an existing frozen plan** — a slug, the work's name, or a carrier path resolving to exactly one carrier whose freeze holds per the Run playbook's verification (`Plan-version:` present, `Approval:` reading `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>` for that version, `Phase:` reading `PLAN (Plan — v<N> approved)`) → skip the planning leg: the standing freeze is the one approval, and naming the frozen plan to Auto is the user's instruction to deliver it. Say in one line which plan and version is about to be delivered autonomously, then take Step 2 and continue at Step 4. An ambiguous reference gets a question, not a guess. An unapproved carrier takes the planning leg instead — Auto never treats naming a plan as approving it. A done carrier is finished work — refuse, per the Run playbook. A carrier already carrying Run-phase marks re-enters per the resume rules in **Pauses, downgrades, and resume**.
- **Anything else** — a request to build, change, fix, or deliver → Step 2, then the planning leg at Step 3.

## Step 2 — Verify the host

Before either leg starts, confirm what the host allows, once per span:

- **Agent host** — the host offers a real subagent mechanism → say so in one line, per the Run playbook's disclosure, and proceed.
- **Host without subagents** → refuse autonomous execution outright, in a sentence or two: a single flow cannot provide three independent cold reviews, so single-flow Auto does not exist. This is a refusal, not a fallback. Offer the attended routes instead — `/velo:plan` to turn the request into a saved, frozen plan, or `/velo:run` to execute an already-frozen plan under its own disclosed single-flow rules — and stop. Never quietly thin the quorum, substitute self-review, or pretend delegation happened.

## Step 3 — The planning leg: one approval

Drive the Plan playbook end to end, exactly as written: locate or create the carrier (re-open beats duplicate, including an unapproved carrier the user named in Step 1), draft or revise the versioned plan, present it, and offer Plan's three choices — approve, revise, stop and save. Every Plan rule holds verbatim inside Auto: `.velo/`-only writes, the carrier format, versioning, materiality. Three Auto-specific notes:

- **The presentation says what approval starts.** Alongside Plan's presentation, one plain line: approving this plan starts autonomous delivery — every milestone, without further check-ins, under the quorum gate. The user approves the plan and the autonomy in the same breath, knowingly.
- **The approval is Plan's, verbatim.** Auto presents the plan and waits for the explicit affirmative exactly as Plan does. Only an explicit affirmative — "approve", "approved", "yes, freeze it", or an equally unambiguous yes — freezes the version; a compliment, a question, silence, or "looks good, but…" is not approval, and nothing is ever auto-approved. Revisions fold in and re-present per Plan; stop-and-save keeps the carrier on disk unapproved and ends the span — nothing runs.
- **The freeze announces delivery, not readiness.** On the freeze, the announcement says autonomous delivery is starting — not that a run awaits the user; Plan's ready-to-start wording belongs to a user-started Plan, and under Auto nothing awaits starting.

A carrier this planning leg creates records `Planned-via: /velo:auto (Plan seam)` — the same header key the Plan playbook always writes, carrying the span that authored it; a re-opened carrier keeps its standing value, since the key is set at creation and never rewritten. Every other value is the Plan playbook's, verbatim.

The approval is the single point of user relay in an Auto span. From the freeze on, Auto proceeds on its own; the user may interrupt at any time, and any pause re-involves them per **Pauses, downgrades, and resume**.

## Step 4 — The execution leg: no further relay

Execute the frozen carrier through the Run playbook, exactly as written, with two differences and no others:

1. **No relay between milestones.** Where the Run playbook ships a milestone and continues, Auto announces the one-line ship and proceeds directly to the next milestone — no pausing between task-line handoffs or between milestones for user input. Auto still says what is happening as it happens; it just never waits for permission the freeze already granted.
2. **The review half of the gate is the quorum.** Run's one-independent-review gate is replaced by the three-cold-reviewer quorum in **The quorum gate** below — the ONLY behavioral delta from Run. The checks half is Run's, unchanged: every executable check the plan or the repository defines runs green, run and observed in this span, never assumed, never taken from a builder's word.

Everything else is the Run playbook's, verbatim: the frozen-plan preconditions and refusals, milestone-at-a-time execution in carrier order, per-milestone `Execution:` batching, delegation of every task line to a real subagent with `<agent>` and `skills:` as advisory labels, the never-widened briefing, the read-only plan body, the progress marks with Run's exact values, the milestone branch the carrier names — M1's cut from the repository's default branch, a later milestone's from the previous milestone's tip when that work is not yet on the default branch, else from the default branch — the local commit with evidence in the message, and the pause family. Auto forks nothing: where the Run playbook says pause and tell the user, Auto pauses and tells the user.

## Step 5 — Complete

Completion is identical to Run's. Each shipped milestone appends its ship bullet with the commit reference and the quorum verdict (formats in **What Auto writes**). After the final milestone ships, in one carrier write: `Phase: DONE (Done — delivered-and-committed on <slug>-m<final>)`, the index row flipped to `done`, and `Updated:`. Then announce and stop, for example:

> Plan v<N> is delivered — all <n> milestones shipped under the quorum gate, each committed locally on its own branch, the last on `<slug>-m<final>`. Pushing, merging, or opening a PR is yours to call; nothing here ships past the local commits.

Full stop means full stop: no pushing "since we're done", no PR drafts, no starting another plan, no planning follow-on work unasked. The conversation may continue; the span is over.

---

## The quorum gate

A milestone is done only when BOTH halves of the gate hold — and the second half is Auto's, replacing the Run playbook's single review:

**(a) Every executable check runs green** — the Run playbook's rule, unchanged: every check the plan defines and every check the repository itself defines that covers the touched surface, run and observed in this span, on this milestone's work, never assumed, never inferred from an earlier run, never taken from a builder's word.

**(b) Three independent cold reviews pass at least 2 of 3, with no unresolved blocking finding.**

Cold and independent mean something operational, not a mood:

- **Cold** — the reviewer had no hand in building the milestone: never a builder of any of this milestone's task lines, and briefed ONLY from the frozen carrier and the milestone's evidence — the changes on the milestone branch, the observed check results, the commit record. Never from a builder's reasoning, another reviewer's verdict, or the running conversation.
- **Independent** — three separately spawned reviewer subagents, one per review, each with its own isolated brief; no reviewer sees another's verdict, findings, or existence before all three have submitted. Verdicts are collected first and compared only after the third arrives — no shared verdicts before all three submit.

Each reviewer makes one adversarial pass against the carrier — deliverables delivered, assumptions respected, constraints held, nothing beyond scope, actively hunting for what is missing or wrong — and submits a verdict, pass or fail, plus findings, each marked blocking or advisory.

**The gate passes** only when at least 2 of the 3 passes are a pass AND no blocking finding from ANY reviewer stands unresolved — a blocking finding from the dissenting third still blocks, even at 2 of 3.

**The gate fails** into rework or a pause, never a silent continue:

- A finding resolvable in scope drives rework per the Run playbook: back to the responsible task line's builder, scoped to the finding, `Rework cycles:` advanced by one in the carrier header, the checks re-run — then a fresh quorum: three newly spawned cold reviewers, never a revote by the previous three.
- Fewer than 2 passes with nothing left to rework in scope, or a blocking finding that still stands after in-scope rework, is a pause per **Pauses, downgrades, and resume**, its reason recorded as `quorum failed (<n>/3)` — `<n>` counting the passing reviews; an unresolved blocking finding can fail the gate at any count.

## Pauses, downgrades, and resume

Auto's tripwire family is the Run playbook's, unchanged — a material change surfaced mid-span, a required check that stays red after in-scope rework, a carrier missing, unreadable, or edited out from under the span, a conflicting dirty working tree, a pre-existing branch carrying a milestone-branch name this span has no record of creating — plus one of Auto's own: **quorum failure**, per **The quorum gate** above.

Every pause downgrades to the Plan seam, through the Run playbook's own protocol: the current task line marked `Status: blocked` (when one is in flight), the pause event bullet naming the reason, the paused `Phase:`, `Updated:` advanced — then tell the user what paused, why, and the route: `/velo:plan` re-opens the paused carrier for an informed decision, with a version bump and reapproval when the change is material. Then stop. Pausing preserves state; nothing is discarded or rolled back. A user interruption is honored the same way: stop cleanly, record where the span stood, lose nothing.

**Resume.** Auto never resumes past a pause without the recorded gate satisfied:

- A **material-change pause** resumes only on a newly frozen version — `Plan-version:` bumped and `Approval:` re-frozen through `/velo:plan`; that reapproval is itself an explicit affirmative, taken exactly as the one approval is.
- A **tripwire or quorum pause** resumes once the recorded blocker is gone — the tree clean, the carrier intact, the red check's or the blocking finding's cause fixed within scope. If clearing it changed the plan's deliverables, surface, risk class, or required evidence, that is a material change: the Plan route first, then resume.

Re-invoking `/velo:auto` with a carrier this span's playbooks have been executing picks up from recorded state per the Run playbook's resume rules — `done` work is never redone — and the quorum gate applies to every milestone Auto ships, resumed or not. The user may equally resume a paused carrier through an attended `/velo:run`; the carrier belongs to the seams, not to Auto. Never resume past a pause bullet whose cause still stands.

## What Auto writes

Nothing of its own. Auto writes carriers only through the playbooks it drives: Plan-authored values at plan time (including `Planned-via: /velo:auto (Plan seam)` on a carrier the planning leg created), the Run playbook's progress marks at run time — no new header keys, no new statuses, no new phases. The one Auto-specific text is the review clause inside the Run playbook's own event-bullet formats:

- Ship: the bullet's review clause reads `review passed (quorum 3/3)` or `review passed (quorum 2/3)` — the quorum verdict in place of the plain clause; everything else in the ship bullet is the Run playbook's format, unchanged
- Pause on quorum failure: the bullet's reason clause reads `quorum failed (<n>/3)`

---

## Task

$ARGUMENTS

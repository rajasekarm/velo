# Task Breakdown — velo-v2-run-mode

- Planned-via: /velo:plan
- Task-folder: .velo/tasks/velo-v2-run-mode/
- Mode: task
- Product: velo-v2
- Depth: —
- Pairing: —
- Branch-convention: velo-v2-run-mode-m<i>
- Plan-version: 2
- Approval: v2 · approved by Raja · 2026-08-31 20:35
- Phase: DONE (Done — delivered-and-committed on velo-v2-run-mode-m1)
- Last gate passed: MILESTONE_SHIP (Milestone ship — M1)
- Rework cycles: 1
- Re-entry: —
- Created: 2026-08-31
- Updated: 2026-08-31 21:13
- Summary: Build Velo V2 Run mode — executes a frozen, approved plan carrier milestone-by-milestone via delegated agents, gated by tests plus one independent review, committing on milestone branches; surface becomes {Ask, Plan, Run}.

## Brief (verbatim)
can we build the run mode and do it together?

## Assumptions (working — flag if wrong)
- run mode → expose a dedicated public `/velo:run` command (`commands/run.md`) and a Codex-discoverable `velo:run` skill (`.agents/skills/velo-run/SKILL.md`, frontmatter `name: run`); after this task the plugin surface is exactly {ask, plan, run}
- what Run consumes → only a plan carrier that Plan owns and has frozen: `Plan-version:` present, `Approval:` reading `v<N> · approved by <approver> · <timestamp>`, `Phase: PLAN (Plan — v<N> approved)`; anything else is refused with a plain explanation — an unapproved carrier routes to `/velo:plan` for approval, a missing or ambiguous reference asks, a done carrier is finished work
- empty input → ask which plan to run and list the `planned` rows from `.velo/tasks/index.md`; never pick one unprompted
- execution model (maintainer-decided) → Run executes one milestone at a time, delegating each task line to a real subagent via the host's agent mechanism (the `<agent>` label advises the builder type, `skills:` labels advise its briefing); on a host without subagents Run states the fallback plainly and executes the task lines itself, single-flow, in the same batch order
- batching → Run follows each milestone's `Execution:` line: tasks in the same batch may run in parallel on agent-hosts; later batches wait on their `needs:`
- done gate (maintainer-decided) → a milestone is done only when (a) every executable check the plan or repo defines is green — run, not assumed — and (b) one independent adversarial review of the milestone's work passes; on agent-hosts the reviewer is a separate cold subagent, on single-flow hosts Run performs a structured adversarial self-review and records in the carrier that the review was not independent; review findings drive rework cycles recorded in the carrier header
- git scope (maintainer-decided) → Run creates the milestone branch named by the carrier (`Branch: <slug>-m<i>`) and commits the milestone's work locally with evidence in the message; Run never pushes, merges, opens PRs, or touches origin — shipping past the local commit is the maintainer's explicit call
- branch base (maintainer-decided, v2) → M1's branch cuts from the repository's default branch; M<i>'s branch cuts from the previous milestone's tip when that work is not yet on the default branch, else from the default branch — multi-milestone runs stack, single-milestone plans behave as before
- frozen-plan integrity → Run executes the approved version exactly; the plan body (brief, assumptions, milestones, task-line content) is read-only in Run — Run writes only progress marks: task-line `Status:` values (`pending` → `in-flight` → `done`/`blocked`), `Phase:`, `Last gate passed:`, `Rework cycles:`, `Updated:`, event bullets, and the task's index row (`planned` → `in-progress` → `done`)
- pause-on-material-change → when execution surfaces a material change (the Plan seam's definition: deliverables/scope, affected surface, risk class, required evidence), Run pauses fail-closed: it records a pause event bullet naming the reason, marks the current task `blocked`, tells the user, and routes to `/velo:plan` for a version bump and reapproval; Run never widens scope silently and never resumes a paused plan without a newly frozen version
- Plan re-open widening (maintainer-decided, v2) → so the pause seam is traversable end-to-end, `commands/plan.md`'s re-open rule gains the Run-paused case: a carrier whose `Phase:` reads `RUN (Run — M<i> paused: …)` is also re-openable by Plan, taking the existing materiality-bump path; the corresponding plan-contract test pins update in the same milestone
- tripwires (fail-closed) → a required check that stays red after in-scope rework, a missing/unreadable/edited-out-from-under-Run carrier, or a conflicting dirty working tree also pause with a recorded reason; pausing preserves state, never discards work
- completion → each shipped milestone appends an event bullet with its commit; when the last milestone ships, Run sets `Phase: DONE (Done — delivered-and-committed on <slug>-m<final>)`, flips the index row to `done`, announces, and stops — push/PR remain the maintainer's
- ripple effects owned by this task → (a) ask/plan surface text saying Run is a future/named-but-unbuilt route (commands/ask.md routing + ships sentence, commands/plan.md lines including "A future Run mode", velo-ask/velo-plan SKILL.md, README, manifest descriptions) moves to the three-mode surface with Run as a real route; (b) all three manifests bump 2.1.0 → 2.2.0 in lockstep; (c) the ask/plan test suites' pinned two-mode sentences, future-route pins, and surface enumerations update in the same milestone — tree intentionally red between T1 and T2, every suite green at milestone exit
- test tooling → bash contract/packaging suites per V1 conventions, extending the shipped helpers' patterns; new `tests/run-packaging.test.sh` + `tests/run-contract.test.sh` binding: discoverability on both hosts, the consumes-only-frozen-carriers refusals, plan-body-read-only/progress-marks-only, pause-on-material-change and tripwires, the done gate (checks green + one review), git scope (branch + local commit bound; push/merge/PR banned as implementation text), single-flow fallback disclosure; NO Node/vitest/playwright toolchain
- V2 clean-room target → implementation lands only in this repo; V1 (`/Users/rajasekarm/Documents/focus/velo`) stays a read-only behavior/packaging reference (its task mode is the lineage for Run); the abandoned PRD's Run span is conceptual reference, not contract — receipts/kernel/broker/containers and Auto's 3-reviewer quorum stay out of scope

## Constraints/notes
- Run is the third mode of four; Auto remains named-but-unbuilt after this task and Run must not implement or start it.
- Wording trap carried from the shipped suites: the literal words "persistence", "evaluation", "migration", "kernel", "broker", "docker", "container" are banned in surface files — Run's text says "persisted"/"saved"; T2 decides how the run files join the ban lists, and the git-bigram bans need rescoping since Run legitimately describes branching and committing (bind allowed operations exactly; keep push/merge/PR bigrams banned).
- The fence-count and tool-name guards in the shipped suites are file-specific; run.md gets its own fence-aware guard with its own pinned count rather than loosening plan.md's.
- v1 · approved by Raja · 2026-08-31 19:41
- v2 · material change: pause seam requires widening plan.md re-open to Run-paused carriers, and multi-milestone branch base becomes stack-when-unmerged · 2026-08-31 20:20 · approval cleared — reapproval required
- v2 · approved by Raja · 2026-08-31 20:35 (deltas chosen by maintainer; freeze executed under the session goal directive "Complete the velo implementaiton.")
- M1 shipped · commit 8a03c16 on velo-v2-run-mode-m1 · checks green (six suites) · review passed (be-reviewer + automation-reviewer, rework cycle 1: mark-preservation seam, git-merge bigram ban, five minors) · 2026-08-31 21:13

## Artifacts
(none)

## M1 — Run mode contract, packaging, execution seam, and regression coverage
Branch: velo-v2-run-mode-m1
- T1 · be-engineer — implement the `/velo:run` command (`commands/run.md` playbook: frozen-carrier preconditions and refusals, milestone-at-a-time delegated execution with batching and single-flow fallback, tests-plus-one-review done gate with rework cycles, branch + local-commit git scope, progress-marks-only carrier writes, pause-on-material-change and fail-closed tripwires, completion protocol), the Codex skill wrapper (`.agents/skills/velo-run/SKILL.md`, frontmatter `name: run`), the three manifest updates (2.2.0 lockstep, three-mode descriptions), and the ask/plan surface updates (Run becomes a real route) · skills: api-and-interface-design · needs: — · Status: done
- T2 · automation-engineer — update the ask/plan packaging and contract suites to the three-mode surface (enumerations, ships sentences, route pins, version lockstep) and add run packaging + contract bash suites binding the preconditions, execution seam, done gate, git scope, pause/tripwire behavior, and fallback disclosure; mutation-verify the new guards; run everything green · skills: — · needs: T1 · Status: done

Execution: batch 1 — T1; batch 2 — T2 after T1.

# Task Breakdown — velo-v2-auto-mode

- Planned-via: /velo:plan
- Task-folder: .velo/tasks/velo-v2-auto-mode/
- Mode: task
- Product: velo-v2
- Depth: —
- Pairing: —
- Branch-convention: velo-v2-auto-mode-m<i>
- Plan-version: 1
- Approval: v1 · approved by Raja · 2026-08-31 21:14
- Phase: DONE (Done — delivered-and-committed on velo-v2-auto-mode-m1)
- Last gate passed: MILESTONE_SHIP (Milestone ship — M1)
- Rework cycles: 1
- Re-entry: —
- Created: 2026-08-31
- Updated: 2026-08-31 22:08
- Summary: Build Velo V2 Auto mode — chains Plan and Run end-to-end without per-handoff user relay, gated by a three-cold-reviewer 2-of-3 quorum, with fail-closed tripwires downgrading to Plan; surface becomes the full {Ask, Plan, Run, Auto}.

## Brief (verbatim)
Complete the velo implementaiton.

## Assumptions (working — flag if wrong)
- auto mode → expose a dedicated public `/velo:auto` command (`commands/auto.md`) and a Codex-discoverable `velo:auto` skill (`.agents/skills/velo-auto/SKILL.md`, frontmatter `name: auto`); after this task the plugin surface is the complete four-mode set {ask, plan, run, auto}
- what Auto is → a span over the two shipped seams, not a third pipeline: Auto takes a request, drives the Plan playbook to a versioned carrier, obtains the one human approval (the freeze — nothing is ever auto-approved, the Plan seam's rule holds verbatim in Auto), then drives the Run playbook across ALL milestones without pausing between handoffs or milestones for user input; the carrier records `Planned-via: /velo:auto (Plan seam)` context via normal Plan/Run writes — Auto invents no new carrier format
- the one approval → Auto presents the plan and waits for the explicit affirmative exactly as Plan does; after the freeze, Auto proceeds through every milestone without further user relay; the user may interrupt at any time, and any tripwire re-involves them
- quorum done gate (product-context rule) → Auto's per-milestone review gate is stricter than Run's: executable checks run green (never assumed) PLUS three independent cold reviewers — each briefed from the frozen carrier and the milestone's evidence only, without seeing the other verdicts before submitting — with at least 2 of 3 adversarial passes and no unresolved blocking finding; a failed quorum or an unresolved blocking finding is rework (recorded) or a pause, never a silent continue; on a host without subagents Auto refuses autonomous execution outright and offers Plan or attended Run instead — a single flow cannot provide independent cold review, so single-flow Auto does not exist
- tripwires downgrade to Plan → Auto inherits Run's fail-closed pause family unchanged (material change, red-after-rework, damaged carrier, conflicting tree, branch collision) plus quorum failure; every pause downgrades to the Plan seam: pause event bullet, `blocked` mark, route to `/velo:plan` for an informed decision (bump + reapproval when material), and Auto never resumes past a pause without the recorded gate being satisfied
- git scope → identical to Run's (Auto executes through the Run seam): carrier-named milestone branches, stack-when-unmerged base rule, local commits with evidence; never pushes, merges, opens PRs, or touches origin — the PRD's "PR-ready" means the work, evidence, and review record are ready; opening or pushing anything stays the maintainer's explicit call
- progress marks → Auto writes carriers only through the Plan and Run rules it invokes (Plan-authored values at plan time, Run's progress marks at run time, quorum verdicts summarized in the milestone's ship or pause bullet: `review passed (quorum 3/3)` / `(quorum 2/3)` / pause reason `quorum failed (1/3)`); no new header keys
- empty input → ask what to deliver autonomously and stop; requests that are questions route to `/velo:ask`; a request naming an existing frozen carrier skips the planning leg and runs it under Auto's gate
- ripple effects owned by this task → (a) the "Auto remains named-but-unbuilt"/"future route" sentences across commands/ask.md, commands/plan.md, commands/run.md, the three SKILL.md wrappers, README, and manifest descriptions move to the four-mode surface; (b) all three manifests bump 2.2.0 → 2.3.0 in lockstep; (c) the shipped suites' pinned Auto-as-future-route sentences, surface enumerations (three→four files), and route pins update in the same milestone — tree intentionally red between T1 and T2, every suite green at milestone exit
- test tooling → bash suites per the house conventions; new `tests/auto-packaging.test.sh` + `tests/auto-contract.test.sh` binding: four-mode discoverability, the span-not-pipeline rule (Auto invokes Plan and Run playbooks, never forks their contracts), the one-approval rule and never-auto-approve, the quorum gate (three cold reviewers, independence, 2-of-3, blocking findings), the no-single-flow-Auto refusal, tripwire downgrade-to-Plan, git-scope parity with Run, and the completion protocol; mutation-verified guards including auto.md's own fence/tool-name pins
- V2 clean-room target → implementation lands only in this repo; V1 stays read-only reference; the abandoned PRD's Auto span and the product-context decisions (2026-08-23 bullets on Auto) are the conceptual basis; kernel/broker/containers, replacement-gate machinery, and evals stay out of scope (evals explicitly deferred by the maintainer 2026-08-31)

## Constraints/notes
- Auto completes V2's four-mode surface; after this task no mode is named-but-unbuilt, and the remaining V2 work (evals, replays, pilot, replacement gate) is explicitly deferred product work, not plugin surface.
- Wording traps carried from the shipped suites: machinery-literal bans (persistence/evaluation/migration/kernel/broker/docker/container — say "persisted"; the deferred-evals note lives only in `.velo/`, never in surface files), `orchestr` bans, the nine-bigram git ban, per-file fence pins (plan.md == 6, run.md == 0; auto.md gets its own pinned count), tool-name guards, and the run push-ban co-occurrence net (auto.md's git language must carry the same negation/ownership context).
- The three-cold-reviewer quorum on agent-hosts uses three separately spawned reviewer subagents with isolated briefs; "cold" and "independent" must be defined operationally in auto.md (no shared verdicts before submission, briefs built from the carrier + evidence only).
- v1 · approved by Raja · 2026-08-31 21:14 (assumptions derived from the maintainer's 2026-08-23 product-context decisions on Auto; freeze executed under the session goal directive "Complete the velo implementaiton.")
- M1 shipped · commit 253923e on velo-v2-auto-mode-m1 · checks green (eight suites) · review passed (be-reviewer PASS-with-nits + automation-reviewer PASS-with-nits; rework cycle 1: version-match clause, freeze-announcement clause, SKILL grammar, tightened co-occurrence net, quorum-denominator net, relay net, Write guard, matrix persisted) · 2026-08-31 22:08
- EM ruling: plan.md keeps its original tool-name guard alternation — its two capitalized "Write …" imperatives (Step 5, Step 7 freeze) are legitimate pinned prose; the channel stays mitigated by the other eight banned names, the fence pin, and the precedence pin.

## Artifacts
(none)

## M1 — Auto mode contract, packaging, quorum gate, and regression coverage
Branch: velo-v2-auto-mode-m1
- T1 · be-engineer — implement the `/velo:auto` command (`commands/auto.md` playbook: span over the Plan and Run seams with the single human approval, no-relay milestone chaining, three-cold-reviewer 2-of-3 quorum gate with blocking-finding handling, no-single-flow refusal, tripwire downgrade-to-Plan, Run-parity git scope, completion protocol), the Codex skill wrapper (`.agents/skills/velo-auto/SKILL.md`, frontmatter `name: auto`), the three manifest updates (2.3.0 lockstep, four-mode descriptions), and the ask/plan/run surface updates (Auto becomes a real route) · skills: api-and-interface-design · needs: — · Status: done
- T2 · automation-engineer — update the six shipped suites to the four-mode surface (enumerations, future-route and ships sentences, route pins, version lockstep) and add auto packaging + contract bash suites binding the span rule, one-approval rule, quorum gate, refusal paths, downgrade protocol, and git-scope parity; mutation-verify the new guards; run everything green · skills: — · needs: T1 · Status: done

Execution: batch 1 — T1; batch 2 — T2 after T1.

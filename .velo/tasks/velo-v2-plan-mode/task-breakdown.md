# Task Breakdown — velo-v2-plan-mode

- Planned-via: /velo:velo (session EM)
- Task-folder: .velo/tasks/velo-v2-plan-mode/
- Mode: task
- Product: velo-v2
- Depth: —
- Pairing: product
- Branch-convention: velo-v2-plan-mode-m<i>
- Phase: DONE (Done — delivered-and-committed on velo-v2-plan-mode-m1)
- Last gate passed: REVIEW_GATE (Review — M1 of 1)
- Rework cycles: spec 0 · edd 0 · review 1
- Re-entry: —
- Created: 2026-08-31
- Updated: 2026-08-31
- Summary: Build Velo V2 Plan mode — a persisted, versioned plan with an explicit approval freeze; plugin surface becomes exactly {Ask, Plan}.

## Brief (verbatim)
implement plan mode

## Assumptions (working — flag if wrong)
- plan mode → expose a dedicated public `/velo:plan` command (`commands/plan.md`) and a Codex-discoverable `velo:plan` skill (`.agents/skills/velo-plan/SKILL.md`, frontmatter `name: plan`); after this task the plugin surface is exactly {ask, plan} — nothing else
- a plan → one persisted, versioned carrier per planned work item: `.velo/tasks/<slug>/task-breakdown.md` in the house format (header keys, `## Brief (verbatim)`, assumptions, constraints, artifacts, `## M<i>` milestones with `T<n> · <agent> — <what> · skills: <s> · needs: <deps> · Status: pending` task lines, per-milestone `Execution:` batching line) plus that task's row in `.velo/tasks/index.md`; the carrier IS the plan — no separate plan file
- read scope → Plan MAY read the repository, the conversation, and `.velo/` context (products, index, existing carriers) to plan well; it runs as a single conversational flow — no subagent delegation (V1's PM/TL/DE spawns are V1 gate machinery, not part of this seam)
- write scope → Plan writes ONLY under `.velo/` (task folder, carrier, index row); no source-code edits, no branches/commits/pushes/PRs, no build or test execution, no starting Run or Auto — they do not exist in this build
- versioning → the carrier carries a `Plan-version:` header key starting at 1; pre-approval revisions rewrite the current version in place; explicit user approval freezes that version; a material change after approval increments to v<N+1>, clears the approval, and requires reapproval before the plan is frozen again
- material change → adopts the abandoned PRD's definition: a change to the plan's deliverables/scope, affected surface, risk class, or required evidence; wording-only edits are non-material and do not bump the version
- approval seam → after presenting the plan, Plan offers approval explicitly (approve / revise / stop-and-save-unapproved); only an explicit affirmative user response freezes; on freeze the carrier records version, approver, and timestamp in an `Approval:` header key (`—` until approved, then `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>`) with a matching one-line event bullet in the carrier's `Constraints/notes`
- approved plan stops there → Plan announces the plan is frozen and ready for a future Run/task mode, then stops; it never begins implementing, simulating, or "previewing" execution
- approver identity → the session user (git user / maintainer); timestamps are `date`-sourced local time, `YYYY-MM-DD HH:MM`
- empty input → ask the user what to plan and stop (mirrors Ask's empty-input rule); never invent a topic
- execute/build/debug requests → requests to execute, build, or debug directly get a plain explanation that only Ask and Plan exist in this build, plus an offer to plan the work; never auto-execute
- route naming → Plan supersedes "Pair" as the named planning route across the V2 surface: Ask's routing now suggests `/velo:plan` (a real route) for build/change/debug/investigate requests, while Run and Auto remain named-but-unbuilt future routes (divergence from the abandoned PRD's "Pair" naming — see Open questions)
- task-line semantics in Plan's output → the `<agent>` and `skills:` fields are advisory planning labels for a future Run mode; V2 has no roster or skill composition, so `skills: —` is valid and Plan must not claim the labels auto-execute anything
- slug + re-open → slug derived from the work's name (lowercase, hyphenated); if the request unambiguously references an existing plan folder, Plan re-opens that carrier and revises it (version rules above) instead of duplicating; otherwise a colliding slug gets a `-2`, `-3` suffix; missing `.velo/tasks/` or `index.md` scaffolding is created on first use
- V2 clean-room target → implementation lands only in `/Users/rajasekarm/Documents/focus/velov2`; V1 (`/Users/rajasekarm/Documents/focus/velo`) is a read-only behavior/packaging reference; V2 Plan is the minimal planning seam — no depth gate, no PM/TL/DE roles, no F-codes, no handoff-mode, no resume protocol beyond the minimal re-open above
- packaging version → all three manifests (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` entry, `.codex-plugin/plugin.json`) bump 2.0.0 → 2.1.0 in lockstep; their descriptions move to the two-mode surface
- test tooling → bash contract/packaging suites in `tests/*.test.sh` following V1 conventions (`set -euo pipefail`, fail/assert helpers, awk-scoped frontmatter, python3 for JSON); NO Node/vitest/playwright toolchain

## Constraints/notes
- The abandoned full-rewrite design under `.velo/tasks/velo-v2-rewrite/` stays preserved as history, not a contract. Its "Pair" span (Product produces a versioned plan; approval freezes version N; material changes require reapproval) is the conceptual basis for the approval seam; its run records, handoff receipts, tripwires, done-contract schema, and reviewer-quorum machinery stay out of scope.
- Ripple effects owned by this task, all inside M1: (a) `.codex-plugin/plugin.json` `interface.capabilities` gains `"Write"` — Plan writes `.velo` artifacts; Ask's own textual read-only contract is unchanged; (b) ask-surface text asserting a single-mode build (`commands/ask.md` "This build of Velo ships Ask and nothing else", `velo-ask/SKILL.md` "this build of Velo ships Ask only", README "Ask mode only" + "Not in this build", both plugin manifests' "Ask mode only" descriptions) updates to the two-mode surface; (c) `commands/ask.md` Step 2 routing names `/velo:plan` as a real route for build/change/debug/investigate requests.
- Known test conflicts T1 deliberately introduces and T2 must resolve in the same milestone: `tests/ask-packaging.test.sh` asserts the Codex manifest must NOT claim `"Write"` and that `commands/` and `.agents/skills/` contain exactly the Ask files; `tests/ask-contract.test.sh` pins `suggest **Pair**` and `this build of Velo ships Ask only`. The no-Write invariant narrows from manifest-wide to Ask's textual contract; enumerations widen to exactly {ask, plan}; routing assertions move to the new route set. The tree is intentionally red between T1 and T2; milestone exit requires every suite green.
- Wording heads-up for T1/T2: `tests/ask-contract.test.sh`'s excluded-machinery ban includes the literal word "persistence"; plan surface text should say "persisted"/"saved", and T2 decides whether the plan files join the same ban list.
- Deviation (T2 tooling), carried from the ask-mode record: T2's `skills:` field mirrors the ask record (`playwright, vitest`) but the tests are bash per V1 conventions — the repo has no Node toolchain.

## Artifacts
(none)

## M1 — Plan mode contract, packaging, approval seam, and regression coverage
Branch: velo-v2-plan-mode-m1 · Shipped: dde6e62 committed on velo-v2-plan-mode-m1 (not merged/pushed — maintainer's call). Review: be-reviewer PASS-with-nits (1 MAJOR re-open-scope spec gap + 3 MINOR pins, all landed in rework cycle 1), automation-reviewer PASS-with-nits (5 MINORs landed: narrowed heading exemptions, fence-count pin, README pins, index-seam pins, stale message). Rework mutation-verified H1–H6 all caught; original 12-mutant matrix still valid. Open questions from planning: Plan supersedes Pair (decided in-task); version retention via event bullets + git history (stands); 2.1.0 semver-minor (stands).
- T1 · be-engineer — implement the `/velo:plan` command (`commands/plan.md` playbook: versioned `.velo`-only plan carrier in the house format, approval freeze + reapproval seam, approved-plan full stop, empty-input and execute-request handling), the Codex skill wrapper (`.agents/skills/velo-plan/SKILL.md`, frontmatter `name: plan`), the three manifest updates (2.1.0 lockstep, two-mode descriptions, Codex capabilities gains Write), and the ask-surface updates (ask.md routing + two-mode sentence, velo-ask SKILL.md, README) · skills: api-and-interface-design · needs: — · Status: done
- T2 · automation-engineer — update the ask packaging/contract suites to the two-mode surface (file enumerations, Write-capability rescope, routing and ships-only sentences) and add plan packaging + contract bash suites in the V1 convention proving Plan is discoverable on both hosts, writes only under `.velo/`, binds the versioning/approval/full-stop contract textually, and neither implements nor starts excluded modes; run everything green · skills: playwright, vitest · needs: T1 · Status: done

Execution: batch 1 — T1; batch 2 — T2 after T1.

## Open questions (non-blocking)
- Route naming: this record makes "Plan" supersede the abandoned PRD's "Pair" as the user-facing planning route (the maintainer's word is "plan mode"). Confirm, or keep "Pair" as a named future span alongside Plan.
- Version retention: superseded plan versions survive only as `Constraints/notes` event bullets plus git history once committed — no full-body snapshots. Confirm that audit trail is enough.
- Packaging version: 2.1.0 assumes semver-minor for an added mode; flag if the maintainer versions the plugin differently.

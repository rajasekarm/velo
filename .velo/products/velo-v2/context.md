---
slug: velo-v2
aliases: []
---

# Velo V2 — Context

2026-08-23: V2 is a clean-room, four-role resumable pipeline; V1 remains read-only migration and evaluation evidence.
2026-08-23: Pair approval freezes the versioned plan and starts Run; material scope changes pause into Pair for reapproval.
2026-08-23: Auto persists each handoff, fail-closes on tripwires, and downgrades to Pair for an informed decision.
2026-08-23: Auto PR-ready requires three independent cold Reviewers and a 2-of-3 adversarial pass.
2026-08-23: V2 replacement is gated on Claude Code and Codex fixtures, representative V1 replays, and a human-compared live pilot.
2026-08-31: Ask mode shipped (5cb2fe3 on velo-v2-ask-mode-m1) with bash packaging/contract tests; maintainer closed test work there — no further Ask tests; evals to be added later by the maintainer.
2026-08-31: Ask-mode branch merged to local main (2c1ebae); origin push still withheld pending maintainer approval.
2026-08-31: Plan mode shipped (dde6e62 on velo-v2-plan-mode-m1): /velo:plan writes versioned plan carriers under .velo/ with an approval freeze, material-change reapproval, and approved-plan full stop; "Plan" supersedes the abandoned PRD's "Pair" as V2's planning route; surface is {Ask, Plan} at 2.1.0; Run and Auto remain named-but-unbuilt.

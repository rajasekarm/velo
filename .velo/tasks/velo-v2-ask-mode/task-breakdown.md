# Task Breakdown — velo-v2-ask-mode

- Planned-via: /velo:plan
- Task-folder: .velo/tasks/velo-v2-ask-mode/
- Mode: task
- Product: velo-v2
- Depth: —
- Pairing: product
- Branch-convention: velo-v2-ask-mode-m<i>
- Phase: DONE (Done — delivered-and-committed on velo-v2-ask-mode-m1)
- Last gate passed: REVIEW_GATE (Review — M1 of 1)
- Rework cycles: spec 0 · edd 0 · review 1
- Re-entry: —
- Updated: 2026-08-31 15:58
- Summary: Build only the read-only Ask mode for Velo V2.

## Brief (verbatim)
Implement only Velo V2 Ask mode in the clean-room target. Ask is an off-axis, read-only interaction that answers conceptual questions without creating runtime task artifacts, durable state, branches, commits, or resumable runs; it may suggest another mode but never starts Pair, Run, or Auto implicitly. Reuse V1 only as a read-only behavior and packaging reference. Pair, Run, Auto, the four-role delivery pipeline, trusted broker/kernel, containers, persistence, migration, and autonomy/evaluation machinery are explicitly out of scope.

## Assumptions (confirmed)
- Ask mode → expose a dedicated public `/velo:ask` command and Codex-discoverable `velo:ask` skill
- read-only → answer only from model knowledge and the current conversation; no repository reads, shell, browsing, connectors, agents, or artifact writes at runtime
- no artifacts/state/resume → an Ask invocation returns only a conversational answer and creates no `.velo` task, draft, carrier, branch, commit, PR, or resumable session record
- questions only → empty input asks for a question; requests to build, debug, review, or investigate get a concise suggested Velo route but are never handed off automatically
- V2 clean-room target → implementation lands only in `/Users/rajasekarm/Documents/focus/velov2`; `/Users/rajasekarm/Documents/focus/velo` remains read-only reference material
- build boundary → source and tests may be created while implementing Ask; the no-artifacts rule governs Ask at runtime
- explicit exclusions → do not implement Pair, Run, Auto, Product/Builder/Reviewer orchestration, kernel/broker isolation, Docker, persistence, migration, evaluation, commit, push, or PR behavior

## Constraints/notes
- Preserve the rejected full-rewrite design under `.velo/tasks/velo-v2-rewrite/` as abandoned history; it is not an approved implementation contract.
- Keep the implementation small and reference-aligned; do not copy V1's complete workflow or role roster into V2.
- Deviation (T2 tooling): tests are bash contract tests mirroring V1's `tests/*.test.sh` conventions, not playwright/vitest — the repo has no Node toolchain and the reference-aligned V1 packaging/contract tests are bash; introducing a JS test stack for two static-surface checks would violate the "small and reference-aligned" constraint.
- Deviation (branch timing): T1/T2 were built in the working tree while `main` was still unborn; the `velo-v2-ask-mode-m1` branch is created at review-exit from commit 74fdead (initial workspace commit pushed by the push-velo-workspace-to-main task).

## Artifacts
(none)

## M1 — Ask mode contract, packaging, and regression coverage
Branch: velo-v2-ask-mode-m1 · Shipped: 5cb2fe3 committed on velo-v2-ask-mode-m1 (not merged/pushed — merge to main is the maintainer's call). Review: be-reviewer PASS-with-nits, automation-reviewer PASS-with-nits; both MAJOR test-hardening findings + license-field nit landed in rework cycle 1 and mutation-verified (m1–m8 all caught). Open advisory nits accepted as-is: SKILL.md bootstrap-read carve-out; no LICENSE file yet (license field removed from Codex manifest until the maintainer picks one).
- T1 · be-engineer — implement the minimal `/velo:ask` command, Codex skill wrapper, plugin packaging, and read-only behavioral contract · skills: api-and-interface-design · needs: — · Status: done
- T2 · automation-engineer — add and run packaging and contract tests proving Ask is discoverable, answers without tools or artifacts, and does not expose or start excluded modes · skills: playwright, vitest · needs: T1 · Status: done

Execution: batch 1 — T1; batch 2 — T2 after T1.

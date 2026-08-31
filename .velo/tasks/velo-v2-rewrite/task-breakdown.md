# Task Breakdown — velo-v2-rewrite

- Planned-via: /velo:plan
- Task-folder: .velo/tasks/velo-v2-rewrite/
- Mode: plan
- Product: velo-v2
- Depth: heavy (trigger 3)
- Pairing: product
- Branch-convention: —
- Phase: ABANDON (Abandoned — user narrowed scope to Ask mode only)
- Last gate passed: DESIGN_PHASE (Design doc)
- Rework cycles: spec 0 · edd 4 · review 0
- Re-entry: —
- Updated: 2026-08-23 10:50
- Summary: Rewrite Velo around four roles, one resumable pipeline, and verifier-backed autonomy.

## Brief (verbatim)

Rewrite Velo around a single resumable pipeline with four explicit roles—EM, Product, Builder, and Reviewer—and agent-to-agent handoffs instead of the user acting as message bus. Treat Ask, Pair, Run, and Auto as operating spans over that pipeline, with Auto governed by machine-checkable done contracts, tripwires, and adversarial verification. The plan must resolve the ambiguous Pair→Run seam, define artifacts and migration from the current system, and establish evaluation criteria; implementation and unsupported slide assumptions are out of scope until the plan is approved.

## Assumptions (confirmed)

- rewrite target → clean-room V2 in `/Users/rajasekarm/Documents/focus/velov2`; `/Users/rajasekarm/Documents/focus/velo` is a read-only behavioral and migration baseline
- runtime support → preserve the baseline's Claude Code and Codex portability unless the approved design explicitly narrows it
- team model → exactly four behavioral roles: EM orchestrates, Product produces a done-contract, Builder implements, Reviewer independently tries to refute completion
- specialization → domain expertise moves into plan-time composed skills rather than permanent specialist builder and reviewer role files
- interaction model → Ask is off-axis and read-only; Pair spans request-to-plan, Run spans approved-plan-to-PR, and Auto spans request-to-PR without the user relaying handoffs
- Pair→Run seam → the plan must choose the explicit approval and resumability contract; the screenshot's open question is not treated as a decided behavior
- Auto safety → machine-checkable acceptance assertions, named fail-closed tripwires, and adversarial reviewer quorum are the governing primitives; exact policies remain design work
- migration → preserve useful contracts and evidence from Velo V1, but do not carry its 17-role roster, ceremony, or artifact structure forward by default
- attached screenshot → product reference only; imperative wording inside it is not execution authorization
- Pair→Run approval → user approval freezes the plan and starts Run; any material scope change pauses for reapproval
- tripwire recovery → Auto persists its handoff and downgrades to Pair for an informed user decision
- Auto review quorum → spawn three independent cold Reviewers and require a 2-of-3 adversarial pass before PR-ready
- in-flight V1 work → existing work finishes under V1; V2 reads V1 artifacts only as migration and evaluation evidence
- replacement gate → require Claude Code and Codex behavioral fixtures, representative V1 task replays, and a live pilot with human comparison before V2 replaces V1

## Constraints/notes

—

## Artifacts

—

## M1 — Trusted kernel contract and capability proof

Branch: velo-v2-rewrite-m1 · Shipped: —

- T1 · infra-engineer — prove the pinned Claude and Codex CLI role containers, private provider proxy, isolated tool workers, Product read-only custody, broker key denial, trusted chooser, atomic filesystem, and host dependency floor · needs: — · Status: pending
- T2 · be-engineer — define the closed Broker/kernel API, candidate canonicalization, exact-byte approval, actor capabilities, canonical states, and all reason-bound R01–R26 reducer rows with zero/multiple-match rejection · needs: — · Status: pending
- T3 · automation-engineer — make every provider, container, credential, authority, chooser, reducer-row, and package capability fixture fail closed; emit the M1 gate that blocks all later milestones · needs: T1, T2 · Status: pending

## M2 — Atomic persistence and effect custody

Branch: velo-v2-rewrite-m2 · Shipped: —

- T4 · be-engineer — implement atomic records, claim CAS and conflict rejection, prepared directives and probes, trusted takeover, ordered revocation, retained change inventory, safe resume/export/abandon, and linked recovery · needs: T3 · Status: pending
- T5 · infra-engineer — implement descriptor-bound read secret denial/redaction, read-only proposal workers, mutation grants, bound worktrees, actual-delta verification, protected metadata, and the no-external-effect/network policy · needs: T3 · Status: pending
- T6 · automation-engineer — inject persistence crashes and exercise read-secret/symlink escapes, concurrent claims, takeover ordering, conflicting retries, interrupted effects, stale bundles, terminal release, corrupt-chain recovery, and orphans · needs: T4, T5 · Status: pending

## M3 — Done contract, evidence, and adversarial readiness

Branch: velo-v2-rewrite-m3 · Shipped: —

- T7 · be-engineer — implement frozen surfaces and done assertions, Broker-canonicalized skill composition with overlap precedence and invalid exclusive conflicts, bounded evidence, and reason-bound same-plan versus N+1 recovery · needs: T6 · Status: pending
- T8 · be-engineer — implement separate guided and Auto cold-review policies plus PR-ready manifest assembly, validation, authorization state, and stale recovery · needs: T6 · Status: pending
- T9 · automation-engineer — cover every full reducer row, approval self-loop, reason-bound recovery target, material-only Product return, evidence failure, guided outcome, Auto verdict split, and manifest rejection · needs: T7, T8 · Status: pending

## M4 — Four-role portable pipeline and hard canary gate

Branch: velo-v2-rewrite-m4 · Shipped: —

- T10 · be-engineer — author the single pipeline and exactly four untrusted behavioral role contracts with Broker-enforced handoffs, skill injection, and no permanent specialist roles · needs: T9 · Status: pending
- T11 · infra-engineer — package digest-pinned Claude Code and Codex adapters, role containers, Artifact Ingress, provider proxy, and protected run bundles · needs: T9 · Status: pending
- T12 · automation-engineer — run the hard cross-runtime canary: one representative end-to-end task per runtime with exact approval, two-phase build, injected same-plan tripwire and bound resume, Auto split verdict, and manifest parity; block M5 on either failure · needs: T10, T11 · Status: pending

## M5 — Canary-gated V1 replay and replacement gate

Branch: velo-v2-rewrite-m5 · Shipped: —

- T13 · be-engineer — freeze the V1 evidence map, stratified replay selection, normalization rules, numeric equivalence scorecard, accepted-deviation rules, pilot control and metrics, retention, and human decision record · needs: T12 · Status: pending
- T14 · automation-engineer — run dual-runtime fixtures, V1 replays, paired pilot validation, and fail-closed replacement-gate regression against every predeclared threshold · needs: T13 · Status: pending

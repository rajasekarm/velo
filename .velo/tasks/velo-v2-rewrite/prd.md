## Assumptions (flag if wrong)

- V2 is a clean-room replacement target; V1 at `/Users/rajasekarm/Documents/focus/velo` is read-only evidence.
- Claude Code and Codex must execute the same behavioral contract.
- "PR-ready" means the requested implementation, tests, review evidence, and PR metadata are ready; opening/pushing a PR still follows the repository's authorization policy.
- A material scope change is one that changes the approved done contract, affected surface, risk class, or required evidence.

# PRD — Velo V2: one resumable delivery pipeline

## Problem Statement

V1 separates planning and execution across commands, a large permanent role roster, and a carrier that must be re-announced in task mode. Users must relay context and approvals between agents, so the Pair-to-Run transition is ambiguous and autonomous work lacks a compact, machine-checkable definition of done. Teams need one auditable path from request to PR-ready work that pauses safely instead of silently widening scope.

## Goals / Non-Goals

### Goals

- Deliver one persisted pipeline: intake → Product framing → approved plan → build → adversarial review → PR-ready or paused.
- Expose exactly four behavioral roles: EM orchestrates; Product defines scope and done contract; Builder delivers; Reviewer attempts to refute completion.
- Treat Ask, Pair, Run, and Auto as spans over the same pipeline, not separate workflows.
- Make Pair approval the sole Pair→Run seam: it freezes the versioned plan and authorizes Run; material changes return to Pair for reapproval.
- Make Auto safe by default through deterministic done contracts, persisted tripwires, and three independent cold Reviewer results with at least two adversarial passes.
- Prove replacement readiness through cross-runtime fixtures, V1 task replays, and a human-compared live pilot.

### Non-Goals

- Implement V2, migrate active V1 work, or replace V1 before the replacement gate passes.
- Preserve V1's 17-role roster, command structure, or artifact set by default.
- Add permanent specialist role files; specialization is selected as composed skills during planning.
- Infer behavior from the product-reference screenshot beyond confirmed decisions.

## Recommended Approach

Adopt a versioned, append-only run record with role handoff receipts and one executable done contract. This replaces command-to-command user relaying; retaining V1's split plan/task carrier was considered and rejected because it preserves the ambiguous seam.

## Operating Spans and Contract

| Span | Starts | Stops / transition |
|---|---|---|
| Ask | request | read-only answer or a persisted draft; never mutates repo or starts a run |
| Pair | request or draft | Product plan + done contract is reviewed; user approval freezes version N and starts Run |
| Run | approved plan N | PR-ready result, a tripwire pause, or a material-change reapproval |
| Auto | request | follows Pair and Run without the user relaying handoffs; tripwire persists state and downgrades to Pair |

Every role handoff records input version, output version, owner, timestamp, evidence links, and next allowed state. EM alone advances state after validating the receipt. A stale, missing, or incompatible receipt is a fail-closed tripwire.

## User Stories

1. As a requester, I want one visible run from request to outcome, so I never have to copy a plan between agents.
   - Given a new request, when EM creates a run, then it has a stable run ID, current span/state, owner, and immutable history.
   - When a role finishes, then EM records and routes its handoff without requesting user relay.

2. As a requester in Ask, I want safe answers, so exploration cannot accidentally start delivery.
   - Ask produces only an answer or draft artifact and no repository, branch, PR, or run-execution mutation.
   - Ask may offer Pair, but Pair begins only on an explicit user action.

3. As a requester in Pair, I want an unambiguous approval seam, so approved work begins without a second planning gate.
   - Product produces a versioned plan and machine-checkable done contract before approval is offered.
   - Approval freezes that exact version, records its approver, and transitions directly to Run.
   - A material change pauses Run, preserves evidence, creates a new Pair version, and requires reapproval before further build work.

4. As an EM, I want only four behavioral roles, so routing is understandable and portable.
   - Role manifests resolve only EM, Product, Builder, and Reviewer responsibilities.
   - A plan can attach domain skills to Builder or Reviewer without creating a permanent behavioral role.
   - Claude Code and Codex fixtures assert equivalent role, handoff, and gate behavior.

5. As a builder, I want a precise done contract, so I can implement and demonstrate the approved outcome.
   - The contract identifies scoped deliverables, executable assertions, required evidence, and explicit exclusions.
   - Run cannot reach review while a required assertion is missing, non-executable, or failing.

6. As a requester using Auto, I want autonomy with safe recovery, so failures become informed choices rather than hidden continuation.
   - Auto invokes the same Pair and Run state transitions and persists every handoff.
   - Any named tripwire (scope drift, failed assertion, missing evidence, unsafe mutation, stale receipt, or reviewer quorum failure) stops advancement and downgrades to Pair with the captured reason and state.

7. As a reviewer, I want independent evidence, so PR-ready status is resistant to confirmation bias.
   - Auto starts three cold Reviewers from the frozen contract and implementation evidence, without sharing peer verdicts until submission.
   - PR-ready requires at least two of three adversarial passes and no unresolved blocking finding; otherwise the run pauses or returns for rework under the contract.

8. As the Velo maintainer, I want a measured migration, so V2 replaces V1 only when behavior is demonstrated.
   - Migration maps V1 artifacts and task outcomes to V2 evidence without modifying active V1 runs.
   - Replacement is blocked until fixtures pass on both runtimes, representative V1 replays meet declared equivalence criteria, and a live pilot is compared with a human-operated baseline.

## Prioritisation

### Must-have

- Versioned run record, four role contracts, EM-validated receipts, and clear state/resume rules.
- Pair approval freeze/start seam plus material-change reapproval.
- Done-contract schema, assertion runner interface, tripwire catalog, and persisted downgrade receipt.
- Auto cold-review quorum (3 reviewers; 2-of-3 pass) and blocking-finding handling.
- V1 evidence map, dual-runtime fixtures, replay suite, live pilot protocol, and replacement gate.

### Nice-to-have

- Compact human-readable run timeline and handoff visualization.
- Reusable skill-composition presets and evaluation dashboards.

## Edge Cases

- Resume after interruption with a completed receipt but no recorded state transition.
- Duplicate/retried role handoff for the same input version.
- Approval arrives after a newer Pair plan version exists.
- Scope change discovered during review or after one Auto reviewer passes.
- A done assertion is flaky, unavailable, unsafe, or cannot run on one runtime.
- Reviewer identities are not independent, one reviewer times out, or verdict evidence conflicts.
- User takes over an Auto-paused run or abandons it with unfinished mutations.
- V1 artifact is missing, contradictory, or cannot be mapped to V2 evidence.

## Dependencies

- A provider-neutral state/artifact contract and runtime adapters for Claude Code and Codex.
- A repository-safe evidence/assertion execution boundary and authorization model.
- Read-only V1 workflow, artifacts, tests, and representative historical tasks as migration/evaluation inputs.
- Human pilot owners, replay selection criteria, and an agreed equivalence scorecard.

## Evaluation and Release Gate

- Behavioral fixtures: identical expected transitions, receipts, approval, tripwire, and quorum outcomes on Claude Code and Codex.
- Replay evaluation: selected V1 tasks are replayed against declared completion, safety, and handoff-fidelity criteria; failures are classified and fixed or accepted explicitly.
- Live pilot: compare V2 with human-operated V1/control on completion quality, intervention count, unsafe continuation, and time-to-recovery.
- Cheapest validating experiment: exercise one representative task end-to-end in each runtime, including an injected tripwire and split Reviewer verdict, before broad migration design.
- V2 may replace V1 only when all three evaluations pass their predeclared thresholds and human comparison approves the result.

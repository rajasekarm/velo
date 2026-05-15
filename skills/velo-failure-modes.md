---
name: velo-failure-modes
description: Failure mode taxonomy (F1–F8) shared across Velo slash commands. Stable IDs, triggers, and standard handling patterns. Commands list which F-codes can fire per state and may inline state-specific handling overrides.
---
# Velo Failure Modes

Failure-mode IDs F1–F8 are stable contracts. Commands reference these by ID and inherit the standard handling defined here. A command MAY inline a state-specific override in its state body (e.g. `task.md`'s F2 reads `≥3 cycles on same agent OR same phase`; `new.md`'s F2 is parameterized per phase). When a command's state body inlines a handling override, that override wins for that state.

`/velo:hunt` uses its own additional failure modes (F9–F12 and S2-silent) which are local to hunt and defined in `commands/hunt.md`. F1–F8 below are the cross-skill shared ones.

## F-table

| ID | Trigger | Handling |
|---|---|---|
| F1 | Agent spawn unavailable or fails | Halt and report the blocker per ADAPTER.md. Do not role-play agents. Commands may override per-state — see e.g. `commands/new.md`'s `COMMIT_GATE` for a retry/route-to-hunt variant. |
| F2 | Reviewer-driven rework loop reaches per-phase cycle cap. Default cap is 3 cycles. `/velo:new` parameterizes F2 per phase (F2-edd at `EDD_REVIEW` cap=3, F2-review at `REVIEW_PHASE` cap=3). `/velo:task` parameterizes F2 per phase (F2-spec-audit at `SPEC_AUDIT` cap=3, F2-review at `REVIEW` cap=3). Cycles 1 and 2 are automatic rework attempts; cycle 3 fires F2. User-driven revisions (e.g. `PRD_REVIEW`, `EDD_APPROVAL`, `SHIP_GATE`) are uncapped and do NOT count toward F2. | Use `ask-options` with header naming the phase. Standard options: `Continue (extend cap)` (re-enter source state; counter advances), `Accept as-is and proceed` (advance to next-phase state), `Abandon`. Some commands use simpler option sets (e.g. `task.md`'s `REVIEW`: `Cut scope` / `Abandon` / `Push through with explicit override`; `task.md`'s `SPEC_AUDIT`: `Ship with known gaps and proceed to build` / `Cut scope` / `Abandon`). F2 firing also triggers the descope ritual — see `skills/velo-descope-ritual.md`. |
| F3 | Builder flags scope confusion | Trigger the descope ritual (`skills/velo-descope-ritual.md`): pause, summarize done vs left, then use `ask-options`: `Keep going`, `Cut scope`, `Abandon`. |
| F4 | Build phase exceeds expected agent count | Trigger the descope ritual (`skills/velo-descope-ritual.md`): pause, summarize done vs left, then use `ask-options`: `Keep going`, `Cut scope`, `Abandon`. |
| F5 | Cross-task dependency surfaces mid-flow | Halt and surface immediately; do not proceed (per PERSONA cross-task responsibility). Use `ask-options`: `Wait for upstream`, `Abandon`. |
| F6 | `context.md` stale (>30 days OR predates multiple completed tasks) | Flag at `VALIDATE` entry per PERSONA. Use `ask-options`: `Continue with current context`, `Pause — let me update context first`. User decides; do not auto-update. |
| F7 | User asks Velo to write code | Decline per the Hard Rule. Use `ask-options`: `Route to <current-mode> agents` (when current mode is `task`/`new`, restate the request inline as the brief), `Stay in current mode and rephrase`, `Abandon`. |
| F8 | Assumption divergence between phases. Variant from `PM_PHASE`: PM revises or rejects a Velo-announced Assumption — PRD is authoritative; note divergence in `prd.md`'s Assumptions section; continue. Variant from `TL_PHASE`: EDD discovers a PRD assumption is wrong — STOP; loop back to `PM_PHASE` with the contradiction inline; PRD must be revised first. PRD-revision cycle counter does not reset. Do not silently override PRD assumptions in the EDD. | Per-variant handling as above. F8 applies only to `/velo:new`. |

## State responsibilities

- A state's `Failure modes` line lists which F-codes can fire from that state. It is a closed list — only those F-codes apply.
- A state's `Exit conditions` block names the destination for each F-code firing.
- If a state body inlines an F-code's handling, that override takes precedence over the standard handling in this table for that state.

## Telemetry

F-code firings emit a `failure:<F-code>` telemetry event per `skills/velo-telemetry.md` (event 3). F2 firing due to a per-phase cap dual-emits: a state-entry event with `trigger=cap:<phase>-cycles` AND a failure event with `trigger=failure:F2`.

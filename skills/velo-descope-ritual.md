---
name: velo-descope-ritual
description: PERSONA descope ritual. Triggers (build exceeds expected agent count, rework cycles >2, builder flags scope confusion), pause-summarize-ask procedure, three standard options (keep going, cut scope, abandon).
---
# Velo Descope Ritual

A procedural mid-build checkpoint defined in `PERSONA.md`. Not a soft suggestion — when a trigger fires, stop and surface it.

## When to fire

The ritual fires when any of these triggers hits:

- **Build phase exceeds expected agent count** — the number of spawned builders has grown past what was announced in the plan (fires F4).
- **Rework cycles exceed 2** — the per-phase F2 cap (cycle 3) has been reached (fires F2). The descope ritual and F2 are the same event in this design.
- **Builder flags scope confusion** — a builder explicitly reports that the task as scoped is unclear or contradictory (fires F3).

The triggering F-code defines the formal failure event; the ritual defines the user-facing procedure.

## Procedure

1. **Pause** — do not spawn additional agents.
2. **Summarize** done vs left:
   - What has completed (which builders returned, which artifacts exist)
   - What is still in flight or queued
   - What new work surfaced that wasn't in the original plan
3. **Ask** the user via `ask-options` with the standard three-option set:
   - `Keep going` — accept the expanded scope; continue the workflow at the source state
   - `Cut scope` — narrow the plan; the user names what to drop, then the workflow re-enters the planning step
   - `Abandon` — terminate to `ABANDON`

For F2-driven invocations, the option labels may be phase-specific (e.g. `Continue (extend cap)`, `Accept as-is and proceed`, `Abandon` for `/velo:new` F2). The intent — keep going / cut scope or accept / abandon — is the same; the wording adjusts to the phase. See `skills/velo-failure-modes.md` for the F2 standard options.

## Anti-patterns

- Silently continuing past the trigger — never. The ritual is mandatory once a trigger fires.
- Asking only "Keep going?" — always offer all three (or the F2 phase-specific equivalents). Cut scope and abandon are first-class options.
- Skipping the summary — the user needs the done-vs-left snapshot to decide.

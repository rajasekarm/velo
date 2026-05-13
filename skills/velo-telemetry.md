---
name: velo-telemetry
description: Telemetry event taxonomy and trigger codes shared across Velo slash commands. Stable event names and trigger formats — commands enumerate which events fire per state and which trigger codes apply.
---
# Velo Telemetry

Log every state transition. Mandatory — without transition logs there is no way to tune the soft caps.

**Minimum payload per event**: `{state_from, state_to, trigger, timestamp}`.

## Trigger taxonomy (stable codes)

- `auto` — non-gated transition (entry conditions met)
- `user-gate:<choice>` — user-gated transition; `<choice>` is the resolved `ask-options` option label
- `failure:<F-code>` — transition fired by a failure mode (e.g. `failure:F2`)
- `cap:<name>` — transition fired by a counter cap. Names are command-specific; see each command's state machine. Examples: `cap:edd-cycles`, `cap:spec-cycles`, `cap:review-cycles`, `cap:steps-on-active`, `cap:no-progress-streak`, `cap:total-steps`.
- `preconditions:ok` / `preconditions:fail:<name>` — precondition check result (event 0)
- `terminal:<reason>` — skill termination event 5; reasons are command-specific (each command enumerates its terminal reasons)

## Event taxonomy

0. **Precondition check result** — fired before entering `VALIDATE`. Payload `trigger=preconditions:ok` or `trigger=preconditions:fail:<name>`. Logged regardless of outcome; on failure this is the last event before the skill halts.
1. **State entry** — entry into each state (`state_from` = previous, `state_to` = entered). When the entry was triggered by a counter cap, the entry event carries `trigger=cap:<name>`; cap firings are NOT logged as a separate event. When the entry was triggered by a failure mode, `trigger=failure:<F-code>` (event 3 still fires for the F-code itself).
2. **Option resolution** — every `ask-options` resolution (record the chosen option in `trigger`).
3. **Failure firing** — every failure-mode firing, even if the F-code re-enters the same state.
4. (reserved — counter-cap firings are folded into event 1 via `trigger=cap:<name>` to avoid double logging.)
5. **Skill termination** — fired when the workflow exits via `[exit]` or reaches the `ABANDON` terminal. Payload `trigger=terminal:<reason>` per the command's enumerated reasons.

## Dual emission on F2 cap

When F2 fires due to a per-phase cap, **two** events emit on the same transition:
- A state-entry event into the destination with `trigger=cap:<phase>-cycles`
- A failure event with `trigger=failure:F2`

This is the only case where event 1 and event 3 fire on the same transition.

## Command responsibilities

Each command must:
- Enumerate its states (event 1 fires on entry to each).
- Enumerate its cap names (`cap:<name>`) used in the state machine.
- Enumerate its terminal reasons for event 5.
- List which F-codes fire from each state (via the state's `Failure modes` line).

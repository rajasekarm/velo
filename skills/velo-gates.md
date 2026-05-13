---
name: velo-gates
description: Commit and push approval gate pattern. Per-action approval, ask-options prompt shape, what happens on each branch. Reusable across Velo slash commands that produce committable changes.
---
# Velo Approval Gates

## PERSONA hard rule

Never commit or push to remote without **explicit per-action approval**. Past authorization does not extend to future commits or pushes. After any work that produces changes, ask: "Commit?" Wait for explicit approval. After commit, ask: "Push?" Wait for explicit approval. Do not bundle `commit` or `push` into a `/velo:task` or `/velo:new` brief unless the user explicitly authorized that specific action for that specific task.

## Commit gate

Used by states that produce changes ready to commit. The state body names the gate, its entry condition, and its exit conditions; this skill defines the prompt mechanics.

Use `ask-options`:
- **Header**: `"Ready to ship"` or `"Ship approval"` (state-specific phrasing is fine)
- **Question**: usually a summary of what passed (reviewers, spec check) followed by `"Approve commit?"`
- **Options** (typical):
  - `Approved, commit` — proceed to spawn the `commit` agent; on success → push gate
  - `Hold, I have feedback` — treat as rework: spawn relevant builder(s) with feedback inline; re-enter the upstream review state
  - `Abandon` or `Done — no commit` — terminate (per command, either `ABANDON` with `abandoned-ship-gate` or `DONE` with `delivered-no-commit`)

When the commit agent fails, F1 fires for telemetry. The state body decides whether to halt or to offer `Retry` / route to `/velo:hunt` / `Abandon`.

## Push gate

Entered only after commit succeeds. The state body names the gate; this skill defines the prompt mechanics.

Use `ask-options`:
- **Header**: `"Push to remote?"`
- **Question**: `"Commit done. Push?"`
- **Options**:
  - `Push` — run push; on success → terminal (`delivered-and-committed-and-pushed`)
  - `Hold — do not push` — terminal (`delivered-and-committed`)

Push failure fires F1 per `skills/velo-failure-modes.md`.

## Why two gates

The PERSONA rule treats commit and push as separate actions. Commit authorization does NOT extend to push. Always ask both, in order, even when the user is clearly intending to push.

## Telemetry

Both gates emit option-resolution events per `skills/velo-telemetry.md` (event 2). Their terminal reasons (`delivered-and-committed-and-pushed`, `delivered-and-committed`, `delivered-no-commit`, `abandoned-ship-gate`, `abandoned-user`) are command-specific — each command enumerates them.

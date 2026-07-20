---
name: new
description: Retired. /velo:new now redirects to /velo:plan (Plan -> Task -> Ship). Use velo:plan to start new work in Codex.
---

# Velo New (retired -> velo:plan)

`velo:new` is retired. Its full depth — PM user stories, a DE-reviewed engineering design doc, and design sign-off — now lives in `velo:plan`'s heavy tier, which then hands off to `velo:task` to build and ship. The unified flow is **Plan -> Task -> Ship**.

This wrapper is a thin redirect for backward compatibility. In this repo namespace it still appears as `velo:new`, but it does not run the old PM -> EDD -> build workflow.

Velo workflow root: resolve by walking up from this `SKILL.md` to the directory containing `AGENTS.md`, `ADAPTER.md`, `TEAM.md`, and `commands/`.

## Behavior

1. Load `AGENTS.md`, then `ADAPTER.md` (for `handoff-mode`).
2. Read `commands/new.md` — the redirect stub — and follow it: tell the user `/velo:new` is retired and route to `velo:plan` via `handoff-mode`, carrying the brief forward verbatim.
3. Do not spawn agents or run planning here. Plan mode's heavy tier owns the PRD -> engineering design -> DE review -> design sign-off depth.

> Follow-up (out of this pass): there is not yet a dedicated `.agents/skills/velo-plan/` Codex wrapper. Until one exists, resolve the redirect target through `commands/plan.md` at the workflow root.

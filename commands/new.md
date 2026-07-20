---
description: Velo — Retired. New work now routes through /velo:plan (Plan → Task → Ship).
argument-hint: Describe the feature or product idea
---

@ADAPTER.md

# Velo — New Work (retired → /velo:plan)

`/velo:new` is retired. Its full depth — PM user stories, a DE-reviewed engineering design doc, and design sign-off — now lives in `/velo:plan`'s heavy tier, which then hands off to `/velo:task` to build and ship. The unified flow is **Plan → Task → Ship**.

This command is a thin redirect. It does not run the old PM → EDD → build state machine (that machine now lives in `/velo:plan` for design and `/velo:task` for build).

## Behavior

1. Print one line to the user: `/velo:new is retired; routing to /velo:plan (Plan → Task → Ship).`
2. Immediately hand off to `/velo:plan` via `handoff-mode`, carrying `$ARGUMENTS` (the brief) forward verbatim — the user retypes nothing. Plan mode's depth gate will classify the work and, for net-new/underspecified briefs, run the heavy tier (PM → design doc → DE review → design sign-off) before breaking the work down and handing off to `/velo:task`.

Do not spawn agents, write PRDs/EDDs, or plan here. The redirect is the whole job.

## Task

$ARGUMENTS

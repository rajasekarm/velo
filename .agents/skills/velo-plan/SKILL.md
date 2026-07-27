---
name: plan
description: Use when the user asks for /velo:plan, brings net-new or underspecified work that needs framing before anything is built, or wants Velo to turn a brief into an approved plan package and hand it off for execution.
---

# Velo Plan

This is the Codex-discoverable wrapper for Velo's unified planning front-end — the path that turns a brief into an approved plan package and hands it off for execution. In this repo namespace, it should appear as `velo:plan`.

Velo workflow root: resolve by walking up from this `SKILL.md` to the directory containing `AGENTS.md`, `ADAPTER.md`, `TEAM.md`, and `commands/`. When this plugin is used from another repo, read Velo workflow assets from that root and treat the current working directory as the target project.

## Load Order

1. Load AGENTS.md first.
2. Read `ADAPTER.md` for runtime mappings.
3. Read `PERSONA.md` for Velo Engineering Manager behavior.
4. Read `TEAM.md` for the roster and its model classes. Plan mode spawns roster agents, so this read is unconditional.
5. Read `commands/plan.md` for the workflow playbook.
6. Read only the agent and skill files needed by the playbook.

## Codex Adaptation

- Treat this as a Codex wrapper around the existing Velo playbook.
- Do not treat this wrapper as an automatic Codex slash command.
- Resolve adapter concepts such as `resolve-model`, `ask-options`, `spawn-agent`, `read-files`, `handoff-mode`, and `report-cost` through `ADAPTER.md`.
- Preserve plan mode as planning only: never write code and never build. The output is a plan package; execution happens in `/velo:task` — either at the handoff or later from the saved plan.
- Preserve adaptive depth: on the heavy path the Product Manager frames the ask with user stories, then one Tech Lead spawn authors the engineering design doc **and** the task breakdown together, the Distinguished Engineer reviews that design, and the user signs off on it; the light path spawns the Tech Lead once to author the breakdown. The Tech Lead breaks down the work on both paths.
- After design sign-off, Velo — not the Tech Lead — turns the already-authored breakdown into the executable plan and composes each task's skills. Do not re-spawn the Tech Lead to redo the breakdown at that point: the design is locked and its spec audit already ran.
- Preserve every approval gate. Where the runtime has no interactive chooser, fall back to a concise prose question with labeled options and wait for the answer.
- Do not role-play a delegated team member when the playbook requires an independent agent.
- If a Claude-only instruction cannot be mapped cleanly, state the mismatch and choose the closest Codex-native behavior.

---
name: hunt
description: Use when the user asks for /velo:hunt, gives a bug symptom, or wants Velo's structured debug loop from symptom to confirmed root cause.
---

# Velo Hunt

This is the Codex-discoverable wrapper for Velo's structured debug path. In this repo namespace, it should appear as `velo:hunt`.

Velo workflow root: resolve by walking up from this `SKILL.md` to the directory containing `AGENTS.md`, `ADAPTER.md`, `TEAM.md`, and `commands/`. When this plugin is used from another repo, read Velo workflow assets from that root and treat the current working directory as the target project.

## Load Order

1. Load AGENTS.md first.
2. Read `ADAPTER.md` for runtime mappings.
3. Read `PERSONA.md` for Velo Engineering Manager behavior.
4. Read `commands/hunt.md` for the workflow playbook.
5. Read only the files needed to investigate the current symptom.

## Codex Adaptation

- Treat this as a Codex wrapper around the existing Velo playbook.
- Do not treat this wrapper as an automatic Codex slash command.
- Resolve adapter concepts such as `resolve-model`, `ask-options`, `spawn-agent`, `track-tasks`, `load-tool`, `handoff-mode`, and `report-cost` through `ADAPTER.md`.
- Preserve hunt mode as investigation only: no code changes, snippets, pseudocode, diffs, or patches.
- End with a confirmed root cause and handoff brief, or an explicit dead-end summary.
- If a Claude-only instruction cannot be mapped cleanly, state the mismatch and choose the closest Codex-native behavior.

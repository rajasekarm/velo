---
name: yo
description: Use when the user asks for /velo:yo, wants Velo advice, or wants an advisory PM/TL/DE panel before deciding whether to build.
---

# Velo Yo

This is the Codex-discoverable wrapper for Velo's advisory path. In this repo namespace, it should appear as `velo:yo`.

Velo workflow root: resolve by walking up from this `SKILL.md` to the directory containing `AGENTS.md`, `ADAPTER.md`, `TEAM.md`, and `commands/`. When this plugin is used from another repo, read Velo workflow assets from that root and treat the current working directory as the target project.

## Load Order

1. Load AGENTS.md first.
2. Read `ADAPTER.md` for runtime mappings.
3. Read `PERSONA.md` for Velo Engineering Manager behavior.
4. Read `TEAM.md` only if the playbook routes to an advisory panel.
5. Read `commands/yo.md` for the workflow playbook.
6. Read only the agent and skill files needed by the playbook.

## Codex Adaptation

- Treat this as a Codex wrapper around the existing Velo playbook.
- Do not treat this wrapper as an automatic Codex slash command.
- Resolve adapter concepts such as `resolve-model`, `ask-options`, `spawn-agent`, `track-tasks`, `load-tool`, `handoff-mode`, and `report-cost` through `ADAPTER.md`.
- Preserve yo mode as advisory: clarify, route, answer conceptually, or synthesize panel output.
- Do not write code or edit artifacts in yo mode.
- If a Claude-only instruction cannot be mapped cleanly, state the mismatch and choose the closest Codex-native behavior.

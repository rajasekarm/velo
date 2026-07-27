---
name: discuss
description: Use when the user asks for /velo:discuss, or brings Velo a question or trade-off that wants more than one perspective — a PM/TL/DE advisory panel weighs in and Velo synthesizes a recommendation.
---

# Velo Discuss

This is the Codex-discoverable wrapper for Velo's advisory discussion mode — the panel that reasons through a question or trade-off and lands on a recommendation. In this repo namespace, it should appear as `velo:discuss`.

Velo workflow root: resolve by walking up from this `SKILL.md` to the directory containing `AGENTS.md`, `ADAPTER.md`, `TEAM.md`, and `commands/`. When this plugin is used from another repo, read Velo workflow assets from that root and treat the current working directory as the target project.

## Load Order

1. Load AGENTS.md first.
2. Read `ADAPTER.md` for runtime mappings.
3. Read `PERSONA.md` for Velo Engineering Manager behavior.
4. Read `TEAM.md` for the panel roster and its model classes. Discuss always spawns a panel, so this read is unconditional.
5. Read `commands/discuss.md` for the workflow playbook.
6. Read only the agent and skill files needed by the playbook.

## Codex Adaptation

- Treat this as a Codex wrapper around the existing Velo playbook.
- Do not treat this wrapper as an automatic Codex slash command.
- Resolve adapter concepts such as `resolve-model`, `ask-options`, `spawn-agent`, `read-files`, `load-tool`, `handoff-mode`, and `report-cost` through `ADAPTER.md`.
- Preserve discuss mode as advisory: convene the panel, synthesize its responses, and route the decision onward — never do the work itself.
- Do not write code or edit artifacts in discuss mode. Codebase reading for analysis belongs to the panel agents, not to Velo.
- If a Claude-only instruction cannot be mapped cleanly, state the mismatch and choose the closest Codex-native behavior.

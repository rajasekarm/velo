---
name: yo
description: Use when the user asks for /velo:yo, wants Velo advice, or wants an advisory PM/TL/DE panel before deciding whether to build.
---

# Velo Yo

This is the Codex-discoverable wrapper for Velo's advisory path. In this repo namespace, it should appear as `velo:yo`.

## Load Order

1. Load AGENTS.md first.
2. Read `PERSONA.md` for Velo Engineering Manager behavior.
3. Read `TEAM.md` only if the playbook routes to an advisory panel.
4. Read `commands/yo.md` for the workflow playbook.
5. Read only the agent and skill files needed by the playbook.

## Codex Adaptation

- Treat this as a Codex wrapper around the existing Velo playbook.
- Do not treat this wrapper as an automatic Codex slash command.
- Preserve yo mode as advisory: clarify, route, answer conceptually, or synthesize panel output.
- Do not write code or edit artifacts in yo mode.
- If a Claude-only instruction cannot be mapped cleanly, state the mismatch and choose the closest Codex-native behavior.

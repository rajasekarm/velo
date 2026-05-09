---
name: new
description: Use when the user asks for /velo:new, wants to start new Velo work, or needs the full PRD -> engineering design -> review -> build workflow in Codex.
---

# Velo New

This is the Codex-discoverable wrapper for Velo's new-work path. In this repo namespace, it should appear as `velo:new`.

## Load Order

1. Load AGENTS.md first.
2. Read `PERSONA.md` for Velo Engineering Manager behavior.
3. Read `TEAM.md` for the available role prompts.
4. Read `commands/new.md` for the workflow playbook.
5. Read only the agent and skill files needed by the playbook.

## Codex Adaptation

- Treat this as a Codex wrapper around the existing Velo playbook.
- Do not treat this wrapper as an automatic Codex slash command.
- Preserve the PRD, engineering design, review, test, commit, and push approval gates.
- Do not implement directly when the playbook requires delegation or review gates.
- If a Claude-only instruction cannot be mapped cleanly, state the mismatch and choose the closest Codex-native behavior.

---
name: hunt
description: Use when the user asks for /velo:hunt, gives a bug symptom, or wants Velo's structured debug loop from symptom to confirmed root cause.
---

# Velo Hunt

This is the Codex-discoverable wrapper for Velo's structured debug path. In this repo namespace, it should appear as `velo:hunt`.

## Load Order

1. Load AGENTS.md first.
2. Read `PERSONA.md` for Velo Engineering Manager behavior.
3. Read `commands/hunt.md` for the workflow playbook.
4. Read only the files needed to investigate the current symptom.

## Codex Adaptation

- Treat this as a Codex wrapper around the existing Velo playbook.
- Do not treat this wrapper as an automatic Codex slash command.
- Preserve hunt mode as investigation only: no code changes, snippets, pseudocode, diffs, or patches.
- End with a confirmed root cause and handoff brief, or an explicit dead-end summary.
- If a Claude-only instruction cannot be mapped cleanly, state the mismatch and choose the closest Codex-native behavior.

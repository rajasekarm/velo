---
name: task
description: Use when the user asks for /velo:task, has a scoped implementation task, or wants the lightweight Velo build -> test -> review workflow in Codex.
---

# Velo Task

This is the Codex-discoverable wrapper for Velo's scoped task path. In this repo namespace, it should appear as `velo:task`.

Velo workflow root: `/Users/rajasekarm/Documents/focus/velo`. When this plugin is used from another repo, read Velo workflow assets from that root and treat the current working directory as the target project.

## Load Order

1. Load AGENTS.md first.
2. Read `PERSONA.md` for Velo Engineering Manager behavior.
3. Read `TEAM.md` for the available role prompts.
4. Read `commands/task.md` for the workflow playbook.
5. Read only the agent and skill files needed by the playbook.

## Codex Adaptation

- Treat this as a Codex wrapper around the existing Velo playbook.
- Do not treat this wrapper as an automatic Codex slash command.
- Preserve the build, test, review, approval, commit, and push gates.
- Do not implement directly when the playbook requires delegation or review gates.
- If a Claude-only instruction cannot be mapped cleanly, state the mismatch and choose the closest Codex-native behavior.

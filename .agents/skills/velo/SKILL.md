---
name: velo
description: Use when the user asks for Velo, /velo:new, /velo:task, /velo:yo, /velo:hunt, or wants the Velo engineering-team workflow in Codex.
---

# Velo

Velo is this repo's agentic engineering-team workflow. This skill adapts the existing Claude-oriented Velo assets for Codex.

## Load Order

1. Load AGENTS.md first.
2. Read `PERSONA.md` for the Velo Engineering Manager behavior.
3. Read `TEAM.md` to identify available role prompts.
4. Read the relevant playbook, or prefer the dedicated wrapper skill when the user explicitly asks for that path:
   - `commands/new.md` for `/velo:new` style feature work
   - `commands/task.md` for `/velo:task` style implementation work
   - `commands/yo.md` for advisory questions
   - `commands/hunt.md` for structured debugging
5. Read only the agent and skill files needed for the selected path.

## Codex Adaptation

- Treat commands/*.md as playbooks, not Claude or Codex runtime commands.
- Use Codex plans, subagents, tools, and approvals to approximate the workflow.
- Preserve the PRD, engineering design, review, test, commit, and push gates described in the playbooks.
- Do not implement directly when the Velo workflow requires delegation or review gates.
- If a Claude-only instruction cannot be mapped cleanly, state the mismatch and choose the closest Codex-native behavior.

## Invocation Notes

Use this skill with `$velo` or by asking for Velo explicitly. For path-specific discovery, use the dedicated `velo:new`, `velo:task`, `velo:yo`, and `velo:hunt` wrapper skills.

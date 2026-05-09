---
name: update-skill
description: Sync a skill from upstream GitHub AGENTS.md. Fetches the latest, splits into per-category rule files, regenerates the compact SKILL.md index.
---
# Sync Agent Skill

**Scope:** Fetch the latest AGENTS.md from a GitHub repo, split it into per-category rule files, and generate a compact SKILL.md index.

## When to use
- User asks to update or refresh a skill from its upstream source
- User says "pull the latest" for a skill that was imported from a GitHub repo
- Any skill whose `SKILL.md` has a `<!-- TO UPDATE: ... -->` comment

## How to sync any skill

Run from the repo root:
```bash
./scripts/sync-agent-skill.sh <skill-name> <owner/repo> <path/to/AGENTS.md>
```

## Known skills with upstream sources

| Skill | Command to update |
|---|---|
| `skills/vercel-react-best-practices.md` (+ `skills/vercel-react-best-practices-rules/`) | `./scripts/sync-agent-skill.sh vercel-react-best-practices vercel-labs/agent-skills skills/react-best-practices/AGENTS.md` |

## What the script produces

```
skills/<skill-name>.md            ← compact index (always loaded by agent, ~90 lines)
skills/<skill-name>-rules/
  01-*.md                         ← full section content (read on demand)
  02-*.md
  ...
```

The flat-file form (not `skills/<name>/SKILL.md`) avoids Claude Code's auto-discovery exposing the skill as a `/<plugin>:<name>` slash command.

## How to identify the update command

Open the skill index file — the exact command is in the header:
```
<!-- TO UPDATE: ./scripts/sync-agent-skill.sh ... -->
```

## Requirements
- `gh` CLI installed and authenticated (`gh auth status`)
- `python3` available in PATH

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
| `skills/vercel-react-best-practices/` | `./scripts/sync-agent-skill.sh vercel-react-best-practices vercel-labs/agent-skills skills/react-best-practices/AGENTS.md` |

## What the script produces

```
skills/<skill-name>/
  SKILL.md          ← compact index (always loaded by agent, ~90 lines)
  rules/
    01-*.md         ← full section content (read on demand)
    02-*.md
    ...
```

## How to identify the update command

Open any `SKILL.md` — the exact command is in the header:
```
<!-- TO UPDATE: ./scripts/sync-agent-skill.sh ... -->
```

## Requirements
- `gh` CLI installed and authenticated (`gh auth status`)
- `python3` available in PATH

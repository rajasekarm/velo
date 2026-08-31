# Velo V2

Clean-room rebuild of Velo. The current surface is **Ask mode only**.

## Ask — `/velo:ask` (Claude Code) · `velo:ask` (Codex)

Ask is off-axis, read-only Q&A. It answers conceptual questions — design trade-offs, patterns, "how does X work" — from model knowledge and the current conversation only. At runtime it:

- reads no repository files, runs no shell, browses nothing, uses no connectors, spawns no subagents
- writes nothing — no `.velo` task, draft, carrier, branch, commit, PR, or resumable session record
- returns only a conversational answer

Empty input gets a prompt for a question. Requests to build, debug, review, or investigate get a concise suggested Velo route by name (Pair, Run, or Auto) — Ask never starts another mode.

## Layout

- `.claude-plugin/plugin.json` — Claude Code plugin manifest (plugin name `velo` → command `/velo:ask`)
- `commands/ask.md` — the Ask playbook and its read-only behavioral contract
- `.codex-plugin/plugin.json` — Codex plugin manifest (`skills` → `.agents/skills/`)
- `.agents/skills/velo-ask/SKILL.md` — self-contained Codex skill wrapper for `velo:ask`

## Not in this build

Pair, Run, Auto, role orchestration, kernel/broker isolation, containers, persistence, migration, and evaluation machinery are intentionally absent. Ask may name them as routes; it never implements or starts them.

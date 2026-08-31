# Velo V2

Clean-room rebuild of Velo. The current surface is **two modes: Ask and Plan**.

## Ask — `/velo:ask` (Claude Code) · `velo:ask` (Codex)

Ask is off-axis, read-only Q&A. It answers conceptual questions — design trade-offs, patterns, "how does X work" — from model knowledge and the current conversation only. At runtime it:

- reads no repository files, runs no shell, browses nothing, uses no connectors, spawns no subagents
- writes nothing — no `.velo` task, draft, carrier, branch, commit, PR, or resumable session record
- returns only a conversational answer

Empty input gets a prompt for a question. Requests to build, debug, review, or investigate get a concise suggested Velo route by name — `/velo:plan` for planning the work, or Run and Auto as future routes — Ask never starts another mode.

## Plan — `/velo:plan` (Claude Code) · `velo:plan` (Codex)

Plan turns a brief into a persisted, versioned plan: one carrier per work item at `.velo/tasks/<slug>/task-breakdown.md` in the house format, plus a row in `.velo/tasks/index.md`. The carrier IS the plan. At runtime it:

- may read the repository, the conversation, and `.velo/` context to plan well; runs as a single conversational flow with no subagents
- writes only under `.velo/` — no source edits, no branches, commits, pushes, or PRs, no build or test execution
- versions the plan (`Plan-version:` starts at 1) and offers explicit approval; approval freezes the version in the `Approval:` header key, and a material change after approval bumps the version, clears the approval, and requires reapproval
- stops at approval — a frozen plan waits for a future Run mode; Plan never executes it

Empty input gets a prompt for what to plan. Requests to execute, build, or debug directly get a plain explanation that this build ships Ask and Plan, plus an offer to plan the work — never auto-execution.

## Layout

- `.claude-plugin/plugin.json` — Claude Code plugin manifest (plugin name `velo` → commands `/velo:ask`, `/velo:plan`)
- `commands/ask.md` — the Ask playbook and its read-only behavioral contract
- `commands/plan.md` — the Plan playbook: the versioned plan carrier, the approval freeze, and the `.velo/`-only write scope
- `.codex-plugin/plugin.json` — Codex plugin manifest (`skills` → `.agents/skills/`)
- `.agents/skills/velo-ask/SKILL.md` — self-contained Codex skill wrapper for `velo:ask`
- `.agents/skills/velo-plan/SKILL.md` — self-contained Codex skill wrapper for `velo:plan`

## Not in this build

Run, Auto, role orchestration, kernel/broker isolation, containers, migration, and autonomy/eval machinery are intentionally absent. Ask and Plan may name Run and Auto as routes; neither implements or starts them, and nothing here executes a plan.

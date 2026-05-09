# Velo for Codex

AGENTS.md is the Codex-native entrypoint for this repo.

## Scope

These instructions apply to the entire repository.

Velo was originally designed around Claude Code. Keep Claude compatibility explicit through `ADAPTER.md` instead of hard-coding runtime-specific workflow terms in shared playbooks.

## Codex Mapping

- Treat `PERSONA.md` as Velo Engineering Manager behavior shared by the playbooks, not as Codex's primary instruction file.
- Treat `ADAPTER.md` as the runtime compatibility contract for concept names such as `resolve-model`, `ask-options`, `spawn-agent`, `track-tasks`, `load-tool`, `handoff-mode`, and `report-cost`.
- Treat `TEAM.md` as the roster of reusable role prompts.
- Treat `TEAM.md` model classes as provider-neutral routing intent; resolve them through `ADAPTER.md` instead of reading them as provider model names.
- Treat `agents/*.md` as role prompt templates that Codex can read when a task needs that role.
- Treat `model:` frontmatter in `agents/*.md` as a Claude compatibility hint, not as Codex routing authority.
- Treat `skills/*.md` as local reference material. They are not Codex skills unless converted into `SKILL.md` directories.
- Keep Velo as the umbrella Engineering Manager concept, not as a separate Codex-discoverable skill.
- Do not add a generic `.agents/skills/velo/SKILL.md`; the visible Codex command surface is mode-only.
- Treat `.agents/skills/velo-{new,task,yo,hunt}/SKILL.md` as path-specific Codex wrapper files whose skill names expose `velo:new`, `velo:task`, `velo:yo`, and `velo:hunt`.
- Treat `.codex-plugin/plugin.json` as the local Codex plugin manifest. It points Codex at `./.agents/skills/` so this repo can be symlinked as a live local plugin.
- Treat commands/*.md as workflow playbooks, not automatic Codex slash commands.
- Use Codex slash commands for session control only.

## Workflow

- Before starting a task, provide a concrete plan broken into small, incremental steps.
- Write tests before implementation changes when the task changes behavior or validation logic.
- Prefer explicit, maintainable changes over clever shortcuts.
- Keep changes scoped to the requested workflow, agent, skill, command, or audit behavior.
- Flag DRY violations and stale references aggressively.
- Preserve existing approval gates unless the user explicitly asks to remove them.

## Review Expectations

When asked for a review, lead with findings ordered by severity. Include concrete file and line references. Call out missing tests, weak assertions, failure modes, edge cases, security concerns, and performance risks.

When reviewing a plan, cover architecture, code quality, tests, and performance. For each issue, give options with tradeoffs and an opinionated recommendation before asking for direction.

## Git Safety

- Do not commit or push without explicit per-action approval.
- Treat commit approval and push approval as separate decisions.
- Never revert user changes unless the user explicitly asks.
- If the worktree is dirty, preserve unrelated changes and work around them.

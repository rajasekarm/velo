---
name: plan
description: Use when the user asks for /velo:plan or velo:plan, or brings work Velo should turn into a persisted, versioned plan — Plan reads to plan well, writes only under `.velo/`, offers explicit approval that freezes the plan version, and never executes the plan or starts another mode.
---

# Velo Plan

This is the Codex-discoverable wrapper for Velo V2's Plan mode — persisted, versioned planning with an explicit approval freeze. In this repo namespace, it should appear as `velo:plan`.

This wrapper is self-contained. Velo V2 has no AGENTS.md, ADAPTER.md, or PERSONA.md; do not go looking for them. The plugin root is the directory reached by walking up from this `SKILL.md` to the directory containing `commands/plan.md`.

## Load Order

1. Read `commands/plan.md` from the plugin root for the Plan playbook. That is the only file to read up front, and reading it is mode bootstrap — loading the playbook, not yet planning. Every other read Plan performs afterward (repository files, `.velo/` context) is planning work the playbook governs.

## Codex Adaptation

- Treat this as a Codex wrapper around the Plan playbook in `commands/plan.md`; the playbook's Hard Rule is the contract and applies verbatim.
- Do not treat this wrapper as an automatic Codex slash command.
- Plan may read the repository, the current conversation, and `.velo/` context to plan well, and runs as a single conversational flow — no subagents, no delegation, no spawned roles.
- Plan writes ONLY under `.velo/`: the task folder `.velo/tasks/<slug>/`, its `task-breakdown.md` carrier — the house-format plan, with the header keys, the brief verbatim, assumptions, constraints, artifacts, `## M<i>` milestones holding `T<n>` task lines, and a per-milestone `Execution:` batching line, all as the playbook specifies — and the task's row in `.velo/tasks/index.md`. No source changes, no branches, no commits, no pushes, no PRs, no building or testing.
- The carrier is versioned: `Plan-version:` starts at 1; pre-approval revisions rewrite the current version in place; only an explicit user approval freezes it, recorded in the `Approval:` header key (`—` until approved, then `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>`) plus a matching one-line event bullet in the carrier's `Constraints/notes`. A material change after approval — the plan's deliverables or scope, affected surface, risk class, or required evidence — bumps to v<N+1>, clears the approval, and requires reapproval; wording-only edits never bump.
- After presenting the plan, offer exactly three choices: approve, revise, or stop and save unapproved. On approval, announce the plan is frozen and ready for a future Run mode, then stop completely — never implement, simulate, or "preview" the planned work.
- Empty input: ask the user what to plan and stop.
- Requests to execute, build, or debug directly: explain that this build of Velo ships Ask and Plan — nothing here executes work — and offer to plan it; never auto-execute, and never start, invoke, or simulate Run or Auto.
- Slug rules per the playbook: lowercase and hyphenated from the work's name; an unambiguous reference to an existing plan re-opens that carrier instead of duplicating it; a colliding slug for genuinely new work gets a `-2`, `-3` suffix; missing `.velo/tasks/` or `index.md` scaffolding is created on first use.
- If a Claude-only instruction in the playbook cannot be mapped cleanly, state the mismatch and choose the closest Codex-native behavior that keeps the `.velo/`-only write scope and the approval freeze intact.

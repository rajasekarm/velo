# Velo V2

Clean-room rebuild of Velo. The current surface is **two modes: Plan and Run**.

## Plan — `/velo:plan` (Claude Code) · `velo:plan` (Codex)

Plan turns a brief into a persisted, versioned plan: one carrier per work item at `.velo/tasks/<slug>/task-breakdown.md` in the house format, plus a row in `.velo/tasks/index.md`. The carrier IS the plan. At runtime it:

- may read the repository, the conversation, and `.velo/` context to plan well; runs as a single conversational flow with no subagents
- writes only under `.velo/` — no source edits, no branches, commits, pushes, or PRs, no build or test execution
- versions the plan (`Plan-version:` starts at 1) and offers explicit approval; approval freezes the version in the `Approval:` header key, and a material change after approval bumps the version, clears the approval, and requires reapproval
- stops at approval — a frozen plan waits for `/velo:run`; Plan never executes it

Empty input gets a prompt for what to plan. Requests to execute, build, or debug directly get a plain explanation that execution belongs to `/velo:run` from a frozen, approved plan — plus an offer to plan the work; never auto-execution.

## Run — `/velo:run` (Claude Code) · `velo:run` (Codex)

Run executes a plan that Plan has frozen — and only such a plan: the carrier must carry `Plan-version:`, an `Approval:` of `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>`, and `Phase: PLAN (Plan — v<N> approved)`. At runtime it:

- executes one milestone at a time, handing each task line to a real subagent per the milestone's `Execution:` batching (`<agent>` and `skills:` labels are advisory); on a host without subagents it discloses the single-flow fallback plainly before work starts and executes the task lines itself in the same batch order
- gates every milestone on green checks — run, never assumed — plus one independent adversarial review, recorded as not independent when self-performed in a single flow; findings drive rework cycles recorded in the carrier header
- creates the milestone branch the carrier names — M1's from the repository's default branch, a later milestone's from the previous milestone's tip when that work is not yet on the default branch — and commits the milestone's work locally with evidence in the message; it never pushes, merges, or opens PRs — shipping past the local commit is the maintainer's call
- treats the plan body as read-only and writes only progress marks: task-line `Status:`, `Phase:`, `Last gate passed:`, `Rework cycles:`, `Updated:`, event bullets, and the task's index row
- pauses fail-closed on a material change or tripwire — the current task line marked `blocked`, a pause bullet naming the reason — and routes material changes to `/velo:plan` for a version bump and reapproval; it never widens scope silently

Empty input gets the list of `planned` plans and a prompt to choose. An unapproved carrier is routed to `/velo:plan` for approval; a done carrier is finished work.

## Layout

- `.claude-plugin/plugin.json` — Claude Code plugin manifest (plugin name `velo` → commands `/velo:plan`, `/velo:run`)
- `commands/plan.md` — the Plan playbook: the versioned plan carrier, the approval freeze, and the `.velo/`-only write scope
- `commands/run.md` — the Run playbook: frozen-plan preconditions, the milestone execution seam, the checks-plus-review done gate, and the local-commit boundary
- `.codex-plugin/plugin.json` — Codex plugin manifest (`skills` → `.agents/skills/`)
- `.agents/skills/plan/SKILL.md` — self-contained Codex skill wrapper for `velo:plan`
- `.agents/skills/run/SKILL.md` — self-contained Codex skill wrapper for `velo:run`

## Not in this build

Role orchestration, kernel/broker isolation, containers, migration machinery, and the V2 replacement gate are intentionally absent. Both modes — Plan and Run — are real routes; no mode pushes, merges, or opens PRs, and shipping past local commits stays the maintainer's call.

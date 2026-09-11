# Velo

Clean-room rebuild of Velo. The current surface is **three modes: Plan, Run, and Verify**.

## Plan — `/velo:plan` (Claude Code) · `velo:plan` (Codex)

Plan turns a request into a persisted, versioned plan: one plan file per work item at `.velo/tasks/<slug>/task-breakdown.md` in the plan format, plus a row in `.velo/tasks/index.md`. At runtime it:

- may read the repository, the conversation, and `.velo/` context to plan well; runs as a single conversational flow with no subagents
- writes only under `.velo/` — no source edits, no branches, commits, pushes, or PRs, no build or test execution
- includes an Architecture section with an inline Mermaid diagram when it helps explain components or data flow, or when explicitly requested
- defines acceptance criteria, task/milestone coverage, and verification setup; browser criteria select Chrome DevTools MCP, Playwriter, or either available provider
- versions the plan (`Plan-version:` starts at 1) and offers explicit approval; approval freezes the version in the `Approval:` header key, and a material change after approval bumps the version, clears the approval, and requires reapproval
- follows requirement → clarify → write → review → freeze → Run; feedback loops through revision and clarification as needed, and explicit approval hands the frozen version to Run unless the user requests freeze only

Empty input gets a prompt for what to plan. Requests to execute, build, or debug directly get a plain explanation that execution belongs to `/velo:run` from a frozen, approved plan — plus an offer to plan the work; never auto-execution.

The [workflow state machine](.agents/skills/plan/references/workflow.md) defines each state, transitions, revision loop, and which guide to load. The agent follows these instructions; there is no enforcing runtime.

## Run — `/velo:run` (Claude Code) · `velo:run` (Codex)

Run executes a plan that Plan has frozen — and only such a plan: the plan file must carry `Plan-version:`, an `Approval:` of `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>`, and `Phase: PLAN (Plan — v<N> approved)`. At runtime it:

- executes one milestone at a time, handing each task line to a real subagent per the milestone's `Execution:` batching (`<agent>` and `skills:` labels are advisory); on a host without subagents it discloses the single-flow fallback plainly before work starts and executes the task lines itself in the same batch order
- verifies due acceptance criteria and records pass/fail/blocked evidence; Verify handles browser checks through the configured provider, and blocked required verification pauses execution
- gates every milestone on green checks — run, never assumed — plus one independent adversarial review, recorded as not independent when self-performed in a single flow; findings drive rework cycles recorded in the plan file header
- creates the milestone branch the plan file names — M1's from the repository's default branch, a later milestone's from the previous milestone's tip when that work is not yet on the default branch — and commits the milestone's work locally with evidence in the message; it never pushes, merges, or opens PRs — shipping past the local commit is the maintainer's call
- treats the plan body as read-only and writes only progress marks: task-line `Status:`, `Phase:`, `Last gate passed:`, `Rework cycles:`, `Updated:`, event bullets, and the task's index row
- pauses fail-closed on a material change or tripwire — the current task line marked `blocked`, a pause bullet naming the reason — and routes material changes to `/velo:plan` for a version bump and reapproval; it never widens scope silently

Empty input gets the list of `planned` plans and a prompt to choose. An unapproved plan file is routed to `/velo:plan` for approval; a done plan file is finished work.

## Verify — `/velo:verify` (Claude Code) · `velo:verify` (Codex)

Verify checks existing changes against a plan's acceptance criteria or explicit criteria supplied with a target. It reports pass, fail, or blocked with actions, expected/observed results, and evidence. Browser checks use Chrome DevTools MCP or Playwriter when configured; API, command, and attributed manual evidence are also supported.

Verify may start the specified local app and run existing checks, but it does not fix source, change the plan, install tools, approve work, or commit. Standalone Verify returns a report; Run calls it for milestone acceptance evidence, records results, and owns the repair loop. A required blocked check prevents milestone completion. Browser tools must be installed/configured separately.

Examples: `velo:verify task-list-search M1` or `velo:verify http://localhost:3000/tasks — searching REPORT should find Monthly Report; clearing should restore the original list`.

## Layout

- `.claude-plugin/plugin.json` — Claude Code plugin manifest (plugin name `velo` → commands `/velo:plan`, `/velo:run`, `/velo:verify`)
- `commands/plan.md` — the shared Plan entrypoint: boundaries, intake, and routing to guides loaded only when needed
- `commands/run.md` — the Run playbook: frozen-plan preconditions, the milestone execution seam, the checks-plus-review done gate, and the local-commit boundary
- `.codex-plugin/plugin.json` — Codex plugin manifest (`skills` → `.agents/skills/`)
- `.agents/skills/plan/SKILL.md` — Codex entrypoint for `velo:plan`, loading the shared Plan instructions
- `.agents/skills/plan/references/` — workflow state machine, drafting, plan format, and approval/versioning guides, shared by Claude Code and Codex
- `commands/verify.md` — shared verification workflow and report format
- `.agents/skills/verify/SKILL.md` — Codex entrypoint for `velo:verify`
- `.agents/skills/verify/references/browser-verification.md` — on-demand Chrome DevTools MCP and Playwriter guidance
- `.agents/skills/run/SKILL.md` — self-contained Codex skill wrapper for `velo:run`

## Not in this build

Role orchestration, kernel/broker isolation, containers, migration machinery, and the V2 replacement gate are intentionally absent. All three modes — Plan, Run, and Verify — are real routes; no mode pushes, merges, or opens PRs, and shipping past local commits stays the maintainer's call.

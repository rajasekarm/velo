# Velo V2

Clean-room rebuild of Velo. The current surface is **four modes: Ask, Plan, Run, and Auto**.

## Ask — `/velo:ask` (Claude Code) · `velo:ask` (Codex)

Ask is off-axis, read-only Q&A. It answers conceptual questions — design trade-offs, patterns, "how does X work" — from model knowledge and the current conversation only. At runtime it:

- reads no repository files, runs no shell, browses nothing, uses no connectors, spawns no subagents
- writes nothing — no `.velo` task, draft, carrier, branch, commit, PR, or resumable session record
- returns only a conversational answer

Empty input gets a prompt for a question. Requests to build, debug, review, or investigate get a concise suggested Velo route by name — `/velo:plan` for planning the work, `/velo:run` for executing an approved plan, or `/velo:auto` for hands-off end-to-end delivery — Ask never starts another mode.

## Plan — `/velo:plan` (Claude Code) · `velo:plan` (Codex)

Plan turns a brief into a persisted, versioned plan: one carrier per work item at `.velo/tasks/<slug>/task-breakdown.md` in the house format, plus a row in `.velo/tasks/index.md`. The carrier IS the plan. At runtime it:

- may read the repository, the conversation, and `.velo/` context to plan well; runs as a single conversational flow with no subagents
- writes only under `.velo/` — no source edits, no branches, commits, pushes, or PRs, no build or test execution
- versions the plan (`Plan-version:` starts at 1) and offers explicit approval; approval freezes the version in the `Approval:` header key, and a material change after approval bumps the version, clears the approval, and requires reapproval
- stops at approval — a frozen plan waits for `/velo:run` or `/velo:auto`; Plan never executes it

Empty input gets a prompt for what to plan. Requests to execute, build, or debug directly get a plain explanation that execution belongs to `/velo:run` from a frozen, approved plan — or to `/velo:auto` end-to-end — plus an offer to plan the work; never auto-execution.

## Run — `/velo:run` (Claude Code) · `velo:run` (Codex)

Run executes a plan that Plan has frozen — and only such a plan: the carrier must carry `Plan-version:`, an `Approval:` of `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>`, and `Phase: PLAN (Plan — v<N> approved)`. At runtime it:

- executes one milestone at a time, handing each task line to a real subagent per the milestone's `Execution:` batching (`<agent>` and `skills:` labels are advisory); on a host without subagents it discloses the single-flow fallback plainly before work starts and executes the task lines itself in the same batch order
- gates every milestone on green checks — run, never assumed — plus one independent adversarial review, recorded as not independent when self-performed in a single flow; findings drive rework cycles recorded in the carrier header
- creates the milestone branch the carrier names — M1's from the repository's default branch, a later milestone's from the previous milestone's tip when that work is not yet on the default branch — and commits the milestone's work locally with evidence in the message; it never pushes, merges, or opens PRs — shipping past the local commit is the maintainer's call
- treats the plan body as read-only and writes only progress marks: task-line `Status:`, `Phase:`, `Last gate passed:`, `Rework cycles:`, `Updated:`, event bullets, and the task's index row
- pauses fail-closed on a material change or tripwire — the current task line marked `blocked`, a pause bullet naming the reason — and routes material changes to `/velo:plan` for a version bump and reapproval; it never widens scope silently

Empty input gets the list of `planned` plans and a prompt to choose. An unapproved carrier is routed to `/velo:plan` for approval; a done carrier is finished work.

## Auto — `/velo:auto` (Claude Code) · `velo:auto` (Codex)

Auto spans Plan and Run end-to-end under a single explicit approval — a span over the two shipped seams, not a third pipeline. At runtime it:

- routes intake: empty input gets a prompt for what to deliver; a pure question gets `/velo:ask` suggested; a request naming an existing frozen plan skips the planning leg and runs under Auto's gate; anything else is planned first
- drives the Plan playbook to a versioned, frozen plan and takes the one explicit approval exactly as Plan does — nothing is ever auto-approved; after the freeze it proceeds through all milestones without pausing for user input (the user may interrupt, and any tripwire re-involves them)
- executes through the Run playbook with the same preconditions, delegation, advisory labels, progress marks, branch bases, and local-commit scope — it never pushes, merges, or opens PRs
- replaces Run's one-reviewer gate with the quorum — the only behavioral delta from Run: green checks (run, never assumed) plus three independent cold reviewers passing at least 2 of 3 with no unresolved blocking finding; ship bullets record `review passed (quorum 3/3)` or `review passed (quorum 2/3)`, and a quorum pause names `quorum failed (<n>/3)`
- refuses autonomous execution on a host without subagents — a single flow cannot provide independent cold review, so this is a refusal, not a fallback — and offers `/velo:plan` or an attended `/velo:run` instead
- pauses fail-closed on Run's tripwire family plus quorum failure; every pause downgrades to `/velo:plan` for an informed decision, and Auto never resumes past a pause without the recorded gate satisfied

## Layout

- `.claude-plugin/plugin.json` — Claude Code plugin manifest (plugin name `velo` → commands `/velo:ask`, `/velo:plan`, `/velo:run`, `/velo:auto`)
- `commands/ask.md` — the Ask playbook and its read-only behavioral contract
- `commands/plan.md` — the Plan playbook: the versioned plan carrier, the approval freeze, and the `.velo/`-only write scope
- `commands/run.md` — the Run playbook: frozen-plan preconditions, the milestone execution seam, the checks-plus-review done gate, and the local-commit boundary
- `commands/auto.md` — the Auto playbook: the span over the Plan and Run seams, the single approval, the three-cold-reviewer quorum gate, and the downgrade-to-Plan pause protocol
- `.codex-plugin/plugin.json` — Codex plugin manifest (`skills` → `.agents/skills/`)
- `.agents/skills/velo-ask/SKILL.md` — self-contained Codex skill wrapper for `velo:ask`
- `.agents/skills/velo-plan/SKILL.md` — self-contained Codex skill wrapper for `velo:plan`
- `.agents/skills/velo-run/SKILL.md` — self-contained Codex skill wrapper for `velo:run`
- `.agents/skills/velo-auto/SKILL.md` — self-contained Codex skill wrapper for `velo:auto` (on Codex it refuses autonomous execution — no subagents — and offers Plan or attended Run)

## Not in this build

Role orchestration, kernel/broker isolation, containers, migration machinery, and the V2 replacement gate are intentionally absent. All four modes — Ask, Plan, Run, and Auto — are real routes; no mode pushes, merges, or opens PRs, and shipping past local commits stays the maintainer's call.

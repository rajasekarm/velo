---
name: run
description: Use when the user asks for /velo:run or velo:run, or asks Velo to execute an approved plan — Run consumes only a plan file frozen by Plan, executes it milestone by milestone through delegated task work gated by green checks plus one independent review, commits the work locally on the plan file's milestone branches, writes only progress marks, and never pushes, merges, or opens PRs.
---

# Velo Run

This is the Codex-discoverable wrapper for Velo V2's Run mode — frozen-plan execution with local commits. In this repo namespace, it should appear as `velo:run`.

This wrapper is self-contained. Velo V2 has no AGENTS.md, ADAPTER.md, or PERSONA.md; do not go looking for them. The plugin root is the directory reached by walking up from this `SKILL.md` to the directory containing `commands/run.md`.

## Load Order

1. Read `commands/run.md` from the plugin root for the Run playbook. That is the only file to read up front, and reading it is mode bootstrap — loading the playbook, not yet running the plan. Every read and write Run performs afterward — the plan file, the repository, the milestone work — is execution the playbook governs.

## Codex Adaptation

- Treat this as a Codex wrapper around the Run playbook in `commands/run.md`; the playbook's Hard Rule is the contract and applies verbatim.
- Do not treat this wrapper as an automatic Codex slash command.
- Run consumes ONLY a plan file Plan has frozen: `Plan-version:` present, `Approval:` reading `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>`, and `Phase:` reading `PLAN (Plan — v<N> approved)`. An unapproved plan file gets a plain refusal and a suggestion to approve it via `/velo:plan`; a done plan file is finished work; a missing or ambiguous reference gets a question, not a guess; empty input gets the list of `planned` rows from `.velo/tasks/index.md` and a question — never an unprompted pick.
- The plan body is read-only: the original request, assumptions, architecture, acceptance criteria and verification expectations, constraints, milestones, and task-line text never change here. Run writes only progress marks — task-line `Status:` (`pending` → `in-flight` → `done`/`blocked`), `Phase:`, `Last gate passed:`, `Rework cycles:`, `Updated:`, event bullets in `## Constraints/notes`, and the task's index row (`planned` → `in-progress` → `done`) — with the exact values the playbook pins.
- Execution is milestone-at-a-time, following each milestone's `Execution:` batching. Codex has no subagent mechanism, so the playbook's single-flow fallback applies: state plainly, before any work starts, that the task lines will be executed in this flow itself, in the same batch order, and that the milestone review will therefore not be independent.
- The done gate per milestone: every executable check the plan or the repository defines runs green — run and observed, never assumed — plus one adversarial review of the milestone's work against the plan file. On Codex that review is a structured adversarial self-review, and the plan file's ship bullet records it as not independent (single flow). Findings drive rework; `Rework cycles:` advances in the plan file header, and a required check that stays red after in-scope rework pauses the run.
- When the plan defines acceptance criteria, require current passing evidence for every criterion due in the milestone and record Verification event bullets per the playbook. Call [Verify](../verify/SKILL.md) with the approved plan/version and milestone criteria; it returns evidence and Run records it. Verify loads browser guidance only when needed and supports Chrome DevTools MCP or Playwriter. A required blocked check pauses; a failed check drives scoped rework. Never substitute browser evidence for required backend checks.
- Repository scope, exactly: create the milestone branch the plan file names (`Branch: <slug>-m<i>`) and commit the milestone's work locally with evidence in the message — checks run, review verdict, rework count. M1's branch cuts from the repository's default branch; M<i>'s branch cuts from the previous milestone's tip when that work is not yet on the default branch, else from the default branch. Never push, never merge, never open a PR, never touch origin — shipping past the local commit is the maintainer's explicit call.
- Pause fail-closed on a material change (the Plan seam's definition: the plan's deliverables or scope, affected surface, risk class, or required evidence): mark the current task line `blocked`, append a pause event bullet naming the reason, tell the user, and route to `/velo:plan` for a version bump and reapproval. Never widen scope silently; never resume a material-change pause without a newly frozen version. The same protocol covers the tripwires: a required check that stays red after in-scope rework, a plan file missing, unreadable, or edited out from under the run, and a conflicting dirty working tree, and a pre-existing branch carrying a milestone-branch name the run has no record of creating. Pausing preserves state; nothing is discarded.
- Completion: each shipped milestone appends its ship bullet with the commit reference; after the final milestone, set `Phase: DONE (Done — delivered-and-committed on <slug>-m<final>)`, flip the index row to `done`, announce that pushing, merging, and PRs remain the maintainer's, and stop completely.
- Run may invoke Verify for evidence and continue after its report. Run never starts Plan or another mode automatically.
- If a Claude-only instruction in the playbook cannot be mapped cleanly, state the mismatch and choose the closest Codex-native behavior that keeps the frozen-plan preconditions, the progress-marks-only write scope, and the local-commit boundary intact.

# PRD: velo:status Command

> Version: 1.0 -- 2026-04-11
> Author: Product Manager
> Status: Draft

---

## Problem Statement

Velo orchestrates multi-agent workflows that can involve 5-10+ specialist agents running across sequential and parallel phases. Today, the user has **no way to inspect progress mid-flight**. The only visibility into what happened comes from the final summary report, which is only printed after all phases complete.

This creates three concrete pain points:

1. **Blind waiting** -- During a `velo:new` run, the user cannot tell whether the workflow is in the PM phase, waiting for Tech Lead review, or halfway through the build. They have no signal to act on until everything finishes.
2. **No recovery context** -- If a session is interrupted (timeout, crash, user closes terminal), there is no record of which agents completed successfully. The user must re-read chat history or start over.
3. **No audit trail between sessions** -- After a task completes, the only record is the final summary printed to the terminal. If the user scrolls past it or starts a new session, that context is gone.

**Who benefits**: Any developer using Velo to orchestrate multi-agent work -- especially for longer `velo:new` workflows that involve planning, review gates, and multi-stream builds.

---

## Goals

- G1: Let the user see the current state of any active or completed task at any time by running `velo:status`
- G2: Show which phase the task is in, which agents have run, and what their outcomes were
- G3: Persist task state to disk so it survives session interruptions
- G4: Require zero changes to how existing commands (`velo:new`, `velo:task`) are invoked by the user

## Non-Goals

- NG1: Real-time streaming progress (live-updating dashboard). This is a point-in-time snapshot.
- NG2: Modifying or resuming interrupted workflows. Status is read-only.
- NG3: Multi-task comparison or analytics across tasks (e.g., "show me average token usage across all tasks").
- NG4: Web UI or GUI. This is a CLI command that prints to the terminal.
- NG5: Retroactive status for tasks completed before this feature ships. Only tasks tracked going forward.

---

## Brainstorming: Three Approaches

### Approach A: File-based status tracking with a status.json manifest

Each task folder (`.velo/tasks/<slug>/`) gets a `status.json` file that Velo writes to as agents start, complete, or fail. The `velo:status` command reads this file and renders a formatted report.

**How it works:**
- `velo:new` and `velo:task` write phase transitions and agent outcomes to `.velo/tasks/<slug>/status.json`
- `velo:status` reads the JSON file and prints a formatted summary
- The file is append-friendly: each agent run adds an entry to an array

**Pros:**
- Simple to implement -- just file reads/writes, no new infrastructure
- Naturally persists across sessions (it is a file on disk)
- Easy to inspect manually (`cat status.json`)
- Fits the existing pattern where task artifacts live in `.velo/tasks/<slug>/`

**Cons:**
- Requires modifying `new.md` and `task.md` to write status updates
- JSON can get stale if Velo crashes mid-write (mitigated by atomic writes)

### Approach B: Git-based tracking using commit metadata or tags

Use git notes, tags, or a dedicated tracking branch to record task state. The `velo:status` command queries git to reconstruct progress.

**How it works:**
- Each phase completion is recorded as a git note or lightweight tag
- `velo:status` queries `git notes` or `git tag --list` to build the status view

**Pros:**
- Leverages existing git infrastructure
- Status is version-controlled by default

**Cons:**
- Over-engineered for the problem -- git notes/tags are not designed for workflow tracking
- Pollutes git history with operational metadata
- Harder to query and format than reading a JSON file
- Breaks if the user has not committed yet (agents may not commit after every phase)

### Approach C: In-memory tracking only, printed on demand

Velo keeps a running log in its conversation context. The `velo:status` command triggers Velo to print whatever it remembers.

**How it works:**
- No file writes. Velo maintains state in its prompt/context as agents complete.
- `velo:status` just asks Velo to summarize what it knows.

**Pros:**
- Zero implementation cost -- no file changes needed

**Cons:**
- Does NOT survive session interruptions (violates G3)
- Context can be lost if the conversation is long
- No persistence at all -- useless for the recovery and audit use cases
- Unreliable: depends on context window, not structured data

### Recommendation: Approach A (file-based status.json)

Approach A is the clear winner. It is the simplest approach that satisfies all four goals. It fits naturally into the existing `.velo/tasks/<slug>/` convention, persists across sessions, and requires no new infrastructure. The implementation cost is modest: add a `status.json` write pattern to the two existing commands, and add a new `status` command that reads and formats it.

Approach B is over-engineered. Approach C does not meet the persistence requirement.

---

## User Stories

### US-1: View active task status

**As a** developer using Velo,
**I want to** run `velo:status` and see the current state of my active task,
**so that** I know what phase it is in and whether I need to do anything (like approve a PRD or engineering design doc).

**Acceptance Criteria:**
- AC1: Running `velo:status` prints the task name, current phase, and elapsed time
- AC2: Each completed agent is listed with its outcome (success, failed, skipped)
- AC3: The currently running phase is indicated distinctly (e.g., "IN PROGRESS")
- AC4: Pending phases that have not started yet are listed as "PENDING"
- AC5: If no task is active and no status.json exists, print a clear message: "No active task found."

### US-2: View completed agent details

**As a** developer using Velo,
**I want to** see which agents have run and what they produced,
**so that** I can understand what work was done without scrolling through chat history.

**Acceptance Criteria:**
- AC1: Each completed agent entry shows: agent name, phase, outcome (success/failed/skipped), duration, token count, artifacts produced (file paths)
- AC2: Agents are listed in chronological order of completion
- AC3: Failed agents include a one-line reason for the failure

### US-3: View status of a specific task by slug

**As a** developer using Velo,
**I want to** run `velo:status <slug>` to see the status of a specific task,
**so that** I can check on any task, not just the most recent one.

**Acceptance Criteria:**
- AC1: `velo:status my-feature` reads `.velo/tasks/my-feature/status.json` and prints its status
- AC2: If the slug does not exist, print: "Task 'my-feature' not found. Available tasks: [list]"
- AC3: If no slug is provided, default to the most recently updated task (by file modification time of status.json)

### US-4: Status persists across sessions

**As a** developer using Velo,
**I want** task status to be available even after I close and reopen my terminal,
**so that** I can resume context without re-reading conversation history.

**Acceptance Criteria:**
- AC1: Status is written to `.velo/tasks/<slug>/status.json` on disk
- AC2: Running `velo:status` in a new session correctly reads and displays previously written status
- AC3: The status file is human-readable JSON (pretty-printed)

### US-5: Status updates are written during velo:new workflow

**As a** developer using Velo,
**I want** the `velo:new` workflow to automatically write status updates as each phase and agent completes,
**so that** status tracking happens without any manual effort.

**Acceptance Criteria:**
- AC1: `status.json` is created at task folder creation time (Step 1b) with initial metadata (task name, slug, created timestamp, workflow type "new")
- AC2: Before each agent is spawned, a "started" entry is written with agent name, phase, and start timestamp
- AC3: After each agent returns, the entry is updated with outcome, duration, token count, tool uses, and artifacts
- AC4: Phase transitions (PM -> Tech Lead -> Build -> Tests -> Review -> Commit) are recorded
- AC5: Approval gate outcomes (approved / revision requested) are recorded

### US-6: Status updates are written during velo:task workflow

**As a** developer using Velo,
**I want** the `velo:task` workflow to also write status updates,
**so that** even quick tasks have a status trail.

**Acceptance Criteria:**
- AC1: `status.json` is created when the task starts, with workflow type "task"
- AC2: Agent start/complete events are tracked identically to US-5
- AC3: The simpler velo:task phases (Build -> Tests -> Review -> Commit) are reflected accurately

### US-7: List all tasks

**As a** developer using Velo,
**I want to** run `velo:status --list` to see all tasks and their high-level status,
**so that** I can pick which one to inspect.

**Acceptance Criteria:**
- AC1: Lists all directories under `.velo/tasks/` that contain a `status.json`
- AC2: Each entry shows: slug, workflow type (new/task), current phase, created date, last updated date
- AC3: Tasks are sorted by last updated (most recent first)
- AC4: If no tasks exist, print: "No tasks found."

---

## Prioritisation

### Must-Have (P0) -- Ship in v1

| ID | Story | Rationale |
|----|-------|-----------|
| US-1 | View active task status | Core value proposition -- without this, the command is useless |
| US-4 | Status persists across sessions | Key differentiator from just reading chat history |
| US-5 | Status updates during velo:new | velo:new is the primary workflow; no tracking = no status to show |
| US-6 | Status updates during velo:task | velo:task is the other command; must be consistent |

### Nice-to-Have (P1) -- Ship in v1 if time allows

| ID | Story | Rationale |
|----|-------|-----------|
| US-2 | View completed agent details | Richer detail per agent; useful but not blocking |
| US-3 | View specific task by slug | Convenient for multi-task users; default-to-latest covers the common case |
| US-7 | List all tasks | Discovery mechanism; lower urgency since users know their task slugs |

---

## status.json Schema

```json
{
  "task": {
    "slug": "user-auth-flow",
    "name": "User Authentication Flow",
    "workflow": "new",
    "created_at": "2026-04-11T18:00:00Z",
    "updated_at": "2026-04-11T18:45:00Z"
  },
  "current_phase": "build",
  "phases": [
    {
      "name": "planning",
      "status": "completed",
      "started_at": "2026-04-11T18:00:00Z",
      "completed_at": "2026-04-11T18:10:00Z"
    },
    {
      "name": "engineering-design-doc",
      "status": "completed",
      "started_at": "2026-04-11T18:10:00Z",
      "completed_at": "2026-04-11T18:25:00Z"
    },
    {
      "name": "build",
      "status": "in_progress",
      "started_at": "2026-04-11T18:25:00Z",
      "completed_at": null
    }
  ],
  "agents": [
    {
      "name": "product-manager",
      "phase": "planning",
      "status": "completed",
      "started_at": "2026-04-11T18:00:00Z",
      "completed_at": "2026-04-11T18:08:00Z",
      "duration_ms": 480000,
      "tokens": 12500,
      "tool_uses": 15,
      "outcome": "success",
      "artifacts": [".velo/tasks/user-auth-flow/prd.md"],
      "error": null
    },
    {
      "name": "tech-lead",
      "phase": "engineering-design-doc",
      "status": "completed",
      "started_at": "2026-04-11T18:10:00Z",
      "completed_at": "2026-04-11T18:20:00Z",
      "duration_ms": 600000,
      "tokens": 18000,
      "tool_uses": 22,
      "outcome": "success",
      "artifacts": [".velo/tasks/user-auth-flow/engineering-design-doc.md"],
      "error": null
    },
    {
      "name": "be-engineer",
      "phase": "build",
      "status": "in_progress",
      "started_at": "2026-04-11T18:25:00Z",
      "completed_at": null,
      "duration_ms": null,
      "tokens": null,
      "tool_uses": null,
      "outcome": null,
      "artifacts": [],
      "error": null
    }
  ],
  "gates": [
    {
      "name": "prd-approval",
      "phase": "planning",
      "status": "approved",
      "timestamp": "2026-04-11T18:09:00Z"
    },
    {
      "name": "engineering-design-doc-approval",
      "phase": "engineering-design-doc",
      "status": "approved",
      "timestamp": "2026-04-11T18:24:00Z"
    }
  ]
}
```

---

## Edge Cases

| # | Scenario | Expected Behaviour |
|---|----------|--------------------|
| E1 | No `.velo/tasks/` directory exists | Print "No tasks found. Run velo:new or velo:task to start work." |
| E2 | Task folder exists but no `status.json` | Print "Task '<slug>' exists but has no status tracking. It may have been created before status tracking was added." |
| E3 | `status.json` is malformed / corrupt | Print "Status file for '<slug>' is corrupt. Raw file at: .velo/tasks/<slug>/status.json" |
| E4 | Agent crashes mid-run (status = "in_progress" but Velo session ended) | Show as "in_progress (stale)" if updated_at is older than the current session. Do not auto-mark as failed -- the user decides. |
| E5 | Multiple tasks have status.json, no slug provided | Default to most recently updated. Print a note: "Showing most recent task. Use velo:status <slug> or velo:status --list to see others." |
| E6 | User runs velo:status during an active velo:new run (same session) | Show real-time status from the status.json file -- it should reflect all agents that have completed so far in the current run. |
| E7 | Parallel agents (e.g., FE + BE engineers running simultaneously) | Both shown as "in_progress" under the same phase. Completion order in the agents array reflects actual finish order. |
| E8 | Review cycle (Tech Lead revises after DE review) | Each review cycle is a separate agent entry. The agents array may contain multiple entries for "tech-lead" and "distinguished-engineer" reflecting revision rounds. |
| E9 | Slug argument contains invalid characters | Normalise or reject gracefully: "Invalid task slug. Use lowercase letters, numbers, and hyphens only." |

---

## Dependencies

| # | Dependency | Type | Impact |
|---|-----------|------|--------|
| D1 | `commands/new.md` | Modify | Must add status.json write instructions at each phase transition and agent spawn/complete |
| D2 | `commands/task.md` | Modify | Must add status.json write instructions at each agent spawn/complete |
| D3 | `commands/` directory | New file | New `status.md` command file for the `velo:status` command |
| D4 | `scripts/audit.sh` | May need update | If the new command references agents or skills, audit.sh should cover it. Current audit only checks commands -> agents and agents -> skills references, so it may already work if status.md does not reference agent files directly. |
| D5 | `.velo/tasks/<slug>/` directory convention | Existing | Status command reads from the existing task folder structure. No schema change needed. |

---

## Open Questions

| # | Question | Suggested Resolution |
|---|----------|---------------------|
| OQ1 | Should the status command be its own agent or a direct command? | **Suggested: Direct command** (like `new.md` and `task.md`). It does not need to delegate to subagents -- it just reads a file and formats output. Making it an agent adds unnecessary overhead. |
| OQ2 | Should status.json be gitignored? | **Suggested: No.** It is a useful audit trail. Include it in commits. It is small and structured. But this is a team preference -- flag it for the EM to decide. |
| OQ3 | Should the status output format be plain text or structured (JSON)? | **Suggested: Plain text by default** (human-readable table), with an optional `--json` flag for machine consumption. Start with plain text only in v1. |
| OQ4 | How should we handle the "stale in_progress" detection in E4? | **Suggested: Heuristic.** If `updated_at` on the task is more than 30 minutes old and there are agents still "in_progress", flag them as "(stale)". Do not auto-transition to "failed". |
| OQ5 | What token/duration data is available from the Agent tool? | Need to confirm what metadata the Agent tool returns after a subagent completes. The existing final report in `new.md` already references `total_tokens`, `tool_uses`, `duration_ms` -- so this data should be available. |

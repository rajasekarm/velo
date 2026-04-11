# Engineering Design Doc: velo:status Command

> Version: 1.1 — 2026-04-11
> Status: Pending approval

---

## Decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | `status.json` lives in `.velo/tasks/<slug>/` alongside other task artifacts | Consistent with existing convention — every task artifact (prd.md, engineering-design-doc.md) already lives here. No new directory structure needed. |
| D2 | JSON format with pretty-printing (2-space indent) | Human-readable on disk (`cat status.json` is useful), machine-parseable, and fits how the system already structures markdown artifacts. YAML adds no value for a file that is programmatically read/written. |
| D3 | `status.json` is not gitignored | It is a structured audit trail. Small, deterministic, useful for post-hoc review. The PRD flags this as a team preference — defaulting to included is the safer choice; it is easy to gitignore later. |
| D4 | Agents array is append-only; never mutate a completed entry | Supports review cycles where the same agent (e.g., tech-lead) runs multiple times. Each run is a separate entry. Mutation would destroy the revision history. |
| D5 | Stale in-progress detection: flag if `updated_at` is >30 minutes old and any agent entry has `status: "in_progress"` | Heuristic from OQ4. Avoids auto-marking failed (which could be wrong), but gives the user a visible signal. Threshold of 30 minutes is conservative — most agents complete well within this window. |
| D6 | `velo:status` is a command file (`commands/status.md`), not an agent | It does not delegate work; it reads a file and formats output. Adding agent overhead (model call, tool permissions) would be wasteful for a pure read operation. Matches the pattern of `new.md` and `task.md`. |
| D7 | When no slug is provided, default to the task with the largest `task.updated_at` in `status.json`; fall back to filesystem mtime only when `status.json` is unreadable | `task.updated_at` is the authoritative source of truth because it is written by the velo workflow with precise semantics. Filesystem mtime can drift (file copies, editor auto-saves). Mtime fallback ensures graceful degradation for corrupt or missing JSON. |
| D8 | `--list` flag outputs a summary table of all tasks. `--json` flag outputs raw `status.json` content. Combinations: `--list` alone is valid; `<slug> --json` is valid; `--list --json` outputs a JSON array of all task metadata objects (one per task); `--list <slug>` is an error. | Specifying all accepted flag combinations eliminates ambiguity for build. `--list --json` is deliberately supported as a scripting escape hatch. `--list <slug>` is contradictory and is rejected with a clear message. |
| D9 | Write status.json at agent spawn time (pre-spawn entry), then update it on agent return (post-return update) | Enables real-time status inspection during an active run (US-6, E6). If a crash occurs between spawn and return, the entry stays `in_progress` — which is accurate and detectable as stale (D5). |
| D10 | Canonical phase name strings — `"engineering-design-doc"` and `"engineering-design-doc-approval"` | C1 resolution. `"engineering-design-doc"` matches the on-disk artifact name (`engineering-design-doc.md`) and the PRD language. The shorter form `"engineering-doc"` was inconsistently used in the previous draft and is eliminated. Every schema example, protocol step, gate name, and renderer must use the full form. Known canonical values: phases: `"planning"`, `"engineering-design-doc"`, `"build"`, `"tests"`, `"review"`, `"commit"`; gates: `"prd-approval"`, `"engineering-design-doc-approval"`. |
| D11 | `gates` array records approval gate outcomes separate from the `phases` array | Gates are user actions, not agent executions. Mixing them into `phases` or `agents` would blur the distinction between automated work and human decisions. They are small records and warrant their own array. |
| D12 | `tokens` field in agent entries uses total token count (input + output) | This matches how `new.md` and `task.md` already report token usage in their final summary (`total_tokens`). Splitting input/output is a P1 enhancement. |
| D13 | `run_id` is added to `AgentEntry` as a UUID generated at spawn time; it is the primary key for update lookups | C2 resolution. Matching by `(name, in_progress)` is ambiguous when the same agent runs concurrently (parallel reviewers), retries, or runs in review cycles. `run_id` is stable across the agent's lifecycle and eliminates lookup ambiguity. The orchestrator generates the UUID before writing the pre-spawn entry and passes it to the agent or records it internally. |
| D14 | `failed` is added to `Phase.status`; `task.status` field added to `TaskMetadata`; `current_phase` semantics on failure defined | C3 resolution. Phase failures are real events that must be visible in the status view and inspectable programmatically. `task.status` aggregates over phase outcomes. `current_phase` retains the name of the failed phase so the renderer can point to it; it does not advance. |
| D15 | All writes to `status.json` use atomic temp-file-and-rename; the orchestrating command owns phase-completion writes; parallel agents must reload-and-merge before writing | C4 resolution. Temp-file-and-rename is standard POSIX atomic write — readers never see a partial file. Reload-and-merge prevents lost updates when parallel agents finish close together. Phase-completion writes are owned exclusively by the orchestrator (after all parallel agents in that phase have returned) to avoid split-brain. |
| D16 | `Gate.name` is `string`, not a closed enum; known values listed in D10 | S1 resolution. Baking the two-gate list into the type would force a schema version bump every time a new gate is introduced. `string` matches the `PhaseName = string` treatment already applied to phases. Known current values are documented in D10 as a reference, not a constraint. |
| D17 | `schema_version: 1` field added to `StatusFile`; `velo:status` rejects files with an unknown version | S2 resolution. The file is a durable on-disk artifact. Silent misparse on version mismatch produces corrupt display or incorrect state transitions. Explicit version detection enables a clear error message and a future migration path. Version 1 = this spec. |
| D18 | Phase duration is derived from `started_at` / `completed_at` at render time; `duration_ms` is not stored on `Phase` | S6 resolution. Storing a pre-computed `duration_ms` on `Phase` alongside timestamps introduces a redundancy that can drift (computed incorrectly, not updated on revision). The renderer already has both timestamps and can compute duration on the fly. `AgentEntry.duration_ms` is kept as a convenience because it is provided by the Agent tool at return time and is authoritative for the agent's wall-clock time. |
| D19 | P0 `velo:status` renders: task metadata, phase table (name/status/started/completed/derived-duration), agent list (name/phase/status/outcome/duration/tokens/tool_uses/artifacts), gates, stale warning. Fields `duration_ms`, `tokens`, `tool_uses`, `artifacts` are written at agent return time and rendered in P0. Full per-field display of agent detail is P1 only if it requires UI work beyond the table row already shown. | S5 resolution. The build engineer needs an unambiguous list of what to render in the P0 command. Every field that is written in P0 is also rendered in P0 in the same table row. Nothing is deferred to P1 except features requiring additional layout work (e.g., sparklines, per-agent deep-drill). |

---

## Command Interface

### `velo:status`

**Purpose**: Display the current or most recently updated task status.

**Invocation**:
```
/velo:status
/velo:status <slug>
/velo:status --list
/velo:status --list --json
/velo:status <slug> --json
```

**Arguments**:

| Argument | Type | Required | Description |
|---|---|---|---|
| `slug` | string | No | Task slug to inspect. If omitted, defaults to the task with the largest `task.updated_at` in its `status.json`; falls back to filesystem mtime when JSON is unreadable. |
| `--list` | flag | No | List all tasks with a one-line summary. Mutually exclusive with providing a `slug`. |
| `--json` | flag | No | Output raw `status.json` content instead of formatted view. Valid alone, with `<slug>`, or with `--list`. |

**Flag combination rules**:

| Invocation | Behaviour |
|---|---|
| `velo:status` | Default view for most-recently-updated task |
| `velo:status <slug>` | Default view for named task |
| `velo:status --list` | Summary table of all tasks |
| `velo:status --list --json` | JSON array of all task `status.json` objects |
| `velo:status <slug> --json` | Raw `status.json` for named task |
| `velo:status --list <slug>` | **Error**: `--list` and a slug are mutually exclusive |

**Output (default — no flags)**:

```
Task: User Authentication Flow  [slug: user-auth-flow]
Workflow: new  |  Started: 2026-04-11 18:00 UTC  |  Updated: 2026-04-11 18:45 UTC
Status: IN PROGRESS

Phase                          Status        Started       Completed     Duration
--------------------------     ----------    ----------    ----------    ----------
planning                       COMPLETED     18:00         18:10         10m 00s
engineering-design-doc         COMPLETED     18:10         18:25         15m 00s
build                          IN PROGRESS   18:25         --            (running)
tests                          PENDING       --            --            --
review                         PENDING       --            --            --
commit                         PENDING       --            --            --

Agents
-----------
product-manager    [planning]                      SUCCESS   8m 00s   12,500 tok   15 tools
                   Artifacts: .velo/tasks/user-auth-flow/prd.md

tech-lead          [engineering-design-doc]        SUCCESS   10m 00s  18,000 tok   22 tools
                   Artifacts: .velo/tasks/user-auth-flow/engineering-design-doc.md

distinguished-engineer  [engineering-design-doc]   SUCCESS  4m 30s  9,200 tok  11 tools
gpt-reviewer            [engineering-design-doc]   SUCCESS  3m 10s  7,400 tok   9 tools

be-engineer        [build]             IN PROGRESS  (running since 18:25)
fe-engineer        [build]             IN PROGRESS  (running since 18:25)

Approval Gates
-----------
prd-approval                        APPROVED    2026-04-11 18:09 UTC
engineering-design-doc-approval     APPROVED    2026-04-11 18:24 UTC

Note: Showing most recent task. Use velo:status <slug> or velo:status --list to see others.
```

**Output (`--list`)**:

```
Tasks (4 total, sorted by last updated)

Slug                    Workflow  Status       Current Phase           Updated
------------------      --------  ----------   --------------------    ----------
user-auth-flow          new       in_progress  build                   Apr 11 18:45
fix-login-redirect      task      in_progress  review                  Apr 10 09:55
add-export-feature      new       completed    commit                  Apr 08 17:20
refactor-db-indexes     task      completed    commit                  Apr 07 11:40
```

**Output (`--list --json`)**:

```json
[
  { "slug": "user-auth-flow", "name": "User Authentication Flow", "workflow": "new", "status": "in_progress", "current_phase": "build", "updated_at": "2026-04-11T18:45:00Z" },
  ...
]
```

**Error outputs**:

| Condition | Output |
|---|---|
| No `.velo/tasks/` directory | `No tasks found. Run velo:new or velo:task to start work.` |
| Slug provided, folder missing | `Task '<slug>' not found. Available tasks: [comma-separated list]` |
| No slug, no status.json anywhere | `No tasks found. Run velo:new or velo:task to start work.` |
| Folder exists, no `status.json` | `Task '<slug>' exists but has no status tracking. It may have been created before status tracking was added.` |
| `status.json` is malformed | `Status file for '<slug>' is corrupt. Raw file at: .velo/tasks/<slug>/status.json` |
| `status.json` has unknown `schema_version` | `Status file for '<slug>' uses schema version <N>, which this version of velo does not support. Upgrade velo or inspect the raw file at: .velo/tasks/<slug>/status.json` |
| Invalid slug characters | `Invalid task slug. Use lowercase letters, numbers, and hyphens only.` |
| `--list` used with `<slug>` | `--list and a task slug are mutually exclusive. Use one or the other.` |

---

## Data Models

### `status.json` — Full Schema

```typescript
interface StatusFile {
  schema_version: 1;          // Increment on any breaking schema change. velo:status rejects unknown versions.
  task: TaskMetadata;
  current_phase: PhaseName;   // Name of the active or most recently active phase. Retains the failed phase name after failure; does not advance.
  phases: Phase[];
  agents: AgentEntry[];
  gates: Gate[];
}

interface TaskMetadata {
  slug: string;          // e.g. "user-auth-flow"
  name: string;          // e.g. "User Authentication Flow"
  workflow: "new" | "task";
  status: "active" | "completed" | "failed" | "cancelled";
  created_at: string;    // ISO 8601 UTC, e.g. "2026-04-11T18:00:00Z"
  updated_at: string;    // ISO 8601 UTC — updated on every write
}

// Canonical phase names for "new" workflow:
//   "planning" | "engineering-design-doc" | "build" | "tests" | "review" | "commit"
// Canonical phase names for "task" workflow:
//   "build" | "tests" | "review" | "commit"
type PhaseName = string;

interface Phase {
  name: PhaseName;
  status: "pending" | "in_progress" | "completed" | "failed" | "skipped";
  started_at: string | null;    // ISO 8601 UTC
  completed_at: string | null;  // ISO 8601 UTC
  // Duration is derived at render time: completed_at - started_at. Not stored to avoid redundancy.
}

type AgentOutcome = "success" | "failed" | "skipped";

interface AgentEntry {
  run_id: string;         // UUID generated at spawn time. Primary key for update lookups. Never changes after creation.
  name: string;           // e.g. "product-manager", "tech-lead", "be-engineer"
  phase: PhaseName;
  status: "in_progress" | "completed" | "failed" | "skipped";
  started_at: string;     // ISO 8601 UTC
  completed_at: string | null;
  duration_ms: number | null;   // Wall-clock ms as reported by the Agent tool at return time.
  tokens: number | null;  // total_tokens (input + output)
  tool_uses: number | null;
  outcome: AgentOutcome | null;
  artifacts: string[];    // relative paths from repo root, e.g. [".velo/tasks/<slug>/prd.md"]
  error: string | null;   // one-line reason for failure; null on success
}

interface Gate {
  name: string;           // Known values: "prd-approval", "engineering-design-doc-approval". Open string — new gates do not require a schema version bump.
  phase: PhaseName;
  status: "approved" | "revision-requested";
  timestamp: string;      // ISO 8601 UTC
}
```

### `status.json` — Concrete Example

```json
{
  "schema_version": 1,
  "task": {
    "slug": "user-auth-flow",
    "name": "User Authentication Flow",
    "workflow": "new",
    "status": "active",
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
    },
    {
      "name": "tests",
      "status": "pending",
      "started_at": null,
      "completed_at": null
    },
    {
      "name": "review",
      "status": "pending",
      "started_at": null,
      "completed_at": null
    },
    {
      "name": "commit",
      "status": "pending",
      "started_at": null,
      "completed_at": null
    }
  ],
  "agents": [
    {
      "run_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
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
      "run_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
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
      "run_id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
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

## Status Write Protocol

This section specifies exactly what `commands/new.md` and `commands/task.md` must write and when. These are instructions for Velo (the EM agent running those commands) — not code to implement.

### Atomic write requirement (applies to every write)

Every write to `status.json` must use a temp-file-and-rename pattern:

1. Write the complete new JSON to a temporary file in the same directory: `.velo/tasks/<slug>/status.json.tmp`
2. Rename (atomic on POSIX): `mv status.json.tmp status.json`
3. Never write directly to `status.json` — a crash mid-write would leave a corrupt file

When multiple agents may write concurrently (parallel phase), each writer must additionally:

1. Read the current `status.json` into memory
2. Apply its change (add or update its own entry)
3. Write the merged result via temp-file-and-rename

The orchestrating command is the only writer permitted to update phase-level fields (`phases[].status`, `phases[].completed_at`, `current_phase`). Agents update only their own `AgentEntry` (matched by `run_id`).

### Initialization (Step 1b in `new.md` / Step 1 in `task.md`)

Immediately after creating the task folder (`mkdir -p .velo/tasks/<slug>`), write `status.json` with:
- `schema_version`: `1`
- `task` metadata populated (slug, name, workflow, `status: "active"`, created_at, updated_at = now)
- `current_phase` = first phase for the workflow (`"planning"` for `new`, `"build"` for `task`)
- `phases` = full list of phases for this workflow, all with `status: "pending"`, `started_at: null`, `completed_at: null`
- `agents` = `[]`
- `gates` = `[]`

### Before spawning an agent

1. Generate a UUID for `run_id`
2. Reload `status.json` into memory (reload-and-merge, not in-memory edit)
3. Append an agent entry to `agents[]` with:
   - `run_id: <generated UUID>`, `name`, `phase`, `status: "in_progress"`, `started_at: now`, all other fields null/empty
4. Update `task.updated_at` = now
5. If this is the first agent in the phase, update `phases[phase].status = "in_progress"` and `phases[phase].started_at = now`
6. Update `current_phase` to the current phase name
7. Write via atomic temp-file-and-rename
8. Record the `run_id` — it will be needed to match the entry after the agent returns

### After an agent returns

1. Reload `status.json` into memory
2. Find the entry where `agents[i].run_id == <run_id recorded at spawn>`
3. Update that entry with:
   - `status: "completed"` or `"failed"`
   - `completed_at: now`
   - `duration_ms: <elapsed from Agent tool return>`
   - `tokens: <total_tokens from agent return>`
   - `tool_uses: <tool_uses from agent return>`
   - `outcome: "success"` or `"failed"`
   - `artifacts: [<list of files the agent wrote>]`
   - `error: <one-line reason>` (null on success)
4. Update `task.updated_at` = now
5. Write via atomic temp-file-and-rename

### After a phase completes (orchestrator step — all parallel agents have returned)

The orchestrator checks that all agents for the phase have a terminal status (`completed`, `failed`, or `skipped`). Then:

1. Reload `status.json` into memory
2. If all agents succeeded: set `phases[phase].status = "completed"` and `phases[phase].completed_at = now`
3. If any agent failed: set `phases[phase].status = "failed"` and `phases[phase].completed_at = now`. Set `task.status = "failed"`. Leave `current_phase` pointing to the failed phase — do not advance.
4. Update `task.updated_at` = now
5. Write via atomic temp-file-and-rename

### After an approval gate

Append to `gates[]`:
- `name`: e.g. `"prd-approval"` or `"engineering-design-doc-approval"` (string — not an enum)
- `phase`: the phase the gate closes
- `status`: `"approved"` or `"revision-requested"`
- `timestamp`: now

If the user requests revisions, append a `"revision-requested"` gate entry and leave the phase `in_progress`. When approved, append an `"approved"` gate entry.

### Skipped phases

If a phase is skipped (e.g., no schema changes so DB engineer is not spawned, or commit not requested), update `phases[phase].status = "skipped"`.

### Rendering order for agents

When displaying the agents list, order entries by `started_at` ascending. In-progress entries (no `completed_at`) are listed after all completed entries for their phase, grouped by phase order.

---

## Error Schema

The `velo:status` command itself does not produce structured error output — it prints human-readable messages to the terminal (see Error outputs in Command Interface above). The `status.json` file records agent failures inline via the `error` field on `AgentEntry`.

Agent failure format (in `status.json`):
```json
{
  "run_id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
  "name": "be-engineer",
  "phase": "build",
  "status": "failed",
  "outcome": "failed",
  "error": "Timed out after 120s waiting for database connection",
  "completed_at": "2026-04-11T18:45:00Z",
  "duration_ms": 1200000,
  "tokens": null,
  "tool_uses": null,
  "artifacts": []
}
```

Phase failure state (in `status.json` after orchestrator phase-completion write):
```json
{
  "current_phase": "build",
  "task": { "status": "failed", "..." : "..." },
  "phases": [
    { "name": "build", "status": "failed", "started_at": "...", "completed_at": "..." }
  ]
}
```

---

## Open Questions — Resolved

| # | Question | Resolution |
|---|---|---|
| OQ1 | Direct command or agent? | Direct command (`commands/status.md`). No delegation needed — pure file read + format. See D6. |
| OQ2 | Gitignore status.json? | No. Included in commits by default. See D3. |
| OQ3 | Plain text or JSON output? | Plain text by default; `--json` flag for machine consumption. `--list` for task discovery. See D8. |
| OQ4 | Stale in-progress detection? | Flag as stale if `updated_at` is >30 minutes old with any `in_progress` agent. Do not auto-fail. See D5. |
| OQ5 | Token data from Agent tool? | Confirmed available: `new.md` and `task.md` already reference `total_tokens`, `tool_uses`, `duration_ms` in their final report. No new instrumentation needed. |
| OQ6 | Which flag combinations are valid for `velo:status`? | Explicitly enumerated in the Command Interface flag combination table. `--list --json` is supported. `--list <slug>` is an error. See D8. |
| OQ7 | What is the source of truth for "most recent task" when no slug is given? | `task.updated_at` from `status.json`. Filesystem mtime is a fallback only when JSON is unreadable. See D7. |

---

## Files to Create or Modify

| File | Change |
|---|---|
| `commands/status.md` | New — the `velo:status` command |
| `commands/new.md` | Modify — add status.json write instructions at Step 1b (init), before/after every agent spawn, and at each approval gate |
| `commands/task.md` | Modify — add status.json write instructions at Step 1 (init) and before/after every agent spawn |

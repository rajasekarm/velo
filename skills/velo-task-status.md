---
name: velo-task-status
description: Lightweight task-status breadcrumbs. Plain-markdown status.md per task folder plus a global .velo/tasks/index.md, written by Velo at folder creation, every state transition, and terminal states; resume protocol at VALIDATE. No engine — no JSON state, no code, no CLI, no tests.
---
# Velo Task Status

## Purpose

Persisted breadcrumbs so an interrupted `/velo:plan` or `/velo:task` run can be resumed, and every run can be seen at a glance. Two plain-markdown files, both written by Velo (the orchestrator) — never by spawned agents:

- `.velo/tasks/<slug>/status.md` — per-task status breadcrumb. The persisted twin of the `track-tasks` todo list: every todo flip and state transition has a matching breadcrumb update.
- `.velo/tasks/index.md` — global task index, one row per task. `index.md` is a file and task slugs are directories, so no slug can collide with it.

**Deliberately NOT an engine.** A prior heavy state system (JS state machine, `state.json`, CLI tracker, 107 tests) was rolled back as over-engineered. This skill is the replacement philosophy: markdown breadcrumbs Velo rewrites at transitions. No schema validation, no code, no CLI, no tests, no JSON. If a breadcrumb is missing or unparseable, Velo degrades gracefully — proceed as new work; never block on a breadcrumb.

## Phase names

`status.md` records both the technical state ID (structure, telemetry, increment-2 executor dispatch) and the friendly team name (everything the user reads), per each command's narration convention. Plan-mode names come from `commands/plan.md`; task-mode names are defined here (task.md narrates work, not states, so these appear only in breadcrumbs and resume prompts):

| Mode | Technical ID | Team name |
|---|---|---|
| plan | VALIDATE | Scope check |
| plan | ANNOUNCE | Kickoff |
| plan | PM_PHASE | Product framing |
| plan | PRD_REVIEW | Framing review |
| plan | DESIGN_PHASE | Design doc |
| plan | DESIGN_REVIEW | Design review |
| plan | DESIGN_APPROVAL | Design sign-off |
| plan | DAG_PHASE | Work planning |
| plan | PLAN_APPROVAL | Plan sign-off |
| plan | HANDOFF | Hand to the builders |
| task | VALIDATE | Scope check |
| task | PLAN_AND_ANNOUNCE | Plan & kickoff |
| task | BUILD | Build |
| task | REVIEW | Review |
| task | SHIP_GATE | Ship gate |
| both | DONE | Done |
| both | ABANDON | Abandoned |

## status.md format

Plain markdown, stable keys (the increment-2 Task-executor will dispatch on `Mode`, `Phase`, and the node checklist — do not rename keys):

```markdown
# Status — <slug>

- Mode: plan | task
- Depth: heavy (trigger <1|2|3>) | light | —          ← plan mode; task mode writes —
- Pairing: product | pure-tech
- Phase: <TECHNICAL_ID> (<team name>)                 ← terminal: DONE (Done — <terminal reason>) / ABANDON (Abandoned — <terminal reason>)
- Last gate passed: <TECHNICAL_ID> (<team name>) | —
- Rework cycles: spec <n> · edd <n> · review <n>
- Updated: <output of `date '+%Y-%m-%d %H:%M'`>
- Summary: <one line — same line as the index row>

## Nodes

- T1 · <agent> — <does> · done
- T2 · <agent> — <does> · in-flight
- T3 · <agent> — <does> · pending
```

Node status vocabulary: `pending | in-flight | done`. Rework sends a node back to `in-flight`. Before a breakdown/DAG exists, the Nodes section reads `(no plan yet)`.

**Timestamps**: always sourced from the shell — run `date '+%Y-%m-%d %H:%M'` (dates in index.md: `date '+%Y-%m-%d'`). Agents cannot generate reliable time; never invent a timestamp.

## index.md format

```markdown
# Velo — Task Index

Newest-first: new tasks are inserted directly below the header row. Maintained by Velo per velo-task-status.md.

| Task | Status | Created | Updated | Summary |
|---|---|---|---|---|
| [<slug>](<slug>/) | in-progress | 2026-07-20 | 2026-07-20 | <one-line title> |
```

- **Ordering**: newest-first — a new task's row is inserted directly below the header separator. Active work is what the index is scanned for.
- **Status vocabulary**: `in-progress | done | abandoned`.
- **Row lifecycle**: inserted at task-folder creation (`in-progress`); flipped to `done` when `/velo:task` reaches `DONE`, and to `abandoned` at either mode's `ABANDON`. Plan mode's `DONE` (`handed-off-to-task` or `plan-saved-no-handoff`) leaves the row `in-progress` — the index tracks the work item, not the planning session; planning finished but the work is live until the executor delivers it. Only the `Updated` date advances.

## Write points

All writes are full-file rewrites by Velo. Solo-user, serial workflow — last write wins, no locking, no concurrency machinery.

| Event | status.md | index.md |
|---|---|---|
| Task-folder creation (plan `ANNOUNCE` / task `PLAN_AND_ANNOUNCE`) | create | insert row at top, `in-progress` |
| Every state transition | rewrite: Phase, Last gate passed, node checklist, rework counters, Updated | — |
| Node lifecycle inside `BUILD` (mirrors each `track-tasks` flip) | node `pending` → `in-flight` → `done` | — |
| Rework cycle that loops *within* a state (`REVIEW`, `DESIGN_REVIEW`, spec loop) | bump the matching Rework counter | — |
| `DONE` / `ABANDON` | Phase → terminal form with terminal reason | flip Status per row lifecycle; advance Updated |

**Exception — plan handoff stays non-terminal**: plan mode's `DONE` via `handed-off-to-task` does NOT stamp a terminal Phase. `status.md` stays at `Phase: HANDOFF (Hand to the builders)` so the package-bearing `/velo:task` invocation arrives at a non-terminal breadcrumb; the executor's first write takes ownership (flipping `Mode:` to `task`). Only `plan-saved-no-handoff` stamps plan-mode `DONE` terminal. The index-row lifecycle is unchanged — the row stays `in-progress` on both plan-mode terminal reasons.

## Resume protocol

Runs at `VALIDATE` entry in both commands, before fresh interpretation.

1. **Trigger**: the invocation references an existing task — an explicit `.velo/tasks/<slug>/` path or a brief that maps unambiguously to an `index.md` row — AND that folder's `status.md` has a non-terminal `Phase` (not DONE/ABANDON).
2. **Gate** via `ask-options` — header `"Resume check"`, question `"Found <slug> mid-flight at <team name> (updated <Updated>). Pick up where it left off, or start over?"`, options:
   - `Resume from <team name>` → re-enter the recorded state in the owning mode, with the recorded depth, pairing, artifacts, and node checklist. Nodes marked `done` are complete and MUST NOT be re-run — identical semantics to the plan package's `done:` annotation ([Velo Plan Package](velo-plan-package.md)). **Cross-mode match**: if the recorded `Mode:` differs from the current command (e.g. `/velo:plan` matched a `Mode: task` breadcrumb), hand off via `handoff-mode` to the owning command carrying the task-folder path; that command's own resume check re-enters. Same-mode matches resume in place.
   - `Start fresh` → derive a suffixed slug (`-2`, `-3`, ...) for the new run; set the old run's `status.md` to `Phase: ABANDON (Abandoned — superseded)` and flip its index row to `abandoned`, appending `(superseded by <new-slug>)` to its Summary. No zombie `in-progress` rows.
3. **Not a resume prompt — expected continuations**: two invocation shapes carry a `Task-folder` header and always arrive with a non-terminal `status.md`; both are the *expected* continuation of a live flow, never a resume prompt. (a) A plan-package-bearing `/velo:task` invocation — non-terminal by construction: plan mode's handoff deliberately leaves `status.md` at `Phase: HANDOFF` rather than stamping `DONE` (see the write-points exception above). Reuse the `Task-folder` silently, flip `Mode:` to `task`, keep the folder and index row. (b) A `Re-entry:`-bearing `/velo:plan` invocation (descope re-entry) — reuse the `Task-folder` silently, flip `Mode:` back to `plan`, and proceed directly to the delta re-plan per `commands/plan.md`'s Re-entry section; the folder is the re-entry anchor ([Velo Plan Package](velo-plan-package.md)) and must never be suffix-slugged or abandoned.
4. **Degrade gracefully**: `status.md` missing, unparseable, or terminal → skip the prompt, proceed as new work.

## Alignment with plan-package `done:`

One meaning, two carriers — do not duplicate the semantics:

- `status.md`'s node checklist is the **live record** during execution; the package's `done:` annotation ([Velo Plan Package](velo-plan-package.md)) is its **snapshot at handoff time**.
- When assembling a re-entry package (descope), derive each node's `done:` annotation from the `status.md` checklist.
- When receiving a package carrying `done:` nodes, initialize those nodes as `done` in `status.md`.
- Either carrier saying done means the same thing: complete, never re-run.

## Scope

Producers: `/velo:plan` and `/velo:task` (Velo only — spawned agents never touch these files). Consumers: the same two commands' resume checks now; the increment-2 Task-executor consumes `status.md` for binding resume later — which is why the keys and node vocabulary above are frozen. No other command reads or writes these files.

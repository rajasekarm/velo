---
name: velo-parallelism
description: Rules for spawning agents in parallel vs sequential, within a milestone. Single-turn parallel spawning, dependency ordering, FE-against-mocks pattern, automation-depends-on-all-builders, batches never span milestones, batch boundaries for track-tasks lifecycle, per-milestone reviewer pairings.
---
# Velo Parallelism Rules

## Core rule — single runtime turn for independents

When multiple todo items / tasks are independent (no shared dependency), their agents MUST be spawned in **one runtime turn** through `spawn-agent`, so they run concurrently. Sequential spawning of independent work is a bug, not a style choice.

This applies to:
- Independent domains (FE + Infra, FE + BE against mocks)
- Multiple reviewers (always parallel)
- Multiple tasks of the same agent type

Independence is assessed **inside one milestone**. Two tasks in different milestones are never spawned together, no matter how independent they look — see Batches never span milestones.

## Dependency rule

A dependency exists when a later item needs output from an earlier one. Absent a real dependency, parallelize.

Standard dependencies:
- **DB before BE** — schema dependency
- **Builders before reviewers** — review needs code to read
- **Automation engineer depends on ALL builders** — tests need the full surface to exercise (all builders in that automation task's own milestone; builders in earlier milestones are already done)
- **FE can always start in parallel against mocks** — FE depends on BE only for integration, not for first build

Milestone order is itself a dependency, and the strongest one: M(i+1) does not start until M(i)'s review passes and its ship gate resolves.

## Carrier encoding

In the carrier, `.velo/tasks/<slug>/task-breakdown.md`, tasks live under `## M1..Mn` milestone headings and the `needs` field on each task line drives parallelism:

- `needs: —` → nothing to wait on; batches with the other unblocked tasks in the same milestone
- `needs: T1` → cannot start until T1 completes
- `needs: T1, T2` → cannot start until both complete
- `needs:` pointing at a task in an EARLIER milestone → already satisfied when this milestone opens, so it does not hold the task back

Unblocked tasks batch together into a single parallel spawn. Tasks with shared dependencies form the next batch once those dependencies complete. Each milestone carries its own `Execution:` line recording its batches, written by Velo at the `PLAN_APPROVAL` freeze; the carrier format itself is specified in [Velo Task Status](velo-task-status.md).

## Batches never span milestones

**Derive batches per milestone, never across the whole breakdown.** Batch 1 of M2 is computed over M2's tasks alone, and its numbering starts again at 1.

This is not an optimization detail — milestones serialize. M(i+1) does not start until M(i)'s review passes, so a runtime turn can never hold a task from two different milestones. If a batch you derived contains ids from two milestones, the derivation is wrong: split it at the milestone boundary and let the earlier milestone finish, review, and pass its gate first.

The milestone boundary is therefore also a hard batch boundary: every task in M(i) is `done` before M(i+1)'s first spawn.

## track-tasks lifecycle and batch boundaries

Register all builders / reviewers as todo items via `track-tasks` **before spawning** — the full breakdown up front, across every milestone, each item `pending`. Registration is plan-wide; only the `in_progress` flip is batch-scoped. Apply the lifecycle:

- Mark each item `in_progress` when its agent starts
- Mark each item `completed` when it returns
- **Only one item `in_progress` per parallel batch boundary**: parallel spawns mark multiple items `in_progress` simultaneously (one batch); sequential spawns mark one at a time

A "batch boundary" is a parallel spawn group. Within a batch, multiple items can be `in_progress`. Between batches, items must be `completed` before the next batch's items go `in_progress`. A milestone boundary is a batch boundary too: no item from M(i+1) goes `in_progress` while any item from M(i) is still open.

Same lifecycle rules apply across `BUILD` and `REVIEW` (`/velo:task`), on every pass through them — the executor runs that build/review pair once per milestone.

## Mandatory reviewer pairings

In review states:
- **If BE engineer was involved**: always spawn the observability-engineer alongside the be-reviewer — same BE changes, different lens.

All reviewers in a state spawn in one parallel batch.

Review runs **per milestone**, not once at the end of the run: at each milestone's `REVIEW`, the reviewer set derives from the builders that ran in THAT milestone, and the mandatory pairing attaches on the same terms. A BE builder in M1 pairs observability into M1's review; if no BE builder runs in M2, M2's review carries no observability reviewer on this rule.

## Re-spawn rules during rework

When a rework cycle re-spawns only the failing reviewers (not the full panel), they still spawn in a single parallel batch if there is more than one. Instruct re-spawned reviewers: *"Re-check only the previously flagged issues — do not perform a full re-review."*

Rework stays inside the milestone that raised it — a rework loop never pulls the next milestone's tasks forward to fill the turn.

---
name: velo-parallelism
description: Rules for spawning agents in parallel vs sequential. Single-turn parallel spawning, dependency ordering, FE-against-mocks pattern, automation-depends-on-all-builders, batch boundaries for track-tasks lifecycle.
---
# Velo Parallelism Rules

## Core rule — single runtime turn for independents

When multiple todo items / tasks are independent (no shared dependency), their agents MUST be spawned in **one runtime turn** through `spawn-agent`, so they run concurrently. Sequential spawning of independent work is a bug, not a style choice.

This applies to:
- Independent domains (FE + Infra, FE + BE against mocks)
- Multiple reviewers (always parallel)
- Multiple tasks of the same agent type

## Dependency rule

A dependency exists when a later item needs output from an earlier one. Absent a real dependency, parallelize.

Standard dependencies:
- **DB before BE** — schema dependency
- **Builders before reviewers** — review needs code to read
- **Automation engineer depends on ALL builders** — tests need the full surface to exercise
- **FE can always start in parallel against mocks** — FE depends on BE only for integration, not for first build

## Task-breakdown encoding

In `.velo/tasks/<slug>/task-breakdown.md`, the `Depends On` column drives parallelism:
- `Depends On: —` → can start immediately, batches with other no-dependency tasks
- `Depends On: T1` → cannot start until T1 completes
- `Depends On: T1, T2` → cannot start until both complete

Tasks with no dependency batch together into a single parallel spawn. Tasks with shared dependencies form the next batch once their dependencies complete.

## track-tasks lifecycle and batch boundaries

Register all builders / reviewers as todo items via `track-tasks` **before spawning**. Apply the lifecycle:

- Mark each item `in_progress` when its agent starts
- Mark each item `completed` when it returns
- **Only one item `in_progress` per parallel batch boundary**: parallel spawns mark multiple items `in_progress` simultaneously (one batch); sequential spawns mark one at a time

A "batch boundary" is a parallel spawn group. Within a batch, multiple items can be `in_progress`. Between batches, items must be `completed` before the next batch's items go `in_progress`.

Same lifecycle rules apply across `BUILD_PHASE` and `REVIEW_PHASE` (`/velo:new`) and across `SPEC_AUDIT`, `BUILD`, and `REVIEW` (`/velo:task`).

## Mandatory reviewer pairings

In review states:
- **If BE engineer was involved**: always spawn the observability-engineer and security-engineer alongside the be-reviewer — same BE changes, different lenses.
- **If FE engineer was involved**: always spawn the security-engineer alongside the fe-reviewer — reviews for XSS, sensitive data exposure, insecure token storage.

All reviewers in a state spawn in one parallel batch.

## Re-spawn rules during rework

When a rework cycle re-spawns only the failing reviewers (not the full panel), they still spawn in a single parallel batch if there is more than one. Instruct re-spawned reviewers: *"Re-check only the previously flagged issues — do not perform a full re-review."*

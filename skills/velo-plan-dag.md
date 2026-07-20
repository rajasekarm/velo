---
name: velo-plan-dag
description: Node/edge schema for /velo:task and /velo:plan plan announcements. Node fields (id, agent, does, skills, needs), predecessor-list edges, batch derivation per velo-parallelism, plain-markdown rendering, and the node-granularity rule.
---
# Velo Plan DAG

## Purpose

Replaces the coarse "Execution: parallel vs sequential" line in the `/velo:task` announcement with an explicit node/edge plan. Built during `PLAN_AND_ANNOUNCE` Part 1; consumed by `BUILD` for spawn batching. Also consumed by `/velo:plan`: `DAG_PHASE` transforms the Tech Lead's task-breakdown table into this node schema, and `PLAN_APPROVAL` renders it per the rules below (user-facing heading `Plan:` — plan mode does not surface the DAG acronym to the user).

## Node schema

Each node declares, on one line:

- **id** — T1, T2, ... in topological order (T = task)
- **agent** — a builder/automation agent name from `TEAM.md`
- **does** — one line: what this node produces
- **skills** — the composed skill set per [Velo Skill Composition](velo-skill-composition.md): default-bundle slugs plain, additions prefixed with `+`
- **needs** — `—` (no dependency) or a comma-list of EARLIER node ids

## Edges and batches

Edges are the `needs` predecessor lists — no separate edge table. `needs` may only reference earlier-declared ids (acyclic by construction).

Batches derive exactly as [Velo Parallelism](velo-parallelism.md) derives them from `Depends On`: `needs: —` nodes form batch 1 and spawn in ONE runtime turn; a node joins a later batch when all its `needs` complete. Standard dependencies bind: DB before BE; automation depends on ALL builders; FE starts against mocks.

## Node-granularity rule

A node earns independence only if it (a) **fans out** — has a parallel sibling in some batch — OR (b) **exposes a clean interface seam** consumed by a dependent node. Same-file sequential work stays ONE node. Do not manufacture branches to look decomposed. A single-node DAG is valid.

## Rendering in the announcement

Plain markdown list — never a fenced code block:

Plan (DAG):
- T1 · \<agent\> — \<does\> · skills: \<slug\>, \<slug\>, +\<addition\> · needs: —
- T2 · \<agent\> — \<does\> · skills: \<slug\> · needs: T1

Execution: batch 1 — \<ids\> in parallel; batch 2 — \<ids\> after \<ids\>; ...
(For a single-node DAG: "Execution: single node — no parallelism.")

Worked example:

Plan (DAG):
- T1 · db-engineer — add `expires_at` to sessions schema · skills: postgresql, clickhouse · needs: —
- T2 · be-engineer — expose expiry in GET /sessions · skills: nodejs, api-and-interface-design, +kafka · needs: T1
- T3 · fe-engineer — render expiry badge (against mocks) · skills: react, react-effects, vercel-react-best-practices · needs: —
- T4 · automation-engineer — e2e coverage for expiry flow · skills: playwright, vitest · needs: T2, T3

Execution: batch 1 — T1, T3 in parallel; batch 2 — T2 after T1; batch 3 — T4 after all builders.

## Scope

DAG nodes are builders + automation only. Reviewers are NEVER DAG nodes — `REVIEW` derives its reviewer set from the pairing classification and the builders that ran, exactly as before. One DAG node = one todo item = one agent (`track-tasks`). Consumers: `/velo:task` (`PLAN_AND_ANNOUNCE`/`BUILD`) and `/velo:plan` (`DAG_PHASE`/`PLAN_APPROVAL`; the approved DAG is carried in the plan package per [Velo Plan Package](velo-plan-package.md)).

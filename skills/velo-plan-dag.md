---
name: velo-plan-dag
description: Node/edge semantics for /velo:task and /velo:plan plan announcements, scoped to a milestone. Node fields (id, agent, does, skills, needs), predecessor-list edges including cross-milestone ones, per-milestone batch derivation via velo-parallelism, plain-markdown rendering of milestones and task lines, and the node-granularity rule.
---
# Velo Plan DAG

## Purpose

Replaces the coarse "Execution: parallel vs sequential" line in the `/velo:task` announcement with an explicit node/edge plan. Built during `PLAN_AND_ANNOUNCE` Part 1; consumed by `BUILD` for spawn batching. Also consumed by `/velo:plan`: `DAG_PHASE` transforms the Tech Lead's task breakdown into this node schema, and `PLAN_APPROVAL` renders it per the rules below (the DAG acronym never surfaces to the user — see the heading rule under Rendering).

**The plan is not flat.** Tasks live inside milestones — `## M1..Mn` headings in the carrier, `task-breakdown.md`, whose format is specified in [Velo Task Status](velo-task-status.md). Milestones are always present: a single-task plan is `## M1` with one task, never a milestone-less table. Everything below is read with that structure in mind — nodes belong to a milestone, edges may cross milestones, batches never do.

## Node schema

Each node is one task line inside a milestone, declaring:

- **id** — T1, T2, ... in topological order (T = task). Ids are unique across the whole breakdown and keep counting across milestone boundaries — M1 ending at T2 means M2 opens at T3. Never restart numbering per milestone.
- **agent** — a builder/automation agent name from `TEAM.md`
- **does** — one line: what this node produces
- **skills** — the composed skill set per [Velo Skill Composition](velo-skill-composition.md): default-bundle slugs plain, additions prefixed with `+`. The Tech Lead writes task lines without this field; Velo enriches them at the `PLAN_APPROVAL` freeze.
- **needs** — `—` (no dependency) or a comma-list of EARLIER node ids, in this milestone or an earlier one

In the carrier, each task line also carries a live `Status` — that field belongs to the executor, and its vocabulary and rules live in [Velo Task Status](velo-task-status.md), not here.

Each milestone carries a name on its heading and its own `Branch:` / `Shipped:` metadata line per the carrier spec. A zero-task milestone is invalid output.

## Edges and batches

Edges are the `needs` predecessor lists — no separate edge table. `needs` may only reference earlier-declared ids, so the graph is acyclic by construction.

**Cross-milestone edges are allowed.** A task in M2 may declare `needs: T2` where T2 lives in M1. What is forbidden is the reverse direction: a task never depends on a task in a later milestone, because milestones ship in order and a forward edge would deadlock the stack.

Batches derive exactly as [Velo Parallelism](velo-parallelism.md) derives them: nodes with nothing left to wait on form batch 1 and spawn in ONE runtime turn; a node joins a later batch when all its `needs` complete. Standard dependencies bind: DB before BE; automation depends on ALL builders; FE starts against mocks.

**Batch derivation is per-milestone, and a batch never spans milestones.** Derive batches for M1 over M1's tasks only, for M2 over M2's tasks only, and so on — each milestone's numbering starts again at batch 1. This is load-bearing: milestones serialize (M(i+1) does not start until M(i)'s review passes and its ship gate resolves), so no task in M(i+1) can ever be spawned in the same runtime turn as a task in M(i), however independent the two look on paper.

A cross-milestone `needs` therefore never constrains batching: by the time M(i)'s tasks are eligible to spawn, every task in every earlier milestone is already `done`. Such an edge is a statement of ordering intent that the milestone boundary has already satisfied — a task in M2 whose only dependency is a task in M1 belongs to M2's batch 1.

## Node-granularity rule

A node earns independence only if it (a) **fans out** — has a parallel sibling in some batch — OR (b) **exposes a clean interface seam** consumed by a dependent node. Same-file sequential work stays ONE node. Do not manufacture branches to look decomposed. A single-node milestone is valid, and so is a whole breakdown that is one milestone holding one task.

Milestones follow the same discipline from the other direction: they are shippable slices, not a decomposition device. Do not split a milestone to make the plan look staged.

## Rendering in the announcement

Plain markdown list — never a fenced code block. **Heading rule (canonical)**: render the heading as `Plan:` — never `Plan (DAG):`, never any graph jargon in front of the user; the `needs` fields and the Execution line carry the structure. This is the single canonical render for every consumer — consumers do not override or restate it.

Under that heading, render one block per milestone: the milestone's name, its task lines, then its own Execution line. **Milestone names and task lines surface to the user; DAG vocabulary does not** — the user reads named slices of work and what runs together, never "node", "edge", "graph", or "DAG".

Plan:

M1 — \<milestone name\>
- T1 · \<agent\> — \<does\> · skills: \<slug\>, \<slug\>, +\<addition\> · needs: —
- T2 · \<agent\> — \<does\> · skills: \<slug\> · needs: T1

Execution: batch 1 — \<ids\> in parallel; batch 2 — \<ids\> after \<ids\>; ...

M2 — \<milestone name\>
- T3 · \<agent\> — \<does\> · skills: \<slug\> · needs: T2

Execution: single node — no parallelism.

Every milestone gets its own Execution line — there is no plan-wide one, because there is no plan-wide batch. (For a milestone holding one task: "Execution: single node — no parallelism.") A one-milestone plan still renders its milestone name; do not flatten it away.

Worked example:

Plan:

M1 — Expiry stored, served, and shown
- T1 · db-engineer — add `expires_at` to sessions schema · skills: postgresql, clickhouse · needs: —
- T2 · be-engineer — expose expiry in GET /sessions · skills: nodejs, api-and-interface-design, +kafka · needs: T1
- T3 · fe-engineer — render expiry badge (against mocks) · skills: react, react-effects, vercel-react-best-practices · needs: —

Execution: batch 1 — T1, T3 in parallel; batch 2 — T2 after T1.

M2 — Expiry covered end to end
- T4 · automation-engineer — e2e coverage for expiry flow · skills: playwright, vitest · needs: T2, T3

Execution: single node — no parallelism.

T4's `needs` reach back into M1 — legal, and already satisfied when M2 opens, so T4 is M2's batch 1.

The same task lines, under the same milestone headings, are what the carrier holds on disk — with `Status` appended per [Velo Task Status](velo-task-status.md), and with the `Execution:` line appended by Velo at the `PLAN_APPROVAL` freeze.

## Scope

Plan tasks are builders + automation only. Reviewers are NEVER plan tasks — each milestone's `REVIEW` derives its reviewer set from the pairing classification and the builders that ran in that milestone, per [Velo Parallelism](velo-parallelism.md). One task = one todo item = one agent (`track-tasks`). Consumers: `/velo:task` (`PLAN_AND_ANNOUNCE`/`BUILD`) and `/velo:plan` (`DAG_PHASE`/`PLAN_APPROVAL`; the approved plan is frozen into the milestone body of the carrier, `.velo/tasks/<slug>/task-breakdown.md`, per [Velo Task Status](velo-task-status.md)).

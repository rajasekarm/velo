---
name: velo-skill-composition
description: How Velo resolves a plan-DAG node's skill set at plan time. Default bundle from the agent file via TEAM.md, additive task-declared additions from the existing skills/ catalog, existence validation, ordered-union dedup, freeze-at-approval.
---
# Velo Skill Composition

## When this applies

At `PLAN_AND_ANNOUNCE` Part 1 (`/velo:task`) and at `DAG_PHASE` (`/velo:plan`, after the Tech Lead's breakdown is transformed into DAG nodes), once per DAG node, before the plan renders for approval. Never at spawn time, never inside an agent. Skill selection is orchestrator-composed: Velo resolves each node's skill set by explicit lookup — agents never self-select skills mid-run.

## The composition rule

A node's composed skill set = **default bundle + task-declared additions**.

## Default bundle — where it comes from

1. Find the node's agent row in `TEAM.md`.
2. Read the file named in that row's **File** column (`agents/<name>.md`).
3. The links in that file's `## Skills` section are the default bundle, in file order.

The TEAM.md Skills column lists the same slugs for quick reference, but the agent file's `## Skills` section is canonical — resolve the bundle from the agent file, not the roster column. The TEAM.md row is the index; the agent file is the payload.

## Task-declared additions — how a task declares them

An addition is a skill **slug**: the basename of `skills/<slug>.md` without the extension (e.g. `kafka`, `api-and-interface-design`).

Velo attaches an addition to a node only when a term in the brief or in the node's scope explicitly matches a catalog skill's frontmatter `name` or `description`. Frontmatter only — do not scan skill bodies. If no explicit match exists, attach nothing. Explicit lookup, not free reasoning.

## Validation — Velo must not invent skills

Every addition must pass an existence check via `read-files`: `skills/<slug>.md` exists, exact filename match, no fuzzy matching.

- Exists → keep.
- Does not exist → **DROP the addition and flag it** in the announcement: `skill '<slug>' not in catalog — proceeding without it`. Never create a file, never link an unverified path, never substitute a "close" name.

## Dedup and conflicts

- **Ordered union**: default bundle first (agent-file order), then additions (declaration order). Exact-slug dedup — an addition already in the default bundle is a silent no-op.
- **Additive-only**: never remove a skill from a default bundle. Named agents keep their identity; composition augments, never subtracts.
- If an addition's rules contradict a default skill's rules, the default bundle wins; flag the conflict in the announcement.
- **Cap: at most 3 additions per node.** Needing more means the node is too broad — repartition per [Velo Plan DAG](velo-plan-dag.md) instead.

## Freeze point

The composed set is frozen when the user approves the plan — `/velo:task`'s announcement gate or `/velo:plan`'s `PLAN_APPROVAL` gate. `BUILD` injects exactly the approved set (see the `inject-skills` concept in `ADAPTER.md`); a plan-mode set is carried frozen in the plan package. An assumption or pairing flip at the gate (or an `I have changes` plan revision in `/velo:plan`) re-runs composition along with the rest of the planning step. Rework re-spawns (REVIEW cycles, SHIP_GATE feedback) inherit the node's frozen composition unchanged.

## Scope

Applies to builder and automation nodes in `/velo:task` and `/velo:plan` (`DAG_PHASE`). In plan mode, composition is done by Velo the orchestrator after the Tech Lead returns the breakdown — the TL never composes skills. Reviewers are not composed this round — they keep their static agent-file bundles, so reviewer routing (task.md Pairing + [Velo Parallelism](velo-parallelism.md) mandatory pairings) is untouched. `/velo:hunt` and `/velo:yo` do not use this skill yet.

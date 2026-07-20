---
name: velo-plan-package
description: The Plan→Task handoff contract. Package format /velo:plan hands to /velo:task via handoff-mode (Planned-via, Task-folder, Depth, Pairing headers, frozen DAG, confirmed ledger), plus the descope-as-reentry variant Task hands back. Producer is /velo:plan (increment 1); executor-side consumption lands in increment 2.
---
# Velo Plan Package

## Purpose

The single contract between planning (`/velo:plan`) and execution (`/velo:task`). Plan mode assembles this package at `HANDOFF`; task mode receives it as its argument via `handoff-mode`. The same format, extended with re-entry fields, is what task mode hands back when a descope resolves to a re-plan.

**Frozen contract**: the header keys — `Planned-via`, `Task-folder`, `Depth`, `Pairing`, `Re-entry`, and the `done:` node annotation — are stable from day one. The increment-2 task.md rewrite dispatches on them; do not rename or repurpose them.

## Package format

```
Planned-via: /velo:plan
Task-folder: .velo/tasks/<slug>/
Depth: heavy | light (trigger <1|2|3|—>)
Pairing: product | pure-tech

Brief (verbatim): <the original user brief, unedited>

Assumptions (confirmed at plan gate):
- <term> → <interpretation/signal>
- (or "(none)" if nothing was ambiguous)

Plan (DAG) — frozen at plan approval:
- T1 · <agent> — <does> · skills: <slug>, <slug>, +<addition> · needs: — [· done: <what it delivered>]
- T2 · <agent> — <does> · skills: <slug> · needs: T1
Execution: batch 1 — <ids> in parallel; batch 2 — <ids> after <ids>.

Artifacts: task-breakdown.md [, prd.md] [, engineering-design-doc.md]
Constraints/notes: <F5 notes, dropped-skill flags, unresolved spec findings carried under an F2-spec override, unresolved DE design findings carried under an F2-edd override, or "(none)">
```

Field semantics:

- **`Planned-via`** — the executor's dispatch key. Increment 2: a package-bearing `/velo:task` invocation skips its own planning (no re-partition, no re-composition — the frozen DAG is authoritative) and suppresses its escalate-to-`/velo:new` rule. Increment 1: advisory only — stock task.md re-validates and re-announces; plan mode warns the user at `HANDOFF`.
- **`Task-folder`** — where the durable artifacts live. The inline package is self-sufficient; the folder is the disk backup and the re-entry anchor.
- **`Depth`** — which path planning took and which trigger fired. Auditability only; the executor does not branch on it.
- **`Pairing`** — the product/pure-tech classification computed at plan mode's `VALIDATE`, carried so the executor's reviewer routing needs no re-derivation.
- **DAG node lines** — exactly the [Velo Plan DAG](velo-plan-dag.md) rendering, skills field per [Velo Skill Composition](velo-skill-composition.md), frozen at `PLAN_APPROVAL`. Rework re-spawns inherit the frozen composition.
- **`done:`** — per-node annotation, absent/empty on first handoff. Populated only in re-entry packages; a `done:` node is complete and MUST NOT be re-run by the executor.
- **`engineering-design-doc.md`** — present in `Artifacts` on the **heavy path only**. Plan mode's heavy tier authors it at `DESIGN_PHASE`, the Distinguished Engineer reviews it at `DESIGN_REVIEW`, and the user signs off at `DESIGN_APPROVAL`; the DAG is derived from this approved design. The light path carries no EDD (`task-breakdown.md` + confirmed ledger only). The executor reads the referenced EDD for build context; it does not re-review it.

## Re-entry variant (descope-as-reentry)

**Dormant until increment 2** — defined here so both sides agree before the executor rewrite lands.

Task mode owns the bounded review/rework loop outright: reviewer findings, builder rework, and F2 review cycles never leave task mode. Only **scope-level** deviations re-enter plan mode — exactly the [Velo Descope Ritual](velo-descope-ritual.md) triggers: F3 (builder flags scope confusion), F4 (agent count exceeds plan), F5 (cross-task dependency surfaces mid-build), and the F2-cap descope. When the ritual's resolution is a re-plan (the `Cut scope`/re-plan branch — not `Keep going`, not `Abandon`), task mode exits via `handoff-mode` → `/velo:plan` carrying the original package plus:

```
Re-entry: descope (<F-code>)
Build state:
- done: <node id> — <one line: what it delivered>
- abandoned in-flight: <node id> — <state it was left in>
Finding: <the scope-level finding that triggered the ritual, verbatim>
Descope choice: <what the user said to cut or re-plan>
```

Plan-side semantics (defined in `commands/plan.md` — Re-entry section): `VALIDATE` recognizes the `Re-entry:` header, skips fresh interpretation of the original brief (the confirmed ledger carries), re-evaluates the depth gate **on the delta only**, and re-plans with `done:` nodes preserved verbatim so the executor never re-runs them.

Task-side terminal for this exit: `replanned-via-plan` (increment 2 defines it in task.md's telemetry; named here so the taxonomy is agreed).

## Scope

Producer: `/velo:plan`'s `HANDOFF` state (increment 1). Consumers: `/velo:task` (binding consumption is increment 2; until then the package is a well-formed brief that stock task.md plans over again). No other command produces or consumes this format.

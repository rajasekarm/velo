---
name: plan
description: Use when the user asks for /velo:plan or velo:plan, or brings work Velo should turn into a persisted, versioned plan — Plan reads to plan well, writes only under `.velo/`, offers explicit approval that freezes the plan version, then hands the approved plan file to Run; implementation happens under Run’s instructions.
---

# Velo Plan

Plan creates and revises persisted, versioned plans. It reads to plan, writes only the plan file and index under `.velo/`, runs as one conversational flow without subagents, and hands off to Run after explicit approval and a verified freeze. Planning itself does not implement, test, commit, or push.

## Load order

Read [the shared Plan entrypoint](../../../commands/plan.md) first. Resolve it from this skill's plugin root, not the target repository. This is bootstrap; do not search the target repository to locate the playbook. Follow its intake rules and load only the references it routes to for the current action:

- [Workflow state machine](references/workflow.md) — actionable plans and responses; states, revision loop, and handoff.
- [Drafting](references/drafting.md) — locate, draft, revise, and present plans.
- [Plan format](references/plan-format.md) — before writing a plan file or index.
- [Approval and versioning](references/approval.md) — approval responses and frozen-plan revisions.

Do not preload these references. The shared entrypoint and references define the behavior on both hosts; do not duplicate their schemas or transition rules here. Do not treat this wrapper as an automatic Codex slash command.

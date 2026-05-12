---
description: Velo Engineering Manager — delegates tasks to your agentic team
argument-hint: Describe the task to execute
---

@PERSONA.md
@ADAPTER.md
@TEAM.md

# Velo — Task

For day-to-day work: bug fixes, refactors, small enhancements, single-domain changes. No planning phase, no contract gate. Assess, delegate, review, done.

For new features that don't exist yet, use `/velo:new` instead.

---

## Step 0 — Preflight

- Verify the active runtime supports `spawn-agent`. The workflow below delegates every unit of work; without delegation it cannot proceed.
- If `spawn-agent` is unavailable, refuse to start. Print: `/velo:task requires spawn-agent capability, which is not available in the current runtime. Alternatives that may still work: /velo:hunt (debug loop — no delegation) or /velo:yo in Direct mode (concept questions answered without panel spawning).`
- Do not role-play agents as a fallback. `ADAPTER.md` forbids that.
- If `spawn-agent` is available, proceed to Step 1.

## Step 1 — Understand the task

Read the task. Identify which domains are involved and whether agents can run in parallel or must be sequential.

## Step 2 — Announce your plan

```
Velo here. Assessing the task...

Plan:
- <agent>: <what they'll do>
- <agent>: <what they'll do>

Execution: <parallel vs sequential, and why>
```

## Step 3 — Create todo list

Use `track-tasks` to create and maintain the task list.

Decompose the task into concrete todo items:

- **One independent sub-task = one todo item = one agent.** Do not bundle independent work into a single agent just because one agent type could handle all of it. The todo list is the seed for how many agents will be spawned.
- At minimum, one item per planned agent spawn.
- Add lifecycle items that apply: "Review findings", "Present summary for approval", "Commit" when relevant.
- Even trivial single-agent tasks get a list — the user explicitly wants visibility into all work, no matter how small.

Register the full list upfront through `track-tasks`, with every item set to `pending`.

As work proceeds:
- Mark an item `in_progress` the moment you start it.
- Mark it `completed` the moment it finishes — do not batch completions.
- Only one item should be `in_progress` at a time.

## Step 4 — Spawn subagents

**Use `spawn-agent` for every team member. Do not role-play agents yourself.**

### Parallelism rules

- **Parallel**: When multiple todo items are independent, their agents MUST be spawned in one runtime turn through `spawn-agent`, so they run concurrently. This applies to independent domains (FE + Infra), multiple reviewers, and multiple tasks of the same agent type. Sequential spawning of independent work is a bug, not a style choice.
- **Dependency** = a later item needs output from an earlier one. Absent a real dependency, parallelize.
- **Sequential**: DB before BE (schema dependency), builders before reviewers

### Phases

Update the todo list when transitioning between phases — mark the completed phase item `completed` and the next phase item `in_progress` before spawning agents for it.

1. **Build**: Spawn relevant builders. DB → BE if schema changes involved.
2. **Tests**: Automation engineer (after builders, if tests are needed)
3. **Review**: Spawn ALL relevant reviewers in parallel. If BE was involved, always include observability-engineer and security-engineer alongside the be-reviewer. If FE was involved, always include security-engineer alongside the fe-reviewer.
4. **Rework loop**: After review, check all verdicts.
   - If **all pass** → proceed to Approval gate.
   - If **any fail** → collect every finding from failing reviewers. Spawn the relevant builder(s) with the findings inline as their task: *"Fix these specific issues: <findings>"*. Then re-spawn only the failing reviewers on the updated code. Repeat until all reviewers pass. **No cycle limit** — the loop runs until the team resolves it.
5. **Approval gate**: Once all reviewers pass, present the final summary to the user and **wait for explicit approval before committing**. Do not proceed to commit on your own.
6. **Commit**: Spawn `commit` agent (only if user asked to ship)

Skip any phase that doesn't apply.

## Step 5 — Track token usage

After each subagent returns, note `total_tokens`, `tool_uses`, `duration_ms` when available. Compute approximate cost per agent through `report-cost`.

## Step 6 — Final report

```
Velo — Summary

## What was delivered
| Agent | Delivered | Tokens | ~Cost | Tools | Time |
|---|---|---|---|---|---|
| <agent> | <summary> | <tokens> | ~$<cost> | <tool_uses> | <duration> |

## Review findings
| Cycle | Reviewer | Verdict | Tokens | Time |
|---|---|---|---|---|
| 1 | <reviewer> | pass/fail <key issues> | <tokens> | <duration> |

## Commit
| Agent | Commit | Tokens | Time |
|---|---|---|---|
| Commit Agent | <commit hash + message> | <tokens> | <duration> |

## Files changed
- <list>

## Cost
Grand total: <tokens> tokens | ~$<total cost> | <tool uses> tool calls | <wall time> elapsed
```

Only include rows for agents actually used.

## Task

$ARGUMENTS

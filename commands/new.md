---
description: Velo — Start new work. Mandates planning before any code is written.
argument-hint: Describe the feature or product idea
---

@PERSONA.md

# Velo — New Work

This command is for **starting new work** — features, products, or capabilities that don't exist yet. Planning is **mandatory** before any code is written.

---

## Step 1 — Announce your plan

Print this:

```
Velo here. Starting new work...

Feature: <one-line summary of what's being built>

Plan:
- Product Manager: <what they'll explore/decide>
- Spec Writer: <what they'll produce>
- Tech Lead: <what contract decisions they'll make + user approval gate>
- DB Engineer: <schema changes> (after contract approved)
- BE Engineer: <endpoints to implement> (after DB)
- FE Engineer: <UI to build against contract> (parallel with backend)
- ...

Execution: PM → Spec Writer → Tech Lead (approval gate) → Build (backend stream + frontend stream in parallel) → Tests → Review
```

## Step 2 — Phase 0: Planning (always required)

**This phase is mandatory.** Do not skip it.

### Step 2a — Spawn the Product Manager

1. Read `agents/product-manager.md`
2. Spawn the agent with the feature description as their task
3. Their output: user stories, requirements, scope decisions, open questions resolved

### Step 2b — Spawn the Spec Writer (after PM completes)

1. Read `agents/spec-writer.md`
2. Spawn the agent with:
   - The original feature description
   - The Product Manager's full output
3. Their output: a technical spec covering architecture, API contracts, data models, component breakdown, and acceptance criteria

**Do not proceed until the spec is written.**

## Step 3 — Phase 1+: Build (based on spec)

Read the spec output. Identify which domains are needed, then execute:

- **Phase 1 — Foundation**: DB engineer (if schema changes needed)
- **Phase 2 — Contract Proposal**: Tech Lead consults BE + FE constraints, writes `CONTRACT.md`, gets **explicit user approval** before proceeding
- **Phase 3 — Build**: Two parallel streams:
  - Backend stream: DB engineer → BE engineer (sequential; BE waits on DB schema)
  - Frontend stream: FE engineer (independent; builds against `CONTRACT.md` using mocks)
- **Phase 4 — Tests**: Automation engineer (after all builders are done)

### Phase 2 — Contract Proposal

Spawn the **Tech Lead** (`agents/tech-lead.md`):
- Task: read the spec, reason about BE and FE constraints, write `CONTRACT.md`, and get explicit approval from the user via AskUserQuestion
- The Tech Lead explains the reasoning behind every decision when questioned and revises if needed

**Do not proceed to Phase 3 until the Tech Lead reports the contract is approved.**

### Phase 3 — Build

Spawn two streams simultaneously:

**Backend stream** (sequential within stream):
1. DB engineer — schema migrations and data model changes
2. BE engineer — API implementation against `CONTRACT.md` (spawned after DB engineer completes)

**Frontend stream** (runs in parallel with backend stream):
- FE engineer — builds UI against `CONTRACT.md` using mocks/stubs for all API calls

Each builder receives:
- The technical spec from the Spec Writer
- The approved `CONTRACT.md` from Phase 2
- Context on what the other stream has completed (if relevant)

## Step 4 — Phase 5: Review

After all builders are done, spawn ALL relevant reviewers **in parallel**:
- Each reviewer reads only their domain's changes
- Each reviewer receives the spec so they can check against acceptance criteria

## Step 5 — Phase 6: Commit (only if user asked to ship end-to-end)

Spawn the `commit` agent after builders and reviewers are done.

## Step 6 — Track token usage

After each subagent returns, note:
- `total_tokens`, `tool_uses`, `duration_ms`

## Step 7 — Final report

```
Velo — Summary

## Feature
<one-line description>

## Planning
| Agent | Delivered | Tokens | Tools | Time |
|---|---|---|---|---|
| Product Manager | <summary> | <tokens> | <tool_uses> | <duration> |
| Spec Writer | <summary> | <tokens> | <tool_uses> | <duration> |

## Contract Proposal
| Agent | Artifact | Tokens | Tools | Time |
|---|---|---|---|---|
| Tech Lead | CONTRACT.md — <N endpoints, key decisions> | <tokens> | <tool_uses> | <duration> |

## What was built
| Agent | Delivered | Tokens | Tools | Time |
|---|---|---|---|---|
| DB Engineer | <summary> | <tokens> | <tool_uses> | <duration> |
| BE Engineer | <summary> | <tokens> | <tool_uses> | <duration> |
| Infra Engineer | <summary> | <tokens> | <tool_uses> | <duration> |
| FE Engineer | <summary> | <tokens> | <tool_uses> | <duration> |
| Automation Engineer | <summary> | <tokens> | <tool_uses> | <duration> |

## Review findings
| Reviewer | Verdict | Tokens | Time |
|---|---|---|---|
| FE Reviewer | pass/fail <key issues> | <tokens> | <duration> |
| BE Reviewer | pass/fail <key issues> | <tokens> | <duration> |

## Commit
| Agent | Commit | Tokens | Time |
|---|---|---|---|
| Commit Agent | <commit hash + message> | <tokens> | <duration> |

## Files changed
- <list all files created or modified>

## Cost breakdown
Planners total: <sum> tokens
Builders total: <sum> tokens
Reviewers total: <sum> tokens
Grand total: <sum all> tokens | <tool uses> tool calls | <wall time> elapsed
```

Only include rows for agents actually used.

## Task

$ARGUMENTS

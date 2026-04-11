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
Task folder: .velo/tasks/<task-slug>/

Plan:
- Product Manager: <what they'll explore/decide>
- Tech Lead: <reads PRD + codebase, defines contract, gets approval>
- DB Engineer: <schema changes> (after contract approved, if needed)
- BE Engineer: <endpoints to implement> (after DB)
- Infra Engineer: <infrastructure changes> (if needed, parallel with BE)
- FE Engineer: <UI to build against contract> (parallel with backend)
- ...

Execution: PM → Tech Lead (approval gate) → Build (backend stream + FE stream in parallel) → Tests → Review
```

## Step 1b — Create task folder

Derive a slug from the feature name: lowercase, spaces and special characters replaced with hyphens, trimmed.

Example: "User Authentication Flow" → `user-authentication-flow`

Create the folder before spawning any agent:
```
mkdir -p .velo/tasks/<slug>
```

All planning artifacts for this task live in `.velo/tasks/<slug>/`. Pass the full folder path to every agent you spawn.

## Step 2 — Phase 0: PM (always required)

**This phase is mandatory.** Do not skip it.

### Spawn the Product Manager

1. Read `agents/product-manager.md`
2. Spawn the agent with:
   - The feature description
   - The task folder path: `.velo/tasks/<slug>/`
3. Their output: user stories, requirements, scope decisions, open questions resolved — written to `.velo/tasks/<slug>/prd.md`

**Do not proceed until `prd.md` is written.**

### PRD Approval Gate

Use **AskUserQuestion** to present the PRD for approval:
- **Header**: "PRD Review"
- **Question**: "I've written the PRD at `.velo/tasks/<slug>/prd.md`. Here's a summary: [2–3 bullet summary of goals, user stories, and scope]. Ready to proceed to contract design?"
- **Options**:
  - "Approved — proceed to contract design"
  - "I have changes"

If the user has changes: convey them to the PM for revision, wait for the updated `prd.md`, then re-present.

**Do not proceed until the PRD is explicitly approved.**

## Step 3 — Phase 1: Contract Proposal

### Spawn the Tech Lead

1. Read `agents/tech-lead.md`
2. Spawn the agent with:
   - The task folder path: `.velo/tasks/<slug>/`
   - Instruction to read `.velo/tasks/<slug>/prd.md` and the existing codebase
3. Their output: `.velo/tasks/<slug>/contract.md`

### Contract Review Pass

After Tech Lead completes:

1. Read `agents/distinguished-engineer.md`
2. Spawn the Distinguished Engineer with the task folder path
3. If verdict is **REVISE**: spawn Tech Lead again with the reviewer's critique, wait for revised `contract.md`, then re-run the Distinguished Engineer
4. Repeat until verdict is **APPROVE**

### Contract Approval Gate

Use **AskUserQuestion** to present the contract for approval:
- **Header**: "Contract Review"
- **Question**: "The contract is at `.velo/tasks/<slug>/contract.md` and passed internal review. Summary: [list key endpoints and top 3 decisions]. Ready to proceed to build?"
- **Options**:
  - "Approved — proceed to build"
  - "I have changes"

If the user has changes: convey them to the Tech Lead for revision, re-run the Distinguished Engineer, then re-present.

**Do not proceed to build until the contract is explicitly approved.**

## Step 4 — Phase 2: Build

Identify which domains are needed from the contract, then spawn:

- **Phase 2 — Build**: Three streams:
  - Backend stream (sequential): DB engineer (if schema changes) → BE engineer
  - Infra stream (if needed, parallel): Infra engineer
  - Frontend stream (parallel): FE engineer (independent; builds against contract using mocks)
- **Phase 3 — Tests**: Automation engineer (after all builders are done)

### Backend stream

Spawn sequentially:
1. DB engineer — schema migrations and data model changes (only if contract requires schema changes)
2. BE engineer — API implementation against `.velo/tasks/<slug>/contract.md`

### Infra stream (if needed)

Spawn in parallel with backend stream if the contract or PRD requires infrastructure changes (new services, queues, etc.):
- Infra engineer

### Frontend stream

Spawn in parallel with backend stream:
- FE engineer — builds UI against `.velo/tasks/<slug>/contract.md` using mocks/stubs for all API calls

Each builder receives:
- The task folder: `.velo/tasks/<slug>/`
- The PRD: `.velo/tasks/<slug>/prd.md`
- The approved contract: `.velo/tasks/<slug>/contract.md`
- Context on what the other stream has completed (if relevant)

## Step 5 — Phase 4: Review

After all builders are done, spawn ALL relevant reviewers **in parallel**:
- Each reviewer reads only their domain's changes
- Each reviewer receives the PRD and contract so they can check against acceptance criteria
- **If BE engineer was involved**: always spawn the observability-engineer and security-engineer alongside the be-reviewer — same BE changes, different lenses
- **If FE engineer was involved**: always spawn the security-engineer alongside the fe-reviewer — reviews for XSS, sensitive data exposure, insecure token storage

## Step 6 — Phase 5: Commit (only if user asked to ship end-to-end)

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

## Contract Proposal
| Agent | Artifact | Tokens | Tools | Time |
|---|---|---|---|---|
| Tech Lead | `.velo/tasks/<slug>/contract.md` — <N endpoints, key decisions> | <tokens> | <tool_uses> | <duration> |

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

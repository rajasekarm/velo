---
description: Velo — Start new work. Mandates planning before any code is written.
argument-hint: Describe the feature or product idea
---

@PERSONA.md
@TEAM.md

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
- Tech Lead: <reads PRD + codebase, writes engineering design doc, gets approval>
- DB Engineer: <schema changes> (after engineering design doc approved, if needed)
- BE Engineer: <endpoints to implement> (after DB)
- Infra Engineer: <infrastructure changes> (if needed, parallel with BE)
- FE Engineer: <UI to build against engineering design doc> (parallel with backend)
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
- **Question**: "I've written the PRD at `.velo/tasks/<slug>/prd.md`. Here's a summary: [2–3 bullet summary of goals, user stories, and scope]. Ready to proceed to engineering design doc?"
- **Options**:
  - "1 — Approved, proceed to engineering design doc"
  - "2 — I have changes"

If the user has changes: convey them to the PM for revision, wait for the updated `prd.md`, then re-present.

**Do not proceed until the PRD is explicitly approved.**

## Step 3 — Phase 1: Engineering Design Doc

### Spawn the Tech Lead

1. Read `agents/tech-lead.md`
2. Read `.velo/tasks/<slug>/prd.md` — you will pass the contents inline
3. Spawn the agent with:
   - The task folder path: `.velo/tasks/<slug>/`
   - The full contents of `prd.md` embedded directly in the prompt (do not ask the agent to read it — provide it inline)
   - Instruction to read the existing codebase for conventions and constraints
4. Their output: `.velo/tasks/<slug>/engineering-design-doc.md` and `.velo/tasks/<slug>/task-breakdown.md`

### Validate Tech Lead output

Before proceeding, verify both files exist:
- `.velo/tasks/<slug>/engineering-design-doc.md`
- `.velo/tasks/<slug>/task-breakdown.md`

If either is missing — **stop**. Print:
```
Tech Lead did not produce [missing file]. Cannot proceed to review.
Re-spawn Tech Lead with the same inputs and explicit instruction to produce both files.
```
Re-spawn Tech Lead, wait for both files, then re-validate before continuing.

### Engineering Design Doc Review

After Tech Lead completes:

1. Read `.velo/tasks/<slug>/prd.md` — you will pass the contents inline
2. Read `.velo/tasks/<slug>/engineering-design-doc.md` — you will pass the contents inline
3. Spawn **both reviewers in parallel**:
   - Read `agents/distinguished-engineer.md` → spawn Distinguished Engineer with both file contents embedded directly in the prompt (do not ask it to read files — provide contents inline)
   - Read `agents/gpt-reviewer.md` → spawn External Distinguished Engineer with the task folder path only — it reads files itself before calling Codex CLI

Wait for both to return. Track cycle count starting at 1.

- If **both** return **APPROVE** → proceed to the approval gate.
- If **either** returns **REVISE** and cycle < 3 → collect all critique from both reviewers. Spawn Tech Lead with combined feedback and what was already attempted in previous cycles. Wait for revised `engineering-design-doc.md` and `task-breakdown.md`. Re-validate both files exist. Increment cycle count and re-run both reviewers in parallel.
- If **either** returns **REVISE** and cycle == 3 → stop. Use **AskUserQuestion** to surface:
  - **Header**: "EDD review cap reached"
  - **Question**: "3 EDD review cycles completed. The following issues remain unresolved: [list each unresolved finding with reviewer and severity]. How do you want to proceed?"
  - **Options**:
    - "1 — Continue revision (extend cap)"
    - "2 — Accept as-is and proceed to approval gate"
    - "3 — Abandon"

### Engineering Design Doc Approval Gate

Read `.velo/tasks/<slug>/task-breakdown.md` before presenting.

Use **AskUserQuestion** to present the engineering design doc and task breakdown for approval:
- **Header**: "Engineering Design Doc Review"
- **Question**: "The engineering design doc passed review. Summary: [list key endpoints and top 3 decisions]. Task breakdown: [list tasks in order with owners]. Ready to proceed to build?"
- **Options**:
  - "1 — Approved, proceed to build"
  - "2 — I have changes"

If the user has changes: convey them to the Tech Lead for revision, re-run both reviewers in parallel, then re-present.

**Do not proceed to build until both the engineering design doc and task breakdown are explicitly approved.**

## Step 4 — Phase 2: Build

Read the task breakdown to determine execution order and parallelism:
- Read `.velo/tasks/<slug>/task-breakdown.md`
- Read `.velo/tasks/<slug>/prd.md`
- Read `.velo/tasks/<slug>/engineering-design-doc.md`

Execute tasks in the order defined by `task-breakdown.md`. Tasks with no dependencies run in parallel. Tasks with dependencies run only after their dependencies complete.

Each builder receives (all embedded directly in the prompt — do not ask them to read files):
- The task folder path: `.velo/tasks/<slug>/`
- Their specific task from `task-breakdown.md` inline
- The full contents of `prd.md` inline
- The full contents of `engineering-design-doc.md` inline
- Context on what completed tasks have delivered (if relevant)

## Step 5 — Phase 4: Review

Before spawning reviewers, read both planning artifacts so you can pass contents inline:
- Read `.velo/tasks/<slug>/prd.md`
- Read `.velo/tasks/<slug>/engineering-design-doc.md`

After all builders are done, spawn ALL relevant reviewers **in parallel**. Each reviewer receives (embedded directly in the prompt — do not ask them to read files):
- The full contents of `prd.md` and `engineering-design-doc.md` inline
- Their specific domain scope (what files/changes to review)
- **If BE engineer was involved**: always spawn the observability-engineer and security-engineer alongside the be-reviewer — same BE changes, different lenses
- **If FE engineer was involved**: always spawn the security-engineer alongside the fe-reviewer — reviews for XSS, sensitive data exposure, insecure token storage

**Rework loop**: After all reviewers return, check verdicts. Track cycle count starting at 1. Maintain a running list of unresolved findings across cycles.

- If **all pass** → proceed to Learning extraction.
- If **any fail** and cycle < 3:
  - Collect findings from failing reviewers. Classify by severity: Critical / Significant / Minor.
  - **Cycle 1**: builders fix all Critical + Significant issues.
  - **Cycle 2**: builders fix remaining Critical issues only — skip Significant if already attempted.
  - Pass builders: the unresolved findings inline + what was attempted in previous cycles + full `prd.md` and `engineering-design-doc.md` inline.
  - Re-spawn only the failing reviewers with instruction: "Re-check only the previously flagged issues — do not perform a full re-review."
  - Increment cycle count and repeat.
- If **any fail** and cycle == 3 → stop. Use **AskUserQuestion** to surface:
  - **Header**: "Rework cap reached"
  - **Question**: "3 rework cycles completed. The following issues remain unresolved: [list each unresolved finding with reviewer and severity]. How do you want to proceed?"
  - **Options**:
    - "1 — Continue rework (extend cap)"
    - "2 — Accept as-is and proceed to commit"
    - "3 — Abandon — do not commit"

**Learning extraction** (only if rework cycles > 1): Read `agents/learnings-agent.md` and spawn the learnings agent with all reviewer findings, builder fix summaries, and existing `.velo/learnings/<domain>.md` contents inline (read each relevant file first; pass empty string if file doesn't exist yet). Present proposed additions to the user via AskUserQuestion for approval. On approval, append entries to `.velo/learnings/<domain>.md` in the repo (create file if needed). On reject, discard.

### Approval Gate

Use **AskUserQuestion** to present the review results before committing:
- **Header**: "Ready to ship"
- **Question**: "All reviewers passed. [Summary of what was built and review cycles taken.] Approve commit?"
- **Options**:
  - "1 — Approved, commit"
  - "2 — Hold, I have feedback"

If the user has feedback: treat it as rework input — spawn the relevant builder(s) with the feedback inline, re-run affected reviewers, then re-present this gate.

**Do not commit until explicitly approved.**

## Step 6 — Phase 5: Commit (only if user asked to ship end-to-end)

Spawn the `commit` agent after approval is received.

## Step 7 — Track token usage

After each subagent returns, note:
- `total_tokens`, `tool_uses`, `duration_ms`
- Approximate cost: `tokens × $27 / 1,000,000` (blended rate: 80% input @ $15/1M + 20% output @ $75/1M, opus pricing)

## Step 8 — Final report

```
Velo — Summary

## Feature
<one-line description>

## Planning
| Agent | Delivered | Tokens | ~Cost | Tools | Time |
|---|---|---|---|---|---|
| Product Manager | <summary> | <tokens> | ~$<cost> | <tool_uses> | <duration> |

## Engineering Design Doc
| Agent | Artifact | Tokens | ~Cost | Tools | Time |
|---|---|---|---|---|---|
| Tech Lead | `engineering-design-doc.md` — <N endpoints, key decisions> + `task-breakdown.md` — <N tasks> | <tokens> | ~$<cost> | <tool_uses> | <duration> |

## What was built
| Agent | Delivered | Tokens | ~Cost | Tools | Time |
|---|---|---|---|---|---|
| DB Engineer | <summary> | <tokens> | ~$<cost> | <tool_uses> | <duration> |
| BE Engineer | <summary> | <tokens> | ~$<cost> | <tool_uses> | <duration> |
| Infra Engineer | <summary> | <tokens> | ~$<cost> | <tool_uses> | <duration> |
| FE Engineer | <summary> | <tokens> | ~$<cost> | <tool_uses> | <duration> |
| Automation Engineer | <summary> | <tokens> | ~$<cost> | <tool_uses> | <duration> |

## Review findings
| Cycle | Reviewer | Verdict | Tokens | Time |
|---|---|---|---|---|
| 1 | FE Reviewer | pass/fail <key issues> | <tokens> | <duration> |
| 1 | BE Reviewer | pass/fail <key issues> | <tokens> | <duration> |

## Commit
| Agent | Commit | Tokens | Time |
|---|---|---|---|
| Commit Agent | <commit hash + message> | <tokens> | <duration> |

## Files changed
- <list all files created or modified>

## Cost breakdown
Planners total: <sum> tokens | ~$<cost>
Builders total: <sum> tokens | ~$<cost>
Reviewers total: <sum> tokens | ~$<cost>
Grand total: <sum all> tokens | ~$<total cost> | <tool uses> tool calls | <wall time> elapsed
```

Only include rows for agents actually used.

## Task

$ARGUMENTS

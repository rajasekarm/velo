---
description: Velo — Start new work. Mandates planning before any code is written.
argument-hint: Describe the feature or product idea
---

@PERSONA.md
@ADAPTER.md
@TEAM.md

# Velo — New Work

This command is for **starting new work** — features, products, or capabilities that don't exist yet. Planning is **mandatory** before any code is written.

---

## Step 0 — Preflight

- Verify the active runtime supports `spawn-agent`. The workflow below delegates every unit of work; without delegation it cannot proceed.
- If `spawn-agent` is unavailable, refuse to start. Print: `/velo:new requires spawn-agent capability, which is not available in the current runtime. Alternatives that may still work: /velo:hunt (debug loop — no delegation) or /velo:yo in Direct mode (concept questions answered without panel spawning).`
- Do not role-play agents as a fallback. `ADAPTER.md` forbids that.
- If `spawn-agent` is available, proceed to Step 1.

## Step 1 — Understand the request and announce your plan

Before announcing, produce two things: a **plan** (which agents, in what order) and an **assumptions ledger** (every term in the request you had to interpret).

Apply the [Requirement Interpretation](skills/requirement-interpretation.md) rule to every term in the request whose interpretation could change which user sees what, which code path runs, or which data gets touched. Resolve each term per the rule, then record it in the Assumptions ledger.

Scope note: "Skip clarifying questions" mode (when the user has opted out of mid-flow questions) applies to workflow friction — preferences, naming, ordering. It does NOT authorize silent guesses on requirement semantics. Requirement-semantic ambiguities still go in the Assumptions ledger; stop-and-ask still fires when an unsurfaced interpretation could change user-visible behavior.

Print this:

```
Velo here. Starting new work...

Feature: <one-line summary of what's being built>
Task folder: .velo/tasks/<task-slug>/

Assumptions (flag if wrong):
- <term from request> → <interpretation/signal>
- (write "(none)" only if every term in the request resolves to exactly one obvious signal)

Plan:
- Product Manager: <what they'll explore/decide>
- Tech Lead: <reads PRD + codebase, writes engineering design doc, gets approval>
- DB Engineer: <schema changes> (after engineering design doc approved, if needed)
- BE Engineer: <endpoints to implement> (after DB)
- Infra Engineer: <infrastructure changes> (if needed, parallel with BE)
- FE Engineer: <UI to build against engineering design doc> (parallel with backend)
- ...

Execution: PM → Tech Lead (approval gate) → Build (backend stream + FE stream in parallel) → Spec Check → Review
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
   - Explicit instruction to run the **full** product context retrieval flow (Step 0 of the PM Workflow): list `.velo/products/`, match the brief, read the matching `context.md` if found; if ambiguous ask the user to pick; if no match ask the user for a slug before creating, and at session end append decisions and write `product.txt` into the task folder
   - Explicit instruction that `prd.md` MUST open with an `## Assumptions (flag if wrong)` section. Apply the [Requirement Interpretation](skills/requirement-interpretation.md) rule to every term from the brief whose interpretation could change which user sees what, which code path runs, or which data gets touched — each entry as `<term> → <interpretation/signal>`. Write `(none)` only if every term in the brief resolves to exactly one obvious signal. Pass through any assumptions Velo already flagged in the announcement. If the PM revises or rejects any assumption Velo flagged in the announcement, the PRD's Assumptions section is authoritative — note the divergence in that section. Velo's announcement Assumptions are superseded by the PRD's on conflict.
3. Their output: user stories, requirements, scope decisions, open questions resolved — written to `.velo/tasks/<slug>/prd.md` (with the Assumptions section at the top); also `.velo/tasks/<slug>/product.txt` with the resolved product slug

**Do not proceed until `prd.md` is written.**

### PRD Approval Gate

Use `ask-options` to present the PRD for approval:
- **Header**: "PRD Review"
- **Question**: "I've written the PRD at `.velo/tasks/<slug>/prd.md`. Here's a summary: [2–3 bullet summary of goals, user stories, and scope]. Assumptions: [the PRD's Assumptions list, or '(none)']. Ready to proceed to engineering design doc?"
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
   - Explicit instruction that `engineering-design-doc.md` MUST include an `## Assumptions (flag if wrong)` section. Apply the [Requirement Interpretation](skills/requirement-interpretation.md) rule to every technical interpretation made when translating the PRD into design — terms whose meaning could change which code path runs, which data gets touched, or which contract the team commits to. Each entry as `<term> → <interpretation/signal>`. Write `(none)` only if every term resolves to exactly one obvious signal. If the EDD discovers a PRD assumption is wrong (e.g. the technical reality contradicts a product-level interpretation), STOP and notify Velo before continuing — the PRD must be revised first. Do not silently override PRD assumptions in the EDD.
4. Their output: `.velo/tasks/<slug>/engineering-design-doc.md` (with the Assumptions section included) and `.velo/tasks/<slug>/task-breakdown.md`

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
   - Read `agents/gpt-reviewer.md` → spawn External Distinguished Engineer with the task folder path only — it reads files itself before using `run-external-review`

Wait for both to return. Track cycle count starting at 1.

- If **both** return **APPROVE** → proceed to the approval gate.
- If **either** returns **REVISE** and cycle < 3 → collect all critique from both reviewers. Spawn Tech Lead with combined feedback and what was already attempted in previous cycles. Wait for revised `engineering-design-doc.md` and `task-breakdown.md`. Re-validate both files exist. Increment cycle count and re-run both reviewers in parallel.
- If **either** returns **REVISE** and cycle == 3 → stop. Use `ask-options` to surface:
  - **Header**: "EDD review cap reached"
  - **Question**: "3 EDD review cycles completed. The following issues remain unresolved: [list each unresolved finding with reviewer and severity]. How do you want to proceed?"
  - **Options**:
    - "1 — Continue revision (extend cap)"
    - "2 — Accept as-is and proceed to approval gate"
    - "3 — Abandon"

### Engineering Design Doc Approval Gate

Read `.velo/tasks/<slug>/task-breakdown.md` before presenting.

Use `ask-options` to present the engineering design doc and task breakdown for approval:
- **Header**: "Engineering Design Doc Review"
- **Question**: "The engineering design doc passed review. Summary: [list key endpoints and top 3 decisions]. Assumptions: [the EDD's Assumptions list, or '(none)']. Task breakdown: [list tasks in order with owners]. Ready to proceed to build?"
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

## Step 5 — Phase 3: Spec Check

After all builders finish, before spawning any reviewers, run the spec checker.

1. Read `agents/spec-checker.md`
2. Spawn the spec-checker with the task folder path (`.velo/tasks/<slug>/`) as its argument

The spec-checker reads `prd.md`, the engineering design doc, and the full diff, then classifies every acceptance criterion as Met / Partially Met / Unmet / Cannot Determine / PRD Ambiguous.

**If verdict is FAIL**: collect the `## Rework guidance` section from the spec-checker output. Send each Unmet or Partially Met criterion back to the responsible builder(s) with the criterion text and file evidence inline. Wait for builders to finish rework, then re-run the spec-checker.

The rework loop is capped at 2 automatic cycles:
- **Cycle 1**: Standard rework — fix all Unmet and Partially Met criteria.
- **Cycle 2**: Rework with explicit note to builders that this is the final automatic cycle. Same scope as cycle 1.
- **Cycle 3 (escalation)**: Pause and surface the remaining gap to the user. Present the failing criteria, what the builders have already attempted, and offer three options:
  1. **Extend** — run another rework cycle (and another, until the user calls it).
  2. **Accept-with-FYI** — proceed to Review phase; remaining unmet criteria become FYI items the human reviewer must verify at merge time.
  3. **Abandon** — stop the workflow; no review, no commit.

**If verdict is BLOCKED** (PRD ambiguity): spec-checker has flagged that one or more criteria are unclear in the PRD itself, not the diff. Do not send to builders. Read the spec-checker's `## PRD ambiguity` section, then spawn the Product Manager (`agents/product-manager.md`) with the ambiguous criteria inline as the task: "Resolve the following PRD ambiguities and update `prd.md`." After PM updates the PRD, re-run the spec-checker. Repeat until verdict is PASS or FAIL (BLOCKED loops back to PM, never to builders).

**If verdict is PASS**: proceed to Review phase.

Do not spawn any reviewer until spec-checker returns PASS.

## Step 6 — Phase 4: Review

Before spawning reviewers, read both planning artifacts so you can pass contents inline:
- Read `.velo/tasks/<slug>/prd.md`
- Read `.velo/tasks/<slug>/engineering-design-doc.md`

After all builders are done, spawn ALL relevant reviewers **in parallel**. Each reviewer receives (embedded directly in the prompt — do not ask them to read files):
- The full contents of `prd.md` and `engineering-design-doc.md` inline
- Their specific domain scope (what files/changes to review)
- **If BE engineer was involved**: always spawn the observability-engineer and security-engineer alongside the be-reviewer — same BE changes, different lenses
- **If FE engineer was involved**: always spawn the security-engineer alongside the fe-reviewer — reviews for XSS, sensitive data exposure, insecure token storage

**Rework loop**: After all reviewers return, check verdicts. Track cycle count starting at 1. Maintain a running list of unresolved findings across cycles.

- If **all pass** → proceed to Approval Gate.
- If **any fail** and cycle < 3:
  - Collect findings from failing reviewers. Classify by severity: Critical / Significant / Minor.
  - **Cycle 1**: builders fix all Critical + Significant issues.
  - **Cycle 2**: builders fix remaining Critical issues only — skip Significant if already attempted.
  - Pass builders: the unresolved findings inline + what was attempted in previous cycles + full `prd.md` and `engineering-design-doc.md` inline.
  - Re-spawn only the failing reviewers with instruction: "Re-check only the previously flagged issues — do not perform a full re-review."
  - Increment cycle count and repeat.
- If **any fail** and cycle == 3 → stop. Use `ask-options` to surface:
  - **Header**: "Rework cap reached"
  - **Question**: "3 rework cycles completed. The following issues remain unresolved: [list each unresolved finding with reviewer and severity]. How do you want to proceed?"
  - **Options**:
    - "1 — Continue rework (extend cap)"
    - "2 — Accept as-is and proceed to commit"
    - "3 — Abandon — do not commit"

### Approval Gate

Use `ask-options` to present the review results before committing:
- **Header**: "Ready to ship"
- **Question**: "All reviewers passed. [Summary of what was built and review cycles taken.] Approve commit?"
- **Options**:
  - "1 — Approved, commit"
  - "2 — Hold, I have feedback"

If the user has feedback: treat it as rework input — spawn the relevant builder(s) with the feedback inline, re-run affected reviewers, then re-present this gate.

**Do not commit until explicitly approved.**

## Step 7 — Phase 5: Commit (only if user asked to ship end-to-end)

Spawn the `commit` agent after approval is received.

## Step 8 — Track token usage

After each subagent returns, note:
- `total_tokens`, `tool_uses`, `duration_ms`
- Approximate cost through `report-cost`

## Step 9 — Final report

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

## Spec Check
| Cycle | Verdict | Criteria Met | Tokens | Time |
|---|---|---|---|---|
| 1 | pass/fail | <N>/<total> | <tokens> | <duration> |

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

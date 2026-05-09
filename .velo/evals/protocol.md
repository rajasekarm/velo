# Run Protocol

## Purpose

The protocol enforces consistency across runs so scores are comparable. Every run captures the same artifacts in the same shape, uses the same baseline reset between attempts, and applies the same rubric. Without this, two runs of the same task aren't measuring the same thing and the scores can't be compared.

## Run lifecycle

1. Pick a task from `tasks/`.
2. Open a fresh Claude Code session at the velo repo root.
3. Apply the task's `Setup` instructions (e.g. plant the typo for T1).
4. Run the command in the task file with the exact prompt — verbatim, no paraphrasing.
5. Capture the run artifacts (see "What to capture" below).
6. Hand-score against `rubric.md`.
7. Save to `runs/run-NNN/T<n>-attempt-<m>.md`.
8. Reset working tree before the next attempt.

## Run filename convention

Runs are stored at `runs/run-NNN/T<n>-attempt-<m>.md`.

- **Run number** (`NNN`) is monotonic across the whole harness: `run-001`, `run-002`, `run-003`, … Bump it any time you start a new evaluation pass over the task suite.
- **Task number** (`<n>`) is `1`–`5`, matching the task file in `tasks/`.
- **Attempt number** (`<m>`) is per task per run: `1`, `2`, `3` for the standard 3-attempt protocol per task per run.

Example: `runs/run-001/T1-attempt-2.md` is the second attempt at T1 inside the first evaluation run.

Each `runs/run-NNN/` folder records its baseline commit SHA at the top so attempts can be reset to a clean and consistent starting point.

## What to capture

- Command invoked (`/velo:task` or `/velo:new`)
- Prompt verbatim
- Agents spawned: count, names, total tokens per agent
- Wall time (start → end)
- Total cost (USD estimate)
- Final git diff (or `git diff <baseline>..HEAD` if shipped)
- Final commit hash if shipped, otherwise "no commit"
- Spec-checker verdict if applicable (PASS / FAIL / BLOCKED)
- Any escalations or user prompts that fired
- Free-text observations: anything surprising, anything wrong

## Reset between attempts

> Before each attempt: `git stash` any unrelated work, then `git reset --hard <baseline-commit>`. The baseline-commit is recorded at the top of each `run-NNN/` folder. For T2, also delete `skills/redis.md` if it was created in a prior attempt.

## Scoring rules

- Phase 1 has one scorer (the user).
- Score immediately after the run while context is fresh.
- If a dimension is genuinely ambiguous, document the uncertainty as a free-text note on the run file. Do not invent half-scores — pick the closer anchor.
- Inter-rater agreement is out of scope until Phase 2.

## Run file template

Copy this into `runs/run-NNN/T<n>-attempt-<m>.md` and fill it in:

```markdown
# Run NNN — T<n> — Attempt <m>

**Task:** [link to task file]
**Date:** YYYY-MM-DD
**Baseline commit:** <sha>

## Capture

- Command: `/velo:...`
- Prompt: `<verbatim>`
- Agents spawned: <count> — <names>
- Total tokens: <n>
- Total cost: ~$<n>
- Wall time: <duration>
- Final diff: <summary or path>
- Commit hash: <sha or "no commit">
- Spec-checker verdict: <PASS / FAIL / BLOCKED / N/A>
- Escalations / user prompts: <list or "none">

## Scores

| Dimension | Score | Note |
|---|---|---|
| Outcome correctness | 0/1/2 | |
| Scope discipline | 0/1/2 | |
| Agent efficiency | 0/1/2 | |
| Cycle discipline | 0/1/2 | |
| Workflow adherence | 0/1/2 | |

**Total: N / 10**
**Cost (numeric, no score): <tokens> / ~$<cost> / <wall time>**
**T5-specific (if applicable): pass / fail**

## Observations

<free-text notes — anything surprising, anything wrong, anything to track>
```

The maximum score is **10** across the 5 scored dimensions (each 0–2). Cost is numeric — tracked, not scored. T5-specific is pass/fail and lives outside the 10-point total. Total is the sum of the 5 scored dimensions.

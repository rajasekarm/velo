# Rubric

Seven dimensions. Five score 0–2 numerically. One (Cost) is numeric and not scored. One (T5-specific) is pass/fail and only applies to T5.

## 1. Outcome correctness (0/1/2)

- **0** — Wrong, broken, or did not ship the requested change.
- **1** — Mostly right with caveats: the change is in the right place but has gaps, errors, or partial coverage.
- **2** — Exactly right: the change matches the brief, is correct, and is complete.

## 2. Scope discipline (0/1/2)

- **0** — Touched files unrelated to the brief; introduced unrequested refactors or "improvements".
- **1** — Minor drift: edited one or two adjacent files that were arguably related but not asked for.
- **2** — Scoped exactly to the brief; no extra files touched.

## 3. Agent efficiency (0/1/2)

- **0** — Wasteful spawning: ran spec-checker for a typo, or spun up the full review chain for a 1-line edit, or invoked PM/TL when the task was trivial.
- **1** — One or two unnecessary spawns; mostly proportional but with avoidable overhead.
- **2** — Lean: only the agents the task actually required.

## 4. Cycle discipline (0/1/2)

- **0** — 3 or more rework cycles, or escalation triggered.
- **1** — Exactly 2 cycles (one rework round).
- **2** — Clean first pass: 1 cycle, no rework.

## 5. Cost (numeric — no score)

Record total tokens and wall time. Used for trend analysis across runs, not for scoring. Document any anomaly (e.g. 10x typical cost).

## 6. Workflow adherence (0/1/2)

- **0** — Skipped a mandatory gate (e.g. EDD review on `/velo:new`, spec-checker on a multi-file change, user-approval gate before commit).
- **1** — Minor deviation: a gate fired but in the wrong order, or a step was abbreviated.
- **2** — Followed protocol end-to-end as defined in `commands/new.md` or `commands/task.md`.

## 7. T5-specific — Ambiguity catch (pass/fail, T5 only)

- **Pass** — PM or spec-checker raised the ambiguity ("faster than what?") before any code shipped. Surfacing the ambiguity to the user and pausing counts as pass.
- **Fail** — The team executed the ambiguous brief and produced output without surfacing the ambiguity.

## Scoring summary

> Maximum score per run: **10 points** (5 dimensions × 2 max — outcome, scope, agent efficiency, cycle, workflow). Cost is recorded numerically, not scored. T5-specific is pass/fail and not part of the 10. Per-task scoring details live in each `tasks/T<n>.md` file's "Scoring notes" section.

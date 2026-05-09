# Velo Evaluation Harness — Phase 1

This directory holds the Phase 1 evaluation harness for Velo. It is a **manual** harness: the user runs each task by hand, captures the run artifacts in a markdown file, and hand-scores the result against a fixed rubric. There is no automation, no LLM judge, and no CI integration in this phase.

The user is the sole runner and sole scorer for Phase 1.

## Where things live

- [protocol](protocol.md) — how to execute and capture each run, including the run-file template.
- [rubric](rubric.md) — the scoring dimensions and anchors.
- [tasks/](tasks/) — the 5 task definitions (T1–T5). Each file pins down the exact command, prompt, setup, expected behavior, and anti-patterns.
- `runs/` — captured run artifacts land here as `runs/run-NNN/T<n>-attempt-<m>.md`. Out of scope to populate as part of bootstrap; runs accumulate over time.

## Phases

Phase 1 (current scope) is manual hand-scoring only. Later phases — semi-automated capture, LLM-as-judge scoring, and continuous evaluation in CI — are explicitly **out of scope** until Phase 1 has produced enough hand-scored runs to calibrate against.

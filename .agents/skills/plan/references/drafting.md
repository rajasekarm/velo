# Drafting a Velo plan

Read when locating, drafting, revising, or presenting a plan. Before creating or rewriting a plan file or index, read [plan-format.md](plan-format.md). Before editing a frozen plan or paused Run, also read [approval.md](approval.md). These guides inherit the Plan entrypoint’s boundaries.

## Locate or create the plan file

**Slug**: derive it from the work's name — lowercase, spaces and special characters replaced with hyphens, trimmed.

**Re-open beats duplicate**: if the request unambiguously references an existing plan — an explicit `.velo/tasks/<slug>/` path, the slug itself, or a request that maps to exactly one row in `.velo/tasks/index.md` — re-open that plan file and revise it under the rules in [approval.md](approval.md) instead of duplicating it. If the reference is ambiguous between several rows, ask which one. Re-open applies only to a plan file Plan owns: one that carries a `Plan-version:` header key and whose `Phase:` still reads `PLAN`. A plan file Run has paused — one whose `Phase:` reads `RUN (Run — M<i> paused: …)` — is also re-openable, and a revision to it always takes the materiality judgment in [approval.md](approval.md), since a paused run necessarily carries a standing approval. When the plan file carries Run's marks, the revision preserves them verbatim: task-line `Status:` values on lines the new version keeps, `Rework cycles:`, `Last gate passed:`, and Run's event bullets; the rules in [plan-format.md](plan-format.md) describe Plan-authored values, not Run's progress marks. A reference to an executed, done, or otherwise non-Plan file is new work — plan it under a suffixed slug and say why in one line; never rewrite that plan file.

**Collision**: if `.velo/tasks/<slug>/` already exists but the request is genuinely new work, suffix the slug `-2`, `-3`, … rather than overwrite.

**Scaffolding**: if `.velo/tasks/` or `.velo/tasks/index.md` is missing, create it on first use — the index starts as the header block shown in [plan-format.md](plan-format.md#the-index).

## Clarify only what changes the plan

Optional, and short. Ask before writing only when a load-bearing choice — something that would change the plan's deliverables, affected surface, or ordering — is genuinely undecidable from the original request, the conversation, and what the repository shows. Everything else becomes an assumption bullet in the plan file, marked for the user to flag rather than asked up front. Answers already given in the conversation are folded in silently, not re-asked.

## Draft or revise the plan

Write the plan into the plan file per [plan-format.md](plan-format.md), including its Architecture section. Use a task-specific Mermaid diagram when the design benefits from one or the user requests it; otherwise state briefly why it is not needed. Define acceptance criteria and verification setup per that guide; map each criterion to its tasks and owning milestone. Three cases:

- **New work**: create `.velo/tasks/<slug>/`, write `task-breakdown.md` at `Plan-version: 1` with `Approval: —`, and insert the task's row in `.velo/tasks/index.md` (status `planning`).
- **Re-opened, unapproved**: fold the requested changes in and rewrite the current version in place — no version bump, `Updated:` advances.
- **Re-opened, approved**: judge materiality first, per [approval.md](approval.md#versioning-and-approval). A material change bumps to v<N+1>, clears `Approval:` to `—`, appends the bump event bullet, and flips the index row back to `planning` before the revision lands. A non-material (wording-only) edit lands in place; the version and the approval stand.

## Present the plan

Present in the conversation as plain markdown — a readable summary, never a dump of the whole file:

- the one-line summary, and — when revising — what changed since the last presentation
- the assumptions worth the user's eyes, as `<term> → <interpretation>` lines
- acceptance criteria, their task coverage, and any verification setup assumptions
- the architecture diagram, when included, with a short explanation of the proposed design
- each milestone with its task lines, rendered exactly as they stand in the plan file
- one plain line on ordering, from the `Execution:` lines (e.g. "T1 and T2 start together; T3 waits on T1")
- the plan file path and the current `Plan-version:`
- one line noting that the `<agent>` and `skills:` fields are advisory labels for Run — nothing in a task line auto-executes anything

After presenting, read [approval.md](approval.md) to offer approve and run, revise, or stop and save, explaining the execution handoff.

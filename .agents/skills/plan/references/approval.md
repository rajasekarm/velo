# Plan approval and versioning

Read before offering approval, processing an approval/revision/stop response, or modifying a frozen plan or paused Run. Resolve the intended plan file using [drafting.md](drafting.md#locate-or-create-the-plan-file) if it is not already unambiguous. Before any write, read [plan-format.md](plan-format.md). An approval-only response needs no new draft.

## Offer approval

After presenting, offer exactly three choices and wait:

- **Approve and run** — freeze this version and start Run
- **Revise** — say what to change; Plan folds it in (see [drafting.md](drafting.md#draft-or-revise-the-plan)) and re-presents
- **Stop and save** — keep the plan file on disk, unapproved

Explain before asking that approval freezes this version and starts Run; honor an explicit request to freeze without execution.

Only an explicit affirmative — "approve", "approved", "yes, freeze it", or an equally unambiguous yes — freezes the plan. A compliment, a question, silence, or "looks good, but…" is not approval. Revisions requested here follow [drafting.md](drafting.md#draft-or-revise-the-plan): on an unapproved version (`Approval:` is `—`) they rewrite it in place; on a frozen plan they take the materiality judgment below first. Either way, Plan re-presents per [drafting.md](drafting.md#present-the-plan). When the plan being presented is already frozen and nothing has changed, approval leaves the standing freeze, version, and event log unchanged. Continue only through the workflow’s authorization and resume checks; never restart an active or completed Run.

**On approval — freeze, verify, hand off.** Write the freeze per **Versioning and approval** below. Re-read the plan file and index to verify the version, approval, phase, and index state. Follow [workflow.md](workflow.md#freeze-and-run-handoff), announcing, for example:

> Plan v<N> is frozen and saved at `.velo/tasks/<slug>/task-breakdown.md`. Moving to Run for this approved version.

If the user requested freeze only, announce it is saved and ready for Run, then stop. Do not enter Run if saving or verifying the freeze fails.

**On stop-and-save**: announce the plan file path and that the plan is saved unapproved (`Approval: —`). It can be re-opened any time by invoking Plan with the slug or the work's name.

## Versioning and approval

**`Plan-version:`**

- Starts at 1 for a new plan file.
- Pre-approval revisions — any edit while `Approval:` is `—` — rewrite the current version in place. No bump.
- Explicit approval freezes the current version.
- A **material change after approval** increments to v<N+1>, clears `Approval:` back to `—`, appends a bump event bullet, and requires reapproval before the plan is frozen again. Material means a change to the plan's deliverables or scope, affected surface, risk class, or required evidence. Wording-only edits are non-material: no bump, and on an approved plan they leave the approval standing (`Updated:` still advances). When Plan bumps, it says so in one line and names what made the change material.
- After a bump, `Last gate passed:` keeps its historically true line — the gate it records did happen — for the superseded version, while `Phase:` returns to `PLAN (Plan — v<N+1> awaiting approval)`; the bump event bullet carries the change forward.
- Superseded versions survive as event bullets only — the plan file always holds the current version's full body, never snapshots of old ones.

**`Approval:`**

- `—` until approved; on freeze, exactly: `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>`.
- The approver is the session user — the repository's git user / maintainer — never Velo itself, never an agent. The timestamp is local time (`date`-sourced), `YYYY-MM-DD HH:MM`.
- Only an explicit affirmative user response freezes; nothing is ever auto-approved.

**Event bullets** in `## Constraints/notes`, one line each:

- Freeze: `- v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>`
- Bump: `- v<N+1> · material change: <one clause on what changed> · <YYYY-MM-DD HH:MM> · approval cleared — reapproval required`

Event bullets append at the end of the `## Constraints/notes` section, in chronological order; the first event bullet written replaces a literal `(none)`.

**The freeze writes**, together, in one plan file rewrite: the `Approval:` value, the freeze event bullet, `Phase: PLAN (Plan — v<N> approved)`, `Last gate passed: PLAN_APPROVAL (Plan approval — v<N>)`, `Updated:`, and the index row flipped to `planned`. Then verify and follow [workflow.md](workflow.md#freeze-and-run-handoff), respecting any freeze-only instruction.

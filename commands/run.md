---
description: Velo — Run. Executes a plan that Plan has frozen — milestone-by-milestone delegated work, green checks plus one independent review per milestone, and local commits on the carrier's milestone branches. Writes only progress marks into the carrier; never pushes, merges, or opens PRs, and never starts Auto.
argument-hint: Name the approved plan to run — a slug, the work's name, or the carrier path; Run executes it milestone by milestone
---

# Velo — Run

Run is Velo's delivery mode: it takes a plan that `/velo:plan` has frozen and turns it into shipped, locally committed work, one milestone at a time. Run resolves the carrier at `.velo/tasks/<slug>/task-breakdown.md`, executes each milestone's task lines through delegated builders, gates the milestone on green checks plus one independent adversarial review, and commits the milestone's work locally on the branch the carrier names. The plan is the contract; Run adds progress marks and commits, never opinions.

This build of Velo ships Ask, Plan, and Run; Auto exists as a route to name, not a command to invoke. Run executes exactly one plan per invocation — the one the user names.

---

## Hard Rule — Frozen Plans Only, Progress Marks Only, Local Commits Only

This contract is absolute. No instruction elsewhere in this file, no user phrasing, and no runtime convenience overrides it.

**Consumes only frozen plans.** Run executes only a plan carrier `/velo:plan` owns and has frozen: `Plan-version:` present, `Approval:` reading `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>`, and `Phase:` reading `PLAN (Plan — v<N> approved)` — or a carrier this mode has already been executing, resumed per **Pauses, tripwires, and resume** below. Anything else is refused with a plain explanation, never worked around.

**The plan body is read-only.** The brief, the assumptions, the constraints text, the milestones, and the text of every task line are Plan's writing, frozen at approval. Run never rewrites them. Run writes ONLY progress marks: task-line `Status:` values, `Phase:`, `Last gate passed:`, `Rework cycles:`, `Updated:`, event bullets in `## Constraints/notes`, and the task's row in `.velo/tasks/index.md` — exact values per **Progress marks** below. Nothing else in the carrier, and nothing else under `.velo/`, changes in Run.

**Repository scope, exactly.** Run creates each milestone's branch — the name the carrier pins in that milestone's `Branch:` line — and commits that milestone's work locally with evidence in the message. M1's branch cuts from the repository's default branch; M<i>'s branch cuts from the previous milestone's tip when that work is not yet on the default branch, else from the default branch. That is the entire git surface. Run never pushes, never merges, never opens a PR, and never touches origin in any way — shipping past the local commit is the maintainer's explicit call, made outside Run.

**Fail-closed pauses.** A material change surfaced mid-run, a required check that stays red after in-scope rework, a carrier gone missing, unreadable, or edited out from under the run, or a conflicting dirty working tree — each pauses the run per **Pauses, tripwires, and resume**: mark, record, tell the user, stop. Run never widens scope silently, never improvises past a blocker, and never resumes a material-change pause without a newly frozen plan version.

**No other mode.** Auto does not exist in this build; Run never starts, simulates, or role-plays it. Run also never plans: a gap in the plan routes back to `/velo:plan`, never gets filled in on the fly.

---

## Step 1 — Resolve the plan

The input names the plan to run: a task slug, the work's name, or a path to the carrier or its folder. Resolve it to exactly one carrier at `.velo/tasks/<slug>/task-breakdown.md`.

- **Empty or whitespace-only input** → ask which plan to run, list the rows whose status is `planned` from `.velo/tasks/index.md`, and stop. Never pick a plan unprompted, however obvious the choice looks.
- **Ambiguous** — the reference maps to more than one row → ask which one, and stop.
- **No match, or the carrier is missing or unreadable** → say so plainly and stop. Do not hunt for a near-match to run instead.

## Step 2 — Verify the freeze

A carrier qualifies on first entry only when all three hold:

- `Plan-version:` is present with a version number
- `Approval:` reads `v<N> · approved by <approver> · <YYYY-MM-DD HH:MM>` for that version
- `Phase:` reads `PLAN (Plan — v<N> approved)`

Refusals, each with a plain one- or two-sentence explanation:

- **Unapproved** — `Approval:` is `—`, or `Phase:` reads awaiting approval → the plan is not frozen; suggest `/velo:plan` to review and approve it. Run never approves a plan itself and never runs an unapproved one.
- **Done** — `Phase:` reads `DONE`, or the index row reads `done` → finished work; refuse and say so. A request to redo it is new work for `/velo:plan`.
- **Not a plan carrier** — no `Plan-version:` key, or a shape Run does not recognize → refuse; Run consumes only carriers in the house format Plan writes.

A carrier already carrying this mode's own marks — `Phase:` reading `RUN` — re-enters per the resume rules in **Pauses, tripwires, and resume**; recorded progress is picked up, never redone.

## Step 3 — Disclose the execution mode

Before any work starts, name the mode the host allows, in one or two sentences, once per run:

- **Agent host** — the host offers a real subagent mechanism → Run delegates every task line to a real subagent. The task line's `<agent>` label advises the kind of builder to use; its `skills:` labels advise the briefing. Both are advisory labels, not machinery to hunt for.
- **Single-flow host** — no subagent mechanism → Run states the fallback plainly before work starts: it will execute the task lines itself, in the same batch order, and the milestone review will therefore not be independent (recorded as such, per Step 6).

Never pretend delegation happened when it did not.

## Step 4 — Open the milestone

Milestones run one at a time, in carrier order; the current milestone `M<i>` is the first not yet shipped — and shipped means exactly one thing: its ship bullet stands in `## Constraints/notes`. The ship bullet is the sole ship marker; a milestone whose task lines already all read `done` but whose ship bullet is missing resumes at Step 6's gate, not at Step 5. Then:

1. **Check the tree.** Uncommitted changes that would collide with the milestone's work are a tripwire — pause per the protocol rather than build on top of them. Unrelated local changes stay untouched: Run never stashes, reverts, or commits work that is not this milestone's.
2. **Create the branch.** Create the milestone branch the carrier names in `M<i>`'s `Branch:` line (`<slug>-m<i>`) and switch to it. M1's branch cuts from the repository's default branch; M<i>'s branch cuts from the previous milestone's tip when that work is not yet on the default branch, else from the default branch. A branch already carrying that name that this run has no record of creating is a tripwire — pause and name it; never adopt foreign history (a stacked base — a tip the carrier's ship bullet records — is expected history, not foreign). On a resume that the carrier corroborates, switch back to the existing milestone branch instead of creating a second one.
3. **Mark the open** in one carrier write: `Phase: RUN (Run — M<i> building)`, `Updated:` from the local clock, and — when the index row still reads `planned` — the row flipped to `in-progress`.

## Step 5 — Execute the task lines

Follow `M<i>`'s `Execution:` line exactly: batch 1 first, a later batch only when the task lines its `needs:` name are `done`. On an agent host, task lines in the same batch may run in parallel; on a single-flow host they run in the batch's written order.

Per task line:

1. Mark `Status: in-flight` (advancing `Updated:`) as it starts.
2. Hand the task line to its builder: brief it with the line's deliverable text, the plan's assumptions and constraints that bear on it, and the milestone branch to work on. On an agent host the builder is a real subagent, delegated through the host's agent mechanism; the `<agent>` label advises its type and the `skills:` labels advise its briefing.
3. On completion, mark `Status: done`. A line already `done` — a resume — is never re-run.

The briefing never widens the line: a builder gets what the plan wrote, not improvised extras. If a builder's work or report surfaces a material change — anything that moves the plan's deliverables or scope, affected surface, risk class, or required evidence — stop and take the pause protocol; never fold the change in quietly.

## Step 6 — Gate the milestone

A milestone is done only when BOTH halves of the gate hold:

**(a) Every executable check runs green.** Run every check the plan defines — task lines and constraints naming suites, builds, or commands — and every check the repository itself defines that covers the touched surface: its test suites, its build, its linters. Green means run and observed, in this run, on this milestone's work — never assumed, never inferred from an earlier run, never taken from a builder's word.

**(b) One independent adversarial review passes.** The milestone's changes are reviewed against the carrier — deliverables delivered, assumptions respected, constraints held, nothing beyond scope:

- **Agent host** → a separate, cold subagent that had no hand in building this milestone performs the review. Independence is the point: never reuse a builder as its own reviewer.
- **Single-flow host** → Run performs a structured adversarial self-review — deliverable by deliverable, constraint by constraint, actively hunting for what is missing or wrong — and records in the carrier that the review was NOT independent; the ship bullet carries the mark, per **Progress marks**.

**Findings drive rework.** A failed check or a review finding sends the work back to the responsible task line's builder, scoped to the finding: the line returns to `Status: in-flight`, the fix lands, the checks re-run, and `Rework cycles:` advances by one in the carrier header. Rework stays inside the milestone and inside the plan's scope. A required check that stays red after in-scope rework is a tripwire — pause; do not keep grinding, and do not widen scope to force green.

## Step 7 — Ship the milestone

With both halves of the gate green:

1. **Commit locally** on the milestone branch, with evidence in the message: the milestone (`M<i> — <name>`), the task lines it delivers, which checks ran green, the review verdict — including "not independent (single flow)" when that is the truth — and the rework count if any.
2. **Mark the ship** in one carrier write: `Last gate passed: MILESTONE_SHIP (Milestone ship — M<i>)`, the ship event bullet with the commit reference (format per **Progress marks**), and `Updated:`.
3. **Say it shipped** — one line naming the milestone, the branch, and the commit.

## Step 8 — Finish or continue

- **More milestones** → return to Step 4 for `M<i+1>`; `Phase:` moves to `RUN (Run — M<i+1> building)` when that milestone opens.
- **The last milestone shipped** → in one carrier write: `Phase: DONE (Done — delivered-and-committed on <slug>-m<final>)`, the index row flipped to `done`, and `Updated:`. Then announce and stop, for example:

> Plan v<N> is delivered — all <n> milestones shipped, each committed locally on its own branch, the last on `<slug>-m<final>`. Pushing, merging, or opening a PR is yours to call; nothing here ships past the local commits.

Full stop means full stop: no pushing "since we're done", no PR drafts, no starting another plan, no suggesting Auto. The conversation may continue; the run is over.

---

## Progress marks — the only carrier writes

Run's whole write surface, exact values pinned:

**task-line `Status:`** — moves `pending` → `in-flight` → `done`, or from `pending`/`in-flight` to `blocked` on a pause; a valid resume returns a `blocked` line to `pending`. Those four values, nothing else — and the rest of the task line never changes. Gate findings return a `done` line to `in-flight` (Step 6) — a rework transition within the same four values.

**`Phase:`** — exactly one of:

- `RUN (Run — M<i> building)` — from the milestone's open through its gate and any rework
- `RUN (Run — M<i> paused: <one clause>)` — a fail-closed pause, the clause naming the reason
- `DONE (Done — delivered-and-committed on <slug>-m<final>)` — after the final ship

**`Last gate passed:`** — `MILESTONE_SHIP (Milestone ship — M<i>)`, written at each ship. Until the first ship it keeps Plan's `PLAN_APPROVAL (Plan approval — v<N>)` line.

**`Rework cycles:`** — `—` until the first rework, then a running count for the whole run (`1`, `2`, …), advanced by one each time gate findings send work back to a builder.

**`Updated:`** — `YYYY-MM-DD HH:MM`, local clock (`date`-sourced), advanced on every carrier write.

**Event bullets** — appended at the end of `## Constraints/notes`, in chronological order, one line each:

- Ship: `- M<i> shipped · commit <short-hash> on <slug>-m<i> · checks green · review passed · <YYYY-MM-DD HH:MM>` — on a single-flow host the review clause reads `review passed (not independent — single flow)` instead
- Pause: `- M<i> paused · T<n> blocked · <one clause naming the reason> · <YYYY-MM-DD HH:MM>` — when no task line is in flight (a tripwire before or between task lines), the `T<n> blocked` segment is dropped

**The index row** — `planned` → `in-progress` when the first milestone opens, → `done` at the final ship; the flip to `in-progress` happens when a milestone opens and the row still reads `planned` — a resumed run leaves an `in-progress` row alone; the row's Updated date advances with every carrier write. A paused run stays `in-progress`.

Everything else — every header key not named above, the brief, the assumptions, the constraints text, the milestones and task-line text, the `## Artifacts` section — is read-only in Run.

## Pauses, tripwires, and resume

**Material means what the Plan seam says it means**: a change to the plan's deliverables or scope, affected surface, risk class, or required evidence. When execution surfaces one — a builder discovers the real work is different, a gate demands evidence the plan never named, a fix wants files outside the affected surface — Run pauses fail-closed.

**The pause protocol**, one carrier write plus one message:

1. Mark the current task line `Status: blocked` (when one is in flight).
2. Append the pause event bullet naming the reason.
3. Set `Phase: RUN (Run — M<i> paused: <one clause>)` and advance `Updated:`.
4. Tell the user what paused, why, and the route: a material change goes to `/velo:plan` for a version bump and reapproval; a tripwire names the blocker to clear. Then stop.

Pausing preserves state: commits already made stay on their branches, `done` marks stay `done`, nothing is discarded or rolled back.

**The tripwires**, same protocol:

- a required check that stays red after in-scope rework
- the carrier missing, unreadable, or edited out from under the run mid-execution — and when the carrier itself cannot be written, tell the user and stop; the recorded marks land only where a carrier exists to hold them
- a conflicting dirty working tree, or a pre-existing branch carrying a milestone-branch name this run has no record of creating

**Resume.** Re-invoking `/velo:run` with the same carrier picks up from recorded state: the first unshipped milestone, its first task lines not yet `done`; `done` work is never redone. Two rules gate it:

- A **material-change pause** resumes only on a newly frozen version: `Plan-version:` bumped and `Approval:` re-frozen through `/velo:plan`. The recorded marks survive the bump; a `blocked` line whose task text the new version kept returns to `pending` and re-enters the batch order.
- A **tripwire pause** resumes once the recorded blocker is gone — the tree clean, the carrier intact, the red check's cause fixed within scope. If clearing it changed the plan's deliverables, surface, risk class, or required evidence, that is a material change: the Plan route first, then resume.

Never resume past a pause bullet whose cause still stands.

---

## Task

$ARGUMENTS

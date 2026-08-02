---
description: Velo — Plan work. Unified planning front-end; adaptive depth, produces an executable plan, hands off to /velo:task.
argument-hint: Describe the work to plan
---

@PERSONA.md
@ADAPTER.md
@TEAM.md

# Velo — Plan

Unified planning front-end. Plan mode turns a brief into an approved **plan**, carried in one durable file — `.velo/tasks/<slug>/task-breakdown.md`, the carrier: a confirmed assumptions ledger, optional user stories, an optional engineering design doc and architecture diagram, and a milestone task breakdown with composed skills — then hands the carrier off to `/velo:task` for execution. Plan mode adapts its depth: when the work is net-new or underspecified, the Product Manager frames the ask with user stories first, the Tech Lead authors an engineering design doc, and the Distinguished Engineer reviews the design before it is signed off (heavy path); otherwise it goes straight to the Tech Lead breaking down the work (light path — no PM, no design doc, no design review). The Tech Lead breaks down the work **always**.

Plan mode never builds. Execution is `/velo:task`'s job.

---

## Hard Rule — No Code, Planning Only

**Never write code in plan mode.** Not snippets, not pseudocode, not diffs, not patches, not inline fixes. Plan mode spawns at most two agents — Product Manager and Tech Lead — and every unit of work goes through `spawn-agent`. **Always ask before delegating.** If the user asks Velo to write code, decline (F7) and offer to hand off to `/velo:task`.

This rule applies to every phase, every failure mode, and every branch of the skill.

---

## Hard Rule — Plan Does Not Execute

The output of plan mode is an approved plan in the carrier, never a build. Do not spawn builders, reviewers, or automation agents. Do not "just build it since we're here" — even for a one-task plan. Execution happens in `/velo:task` after the handoff (or later, from the saved plan).

---

## Depth gate — the conditional-PM rule

Evaluated at `VALIDATE`, after all in-place stop-and-asks resolve. Deterministic, first match wins. The output is binary — `heavy | light` — plus the id of the first trigger that fired.

<!-- LOCKSTEP: the three triggers below are copied verbatim from task.md's "Escalate Underspecification UP" hard rule. Do not reword either copy independently — extract into a shared skill in increment 2 (task.md executor rewrite). -->

**Heavy path** (PM frames the ask with user stories first, then the Tech Lead authors an engineering design doc and the Distinguished Engineer reviews it before design sign-off) when ANY of the following holds:

1. The brief **cannot be reduced to a stable assumptions ledger the user will confirm** — i.e. resolving the load-bearing terms requires guesses the user is unlikely to simply correct at the gate, because the design space is still open.
2. **Conflicting requirements that are not resolvable by a single assumption** — two clauses pull in incompatible directions and picking one is a product decision, not an interpretation.
3. The work is **net-new feature scope** rather than a change to existing behavior — there is no existing surface to modify; something new must be designed.

**Otherwise: light path** — straight to `DAG_PHASE`, no PM, no engineering design doc, no design review.

Rules around the gate:

- **Binary, not a dial.** Record `depth ∈ {heavy, light}` and the fired trigger id (`1 | 2 | 3 | —`). The trigger id is printed at kickoff so the call is auditable and correctable.
- **A single ambiguous term is NOT a heavy trigger by itself.** It is an in-place stop-and-ask per [Requirement Interpretation](skills/requirement-interpretation.md) — resolve the ask first, then evaluate the gate with the answer folded in. Only if the answer surfaces trigger 1, 2, or 3 does the heavy path fire.
- **User override beats the gate**, both directions, at the `ANNOUNCE` gate. A depth flip re-renders the kickoff.
- **Late correction is light→heavy only**: if the Tech Lead discovers mid-`DAG_PHASE` that a light-path brief is actually net-new or conflicted, it returns `DEPTH_FLAG` and the flow re-enters `ANNOUNCE` with depth flipped to heavy (which now routes through the design-doc + design-review depth). There is no heavy→light late flip — once stories and a design exist, they only help the breakdown.
- **User adjudicates a DEPTH_FLAG dispute** (mirrors the `Step 0 override: user-adjudicated` pattern at `DESIGN_PHASE`): if the user forces light at the re-entered kickoff after a `DEPTH_FLAG`, that call is final for this run — re-enter `DAG_PHASE` and re-spawn the Tech Lead with the override line `Depth override: user-adjudicated — proceed light; do not re-flag` plus the flag reason inline. The TL proceeds best-effort and must not return `DEPTH_FLAG` again; carry the flag reason into the carrier's `Constraints/notes` as an advisory. This caps the flip at one round — no agent-vs-user ping-pong.

---

## Pairing — reviewer routing (carried, not consumed)

Plan mode classifies pairing once, at `VALIDATE`, and carries the label in the carrier's `Pairing:` header key for `/velo:task`'s reviewer routing. Plan mode itself spawns no reviewers.

<!-- LOCKSTEP: the classification rule below is copied verbatim from task.md's "Pairing — reviewer routing" section. Do not reword either copy independently — extract into a shared skill in increment 2. -->

**Classification rule** (deterministic, evaluate at `VALIDATE`, first match wins):

1. **Product** — brief touches a code path that runs on a user request (any inbound user-facing entry point).
2. **Product** — brief changes a public or cross-team contract (API shape, event schema, queue payload, published interface).
3. **Product** — brief changes an operator-visible surface (alert threshold, dashboard, on-call page, runbook-referenced behavior).
4. **Pure-tech** — brief is confined to dependency bumps, internal-only schema (no contract change), infra config, build tooling, or observability internals (collectors, exporters, retention) with no operator-visible surface change.

**Ambiguous → Product; Product wins ties.** If none of rules 1–4 cleanly applies, OR if rules 1–3 (product) AND rule 4 (pure-tech) both match (e.g. a dep bump that also alters a public API shape), classify as product. Conservative default.

---

## Non-Goals

- Writing or editing source code directly (plan mode never builds)
- Building, reviewing, testing, or shipping (→ `/velo:task` via the handoff)
- The build phase of an EDD-driven flow — plan mode authors and DE-reviews the engineering design doc on the heavy path, then hands the approved design + breakdown to `/velo:task` to build; it never builds against the EDD itself (the build runs in `/velo:task` after handoff)
- Debug investigation (→ `/velo:hunt`)
- Architecture discussions or open-ended design exploration (→ `/velo:discuss`)
- Editing `/velo:task`'s behavior — plan mode freezes the carrier and hands off; the executor owns how it consumes it from there

Routing hint: net-new or underspecified work → plan here (heavy tier: PM → DE-reviewed engineering design doc → design sign-off), then execute in `/velo:task`. Small change you'd rather have task mode plan itself → `/velo:task` directly.

---

## Preconditions

The following must be true before the workflow starts. If any precondition fails, the skill cannot run safely.

1. **Adapter concepts available**: `spawn-agent`, `ask-options`, `handoff-mode`, `read-files`, `report-cost` are all defined and bound in the runtime adapter.
2. **Runtime capability — agent spawning**: the active runtime supports `spawn-agent`. The workflow below delegates the PM and TL work; without delegation it cannot proceed.
3. **TEAM.md present and parseable**: agent roster resolves before state `VALIDATE` begins.
4. **PERSONA + ADAPTER imports loaded**: tone rules and adapter concept names resolve before state `VALIDATE` begins.
5. **Runtime capability — option prompts**: `ask-options` is available; without it, gated transitions cannot solicit user choice.
6. **`.velo/tasks/` writable**: planning artifacts must be persistable.
7. **`.velo/products/` readable**: product context retrieval depends on it.

**Fail-fast**: if any precondition fails, print `Cannot start plan: precondition failed — <name>: <one-line reason>` and halt. If `spawn-agent` is the missing precondition, print: `/velo:plan requires spawn-agent capability, which is not available in the current runtime. Alternatives that may still work: /velo:hunt (debug loop — no delegation) or /velo:yo (concept questions answered directly from knowledge — no agents spawned).` Do not role-play agents as a fallback — `ADAPTER.md` forbids that.

---

## Failure modes and terminal reasons

F-codes that fire from this command are F1, F2, F5, F6, F7, F8 per [Velo Failure Modes](skills/velo-failure-modes.md). **F3 and F4 never fire — plan mode has no build phase.**

**Terminal reasons**: `handed-off-to-task`, `plan-saved-no-handoff`, `cancelled-announce`, `abandoned-prd-review`, `abandoned-design-approval`, `abandoned-plan-approval`, `abandoned-spec-f2`, `abandoned-edd-f2`, `abandoned-user`, `abandoned-f5`, `abandoned-f7`, `preflight-failed`. (F6's options are continue/pause — it has no abandon branch and therefore no terminal reason.)

---

## Workflow

```
VALIDATE → ANNOUNCE → [heavy] PM_PHASE → PRD_REVIEW → DESIGN_PHASE → DESIGN_REVIEW → DESIGN_APPROVAL → DAG_PHASE → PLAN_APPROVAL → HANDOFF → DONE
                    → [light] ──────────────────────────────────────────────────────────────────────→ DAG_PHASE   (+ ABANDON terminal sink)
```

The heavy tier gains a design depth — `DESIGN_PHASE → DESIGN_REVIEW → DESIGN_APPROVAL` — between `PRD_REVIEW` and `DAG_PHASE`: the Tech Lead authors an engineering design doc, the Distinguished Engineer reviews it, and the user signs off on the design before the work is broken down. **The light tier does not pass through any of the design states** — it goes straight from `ANNOUNCE` to `DAG_PHASE`, exactly as before.

**Reading guide**: each state's `Exit conditions` list is the authoritative source for transitions out of that state. There is no separate top-level transition table — when you need to know "where does this go next?", read the `Exit conditions` block on the current state. Any state may additionally be entered via a resume per [Velo Task Status](skills/velo-task-status.md); resume re-entry does not change that state's body or exit conditions.

**Narration**: adopt the narration convention from `commands/task.md` — one short line in Velo's voice per transition, name what's happening in team terms ("PM's framing the ask", "TL's designing it", "design's reviewed, let's sign off"), say the *why* only when it isn't obvious, keep failure narration factual. **Never say state names (`PM_PHASE`, `DESIGN_PHASE`, `DAG_PHASE`) out loud** — in the conversation the steps go by their team names: `VALIDATE` is the "Scope check", `ANNOUNCE` the "Kickoff", `PM_PHASE` the "Product framing", `PRD_REVIEW` the "Framing review", `DESIGN_PHASE` the "Design doc", `DESIGN_REVIEW` the "Design review", `DESIGN_APPROVAL` the "Design sign-off", `DAG_PHASE` the "Work planning", `PLAN_APPROVAL` the "Plan sign-off", `HANDOFF` the "Hand to the builders". Structure uses the technical names; everything the user reads uses the team names.

**The carrier**: per [Velo Task Status](skills/velo-task-status.md) — plain markdown, no engine. One durable file per task, `.velo/tasks/<slug>/task-breakdown.md`, carries the plan, the handoff contract, and the live phase together. Velo creates it as a header-only stub and inserts the task's `.velo/tasks/index.md` row when the task folder is created at `ANNOUNCE`, rewrites the Velo-owned header at EVERY state transition (Phase ID + team name, last gate passed, rework counters, `date`-sourced timestamp), and updates both files at the terminal states. **Ownership seam**: the seam is the first `## M` heading below the `## Artifacts` line. Velo owns everything above that heading; the Tech Lead writes only the milestone body at and below it. No spawned agent ever writes the header region, and no agent writes `index.md`.

---

## State: VALIDATE

**Entry condition**: skill invoked with `$ARGUMENTS` — a direct brief, a pasted `/velo:yo` draft brief or `/velo:hunt` handoff brief, or a re-entry package (see [Re-entry](#re-entry--descope-from-velotask)).

**Precondition check (fail-fast)**: before any other `VALIDATE` behavior, evaluate each item in the Preconditions section in order. If any precondition fails, halt immediately and print a clear error naming the missing precondition. Do not proceed to `ANNOUNCE`.

**Body**:

This is the Scope check step (`VALIDATE`) in team language — anything the user reads calls it that; the identifier stays internal.

**Resume check (per [Velo Task Status](skills/velo-task-status.md))**: if the invocation references an existing task — an explicit `.velo/tasks/<slug>/` path or a brief that maps unambiguously to a row in `.velo/tasks/index.md` — run the skill's resume protocol before fresh interpretation: its detection order first (new carrier / legacy folder / new work — legacy folders are detected, refused, and left untouched, `Start fresh` only), then, on a non-terminal carrier, its gate (`ask-options`: `Resume from <team name>` / `Start fresh`). Resume re-enters the recorded state with the recorded depth, pairing, artifacts, and milestone body; tasks whose `Status` reads `done` are complete and MUST NOT be re-run. A header-only stub is a valid resume target, not a missing carrier. **Carve-out**: a `Re-entry:`-bearing invocation (descope re-entry) is the expected continuation, NOT a resume prompt — reuse its `Task-folder` silently (flip the carrier's `Mode:` back to `plan`) and proceed directly to the delta re-plan per [Re-entry](#re-entry--descope-from-velotask). If the carrier is missing, unparseable, half-written, or terminal, proceed as new work.

Read the request. Apply the [Requirement Interpretation](skills/requirement-interpretation.md) rule to every term in the request whose interpretation could change which user sees what, which code path runs, or which data gets touched. Resolve each term per the rule for later capture in the Assumptions ledger (state `ANNOUNCE`).

**Scope note**: "Skip clarifying questions" mode (when the user has opted out of mid-flow questions) applies to workflow friction — preferences, naming, ordering. It does NOT authorize silent guesses on requirement semantics. Requirement-semantic ambiguities still go in the Assumptions ledger; stop-and-ask still fires when an unsurfaced interpretation could change user-visible behavior.

**Two stop mechanisms — do not conflate them**:

1. **In-place stop-and-ask**: when a term has zero codebase signals OR multiple competing signals, STOP and ask the user before kicking off — resolved in-place, loop within `VALIDATE` on the answer. A single ambiguous term is mechanism 1, never a depth trigger by itself.
2. **The depth gate**: after all in-place asks resolve, evaluate the [Depth gate](#depth-gate--the-conditional-pm-rule) triggers. Unlike task.md's escalation rule, firing does not exit the mode — it selects the heavy path inside it.

**Depth**: record `depth` and the fired trigger id per the gate.

**Pairing classification**: apply the rule in [Pairing — reviewer routing](#pairing--reviewer-routing-carried-not-consumed). Carry the resolved label (`product` | `pure-tech`) forward into the carrier's `Pairing:` key — it is used nowhere inside plan mode.

**Context decay check (per PERSONA)**: if the request maps to an existing product slug, check `.velo/products/<slug>/context.md`. If it is older than 30 days OR predates multiple completed tasks, fire F6.

**Exit conditions**:
- Resume check matches a non-terminal task and user picks `Resume from <team name>` → (user-gate: resume) → re-enter the recorded state per [Velo Task Status](skills/velo-task-status.md)
- Term has zero / multiple competing signals → (stop-and-ask) → ask the user in-place; on the answer, loop within `VALIDATE` (re-evaluate interpretation + depth gate with the answer folded in)
- Preconditions pass, interpretation resolved, depth + pairing resolved → (auto) → `ANNOUNCE`
- Precondition fails → (failure:preconditions) → halt (terminal `preflight-failed`)
- F6 fires → see F6 handling in the failure-mode table
- F7 fires (user asks Velo to write code) → see F7 handling

**Failure modes**: can trigger F6, F7.

---

## State: ANNOUNCE

**Entry condition**: `VALIDATE` resolved depth and pairing.

**Body**:

This is the Kickoff step (`ANNOUNCE`) in team language — the template the user reads is the Kickoff; the identifier stays internal.

**Derive task slug**: from the work's name — lowercase, spaces and special characters replaced with hyphens, trimmed. If `.velo/tasks/<slug>/` already exists (e.g. from an earlier `/velo:plan` run on the same feature), suffix `-2`, `-3`, ... rather than overwrite.

**Create task folder** before spawning any agent:
```
mkdir -p .velo/tasks/<slug>
```

Then create the carrier and the index row per [Velo Task Status](skills/velo-task-status.md). **Two writes happen inside this state — both are deliberate:**

1. **On entry — write the stub.** Create `.velo/tasks/<slug>/task-breakdown.md` as the header-only stub: the header keys (`Planned-via: /velo:plan`, `Task-folder`, `Mode: plan`, `Product: —`, `Depth` + trigger, `Pairing`, `Branch-convention: —`, `Phase: ANNOUNCE (Kickoff)`, `Last gate passed: —`, `Rework cycles`, `Re-entry: —`, `Updated` via `date`, `Summary`), a `## Brief (verbatim)` section holding the user's brief unedited, the PROPOSED assumptions ledger under `## Assumptions (confirmed)` with every entry marked `(pending kickoff approval)`, and the two remaining Velo-owned section headings — `## Constraints/notes` and `## Artifacts`, both holding `—` until the `PLAN_APPROVAL` freeze fills them. No milestone body yet — a stub is a named, valid state, not an error. Insert the task's row into `.velo/tasks/index.md` (status `in-progress`).

   The empty `## Artifacts` heading is not decoration: it is the seam anchor — the seam is the first `## M` heading below the `## Artifacts` line — and the Tech Lead returns a milestone body at `DESIGN_PHASE` (heavy) or `DAG_PHASE` (light), both of which run *before* the freeze. The anchor therefore has to exist from the stub, not from the freeze, or the seam is uncomputable at the moment it is first needed.

2. **On kickoff approval — rewrite it.** Clear the `(pending kickoff approval)` marker on every ledger entry (they are now confirmed) and write `Depth`/`Pairing` final.

Persisting the brief and the proposed ledger at entry is what makes a pre-approval kill survivable: the run resumes from the Kickoff and re-renders from what is on disk. The `VALIDATE` stop-and-ask answers are already folded into those entries, so nothing is lost.

Print the kickoff using the template in [Templates — Kickoff](#kickoff): the depth call **with its trigger id and one-line reason**, the assumptions ledger, and who's doing what (heavy: PM frames the ask, then TL designs it and the DE reviews the design, then TL breaks down the work — light: TL only). Per the PERSONA hard rule "Always ask before delegating", wait for the user.

The user corrects assumptions and can **flip the depth** in either direction at this gate — the user's call overrides the gate. Any flip or correction re-renders the kickoff before any agent is spawned.

**Late correction, light→heavy, on re-entry**: when the kickoff is re-entered after a `DEPTH_FLAG` and the user accepts the flip, flip the header's `Depth` to `heavy (trigger <n>)` and **retain any light-path milestone body the Tech Lead already drafted** — it is never silently discarded. Note the retention in `Constraints/notes` in one line (what the draft was, that it is superseded pending the design depth). The heavy path re-authors the body at `DESIGN_PHASE`, which also produces `architecture.md`.

**Exit conditions**:
- User approves, depth = heavy → (user-gate: approve) → `PM_PHASE`
- User approves, depth = light → (user-gate: approve) → `DAG_PHASE`
- User flips depth OR corrects assumptions → (user-gate: revise) → re-render (loop within `ANNOUNCE`)
- User cancels → (user-gate: cancel) → `ABANDON` (terminal `cancelled-announce`)

**Failure modes**: can trigger F7.

---

## State: PM_PHASE

**Entry condition**: `ANNOUNCE` approved with depth = heavy, or `DAG_PHASE` looped back with spec-quality findings (F8).

**Body**:

This is the Product framing step (`PM_PHASE`) in team language — narrate it that way ("PM's framing the ask"); the identifier stays internal.

1. Read `agents/product-manager.md`.
2. Spawn the Product Manager in **`Mode: prd`** with:
   - The brief (verbatim)
   - The task folder path: `.velo/tasks/<slug>/`
   - Explicit instruction to run the **full** product context retrieval flow (Step 0 of the PM Workflow): list `.velo/products/`, match the brief, read the matching `context.md` if found; if ambiguous ask the user to pick; if no match ask the user for a slug before creating, and at session end append decisions to that product's `context.md`. The PM writes no marker file into the task folder — it **reports the resolved product slug back to Velo** in its return line, and Velo writes it into the carrier.
   - Explicit instruction that `prd.md` MUST open with an `## Assumptions (flag if wrong)` section — each entry as `<term> → <interpretation/signal>`, passing through the assumptions Velo flagged at kickoff. If the PM revises or rejects any assumption Velo flagged, the PRD's Assumptions section is authoritative — note the divergence there (F8 path).
   - On an F8 loop-back from `DAG_PHASE`: the TL's findings list inline, with instruction to revise `prd.md` against them.
3. Output: `.velo/tasks/<slug>/prd.md` (the **User Stories with acceptance criteria** section is the load-bearing artifact for the breakdown) — one file, plus the reported product slug.
4. **On return, Velo writes the `Product:` header key** into the carrier from the slug the PM reported (`—` if the run has no product context). The PM never touches the header region; the transcription is Velo's, like every other header write.

**Do not proceed until `prd.md` is written.**

**Token tracking**: after the PM returns, note `total_tokens`, `tool_uses`, `duration_ms`. Compute approximate cost through `report-cost`.

**Exit conditions**:
- `prd.md` exists → (auto) → `PRD_REVIEW`
- PM revises/rejects a Velo-flagged assumption → (failure:F8, PM variant) → note divergence in PRD; `prd.md` is authoritative; proceed to `PRD_REVIEW`
- Spawn unavailable or fails → (failure:F1) → halt and report blocker
- User aborts → (user-gate: abandon) → `ABANDON` (terminal `abandoned-user`)

**Failure modes**: can trigger F1, F7, F8.

---

## State: PRD_REVIEW

**Entry condition**: `PM_PHASE` produced `prd.md`.

**Body**:

This is the Framing review step (`PRD_REVIEW`) in team language — the gate header below carries that name; the identifier stays internal.

Use `ask-options` to present the framing for approval:
- **Header**: `"Framing review"`
- **Question**: `"PM's framed the ask — stories are at .velo/tasks/<slug>/prd.md. Summary: [2–3 bullets — goals, user stories, scope]. Assumptions: [the PRD's Assumptions list, or '(none)']. Good to hand this to the Tech Lead to design?"`
- **Options**:
  - `Approved, design it`
  - `I have changes`
  - `Abandon`

If the user has changes: convey them to the PM for revision, wait for the updated `prd.md`, then re-present.

**Cycle-cap note**: user-driven revisions are uncapped. F2 applies only to reviewer-driven rework loops (`cap:spec-cycles` at `DESIGN_PHASE`, `cap:edd-cycles` at `DESIGN_REVIEW`); `PRD_REVIEW`, `DESIGN_APPROVAL`, and `PLAN_APPROVAL` allow unlimited user revisions.

**Exit conditions**:
- `Approved, design it` → (user-gate: approve) → `DESIGN_PHASE`
- `I have changes` → (user-gate: revise) → re-spawn PM with changes inline → `PM_PHASE` (revision); on return → `PRD_REVIEW`
- `Abandon` → (user-gate: abandon) → `ABANDON` (terminal `abandoned-prd-review`)

**Failure modes**: can trigger F1, F7.

---

## State: DESIGN_PHASE

**Entry condition**: `PRD_REVIEW` approved (heavy path only — the light path never enters this state).

**Body**:

This is the Design doc step (`DESIGN_PHASE`) in team language — narrate it that way ("TL's designing it"); the identifier stays internal. Lifted from `/velo:new`'s former `TL_PHASE` (retired; see git history): the Tech Lead runs its Step 0 spec-quality-check on the PRD, then authors the engineering design doc and the task breakdown together.

1. Read `agents/tech-lead.md`.
2. Read `.velo/tasks/<slug>/prd.md` — you will pass the contents inline.
3. Spawn the Tech Lead in its **default (new-work) mode** — no `Mode:` line, PRD path + contents provided — with:
   - The task folder path: `.velo/tasks/<slug>/`
   - The full contents of `prd.md` embedded directly in the prompt (do not ask the agent to read it — provide it inline)
   - Instruction to read the existing codebase for conventions and constraints
   - **Explicit reminder to run TL's Step 0 — spec-quality-check** on `prd.md` BEFORE any design work. If the TL returns `STATUS: SPEC_REWORK_NEEDED`, it stops without writing any files and returns the findings list inline. This is the spec-quality F8 variant — see Exit conditions.
   - Explicit instruction that `engineering-design-doc.md` MUST include an `## Assumptions (flag if wrong)` section — each entry as `<term> → <interpretation/signal>`, passing through the assumptions confirmed at kickoff and the PRD. If the design discovers a PRD assumption is wrong (the technical reality contradicts a product-level interpretation), STOP and notify Velo before continuing — the PRD must be revised first. Do not silently override PRD assumptions in the design doc (F8 path).
   - Explicit instruction to author `architecture.md` — a shape diagram of the change, exactly one fenced ` ```mermaid ` block, **strictly inside the constrained allow-list** in [Velo Task Status](skills/velo-task-status.md) (anything not on the list is forbidden: `flowchart TD|LR` only, ≤20 nodes, three node forms, `-->` / `-->|label|` edges one per line, quoting rules, no subgraphs/styling/comments/directives). The EDD references the diagram in one line and never duplicates it. Heavy path only.
   - Explicit instruction on the **ownership seam**: the seam is the first `## M` heading below the `## Artifacts` line, and the Tech Lead writes only the `## M1..Mn` milestone body at and below it — milestone headings, their `Branch:`/`Shipped:` lines, and the task lines. Everything above that heading is Velo's, must be left exactly as found, and task lines are written WITHOUT `skills:` (Velo composes those at the freeze). Milestones are always present — a single-task plan is `## M1` with one task; a zero-task milestone is invalid output.
4. Outputs: `.velo/tasks/<slug>/engineering-design-doc.md` (with Assumptions section), `.velo/tasks/<slug>/architecture.md`, and the milestone body of `.velo/tasks/<slug>/task-breakdown.md`.

**Validate Tech Lead output**: before proceeding, verify all three files exist:
- `.velo/tasks/<slug>/engineering-design-doc.md`
- `.velo/tasks/<slug>/architecture.md`
- `.velo/tasks/<slug>/task-breakdown.md`

If any is missing — **stop**, print a one-line blocker naming the missing file, and re-spawn the Tech Lead with the same inputs and explicit instruction to produce all three. Wait, then re-validate. **A missing `architecture.md` fails exactly like a missing engineering design doc** — same stop, same named blocker, same re-spawn. Never proceed to the design review without a diagram.

Then run the header validation and repair rule in [Velo Task Status](skills/velo-task-status.md): compare the region above the seam — the first `## M` heading below the `## Artifacts` line — against the header Velo last wrote; on mismatch rewrite the header from that authoritative state and note the repair in `Constraints/notes`. Take the last `## Artifacts` line if more than one is present; a carrier with no `## Artifacts` line at all is a damaged Velo region, not a licence to fall back to a top-of-file scan — restore the line from the files actually present in the task folder, then compute the seam. Re-spawn the Tech Lead only if the body is also invalid (no `## M` heading below the anchor, a zero-task milestone, or task lines that cannot be read as task lines) — a clobbered header over a sound body is a repair, not a re-spawn.

**Rework re-entering this state with `architecture.md` already standing**: the Tech Lead must either update the diagram or state "diagram unchanged" in its report — **silence is not a stance**. If the report is silent on the diagram, treat it as incomplete output and ask the TL for the call before advancing. Velo re-embeds the on-disk file at `DESIGN_REVIEW` either way.

**Token tracking**: after the TL returns, note `total_tokens`, `tool_uses`, `duration_ms`. Compute approximate cost through `report-cost`.

**Exit conditions**:
- All three files exist and the header validated (or was repaired) → (auto) → `DESIGN_REVIEW`
- TL returns `STATUS: SPEC_REWORK_NEEDED` from Step 0 spec-quality-check → (failure:F8, spec-quality variant) → increment the `cap:spec-cycles` counter; if cycle < 3, loop back to `PM_PHASE` with findings inline; on PM revision → `PRD_REVIEW` → `DESIGN_PHASE`. No files written this cycle.
- `cap:spec-cycles` reaches 3 → (failure:F2) → F2-spec: `ask-options` with header `"Spec rework cap reached"`, options `Continue (extend cap)` (loop to `PM_PHASE`; counter advances) / `Accept as-is and proceed` (re-spawn the TL in default mode with the override line `Step 0 override: user-adjudicated — skip the audit, proceed to the design doc, treat prior findings as advisories` plus the unresolved findings inline; TL skips Step 0 and produces the design doc + diagram + breakdown best-effort; carry the findings into the carrier's `Constraints/notes`) / `Abandon` → `ABANDON` (terminal `abandoned-spec-f2`)
- TL flagged a PRD assumption wrong → (failure:F8, assumption-divergence variant) → loop back to `PM_PHASE` with the contradiction inline; on PM revision → `PRD_REVIEW` → `DESIGN_PHASE`
- Spawn unavailable or fails → (failure:F1) → halt and report blocker
- User aborts → (user-gate: abandon) → `ABANDON` (terminal `abandoned-user`)

**Failure modes**: can trigger F1, F2 (`cap:spec-cycles` = 3, heavy path only), F7, F8.

---

## State: DESIGN_REVIEW

**Entry condition**: `DESIGN_PHASE` produced `engineering-design-doc.md`, `architecture.md`, and the milestone body of `task-breakdown.md` (heavy path only).

**Body**:

This is the Design review step (`DESIGN_REVIEW`) in team language — narrate it that way ("DE's reviewing the design"); the identifier stays internal. Lifted from `/velo:new`'s former `EDD_REVIEW` (retired; see git history): the Distinguished Engineer reviews the engineering design doc under a ≤3-cycle rework cap.

1. Read `.velo/tasks/<slug>/prd.md` — you will pass the contents inline.
2. Read `.velo/tasks/<slug>/engineering-design-doc.md` — you will pass the contents inline.
3. Read `.velo/tasks/<slug>/architecture.md` — you will pass the contents inline, mermaid fence included, so the DE reviews the shape diagram alongside the prose.
4. Read `agents/distinguished-engineer.md` → spawn the Distinguished Engineer with all three file contents embedded directly in the prompt (do not ask it to read files — provide contents inline).

Wait for the reviewer to return. Track cycle count starting at 1.

**Cycle counter on re-entry**: when `DESIGN_REVIEW` is re-entered from `DESIGN_APPROVAL` (user requested changes), the cycle counter resets to 1. F2-edd's ≥3 cap applies only within a single contiguous review pass.

- If DE returns **APPROVE** → proceed to `DESIGN_APPROVAL`.
- If DE returns **REVISE** and cycle < 3 → collect the critique. Spawn the Tech Lead (default mode) with the feedback inline and what was already attempted in previous cycles. Wait for the revised `engineering-design-doc.md`, `architecture.md`, and milestone body, and for the TL's diagram stance (updated, or "diagram unchanged"). Re-validate all three files exist and the header is intact, per `DESIGN_PHASE`. Increment cycle count, re-read `architecture.md` from disk, and re-run the Distinguished Engineer.
- If DE returns **REVISE** and cycle == 3 → fire F2-edd (per-phase cap == 3 for `DESIGN_REVIEW`).

**Token tracking**: after each subagent returns, note `total_tokens`, `tool_uses`, `duration_ms` and compute approximate cost through `report-cost`.

**Exit conditions**:
- DE returns APPROVE → (auto) → `DESIGN_APPROVAL`
- Cycle < 3 with REVISE → (auto) → loop within `DESIGN_REVIEW` (re-spawn TL + DE)
- `cap:edd-cycles` reaches 3 with REVISE → (failure:F2) → F2-edd: `ask-options` with header `"Design review cap reached"`, options `Continue (extend cap)` (loop within `DESIGN_REVIEW`; counter advances) / `Accept as-is and proceed` (advance to `DESIGN_APPROVAL`; carry the unresolved DE findings into the carrier's `Constraints/notes`) / `Abandon` → `ABANDON` (terminal `abandoned-edd-f2`)
- Spawn unavailable or fails → (failure:F1) → halt and report blocker

**Failure modes**: can trigger F1, F2 (`cap:edd-cycles` = 3, heavy path only), F7.

---

## State: DESIGN_APPROVAL

**Entry condition**: `DESIGN_REVIEW` reported DE APPROVE (or user accepted the F2-edd override).

**Body**:

This is the Design sign-off step (`DESIGN_APPROVAL`) in team language — the gate header below carries that name; the identifier stays internal. The user signs off on the **design** here; the executable plan (DAG + composed skills) gets its own sign-off later at `PLAN_APPROVAL`.

Read `.velo/tasks/<slug>/engineering-design-doc.md` before presenting. Use `ask-options`:
- **Header**: `"Design sign-off"`
- **Question**: `"Design's reviewed and clean — engineering design doc is at .velo/tasks/<slug>/engineering-design-doc.md. Key decisions: [top 3]. Endpoints/interfaces: [short list]. Assumptions: [the EDD's Assumptions list, or '(none)']. Sign off on the design and break it down into a plan?"`
- **Options**:
  - `Approved, break down the work`
  - `I have changes`
  - `Abandon`

If the user has changes: convey them to the Tech Lead for revision, re-run the Distinguished Engineer, then re-present.

**Exit conditions**:
- `Approved, break down the work` → (user-gate: approve) → `DAG_PHASE`
- `I have changes` → (user-gate: revise) → re-spawn TL with changes inline → `DESIGN_PHASE`; on return → `DESIGN_REVIEW`
- `Abandon` → (user-gate: abandon) → `ABANDON` (terminal `abandoned-design-approval`)

**Failure modes**: can trigger F7.

---

## State: DAG_PHASE

**Entry condition**: `DESIGN_APPROVAL` approved the design (heavy), or `ANNOUNCE` approved with depth = light. This state runs on **every** path — the Tech Lead breaks down the work always.

**Body**:

This is the Work planning step (`DAG_PHASE`) in team language — narrate it that way ("TL's breaking down the work"); the identifier stays internal. This is the single convergence point for both tiers: Velo (not the TL) turns the milestone body into the plan-DAG and composes skills here. On the **heavy path** the breakdown was already authored, design-reviewed, and design-approved in the design depth, so this state consumes it directly (no TL re-spawn, no Step 0 — the audit already ran at `DESIGN_PHASE`). On the **light path** the TL is spawned here to author the breakdown fresh.

1. **Obtain the milestone body** — the path depends on the tier:
   - **Heavy path**: the carrier's `## M1..Mn` body already exists — it was authored, design-reviewed, and design-approved in the design depth (`DESIGN_PHASE` → `DESIGN_REVIEW` → `DESIGN_APPROVAL`). Do NOT re-spawn the Tech Lead and do NOT re-run Step 0 — the spec audit already ran at `DESIGN_PHASE` and the design is locked. Just verify the file exists (validation below) and consume it.
   - **Light path**: read `agents/tech-lead.md` and spawn the Tech Lead in **`Mode: plan-dag`** (input variant B — see the mode contract in the agent file) with the task folder path, the original brief, and the **user-confirmed** assumptions ledger, both inline. Step 0 is skipped — the confirmed ledger is the spec; the kickoff gate already did the audit's job. If the TL finds the brief is actually net-new or internally conflicted, it returns `DEPTH_FLAG: <one-line reason>` and writes nothing (unless the spawn carries the `Depth override: user-adjudicated` line — then it proceeds without re-flagging, per the depth-gate rules). Same ownership seam as `DESIGN_PHASE`: the seam is the first `## M` heading below the existing carrier's `## Artifacts` line, the TL writes only the `## M1..Mn` milestone body at and below it, leaves the header region untouched, and writes task lines without `skills:`. Output: the milestone body of `.velo/tasks/<slug>/task-breakdown.md` — **no engineering design doc and no `architecture.md` on the light path**.
2. **Validate output**: verify the carrier has a milestone body — at least one `## M` heading below the `## Artifacts` line, no zero-task milestone. If it is missing — stop, print:
   ```
   task-breakdown.md has no milestone body. Cannot proceed to plan sign-off.
   [heavy] The design depth should have produced it — re-enter DESIGN_PHASE.
   [light] Re-spawn Tech Lead with the same inputs and explicit instruction to produce the milestone body.
   ```
   Recover per tier, wait, re-validate. Then run the header validation and repair rule in [Velo Task Status](skills/velo-task-status.md) — a clobbered header over a sound body is a repair (rewrite it from Velo's authoritative in-session copy, note the repair in `Constraints/notes`), not a re-spawn.
3. **Turn the milestone body into the plan** (Velo does this, not the TL): consume the body exactly as the TL wrote it — the `## M1..Mn` milestones in order, and inside each one its task lines, `- T# · <agent> — <what it does> · needs: <— | earlier ids> · Status: <state>`. Each task line is one node: `T#` is the id, `<agent>` the agent, the text after the em dash is what the node produces, `needs:` carries its dependency edges (possibly reaching into an earlier milestone), and `Status:` is the executor's live state — carry it through verbatim, never rewrite it here (a line already reading `Status: done` is complete work). Node and edge semantics per [Velo Plan DAG](skills/velo-plan-dag.md); the carrier's task-line grammar and the `Status` vocabulary per [Velo Task Status](skills/velo-task-status.md). Batches derive per milestone, never across them, per [Velo Parallelism](skills/velo-parallelism.md). Reviewers are never plan tasks.
4. **Compose skills per task** (Velo does this — orchestrator-composed, never inside an agent) per [Velo Skill Composition](skills/velo-skill-composition.md): default bundle from the owner's agent file via TEAM.md, plus validated additions; drop-and-flag nonexistent slugs; ≤3 additions per task.
5. **Cross-task dependency check (per PERSONA)**: if any task depends on another task's API/schema/interface contract that is not yet locked, fire F5.

**Token tracking**: on the light path, after the TL returns, note `total_tokens`, `tool_uses`, `duration_ms`. Compute approximate cost through `report-cost`.

**Exit conditions**:
- Carrier body valid, header intact, plan built, skills composed → (auto) → `PLAN_APPROVAL`
- TL returns `DEPTH_FLAG: <reason>` (light path only) → (auto) → `ANNOUNCE` with depth flipped to heavy, reason surfaced for the user to confirm; if the user forces light again there, re-enter `DAG_PHASE` with the `Depth override: user-adjudicated` line per the depth-gate rules (TL proceeds without re-flagging; reason carried as an advisory)
- F5 fires → (failure:F5) → see F5 handling; on user halt → `ABANDON` (terminal `abandoned-f5`)
- Spawn unavailable or fails (light path) → (failure:F1) → halt and report blocker
- User aborts → (user-gate: abandon) → `ABANDON` (terminal `abandoned-user`)

**Note**: the spec-quality Step 0 loop (`cap:spec-cycles` / F2-spec) does NOT fire here — on the heavy path it runs at `DESIGN_PHASE`; the light path skips Step 0 entirely.

**Failure modes**: can trigger F1 (light path), F5, F7.

---

## State: PLAN_APPROVAL

**Entry condition**: `DAG_PHASE` produced a valid breakdown, a built plan, and composed skill sets.

**Body**:

This is the Plan sign-off step (`PLAN_APPROVAL`) in team language — the gate header below carries that name; the identifier stays internal.

Render the plan per [Velo Plan DAG](skills/velo-plan-dag.md)'s rendering rules — plain markdown, never a fenced code block: one line per task (`T1 · <agent> — <does> · skills: <slug>, +<addition> · needs: —`), then a plain line on what runs together and what waits on what. The heading is `Plan:` per the skill's canonical heading rule — graph jargon never surfaces to the user. Surface any dropped-skill flags from composition. Use the voiced framing in [Templates — Plan sign-off](#plan-sign-off).

Use `ask-options`:
- **Header**: `"Plan sign-off"`
- **Question**: `"Here's the plan. [pairing call in one clause]. Sign off and hand it to the builders in /velo:task, or adjust?"`
- **Options**:
  - `Approve — hand off to /velo:task`
  - `I have changes`
  - `Save plan — stop here`
  - `Abandon`

**Sign-off is the skill-composition freeze point** per [Velo Skill Composition](skills/velo-skill-composition.md) — the approved task set, ordering, and composed skills are frozen into the carrier. `I have changes` is pre-freeze, user-driven, uncapped; its routing depends on the tier and what changed (see Exit conditions).

**Write the freeze into the carrier**: on either freezing exit (`Approve — hand off to /velo:task` or `Save plan — stop here`), before leaving this state, rewrite `.velo/tasks/<slug>/task-breakdown.md` per [Velo Task Status](skills/velo-task-status.md) with:

- `Constraints/notes` — **fill** the heading the stub already created, replacing its `—`: F5 notes, dropped-skill flags, F2-override advisories, header-repair notes, or `(none)`. Every entry is a `- ` bullet or the literal `(none)` — never a heading; a quoted finding goes inline after the bullet.
- `Artifacts` — **fill** the heading the stub already created, replacing its `—`: whichever of `prd.md`, `engineering-design-doc.md`, `architecture.md` exist (the last two are heavy path only). Do not re-create this heading and never move it below a milestone — it is the seam anchor, and the milestone body it anchors is already on disk by now
- `skills:` on every task line — the composed set, Velo-written into the TL's milestone body
- `Execution:` under each milestone — the batches derived within that milestone

There is no separate plan file: the carrier *is* the durable, executable copy of the approved plan. The `## Brief (verbatim)` section and the confirmed assumptions ledger were already persisted into the stub at `ANNOUNCE` — **do not re-write them here**. The `## Constraints/notes` and `## Artifacts` headings were persisted there too — this step fills them, it does not create them. A saved plan is executed straight from the carrier, and a new-session resume or a descope re-entry reads the confirmed ledger out of it on both tiers.

**Exit conditions**:
- `Approve — hand off to /velo:task` → (user-gate: approve) → `HANDOFF`
- `I have changes`, **light path** → (user-gate: revise) → convey to TL, re-spawn → `DAG_PHASE`; on return → `PLAN_APPROVAL`
- `I have changes`, **heavy path** → (user-gate: revise) → if the change touches the breakdown or the design, re-open the design depth → `DESIGN_PHASE` (TL revises the EDD + breakdown), on return → `DESIGN_REVIEW` → `DESIGN_APPROVAL` → `DAG_PHASE` → `PLAN_APPROVAL`; if the change is only to skill composition or task ordering, Velo re-runs `DAG_PHASE` steps 3–4 in place → `PLAN_APPROVAL` (no TL/DE re-spawn)
- `Save plan — stop here` → (user-gate: save) → `DONE` (terminal `plan-saved-no-handoff`; artifacts persist in `.velo/tasks/<slug>/`, including the executable `task-breakdown.md` frozen at the freeze)
- `Abandon` → (user-gate: abandon) → `ABANDON` (terminal `abandoned-plan-approval`)

**Failure modes**: can trigger F7.

---

## State: HANDOFF

**Entry condition**: `PLAN_APPROVAL` approved the handoff.

**Body**:

This is the Hand to the builders step (`HANDOFF`) in team language — narrate it that way ("handing this to the builders"); the identifier stays internal.

The approved plan was frozen into the carrier, `.velo/tasks/<slug>/task-breakdown.md`, at the `PLAN_APPROVAL` freeze per [Velo Task Status](skills/velo-task-status.md). Invoke `/velo:task` via `handoff-mode`, carrying the full carrier contents — header keys included, verbatim — as the argument (per `ADAPTER.md`: always carry the generated brief forward — the user retypes nothing). **Never strip or summarize the carrier header**: the `Planned-via: /velo:plan` key is what suppresses task mode's escalate-to-plan rule; a stripped header makes a heavy-path brief read as net-new and bounce straight back to `/velo:plan`. `Task-folder:` must travel with it too — it is the anchor task mode reuses instead of deriving a fresh slug and orphaning the plan's folder and index row.

**Transition friction warning (mandatory)**: before invoking, print one line: `Note: /velo:task will re-validate and re-announce this plan with its own gate — approve it there too.`

**Exit conditions**:
- Handoff invoked → `DONE` (terminal `handed-off-to-task`)
- `handoff-mode` unavailable or fails → (failure:F1) → surface the blocker; `ask-options`: `Save plan — stop here` (→ `DONE`, terminal `plan-saved-no-handoff`) / `Abandon` (→ `ABANDON`, terminal `abandoned-user`)

**Failure modes**: can trigger F1.

---

## State: DONE

**Entry condition**: either arrival path:
- `HANDOFF` invoked `/velo:task` (terminal `handed-off-to-task`)
- `PLAN_APPROVAL` or a `HANDOFF` F1 fallback chose `Save plan — stop here` (terminal `plan-saved-no-handoff`)

**Body**:

Print a short plan summary — NOT the [Velo Final Report](skills/velo-final-report.md) table (that is a ship report; plan mode ships nothing): depth taken (+ trigger id), artifacts written (paths — the carrier `task-breakdown.md` always, plus whichever of `prd.md`, `engineering-design-doc.md`, `architecture.md` exist), task count per milestone and what runs in parallel, and — on `plan-saved-no-handoff` — how to execute later (`/velo:task` with the persisted `.velo/tasks/<slug>/task-breakdown.md`, or re-open via `/velo:plan`).

**Carrier stamp — split by terminal reason** (per [Velo Task Status](skills/velo-task-status.md)):
- `plan-saved-no-handoff` → stamp the carrier header `Phase: DONE (Done — plan-saved-no-handoff)`.
- `handed-off-to-task` → do NOT stamp a terminal phase. Leave the carrier header at `Phase: HANDOFF (Hand to the builders)` — the carrier-bearing `/velo:task` invocation must find a live, non-terminal breadcrumb; its first write takes ownership of the folder (flipping `Mode:` to `task`). Stamping `DONE` here would make the executor's reuse-folder path read the task as finished.

The `index.md` row stays `in-progress` on both terminal reasons — the index tracks the work item, which is live until `/velo:task` delivers it — only its Updated date advances. Skill ends.

**Exit conditions**: terminal.

**Failure modes**: none — terminal sink for successful completion.

---

## State: ABANDON

**Entry condition**: any of:
- User selects "Abandon" or "Cancel" at any interaction prompt
- User types "abandon", "stop", or "cancel" mid-flow
- F2-spec cap reached at `DESIGN_PHASE` and user chose "Abandon" (terminal `abandoned-spec-f2`)
- F2-edd cap reached at `DESIGN_REVIEW` and user chose "Abandon" (terminal `abandoned-edd-f2`)
- User chose "Abandon" at `DESIGN_APPROVAL` (terminal `abandoned-design-approval`)
- F5 cross-task dependency surfaced and user chose to halt (terminal `abandoned-f5`)
- F7 fired and user chose "Abandon" at the F7 prompt (terminal `abandoned-f7`)

**Body**:

Print a short abandon summary: state reached (by its team name), artifacts produced (prd.md, engineering-design-doc.md, architecture.md, task-breakdown.md — whichever exist; they persist on disk), what was attempted, what was left. No report file written; if the task folder exists, stamp the carrier header `Phase: ABANDON (Abandoned — <terminal reason>)` and flip the task's `index.md` row to `abandoned` per [Velo Task Status](skills/velo-task-status.md).

**Exit conditions**: terminal. Skill ends.

**Failure modes**: none — terminal sink for failures that route here.

---

## Re-entry — descope from `/velo:task`

**Live**: `/velo:task` fires this path — its descope ritual's `Cut scope` resolution exits task mode via `handoff-mode` under the terminal reason `replanned-via-plan`. Contract details in [Velo Task Status](skills/velo-task-status.md) — the **Descope re-entry** section.

When task mode's descope ritual resolves to a re-plan, it hands back via `handoff-mode` carrying:

```
Re-entry: descope (<F-code>)
Task-folder: .velo/tasks/<slug>/
Finding: <the scope-level finding that triggered the ritual, verbatim>
Descope choice: <what the user said to cut or re-plan>
```

The old `Build state:` list is **superseded**: the carrier's per-task `Status` at `Task-folder` already records what is done and what was in flight, on disk, in the one place both modes read. Never expect it on the payload, and never re-serialize it. Plan mode then:

1. **`VALIDATE`** recognizes the `Re-entry:` header: skip fresh interpretation of the original brief (the carrier's confirmed ledger carries), read the carrier at `Task-folder` for build state, and **re-evaluate the depth gate on the delta only** — the surfaced finding may now trip trigger 1/2/3 and force a heavy re-plan (which routes through the design depth: `DESIGN_PHASE` → `DESIGN_REVIEW` → `DESIGN_APPROVAL` before the DAG).
2. **`ANNOUNCE`** renders the kickoff in re-plan voice: what landed and stays done, what the finding was, how the remainder re-partitions. The named `Task-folder` is reused and its carrier rewritten in place — `Mode:` back to `plan`, `Re-entry: descope (<F-code>)`, `Phase` current. Never suffix-slug it, never abandon it, never start a fresh stub over it.
3. On a heavy re-plan, the design depth revises `engineering-design-doc.md` and `architecture.md` against the surfaced finding before the breakdown; `DAG_PHASE` then re-partitions the remaining work. Tasks whose `Status` reads `done` are preserved verbatim in the re-issued milestone body so the executor never re-runs them.
4. Normal `PLAN_APPROVAL` → `HANDOFF` from there — the freeze rewrites the same carrier; `Re-entry:` clears back to `—` once the re-plan is handed off.

Task mode owns the bounded review/rework loop outright — reviewer findings and builder rework never re-enter plan mode. Only scope-level deviations (the descope-ritual triggers) do.

---

## Templates

### Kickoff

Voiced, not a form — per [PERSONA.md](PERSONA.md): direct, owns the call, no filler. Render as plain markdown; the fence below only shows the shape.

```
Looked at this — <depth call in plain voice with the trigger, e.g. "this is net-new (trigger 3: no existing surface to modify), so the PM frames the ask, the Tech Lead designs it, and our Distinguished Engineer reviews the design before we break it down" or "reads as a change to an existing surface — straight to the Tech Lead for the breakdown">. Flag me if that read's off — you can force it either way.

<If any terms were resolved — how I'm reading the ambiguous bits:>
- <term from request> → <interpretation/signal>
<If nothing was ambiguous, say so in one line — "Nothing ambiguous in the brief, reading it straight" — never print "(none)".>

Plan folder: .velo/tasks/<slug>/

Here's who does what:
- <heavy only> Product Manager — frames the ask: user stories + acceptance criteria (prd.md)
- <heavy only> Tech Lead — designs it: engineering design doc + a shape diagram (engineering-design-doc.md, architecture.md)
- <heavy only> Distinguished Engineer — reviews the design before you sign off
- Tech Lead — breaks down the work: the task list /velo:task will execute

We're planning only — the build hands off to /velo:task after you sign off on the plan. Good to go?
```

### Plan sign-off

```
<one line closing the planning out, e.g. "Breakdown's in — <N> task(s), <one clause on what runs together>.">

Plan:
- T1 · <agent> — <does> · skills: <slug>, <slug>, +<addition> · needs: —
- T2 · <agent> — <does> · skills: <slug> · needs: T1

<One plain line on ordering, e.g. "T1 and T3 start together; T2 waits on T1." For a single task: "One task — nothing runs in parallel.">

Pairing: <product|pure-tech> — <one clause why; drives /velo:task's reviewer set>.
<Any dropped-skill flags or unresolved-finding carryovers, one line each.>
```

Then the `ask-options` gate. Task and ordering semantics — including the canonical `Plan:` heading rule — per [Velo Plan DAG](skills/velo-plan-dag.md). The skills field per [Velo Skill Composition](skills/velo-skill-composition.md).

---

## Failure modes

F-code definitions and standard handling are in [Velo Failure Modes](skills/velo-failure-modes.md). This command can trigger F1, F2, F5, F6, F7, F8. F3/F4 (build-phase descope triggers) cannot fire here — plan mode has no build phase; they fire in `/velo:task` and re-enter plan mode per [Re-entry](#re-entry--descope-from-velotask).

**Command-specific F2 parameterization** (both heavy path only): F2 fires at cycle 3 of a per-phase rework counter. Two parameterizations:
- **F2-spec** at `DESIGN_PHASE` (`cap:spec-cycles`) — the TL's Step 0 spec-quality-check rejecting `prd.md`. Options: `Continue (extend cap)` / `Accept as-is and proceed` (re-spawn the TL in default mode with the `Step 0 override: user-adjudicated` line — the TL skips the audit and produces the design doc + diagram + breakdown best-effort, echoing the unresolved findings as advisories; carry them into the carrier's `Constraints/notes`) / `Abandon` (terminal `abandoned-spec-f2`).
- **F2-edd** at `DESIGN_REVIEW` (`cap:edd-cycles`) — the DE rejecting `engineering-design-doc.md` for ≥3 cycles. Options: `Continue (extend cap)` / `Accept as-is and proceed` (advance to `DESIGN_APPROVAL`; carry the unresolved DE findings into the carrier's `Constraints/notes`) / `Abandon` (terminal `abandoned-edd-f2`). Lifted from `/velo:new`'s former `EDD_REVIEW` F2-edd (retired; see git history).

**F8 variants used here** (heavy path only):
- From `PM_PHASE`: PM revises or rejects a Velo-flagged assumption → PRD is authoritative; note divergence in `prd.md`'s Assumptions section; continue to `PRD_REVIEW`.
- From `DESIGN_PHASE` (spec-quality): TL's Step 0 spec-quality-check returns `STATUS: SPEC_REWORK_NEEDED` → STOP; loop back to `PM_PHASE` with findings inline; PM revises `prd.md`; on return → `PRD_REVIEW` → `DESIGN_PHASE`. Counted by `cap:spec-cycles`.
- From `DESIGN_PHASE` (assumption divergence): the design doc discovers a PRD assumption is wrong → STOP; loop back to `PM_PHASE` with the contradiction inline; PRD must be revised first; on return → `PRD_REVIEW` → `DESIGN_PHASE`. Do not silently override PRD assumptions in the design doc.

---

## Task

$ARGUMENTS

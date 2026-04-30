# PRD — `/velo:hunt`

## Problem Statement

Engineers debugging a specific bug face a mismatch: `/velo:yo` gives advice but won't touch code; `/velo:task` delegates to a full agent team with build/review overhead. Neither fits the loop of "I have a symptom, I need a root cause, then maybe a fix." The gap is a tight, iterative hypothesis-investigation loop — one engineer and Velo, going fast.

## Goals

- Give engineers a dedicated mode for structured debugging: symptom → hypothesis → investigation → root cause.
- Keep the interaction tight: no PM, no TL, no review panels by default.
- End cleanly: either a confirmed root cause (handoff to `/velo:task`) or an explicit dead-end (abandoned with what was learned).
- Optionally spawn 1-2 focused subagents (log reader, code tracer) when investigation genuinely requires parallel reads — not as default.

## Non-Goals

- Writing any production code — hunt stops at root cause + fix proposal. Implementation goes to `/velo:task`.
- Code review or quality assessment of the surrounding code.
- Multi-bug triage or bug queue management.
- Broad refactoring of the affected area.
- Feature gap analysis ("this is a missing feature, not a bug").
- Cross-service distributed tracing or infra-level diagnosis requiring specialist agents (infra-engineer, db-engineer).
- Test writing — handled post-fix by `/velo:task` automation-engineer.

---

## User Stories

### US-1 — Start a hunt from a symptom
**As an** engineer stuck on a bug,
**I want to** type `/velo:hunt <symptom or error>` and immediately enter a structured debug loop,
**so that** I don't have to frame it as a task or feature to get help.

**Acceptance criteria:**
- Velo reads the symptom and asks 1-3 targeted clarifying questions (repro steps, what's been tried, suspected area) before proceeding.
- If symptom is fewer than 10 words with no file/function/error reference, Velo asks for more context.
- First response is always: context gathering, not a theory dump.

---

### US-2 — Hypothesis-driven investigation loop
**As an** engineer in a hunt,
**I want** Velo to propose ranked hypotheses and investigate them one at a time,
**so that** I'm not drowning in parallel theories and can stay focused.

**Acceptance criteria:**
- After context is gathered, Velo proposes ≤3 hypotheses, ranked by likelihood.
- Velo states which it's investigating first and why.
- Each investigation step reads actual files/logs/code — no speculation.
- After each step, Velo updates hypothesis confidence and states next action explicitly.

---

### US-3 — Root cause confirmation
**As an** engineer,
**I want** Velo to declare a confirmed root cause with evidence,
**so that** I know when the hunt is done and what to fix.

**Acceptance criteria:**
- Root cause declaration includes: the specific code location, the mechanism of failure, and the conditions that trigger it.
- Velo does not declare root cause without pointing to at least one concrete artefact (file + line or log entry).
- If Velo cannot confirm, it says so explicitly rather than guessing.

---

### US-4 — Fix proposal and handoff
**As an** engineer with a confirmed root cause,
**I want** Velo to propose a fix approach and offer to hand off to `/velo:task`,
**so that** I don't have to re-explain the context when switching modes.

**Acceptance criteria:**
- Fix proposal is prose only — no code written.
- Proposal includes: what to change, where, and what test would verify the fix.
- Velo offers an explicit handoff: draft brief pre-filled with root cause + fix approach for `/velo:task`.
- Handoff is one click (AskUserQuestion with options: "Start /velo:task", "Fix myself", "Keep investigating").

---

### US-5 — Abandon a hunt cleanly
**As an** engineer who has hit a wall,
**I want** to exit the hunt with a summary of what was ruled out,
**so that** the investigation isn't lost and I can resume or escalate.

**Acceptance criteria:**
- Velo detects stalls: 3+ investigation steps with no progress, or engineer types "abandon" / "give up" / "stop".
- On abandon, Velo prints a structured summary: symptom, hypotheses tried, what each ruled out, last known state.
- Summary is printed to terminal — no file written unless the user asks.

---

### US-6 — Scope boundary: redirect feature requests
**As an** engineer who accidentally hunts a missing feature,
**I want** Velo to flag it and offer to redirect to `/velo:yo` or `/velo:new`,
**so that** I don't waste time debugging expected behaviour.

**Acceptance criteria:**
- If investigation reveals the behaviour is intentional (no code defect), Velo names it explicitly: "This looks like a missing feature, not a bug."
- Offers redirect: `/velo:yo` for discussion, `/velo:new` for building it.
- Does not continue hunt mode after flagging.

---

### US-7 — Optional focused subagent for deep reads
**As an** engineer on a complex bug,
**I want** Velo to optionally spawn a read-only subagent for parallel code or log analysis,
**so that** investigation is faster without adding team overhead.

**Acceptance criteria:**
- Subagent is spawned only when investigation requires reading more than 5 files in parallel or a log corpus that would slow the main loop.
- Subagent is read-only — produces findings, no writes.
- Velo announces the spawn explicitly: "Spawning a code-reading agent to trace X in parallel."
- Default is no subagent — Velo reads directly unless the case warrants it.

---

### US-8 — Skill boundary enforcement vs `/velo:yo` and `/velo:task`
**As a** user of the velo plugin,
**I want** clear rules about when hunt is the right tool,
**so that** I reach for the right skill first.

**Acceptance criteria:**
- `/velo:hunt` is the right choice when: there is a specific observed defect, the engineer has a repro (or near-repro), and the goal is root cause — not advice or implementation.
- `/velo:yo` is preferred when: the engineer wants to understand a behaviour, explore a trade-off, or discuss before debugging.
- `/velo:task` is preferred when: root cause is already known and the goal is to fix + ship.
- Hunt must validate input against these criteria and redirect if the request clearly fits another skill.

---

## Prioritisation

### Must-have
- Input validation and context gathering (US-1)
- Hypothesis-driven investigation loop with ranked theories (US-2)
- Root cause confirmation with evidence gate (US-3)
- Fix proposal + AskUserQuestion handoff to `/velo:task` (US-4)
- Clean abandon with summary (US-5)
- Scope boundary enforcement and redirect logic (US-8)

### Nice-to-have
- Feature-vs-bug detection and redirect (US-6)
- Optional focused subagent for parallel reads (US-7)

---

## Edge Cases

- Bug cannot be reproduced: Velo says so, asks for logs or a minimal repro, does not fabricate a root cause.
- Bug spans multiple services: flag it. Hunt stays in one service. Recommend `/velo:yo` for cross-service architecture discussion or `/velo:task` with infra-engineer if a deployment fix is needed.
- Engineer provides contradictory symptoms (works locally, fails in prod): treat as two hypotheses, investigate env differences first.
- Root cause found but fix requires schema migration or infra change: propose fix in prose, route to `/velo:new` not `/velo:task`.
- Engineer abandons mid-hypothesis: print partial summary of what was investigated, stop cleanly.
- Input is a stack trace with no surrounding context: Velo reads the trace, identifies the first non-library frame, and asks one targeted question before hypothesising.
- Bug is a known upstream dependency issue: flag it, link to the relevant area, recommend a workaround rather than a fix.
- Engineer asks Velo to write a fix mid-hunt: decline, offer `/velo:task` handoff.

---

## Dependencies

- `PERSONA.md` — Velo persona rules apply (no code, opinionated, direct).
- `commands/task.md` — handoff target; draft brief format must be compatible with `/velo:task` input.
- `commands/yo.md` — redirect target for feature-vs-bug and advisory questions; AskUserQuestion pattern from yo Step 7 is reused.
- `commands/new.md` — redirect target when fix requires schema/infra changes.
- AskUserQuestion deferred tool — required for handoff gate (US-4) and abandon confirmation (US-5); must ToolSearch before calling.
- No new agents required for MVP — Velo runs the loop directly. US-7 subagent is optional and uses the existing Agent tool pattern from `TEAM.md`.

# Engineering Design Doc — `/velo:hunt`

> Version: 2.0 — 2026-04-30
> Status: Pending approval (cycle 2 revision)

## Decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | Ship as `commands/hunt.md` (not `commands/velo/`) | Existing skills (`yo.md`, `task.md`, `new.md`) live directly under `commands/`; creating `commands/velo/` would silently break the `/velo:hunt` invocation. |
| D2 | Velo runs the loop in-thread; no agents spawned | Hunt's value is tightness. Per-step agent round-trips break the conversational rhythm that distinguishes hunt from `/velo:task`. |
| D3 (revised) | State is the printed Hunt board markdown — no TypeScript types, no in-memory store. Every counter that drives a transition must render in the board. | Velo has no durable typed store between turns; the rendered transcript is the only substrate. If a counter doesn't render, it can't justify a state change to the user. Replaces the cycle-1 TypeScript block. |
| D4 (revised) | Caps are **soft warnings**, not hard triggers. At 5 steps on the active hypothesis OR 3 consecutive no-progress steps, Velo prompts via `AskUserQuestion`: "Re-rank, keep going, or abandon?" The stall counter is global and pre-empts the per-hypothesis cap when both fire on the same step. | Flaky/env-diff bugs legitimately need more steps. Hard caps would force premature re-ranks. Pre-emption rule resolves the cycle-1 ambiguity (was S2 in critique). |
| D5 | Root cause requires evidence gate: at least one concrete artefact (file:line or log entry) cited before declaration | Direct from PRD US-3. Without this, hunt degenerates into speculation. |
| D6 | All exits (handoff, redirect, abandon) route through `AskUserQuestion`. The schema is loaded once via `ToolSearch select:AskUserQuestion` on first use. | One uniform exit gate. Load-once mirrors the pattern in `commands/task.md` and avoids the per-call `InputValidationError` that would fire if a redirect hits before Step 6. |
| D7 (revised, supersedes cycle-1 D7) | **Cut subagents from MVP.** US-7 moves to a follow-up. | Removes the unrestricted-tools risk (cycle-1 C5) and the unspec'd merge-back schema (cycle-1 S3). PRD lists US-7 as nice-to-have. Reduces surface area. |
| D8 | Hard rule: Velo never writes code in hunt mode. Block lives at the top of the skill, not just in the failure table. | Long debug threads drift toward inline code suggestions. Top-of-skill placement mirrors `yo.md`'s "Hard Rule — No Code, Always Delegate". |
| D9 (new) | Tool allowlist: `Read`, `Grep`, `Glob` only. `Bash` is allowed only for `git log` and `git blame` (history attribution) — both read-only. No other Bash. | Constrains the "read-only" claim. Closes cycle-1 C5. Keeps hunt as an investigation skill, not an executor. |
| D10 (new) | Step 1 input classifier is signal-based, 3-way: (a) specific observed defect with no known root cause → continue, (b) root cause already known + ready to fix → redirect to `/velo:task`, (c) conceptual / no observed defect → redirect to `/velo:yo`. Verb heuristics removed. | "Fix login 500" or "debug retry loop" is a defect, not a build request. Cycle-1 verb matching mis-routed these. Resolves C7. |
| D11 (new) | Hypothesis state machine is documented with explicit transitions, triggers, and counter-reset rules (see "Hypothesis state machine" section). | Cycle-1 left transitions implicit. Closes C6. |
| D12 (new) | Secret-handling rule: if investigation surfaces a credential / token / private key, Velo flags and stops reading that artefact. The secret is never re-printed in Hunt board, evidence ledger, or summary. | Investigation reads can hit `.env`, log dumps, fixtures. Closes critique S9 / F12. |
| D13 (new) | Handoff brief is a 3-line structured format: `Root cause: <file:line + mechanism>`, `Fix approach: <prose>`, `Verifying test: <prose>`. Used in Step 6 successful exit and as `/velo:task` input. | Cycle-1 left brief shape implicit. Closes S10. |

## Hard Rule — No Code, Investigation Only

(Renders at the top of `commands/hunt.md`, before Step 1.) Velo never writes code in hunt mode — not snippets, pseudocode, diffs, or the fix itself. Hunt produces prose only: hypotheses, evidence, root cause, fix proposal. If the user asks for code mid-hunt, decline and offer the Step 6 handoff to `/velo:task`.

## Non-Goals (skill-level)

Writing/editing source (→ `/velo:task`); code review of surrounding code; multi-bug triage; cross-service tracing; broad refactors; test writing; spawning subagents (cut per D7).

## Skill workflow

### Step 0 — Load AskUserQuestion

Before the first `AskUserQuestion` call (which may fire from any of Steps 1, 2, 4, 5, 6, 7 or any failure mode), run `ToolSearch` with query `select:AskUserQuestion`. Load once per skill invocation.

### Step 1 — Validate input + classify

Print the mode banner: `**Hunt mode.** <one sentence on what's being investigated>`.

Classify input by signal (per D10):

1. **Empty / whitespace** → print "What's the symptom?" and stop.
2. **<10 words AND no error/file/function/stack-frame reference** → ask one clarifying question (repro? error? where seen?). Wait. Then re-classify.
3. **Specific observed defect, no known root cause** (signals: error message, log entry, stack trace, observed wrong output, specific failing condition) → continue to Step 2.
4. **Root cause already stated by user** (signals: user names a file/function as the cause, or proposes a specific fix) → call `AskUserQuestion` with header "Looks like a build request", question "Root cause sounds known. Switch to /velo:task to fix it?", options: `Start /velo:task` (invoke `velo:task` with brief = user's stated cause + symptom), `Continue hunting` (treat as defect, go to Step 2), `Cancel`.
5. **Conceptual / no observed defect** (signals: "how should…", "is X better than Y", "what's the right way to…") → call `AskUserQuestion` with header "Sounds advisory", question "This looks like a discussion, not a debug. Switch to /velo:yo?", options: `Start /velo:yo` (invoke `velo:yo` with the original input), `Continue hunting`, `Cancel`.

### Step 2 — Gather context (1–3 questions max)

Ask numbered clarifying questions per PERSONA.md. Required signals: repro steps (or "can't reproduce" — see F2), what's been tried, suspected file/area.

**Stack-trace input branch**: read trace, identify first non-library frame, read that file, then ask one targeted question. After the user answers, proceed to Step 3.

### Step 3 — Propose hypotheses + render Hunt board

Print the Hunt board (template below). ≤3 hypotheses ranked H1/H2/H3, each with a one-line rationale and confidence (low/medium/high). Name the active hypothesis and why it's first.

### Step 4 — Investigation loop

For the active hypothesis, one step at a time:
1. Name the next read (file/grep/git-log) and why.
2. Perform the read using `Read` / `Grep` / `Glob` (or `Bash` for `git log` / `git blame` only — D9).
3. Re-render the Hunt board: confidence delta on active, new evidence appended, counters updated, next action stated.

Rules:
- Every step must read a real artefact. No speculation steps.
- **Soft cap (D4)**: at 5 steps on the active hypothesis with no confidence increase, OR 3 consecutive no-progress steps globally, prompt the user via `AskUserQuestion`: options `Re-rank now`, `Keep going`, `Abandon`. If both caps fire on the same step, the global stall counter wins (D4 pre-emption).
- High confidence + concrete evidence → Step 5.

### Step 5 — Confirm root cause (evidence gate)

Declare root cause only when all three are present:
- Specific code location (file:line) OR specific log entry
- Mechanism of failure (one paragraph)
- Trigger conditions

Missing any → return to Step 4 or trigger F1.

### Step 6 — Fix proposal + handoff

Print the prose fix proposal (no code) and the **handoff brief** in the D13 format:

```
> Root cause: <file:line + mechanism>
> Fix approach: <prose, what to change and where>
> Verifying test: <prose description of the test>
```

Then call `AskUserQuestion`:
- `Start /velo:task` → invoke `velo:task` with the brief as argument
- `Start /velo:new` → use this option instead of `/velo:task` when fix requires schema migration / infra change (F4)
- `Fix myself` → print successful-exit summary (template below) and stop
- `Keep investigating` → return to Step 4 with current Hunt board
- `Abandon` → Step 7

### Step 7 — Abandon / summary

Triggered by: stall option "Abandon", user types abandon/give up/stop, F1, F2 dead-end. Print the abandon summary template (below). No file written.

## Hunt board render template

Render after every Step 3 hypothesis update and every Step 4 read.

```
### Hunt board

Symptom: <one line>
Active: H1

| ID | Hypothesis | Confidence | Status | Rank |
|---|---|---|---|---|
| H1 | <statement> | medium | active | 1 |
| H2 | <statement> | low | pending | 2 |
| H3 | <statement> | low | pending | 3 |

Evidence ledger:
- H1 +: <file:line — finding>
- H1 -: <file:line — counter-evidence>
- H2 ?: <still untested>

Counters: Steps on active 3/5 · No-progress streak 1/3
Next action: <one line — what Velo will read next and why>
```

Every counter visible. Anything that doesn't render doesn't drive a transition.

## Hypothesis state machine

States: `pending` → `active` → (`confirmed` | `ruled-out`).

| From | Trigger | To | Side effects |
|---|---|---|---|
| pending | Selected by Velo as next-best after a re-rank | active | `stepsOnActive` resets to 0 |
| active | Step 5 evidence gate satisfied | confirmed | Proceed to Step 6 |
| active | Soft-cap re-rank chosen by user with no evidence-for | ruled-out | `stepsOnActive` resets; next-ranked pending → active |
| active | Soft-cap "Keep going" chosen | active | No transition; counters continue |
| active | Step finds explicit counter-evidence (e.g. condition impossible to hit) | ruled-out | Same as above |
| pending | All 3 hypotheses ruled-out OR all hit 5-step soft cap with no confirmation | — | Trigger F1 |

Counter resets:
- `stepsOnActive`: resets on hypothesis switch (re-rank or rule-out).
- `noProgressStreak`: resets on any step with confidence delta = up.

## Successful-exit summary template (Step 6 "Fix myself")

```
### Hunt complete — root cause confirmed

Symptom: <one line>
Root cause: <file:line + mechanism>
Trigger conditions: <one line>
Fix approach: <prose>
Verifying test: <prose>
Hypotheses ruled out: H2 (<why>), H3 (<why>)
```

## Abandon summary template (Step 7)

```
### Hunt abandoned

Symptom: <one line>
Hypotheses tried:
- H1 <statement> — ruled out by <evidence>
- H2 <statement> — stalled at step 5, no confidence increase
- H3 <statement> — not investigated
Last known state: <one line>
Next step if resuming: <one line>
```

## Failure modes

| ID | Trigger | Handling |
|---|---|---|
| F1 | All 3 hypotheses status `ruled-out` OR all hit the 5-step soft cap with no confirmation | `AskUserQuestion`: `Reset and re-rank with new hypotheses` (replaces current 3, doesn't extend — D4), `Switch to /velo:yo`, `Abandon` |
| F2 | User cannot reproduce the bug | Ask for logs or minimal repro. If neither available → route through Step 7 (abandon summary). |
| F3 | Bug spans multiple services | `AskUserQuestion`: `Switch to /velo:yo` (architecture discussion), `Switch to /velo:task` (single-service deployment fix), `Continue hunting in this service`, `Abandon` |
| F4 | Fix requires schema migration / infra change | Step 6 substitutes `/velo:new` for `/velo:task` in the AskUserQuestion options (D6 single-gate). |
| F5 | User asks Velo to write code mid-hunt | Decline per Hard Rule. Offer Step 6 handoff via `AskUserQuestion`: `Start /velo:task`, `Keep investigating`, `Abandon`. |
| F6 | Investigation reveals intentional behaviour (feature gap) | `AskUserQuestion`: `Switch to /velo:yo`, `Switch to /velo:new`, `Abandon`. Do not continue hunt. |
| F7 | Known upstream dependency issue | `AskUserQuestion`: `Continue hunting (workaround)`, `Switch to /velo:yo`, `Abandon`. |
| F8 | Tool error (Read/Grep/Glob/Bash returns failure) | Re-render Hunt board, log the failed read in the evidence ledger as `error: <message>`, propose an alternative read. Two consecutive tool errors → trigger F1. |
| F9 | Bash blocked (permission denied for `git log` / `git blame`) | Skip the history read; continue with `Read`/`Grep`/`Glob`. Note in evidence ledger. |
| F10 | Stack trace contains only library frames (no first-party code) | Ask user for the calling code path or the entry point that triggered the trace. Do not hypothesise on library internals. |
| F11 | Two reads return contradictory evidence on the same hypothesis | Add both to the evidence ledger as `+`/`−`, downgrade confidence one level, name a tie-breaker read as the next action. |
| F12 | Investigation surfaces a secret / credential / private key | Stop reading that artefact. Do NOT print the secret in Hunt board, evidence, or summary. Note as `redacted: <artefact path, no content>`. |
| S2-silent | User goes silent mid-hunt | No proactive ping. On next user message, re-render the current Hunt board and continue. |

## File layout

| Path | Action | Notes |
|---|---|---|
| `commands/hunt.md` | New file | Frontmatter (`description`, `argument-hint`) + `@PERSONA.md` import + Hard Rule + Non-Goals + Steps 0–7 + Hunt board template + state machine + summary templates + failure table. |
| `README.md` | Update | Add `/velo:hunt` to the command index. |
| `WORKFLOW.md` | Update | Add `/velo:hunt` alongside `/velo:new`, `/velo:task`, `/velo:yo`. |

No new agents. No `TEAM.md` change. No new files under `skills/`. No subagents (D7).

---
name: velo-yo-input-validation
description: Yo Step 1 triage. Empty-input handling, @-prefix forwarding to /velo:discuss, vagueness threshold, action-request verb classes (build / debug / review) and their routing prompts, multi-part question handling, discussion fall-through.
---
# Velo Yo — Input Validation

This is Step 1 of `/velo:yo` — the front door's triage. Yo is the entry point: it classifies the intent and routes work to the mode that does it, or lets questions through to discussion. Gates applied in order; the first matching gate fires and the others are skipped.

## 1. Empty or whitespace

If the input is empty or whitespace only → print `"What's the question?"` and stop.

## 2. `@<agent>` prefix — forward to `/velo:discuss` verbatim

`@pm`, `@tl`, and `@de` target a single advisory agent. Yo does not own that syntax and does not parse it — `/velo:discuss` does.

If the input's first token starts with `@` → route to `/velo:discuss` through `handoff-mode`, carrying the input **verbatim, prefix included**. Do not strip the prefix, do not split it off from the question, and do not validate the agent name here — discuss's Step 1 gate 2 owns the token-boundary rules (so `@pmail` does not match `@pm`) and the unknown-agent error. Skip the remaining gates below: a targeted input is never re-classified as a build, a review, or a vague question.

This gate sits ahead of the vagueness, action-request, and multi-part gates on purpose. `@de is refactoring auth worth it` carries a build verb; without this precedence it would route to `/velo:plan` and the targeting would be lost — the exact failure this gate exists to prevent.

## 3. Too vague

Fewer than 10 words AND no named technology, architecture pattern, codebase component, or specific trade-off → ask a clarifying question before proceeding.

## 4. Action request (build, debug, or review verbs)

Routing work to its mode is yo's primary job, not a redirect away. Detect by verb class targeting a concrete artifact, then use `ask-options` to present the route. The work itself always happens in the routed mode — never perform the action in yo.

**Tone:** acknowledge conversationally, like a teammate — "Sure, sounds like a build — want me to route this?" Do NOT explain the rules ("yo doesn't write code", "that's a build request, not a discussion"). The user knows what yo is; just route.

Check the debug class before the build class — `fix` overlaps: `fix` targeting a symptom with no known cause (e.g. "fix the crash on login") is debug intent; `fix` where the change is already understood is a build.

**Debug verbs** — `debug`, `investigate`, `diagnose`, `troubleshoot`, or symptom language (`bug`, `crash`, `error`, `broken`, `failing`, `regression`) where the root cause is not yet known:

Ask `"Sounds like a bug hunt — which route?"` with 3 options:
- `Start /velo:hunt` — structured debug loop: symptom → hypothesis → root cause
- `Start /velo:task` — root cause already known; go straight to the fix
- `Keep discussing` — stay in yo mode for follow-up

**Build verbs** — `add`, `fix`, `build`, `implement`, `refactor`, `create`, `delete`, `deploy` — targeting a page, component, endpoint, table, service, function, agent, skill:

Ask `"Sounds like a build — which route?"` with 3 options:
- `Start /velo:plan` — net-new feature: plan (PRD + DE-reviewed EDD) first, then build via /velo:task
- `Start /velo:task` — smaller change, lighter workflow
- `Keep discussing` — stay in yo mode for follow-up

**Review verbs** — `review`, `audit`, `critique`, `check`, `inspect`, `analyze` — targeting code, a PR, a branch, a file, a service, security, performance:

Ask `"Sounds like a review — which route?"` with 4 options:
- `Start review` — route through `handoff-mode`
- `Start security review` — route through `handoff-mode`
- `Start ultrareview` — route through `handoff-mode`
- `Keep discussing` — stay in yo mode for follow-up

Never present more than 4 options in a single `ask-options`. After the user picks, route through `handoff-mode`. If they pick `Keep discussing`, do nothing further on the routing — wait for the user's next message.

## 5. Multi-part question (3+ distinct questions)

Pick the most important one, state which you're focusing on, OR ask the user to narrow.

## After triage — the discussion fall-through

If none of the gates above route onward or terminate, the request is a question rather than work to route. Discussion has no verb class of its own on purpose: it is what remains when nothing else fires, so every question reaches this fall-through instead of competing with the multi-part and vagueness gates for precedence.

Input prefixed `@pm` / `@tl` / `@de` never reaches this fall-through — gate 2 already forwarded it verbatim, so the "carry the user's question" wording below applies only to untargeted input and can never strip a prefix in transit.

Two outcomes, and Velo picks between them:

- **Answerable from pure knowledge** — a concept explanation, a follow-on in this thread that needs no new file reading, or a well-established answer with no genuine multi-sided trade-off → answer it in yo per Step 1's "Answering directly" in `commands/yo.md`. No file reads.
- **Needs evidence from the codebase, or worth more than one perspective** — a genuine multi-sided trade-off, a scope or build-vs-shelve call, a major architectural choice → route to `/velo:discuss` through `handoff-mode`, carrying the user's question so they do not retype it. The panel agents read the code; Velo does not.

When in doubt, route. If Velo starts answering and then finds itself wanting to read a file, that is the signal it picked wrong — stop and route to `/velo:discuss`.

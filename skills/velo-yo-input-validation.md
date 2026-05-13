---
name: velo-yo-input-validation
description: Yo Step 1 input validation. Empty-input handling, @-prefix agent targeting, vagueness threshold, action-request verb classes (build vs review) and routing prompts, multi-part question handling.
---
# Velo Yo — Input Validation

This is Step 1 of `/velo:yo`. Applied in order; the first matching gate fires and the others are skipped.

## 1. Empty or whitespace

If the input is empty or whitespace only → print `"What's the question?"` and stop.

## 2. `@<agent>` prefix (check before any other validation)

Check the `@`-prefix gate **first** after the empty-input check. Single-agent bypass makes vagueness, implementation-request, and multi-part checks irrelevant.

- If input starts with `@pm`, `@tl`, or `@de` (case-insensitive) **and the prefix token is followed immediately by a space, tab, or end of input** (not embedded in a longer word — e.g. `@pmail` must NOT match `@pm`): strip the prefix and any following whitespace to get the question.
  - If the remaining question is empty → print `"What's the question?"` and stop.
  - Otherwise → route to **Single-agent mode** (Step 2). Skip the remaining gates below.
- If input starts with `@` followed by any other token (not `pm`, `tl`, or `de`) → print `"Unknown agent. Available: @pm, @tl, @de."` and stop.
- Multi-agent syntax (`@pm @tl`) is out of scope for v1 — single agent only.

## 3. Too vague

Fewer than 10 words AND no named technology, architecture pattern, codebase component, or specific trade-off → ask a clarifying question before proceeding.

## 4. Action request (build or review verbs)

Detect by verb class targeting a concrete artifact, then use `ask-options` to present the route. Do NOT preface with meta-commentary about why yo doesn't do work — render through the richest interaction supported by the runtime. Do not perform the action yourself in either case.

**Build verbs** — `add`, `fix`, `build`, `implement`, `refactor`, `create`, `delete`, `deploy` — targeting a page, component, endpoint, table, service, function, agent, skill:

Ask `"This looks like a build request — which route?"` with 3 options:
- `Start /velo:new` — net-new feature with full PRD/EDD pipeline
- `Start /velo:task` — smaller change, lighter workflow
- `Keep discussing` — stay in yo mode for follow-up

**Review verbs** — `review`, `audit`, `critique`, `check`, `inspect`, `analyze` — targeting code, a PR, a branch, a file, a service, security, performance:

Ask `"This looks like a review request — which route?"` with 4 options:
- `Start review` — route through `handoff-mode`
- `Start security review` — route through `handoff-mode`
- `Start ultrareview` — route through `handoff-mode`
- `Keep discussing` — stay in yo mode for follow-up

After the user picks, route through `handoff-mode`. If they pick `Keep discussing`, do nothing further on the routing — wait for the user's next message.

## 5. Multi-part question (3+ distinct questions)

Pick the most important one, state which you're focusing on, OR ask the user to narrow.

## After validation

If none of the gates above terminate or redirect the flow, proceed to Step 2 — mode selection (`skills/velo-yo-mode-selection.md`).

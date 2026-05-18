---
name: velo-gates
description: Ship (commit + optional push) and PR approval gate pattern. Per-action approval, ask-options prompt shape, what happens on each branch. Reusable across Velo slash commands that produce committable changes.
---
# Velo Approval Gates

## PERSONA hard rule

Never commit, push to remote, or open a PR without **explicit per-action approval**. Commit, push, and PR are three distinct visible-action surfaces — each requires its own approval, and past authorization for one never extends to the others or to future actions of the same type. The specific gate shape — a single ship gate that bundles commit + optional push, or separate commit and push gates — is the caller command's choice; what is non-negotiable is that the user explicitly chooses each surface before it fires. Do not bundle `commit`, `push`, or `pr` into a `/velo:task` or `/velo:new` brief unless the user explicitly authorized that specific action for that specific task.

## Why these gates

Commit, push, and PR are three distinct visible-action surfaces. This skill defines four gate patterns that callers compose into their state machines: a unified **ship gate** that bundles commit + optional push into a single prompt (lower-friction, used by `/velo:task` for day-to-day work where the user almost always knows up-front whether the commit should leave the local machine), separate **commit gate** and **push gate** patterns that surface each action as its own prompt (higher-fidelity, used by `/velo:new` where reviewer-approval and ship-readiness are distinct phases), and a **PR gate** that always lives on its own (PR creation is a distinct decision — the user may want a commit pushed to a feature branch without immediately opening a PR for WIP, stacked branches, or draft work). All four gates honor PERSONA's per-action approval rule; authorization for one surface never implies authorization for the next.

## Ship gate (commit + optional push)

Used by callers that bundle commit + push into a single prompt (e.g. `/velo:task`'s `SHIP_GATE` state). The state body names the gate, its entry condition, and its exit conditions; this skill defines the prompt mechanics.

Use `ask-options`:
- **Header**: `"Ready to ship"` or `"Ship approval"` (state-specific phrasing is fine)
- **Question**: usually a summary of what passed (reviewers, spec check) followed by `"How do you want to ship?"`
- **Options** (verbatim labels):
  - `Commit + push` — spawn the `commit` agent (default mode); on commit success, run `git push`. On push success: if the current branch equals the repo's default branch (see Base-branch detection below) → terminal (`delivered-and-committed-and-pushed`); otherwise → PR gate.
  - `Commit only` — spawn the `commit` agent (default mode); on success → terminal (`delivered-and-committed`).
  - `Hold feedback` — treat as rework: spawn relevant builder(s) with the user's feedback inline; re-enter the upstream review state (per the caller's state body, typically with the review cycle counter reset to 1).
  - `Done — no commit` — terminal (`delivered-no-commit`).

When the commit agent fails OR push fails, F1 fires for telemetry. The state body decides whether to halt or to offer `Retry` / route to `/velo:hunt` / `Abandon`.

## Commit gate

Used by callers that surface commit as its own prompt distinct from push (e.g. `/velo:new`'s `COMMIT_GATE` state, which follows a separate reviewer-approval `SHIP_GATE`). The state body names the gate, its entry condition, and its exit conditions; this skill defines the prompt mechanics.

Use `ask-options`:
- **Header**: `"Commit approval"` (state-specific phrasing is fine)
- **Question**: usually a one-line summary of what's staged followed by `"Commit?"`
- **Options** (verbatim labels):
  - `Commit` — spawn the `commit` agent (default mode). On success, the caller typically transitions to its push gate.
  - `Hold — do not commit` — terminal for the caller's ship flow (`delivered-no-commit` or equivalent per the caller's terminal taxonomy).
  - `Abandon` — terminal (`abandoned-user` or equivalent per the caller's terminal taxonomy).

When the commit agent fails, F1 fires for telemetry. The state body decides whether to halt, retry, or route to `/velo:hunt`.

## Push gate

Entered only after the commit gate's `Commit` path succeeds. Used by callers that surface push as its own prompt distinct from commit (e.g. `/velo:new`'s `PUSH_GATE` state). The state body names the gate, its entry condition, and its exit conditions; this skill defines the prompt mechanics.

Use `ask-options`:
- **Header**: `"Push approval"` (state-specific phrasing is fine)
- **Question**: usually `"Commit landed locally. Push to remote?"`
- **Options** (verbatim labels):
  - `Push` — run `git push`. On success: if the current branch equals the repo's default branch (see Base-branch detection below) → terminal (`delivered-and-committed-and-pushed`); otherwise → PR gate.
  - `Hold — do not push` — terminal (`delivered-and-committed`).

When push fails, F1 fires for telemetry. The state body decides whether to halt or retry.

## PR gate

Entered only after the ship gate's `Commit + push` path succeeds (both commit and push landed) AND the current branch is not the repo's default branch (a PR from base → base is meaningless and is bypassed straight to terminal). The state body names the gate; this skill defines the prompt mechanics.

Use `ask-options`:
- **Header**: `"Open PR?"`
- **Question**: `"Push landed on <branch>. Open a pull request?"`
- **Options**:
  - `Open PR` — spawn the `commit` agent in PR mode (signal via `mode: pr` in `$ARGUMENTS`). The commit agent's PR-mode workflow delegates to [PR Protocol](pr-protocol.md) for title derivation, body templates, idempotency, and `gh pr create` invocation. On success → terminal (`delivered-and-committed-and-pushed-and-pr-opened`).
  - `Skip — no PR` — terminal (`delivered-and-committed-and-pushed`)

PR creation failure fires F1 per `skills/velo-failure-modes.md`. The state body decides whether to halt or to offer retry — typically halt and let the user retry manually with `gh pr create`.

The PR gate is the second concrete gate in the family — it is NOT a generic "gate factory" abstraction. It exists as its own state (not bundled into the ship gate's `Commit + push` path) because PR creation is a distinct visible action per PERSONA's per-action approval rule.

## Base-branch detection

Both the ship gate's `Commit + push` path (to decide whether `PR_GATE` should be bypassed after a successful push) and the PR gate (as an entry guard) need the repo's default branch. Resolve it in this order, stopping at the first source that yields a non-empty name:

1. `git symbolic-ref refs/remotes/origin/HEAD --short` → strip the leading `origin/` → use as the default branch name.
2. If step 1 fails (no `origin/HEAD` set), use `main` if `git show-ref --verify --quiet refs/heads/main` succeeds.
3. Otherwise, use `master` if `git show-ref --verify --quiet refs/heads/master` succeeds.

If none of the three resolve, the gate cannot determine a base branch — treat as on-base-branch (skip `PR_GATE`) and surface a one-line note to the user so they can retry PR creation manually if desired.

Then compare against `git rev-parse --abbrev-ref HEAD`: if equal, the current branch IS the base branch and `PR_GATE` is bypassed straight to terminal.

## Telemetry

All gates emit option-resolution events per `skills/velo-telemetry.md` (event 2). Their terminal reasons (`delivered-and-committed-and-pushed-and-pr-opened`, `delivered-and-committed-and-pushed`, `delivered-and-committed`, `delivered-no-commit`, `abandoned-user`, and any caller-specific phase abandons such as `abandoned-ship-gate`) are command-specific — each command enumerates its own terminal taxonomy.

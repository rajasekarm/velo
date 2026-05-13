---
name: velo-gates
description: Commit, push, and PR approval gate pattern. Per-action approval, ask-options prompt shape, what happens on each branch. Reusable across Velo slash commands that produce committable changes.
---
# Velo Approval Gates

## PERSONA hard rule

Never commit, push to remote, or open a PR without **explicit per-action approval**. Past authorization does not extend to future commits, pushes, or PRs. After any work that produces changes, ask: "Commit?" Wait for explicit approval. After commit, ask: "Push?" Wait for explicit approval. After push, ask: "Open PR?" Wait for explicit approval. Do not bundle `commit`, `push`, or `pr` into a `/velo:task` or `/velo:new` brief unless the user explicitly authorized that specific action for that specific task.

## Why three gates

Commit, push, and PR are three distinct visible actions. Each one is observable by collaborators (push and PR especially) and reversing them has different costs. Per PERSONA's "one action, one approval" principle, each lives as its own gate state — they are NOT bundled into a single confirmation. Authorization for an earlier action never implies authorization for the next.

## Commit gate

Used by states that produce changes ready to commit. The state body names the gate, its entry condition, and its exit conditions; this skill defines the prompt mechanics.

Use `ask-options`:
- **Header**: `"Ready to ship"` or `"Ship approval"` (state-specific phrasing is fine)
- **Question**: usually a summary of what passed (reviewers, spec check) followed by `"Approve commit?"`
- **Options** (typical):
  - `Approved, commit` — proceed to spawn the `commit` agent; on success → push gate
  - `Hold, I have feedback` — treat as rework: spawn relevant builder(s) with feedback inline; re-enter the upstream review state
  - `Abandon` or `Done — no commit` — terminate (per command, either `ABANDON` with `abandoned-ship-gate` or `DONE` with `delivered-no-commit`)

When the commit agent fails, F1 fires for telemetry. The state body decides whether to halt or to offer `Retry` / route to `/velo:hunt` / `Abandon`.

## Push gate

Entered only after commit succeeds. The state body names the gate; this skill defines the prompt mechanics.

Use `ask-options`:
- **Header**: `"Push to remote?"`
- **Question**: `"Commit done. Push?"`
- **Options**:
  - `Push` — run push; on success → terminal (`delivered-and-committed-and-pushed`)
  - `Hold — do not push` — terminal (`delivered-and-committed`)

Push failure fires F1 per `skills/velo-failure-modes.md`.

## PR gate

Entered only after push succeeds AND the current branch is not the repo's default branch (a PR from base → base is meaningless and is bypassed straight to terminal). The state body names the gate; this skill defines the prompt mechanics.

Use `ask-options`:
- **Header**: `"Open PR?"`
- **Question**: `"Push landed on <branch>. Open a pull request?"`
- **Options**:
  - `Open PR` — spawn the `commit` agent in PR mode (signal via `mode: pr` in `$ARGUMENTS`); on success → terminal (`delivered-and-committed-and-pushed-and-pr-opened`)
  - `Skip — no PR` — terminal (`delivered-and-committed-and-pushed`)

PR creation failure fires F1 per `skills/velo-failure-modes.md`. The state body decides whether to halt or to offer retry — typically halt and let the user retry manually with `gh pr create`.

The PR gate is a third concrete gate in the family — it is NOT a generic "gate factory" abstraction. It exists as its own state (not bundled into the push gate) because PR creation is a distinct visible action per PERSONA's per-action approval rule.

## Base-branch detection

Both the push gate (to decide whether `PR_GATE` should be bypassed) and the PR gate (as an entry guard) need the repo's default branch. Resolve it in this order, stopping at the first source that yields a non-empty name:

1. `git symbolic-ref refs/remotes/origin/HEAD --short` → strip the leading `origin/` → use as the default branch name.
2. If step 1 fails (no `origin/HEAD` set), use `main` if `git show-ref --verify --quiet refs/heads/main` succeeds.
3. Otherwise, use `master` if `git show-ref --verify --quiet refs/heads/master` succeeds.

If none of the three resolve, the gate cannot determine a base branch — treat as on-base-branch (skip `PR_GATE`) and surface a one-line note to the user so they can retry PR creation manually if desired.

Then compare against `git rev-parse --abbrev-ref HEAD`: if equal, the current branch IS the base branch and `PR_GATE` is bypassed straight to terminal.

## Telemetry

All three gates emit option-resolution events per `skills/velo-telemetry.md` (event 2). Their terminal reasons (`delivered-and-committed-and-pushed-and-pr-opened`, `delivered-and-committed-and-pushed`, `delivered-and-committed`, `delivered-no-commit`, `abandoned-ship-gate`, `abandoned-user`) are command-specific — each command enumerates them.

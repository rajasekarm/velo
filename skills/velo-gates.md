---
name: velo-gates
description: Single ship gate pattern bundling commit + optional push + optional PR. Per-action approval via action-naming labels, ask-options prompt shape, conditional PR option, base-branch detection, what happens on each branch. Reusable across Velo slash commands that produce committable changes.
---
# Velo Approval Gates

## PERSONA hard rule

Never commit, push to remote, or open a PR without **explicit per-action approval**. Commit, push, and PR are three distinct visible-action surfaces — each requires its own approval, and past authorization for one never extends to the others or to future actions of the same type. A single ship gate may bundle commit, push, and PR into one prompt **only when each option label explicitly names every action it triggers** — a label such as `Commit + push + open PR` constitutes explicit per-action authorization for all three, because the user reads and chooses exactly those named actions before any of them fires. What is non-negotiable is that the user explicitly chooses (by selecting a label that names them) each surface before it fires. Do not bundle `commit`, `push`, or `pr` into a `/velo:task` or `/velo:new` brief unless the user explicitly authorized that specific action for that specific task.

## Why this gate

Commit, push, and PR are three distinct visible-action surfaces. This skill defines a single **ship gate** pattern that both `/velo:task` and `/velo:new` compose into their state machines. The gate bundles commit, push, and PR into one `ask-options` prompt whose option labels each name the full action sequence they trigger, so a single choice still satisfies PERSONA's per-action approval rule (selecting `Commit + push + open PR` authorizes all three named actions, in that order). The gate honors per-action approval precisely because no action fires that is not spelled out in the chosen label.

## Ship gate (commit + optional push + optional PR)

The single shipping gate, used by `/velo:task`'s `SHIP_GATE` and `/velo:new`'s `SHIP_GATE`. The state body names the gate, its entry condition, and its exit conditions; this skill defines the prompt mechanics.

Use `ask-options`:
- **Header**: `"Ready to ship"` or `"Ship approval"` (state-specific phrasing is fine)
- **Question**: usually a summary of what passed (reviewers, spec check) followed by `"How do you want to ship?"`
- **Options** (verbatim labels, in this order):
  - `Commit + push + open PR` — **conditional**: present this option ONLY when the current branch is not the repo's default branch (resolve at gate time per Base-branch detection below; a PR from base → base is meaningless). Runs strictly ordered commit → push → PR: spawn the `commit` agent (default mode), then run `git push`, then spawn the `commit` agent in PR mode. On full success → terminal (`delivered-and-committed-and-pushed-and-pr-opened`). On failure see Failure handling below.
  - `Commit + push` — spawn the `commit` agent (default mode); on commit success, run `git push`. On push success → terminal (`delivered-and-committed-and-pushed`).
  - `Commit only` — spawn the `commit` agent (default mode); on success → terminal (`delivered-and-committed`).
  - `Hold feedback` — treat as rework: spawn relevant builder(s) with the user's feedback inline; re-enter the upstream review state (per the caller's state body, typically with the review cycle counter reset to 1).
  - `Done — no commit` — terminal (`delivered-no-commit`).

When the current branch equals the repo's default branch, the `Commit + push + open PR` option is omitted; the gate presents the remaining four options and their relative order is preserved.

### Failure handling

All failures fire F1 for telemetry; the state body decides halt vs. retry/route.
- **Commit agent fails** (any path) → F1. The state body decides whether to halt or to offer `Retry` / route to `/velo:hunt` / `Abandon`.
- **Push fails** (either `Commit + push` or `Commit + push + open PR`) → F1; halt. The report MUST surface `"local commit landed — push failed, retry manually or revert"` so the user knows the side effect.
- **PR step fails** on `Commit + push + open PR` after commit AND push both succeeded → F1; halt. Surface that the commit and push landed and that the PR can be retried manually with `gh pr create` (this preserves the retired standalone PR gate's failure behavior).

The PR step spawns the `commit` agent in PR mode (signal via `mode: pr` in `$ARGUMENTS`, passing the current branch name and the repo's default branch as the base). The commit agent's PR-mode workflow delegates to [PR Protocol](pr-protocol.md) for title derivation, body templates, idempotency, and `gh pr create` invocation; this gate does not duplicate PR-protocol logic inline.

## Base-branch detection

The ship gate needs the repo's default branch both to decide whether the `Commit + push + open PR` option is offered at all and, when it is chosen, to pass the base branch to the PR step. Resolve it in this order, stopping at the first source that yields a non-empty name:

1. `git symbolic-ref refs/remotes/origin/HEAD --short` → strip the leading `origin/` → use as the default branch name.
2. If step 1 fails (no `origin/HEAD` set), use `main` if `git show-ref --verify --quiet refs/heads/main` succeeds.
3. Otherwise, use `master` if `git show-ref --verify --quiet refs/heads/master` succeeds.

If none of the three resolve, the gate cannot determine a base branch — treat as on-base-branch (omit the `Commit + push + open PR` option) and surface a one-line note to the user so they can retry PR creation manually if desired.

Then compare against `git rev-parse --abbrev-ref HEAD`: if equal, the current branch IS the base branch, so the `Commit + push + open PR` option is omitted.

## Telemetry

The ship gate emits option-resolution events per `skills/velo-telemetry.md` (event 2). Its terminal reasons (`delivered-and-committed-and-pushed-and-pr-opened`, `delivered-and-committed-and-pushed`, `delivered-and-committed`, `delivered-no-commit`, `abandoned-user`, and any caller-specific phase abandons such as `abandoned-ship-gate`) are command-specific — each command enumerates its own terminal taxonomy.

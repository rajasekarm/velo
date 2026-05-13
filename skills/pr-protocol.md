---
name: pr-protocol
description: Pull-request protocol — title derivation with ticket-prefix convention, type-specific body templates (fix / feat / other), base-branch selection, idempotency check, and gh-cli invocation. Used by the commit agent's PR mode and any caller that opens PRs.
---
# PR Protocol

**Scope**: how to derive a PR title and body, check for an existing PR, and create one via `gh`. Used by the commit agent's PR mode (invoked from Velo's `PR_GATE`) and by any caller that opens PRs.

## Preconditions

Before creating a PR:

1. **gh authenticated**: run `gh auth status`. If unauthenticated, stop with: `"gh is not authenticated. Run \`gh auth login\` and try again."`
2. **On a named branch**: run `git branch --show-current`. If empty (detached HEAD), abort with: `"Cannot create PR: not on a named branch."`
3. **Branch differs from base**: if the current branch equals the base branch, abort with: `"Cannot create PR: current branch is the base branch."`

## Base-branch selection

Use the resolution order defined in [Velo Approval Gates — Base-branch detection](velo-gates.md): `git symbolic-ref refs/remotes/origin/HEAD --short` → `main` → `master`.

When invoked from `PR_GATE`, the gate passes the base explicitly in `$ARGUMENTS` — use it.

When invoked standalone (no base in `$ARGUMENTS`), resolve it per the skill section above.

## Idempotency check

Before invoking `gh pr create`, check whether a PR already exists for the current branch:

```
gh pr list --head "$(git branch --show-current)" --json url --jq '.[0].url'
```

If the command returns a non-empty URL, print it and stop with: `"A PR already exists at <url>."` Do NOT create a duplicate PR.

## Title derivation

PR titles follow the format `[TICKET-ID] - Description` when a ticket ID is derivable. Plain commit subject (no ticket prefix) is the FALLBACK, not the default.

### Ticket ID derivation order

Set `TICKET` by checking these sources in order, stopping at the first that yields a match against the regex `[A-Z]+-[0-9]+`:

1. **Branch name**:
   ```
   TICKET=$(git branch --show-current | grep -oE '[A-Z]+-[0-9]+' | head -1)
   ```
2. **Commit messages on the branch**:
   ```
   TICKET=$(git log <base>..HEAD --format=%B | grep -oE '[A-Z]+-[0-9]+' | head -1)
   ```
3. **Recent conversation context**: if the user mentioned a ticket ID matching `[A-Z]+-[0-9]+` in their most recent message or the message that triggered this PR flow, use that. Do not search older history.
4. **Prompt the user**: if none of the above yields a match, ask explicitly: `"No ticket ID found in branch, commits, or context. What is the ticket ID? (e.g. AGT-123)"`. Validate the response matches `^[A-Z]+-[0-9]+$`. Re-ask up to 3 times on invalid or empty input; after the third invalid response, fall back to the no-ticket title (see below) and proceed.

If multiple distinct ticket IDs appear within a source, use the first match returned by the lookup. The branch-name source takes precedence over commits by virtue of the lookup order.

### Building the title

When `TICKET` is non-empty, strip any existing ticket prefix from the description so it isn't duplicated:

```
TITLE="[$TICKET] - $(<description> | sed -E 's/^\[[A-Z]+-[0-9]+\][[:space:]]*-?[[:space:]]*//' | tr -cd 'a-zA-Z0-9 ()\[\]/_.,:-')"
```

Where `<description>` is:
- If there is exactly one commit on the branch: that commit's subject (`git log -1 --format="%s"`).
- If there are multiple commits: a single imperative-mood summary line, max 72 chars. Do not concatenate commit subjects.

When `TICKET` is empty (user declined to provide one after 3 prompts), fall back to the plain description as the title — no `[...]` prefix.

**Caller notice on soft fallback**: when the no-ticket fallback fires, the caller (the agent invoking this protocol) MUST surface a one-line notice alongside the PR URL in its return output, telling the user the PR was created without a ticket prefix and how to fix it. Recommended wording:

```
Created without ticket prefix — edit via `gh pr edit` if needed.
```

This is a caller responsibility, not a `gh pr create` flag — the protocol prescribes the message but does not emit it itself.

## Body templates

Pick the body template by inferring the PR type. Sources, in order:
1. The commit message prefix on the most recent commit (`fix:` / `fix(...):` → bug fix; `feat:` / `feat(...):` → feature; anything else → other).
2. If unclear and the agent is running interactively, ask: `"Bug fix, feature, or other?"`.

PR bodies do NOT carry a Claude Code attribution line. Commits carry their `Co-Authored-By` tail (see `commit-protocol.md`); PR bodies go out clean.

### Bug fix template (commit prefix `fix:` or `fix(...):`)

```
## Problem
<derived from diff and commit message — what was broken>

## Fix
<derived from diff — what changed and why>

## Test Case
<derived from diff — tests added or modified; write "N/A" if no test files appear in the diff>
```

### Feature template (commit prefix `feat:` or `feat(...):`)

```
## Feature
<derived from diff and commit message — what was added>

## Test Case
<derived from diff — tests added or modified; write "N/A" if no test files appear in the diff>
```

### Other template (multi-commit, chore, refactor, docs, test, perf, style, or unclear)

```
## Summary
- <1-3 bullets describing what changed and why>

## Test plan
- [ ] <derived from diff — tests added or modified; write "N/A" if no test files appear in the diff>
```

## gh-cli invocation

1. Write the body to a temp file (HEREDOC preserves formatting):
   ```
   BODY_FILE=$(mktemp /tmp/pr_body_XXXXXX.md)
   cat > "$BODY_FILE" <<'EOF'
   <body content>
   EOF
   ```
2. Assert `$TITLE` is non-empty before creating:
   ```
   if [ -z "$TITLE" ]; then echo "PR title is empty, aborting."; rm -f "$BODY_FILE"; exit 1; fi
   ```
3. Create the PR:
   ```
   gh pr create --base "<base>" --head "<current-branch>" --title "$TITLE" --body-file "$BODY_FILE"
   ```
4. Delete `$BODY_FILE` after `gh pr create` completes — whether it succeeds or fails.
5. Print the PR URL on success. On failure, print the error and stop — do not retry; the user can retry manually with `gh pr create`.

## What this protocol does NOT do

- Does not commit. Does not push. Those are caller responsibilities.
- Does not modify the working tree.
- Does not retry on `gh pr create` failure. Callers (e.g. `PR_GATE`) decide retry policy.

## Telemetry

PR-protocol does not emit telemetry directly. The calling state (typically `PR_GATE`) emits events per its own taxonomy.

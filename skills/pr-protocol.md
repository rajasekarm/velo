---
name: pr-protocol
description: Pull-request protocol — title derivation with ticket-prefix convention (derivation delegated to ticket-id-derivation.md, terminal behavior SOFT-FALLBACK), type-specific body templates ([FIX] / [FEAT] / other), base-branch selection, idempotency check, and gh-cli invocation. Used by the commit agent's PR mode and any caller that opens PRs.
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

### Ticket ID derivation

Set `TICKET` per [Ticket ID Derivation](ticket-id-derivation.md). That skill owns the ID shape and both regex forms, the stop-at-first-match lookup and its extraction idiom, the within-source tie-break, and the prompt-validate-re-ask fallback. This protocol declares only the two bindings required by [Ticket ID Derivation — Consumer binding contract](ticket-id-derivation.md#consumer-binding-contract) and restates none of those rules.

**Source list**, in precedence order — checked per [Ticket ID Derivation — Source lookup order](ticket-id-derivation.md#source-lookup-order):

1. **Branch name** — `git branch --show-current`
2. **Commit messages in the PR range** — `git log <base>..HEAD --format=%B`, where `<base>` is the base branch resolved above. This source is specific to this protocol: a PR spans a range of commits that already exist, so the range is readable here and has no counterpart in a protocol that authors a commit not yet written.
3. **Recent conversation context** — a ticket ID the user mentioned in their most recent message or the message that triggered this PR flow. Do not search older history.

If all three come back empty, the fixed prompt step in [Ticket ID Derivation — Prompting the user](ticket-id-derivation.md#prompting-the-user) runs. The prompt is not a fourth source.

**Terminal behavior: `SOFT-FALLBACK`**, per [Ticket ID Derivation — Terminal behavior](ticket-id-derivation.md#terminal-behavior). Its two declared parts:

- **No-ticket title form**: when `TICKET` is empty (no source matched and the user supplied no valid ID within 3 attempts), use the plain description as the title — no `[...]` prefix. Create the PR; do not abort.
- **Caller notice**: the caller (the agent invoking this protocol) MUST surface a one-line notice alongside the PR URL in its return output, telling the user the PR was created without a ticket prefix and how to fix it. Wording:

  ```
  Created without ticket prefix — edit via `gh pr edit` if needed.
  ```

  This is a caller responsibility, not a `gh pr create` flag — the protocol prescribes the message but does not emit it itself.

**Why this survives the mandatory-ticket rule** (do not prune it as dead code): that rule governs only commits Velo authors going forward and cannot retroactively constrain the range a PR spans, so pre-existing commits on long-lived branches, hand-authored or non-Velo commits, merges from forks, and rebased or cherry-picked history still lack `[TICKET-ID]` — and hard-aborting `gh pr create` on legitimate history is strictly worse than a degraded title.

**The asymmetry with commits is deliberate**: `commit-protocol.md` binds `HALT` — a ticket ID is mandatory for a commit — while this protocol binds `SOFT-FALLBACK`. A commit subject is authored fresh, so Velo controls the input and can demand a ticket. A PR title is derived from existing history Velo may not have authored, so making it mandatory would hard-block exactly the legitimate cases named above. PR titles stay soft by design, not by oversight.

### Building the title

When `TICKET` is non-empty, reduce the description to its bare description text — strip any ticket prefix per [Ticket ID Derivation — Prefix de-duplication](ticket-id-derivation.md#prefix-de-duplication), then strip a leading bracketed type token — and only then apply this protocol's own character sanitization, a separate concern applied after both strips:

```
TITLE="[$TICKET] - $(<description> | <de-dup strip> | <type strip> | tr -cd 'a-zA-Z0-9 ()\[\]/_.,:-')"
```

`<description>` is:
- **Exactly one commit on the branch**: that commit's subject (`git log -1 --format="%s"`). Under the subject format in `commit-protocol.md` that subject is `[TICKET-ID] [TYPE] - description`, so it carries **two** bracketed tokens. Both must come off before the title is assembled — otherwise the title reads `[AGT-123] - [FEAT] - add oauth login`, with a redundant type token and a doubled ` - ` separator, against the format declared above.
- **Multiple commits**: a single imperative-mood summary line, max 72 chars. Do not concatenate commit subjects. Such a line has no bracketed prefix by construction, so both strips are no-ops on it.

`<de-dup strip>` is the `sed -E` expression from Prefix de-duplication. It removes a leading bracketed *ticket* ID plus one following separator and nothing else — by design it leaves `[TYPE]` untouched, a property `commit-protocol.md` depends on. It therefore cannot remove the type token; that is this protocol's job.

`<type strip>` is this protocol's own step. It runs **after** the de-dup strip, because in a conforming subject the ticket precedes the type and both patterns are `^`-anchored:

```
sed -E 's/^\[(FEAT|FIX|REFACTOR|CHORE|DOCS|TEST|PERF|STYLE)\][[:space:]]*-?[[:space:]]*//'
```

It removes a leading bracketed token drawn from the eight-value type enum plus one immediately following separator (whitespace and/or a single hyphen). It deliberately does NOT touch:

- a Conventional-Commits prefix — `feat(auth): add oauth login` has no leading bracketed token and passes through whole;
- a bracketed token outside the type enum (e.g. `[WIP]`);
- a type token anywhere but the start of the line;
- a description with no bracketed token at all — `fix the login crash` passes through unchanged.

Both strips are no-ops on input they do not match, so a pre-existing or hand-authored subject survives intact.

Both strips apply only on the `TICKET`-non-empty path. Under `SOFT-FALLBACK` the description is used as the title as-is (see the no-ticket title form above): nothing is being prefixed, so there is no redundancy to remove, and stripping would only discard information the author wrote.

## Body templates

Pick the body template by inferring the PR type. Sources, in order:
1. The bracketed type token in the most recent commit's subject (`[TICKET-ID] [TYPE] - description`), mapped across the full eight-value type enum:
   - `[FIX]` → bug fix
   - `[FEAT]` → feature
   - `[REFACTOR]`, `[CHORE]`, `[DOCS]`, `[TEST]`, `[PERF]`, `[STYLE]` → other
   - No parseable type token (e.g. a pre-existing or hand-authored commit) → other
2. If unclear and the agent is running interactively, ask: `"Bug fix, feature, or other?"`.

PR bodies do NOT carry a Claude Code attribution line. Commits carry their `Co-Authored-By` tail (see `commit-protocol.md`); PR bodies go out clean.

### Bug fix template (commit type `[FIX]`)

```
## Problem
<derived from diff and commit message — what was broken>

## Fix
<derived from diff — what changed and why>

## Test Case
<derived from diff — tests added or modified; write "N/A" if no test files appear in the diff>
```

### Feature template (commit type `[FEAT]`)

```
## Feature
<derived from diff and commit message — what was added>

## Test Case
<derived from diff — tests added or modified; write "N/A" if no test files appear in the diff>
```

### Other template (commit type `[REFACTOR]`, `[CHORE]`, `[DOCS]`, `[TEST]`, `[PERF]`, `[STYLE]`; multi-commit; no parseable type; or unclear)

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

---
name: commit-protocol
description: Git commit protocol — the `[TICKET-ID] [TYPE] - short description` subject format with its bracketed uppercase type enum, the mandatory-ticket rule (no ticket, no commit), body conventions, multi-line HEREDOC pattern, Co-Authored-By tail, one-logical-change-per-commit rule, secret scans, and git safety rules (no force-push, no --no-verify, no --no-gpg-sign, no amending pushed commits). Ticket-ID lookup, prompting, and the HALT terminal behavior come from ticket-id-derivation.md.
---
# Commit Protocol

**Scope**: how to draft commit messages and create git commits safely. Used by the commit agent's default mode and by any caller that needs to produce a commit by hand.

## Commit message format

Every commit subject is a ticket ID, a bracketed type, and a description:

```
[TICKET-ID] [TYPE] - short description
```

Example: `[AGT-123] [FEAT] - add oauth login`

Rules for the subject line:
- Max 72 chars on the first line.
- `TICKET-ID` is mandatory — see Ticket ID below. There is no scope field.
- `TYPE` is bracketed and uppercase, one of: `[FEAT]`, `[FIX]`, `[REFACTOR]`, `[CHORE]`, `[DOCS]`, `[TEST]`, `[PERF]`, `[STYLE]`.
- A single ` - ` separates the type from the description.
- `description` is imperative mood, lowercase, no trailing period ("add X", not "Added X").

### Ticket ID (mandatory)

The ticket ID is **MANDATORY**. No ticket, no commit. There is no no-ticket subject form and no override flag.

Derive it per [Ticket ID Derivation](ticket-id-derivation.md), which owns the [ID shape](ticket-id-derivation.md#ticket-id-shape), the lookup mechanics, the user prompt, and prefix de-duplication. This protocol binds the two things a consumer owes.

**Source list** — checked in this order, stopping at the first match, per [Source lookup order](ticket-id-derivation.md#source-lookup-order):

1. **Branch name** — `git branch --show-current`
2. **Recent commits reachable from HEAD** — `git log -20 --format=%B`. A commit-count window, deliberately **not** a base range: `git log <base>..HEAD` scopes to commits that already exist, and the commit being drafted does not exist yet. The window therefore walks HEAD's whole ancestry, not just this branch's own commits — on a freshly cut branch every commit in it is inherited from the base branch. That width is the accepted cost of having any commit-backed source at all; the branch name above outranks it whenever both match.
3. **Recent conversation context** — a ticket ID the user named in their most recent message or in the message that triggered this commit. Do not search older history.

Each source is declared here as a bare source command, per [Granularity of a source declaration](ticket-id-derivation.md#granularity-of-a-source-declaration). The extraction pipeline, the candidate patterns, the boundary and exclusion rules, and the first-match cut all live in that skill and are deliberately not restated here.

Within any one source the first match wins ([Multiple matches](ticket-id-derivation.md#multiple-matches)). If all three sources come back empty, fall through to [Prompting the user](ticket-id-derivation.md#prompting-the-user) — the prompt is the fixed final step of the derivation, not a fourth source.

Before prefixing, strip any ticket prefix the description already carries, per [Prefix de-duplication](ticket-id-derivation.md#prefix-de-duplication). Apply it to the description alone and insert `[TYPE]` afterwards; that `sed` strips only a leading bracketed *ticket* ID plus one following separator, so the `[TYPE]` token is never at risk from it.

**Terminal behavior: `HALT`** (see [Terminal behavior](ticket-id-derivation.md#terminal-behavior)). When derivation ends with no ticket ID, do not commit, and surface exactly:

```
Cannot commit without a ticket ID. Supply one (e.g. AGT-123) and retry.
```

The message names an example rather than a pattern on purpose: the authoritative shape lives in [Ticket ID shape](ticket-id-derivation.md#ticket-id-shape), and a user-facing string that restated it could drift out of agreement with it.

The halt fires **before `git add`** — derivation is part of drafting the subject, which happens ahead of staging. What that guarantees is scoped to this protocol: nothing is staged, no commit exists, and no cleanup is required *for staging*. It does not claim the repository is untouched — earlier steps in the calling agent's flow may already have had effects (the commit agent resolves the target branch first, and may have created or checked out a branch to get there). Surfacing that residue is the caller's concern, not this protocol's. Contrast the push-failure case in [Velo Approval Gates — Failure handling](velo-gates.md), which needs bespoke messaging precisely because a local commit already landed.

A refused-ticket halt is an **ordinary commit-agent failure** — plain F1, resolved by the calling state body as "halt and report blocker". Do not define a new failure mode for it.

### When to add a body

Add a blank line after the subject and then a body when the change needs explanation:
- Why the change was made (not just what).
- Trade-offs or alternatives considered.
- Non-obvious side effects.

Skip the body when the subject line is self-explanatory (trivial typo fix, small chore).

### Co-Authored-By tail

When the commit was authored with assistance from Claude Code, append a trailer at the end of the body (preceded by a blank line). Substitute `<model-identifier>` with the actual model identifier (name and version) that authored the commit — the literal in the example below is a placeholder, not a fixed value:

```
Co-Authored-By: <model-identifier> <noreply@anthropic.com>
```

Omit the trailer entirely when the commit is fully human-authored.

## Creating the commit

Use a HEREDOC with real newlines for multi-line messages — do NOT use literal `\n` inside the heredoc:

```
git commit -m "$(cat <<'EOF'
[TICKET-ID] [TYPE] - short description

Optional body here explaining what and why.

Co-Authored-By: <model-identifier> <noreply@anthropic.com>
EOF
)"
```

The `'EOF'` quoting prevents shell expansion inside the body.

## One logical change per commit

A commit captures **one logical change**. If the diff mixes unrelated concerns (e.g. a bug fix plus an unrelated refactor), split it into separate commits — one per logical unit. Stage each unit's files explicitly and commit them independently.

## Pre-commit checks

Before staging:

1. **Secret scan**: scan `git diff` and `git diff --cached` for patterns like `SECRET`, `TOKEN`, `PASSWORD`, `API_KEY`, or `-----BEGIN`. If any match, abort immediately — do not stage, do not commit.
2. **Re-scan after staging**: run the scan again against `git diff --cached` after `git add`. Abort on any match.

Stage files explicitly:

- Use `git add <file>` with named paths.
- Never use `git add .` or `git add -A` — they can pick up `.env`, credentials, build artifacts, or unrelated changes.

## When NOT to commit

- Working tree has no meaningful changes. Report "nothing to commit" and stop. Do not create empty commits.
- The diff contains secrets (see pre-commit checks above).
- The diff mixes unrelated concerns and the caller has not authorized splitting.

## Git safety rules

These rules are non-negotiable. They override caller convenience.

- **Never force-push** (`git push --force`, `git push -f`). If a push is rejected as non-fast-forward, stop and report — do not auto-resolve.
- **Never skip hooks** (`--no-verify`). If a pre-commit or commit-msg hook fails, report the failure and stop. Do not bypass.
- **Never skip signing** (`--no-gpg-sign`, `-c commit.gpgsign=false`). If signing fails, stop and report.
- **Never amend a commit that has been pushed**. Amend is acceptable only for the most recent local-only commit, and only when the caller explicitly asked for an amend. By default, prefer creating a NEW commit over amending.
- **Never amend after a pre-commit hook failure**. The failed commit did not happen; amending would modify the PREVIOUS commit. Fix the underlying issue, re-stage, and create a new commit.
- **Never commit `.env`, credentials, or generated lock-file changes** unless the caller explicitly asked for them.

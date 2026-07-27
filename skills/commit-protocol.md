---
name: commit-protocol
description: Git commit protocol — the `[TICKET-ID] [TYPE] - short description` subject format with its bracketed uppercase type enum, the optional-ticket rule (no derivable ticket → `[TYPE] - short description`, no prompt), body conventions, multi-line HEREDOC pattern, Co-Authored-By tail, one-logical-change-per-commit rule, secret scans, and git safety rules (no force-push, no --no-verify, no --no-gpg-sign, no amending pushed commits). Ticket-ID lookup and the SOFT-FALLBACK terminal behavior come from ticket-id-derivation.md.
---
# Commit Protocol

**Scope**: how to draft commit messages and create git commits safely. Used by the commit agent's default mode and by any caller that needs to produce a commit by hand.

## Commit message format

Every commit subject is a bracketed type and a description, prefixed with a ticket ID when one is derivable:

```
[TICKET-ID] [TYPE] - short description
```

Example: `[AGT-123] [FEAT] - add oauth login`

When no ticket ID is derivable, drop the prefix — nothing takes its place:

```
[TYPE] - short description
```

Example: `[FEAT] - add oauth login`

Rules for the subject line:
- Max 72 chars on the first line.
- `TICKET-ID` is optional — present when derivable, absent otherwise; see Ticket ID below. No placeholder token ever stands in for it. There is no scope field.
- `TYPE` is bracketed and uppercase, one of: `[FEAT]`, `[FIX]`, `[REFACTOR]`, `[CHORE]`, `[DOCS]`, `[TEST]`, `[PERF]`, `[STYLE]`.
- A single ` - ` separates the type from the description.
- `description` is imperative mood, lowercase, no trailing period ("add X", not "Added X").

### Ticket ID (optional)

The ticket ID is **optional**. When derivation finds one, it prefixes the subject; when it finds none, the subject takes the no-ticket form `[TYPE] - short description` — the commit proceeds either way.

Derive it per [Ticket ID Derivation](ticket-id-derivation.md), which owns the [ID shape](ticket-id-derivation.md#ticket-id-shape), the lookup mechanics, and prefix de-duplication. This protocol binds the three things a consumer owes.

**Source list** — checked in this order, stopping at the first match, per [Source lookup order](ticket-id-derivation.md#source-lookup-order):

1. **Branch name** — `git branch --show-current`
2. **Commit subjects on this branch** — `git log <base>..HEAD --format=%s`, where `<base>` is resolved per [Velo Approval Gates — Base-branch detection](velo-gates.md), the same convention `pr-protocol.md` binds for its range. Subjects only, this branch only: the one question a commit-backed source can legitimately answer is "has this branch already been stamped with a ticket?" Bodies are prose — they quote example subjects, reference other tickets, and discuss other work — so scanning them derives IDs the change never had; and an unscoped window (`git log -20`) walks past the branch point into inherited history. The range means "commits on this branch since base": on the base branch itself, or on a branch with no ticketed subject yet, it yields nothing — that is an empty source, not an error, and the lookup continues to the next source.
3. **Recent conversation context** — a ticket ID the user named in their most recent message or in the message that triggered this commit. Do not search older history.

Each source is declared here as a bare source command, per [Granularity of a source declaration](ticket-id-derivation.md#granularity-of-a-source-declaration). The extraction pipeline, the candidate patterns, the boundary and exclusion rules, and the first-match cut all live in that skill and are deliberately not restated here.

Within any one source the first match wins ([Multiple matches](ticket-id-derivation.md#multiple-matches)).

**Prompt participation: declined.** This protocol does not run [Prompting the user](ticket-id-derivation.md#prompting-the-user): when all three sources come back empty, the terminal behavior below fires immediately — the user is not asked for a ticket ID.

Before prefixing, strip any ticket prefix the description already carries, per [Prefix de-duplication](ticket-id-derivation.md#prefix-de-duplication). Apply it to the description alone and insert `[TYPE]` afterwards; that `sed` strips only a leading bracketed *ticket* ID plus one following separator, so the `[TYPE]` token is never at risk from it.

**Terminal behavior: `SOFT-FALLBACK`** (see [Terminal behavior](ticket-id-derivation.md#terminal-behavior)). Its two declared parts:

- **No-ticket subject form**: `[TYPE] - short description` — the same subject with the ticket prefix dropped. Do not halt, do not insert a placeholder token; create the commit.
- **Caller notice**: the agent creating the commit surfaces this one line alongside its normal report, so the user knows the prefix is missing:

  ```
  Committed without ticket prefix — no ticket ID was derivable.
  ```

Derivation still runs **before `git add`** — it is part of drafting the subject, which happens ahead of staging.

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

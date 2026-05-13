---
name: commit-protocol
description: Git commit protocol — message format, body conventions, multi-line HEREDOC pattern, Co-Authored-By tail, one-logical-change-per-commit rule, secret scans, and git safety rules (no force-push, no --no-verify, no --no-gpg-sign, no amending pushed commits). PR-title ticket-prefix policy lives in pr-protocol.md.
---
# Commit Protocol

**Scope**: how to draft commit messages and create git commits safely. Used by the commit agent's default mode and by any caller that needs to produce a commit by hand.

## Commit message format

Follow **Conventional Commits**:

```
type(scope): short description
```

Rules for the subject line:
- Max 72 chars on the first line.
- `type` is one of: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `style`.
- `scope` is the affected module, file, or domain (e.g. `auth`, `api`, `db`).
- `description` is imperative mood, lowercase, no trailing period ("add X", not "Added X").

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
type(scope): short description

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

## Telemetry

Commit-protocol does not emit telemetry directly. The calling agent or state emits events per its own taxonomy.

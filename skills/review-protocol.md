---
name: review-protocol
description: Shared code review protocol for reviewer agents. Five review axes (correctness, readability, architecture, security, performance), severity taxonomy, output format.
---
# Review Protocol

This is the shared review protocol referenced by all reviewer agents. It defines the review axes, severity taxonomy, reading order, output format, and guiding principle that every reviewer must apply consistently.

## The 5 Review Axes

1. **Correctness** — Does the code do what it claims? Edge cases, error paths, off-by-ones, race conditions, spec alignment.
2. **Readability & Simplicity** — Naming, control flow, dead code, abstractions justified by their cost.
3. **Architecture** — Pattern fit, module boundaries, dependency direction (no circular deps), duplication.
4. **Security** — Input validation, secrets handling, authn/authz, parameterized queries, untrusted input at boundaries.
5. **Performance** — N+1 queries, unbounded loops, blocking ops in hot paths, missing pagination, unnecessary re-renders.

## Severity Taxonomy

- **Critical** — Must fix before merge. Blocks approval.
- **Important** — Should fix before merge unless explicitly deferred with rationale.
- **Nit** — Style or minor preference. Author may accept or decline.
- **Optional** — Suggested improvement, non-blocking.
- **FYI** — Observation, no action required.

## Test-First Reading Rule

Read tests before implementation. Tests reveal intended behavior and surface coverage gaps immediately. If tests are missing or misleading, note it under the relevant axis before reading the implementation.

## "Improves Health, Not Perfection" Principle

Approve changes that leave the codebase healthier than before. Do not block on perfection. Do not require unrelated cleanup. If a PR moves the codebase forward on balance, approve it and log non-blocking items as Nit, Optional, or FYI.

## Uniform Output Format

All reviewers must structure their findings as follows:

```
## Review verdict: PASS | FAIL

## Findings by axis

### Correctness
- [Severity] Finding description (file:line if applicable)
- ...

### Readability & Simplicity
- ...

### Architecture
- ...

### Security
- ...

### Performance
- ...

## Notes
- Test-first read: <what the tests revealed about intent / coverage gaps>
- Health delta: <does this PR improve or degrade codebase health overall?>
```

Under any axis where no issues were found, write "No findings." Under any axis that genuinely does not apply to the domain being reviewed, write "Not applicable for this domain." This ensures every axis was actively considered, not silently skipped.

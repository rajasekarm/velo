---
name: requirement-interpretation
description: Decision rule for handling semantically ambiguous terms in a request before announcing a plan. Three-branch signal-count rule: state-and-proceed on exactly one obvious signal, state-and-proceed-with-flag on partial match, hard-stop on zero or multiple competing signals.
---
# Requirement Interpretation

**Scope:** How to handle terms in a request whose meaning is not pinned down by the request itself — before any plan is announced, any agent is spawned, or any code is written.

## When to apply

A term in the request qualifies as an ambiguity worth surfacing if its interpretation could change *which user sees what, which code path runs, or which data gets touched*.

Apply this rule once per such term, before announcing the plan.

## Decision rule

- **Exactly one obvious signal in the codebase** maps to the term → state the interpretation in the Assumptions ledger and proceed.
- **Partial match (one signal nearly fits but doesn't fully resolve the term)** → you may state the interpretation and proceed IF the worst case is a flagged misinterpretation the user will catch at announcement time. Otherwise stop and ask.
- **Zero signals OR multiple competing signals** → STOP and ask the user before announcing the plan. Do NOT pick the nearest grep hit. Do NOT proceed on inference.

## Anti-pattern

A grep that turns up no matching signal is NOT permission to redefine the term. It is information to bring back to the user via the Assumptions ledger.

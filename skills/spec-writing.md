# Spec Writing

**Scope:** Technical specifications, implementation plans, architecture decisions.

## Rules
- A spec answers: what are we building, why, how, and how do we know it works
- Write for the implementer — they should be able to build from the spec without asking questions
- Every spec has a single decision-maker and clear scope boundary
- No hand-waving — if a section says "TBD", it's not ready for implementation
- Diagrams over paragraphs for data flow, system interactions, and state machines

## Spec Structure
1. **Summary** — One paragraph. What and why.
2. **Background** — Context the reader needs. Link to prior art, related specs, relevant code.
3. **Goals / Non-goals** — Explicit. Non-goals prevent scope creep.
4. **Detailed Design** — The how. API contracts, data models, algorithms, state transitions.
5. **API Contracts** — Request/response shapes, error codes, authentication requirements.
6. **Data Model** — Schema changes, migrations, storage considerations.
7. **Edge Cases** — Enumerate and decide: handle, defer, or explicitly reject.
8. **Security Considerations** — Auth, data access, input validation, rate limiting.
9. **Testing Strategy** — What gets unit tested, integration tested, e2e tested.
10. **Rollout Plan** — Feature flags, migration steps, rollback procedure.
11. **Open Questions** — Numbered. Each must be resolved before implementation starts.

## Quality Checks
- Can an engineer implement this without further clarification?
- Are all API contracts defined with request/response types?
- Are error states and failure modes documented?
- Is the scope achievable in the stated timeline?
- Are there circular dependencies or missing prerequisites?

## Anti-Patterns
- Specs that describe UI without defining the data behind it
- "The system should handle errors gracefully" — vague, untestable
- Mixing requirements with implementation details in the same section
- Specs longer than needed — brevity is a feature

---
name: spec-quality-check
description: Consumer-side adversarial audit of a spec (PRD or task-spec) before any design or implementation begins. Encodes a 5-finding taxonomy and 5 quality criteria. Returns STATUS:SPEC_OK or STATUS:SPEC_REWORK_NEEDED with prioritized findings. Loaded by the agent that consumes the spec.
---
# Spec Quality Check

The agent that *consumes* the spec is the natural auditor. The Tech Lead consumes the PRD or task-spec to design the build, so the TL audits it. This skill encodes how.

**Framing — adversarial, not validating.** Read the spec looking for failure modes that will hurt the downstream build: ambiguity that will be resolved silently and wrongly; conflicts that will surface as bugs; gaps where requirements are missing entirely. Do NOT look for things to praise. Do NOT produce theater findings to look thorough. **Zero findings is the expected outcome when the spec is clean** — return `STATUS: SPEC_OK` and stop.

## Finding taxonomy

Five finding kinds. Each finding you raise MUST be one of these:

| Kind | One-line description | When it applies |
|---|---|---|
| **ambiguity** | A requirement admits more than one reasonable interpretation, and the choice changes user-visible behavior or which code runs. | Phrases like "quickly", "the user", "appropriate", "as needed" — anything that requires guessing intent. |
| **conflict** | Two requirements (or one requirement and a stated constraint) cannot both be true at the same time. | Requirement A says "no auth required"; requirement B says "log the calling user". |
| **completeness** | A requirement implies a behavior whose details are not specified, and the omission will force the builder to invent the contract. | A "delete user" requirement that says nothing about cascade behavior, soft-delete vs hard-delete, audit trail. |
| **accepted-scenario** | A positive (happy-path) scenario the spec asserts as in-scope is not represented by any acceptance criterion. | Spec says "users can export reports" but no AC covers the export flow. |
| **rejected-scenario** | A negative scenario (input the system should reject, state it should refuse to enter) is not represented by any acceptance criterion. | Spec says "valid emails only" but no AC describes what happens for invalid ones. |

## Quality criteria

When auditing the spec, evaluate it against five criteria. A finding is raised when the spec fails one of these:

1. **Testable** — Each requirement can be verified by an observable check (a test, a manual reproduction, or a log assertion). Vague outcomes ("fast", "intuitive", "robust") fail this and are ambiguities.
2. **Solution-free** — The spec describes *what* and *why*, not *how*. Implementation choices (specific libraries, frameworks, file layouts) leaking into a spec are not findings to escalate — but they ARE noted if they constrain the EDD prematurely.
3. **Unambiguous** — Every load-bearing term has exactly one reasonable interpretation in the context of this product. Terms that don't pass this test are ambiguities.
4. **Consistent** — No two requirements contradict each other; no requirement contradicts a stated constraint, non-goal, or assumption. Contradictions are conflicts.
5. **Complete** — Every in-scope behavior the spec implies has at least one acceptance criterion. Gaps are completeness, accepted-scenario, or rejected-scenario findings depending on which leg is missing.

## Severity rules

Two severity bands. The band determines the return status.

- **Blocking** — raised by `conflict` or `ambiguity` findings. Returns `STATUS: SPEC_REWORK_NEEDED`. The downstream build cannot start safely without resolving these — the builder will either guess (and likely guess wrong) or stall.
- **Advisory** — raised by `completeness`, `accepted-scenario`, or `rejected-scenario` findings. Returns `STATUS: SPEC_OK` with the advisory findings noted. The build can proceed; the gaps are surfaced so the caller can decide whether to revise the spec before build or accept the gap and move on.

If a single audit produces both blocking and advisory findings, the blocking band wins — return `STATUS: SPEC_REWORK_NEEDED` and list both groups.

## Output format

Max **7 findings** total per audit, prioritized by severity (blocking before advisory) and then by impact on the build. If there are more than 7 candidate findings, pick the 7 highest-leverage and drop the rest — flag in the output that more were observed.

When there are zero findings, output exactly:

```
STATUS: SPEC_OK
```

and stop. No preamble, no "looks good", no list of what you checked.

When there are findings, output:

```
STATUS: SPEC_REWORK_NEEDED    (or SPEC_OK if only advisory findings)

Findings:
1. [<kind>] <one-sentence statement of the issue>
   Proposed revision: "<the exact replacement text the spec author should paste in>"
2. [<kind>] ...
   Proposed revision: "..."
...
```

Each finding has exactly two lines:
- Line 1: `[<kind>]` followed by a one-sentence statement of the issue (cite the offending phrase verbatim where possible).
- Line 2: `Proposed revision: "<verbatim replacement>"`. The proposed revision is what the spec should literally say — it gets pasted back to the user as the option label in the audit-rework loop, so it must be drop-in-ready.

If you observed more than 7 candidate findings, add one final line: `(N additional findings observed, listed by severity — request a re-audit after the top 7 are resolved.)`.

## Return contract

The caller (TL workflow Step 0; `/velo:task`'s `SPEC_AUDIT` state) reads the first line of your output. The contract is:

- First line is `STATUS: SPEC_OK` → caller proceeds to the next step. Advisory findings, if any, are surfaced to the user but do not block.
- First line is `STATUS: SPEC_REWORK_NEEDED` → caller stops, surfaces the findings, and routes back to the spec author (PM) for revision. The caller does not silently revise the spec on the author's behalf.

Do not invent new status strings. Do not append qualifiers (no `STATUS: SPEC_OK_WITH_NOTES`, no `STATUS: SPEC_REWORK_NEEDED_OPTIONAL`). The two strings above are the entire contract.

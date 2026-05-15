# Velo — Workflow

## `/velo:new` — New features

Structured workflow with mandatory planning and approval gates before any code is written.

```mermaid
flowchart TD
    A([Start]) --> PM[Product Manager\nwrites prd.md]
    PM --> A1{Your approval}
    A1 -->|changes| PM
    A1 -->|approved| TL[Tech Lead\nStep 0 spec audit\n+ writes engineering-design-doc.md\n+ task-breakdown.md]
    TL -->|SPEC_REWORK_NEEDED| PM
    TL --> TLV{task-breakdown.md\nexists?}
    TLV -->|missing| TL
    TLV -->|ok| REV[Distinguished Engineer\nreviews EDD]
    REV -->|REVISE cycle 1-2| TL
    REV -->|cycle 3| A2C{Your call}
    A2C -->|extend| TL
    A2C -->|accept| A2{Your approval}
    REV -->|APPROVE| A2{Your approval}
    A2 -->|changes| TL
    A2 -->|approved| BUILD

    subgraph BUILD [Build — ordered by task-breakdown.md]
        direction LR
        DB[DB Engineer] --> BE[BE Engineer]
        INF[Infra Engineer\nif needed]
        FE[FE Engineer\nbuilds against EDD]
    end

    BUILD --> TEST[Automation Engineer\nTests]
    TEST --> REVIEW[All reviewers\nin parallel]
    REVIEW -->|any fail cycle 1-2| REWORK[Rework\nrelevant builders]
    REWORK --> REVIEW
    REVIEW -->|cycle 3| A3C{Your call}
    A3C -->|extend| REWORK
    A3C -->|accept| A3{Your approval}
    REVIEW -->|all pass| A3{Your approval}
    A3 -->|approved| COMMIT[Commit Agent]
    A3 -->|hold| REWORK
    COMMIT --> A4{Push?}
    A4 -->|approved| PUSH([Push to remote])
    A4 -->|hold| DONE1([Done — local commit only])
```

## `/velo:task` — Day-to-day tasks

Lightweight path for bug fixes, refactors, and small changes. No planning phase.

```mermaid
flowchart TD
    A([Start]) --> ANN[Announce plan\nuser approval]
    ANN --> SA[SPEC_AUDIT\nPM Mode: task-spec\n+ TL Step 0 audit]
    SA -->|SPEC_REWORK_NEEDED cycle 1-2| SA
    SA -->|SPEC_REWORK_NEEDED cycle 3| A0S{Your call}
    A0S -->|ship-with-gaps| BUILD
    A0S -->|cut scope| ANN
    A0S -->|abandon| ENDS([Abandon])
    SA -->|SPEC_OK| BUILD[Relevant builders]
    BUILD --> TEST[Automation Engineer\nTests]
    TEST --> REVIEW[All reviewers\nin parallel]
    REVIEW -->|any fail cycle 1-2| REWORK[Rework\nrelevant builders]
    REWORK --> REVIEW
    REVIEW -->|cycle 3| A0C{Your call}
    A0C -->|extend| REWORK
    A0C -->|accept| A1{Your approval}
    A0C -->|abandon| END0([Abandon])
    REVIEW -->|all pass| A1{Your approval}
    A1 -->|approved| COMMIT[Commit Agent]
    A1 -->|hold| REWORK
    COMMIT --> A2{Push?}
    A2 -->|approved| PUSH([Push to remote])
    A2 -->|hold| DONE0([Done — local commit only])
```

## `/velo:hunt` — Structured debug loop

Symptom → hypothesis → root cause → handoff. No planning phase, no code written. Hunt ends with a confirmed root cause and a prose handoff brief, then routes to `/velo:task` (or `/velo:new` for infra/schema fixes).

> **Operator note**: Hunt reads source files and git history. Bash is constrained to `git log`/`git blame` — verify your `settings.json` allowlist before use on sensitive repos.

```mermaid
flowchart TD
    A([Start]) --> CL[Classify input]
    CL -->|specific defect| CTX[Gather context\n1–3 clarifying questions]
    CL -->|root cause known| TASK[Redirect → /velo:task]
    CL -->|conceptual| YO[Redirect → /velo:yo]
    CTX --> HYP[Propose hypotheses\nH1 / H2 / H3]
    HYP --> LOOP[Investigation loop\nRead → update Hunt board]
    LOOP -->|soft cap hit| ASK{Re-rank, keep going,\nor abandon?}
    ASK -->|re-rank| LOOP
    ASK -->|abandon| ABANDON[Abandon summary]
    LOOP -->|evidence gate satisfied| RC[Confirm root cause\nfile:line + mechanism + trigger]
    RC --> FIX[Fix proposal + handoff brief]
    FIX --> HAND{Hand off}
    HAND -->|/velo:task| TASK2[Start /velo:task]
    HAND -->|/velo:new| NEW[Start /velo:new]
    HAND -->|fix myself| DONE([Done])
```

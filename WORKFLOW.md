# Velo — Workflow

## `/velo:new` — New features

Structured workflow with mandatory planning and approval gates before any code is written.

```mermaid
flowchart TD
    A([Start]) --> PM[Product Manager\nwrites prd.md]
    PM --> A1{Your approval}
    A1 -->|changes| PM
    A1 -->|approved| TL[Tech Lead\nwrites engineering-design-doc.md\n+ task-breakdown.md]
    TL --> TLV{task-breakdown.md\nexists?}
    TLV -->|missing| TL
    TLV -->|ok| REV[Distinguished Engineer\n+ GPT Reviewer in parallel]
    REV -->|REVISE cycle 1-2| TL
    REV -->|cycle 3| A2C{Your call}
    A2C -->|extend| TL
    A2C -->|accept| A2{Your approval}
    REV -->|both APPROVE| A2{Your approval}
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
    A3C -->|accept| LEARN{Rework occurred?}
    REVIEW -->|all pass| LEARN{Rework occurred?}
    LEARN -->|yes| LA[Learnings Agent\nproposes additions]
    LA --> A3{Your approval}
    LEARN -->|no| A3
    A3 -->|approved| COMMIT[Commit Agent]
    A3 -->|hold| REWORK
```

## `/velo:task` — Day-to-day tasks

Lightweight path for bug fixes, refactors, and small changes. No planning phase.

```mermaid
flowchart TD
    A([Start]) --> BUILD[Relevant builders]
    BUILD --> TEST[Automation Engineer\nTests]
    TEST --> REVIEW[All reviewers\nin parallel]
    REVIEW -->|any fail| REWORK[Rework\nrelevant builders]
    REWORK --> REVIEW
    REVIEW -->|all pass| LEARN{Rework occurred?}
    LEARN -->|yes| LA[Learnings Agent\nproposes additions]
    LA --> A1{Your approval}
    LEARN -->|no| A1
    A1 -->|approved| COMMIT[Commit Agent]
    A1 -->|hold| REWORK
```

## Learning loop

After any rework cycle, the Learnings Agent extracts codebase-specific patterns from reviewer findings and proposes additions to `.velo/learnings/`. You approve before anything is written. The team gets better with every task.

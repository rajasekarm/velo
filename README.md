<p align="center">
  <img src="assets/logo.svg" alt="Velo" />
</p>

<p align="center"><b>Rajasekar's high-velocity engineering team, portable across Claude Code and Codex.</b></p>

Velo is an agentic engineering team — a full squad of specialised role agents coordinated by an Engineering Manager. Describe what you want built. Velo plans it, gets your approval at the right gates, runs work in parallel, and ships with review baked in.

## Why Velo?

- **Approval-gated**: PRD before technical design. Engineering design doc before code. Review results before commit. Nothing ships without your sign-off.
- **Explicit task ordering**: Tech Lead produces a `task-breakdown.md` alongside the engineering design doc — who does what, in what order, what can run in parallel. Build phase executes it directly, no guessing.
- **Bounded rework loop**: Reviewers that fail send builders back with findings inline. Cycle 1 fixes Critical + Significant, cycle 2 fixes remaining Critical only. Capped at 3 cycles — if issues remain, you decide: extend, accept as-is, or abandon.
- **Spec audited before design**: Every PRD passes an adversarial spec-quality audit (Tech Lead, Step 0) before any design or code begins. Blocking ambiguities and conflicts route back to the PM with proposed revisions — never silently guessed by a builder.
- **Observability baked in**: Every BE task is reviewed by BE Reviewer and Observability Engineer — non-optional. Security review is available on-demand via `/security-review`.
- **Right model class for the job**: Tech lead and architecture reviewers use `deep-reasoning`. PM, builders, and reviewers use `balanced`. `ADAPTER.md` maps these classes to the active runtime.

## The team

### Leadership

| Agent | Model Class | Responsibility |
|---|---|---|
| **Velo** (Engineering Manager) | — | Orchestrates the team, owns delivery, never implements |
| **Distinguished Engineer** | deep-reasoning | Peer to EM — sets technical bar, reviews architecture |

### Planners

| Agent | Model Class | Responsibility |
|---|---|---|
| **Product Manager** | balanced | Requirements, user stories, scope decisions, PRD |

### Engineering Lead

| Agent | Model Class | Responsibility |
|---|---|---|
| **Tech Lead** | deep-reasoning | Technical design, API surface, engineering design doc |

### Specialists

| Agent | Model Class | Responsibility |
|---|---|---|
| **Observability Engineer** | balanced | Implements observability infra — reviews all BE tasks for metrics, logging, tracing gaps |
| **Security Engineer** | balanced | On-demand vulnerability review (via `/security-review`); not auto-attached to BE/FE reviews |

### Builders

| Agent | Model Class | Responsibility |
|---|---|---|
| **Frontend Engineer** | balanced | React components, routing, client-side logic |
| **Backend Engineer** | balanced | APIs, business logic, Node.js services |
| **Database Engineer** | balanced | Schema design, migrations, query optimisation |
| **Infrastructure Engineer** | balanced | Docker, Kubernetes, AWS, Kafka, CI/CD |
| **Automation Engineer** | balanced | Playwright e2e tests, Vitest unit tests |

### Reviewers

| Agent | Model Class | Responsibility |
|---|---|---|
| **Frontend Reviewer** | balanced | UI quality, component correctness, React patterns |
| **Backend Reviewer** | balanced | API design, error handling, Node.js correctness |
| **Database Reviewer** | balanced | Schema correctness, index coverage, query safety |
| **Infrastructure Reviewer** | balanced | Config hygiene, security posture, cost |
| **Automation Reviewer** | balanced | Test coverage, reliability, flakiness |

### Utilities

| Agent | Model Class | Responsibility |
|---|---|---|
| **Commit** | balanced | Analyse diff, generate commit message, create git commit |
| **Learnings Agent** | balanced | Extract codebase-specific learnings after rework cycles |

## How it works

See [WORKFLOW.md](WORKFLOW.md) for detailed flow diagrams.

### `/velo:new` — New features
Structured workflow: PM → Tech Lead → DE review → Build → Review → Commit. Mandatory planning and approval gates before any code is written.

### `/velo:task` — Day-to-day tasks
Single adaptive delegated flow for bug fixes, refactors, and small changes: validate scope, announce the plan with an inline assumptions ledger, then build, review, and ship. Underspecified or net-new work escalates to `/velo:new`.

### `/velo:yo` — Advisory
Ask Velo anything. Get a direct answer, a TL + DE panel, or a full PM + TL + DE panel depending on the question.

### `/velo:hunt` — Structured debug loop
Symptom → hypothesis → root cause → handoff. Tight, iterative debugging mode that ends with a confirmed root cause and a handoff brief to `/velo:task` — or an explicit dead-end with what was ruled out.

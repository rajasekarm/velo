<p align="center">
  <img src="assets/logo.svg" alt="Velo" />
</p>

<p align="center"><b>Rajasekar's high-velocity engineering team, running on Claude Code.</b></p>

Velo is an agentic engineering team — a full squad of specialised Claude agents coordinated by an Engineering Manager. Describe what you want built. Velo plans it, gets your approval at the right gates, runs work in parallel, and ships with review baked in.

## Why Velo?

- **Approval-gated**: PRD before technical design. Engineering design doc before code. Review results before commit. Nothing ships without your sign-off.
- **Explicit task ordering**: Tech Lead produces a `task-breakdown.md` alongside the engineering design doc — who does what, in what order, what can run in parallel. Build phase executes it directly, no guessing.
- **Bounded rework loop**: Reviewers that fail send builders back with findings inline. Cycle 1 fixes Critical + Significant, cycle 2 fixes remaining Critical only. Capped at 3 cycles — if issues remain, you decide: extend, accept as-is, or abandon.
- **Spec-check before review**: Every build is verified against the PRD before reviewers run. Acceptance criteria are mapped to diff evidence; unmet criteria trigger rework. Capped at 2 automatic cycles — on the 3rd, you decide: extend, accept-with-FYI, or abandon. Ambiguous PRDs route back to the PM, not the builder.
- **Dual independent review**: Engineering design docs are reviewed by both the Distinguished Engineer (Claude opus) and an External Reviewer (gpt-5.4 via Codex CLI) in parallel — two different models, two independent perspectives before build starts.
- **Security and observability baked in**: Every BE task is reviewed by BE Reviewer, Security Engineer, and Observability Engineer. Every FE task gets Security review. Non-optional.
- **Right model for the job**: Tech lead and architecture reviewers run on opus. PM, builders, and reviewers run on sonnet.

## The team

### Leadership

| Agent | Model | Responsibility |
|---|---|---|
| **Velo** (Engineering Manager) | — | Orchestrates the team, owns delivery, never implements |
| **Distinguished Engineer** | opus | Peer to EM — sets technical bar, reviews architecture |
| **External Distinguished Engineer** | gpt-5.4 | Independent review of engineering design doc via Codex CLI, runs parallel to Distinguished Engineer |

### Planners

| Agent | Model | Responsibility |
|---|---|---|
| **Product Manager** | sonnet | Requirements, user stories, scope decisions, PRD |

### Engineering Lead

| Agent | Model | Responsibility |
|---|---|---|
| **Tech Lead** | opus | Technical design, API surface, engineering design doc |

### Specialists

| Agent | Model | Responsibility |
|---|---|---|
| **Observability Engineer** | sonnet | Implements observability infra — reviews all BE tasks for metrics, logging, tracing gaps |
| **Security Engineer** | sonnet | Reviews all BE and FE tasks for vulnerabilities |

### Builders

| Agent | Model | Responsibility |
|---|---|---|
| **Frontend Engineer** | sonnet | React components, routing, client-side logic |
| **Backend Engineer** | sonnet | APIs, business logic, Node.js services |
| **Database Engineer** | sonnet | Schema design, migrations, query optimisation |
| **Infrastructure Engineer** | sonnet | Docker, Kubernetes, AWS, Kafka, CI/CD |
| **Automation Engineer** | sonnet | Playwright e2e tests, Vitest unit tests |

### Reviewers

| Agent | Model | Responsibility |
|---|---|---|
| **Frontend Reviewer** | sonnet | UI quality, component correctness, React patterns |
| **Backend Reviewer** | sonnet | API design, error handling, Node.js correctness |
| **Database Reviewer** | sonnet | Schema correctness, index coverage, query safety |
| **Infrastructure Reviewer** | sonnet | Config hygiene, security posture, cost |
| **Automation Reviewer** | sonnet | Test coverage, reliability, flakiness |

### Utilities

| Agent | Model | Responsibility |
|---|---|---|
| **Commit** | sonnet | Analyse diff, generate commit message, create git commit |

## How it works

See [WORKFLOW.md](WORKFLOW.md) for detailed flow diagrams.

### `/velo:new` — New features
Structured workflow: PM → Tech Lead → Dual review → Build → Review → Commit. Mandatory planning and approval gates before any code is written.

### `/velo:task` — Day-to-day tasks
Lightweight path for bug fixes, refactors, and small changes. No planning phase — straight to build and review.

### `/velo:yo` — Advisory
Ask Velo anything. Get a direct answer, a TL + DE panel, or a full PM + TL + DE panel depending on the question.

### `/velo:hunt` — Structured debug loop
Symptom → hypothesis → root cause → handoff. Tight, iterative debugging mode that ends with a confirmed root cause and a handoff brief to `/velo:task` — or an explicit dead-end with what was ruled out.

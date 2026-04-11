<p align="center">
  <img src="assets/logo.svg" alt="Velo" />
</p>

<p align="center"><b>Rajasekar's high-velocity engineering team, running on Claude Code.</b></p>

Velo is an agentic engineering team — a full squad of specialised Claude agents coordinated by an Engineering Manager. Describe what you want built. Velo plans it, gets your approval at the right gates, runs work in parallel, and ships with review baked in.

## How it works

### New features — `/velo:new`

Structured workflow with mandatory planning and two approval gates before any code is written.

```
PM → PRD → [your approval]
         → Tech Lead → contract.md
         → Distinguished Engineer → review
         → [your approval]
         → Build: DB→BE | Infra (if needed) | FE (parallel)
         → Tests → Review → Commit
```

1. **Product Manager** defines requirements, user stories, and scope — writes `prd.md`
2. **You approve the PRD** before technical design begins
3. **Tech Lead** reads the PRD and codebase, designs the API contract — writes `contract.md`
4. **Distinguished Engineer** (peer to EM) reviews the contract for architecture, integration risks, and long-term concerns
5. **You approve the contract** before any implementation starts
6. **Build phase** runs two streams in parallel:
   - Backend: DB Engineer → BE Engineer (sequential — schema before implementation)
   - Frontend: FE Engineer (independent — builds against contract using mocks)
   - Infra Engineer spawned if needed
7. **Review phase** runs all relevant reviewers in parallel — including Security and Observability on every BE task
8. **Commit** only when you ask to ship end-to-end

All planning artifacts are stored per-task in `.velo/tasks/<slug>/`:
- `prd.md` — Product Manager output
- `contract.md` — Tech Lead API contract

### Day-to-day tasks — `/velo:task`

Lightweight path for bug fixes, refactors, and small changes. No planning phase, no approval gates. Assess → build → review → done.

## The team

### Leadership

| Role | Agent | Responsibility |
|---|---|---|
| **Engineering Manager** | Velo | Orchestrates the team, owns delivery, never implements |
| **Distinguished Engineer** | Distinguished Engineer | Peer to EM — sets technical bar, reviews architecture |

### Planners

| Role | Agent | Responsibility |
|---|---|---|
| **Planner** | Product Manager | Requirements, user stories, scope decisions, PRD |

### Engineering Lead

| Role | Agent | Responsibility |
|---|---|---|
| **Engineering Lead** | Tech Lead | API contract design, technical decisions before build |

### Specialists

| Role | Agent | Responsibility |
|---|---|---|
| **Specialist** | Observability Engineer | Prometheus, Grafana, Jaeger, Pino+Loki — implements observability infra and reviews all BE tasks for metrics, logging, tracing gaps |
| **Specialist** | Security Engineer | OWASP, auth/authz, input validation — reviews all BE and FE tasks for vulnerabilities |

### Builders

| Role | Agent | Responsibility |
|---|---|---|
| **Builder** | Frontend Engineer | React components, routing, client-side logic |
| **Builder** | Backend Engineer | APIs, business logic, Node.js services |
| **Builder** | Database Engineer | Schema design, migrations, query optimisation |
| **Builder** | Infrastructure Engineer | Docker, Kubernetes, AWS, Kafka, CI/CD |
| **Builder** | Automation Engineer | Playwright e2e tests, Vitest unit tests |

### Reviewers

| Role | Agent | Responsibility |
|---|---|---|
| **Reviewer** | Frontend Reviewer | UI quality, component correctness, React patterns |
| **Reviewer** | Backend Reviewer | API design, error handling, Node.js correctness |
| **Reviewer** | Database Reviewer | Schema correctness, index coverage, query safety |
| **Reviewer** | Infrastructure Reviewer | Config hygiene, security posture, cost |
| **Reviewer** | Automation Reviewer | Test coverage, reliability, flakiness |

### Utilities

| Role | Agent | Responsibility |
|---|---|---|
| **Utility** | Commit | Analyse diff, generate commit message, create git commit |

## Skills

Each agent reads domain-specific skill files before starting work — conventions, rules, and patterns they must follow.

| Skill | Used by |
|---|---|
| `skills/react.md` | FE Engineer, FE Reviewer |
| `skills/nodejs.md` | BE Engineer, BE Reviewer |
| `skills/postgresql.md` | DB Engineer, DB Reviewer |
| `skills/clickhouse.md` | DB Engineer, DB Reviewer |
| `skills/kafka.md` | Infra Engineer, Infra Reviewer |
| `skills/docker.md` | Infra Engineer, Infra Reviewer |
| `skills/kubernetes.md` | Infra Engineer, Infra Reviewer |
| `skills/aws.md` | Infra Engineer, Infra Reviewer |
| `skills/ci-cd.md` | Infra Engineer, Infra Reviewer |
| `skills/playwright.md` | Automation Engineer, Automation Reviewer |
| `skills/vitest.md` | Automation Engineer, Automation Reviewer |
| `skills/prometheus.md` | Observability Engineer |
| `skills/grafana.md` | Observability Engineer |
| `skills/opentelemetry.md` | Observability Engineer |
| `skills/logging.md` | Observability Engineer |
| `skills/security.md` | Security Engineer |
| `skills/product-management.md` | Product Manager |

## Why Velo?

- **Approval-gated**: You approve the PRD before technical design starts. You approve the contract before code is written. Nothing is built without your sign-off on what and how.
- **Contract-first parallelism**: Tech Lead defines the API surface before build. Backend and frontend build simultaneously against the same contract — no blocking, no rework.
- **Security and observability baked in**: Every BE task is reviewed by three agents — BE Reviewer, Security Engineer, and Observability Engineer. Every FE task gets a Security review. These aren't optional.
- **Right engineer for the job**: Scoped roles, domain-specific knowledge. Nobody wanders outside their lane.
- **You set direction, Velo handles coordination**: One task in, a shipped feature out.

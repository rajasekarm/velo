<p align="center">
  <img src="assets/logo.svg" alt="Velo" />
</p>

<p align="center"><b>Rajasekar's high-velocity engineering team, portable across Claude Code and Codex.</b></p>

Velo is an agentic engineering team — a full squad of specialised role agents coordinated by an Engineering Manager. Describe what you want built. Velo plans it, gets your approval at the right gates, runs work in parallel, and ships with review baked in.

## Why Velo?

- **Approval-gated**: PRD before technical design. Engineering design doc before code. Review results before commit. Nothing ships without your sign-off.
- **Explicit task ordering**: Tech Lead produces the `task-breakdown.md` carrier alongside the engineering design doc — milestones, who does what, in what order, what can run in parallel. The build loop executes it directly, one milestone at a time, no guessing.
- **Bounded rework loop**: Reviewers that fail send builders back with findings inline. Cycle 1 fixes Critical + Significant, cycle 2 fixes remaining Critical only. Capped at 3 cycles — if issues remain, you decide: extend, accept as-is, or abandon. The cap is **per milestone**, not per run: the counter resets when the next milestone enters review, so an n-milestone run budgets up to 3 cycles in each of them.
- **Spec-check before review**: Every build is verified against the PRD before reviewers run. Acceptance criteria are mapped to diff evidence; unmet criteria trigger rework. Capped at 2 automatic cycles — on the 3rd, you decide: extend, accept-with-FYI, or abandon. Ambiguous PRDs route back to the PM, not the builder.
- **Observability baked in**: Every BE task is reviewed by BE Reviewer and Observability Engineer — non-optional. Security review is available on-demand via `/security-review`.
- **Right model class for the job**: Tech lead and architecture reviewers use `deep-reasoning`. Builders use `build`. PM, reviewers, and utilities use `balanced`. `ADAPTER.md` maps these classes to the active runtime.

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
| **Frontend Engineer** | build | React components, routing, client-side logic |
| **Backend Engineer** | build | APIs, business logic, Node.js services |
| **Database Engineer** | build | Schema design, migrations, query optimisation |
| **Infrastructure Engineer** | build | Docker, Kubernetes, AWS, Kafka, CI/CD |
| **Automation Engineer** | build | Playwright e2e tests, Vitest unit tests |

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
| **Commit** | balanced | Default mode: resolve the target branch (a caller-supplied one in `$ARGUMENTS` skips the ask; an invalid caller-supplied name stops before touching the tree and reports back, while a user-supplied one is re-asked), analyse diff, generate commit message, create the commit. PR mode opens the pull request. Never pushes — the caller does that |
| **Spec Writer** | balanced | Write technical specifications from PRDs when needed |

## How it works

See [WORKFLOW.md](WORKFLOW.md) for detailed flow diagrams.

### `/velo:plan` — Plan work (Plan → Task → Ship)
Unified planning front-end. Depth adapts to the work: the **light tier** goes straight to a Tech Lead breakdown; the **heavy tier** (net-new or underspecified work) first runs PM user stories → a Distinguished-Engineer-reviewed engineering design doc → your design sign-off. Produces one durable carrier — `task-breakdown.md`, holding the frozen milestone plan with composed skills — plus, on the heavy path, `prd.md`, the DE-reviewed `engineering-design-doc.md`, and `architecture.md` (a constrained mermaid shape diagram). The light path produces the carrier alone. It then hands the carrier off to `/velo:task`, which consumes the frozen plan as binding, to build and ship. Planning only — it never writes code.

### `/velo:task` — Day-to-day tasks
A single adaptive delegated flow for bug fixes, refactors, and small changes: validate scope, announce the plan — a task DAG with an inline assumptions ledger — then run the build half as a **per-milestone loop**. Each milestone gets its own branch (`<slug>-m<i>`, cut before any builder spawns), its own review cycle, and its own ship gate; PRs stack, M(i)'s targeting M(i-1)'s branch, and nothing waits on a merge. Only the last milestone's gate ends the run — a task-mode-native run is a single milestone, so the loop simply runs once.

### `/velo:yo` — Entry point
The front door. Bring anything — an idea, a bug, a question — and Velo triages the intent and routes it: `/velo:plan` or `/velo:task` to build, `/velo:hunt` to debug, the review skills to review, `/velo:discuss` to think a question through with the advisory panel. A question with a settled answer Velo can give from knowledge alone gets answered right there, with no file reads; anything needing evidence from the codebase routes to `/velo:discuss` instead. An answer that lands on something to do hands off into a mode with a draft brief. Yo is a front door, not a gate: every mode stays directly invokable.

### `/velo:discuss` — Advisory discussion
Bring a question, a trade-off, or a decision you're stuck on. Velo convenes the advisory panel — TL + DE for a technical trade-off, PM + TL + DE when scope and product impact are in play — synthesizes the positions, and picks a side instead of averaging. Prefix `@pm`, `@tl`, or `@de` to skip mode selection and target one agent. The panel agents read the codebase; Velo does not. Advisory only: no code, no artifacts — and a discussion that lands on a decision hands off into a mode with a draft brief.

### `/velo:hunt` — Structured debug loop
Symptom → hypothesis → root cause → handoff. Tight, iterative debugging mode that ends with a confirmed root cause and a handoff brief to `/velo:task` — or an explicit dead-end with what was ruled out.

# Velo — Team

## Peer

| Agent | File | Role | Model Class |
|---|---|---|---|
| **distinguished-engineer** | `agents/distinguished-engineer.md` | Technical bar, architecture review — peer to EM. Also: design review on `/velo:plan` heavy tier (DESIGN_REVIEW — reviews the TL's engineering design doc) | deep-reasoning |

---

## Your Team

> **Skills column**: exact catalog slugs (basename of `skills/<slug>.md`). The canonical default bundle for skill composition is the agent file's `## Skills` section — see [Velo Skill Composition](skills/velo-skill-composition.md); this column mirrors it for quick reference.

### Planners
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **product-manager** | `agents/product-manager.md` | product-management | balanced |

### Engineering Lead
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **tech-lead** | `agents/tech-lead.md` | api-and-interface-design, spec-quality-check — also: Velo system architecture (agents, commands, skills); authors the engineering design doc on `/velo:plan` heavy tier (DESIGN_PHASE) and the plan breakdown via `Mode: plan-dag` | deep-reasoning |

### Specialists
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **observability-engineer** | `agents/observability-engineer.md` | prometheus, grafana, opentelemetry, logging | balanced |
| **security-engineer** | `agents/security-engineer.md` | security | balanced |

### Builders
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **fe-engineer** | `agents/fe-engineer.md` | react, react-effects, vercel-react-best-practices | build |
| **be-engineer** | `agents/be-engineer.md` | python \| nodejs (language-conditional — see agent file), api-and-interface-design | build |
| **db-engineer** | `agents/db-engineer.md` | postgresql, clickhouse | build |
| **infra-engineer** | `agents/infra-engineer.md` | kafka, docker, kubernetes, aws, ci-cd | build |
| **automation-engineer** | `agents/automation-engineer.md` | playwright, vitest | build |

### Reviewers
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **fe-reviewer** | `agents/fe-reviewer.md` | react, react-effects, vercel-react-best-practices, review-protocol | balanced |
| **be-reviewer** | `agents/be-reviewer.md` | python \| nodejs (language-conditional — see agent file), api-and-interface-design, review-protocol | balanced |
| **db-reviewer** | `agents/db-reviewer.md` | postgresql, clickhouse, review-protocol | balanced |
| **infra-reviewer** | `agents/infra-reviewer.md` | kafka, docker, kubernetes, aws, ci-cd, review-protocol | balanced |
| **automation-reviewer** | `agents/automation-reviewer.md` | playwright, vitest, review-protocol | balanced |
| **observability-engineer** | `agents/observability-engineer.md` | prometheus, grafana, opentelemetry, logging — reviews all BE tasks for metrics, logging, tracing gaps | balanced |
| **security-engineer** | `agents/security-engineer.md` | security — on-demand vulnerability review (via `/security-review`); not auto-attached to BE/FE reviews | balanced |

### Utilities
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **commit** | `agents/commit.md` | commit-protocol, pr-protocol | balanced |

---

## Model Classes

Model classes are defined in `ADAPTER.md`. The roster above uses them as provider-neutral routing intent.

## How to spawn an agent

Follow the `spawn-agent` concept in `ADAPTER.md` (Agent Spawning + Pre-Composed Skill Injection). The steps are defined there once — do not duplicate them here.

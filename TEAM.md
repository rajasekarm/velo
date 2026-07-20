# Velo — Team

## Peer

| Agent | File | Role | Model Class |
|---|---|---|---|
| **distinguished-engineer** | `agents/distinguished-engineer.md` | Technical bar, architecture review — peer to EM. Also: `Mode: task-spec audit` on `/velo:task` pure-tech tier (audits TL-authored task-specs via spec-quality-check) | deep-reasoning |

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
| **tech-lead** | `agents/tech-lead.md` | api-and-interface-design, spec-quality-check — also: EDD authorship, Velo system architecture (agents, commands, skills); `Mode: task-spec` author on `/velo:task` pure-tech tier (authors task-specs for dep bumps, internal schema, infra config, build tooling, observability internals — DE audits) | deep-reasoning |

### Specialists
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **observability-engineer** | `agents/observability-engineer.md` | prometheus, grafana, opentelemetry, logging | balanced |
| **security-engineer** | `agents/security-engineer.md` | security | balanced |

### Builders
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **fe-engineer** | `agents/fe-engineer.md` | react, react-effects, vercel-react-best-practices | balanced |
| **be-engineer** | `agents/be-engineer.md` | nodejs, api-and-interface-design | balanced |
| **db-engineer** | `agents/db-engineer.md` | postgresql, clickhouse | balanced |
| **infra-engineer** | `agents/infra-engineer.md` | kafka, docker, kubernetes, aws, ci-cd | balanced |
| **automation-engineer** | `agents/automation-engineer.md` | playwright, vitest | balanced |

### Reviewers
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **fe-reviewer** | `agents/fe-reviewer.md` | react, react-effects, vercel-react-best-practices, review-protocol | balanced |
| **be-reviewer** | `agents/be-reviewer.md` | nodejs, api-and-interface-design, review-protocol | balanced |
| **db-reviewer** | `agents/db-reviewer.md` | postgresql, clickhouse, review-protocol | balanced |
| **infra-reviewer** | `agents/infra-reviewer.md` | kafka, docker, kubernetes, aws, ci-cd, review-protocol | balanced |
| **automation-reviewer** | `agents/automation-reviewer.md` | playwright, vitest, review-protocol | balanced |
| **observability-engineer** | `agents/observability-engineer.md` | prometheus, grafana, opentelemetry, logging — reviews all BE tasks for metrics, logging, tracing gaps | balanced |
| **security-engineer** | `agents/security-engineer.md` | security — on-demand vulnerability review (via `/security-review`); not auto-attached to BE/FE reviews | balanced |

### Utilities
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **commit** | `agents/commit.md` | commit-protocol, pr-protocol | balanced |
| **learnings-agent** | `agents/learnings-agent.md` | (none) — extracts codebase-specific learnings after rework cycles | balanced |

---

## Model Classes

Model classes are defined in `ADAPTER.md`. The roster above uses them as provider-neutral routing intent.

## How to spawn an agent

Follow the `spawn-agent` concept in `ADAPTER.md` (Agent Spawning + Pre-Composed Skill Injection). The steps are defined there once — do not duplicate them here.

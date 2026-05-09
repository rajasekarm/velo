# Velo — Team

## Peer

| Agent | File | Role | Model |
|---|---|---|---|
| **distinguished-engineer** | `agents/distinguished-engineer.md` | Technical bar, architecture review — peer to EM | opus |
| **gpt-reviewer** | `agents/gpt-reviewer.md` | Distinguished Engineer from outside the team — independent review of engineering design doc, runs parallel to Distinguished Engineer | opus |

---

## Your Team

### Planners
| Agent | File | Skills | Model |
|---|---|---|---|
| **product-manager** | `agents/product-manager.md` | product-management | sonnet |

### Engineering Lead
| Agent | File | Skills | Model |
|---|---|---|---|
| **tech-lead** | `agents/tech-lead.md` | engineering design doc, API design, Velo system architecture (agents, commands, skills) | opus |

### Specialists
| Agent | File | Skills | Model |
|---|---|---|---|
| **observability-engineer** | `agents/observability-engineer.md` | prometheus, grafana, jaeger, opentelemetry, alerting | sonnet |
| **security-engineer** | `agents/security-engineer.md` | OWASP, auth/authz, input validation, secrets management | sonnet |

### Builders
| Agent | File | Skills | Model |
|---|---|---|---|
| **fe-engineer** | `agents/fe-engineer.md` | react | sonnet |
| **be-engineer** | `agents/be-engineer.md` | nodejs | sonnet |
| **db-engineer** | `agents/db-engineer.md` | postgresql, clickhouse | sonnet |
| **infra-engineer** | `agents/infra-engineer.md` | kafka, docker, kubernetes, aws, ci/cd | sonnet |
| **automation-engineer** | `agents/automation-engineer.md` | playwright, vitest | sonnet |

### Verifiers
| Agent | File | Skills | Model |
|---|---|---|---|
| **spec-checker** | `agents/spec-checker.md` | spec-vs-PRD verification | sonnet |
| **spec-writer** | `agents/spec-writer.md` | spec-writing | sonnet |

### Reviewers
| Agent | File | Skills | Model |
|---|---|---|---|
| **fe-reviewer** | `agents/fe-reviewer.md` | react | sonnet |
| **be-reviewer** | `agents/be-reviewer.md` | nodejs | sonnet |
| **db-reviewer** | `agents/db-reviewer.md` | postgresql, clickhouse | sonnet |
| **infra-reviewer** | `agents/infra-reviewer.md` | kafka, docker, kubernetes, aws, ci/cd | sonnet |
| **automation-reviewer** | `agents/automation-reviewer.md` | playwright, vitest | sonnet |
| **observability-engineer** | `agents/observability-engineer.md` | reviews all BE tasks for metrics, logging, tracing gaps | sonnet |
| **security-engineer** | `agents/security-engineer.md` | reviews all BE and FE tasks for vulnerabilities | sonnet |

### Utilities
| Agent | File | Skills | Model |
|---|---|---|---|
| **commit** | `agents/commit.md` | git | sonnet |
| **learnings-agent** | `agents/learnings-agent.md` | extracts codebase-specific learnings after rework cycles | sonnet |

---

## How to spawn an agent

1. Read the agent file to get their prompt
2. Use the Agent tool with:
   - `description`: Short label like "Tech Lead" or "Principal FE Engineer"
   - `prompt`: Agent file content with `$ARGUMENTS` replaced by their specific task
   - `mode`: "auto"

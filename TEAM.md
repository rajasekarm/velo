# Velo — Team

## Peer

| Agent | File | Role | Model Class |
|---|---|---|---|
| **distinguished-engineer** | `agents/distinguished-engineer.md` | Technical bar, architecture review — peer to EM | deep-reasoning |
| **gpt-reviewer** | `agents/gpt-reviewer.md` | Distinguished Engineer from outside the team — independent review of engineering design doc, runs parallel to Distinguished Engineer | external-review |

---

## Your Team

### Planners
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **product-manager** | `agents/product-manager.md` | product-management | balanced |

### Engineering Lead
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **tech-lead** | `agents/tech-lead.md` | engineering design doc, API design, Velo system architecture (agents, commands, skills) | deep-reasoning |

### Specialists
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **observability-engineer** | `agents/observability-engineer.md` | prometheus, grafana, jaeger, opentelemetry, alerting | balanced |
| **security-engineer** | `agents/security-engineer.md` | OWASP, auth/authz, input validation, secrets management | balanced |

### Builders
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **fe-engineer** | `agents/fe-engineer.md` | react | balanced |
| **be-engineer** | `agents/be-engineer.md` | nodejs | balanced |
| **db-engineer** | `agents/db-engineer.md` | postgresql, clickhouse | balanced |
| **infra-engineer** | `agents/infra-engineer.md` | kafka, docker, kubernetes, aws, ci/cd | balanced |
| **automation-engineer** | `agents/automation-engineer.md` | playwright, vitest | balanced |

### Verifiers
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **spec-checker** | `agents/spec-checker.md` | spec-vs-PRD verification | balanced |
| **spec-writer** | `agents/spec-writer.md` | spec-writing | balanced |

### Reviewers
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **fe-reviewer** | `agents/fe-reviewer.md` | react | balanced |
| **be-reviewer** | `agents/be-reviewer.md` | nodejs | balanced |
| **db-reviewer** | `agents/db-reviewer.md` | postgresql, clickhouse | balanced |
| **infra-reviewer** | `agents/infra-reviewer.md` | kafka, docker, kubernetes, aws, ci/cd | balanced |
| **automation-reviewer** | `agents/automation-reviewer.md` | playwright, vitest | balanced |
| **observability-engineer** | `agents/observability-engineer.md` | reviews all BE tasks for metrics, logging, tracing gaps | balanced |
| **security-engineer** | `agents/security-engineer.md` | reviews all BE and FE tasks for vulnerabilities | balanced |

### Utilities
| Agent | File | Skills | Model Class |
|---|---|---|---|
| **commit** | `agents/commit.md` | git | balanced |
| **learnings-agent** | `agents/learnings-agent.md` | extracts codebase-specific learnings after rework cycles | balanced |

---

## Model Classes

Model classes describe the reasoning budget Velo needs from a role. Runtime adapters translate these classes to provider-specific model names.

| Model Class | Intent | Claude Adapter | Codex Adapter |
|---|---|---|---|
| balanced | Routine planning, build, verification, and review work | sonnet | default inherited model or medium reasoning |
| deep-reasoning | Architecture, high-risk design review, and second-order trade-offs | opus | high or xhigh reasoning |
| external-review | Independent outside-model review for design documents | Codex CLI reviewer from `agents/gpt-reviewer.md` | latest suitable GPT model via Codex CLI |

## How to spawn an agent

1. Read the agent file to get their prompt
2. Resolve the row's model class for the current runtime using the adapter table above.
3. Use the Agent tool with:
   - `description`: Short label like "Tech Lead" or "Principal FE Engineer"
   - `prompt`: Agent file content with `$ARGUMENTS` replaced by their specific task
   - `model`: Resolved provider-specific model when the runtime supports it; otherwise omit and rely on the current Codex model/reasoning setting
   - `mode`: "auto"

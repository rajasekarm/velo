---
name: velo-final-report
description: Final-report template printed at the DONE terminal state of Velo slash commands. Authoritative shape for the summary table emitted on successful completion. Consumed by `/velo:task` and `/velo:new` in place of an inlined template.
---
# Velo Final Report

The DONE terminal state of a Velo slash command prints a final summary. This skill is the single source of truth for that template — consuming commands reference this skill in place of inlining the template body.

Commands MAY include only the rows that apply for the run (omit empty sections — e.g. a `/velo:task` run that has no planning phase omits the Planning and Engineering Design Doc tables; a run that stopped at `Done — no commit` omits the Commit table).

## Template

```
Velo — Summary

## Feature (or task)
<one-line description of what was attempted>

## Planning
| Agent | Delivered | Tokens | ~Cost | Tools | Time |
|---|---|---|---|---|---|
| Product Manager | <summary> | <tokens> | ~$<cost> | <tool_uses> | <duration> |

## Engineering Design Doc
| Agent | Artifact | Tokens | ~Cost | Tools | Time |
|---|---|---|---|---|---|
| Tech Lead | `engineering-design-doc.md` — <N endpoints, key decisions> + `task-breakdown.md` — <N tasks> | <tokens> | ~$<cost> | <tool_uses> | <duration> |

## What was delivered
| Agent | Delivered | Tokens | ~Cost | Tools | Time |
|---|---|---|---|---|---|
| <agent> | <summary> | <tokens> | ~$<cost> | <tool_uses> | <duration> |

## Review findings
| Cycle | Reviewer | Verdict | Tokens | Time |
|---|---|---|---|---|
| 1 | <reviewer> | pass/fail <key issues> | <tokens> | <duration> |

## Commit
| Agent | Commit | Tokens | Time |
|---|---|---|---|
| Commit Agent | <commit hash + message> | <tokens> | <duration> |

## Files changed
- <list all files created or modified>

## Cost
Planners total: <sum> tokens | ~$<cost>
Builders total: <sum> tokens | ~$<cost>
Reviewers total: <sum> tokens | ~$<cost>
Grand total: <sum all> tokens | ~$<total cost> | <tool uses> tool calls | <wall time> elapsed
```

Only include rows for agents actually used. For `/velo:task` runs (no planning phase), omit the Planning and Engineering Design Doc tables and collapse the cost breakdown to a single `Grand total` line.

# Task Breakdown

| # | Task | Owner | Depends On |
|---|---|---|---|
| T1 | Author `commands/hunt.md` per the engineering design doc — frontmatter (`description`, `argument-hint`), `@PERSONA.md` import, top-of-skill **Hard Rule — No Code, Investigation Only** (D8), **Non-Goals** block, **Step 0** (load `AskUserQuestion` once via `ToolSearch select:AskUserQuestion` — D6), **Steps 1–7** with the signal-based 3-way classifier in Step 1 (D10) and explicit `AskUserQuestion` invocations at every redirect site (Step 1 cases 4 & 5, F3, F4, F5, F6, F7), the **Hunt board render template** (D3), the **hypothesis state machine** transitions and counter-reset rules (D11), the **soft-cap re-rank** prompt with stall-pre-emption (D4), the **evidence gate** (D5), the **handoff brief** in the 3-line D13 format, the **successful-exit summary** and **abandon summary** templates, the **tool allowlist** Read/Grep/Glob + Bash limited to `git log` / `git blame` (D9), the **secret-handling rule** (D12), and the failure table F1–F12 + S2-silent. | be-engineer | — |
| T2 | Update `README.md` and `WORKFLOW.md` to add `/velo:hunt` to the command index alongside `/velo:new`, `/velo:task`, `/velo:yo`. | be-engineer | T1 |

Notes:
- Two tasks. T2 depends on T1 only because the skill's exact `description`/`argument-hint` is the source of truth for the index entries; sequencing avoids inconsistency.
- No db / fe / infra / automation work. D7 cuts subagents from MVP — there is no agent setup, no merge-back schema, no automation layer to add. US-7 moves to a follow-up.
- Verification is manual: invoke `/velo:hunt` against four sample inputs covering (a) specific defect → full loop, (b) user-stated root cause → `/velo:task` redirect via Step 1 case 4, (c) advisory question → `/velo:yo` redirect via Step 1 case 5, (d) request for code mid-hunt → F5 decline. Confirm Hunt board renders with all counters, soft-cap prompts use `AskUserQuestion`, and no code is written in any branch. No automated test layer exists for skill markdown files in this repo.

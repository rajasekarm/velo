# PRD: `/velo:yo` — Technical Discussion Command

> Version: 1.0 — 2026-04-12
> Status: Draft

---

## Problem Statement

Velo users currently have two commands: `/velo:new` for new features (full PM-to-commit pipeline) and `/velo:task` for day-to-day work (build-review-commit pipeline). Both commands are optimised for producing code artifacts — they assume the user has already decided to build something and is ready to delegate.

But a significant category of user intent falls outside both commands: **"I have an idea or question and I want to think it through before deciding what to do."**

Today, users misuse `/velo:new` (overkill — triggers a full PM phase, engineering design doc, build pipeline) or `/velo:task` (wrong tool — skips planning entirely and jumps to building). Both waste tokens, produce unwanted artifacts, and force the user to abort midway or manually redirect.

**Who is affected:** Any Velo user who wants to explore a technical idea, debate an architectural approach, compare trade-offs, or get structured opinions — without committing to a build.

**The pain:**
1. No lightweight way to get structured, multi-perspective technical advice
2. Using `/velo:new` for exploration wastes tokens on PM, engineering design doc, and build phases that get thrown away
3. Using `/velo:task` for exploration produces code changes when the user just wanted analysis
4. The user ends up doing the thinking alone, losing the value of Velo's opinionated agent team

---

## Brainstorming: Three Approaches

### Approach A: Roundtable Discussion (Recommended)

Velo convenes a panel of 2-3 agents in parallel, each given the same question but responding from their distinct perspective. Velo synthesises their views into a structured recommendation with dissenting opinions noted.

**Flow:** User question -> Velo selects panel -> Agents respond in parallel -> Velo synthesises -> User decides next step.

- **What works:** Fast (parallel execution), multi-perspective, cheap (no build/review/commit overhead). Feels like calling a meeting.
- **What breaks:** Agents might overlap in their analysis. Synthesis by Velo adds a layer of interpretation.
- **What scales:** Adding new personas to the panel is trivial. Could add domain specialists (security-engineer, infra-engineer) for domain-specific questions.
- **Simplest version:** Always spawn the same 3 voices (distinguished-engineer, product-manager, tech-lead), synthesise, done. No dynamic panel selection in v1.

### Approach B: Sequential Debate (Socratic)

Spawn agents one at a time in a chain — each reads the previous agent's take and responds to it. Like a structured argument thread.

- **What works:** Builds on itself — later agents refine or counter earlier positions. More dialectic.
- **What breaks:** Slow (sequential = 3x wall time). Earlier agents can't respond to later critiques. Ordering introduces bias — whoever goes last gets the final word.
- **What scales:** Poorly. Adding agents makes it linearly slower.
- **Simplest version:** Distinguished Engineer -> Tech Lead -> Product Manager, each building on the prior.

### Approach C: Single Advisor + Follow-ups

Route the question to the single most relevant agent. Allow the user to say "now ask the tech lead" or "what would the DE think?" as follow-ups.

- **What works:** Cheapest per interaction. User controls depth.
- **What breaks:** Loses the "convene the room" feel. User has to manually orchestrate. Becomes a series of `/velo:task` calls without the task.
- **What scales:** Well for simple questions, poorly for nuanced trade-off discussions.
- **Simplest version:** Velo picks one agent, routes the question, returns the answer.

### Recommendation: Approach A (Roundtable Discussion)

Approach A delivers the core value proposition — structured multi-perspective discussion — in a single command invocation. It is the cheapest experiment that validates whether users value "discussion mode" at all. Parallel execution keeps wall time low. The fixed panel of 3 agents (distinguished-engineer, product-manager, tech-lead) avoids routing complexity in v1 while covering the three critical lenses: technical feasibility, product value, and implementation pragmatics.

---

## Goals

1. Give users a zero-artifact way to get structured technical advice from Velo's agent team
2. Produce a clear recommendation with explicit dissenting views and trade-offs
3. End with an actionable decision point: shelve, `/velo:new`, or `/velo:task`
4. Keep token cost significantly lower than `/velo:new` (no build, no review, no commit phases)

## Non-Goals

1. **No code generation** — `/velo:yo` produces no code, no files (except optionally saving the discussion)
2. **No build/review/commit pipeline** — this is purely conversational
3. **No interactive multi-turn debate** — v1 is a single-shot roundtable; the user asks, agents respond, Velo synthesises. The user can run `/velo:yo` again with a refined question if needed.
4. **No dynamic panel selection** — v1 always uses the same 3 agents. Smart routing is a future enhancement.
5. **No persistence by default** — the discussion lives in the conversation. Saving to a file is opt-in (future enhancement).

---

## User Stories

### US-1: Core Discussion Flow

**As a** Velo user,
**I want to** ask a technical question and get structured opinions from multiple perspectives,
**so that** I can make an informed decision before committing to build anything.

**Acceptance Criteria:**
- User invokes `/velo:yo <question or topic>`
- Velo announces the discussion topic and which agents are being consulted
- Three agents (distinguished-engineer, product-manager, tech-lead) are spawned in parallel with the user's question
- Each agent responds from their own perspective with a clear position
- Velo synthesises the responses into a structured output containing:
  - A recommendation (what Velo would do)
  - Key agreements across agents
  - Key disagreements or tensions
  - Trade-offs identified
  - Suggested next step (shelve / `/velo:new` / `/velo:task` / ask a follow-up)
- No files are created in the repository
- No build, review, or commit phases are triggered

### US-2: Velo Synthesis and Recommendation

**As a** Velo user,
**I want** Velo to synthesise the discussion into an opinionated recommendation (not just relay three opinions),
**so that** I get a clear signal, not noise.

**Acceptance Criteria:**
- Velo's synthesis includes a clear "Here's what I'd do" statement
- Dissenting views are noted with their reasoning, not suppressed
- If agents agree, Velo states the consensus and confidence level
- If agents disagree, Velo explains the fault line and which side it leans toward and why

### US-3: Announce and Track Token Usage

**As a** Velo user,
**I want to** see how much the discussion cost in tokens,
**so that** I know the cost of exploration vs. building.

**Acceptance Criteria:**
- After the discussion completes, Velo prints a summary table with:
  - Each agent's token usage, tool calls, and wall time
  - Grand total
- Format matches existing Velo summary reports (consistent with `/velo:new` and `/velo:task`)

### US-4: Mode Switch Handoff

**As a** Velo user,
**I want** `/velo:yo` to directly transition into the appropriate build mode when the discussion concludes with a build recommendation,
**so that** I don't have to manually invoke `/velo:new` or `/velo:task` — the discussion flows seamlessly into action.

**Acceptance Criteria:**
- The synthesis ends with a "Next steps" section with an explicit recommendation: build it (new/task), shelve it, or ask a follow-up
- If the recommendation is to build: Velo asks "Proceed with `/velo:new <draft brief>`?" (or `/velo:task`) using AskUserQuestion with the refined brief pre-filled from the discussion output
- If the user confirms: Velo invokes the appropriate command inline, passing the discussion-derived brief as the argument — no copy-pasting required
- If the user declines: Velo surfaces the draft brief as copy-pasteable text and exits cleanly
- If the recommendation is to shelve: Velo states why and exits — no gate needed
- The draft brief passed to `/velo:new` or `/velo:task` must be informed by the discussion (not just the original question verbatim)

### US-5: Codebase-Aware Discussion

**As a** Velo user,
**I want** the discussion agents to have context about my current codebase,
**so that** their opinions are grounded in what actually exists, not abstract advice.

**Acceptance Criteria:**
- Each agent is instructed to read relevant parts of the codebase before responding
- Opinions reference existing patterns, conventions, and constraints from the actual code
- If the question involves a specific file or module, agents read it

---

## Prioritisation

### Must-Have (v1 — ship this)

| # | Item | Rationale |
|---|---|---|
| M1 | Core roundtable flow (US-1) | The entire point of the command |
| M2 | Velo synthesis with opinionated recommendation (US-2) | Without this, it's just three opinions — no signal |
| M3 | Token usage summary (US-3) | Consistency with existing commands; users need cost visibility |
| M4 | Mode switch handoff (US-4) | Seamlessly transitions from discussion to build — no manual re-invocation |
| M5 | Codebase-aware agents (US-5) | Without codebase context, advice is generic and low-value |

### Nice-to-Have (v2 — future enhancements)

| # | Item | Rationale |
|---|---|---|
| N1 | Dynamic panel selection — Velo picks which agents to consult based on the question topic (e.g., security question adds security-engineer) | Reduces noise for domain-specific questions |
| N2 | Save discussion to file — opt-in flag like `/velo:yo --save <topic>` writes the synthesis to `.velo/discussions/<slug>.md` | Useful for decisions that need to be referenced later |
| N3 | Follow-up mode — after the roundtable, user can ask "what does the security-engineer think?" to bring in additional voices | Enables deeper exploration without restarting |
| N4 | Discussion history — Velo remembers past `/velo:yo` sessions and can reference them ("we discussed this on April 10") | Builds institutional memory |
| N5 | Confidence scoring — each agent rates their confidence (high/medium/low) so Velo can weight the synthesis | Makes disagreements more nuanced |

---

## Edge Cases

### Empty or Vague Input
- If the user provides no argument or an extremely vague one (e.g., `/velo:yo` with no topic), Velo should ask a clarifying question before spawning agents. Do not waste tokens on an unfocused roundtable.

### Question Better Suited for Another Command
- If the question is clearly an implementation request (e.g., "add a login page"), Velo should flag: "This sounds like a build task. Did you mean `/velo:new` or `/velo:task`?" and ask before proceeding.

### Single-Domain Question
- If the question is narrowly about one domain (e.g., "what Postgres index should I use here?"), all three agents still respond but their value varies. The synthesis should weight the most relevant voice. This is acceptable for v1; dynamic panel selection (N1) addresses it in v2.

### Agents Fully Agree
- If all three agents reach the same conclusion, Velo should state the consensus clearly and note the confidence level, rather than artificially manufacturing disagreement.

### Agents Fully Disagree
- If all three agents take different positions, Velo must still pick a side in the synthesis. The recommendation is "what Velo would do" — it is not a vote.

### Very Long or Multi-Part Questions
- If the user asks multiple distinct questions in one invocation, Velo should either: (a) pick the most important one and address it, noting the others for a follow-up, or (b) split them and address sequentially. Do not let a sprawling question produce an unfocused roundtable.

### Codebase Not Available
- If there is no codebase to read (e.g., greenfield discussion), agents should still respond based on the question alone. Their responses should note that they are advising without codebase context.

---

## Dependencies

### Existing Agents (no new agents required for v1)
- `agents/distinguished-engineer.md` — exists, opus model, has codebase reading capability
- `agents/product-manager.md` — exists, opus model, has codebase reading capability
- `agents/tech-lead.md` — exists, opus model, has codebase reading capability

### Existing Infrastructure
- Agent spawning via the Agent tool — already used by `/velo:new` and `/velo:task`
- Parallel agent execution — already used by `/velo:new` (review phase) and `/velo:task` (review phase)
- Token tracking — already implemented in both existing commands

### New Artifacts Required
- `commands/yo.md` — the new command file (follows existing pattern from `commands/new.md` and `commands/task.md`)
- No new agent files required
- No new skill files required

### Agent Prompt Adaptation
- The three agents are currently prompted for build-oriented workflows (PM writes a PRD, Tech Lead writes an engineering design doc, DE reviews an engineering design doc). For `/velo:yo`, they need to be prompted differently — as discussion participants giving opinions, not producing artifacts. This is handled in the command file's prompt construction, not by modifying the agent files.

---

## Open Questions

1. **Should agents read each other's responses?** In v1 (Approach A), agents respond independently in parallel. This means they cannot react to each other. Is this a meaningful limitation, or is Velo's synthesis sufficient to capture the interplay? (Recommendation: parallel is fine for v1 — the synthesis layer handles cross-referencing.)

2. **What model tier for discussion agents?** All three are currently opus. For a discussion-only command with no code output, could we use sonnet for the PM and tech lead to save tokens, keeping opus only for the distinguished engineer? (Recommendation: keep opus for v1 — the value of this command is quality of thought, and that is model-sensitive.)

3. **Should the command name be `yo` or something more descriptive?** `yo` is casual and memorable, fitting Velo's direct personality. Alternatives: `discuss`, `think`, `ask`. (Recommendation: `yo` — it is distinctive, short, and signals "this is informal, not a build pipeline.")

4. **Maximum question length?** Should there be a soft limit on input length to prevent token waste on overly long prompts? (Recommendation: no hard limit, but Velo should summarise long inputs before passing to agents.)

# Engineering Design Doc: velo:yo Command

> Version: 2.0 — 2026-04-12
> Status: Revised — addressing DE review (C1, C2, S1, S2, S3, M1-M5)

---

## Decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | `velo:yo` is a command file (`commands/yo.md`), not a skill file or agent | It orchestrates agents, produces structured output, and follows the same delegation pattern as `commands/new.md` and `commands/task.md`. Skill files are domain-knowledge references (e.g., `skills/react.md`); command files are orchestration workflows. The PRD's artifact section was ambiguous — this follows the established convention. |
| D2 | All three agents (distinguished-engineer, product-manager, tech-lead) are spawned in parallel — they do not see each other's responses | Parallel execution minimises wall time. Cross-pollination would require sequential spawning (3x latency) or a second round (2x token cost). Velo's synthesis compensates for lack of cross-agent awareness — it resolves contradictions, weights perspectives, and picks a side. The PRD explicitly recommends this approach (OQ1). |
| D3 | ~~Agents use existing agent files with a prompt wrapper~~ **REVISED**: Each agent uses a **self-contained inline prompt** defined in `commands/yo.md` — existing agent files are NOT referenced or loaded | The existing agent files (`agents/product-manager.md`, `agents/tech-lead.md`, `agents/distinguished-engineer.md`) have deeply ingrained build/artifact workflows (e.g., "Output PRD to task folder", "Read engineering-design-doc.md", "Write REVISE/APPROVE verdict"). A `$ARGUMENTS` wrapper saying "no files, no code" is insufficient to override these hardcoded instructions — the agents will fight the wrapper. Self-contained inline prompts are simpler, more deterministic, and cannot conflict with build-oriented instructions. See C1 in DE review. |
| D4 | All three agents run at opus model tier | The PRD recommends opus (OQ2), and all three agents are already configured as opus in PERSONA.md. Quality of reasoning is the entire value proposition of `/velo:yo` — there is no implementation work to offset weak analysis. Downgrading to sonnet would save tokens but undermine the command's purpose. |
| D5 | Agents read the codebase before responding — with explicit reading guidance (README + directory structure first, max 5 files total) | The prompt instructs each agent to explore the codebase with a specific strategy: read README and directory structure first, then up to 3 files most relevant to the question, max 5 files total. This prevents unbounded exploration, avoids three agents independently reading the same files without coordination, and keeps token cost predictable. See S3 in DE review. |
| D6 | Velo's synthesis is structured with fixed sections: Recommendation, Consensus, Tensions, Trade-offs, Next Steps | A fixed structure ensures consistency across invocations and makes the output scannable. The PRD requires all of these elements (US-2). Free-form synthesis would vary in quality and coverage. |
| D7 | Synthesis is performed by Velo (the orchestrator) directly, not by spawning a synthesis agent | Velo already has all three responses in context. Spawning a fourth agent would add latency, token cost, and context-passing overhead for no benefit — the orchestrator can reason over three structured responses. This keeps `/velo:yo` to exactly 3 agent calls (matching the "significantly lower than `/velo:new`" cost target). |
| D8 | ~~Mode switch executes commands inline~~ **REVISED**: Mode switch produces a draft brief + copy-pasteable invocation command only — no inline execution | Inline execution of `/velo:new` or `/velo:task` after three opus responses creates multiple problems: (1) `/velo:new` creates `.velo/tasks/<slug>/`, violating zero-artifact design; (2) `/velo:new` prints its own announcement header, creating jarring UX; (3) context window pressure after 3 opus responses + synthesis is already high. Instead, Velo prints the draft brief and the exact command to run. The user copy-pastes to invoke in a fresh context. See S2 in DE review. |
| D9 | No files are created in the repository — all output is printed to the conversation | `/velo:yo` is a zero-artifact command (PRD Goal 1, Non-Goal 1). No task folder, no markdown files, no status.json. Output lives in the conversation only. This is a deliberate contrast to `/velo:new` and `/velo:task` which both create `.velo/tasks/<slug>/` artifacts. |
| D10 | Empty/vague input triggers a clarifying question — validated by Velo using concrete heuristics, not subjective judgment | Velo checks the input against defined rules before spawning agents. See Input Validation section for the full heuristic table. This saves 3 opus agent calls on bad input and ensures deterministic classification across invocations. See C2 in DE review. |
| D11 | If the question is clearly an implementation request, Velo flags it and asks whether the user meant `/velo:new` or `/velo:task` before proceeding | This prevents misuse (PRD edge case). Velo does not refuse — it flags and asks. If the user confirms they want discussion, Velo proceeds. Detection uses concrete heuristics (see Input Validation), not open-ended judgment. |
| D12 | Each agent's response is summarised to 3-5 bullet points in the final output — full responses are not printed | Printing three full opus-length responses would be overwhelming. The summary forces each agent's position into a scannable format. If the user wants detail, they can re-invoke the specific agent or ask Velo to elaborate. This keeps the output concise and decision-oriented. |
| D13 | Token usage summary follows the existing Velo report format — table with agent name, tokens, tool uses, duration | Consistent with `/velo:new` and `/velo:task` final reports (US-3). Same columns, same format. The cost breakdown section is simpler since there is only one phase (Discussion) and no build/review phases. |
| D14 | The command file references `@PERSONA.md` and uses `$ARGUMENTS` — matching the exact pattern of `new.md` and `task.md` | Convention consistency. The frontmatter includes `description` and `argument-hint`. The body references PERSONA.md for Velo's personality. `$ARGUMENTS` is replaced with the user's question at invocation. |
| D15 | When recommendation is to shelve: Velo states why and exits cleanly — no AskUserQuestion gate | A shelve recommendation means "don't build." Adding a confirmation gate ("Are you sure you don't want to build?") would be friction with no value. Velo states its reasoning and the user can always invoke `/velo:new` or `/velo:task` manually if they disagree. |
| D16 | **NEW**: Agent prompts are fully self-contained inline blocks in `commands/yo.md` — one per agent, each with role identity, advisory framing, codebase reading strategy, output format, and response cap | Addresses C1 and S1 from DE review. The existing agent files have hardcoded build workflows that conflict with advisory mode. Self-contained prompts eliminate the conflict entirely. Each prompt is written from scratch for the advisory context. The DE advisory prompt in particular is rewritten to focus on second-order effects, tech debt, maintenance burden, and abstraction quality — not artifact review (which is the existing DE agent's entire identity). |
| D17 | **NEW**: Input classification uses concrete, testable heuristics — not open-ended LLM judgment | Addresses C2 from DE review. Three heuristics: (1) word count + technical specificity for vague detection, (2) imperative verb + code-change target for implementation detection, (3) conjunction count for multi-part detection. Each heuristic is defined with examples. Velo applies these rules before spawning agents. |
| D18 | **NEW**: Each agent prompt includes an explicit codebase reading strategy with a 5-file cap | Addresses S3 from DE review. Strategy: "Read the project README and top-level directory structure first. Then read up to 3 files most relevant to the question. Do not read more than 5 files total. Do not read test files unless the question is about testing." This bounds token cost and prevents three agents independently doing full codebase exploration. |
| D19 | **NEW**: Agent responses are capped at 400 words / 8 bullets maximum | Addresses M1 from DE review. The prompt explicitly states: "Keep your response under 400 words. Position: 1-2 sentences. Reasoning: 3-5 bullets. Risks: 2-3 bullets. Alternative: 1-2 sentences." This prevents 2000+ token agent responses that would bloat the synthesis context. |
| D20 | **NEW**: Announcement step includes a cost note warning about 3 opus calls | Addresses M2 from DE review. The announcement prints: "Note: This is the most expensive per-invocation command (3 opus calls)." Users should know upfront. |
| D21 | **NEW**: When all three agents agree, synthesis output is compact — state consensus once, note confidence, move to next steps | Addresses M3 from DE review. When consensus is detected, Velo collapses the "Where they disagree" and "Trade-offs" sections into a single "The panel agrees" block and moves directly to next steps. No need to enumerate agreement points when everyone is saying the same thing. |
| D22 | **NEW**: If only 1 of 3 agents returns, present the single response directly — no synthesis. Minimum 2-of-3 for synthesis | Addresses M5 from DE review. If exactly 1 agent returns (other 2 failed/timed out), Velo presents that response directly with a note: "Only one perspective available — [agent name] responded, [other two] did not. Treat this as a single opinion, not a synthesised recommendation." If 2 return, Velo synthesises from the two and notes the missing agent. |

---

## Command Interface

### `velo:yo`

**Purpose**: Structured multi-perspective technical discussion before deciding whether and what to build.

**Invocation**:
```
/velo:yo <question or topic>
```

**Arguments**:

| Argument | Type | Required | Description |
|---|---|---|---|
| `question` | string (free text) | Yes | The technical question, idea, or topic to discuss. No length limit — Velo will summarise if excessively long. |

**Frontmatter**:
```yaml
---
description: Velo — Technical discussion. Get multi-perspective advice before deciding to build.
argument-hint: Ask a technical question or describe an idea to explore
---
```

**File reference**: `@PERSONA.md` (same as `new.md` and `task.md`)

### Input Validation

Before spawning agents, Velo evaluates the input against these concrete heuristics:

| Condition | Heuristic | Action |
|---|---|---|
| Empty or whitespace-only input | Input is empty or contains only whitespace characters | Print: "What's the question? Give me a topic or technical question to discuss." and stop. |
| Vague input | Input is **fewer than 10 words** AND contains **no technical specificity** (no mention of a technology, component, pattern, data structure, trade-off, or architectural concept) | Ask a clarifying question: "That's broad. What specifically? Are you evaluating a migration, questioning a schema choice, exploring a new use case? Narrow it down and I'll convene the panel." |
| Implementation request | Input contains an **imperative verb targeting code changes** (`add`, `fix`, `build`, `implement`, `refactor`, `migrate`, `create`, `remove`, `delete`, `update`, `deploy`) AND the verb targets a **concrete code artifact** (page, component, endpoint, table, migration, service, function) | Flag: "That sounds like a build task, not a discussion. Did you mean `/velo:new` or `/velo:task`?" with options: "1 — Yes, switch to build mode", "2 — No, I want to discuss it first". If user picks 1, print the appropriate command invocation. If user picks 2, proceed with discussion. |
| Multi-part question | Input contains **3+ distinct questions** (detected by: multiple question marks, or conjunctions joining unrelated topics — e.g., "X and also Y and what about Z") | Velo picks the most important thread or asks: "That's multiple questions. Which one is most urgent? I'll focus the panel on that — we can take the others after." |
| Valid question | None of the above conditions match | Proceed to Step 1. |

**Edge cases in classification**:
- "Should we add authentication?" — contains "add" but is framed as a question ("should we"), not an imperative. This is a **valid question**, not an implementation request.
- "database" — 1 word, but has technical specificity. Still **vague** because it has no framing (what about the database?).
- "Should we use Postgres or MySQL for the new user service?" — 12 words, technical specificity, clear framing. **Valid question**.

---

## Agent Prompting Strategy

### Core Principle

Each agent uses a **self-contained inline prompt** defined directly in `commands/yo.md`. Existing agent files (`agents/product-manager.md`, `agents/tech-lead.md`, `agents/distinguished-engineer.md`) are **NOT referenced or loaded**. This is a deliberate design choice — see D3 and D16.

The existing agent files have hardcoded build/artifact workflows:
- `product-manager.md`: "Output a structured PRD to the task folder"
- `tech-lead.md`: "Produce engineering-design-doc.md in the task folder"
- `distinguished-engineer.md`: "Read .velo/tasks/<slug>/prd.md" and "Write REVISE/APPROVE verdict"

These instructions would conflict with the advisory framing. Self-contained prompts eliminate this problem entirely.

### Inline Agent Prompts

Each agent is spawned with **model: opus** and the following complete prompt. No external file references.

**Product Manager Advisory Prompt**:
```
You are a senior Product Manager providing advisory input on a technical discussion. You are NOT writing a PRD, creating user stories, or producing any files. This is a conversation, not a planning exercise.

## Codebase Reading Strategy
Before responding, ground yourself in the codebase:
1. Read the project README and top-level directory structure
2. Read up to 3 files most relevant to the question
3. Do not read more than 5 files total
4. Do not read test files unless the question is about testing

## Question
<user's question — inserted by Velo>

## Your Lens
Think about this from a product perspective:
- Who benefits and who pays the cost?
- What's the user impact? What changes for them?
- What's the scope risk? Will this grow beyond what's intended?
- Is the timing right? What else competes for attention?
- What's the cheapest experiment to validate before committing?

## Output Format
Keep your response under 400 words. Structure as:
1. **Position**: Your clear stance in 1-2 sentences
2. **Reasoning**: Why you hold this position (3-5 bullets, grounded in codebase evidence where possible)
3. **Risks**: What could go wrong with your recommended approach (2-3 bullets)
4. **Alternative**: The best alternative you considered and why you rejected it (1-2 sentences)

Do not create any files. Do not write any code. Do not produce a PRD.
```

**Tech Lead Advisory Prompt**:
```
You are the Tech Lead providing advisory input on a technical discussion. You are NOT writing an engineering design doc, defining API contracts, or producing any files. This is a conversation, not a design exercise.

## Codebase Reading Strategy
Before responding, ground yourself in the codebase:
1. Read the project README and top-level directory structure
2. Read up to 3 files most relevant to the question
3. Do not read more than 5 files total
4. Do not read test files unless the question is about testing

## Question
<user's question — inserted by Velo>

## Your Lens
Think about this from an implementation perspective:
- What would the engineering design doc look like? What are the hard decisions?
- How does this fit the existing architecture? What bends, what breaks?
- What's the implementation cost? Days, not weeks — be specific.
- What dependencies or ordering constraints exist?
- What's the simplest version that delivers value?

## Output Format
Keep your response under 400 words. Structure as:
1. **Position**: Your clear stance in 1-2 sentences
2. **Reasoning**: Why you hold this position (3-5 bullets, grounded in codebase evidence where possible)
3. **Risks**: What could go wrong with your recommended approach (2-3 bullets)
4. **Alternative**: The best alternative you considered and why you rejected it (1-2 sentences)

Do not create any files. Do not write any code. Do not produce an engineering design doc.
```

**Distinguished Engineer Advisory Prompt**:
```
You are a Distinguished Engineer providing advisory input on a technical discussion. You are NOT reviewing a PRD or engineering design doc. There is no artifact to approve or reject. This is a conversation about technical direction.

Your expertise: second-order effects, tech debt assessment, maintenance burden, abstraction quality, and long-term system health. You think about what decisions make harder to change later, and whether the team is solving the right problem at the right layer.

## Codebase Reading Strategy
Before responding, ground yourself in the codebase:
1. Read the project README and top-level directory structure
2. Read up to 3 files most relevant to the question
3. Do not read more than 5 files total
4. Do not read test files unless the question is about testing

## Question
<user's question — inserted by Velo>

## Your Lens
Think about this from a long-term technical excellence perspective:
- What are the second-order effects? What does this make harder later?
- Does this create tech debt, or pay it down?
- What's the maintenance burden in 6 months?
- Is this the right abstraction level? Over-engineered or under-engineered?
- What would you veto, and what would you champion?

## Output Format
Keep your response under 400 words. Structure as:
1. **Position**: Your clear stance in 1-2 sentences
2. **Reasoning**: Why you hold this position (3-5 bullets, grounded in codebase evidence where possible)
3. **Risks**: What could go wrong with your recommended approach (2-3 bullets)
4. **Alternative**: The best alternative you considered and why you rejected it (1-2 sentences)

Do not create any files. Do not write any code. Do not produce a review verdict.
```

### Why Self-Contained Prompts (Not Agent File Wrappers)

The original design (v1.0) proposed reusing existing agent files with a `$ARGUMENTS` wrapper to reframe them. This was rejected because:

1. **Agent files have hardcoded build workflows** — "Output PRD to task folder", "Read engineering-design-doc.md", "Write REVISE/APPROVE" are baked into the agent file body, not the `$ARGUMENTS` section. A wrapper cannot reliably override instructions that appear earlier in the same prompt.
2. **The DE agent is a particularly poor fit** — its entire identity is reviewing engineering design docs against PRDs. There is no engineering design doc or PRD in `/velo:yo`. The advisory DE prompt is written from scratch with a different focus: second-order effects, tech debt, maintenance burden, abstraction quality.
3. **Self-contained prompts are more deterministic** — no risk of conflicting instructions, no reliance on the agent "ignoring" parts of its own prompt file.
4. **Maintenance is minimal** — the advisory prompts are stable (the advisory lens for each role rarely changes). If the base agent personas change, the advisory prompts do not need to change in lockstep because they are independent.

---

## Synthesis Algorithm

After all three agents return, Velo processes their responses through this algorithm:

### Step 0 — Check response count

| Responses received | Action |
|---|---|
| 0 of 3 | Print: "All three agents failed to respond. Try again or rephrase the question." and stop. |
| 1 of 3 | Present the single response directly with a note: "Only one perspective available — [agent name] responded, [other two] did not. Treat this as a single opinion, not a synthesised recommendation." Skip synthesis. Still offer next steps if applicable. |
| 2 of 3 | Proceed with synthesis from the two responses. Note the missing agent: "[agent name] did not respond — synthesis is based on two perspectives." |
| 3 of 3 | Proceed with full synthesis. |

### Step 1 — Extract positions

For each agent response, extract:
- The stated position (agree/disagree/qualified)
- Key evidence cited
- Risks identified
- Alternatives considered

### Step 2 — Identify agreement and disagreement

Compare the positions:

| Pattern | Classification |
|---|---|
| All responding agents align on the same recommendation | **Consensus** — note confidence level (strong if reasoning also aligns, moderate if reasoning diverges) |
| Majority agrees, one dissents | **Majority with dissent** — identify the fault line |
| All responding agents disagree | **No consensus** — identify the key axis of disagreement |
| Partial overlap (e.g., agree on "what" but disagree on "how") | **Qualified agreement** — state what's agreed and what's contested |

### Step 3 — Formulate Velo's recommendation

Velo does not average opinions. Velo picks a side:

- Weight the most relevant voice for the question type (architecture question → DE weighs more; scope question → PM weighs more; implementation question → TL weighs more)
- If agents disagree, Velo explains the fault line and states which side it leans toward and why
- If agents agree, Velo states the consensus and its confidence level
- Velo may disagree with all three agents — it has its own engineering judgment

### Step 4 — Determine next step

Based on the recommendation:

| Recommendation Type | Next Step |
|---|---|
| Build something new | Suggest `/velo:new` with draft brief |
| Fix/enhance existing | Suggest `/velo:task` with draft brief |
| Needs more investigation | Suggest a focused follow-up question |
| Shelve / don't pursue | State why and exit |

---

## Mode Switch Handoff

### Core Principle

`/velo:yo` **never executes** `/velo:new` or `/velo:task` inline. It produces a draft brief and a copy-pasteable command invocation. The user runs the command in a fresh context. This keeps `/velo:yo` truly zero-artifact and avoids context window pressure after three opus responses + synthesis.

### When recommendation is to build

After printing the synthesis, Velo prints:

```
Ready to build?

Based on the discussion, here's what I'd brief the team on:

> <draft brief — 2-4 sentences distilling the recommendation into an actionable feature/task description>

Copy-paste when ready:

  /velo:new <draft brief>

Or for a smaller task:

  /velo:task <draft brief>
```

No AskUserQuestion gate. No inline execution. The user decides when and whether to invoke the next command.

### When recommendation is to shelve

No gate. Velo prints:
```
My recommendation: shelve this.

Reason: <1-2 sentences explaining why>

If you disagree, `/velo:new` or `/velo:task` are always available.
```

### When recommendation is to investigate further

Velo prints:
```
Not ready to build yet. Suggested follow-up:

> <specific follow-up question to ask /velo:yo>

Copy-paste when ready:

  /velo:yo <follow-up question>
```

### Draft Brief Construction

The draft brief is NOT the user's original question. It is constructed from:
1. The core recommendation from synthesis
2. Scope boundaries identified by the PM perspective
3. Technical approach favoured by TL and DE
4. Explicit non-goals surfaced during discussion

Format: 2-4 sentences. Actionable. Specific enough to hand to the PM or a builder.

---

## Output Format

### Step 1 — Announcement (printed before spawning agents)

```
Velo here. Convening the panel...

Topic: <one-line summary of the question>

Consulting:
- Product Manager: product impact, scope, user value
- Tech Lead: implementation cost, architecture fit, dependencies
- Distinguished Engineer: long-term implications, tech debt, abstraction quality

Execution: All three in parallel. Synthesis after.
Note: This is the most expensive per-invocation command (3 opus calls).
```

### Step 2 — Per-Agent Summary (printed after agents return)

```
## Panel Responses

### Product Manager
- <bullet 1 — position>
- <bullet 2-4 — key reasoning>
- <bullet — primary risk flagged>

### Tech Lead
- <bullet 1 — position>
- <bullet 2-4 — key reasoning>
- <bullet — primary risk flagged>

### Distinguished Engineer
- <bullet 1 — position>
- <bullet 2-4 — key reasoning>
- <bullet — primary risk flagged>
```

Each agent's full response is distilled to 3-5 bullets. Position first, reasoning next, risks last.

Only include sections for agents that responded. If an agent failed, note: "[Agent name] did not respond."

### Step 3 — Velo's Synthesis

**When agents disagree (standard format)**:
```
## Velo's Take

### Recommendation
<1-3 sentences. What I'd do and why. Direct, opinionated, not hedged.>

### Where the panel agrees
- <agreement point 1>
- <agreement point 2>

### Where they disagree
- <tension 1: what PM says vs what DE says, and which side I lean toward>
- <tension 2: ...>

### Trade-offs
- <trade-off 1: choosing X means accepting Y>
- <trade-off 2: ...>

### Next steps
<One of: "Build it" with draft brief, "Shelve it" with reason, "Dig deeper" with follow-up question>
```

**When all agents agree (compact format)**:
```
## Velo's Take

### Recommendation
<1-3 sentences. What I'd do and why.>

### The panel agrees
<1-2 sentences stating the consensus and confidence level. No need to enumerate each point of agreement separately.>

### Next steps
<One of: "Build it" with draft brief, "Shelve it" with reason, "Dig deeper" with follow-up question>
```

### Step 4 — Mode Switch (conditional)

Only shown when next step involves a build command — see Mode Switch Handoff section above. Prints the draft brief and copy-pasteable command. No interactive gate.

### Step 5 — Token Usage Summary

```
## Cost

| Agent | Tokens | Tools | Time |
|---|---|---|---|
| Product Manager | <tokens> | <tool_uses> | <duration> |
| Tech Lead | <tokens> | <tool_uses> | <duration> |
| Distinguished Engineer | <tokens> | <tool_uses> | <duration> |

Grand total: <sum> tokens | <tool uses> tool calls | <wall time> elapsed
```

---

## Edge Cases

| Case | Handling |
|---|---|
| All agents fail to respond (timeout/error) | Print error message and stop. Do not synthesise from nothing. See Step 0 in Synthesis Algorithm. |
| 1 of 3 agents responds | Present the single response directly with a note. Do not synthesise from one perspective. See D22 and Step 0. |
| 2 of 3 agents respond | Synthesise from the two, note the missing agent. See Step 0. |
| Agent ignores discussion framing and tries to build | Velo extracts the advisory content from the response and ignores any artifacts. The self-contained prompts make this unlikely — there are no build instructions to follow. |
| User asks the same question twice | No deduplication. Each invocation is independent. No persistence means no way to detect duplicates. |
| Question has no codebase relevance (e.g., "should we use Kubernetes?") | Agents respond based on general expertise. They will note if the codebase provides no relevant context. |
| Very long user question | Velo summarises the question to a focused form before passing to agents. Original text is preserved in the agent prompt but Velo adds a summary header. |

---

## Files to Create or Modify

| File | Action | Description |
|---|---|---|
| `commands/yo.md` | **New** | The complete `/velo:yo` command file. Contains frontmatter, @PERSONA.md reference, all orchestration steps, three self-contained inline agent prompts, input validation heuristics, synthesis instructions, output format templates, mode switch handoff (copy-pasteable commands only, no inline execution), and token tracking. Single file, no dependencies on agent files. |

No other files are created or modified. No new agent files. No new skill files. No task folder created at runtime.

---

## Open Questions — Resolved

| # | Question | Resolution |
|---|---|---|
| OQ1 | Should agents read each other's responses? | No. Parallel execution. Velo's synthesis compensates. See D2. |
| OQ2 | What model tier for discussion agents? | Opus for all three. Quality of thought is the product. See D4. |
| OQ3 | `skills/yo.md` or `commands/yo.md`? | `commands/yo.md`. It orchestrates agents — that's a command, not a skill. See D1. |
| OQ4 | Should discussion output be saved to a file? | No. Zero-artifact by design (D9). User can copy-paste if needed. |
| OQ5 | Maximum question length? | No hard limit. Velo summarises long inputs (D10). |
| OQ6 | Should we reuse existing agent files or write inline prompts? | Inline prompts. Existing agent files have hardcoded build workflows that conflict with advisory mode. See D3, D16. |
| OQ7 | Should `/velo:yo` execute `/velo:new` inline on confirmation? | No. Print draft brief + copy-pasteable command only. Inline execution violates zero-artifact design and creates context pressure. See D8, S2. |
| OQ8 | How should Velo distinguish vague from valid input? | Concrete heuristics: word count + technical specificity for vague, imperative verb + code artifact for implementation. See D17 and Input Validation. |

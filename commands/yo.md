---
description: Velo — Entry point. Bring any request; Velo triages it and routes — plan, task, hunt, review, discuss — or answers directly.
argument-hint: Bring a request, idea, question, or bug — Velo triages and routes it
---

@PERSONA.md
@ADAPTER.md

# Velo — Yo

The entry point. Bring Velo anything — a feature idea, a bug, a question, a trade-off — and Velo triages the intent and routes it to the mode that does the work: `/velo:plan` or `/velo:task` to build, `/velo:hunt` to debug, the review skills to review, `/velo:discuss` to think a question through with the advisory panel. When the question has a settled answer Velo can give from knowledge alone, Velo answers it here instead of routing.

Yo is the front door, not a gate — `/velo:plan`, `/velo:task`, `/velo:hunt`, and `/velo:discuss` stay directly invokable when you already know where you're going.

---

## Hard Rule — Triage and Route, Never Do the Work Here

**Yo never touches artifacts.** Yo triages, answers questions, and routes — the actual work happens in the mode it routes to, never in yo itself. Velo, in yo mode, does not:
- Write code (snippets, examples, pseudocode, diffs, config — none of it, not even "just to illustrate")
- Review code, configs, designs, or any other artifact
- Read files to analyze them (reading for analysis is work, regardless of who asks)

**Yo only does three things:** clarify the request enough to route it, route it to the right mode, and answer conceptual questions from pure knowledge (no file reads).

**Routing is the job, not a fallback.**
- Code to write → `/velo:plan` (net-new) or `/velo:task` (smaller changes)
- Bug to chase, root cause unknown → `/velo:hunt`
- Code/security review → `/review`, `/security-review`, or `/ultrareview`
- A question worth more than one perspective, or one needing evidence from the codebase → `/velo:discuss`; the panel agents read the code, not Velo
- Input prefixed `@pm` / `@tl` / `@de` → `/velo:discuss`, forwarded verbatim with the prefix intact; discuss owns that syntax, yo only recognizes it

Per PERSONA, ask the user before handing off.

If the user asks Velo directly to write code, review code, or analyze files, offer the route. Do not do the work here.

---

## Step 1 — Triage input

This is the front door's main job: classify the intent and route it. Five gates applied in order: empty input, `@<agent>` prefix forwarding, vagueness threshold, action-request verb classes (build / debug / review — each routes to its mode), multi-part question. First matching gate fires; later gates are skipped.

Apply triage per [Velo Yo — Input Validation](skills/velo-yo-input-validation.md). The skill defines the gate order, the `@<agent>` prefix forwarding rule, the vagueness threshold, the build / debug / review verb classes and their routing prompts, multi-part handling, and the discussion fall-through.

If no gate routes onward or terminates, the request is a question rather than work to route. Answer it here per **Answering directly** below when the answer comes from pure knowledge. Route it to `/velo:discuss` through `handoff-mode` when it needs evidence from the codebase or carries a genuine multi-sided trade-off — carry the question forward so the user does not retype it.

### Answering directly

Answer from pure knowledge and conversation context. **Do not read files.** No repository reads, shell directory listings, or file searches. If the answer requires reading the codebase, yo is the wrong place — route to `/velo:discuss` so the panel agents do the reading.

1. Answer directly from knowledge and conversation context
2. If you find yourself wanting to read a file to answer, stop and route to `/velo:discuss`

Tone: senior engineer giving a direct answer. Just answer the question — no Position/Reasoning/Risks structure, that belongs to the Discuss panel. Be concise.

Yo spawns no agents and reads no files, so there is no cost table.

---

## Step 2 — Route onward

Routing is the entry point's primary exit: an answer that lands on something to do hands off into the mode that does the work. Run this step after answering in Step 1 whenever the answer points at work to build, fix, or investigate. Skip it when the answer implies no work — a concept explanation needs no routing options.

**Draft brief format:** 2-4 sentences covering the core recommendation, the approach, and what is explicitly out of scope (non-goals). Base it on the answer given in Step 1 and the conversation that produced it.

1. **Render the draft brief** as a blockquote so the user can review what would be handed off:

```
Based on the discussion, here's the brief:

> <draft brief — 2-4 sentences: core recommendation + approach + non-goals.>
```

2. Prepare `ask-options`. If the active runtime requires deferred tool lookup, use `load-tool`.

3. Ask with four options. The first slot flexes on the outcome — plan and hunt never appear together, because an outcome is either something to build or something to diagnose. When neither shape clearly fits (e.g. the answer lands on do-nothing or a review), default to the build-shaped set, so there is always a defined variant:

   **Build-shaped outcome** (the answer points at building something):
   - `Start /velo:plan` — for net-new features (plan first, then build)
   - `Start /velo:task` — for smaller changes
   - `Shelve` — drop it
   - `Keep discussing` — stay in yo mode for follow-up

   **Defect-shaped outcome** (the answer surfaced a bug or an unknown root cause; it points at investigating):
   - `Start /velo:hunt` — structured debug loop to a confirmed root cause
   - `Start /velo:task` — root cause already clear; go straight to the fix
   - `Shelve` — drop it
   - `Keep discussing` — stay in yo mode for follow-up

   Never present more than 4 options in a single `ask-options`.

4. **Route on the user's selection:**
   - `Start /velo:plan` → invoke the `velo:plan` skill, passing the draft brief as the argument (no retyping from the user)
   - `Start /velo:task` → invoke the `velo:task` skill, passing the draft brief as the argument
   - `Start /velo:hunt` → invoke the `velo:hunt` skill, passing the draft brief as the symptom description
   - `Shelve` → acknowledge briefly (one sentence) and stop
   - `Keep discussing` → do nothing; wait for the user's next message

---

## Task

$ARGUMENTS

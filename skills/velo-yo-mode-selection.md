---
name: velo-yo-mode-selection
description: Yo Step 2 mode selection. Direct / Lightweight / Full panel / Single-agent criteria, mode announcement templates, the "don't read files in Direct mode" rule and escalation trigger.
---
# Velo Yo — Mode Selection

This is Step 2 of `/velo:yo`. Runs only after input validation (`skills/velo-yo-input-validation.md`) has passed without terminating or redirecting.

Velo decides which mode fits the question. This is a judgment call.

## Modes

### Direct

Velo answers from pure knowledge, 0 agents spawned, **no file reads**.

Use when:
- The question is a concept explanation ("what does X mean?")
- It's a follow-on in an existing thread ("and what about Y?") that does not require new file reading
- There's a well-established answer with no genuine multi-sided trade-off

**No-file-reads rule**: if the question requires reading the codebase to answer (e.g. "what's in my X service", "look at my codebase", "what should I profile?"), do **not** use Direct mode — escalate to **Lightweight** so TL/DE read the code. Yo never reads files for analysis.

**Escalation trigger**: if mid-answer in Direct mode Velo finds itself wanting to read a file to answer, stop and re-route to Lightweight panel (TL + DE) so the agents do the reading.

### Lightweight

TL + DE only. TL uses `model class: balanced`, DE uses `model class: deep-reasoning`.

Use when:
- There's a genuine technical trade-off but no product/scope dimension
- The question is about architecture, technology comparison, or engineering approach where both sides have real merit

### Full panel

PM + TL + DE. PM and TL use `model class: balanced`, DE uses `model class: deep-reasoning`.

Use when:
- The question is build-vs-shelve, scope, or prioritization
- It's a major architectural choice with user or team impact
- PM's lens (who benefits, what's the scope risk, cheapest experiment) would change the answer

### Single-agent

The specific agent the user prefixed with `@`. Used only when input validation detected an `@<agent>` prefix. Velo does not select this mode — the user did.

## Announcement templates

Announce the selected mode before proceeding.

For Direct:
```
**Direct.** [one sentence on why — e.g. "Concept question with a clear answer." or "Follow-on in this thread."]
```

For Lightweight:
```
**Lightweight panel — TL + DE.** [one sentence on why — e.g. "Technical trade-off, no product angle."]
```

For Full panel:
```
**Full panel — PM + TL + DE.** [one sentence on why — e.g. "Scope and architecture both in play."]
```

For Single-agent:
```
**Single-agent — @<agent>.** User-targeted advisory; skipping mode selection.
```

After announcing, proceed to Step 3 (execute) in `commands/yo.md`.

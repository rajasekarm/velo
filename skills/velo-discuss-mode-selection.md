---
name: velo-discuss-mode-selection
description: Discuss Step 2 mode selection. How discuss shapes the advisory panel — Lightweight / Full panel / Single-agent criteria and the mode announcement templates.
---
# Velo Discuss — Mode Selection

This is Step 2 of `/velo:discuss`. Runs after input handling (Step 1) has passed without terminating.

Everything that reaches **Step 2** is a discussion — not everything that reaches discuss. Discuss is invocable directly as well as by a route from `/velo:yo`, so work does sometimes arrive unfiltered; Step 1's gates are what make the premise true by the time mode selection runs, having already stopped a too-vague question and offered to reroute an unambiguous action request.

Triage proper is still `/velo:yo`'s job — build intent to `/velo:plan` or `/velo:task`, debug intent to `/velo:hunt`, review intent to the review skills. Step 1 does not duplicate that taxonomy; it only protects the panel from spending agents on an input no panel can answer. A decided discussion routes again at Step 7 to plan, task, or hunt, and review requests raised mid-discussion route via the Hard Rule.

The modes below are the shapes the discussion can take. Velo decides which one fits the question. This is a judgment call.

## Modes

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

The specific agent the user prefixed with `@`. Used only when input handling detected an `@<agent>` prefix. Velo does not select this mode — the user did.

## Announcement templates

Announce the selected mode before proceeding.

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

After announcing, proceed to Step 3 (execute) in `commands/discuss.md`.

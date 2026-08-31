---
name: ask
description: Use when the user asks for /velo:ask or velo:ask, or brings Velo a conceptual question to answer in place — off-axis and read-only, answered from model knowledge and the current conversation only; never reads the repository, runs tools, writes artifacts, or starts another mode.
---

# Velo Ask

This is the Codex-discoverable wrapper for Velo V2's Ask mode — off-axis, read-only Q&A. In this repo namespace, it should appear as `velo:ask`.

This wrapper is self-contained. Velo V2 has no AGENTS.md, ADAPTER.md, or PERSONA.md; do not go looking for them. The plugin root is the directory reached by walking up from this `SKILL.md` to the directory containing `commands/ask.md`.

## Load Order

1. Read `commands/ask.md` from the plugin root for the Ask playbook. That is the only file to read, and reading it is mode bootstrap — loading the playbook, not answering the question.

## Codex Adaptation

- Treat this as a Codex wrapper around the Ask playbook in `commands/ask.md`; the playbook's Hard Rule is the contract and applies verbatim.
- Do not treat this wrapper as an automatic Codex slash command.
- Once the playbook is loaded, answer with zero tool calls: no repository reads, no shell, no browsing, no connectors, no subagents, no writes. Model knowledge and the current conversation are the only sources.
- An Ask invocation returns only a conversational answer. Create no `.velo` task, draft, carrier, branch, commit, PR, or resumable session record — no durable state at all.
- Empty input: ask the user for a question and stop.
- Requests to build, debug, review, or investigate: suggest the Velo route by name (Pair, Run, or Auto, per the playbook) but never start, invoke, or simulate another mode — this build of Velo ships Ask only.
- If a Claude-only instruction in the playbook cannot be mapped cleanly, state the mismatch and choose the closest Codex-native behavior that keeps the read-only contract intact.

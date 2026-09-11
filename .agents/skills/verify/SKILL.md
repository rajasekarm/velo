---
name: verify
description: Use when the user asks for /velo:verify or velo:verify, or asks Velo to check existing changes against acceptance criteria using browser, API, or command evidence. Reports pass, fail, or blocked; does not fix code, approve plans, or commit changes.
---

# Velo Verify

Verify checks existing behavior against stated expectations and reports evidence. It can run standalone or supply acceptance evidence to Run. It never implements fixes or approves a plan.

## Load order

Read [the shared Verify playbook](../../../commands/verify.md) first, resolving from this plugin root rather than the target repository. Load [browser verification](references/browser-verification.md) only for browser checks. Follow the installed browser tool's instructions only after selecting a provider that is actually available.

The shared playbook defines scope, evidence, results, and the Run handback on both hosts. Do not treat this wrapper as an automatic Codex slash command. Do not launch Run or Plan from standalone Verify.

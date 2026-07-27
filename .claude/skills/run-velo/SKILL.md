---
name: run-velo
description: Run and drive the Velo plugin — load it into a real Claude Code session, verify commands/agents/skills actually load after an edit, run the integrity audit, and fire live routing probes that invoke /velo:yo headless and grade which mode it routes to. Use when asked to run, start, test, verify, or smoke-check velo, to confirm a command/agent/skill edit took effect, or to check that mode routing still works.
---

# Run Velo

Velo is a **Claude Code + Codex plugin**, not a service: 5 commands (`commands/*.md`),
17 agents (`agents/*.md`), ~40 skill files (`skills/*.md`), plus a Codex wrapper layer
(`.agents/skills/velo-*/SKILL.md`). There is nothing to compile and no port to open —
**the running app is a Claude Code session with the plugin loaded**, and "driving it"
means invoking `/velo:yo` and watching where it routes.

The driver is [.claude/skills/run-velo/driver.mjs](driver.mjs). It has two halves:

| | what it does | cost |
|---|---|---|
| `check` | static gauntlet against the plugin runtime: manifest, component inventory, where the runtime loads velo from, Codex parity, `scripts/audit.sh` | ~15 s, no model calls |
| `probe` | live `claude -p` sessions that invoke `/velo:yo` and grade the routing decision | 30–110 s and $0.20–0.80 **per case** |

All paths below are relative to the repo root (`/Users/rajasekarm/Documents/focus/velo`).

## Prerequisites

Nothing to install. Verified present:

```bash
claude --version   # 2.1.220 (Claude Code) — needs `claude plugin details|validate`
node --version     # v22.12.0 — driver is plain ESM, zero deps
```

No build step. No `package.json`. Velo is loaded from the working tree — see
`live-source` below.

## Run: static gauntlet (start here)

```bash
node .claude/skills/run-velo/driver.mjs check
```

Actual output on this branch (`velo/plan-mode-unification`):

```
=== velo check (repo: /Users/rajasekarm/Documents/focus/velo) ===

  ⚠ manifest — 17 warning(s), 17 agent(s) have no frontmatter description
  ✓ marketplace — marketplace.json passes --strict
  ✓ inventory — 5 skills + 17 agents loaded, ~463 tok always-on
  ⚠ live-source — velo@local recorded at cache copy …/plugins/cache/local/velo/1.0.0 —
    that copy is stale (no commands/yo.md) yet /velo:yo works, so sessions load the
    repo working tree. Edit the repo, never the cache.
  ⚠ codex-parity — no .agents/skills/velo-<cmd>/SKILL.md wrapper for: plan
  ✗ audit — === Result: FAIL (2 error(s), 45 warning(s)) === → …

=== FAIL (1 failure(s), 3 warning(s)) ===
```

Exit 1 on any `✗`; `⚠` still exits 0. **The three warnings and the one failure above
are the pre-existing state of this branch, not something you broke** — the two audit
failures reproduce identically at `HEAD` (verified in a detached worktree). See Gotchas.

`inventory` is the check that earns its keep: it diffs `claude plugin details velo`
(what the *runtime* sees) against `commands/` and `agents/` on disk, so adding
`commands/foo.md` and forgetting to make it loadable shows up as a hard failure. The
token figure it echoes is informational only — it is environment-dependent (~463 tok in
a normal shell, ~273 tok under `env -i`, same inventory), so nothing asserts on it.

## Run: live routing probes

```bash
node .claude/skills/run-velo/driver.mjs cases          # list fixtures
node .claude/skills/run-velo/driver.mjs probe hunt     # one case
node .claude/skills/run-velo/driver.mjs probe all      # all four (~4.5 min, ~$1.80)
```

Each case spawns a real headless session:

```bash
claude -p --model sonnet --permission-mode plan \
  --disallowed-tools 'Agent Task Edit Write NotebookEdit' \
  --output-format json --json-schema '<verdict schema>' "/velo:yo <fixture>"
```

and grades `structured_output.recommended_mode` against the fixture's expectation.
Full transcripts (cost, turns, session id) land in
`.velo/run-artifacts/probe-<timestamp>/<case>.json` — `.velo` is gitignored.

Real `probe all` output on this branch:

```
=== velo probe (sonnet) — transcripts: .velo/run-artifacts/probe-2026-07-26T15-02-46-111Z ===
    4 case(s), ~1.5-4 min each

  ✓ hunt — → hunt (want hunt) [gated] 110s $0.78 :: The DAG announcement in commands/task.md
      is not conditional anywhere in the state machine — PLAN_AND_ANNOUNCE is mandatory…
  ✓ task — → task (want task) [NO GATE] 55s $0.32 :: Build-verb request ("add") targeting a
      concrete, existing artifact (scripts/audit.sh) with a well-understood, scoped change…
  ✓ plan — → plan (want plan) [gated] 32s $0.21 :: Net-new, multi-component build with no
      existing scaffolding — warrants upfront design…
  ✓ answer — → answer (want answer) [NO GATE] 71s $0.46 :: The input asks Velo to explain an
      existing distinction (light vs heavy tier in /velo:plan's depth gate)…

=== PASS (4/4 routed as expected) ===
```

Knobs: `VELO_PROBE_MODEL` (default `sonnet`), `VELO_PROBE_TIMEOUT_MS` (default 420000),
`CLAUDE_BIN`.

**Always read the `reason` before believing a `✗`.** An earlier `hunt` fixture ("audit.sh
exits 1, which assertion is tripping?") routed to `task` — correctly, because one grep
finds the answer, so there was nothing to hunt. Two of the four fixtures here were wrong
before Velo was.

## Run: one agent, directly

The cheapest way to check that an edit to `agents/<role>.md` loads and reads the way
you intended — no orchestration, one turn:

```bash
claude -p --agent tech-lead --model haiku --permission-mode plan \
  "Without reading files, state your role in one sentence."
# → I'm the Tech Lead — I turn approved technical specs into concrete engineering
#   design docs (API contracts, data models, task breakdowns) and get sign-off…
```

Use the **bare** agent name. `--agent velo:tech-lead` does *not* error — it silently
loads no agent at all and you get a generic assistant ("Hey! What's on your mind?").

Free-form drive of any mode (streams the reply straight to your terminal):

```bash
node .claude/skills/run-velo/driver.mjs ask \
  "/velo:yo In one sentence: should ADAPTER.md own model classes, or should each agent file?"
# → **Answer:** ADAPTER.md should own model classes — it already does (the Model Classes
#   table maps balanced/deep-reasoning to concrete runtime models), so agent files and
#   TEAM.md only declare intent, keeping runtime-model changes to one file instead of 17+.
```

## Run: human path

```bash
claude          # interactive, then type /velo:yo
```

Same plugin, same working tree — and the only path where Velo's approval gates can
render an `AskUserQuestion` popup instead of a "waiting on you" paragraph. **Not
exercised while writing this skill** (no TTY available); everything else here was.

## Test

```bash
./scripts/audit.sh                        # what CI runs (.github/workflows) — 5 checks
bash tests/task-workflow-contract.test.sh  # one contract test, fails fast with the assertion
```

`audit.sh` check 5 runs every `tests/*.test.sh`; the tests are string-contract
assertions over the markdown (does `commands/task.md` still contain
`lightweight delegated flow`), so prose edits break them and that is intentional.

## Gotchas

- **The installed plugin points at a stale cache copy, but sessions load the repo.**
  `installed_plugins.json` records `velo@local` at
  `~/.claude/plugins/cache/local/velo/1.0.0` — a frozen 2026-04-11 snapshot at commit
  `6c2417a` whose `commands/` holds only `velo.md` (no `yo.md`, no `plan.md`). Yet
  `/velo:yo` and `/velo:plan` both work and `claude plugin details velo` lists all 5,
  because the `local` marketplace is a *directory* source (`known_marketplaces.json` →
  `installLocation: <repo>`) and `~/.claude/plugins/local/velo` is a symlink to the
  repo. **Net: edit the repo; the cache is dead weight.** `check`'s `live-source` line
  re-derives this every run.
- **`--plugin-dir .` does not give you a clean-room load.** It registers a second
  `velo@inline`, collides with the already-installed `velo@local`, and a session
  started that way reported zero velo commands. There is no working isolation trick —
  an isolated `CLAUDE_CONFIG_DIR` hangs forever (fresh-config onboarding, no TTY, had
  to `pkill`). Drive the installed plugin instead.
- **Yo never completes a handoff headless — by design.** `PERSONA.md` makes yo ask
  before routing, so every `-p` turn ends "awaiting your approval." An early probe
  schema asked "what mode did you end in" and got `clarify` on a perfectly-correct
  turn. The driver grades `recommended_mode` + reports `awaiting_user_approval` as a
  separate field, which is why a passing probe prints `[gated]`. That field is
  *self-reported*, not observed — the `task` case reports `[NO GATE]`, so treat it as a
  hint to go read the transcript, not as evidence a gate is missing.
- **Velo triages against the cwd, so app-shaped fixtures are wrong here.** A probe of
  "the login button does nothing in prod" made Velo spawn an Explore agent, discover
  velo has no frontend at all, and refuse to route — correct behavior, useless test.
  All fixtures are about *this* repo.
- **A hunt fixture needs a genuinely unknown cause.** "audit.sh exits 1, which
  assertion?" routes to `task`, because one grep finds the answer and there is nothing
  to hunt. Velo is right and the fixture is wrong.
- **Leave the Agent/Task tools disabled in probes.** Yo itself spawns nothing, but a
  probe that follows a route into `/velo:discuss` lands in the advisory panel, which
  fans out to subagents; with them enabled one probe ran past 9 minutes and had to be
  killed. Disabled, cases land in 32–140 s. But do not strip *everything*: with
  `Read`/`Grep` also gone, yo spends the turn complaining it has no tools and returns
  `clarify`.
- **`--permission-mode plan` is the right sandbox for a probe** (read-only by design),
  but headless plan mode has two quirks: `ExitPlanMode` is not actually callable, so
  every run ends with the session noting it "can't formally close out plan mode" (the
  answer above it is still complete), and it writes a stray plan file to
  `~/.claude/plans/<slug>.md`. Both are cosmetic. Do not pile a broad
  `--disallowed-tools` list on top — strip `Read`/`Grep` too and the turn dead-ends.
- **`--disallowed-tools` is variadic and will eat your prompt.** `claude -p
  --disallowed-tools 'Edit Write' "/velo:yo hi there"` dies with `Input must be
  provided either through stdin or as a prompt argument`, after printing
  `Permission deny rule "/velo:yo" matches no known tool` for every word. Always put
  another flag between it and the prompt (the driver wedges `--output-format` in).
- **`--output-format json` + `--json-schema` compose**, and `structured_output` gives
  you the parsed object. Parse **stdout only**: `claude` writes a workspace-trust
  warning to stderr, so `2>&1 | python3 -m json.tool` blows up on line 1.
- **All 17 agents ship with no frontmatter `description:`** (only `model:`). That is
  why the Agent-tool listing shows every one as "Agent from velo plugin" and Claude
  has nothing to match on when choosing an agent. `claude plugin validate
  .claude-plugin/plugin.json` reports all 17; the dir form (`validate .`) checks only
  the marketplace manifest and stays silent about them.
- **`commands/plan.md` has no Codex wrapper.** `.agents/skills/` has
  `velo-task`, `velo-yo`, `velo-hunt`, `velo-discuss` — no `velo-plan` — so the flagship
  mode is Claude-only, and `tests/codex-velo-skill.test.sh` does not assert it, so no
  test catches the gap.
- **`audit.sh` fails on this branch at `HEAD`, not just in your working tree:**
  `commands/task.md` no longer contains `lightweight delegated flow`. That is a contract
  test that the retirement commits outran. Expect a red audit until it is reconciled.
- **The 45 audit warnings are load-bearing noise.** Check 4 flags every
  `skills/*.md` not referenced by an agent — but the orchestrator-composed skills
  (`velo-plan-dag.md`, `velo-gates.md`, `velo-task-status.md`, …) are pulled in by
  *commands*, which check 4 does not scan. Do not "fix" them by wiring them into agents.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `Ignoring 5 permissions.allow entries from .claude/settings.local.json: this workspace has not been trusted` on every `claude` call | Benign — only the local permission allowlist is dropped, the plugin still loads. Silence it by accepting the trust dialog once interactively, or set `projects["<repo>"].hasTrustDialogAccepted: true` in `~/.claude.json`. |
| `check` → `✗ live-source — no marketplace resolves to <repo>` | Velo isn't registered on this machine: `claude plugin marketplace add . && claude plugin install velo@local`. Those two are the only commands in this file that were not exercised — velo was already registered here (`claude plugin marketplace list` → `local → Directory (<repo>)`). |
| `check` → `✗ inventory — commands not exposed as skills: foo` | The runtime does not see `commands/foo.md`. Re-run `claude plugin details velo` by hand; if it is also missing there, the file is malformed (frontmatter) rather than mis-wired. |
| `probe` → `timed out after 420s` | Something re-enabled subagent fan-out, or the model is thinking hard. Raise `VELO_PROBE_TIMEOUT_MS`, or check the transcript in `.velo/run-artifacts/`. |
| `probe` → `unparseable output` | `claude` failed before emitting JSON (auth, rate limit). Re-run the same prompt by hand without `--output-format json` to see the raw error. |
| Probe routes somewhere plausible but "wrong" | Read the `reason` field before blaming Velo — twice here the fixture was wrong, not the router. |

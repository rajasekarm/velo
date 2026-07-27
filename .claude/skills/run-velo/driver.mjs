#!/usr/bin/env node
// driver.mjs — run and drive the Velo plugin.
//
// Velo has no server and no UI: the "running app" is Claude Code with the velo
// plugin loaded. So this driver has two halves:
//
//   check  — static gauntlet against the plugin runtime (no model calls, ~15s)
//   probe  — live routing probes: real `claude -p` sessions that invoke
//            /velo:yo and report which mode Velo routed to (model calls, slow)
//
// Usage (from the repo root):
//   node .claude/skills/run-velo/driver.mjs check
//   node .claude/skills/run-velo/driver.mjs cases
//   node .claude/skills/run-velo/driver.mjs probe hunt
//   node .claude/skills/run-velo/driver.mjs probe all
//   node .claude/skills/run-velo/driver.mjs ask "/velo:yo <anything>"
//
// Exit codes: 0 = pass (warnings allowed), 1 = hard failure, 2 = driver error.

import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const SKILL_DIR = dirname(fileURLToPath(import.meta.url));
const REPO = resolve(SKILL_DIR, '../../..');
const CLAUDE = process.env.CLAUDE_BIN || 'claude';
const PLUGIN_HOME = join(homedir(), '.claude', 'plugins');
const ARTIFACTS = join(REPO, '.velo', 'run-artifacts');

// Probe timeout. Yo itself spawns nothing, but a probe that follows a route into
// /velo:discuss lands in the advisory panel, which fans out to subagents and can run
// past 10 minutes. Probes disable the Agent tool and cap here.
const PROBE_TIMEOUT_MS = Number(process.env.VELO_PROBE_TIMEOUT_MS || 420_000);
const PROBE_MODEL = process.env.VELO_PROBE_MODEL || 'sonnet';

const results = [];
const record = (name, status, detail) => {
  results.push({ name, status, detail });
  const icon = { pass: '✓', warn: '⚠', fail: '✗' }[status];
  console.log(`  ${icon} ${name} — ${detail}`);
};

const sh = (cmd, args, opts = {}) =>
  spawnSync(cmd, args, { cwd: REPO, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024, ...opts });

const mdFiles = (dir) =>
  existsSync(join(REPO, dir)) ? readdirSync(join(REPO, dir)).filter((f) => f.endsWith('.md')) : [];

const readJson = (path) => {
  try {
    return JSON.parse(readFileSync(path, 'utf8'));
  } catch {
    return null;
  }
};

// ---------------------------------------------------------------------------
// check — static gauntlet
// ---------------------------------------------------------------------------

// 1. Does the runtime accept the plugin manifest, and every agent it points at?
//    Passing the plugin.json path (not the repo dir) makes `validate` walk the
//    agents too — passing the dir only validates the marketplace manifest.
function checkManifest() {
  const r = sh(CLAUDE, ['plugin', 'validate', '.claude-plugin/plugin.json']);
  const out = `${r.stdout}${r.stderr}`;
  const warnings = (out.match(/^\s+❯ /gm) || []).length;
  if (r.status !== 0) return record('manifest', 'fail', out.trim().split('\n').slice(-6).join(' / '));
  const noDesc = (out.match(/No description in frontmatter/g) || []).length;
  const validated = (out.match(/^Validating agent:/gm) || []).length;
  if (warnings === 0) return record('manifest', 'pass', `plugin.json + ${validated} agents validate clean`);
  record(
    'manifest',
    'warn',
    `${warnings} warning(s)${noDesc ? `, ${noDesc} agent(s) have no frontmatter description` : ''}`,
  );
}

function checkMarketplace() {
  const r = sh(CLAUDE, ['plugin', 'validate', '.', '--strict']);
  const out = `${r.stdout}${r.stderr}`;
  if (r.status !== 0) return record('marketplace', 'fail', out.trim().split('\n').slice(-4).join(' / '));
  record('marketplace', 'pass', 'marketplace.json passes --strict');
}

// 2. Does the runtime's component inventory match what is on disk? This is the
//    check that catches "I added commands/plan.md but the session never sees it".
function checkInventory() {
  const r = sh(CLAUDE, ['plugin', 'details', 'velo']);
  if (r.status !== 0) {
    return record('inventory', 'fail', `claude plugin details velo failed: ${(r.stderr || '').trim().slice(0, 200)}`);
  }
  const out = r.stdout;
  const skills = (out.match(/Skills \(\d+\)\s+(.+)/) || [, ''])[1].split(',').map((s) => s.trim()).filter(Boolean);
  const agents = (out.match(/Agents \(\d+\)\s+(.+)/) || [, ''])[1].split(',').map((s) => s.trim()).filter(Boolean);
  const onDiskCommands = mdFiles('commands').map((f) => f.replace(/\.md$/, '')).sort();
  const onDiskAgents = mdFiles('agents').map((f) => f.replace(/\.md$/, '')).sort();

  const missingSkills = onDiskCommands.filter((c) => !skills.includes(c));
  const missingAgents = onDiskAgents.filter((a) => !agents.includes(a));
  const ghostSkills = skills.filter((s) => !onDiskCommands.includes(s));

  if (missingSkills.length || missingAgents.length || ghostSkills.length) {
    return record(
      'inventory',
      'fail',
      [
        missingSkills.length && `commands not exposed as skills: ${missingSkills.join(', ')}`,
        missingAgents.length && `agents not loaded: ${missingAgents.join(', ')}`,
        ghostSkills.length && `skills with no command file: ${ghostSkills.join(', ')}`,
      ]
        .filter(Boolean)
        .join('; '),
    );
  }
  const alwaysOn = (out.match(/Always-on:\s+~?([\d.]+k?) tok/) || [, '?'])[1];
  record('inventory', 'pass', `${skills.length} skills + ${agents.length} agents loaded, ~${alwaysOn} tok always-on`);
}

// 3. WHERE does the runtime load velo from? velo is installed as velo@local off
//    a directory marketplace, and there is also a frozen copy under
//    plugins/cache. Editing the wrong one is the classic wasted afternoon.
function checkLiveSource() {
  const markets = readJson(join(PLUGIN_HOME, 'known_marketplaces.json'));
  const installed = readJson(join(PLUGIN_HOME, 'installed_plugins.json'));
  if (!markets || !installed) {
    return record('live-source', 'warn', `could not read ${PLUGIN_HOME}/{known_marketplaces,installed_plugins}.json`);
  }
  const entry = Object.entries(markets).find(([, v]) => resolve(v?.installLocation || '') === REPO);
  if (!entry) {
    return record(
      'live-source',
      'fail',
      `no marketplace resolves to ${REPO} — run: ${CLAUDE} plugin marketplace add . && ${CLAUDE} plugin install velo@local`,
    );
  }
  const [market] = entry;
  // installed_plugins.json is {version, plugins: {"<name>@<marketplace>": [...]}}
  const installs = (installed.plugins || installed)[`velo@${market}`];
  if (!installs?.length) {
    return record('live-source', 'fail', `marketplace '${market}' points at the repo but velo@${market} is not installed`);
  }
  const installPath = installs[0].installPath || '';
  if (installPath.startsWith(join(PLUGIN_HOME, 'cache'))) {
    const cachedYo = join(installPath, 'commands', 'yo.md');
    const stale = !existsSync(cachedYo);
    return record(
      'live-source',
      'warn',
      `velo@${market} recorded at cache copy ${installPath}` +
        (stale
          ? ' — that copy is stale (no commands/yo.md) yet /velo:yo works, so sessions load the repo working tree. Edit the repo, never the cache.'
          : ' — verify which copy a session actually loads before trusting an edit.'),
    );
  }
  record('live-source', 'pass', `velo@${market} loads from ${installPath}`);
}

// 4. Codex parity: every Claude command needs a .agents/skills wrapper, or the
//    mode is unreachable from Codex.
function checkCodexParity() {
  const commands = mdFiles('commands').map((f) => f.replace(/\.md$/, ''));
  const missing = commands.filter((c) => !existsSync(join(REPO, '.agents', 'skills', `velo-${c}`, 'SKILL.md')));
  if (missing.length) {
    return record(
      'codex-parity',
      'warn',
      `no .agents/skills/velo-<cmd>/SKILL.md wrapper for: ${missing.join(', ')} — those modes are Claude-only`,
    );
  }
  record('codex-parity', 'pass', `${commands.length} commands each have a Codex wrapper skill`);
}

// 5. The repo's own integrity audit (also what CI runs).
function checkAudit() {
  const r = sh('bash', ['./scripts/audit.sh']);
  const out = `${r.stdout}${r.stderr}`;
  const summary = (out.match(/=== Result: .* ===/) || ['no result line'])[0];
  const failures = (out.match(/^FAIL: .*/gm) || []).map((l) => l.replace(/^FAIL: /, ''));
  if (r.status !== 0) {
    return record('audit', 'fail', `${summary}${failures.length ? ` → ${failures.join(' | ')}` : ''}`);
  }
  record('audit', 'pass', summary);
}

function runCheck() {
  console.log(`\n=== velo check (repo: ${REPO}) ===\n`);
  checkManifest();
  checkMarketplace();
  checkInventory();
  checkLiveSource();
  checkCodexParity();
  checkAudit();

  const fails = results.filter((r) => r.status === 'fail');
  const warns = results.filter((r) => r.status === 'warn');
  console.log(
    `\n=== ${fails.length ? 'FAIL' : 'PASS'} (${fails.length} failure(s), ${warns.length} warning(s)) ===\n`,
  );
  return fails.length ? 1 : 0;
}

// ---------------------------------------------------------------------------
// probe — live routing probes through a real Claude Code session
// ---------------------------------------------------------------------------

// Grade the RECOMMENDATION, not the terminal state. Velo's PERSONA makes yo ask
// before every handoff, so a headless turn always ends waiting on the user —
// asserting on "what did it end up doing" would fail every case by design.
const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    recommended_mode: { type: 'string', enum: ['plan', 'task', 'hunt', 'review', 'discuss', 'answer'] },
    awaiting_user_approval: { type: 'boolean' },
    reason: { type: 'string' },
  },
  required: ['recommended_mode', 'awaiting_user_approval', 'reason'],
};

const ASK = 'Report the mode you recommend routing this to. Do not implement anything.';

// Prompts are deliberately about THIS repo. Velo triages against the cwd, so a
// generic "my login button is broken" prompt correctly stalls here — velo has
// no application code, and yo will say so instead of routing.
const CASES = [
  {
    // A hunt fixture has to be a symptom with a genuinely unknown cause. An
    // earlier version of this case ("audit.sh exits 1, which assertion?") kept
    // routing to task — correctly, because one grep finds the failing assertion,
    // so there is nothing to hunt.
    name: 'hunt',
    expect: ['hunt'],
    prompt: `/velo:yo /velo:task sometimes announces a task DAG before building and sometimes jumps straight to build with no announcement, on the same kind of request. I have no idea what makes it diverge. ${ASK}`,
  },
  {
    name: 'task',
    expect: ['task'],
    prompt: `/velo:yo Add a --json flag to scripts/audit.sh so CI can consume the check results as JSON. ${ASK}`,
  },
  {
    name: 'plan',
    expect: ['plan'],
    prompt: `/velo:yo I want a full eval harness for velo: per-mode eval cases, graders, CI wiring and a scoring report. Nothing exists yet. ${ASK}`,
  },
  {
    // A discuss fixture has to be a question with no settled answer — a genuine
    // multi-sided trade-off, not work. If the prompt implies a decision already made,
    // yo routes to plan or task instead, which is correct and makes the fixture wrong.
    name: 'discuss',
    expect: ['discuss'],
    prompt: `/velo:yo Should velo's per-discipline reviewer agents (be-reviewer, fe-reviewer, db-reviewer, …) collapse into one generalist reviewer, or stay split? I genuinely go back and forth on it and have not decided. ${ASK}`,
  },
  {
    name: 'answer',
    expect: ['answer'],
    prompt: `/velo:yo What is the difference between /velo:plan's light tier and heavy tier? ${ASK}`,
  },
];

function runProbe(testCase, outDir) {
  const args = [
    '-p',
    '--model',
    PROBE_MODEL,
    // plan mode keeps the session read-only by design; Agent/Task are disabled as
    // insurance against a probe following a route into /velo:discuss, whose panel fans
    // out to subagents and blows past any timeout. Yo's own turn spawns nothing.
    '--permission-mode',
    'plan',
    '--disallowed-tools',
    'Agent Task Edit Write NotebookEdit',
    '--output-format',
    'json',
    '--json-schema',
    JSON.stringify(VERDICT_SCHEMA),
    testCase.prompt,
  ];
  const started = Date.now();
  const r = sh(CLAUDE, args, { timeout: PROBE_TIMEOUT_MS });
  const wall = Math.round((Date.now() - started) / 1000);

  // spawnSync signals a timeout via error.code on some Node builds and via a bare
  // SIGTERM on others — check both or a killed probe reads as "unparseable output".
  if (r.error?.code === 'ETIMEDOUT' || r.signal === 'SIGTERM') {
    record(testCase.name, 'fail', `timed out after ${wall}s (raise VELO_PROBE_TIMEOUT_MS)`);
    return;
  }
  let payload = null;
  try {
    payload = JSON.parse(r.stdout);
  } catch {
    record(testCase.name, 'fail', `unparseable output after ${wall}s: ${(r.stdout || r.stderr || '').slice(0, 200)}`);
    return;
  }
  writeFileSync(join(outDir, `${testCase.name}.json`), JSON.stringify(payload, null, 2));

  const verdict = payload.structured_output;
  const cost = payload.total_cost_usd ? `$${payload.total_cost_usd.toFixed(2)}` : '$?';
  if (!verdict?.recommended_mode) {
    record(testCase.name, 'fail', `no structured verdict after ${wall}s (${cost}) — see ${testCase.name}.json`);
    return;
  }
  const gate = verdict.awaiting_user_approval ? 'gated' : 'NO GATE';
  const detail = `→ ${verdict.recommended_mode} (want ${testCase.expect.join('|')}) [${gate}] ${wall}s ${cost} :: ${verdict.reason.slice(0, 140)}`;
  record(testCase.name, testCase.expect.includes(verdict.recommended_mode) ? 'pass' : 'fail', detail);
}

function runProbes(selector) {
  const picked = selector === 'all' ? CASES : CASES.filter((c) => c.name === selector);
  if (!picked.length) {
    console.error(`unknown probe '${selector}'. Known: ${CASES.map((c) => c.name).join(', ')}, all`);
    return 2;
  }
  const outDir = join(ARTIFACTS, `probe-${new Date().toISOString().replace(/[:.]/g, '-')}`);
  mkdirSync(outDir, { recursive: true });
  console.log(`\n=== velo probe (${PROBE_MODEL}) — transcripts: ${outDir} ===`);
  console.log(`    ${picked.length} case(s), ~1.5-4 min each\n`);
  for (const testCase of picked) runProbe(testCase, outDir);

  const fails = results.filter((r) => r.status === 'fail');
  console.log(`\n=== ${fails.length ? 'FAIL' : 'PASS'} (${results.length - fails.length}/${results.length} routed as expected) ===\n`);
  return fails.length ? 1 : 0;
}

// ask — free-form: push any prompt through the loaded plugin, print the text.
function runAsk(prompt) {
  if (!prompt) {
    console.error('usage: driver.mjs ask "/velo:yo <request>"');
    return 2;
  }
  const r = sh(
    CLAUDE,
    [
      '-p',
      '--model',
      PROBE_MODEL,
      '--permission-mode',
      'plan',
      '--disallowed-tools',
      'Edit Write NotebookEdit',
      // --disallowed-tools is variadic: without another flag between it and the
      // prompt, commander eats the prompt's words as tool names and the run dies
      // with "Input must be provided either through stdin or as a prompt argument".
      '--output-format',
      'text',
      prompt,
    ],
    { timeout: PROBE_TIMEOUT_MS, stdio: ['ignore', 'inherit', 'inherit'] },
  );
  // spawnSync signals a timeout via error.code on some Node builds and via a bare
  // SIGTERM on others — check both or a killed probe reads as "unparseable output".
  if (r.error?.code === 'ETIMEDOUT' || r.signal === 'SIGTERM') {
    console.error(`\n[driver] timed out after ${PROBE_TIMEOUT_MS / 1000}s`);
    return 1;
  }
  return r.status ?? 1;
}

// ---------------------------------------------------------------------------

const [cmd, arg] = process.argv.slice(2);
switch (cmd) {
  case 'check':
    process.exit(runCheck());
  case 'probe':
    process.exit(runProbes(arg || 'all'));
  case 'ask':
    process.exit(runAsk(process.argv.slice(3).join(' ')));
  case 'cases':
    for (const c of CASES) console.log(`${c.name.padEnd(8)} expect=${c.expect.join('|')}  ${c.prompt}`);
    process.exit(0);
  default:
    console.log(`usage: node .claude/skills/run-velo/driver.mjs <check|probe [name|all]|ask "<prompt>"|cases>`);
    process.exit(cmd ? 2 : 0);
}

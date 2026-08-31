#!/usr/bin/env bash
# Packaging / discoverability tests for Velo V2's two-mode surface, anchored
# on Ask (Plan's own frontmatter/discoverability lives in
# tests/plan-packaging.test.sh).
#
# Proves:
#   1. Both plugin manifests parse as valid JSON with the required fields, all
#      three manifest versions agree (drift check, not a version pin), and the
#      Codex `skills` path resolves to a real directory holding both skills.
#   2. commands/ask.md and .agents/skills/velo-ask/SKILL.md exist with
#      well-formed frontmatter carrying the keys each host needs to discover
#      and route the Ask command.
#   3. The plugin surface is exactly {Ask, Plan} — no extra commands, skills,
#      registration keys, or V1 orchestration/container files (structural half
#      of the "no excluded modes" contract; the textual half lives in
#      tests/ask-contract.test.sh and tests/plan-contract.test.sh).
#   4. The Codex manifest claims exactly Interactive + Write capability: Write
#      is required because Plan writes `.velo` artifacts. Ask's own read-only
#      guarantee is textual (its Hard Rule pins), not manifest-level.
#
# Conventions follow V1 (velo/tests/*.test.sh): bash, set -euo pipefail, small
# fail/assert helpers, frontmatter parsed with awk scoped to the leading ---
# block. JSON fields are asserted on parsed JSON (python3, already a V1 test
# dependency via `python3 -m json.tool`) rather than formatting-sensitive greps.
set -euo pipefail

# Deterministic glob character ranges (the trigger boundary check below) and
# sort order regardless of the host locale.
export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

claude_plugin="${repo_root}/.claude-plugin/plugin.json"
marketplace="${repo_root}/.claude-plugin/marketplace.json"
codex_plugin="${repo_root}/.codex-plugin/plugin.json"
command_file="${repo_root}/commands/ask.md"
skill_file="${repo_root}/.agents/skills/velo-ask/SKILL.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

command -v python3 >/dev/null || fail "python3 is required to run these tests"

json_field() {
  # Prints the string value at a dotted key path in a JSON file, or nothing if
  # any segment is absent. Exact lookup on parsed JSON, not a grep.
  local file="$1"
  local path="$2"

  python3 - "${file}" "${path}" <<'PY'
import json, sys

node = json.load(open(sys.argv[1]))
for part in sys.argv[2].split("."):
    if not isinstance(node, dict) or part not in node:
        sys.exit(0)
    node = node[part]
print(node if isinstance(node, str) else json.dumps(node))
PY
}

frontmatter_value() {
  # V1 convention (velo/tests/codex-velo-skill.test.sh): value of a YAML
  # frontmatter key, scoped to the leading --- block so a `name:` further down
  # the body cannot satisfy a frontmatter assertion.
  local file="$1"
  local key="$2"

  awk -v key="${key}" '
    NR == 1 { in_frontmatter = ($0 == "---"); next }
    in_frontmatter && $0 == "---" { in_frontmatter = 0; next }
    in_frontmatter && substr($0, 1, length(key) + 2) == key ": " {
      print substr($0, length(key) + 3)
      in_frontmatter = 0
    }
  ' "${file}"
}

assert_frontmatter_block() {
  # Well-formed frontmatter: the file opens with --- on line 1 and closes the
  # block with a second --- line.
  local file="$1"

  [[ -f "${file}" ]] || fail "${file#${repo_root}/} must exist"
  [[ "$(head -n 1 "${file}")" == "---" ]] \
    || fail "${file#${repo_root}/} must open with a --- frontmatter fence on line 1"
  [[ -n "$(awk 'NR > 1 && $0 == "---" { print NR; exit }' "${file}")" ]] \
    || fail "${file#${repo_root}/} must close its frontmatter block with a second ---"
}

# --- 1. Claude Code plugin manifest ------------------------------------------

[[ -f "${claude_plugin}" ]] || fail ".claude-plugin/plugin.json must exist so Claude Code can discover the plugin"
python3 -m json.tool "${claude_plugin}" >/dev/null || fail ".claude-plugin/plugin.json must be valid JSON"

plugin_name="$(json_field "${claude_plugin}" "name")"
[[ "${plugin_name}" == "velo" ]] \
  || fail ".claude-plugin/plugin.json name must be exactly 'velo' so the commands surface as /velo:ask and /velo:plan, but it is '${plugin_name}'"

plugin_version="$(json_field "${claude_plugin}" "version")"
[[ "${plugin_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
  || fail ".claude-plugin/plugin.json version must be a semver string, but it is '${plugin_version}'"

[[ -n "$(json_field "${claude_plugin}" "description")" ]] \
  || fail ".claude-plugin/plugin.json must carry a non-empty description"

# The Ask command is auto-discovered from commands/. A key WHITELIST (not a
# blacklist) so any unexpected key — commands, agents, hooks, mcpServers,
# skills, or one we did not think to ban — fails instead of registering
# additional surface silently.
python3 - "${claude_plugin}" <<'PY'
import json, sys

extra = sorted(set(json.load(open(sys.argv[1]))) - {"name", "version", "description", "author"})
if extra:
    print(f"FAIL: .claude-plugin/plugin.json must carry only name/version/description/author — unexpected keys {extra} could register excluded surface", file=sys.stderr)
    sys.exit(1)
PY

# --- 2. Marketplace manifest --------------------------------------------------

[[ -f "${marketplace}" ]] || fail ".claude-plugin/marketplace.json must exist for local installation"
python3 -m json.tool "${marketplace}" >/dev/null || fail ".claude-plugin/marketplace.json must be valid JSON"

marketplace_source="$(python3 - "${marketplace}" "${plugin_version}" <<'PY'
import json, sys

def fail(msg):
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

plugins = json.load(open(sys.argv[1])).get("plugins")
if not isinstance(plugins, list) or len(plugins) != 1:
    fail(".claude-plugin/marketplace.json must list exactly one plugin — velo is the only plugin in this surface")
entry = plugins[0]
if entry.get("name") != "velo":
    fail(f".claude-plugin/marketplace.json plugin entry must be named 'velo', but it is {entry.get('name')!r}")
if entry.get("version") != sys.argv[2]:
    fail(f".claude-plugin/marketplace.json plugin version {entry.get('version')!r} must match plugin.json version {sys.argv[2]!r}")
if not isinstance(entry.get("source"), str) or not entry["source"]:
    fail(".claude-plugin/marketplace.json plugin entry must carry a non-empty source")
# Claude Code merges manifest fields from marketplace entries, so an entry key
# like "commands" or "hooks" registers surface just as plugin.json would.
# Whitelist the entry's keys for the same reason plugin.json's are.
extra = sorted(set(entry) - {"name", "description", "version", "source", "author"})
if extra:
    fail(f".claude-plugin/marketplace.json plugin entry must not carry {extra} — marketplace entry fields merge into the plugin manifest and could register excluded surface")
print(entry["source"])
PY
)"

[[ -f "${repo_root}/${marketplace_source}/.claude-plugin/plugin.json" ]] \
  || fail ".claude-plugin/marketplace.json source '${marketplace_source}' must resolve to the plugin root"

# --- 3. Codex plugin manifest --------------------------------------------------

[[ -f "${codex_plugin}" ]] || fail ".codex-plugin/plugin.json must exist so Codex can discover the plugin"
python3 -m json.tool "${codex_plugin}" >/dev/null || fail ".codex-plugin/plugin.json must be valid JSON"

codex_name="$(json_field "${codex_plugin}" "name")"
[[ "${codex_name}" == "velo" ]] \
  || fail ".codex-plugin/plugin.json name must be exactly 'velo' so the skill surfaces as velo:ask, but it is '${codex_name}'"

codex_version="$(json_field "${codex_plugin}" "version")"
[[ "${codex_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
  || fail ".codex-plugin/plugin.json version must be a semver string, but it is '${codex_version}'"

# Drift check across all three manifests (marketplace == plugin.json is
# asserted above): the manifests version in lockstep, whatever the number.
[[ "${codex_version}" == "${plugin_version}" ]] \
  || fail ".codex-plugin/plugin.json version '${codex_version}' must match .claude-plugin/plugin.json version '${plugin_version}' — the three manifests version in lockstep"

skills_path="$(json_field "${codex_plugin}" "skills")"
[[ "${skills_path}" == "./.agents/skills/" ]] \
  || fail ".codex-plugin/plugin.json skills must be './.agents/skills/', but it is '${skills_path}'"
[[ -d "${repo_root}/${skills_path}" ]] \
  || fail ".codex-plugin/plugin.json skills path '${skills_path}' must resolve to a real directory"
[[ -f "${repo_root}/${skills_path}/velo-ask/SKILL.md" ]] \
  || fail ".codex-plugin/plugin.json skills directory must contain the velo-ask skill"
[[ -f "${repo_root}/${skills_path}/velo-plan/SKILL.md" ]] \
  || fail ".codex-plugin/plugin.json skills directory must contain the velo-plan skill"

# Deliverable 4: the capability claim is exactly {Interactive, Write} — Write
# is REQUIRED because Plan writes `.velo` artifacts (carrier + index), and
# anything beyond those two would be undeclared surface drift. Ask's read-only
# contract is textual, enforced by its Hard Rule pins in
# tests/ask-contract.test.sh, not by withholding the manifest capability Plan
# needs. Asserted on the parsed capabilities list so wording elsewhere in the
# manifest cannot false-positive.
python3 - "${codex_plugin}" <<'PY'
import json, sys

def fail(msg):
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

caps = json.load(open(sys.argv[1])).get("interface", {}).get("capabilities")
if not isinstance(caps, list) or not caps:
    fail(".codex-plugin/plugin.json interface.capabilities must be a non-empty list")
if "Interactive" not in caps:
    fail('.codex-plugin/plugin.json capabilities must include "Interactive"')
if "Write" not in caps:
    fail('.codex-plugin/plugin.json capabilities must include "Write" — Plan writes .velo artifacts')
extra = sorted(set(caps) - {"Interactive", "Write"})
if extra:
    fail(f'.codex-plugin/plugin.json capabilities must be exactly ["Interactive", "Write"] — unexpected {extra} would claim surface neither mode has')
PY

# Key WHITELIST, mirroring the Claude manifest check: any key outside the
# known packaging shape fails rather than registering surface silently.
# "license" stays allowed even if currently absent, so re-adding it alongside
# a LICENSE file later does not break packaging.
python3 - "${codex_plugin}" <<'PY'
import json, sys

allowed = {"name", "version", "description", "author", "license", "keywords", "skills", "interface"}
extra = sorted(set(json.load(open(sys.argv[1]))) - allowed)
if extra:
    print(f"FAIL: .codex-plugin/plugin.json must carry only {sorted(allowed)} — unexpected keys {extra} could register excluded surface", file=sys.stderr)
    sys.exit(1)
PY

# --- 4. Ask command frontmatter -------------------------------------------------

assert_frontmatter_block "${command_file}"

[[ -n "$(frontmatter_value "${command_file}" "description")" ]] \
  || fail "commands/ask.md frontmatter must carry a non-empty description"
[[ -n "$(frontmatter_value "${command_file}" "argument-hint")" ]] \
  || fail "commands/ask.md frontmatter must carry a non-empty argument-hint"
grep -qF '$ARGUMENTS' "${command_file}" \
  || fail "commands/ask.md must consume \$ARGUMENTS so /velo:ask receives the user's question"

# --- 5. Codex skill frontmatter --------------------------------------------------

assert_frontmatter_block "${skill_file}"

skill_name="$(frontmatter_value "${skill_file}" "name")"
# Whole-value match, per V1's lesson: `name: asking` would satisfy a substring
# check for `name: ask` while exposing the wrong Codex command.
[[ "${skill_name}" == "ask" ]] \
  || fail ".agents/skills/velo-ask/SKILL.md frontmatter name must be exactly 'ask' so Codex exposes velo:ask, but it is '${skill_name}'"

skill_description="$(frontmatter_value "${skill_file}" "description")"
[[ -n "${skill_description}" ]] \
  || fail ".agents/skills/velo-ask/SKILL.md frontmatter must carry a non-empty description"

# V1's prefix + boundary check: the description must trigger on exactly
# /velo:ask — anchored to the start, and the mode name must end at a word
# boundary rather than run on into a longer name.
trigger="Use when the user asks for /velo:ask"
description_tail="${skill_description#"${trigger}"}"
if [[ "${description_tail}" == "${skill_description}" ]]; then
  fail ".agents/skills/velo-ask/SKILL.md frontmatter description must start with '${trigger}', but it is '${skill_description}'"
fi
if [[ "${description_tail}" == [a-z0-9_-]* ]]; then
  fail ".agents/skills/velo-ask/SKILL.md frontmatter description must trigger on exactly '${trigger}', but it runs on into a longer mode name"
fi

# --- 6. Surface enumeration: the surface is EXACTLY {Ask, Plan} ------------------

list_files() {
  # All regular files under a directory, repo-relative, sorted. .DS_Store is
  # macOS Finder noise, not plugin surface, so it cannot make this flaky.
  find "$1" -type f -not -name '.DS_Store' | sed "s|^${repo_root}/||" | sort
}

expected_commands="commands/ask.md
commands/plan.md"
actual_commands="$(list_files "${repo_root}/commands")"
if [[ "${actual_commands}" != "${expected_commands}" ]]; then
  fail "commands/ must contain exactly ask.md and plan.md — Ask and Plan are the only modes in this build; found: $(echo "${actual_commands}" | tr '\n' ' ')"
fi

expected_skills=".agents/skills/velo-ask/SKILL.md
.agents/skills/velo-plan/SKILL.md"
actual_skills="$(list_files "${repo_root}/.agents/skills")"
if [[ "${actual_skills}" != "${expected_skills}" ]]; then
  fail ".agents/skills/ must contain exactly velo-ask/SKILL.md and velo-plan/SKILL.md — Ask and Plan are the only skills in this build; found: $(echo "${actual_skills}" | tr '\n' ' ')"
fi

# V1's orchestration, adapter, role, hook, and container scaffolding must not
# exist in the V2 clean room — nothing here may register or auto-start an
# excluded mode.
for artifact in AGENTS.md ADAPTER.md PERSONA.md TEAM.md agents hooks skills Dockerfile docker-compose.yml compose.yaml; do
  if [[ -e "${repo_root}/${artifact}" ]]; then
    fail "${artifact} must not exist — V2 ships Ask and Plan only, with no orchestration roles, hooks, or container machinery"
  fi
done

echo "PASS: tests/ask-packaging.test.sh"

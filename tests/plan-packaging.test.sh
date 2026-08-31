#!/usr/bin/env bash
# Packaging / discoverability tests for Velo V2 Plan.
#
# Proves Plan is discoverable on both hosts:
#   1. Claude Code — the plugin manifest names the plugin 'velo' (so the
#      command surfaces as /velo:plan) and commands/plan.md exists with
#      well-formed frontmatter (description, argument-hint) and consumes
#      $ARGUMENTS.
#   2. Codex — the Codex manifest's `skills` path resolves to the velo-plan
#      skill, whose frontmatter name is exactly 'plan' (so it surfaces as
#      velo:plan) with a description that triggers on exactly /velo:plan.
#   3. The Codex manifest claims Write capability — Plan writes `.velo`
#      artifacts (the carrier and the index row), so the claim is required.
#
# Manifest shape (key whitelists), the three-way version drift check, and the
# surface enumeration (exactly {ask, plan}) live in tests/ask-packaging.test.sh
# and are not duplicated here. The textual behavior contract lives in
# tests/plan-contract.test.sh.
#
# Conventions follow V1 (velo/tests/*.test.sh): bash, set -euo pipefail, small
# fail/assert helpers, frontmatter parsed with awk scoped to the leading ---
# block. JSON fields are asserted on parsed JSON (python3) rather than
# formatting-sensitive greps.
set -euo pipefail

# Deterministic glob character ranges (the trigger boundary check below) and
# sort order regardless of the host locale.
export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

claude_plugin="${repo_root}/.claude-plugin/plugin.json"
codex_plugin="${repo_root}/.codex-plugin/plugin.json"
command_file="${repo_root}/commands/plan.md"
skill_file="${repo_root}/.agents/skills/velo-plan/SKILL.md"

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

# --- 1. Claude Code discoverability: /velo:plan -----------------------------------

[[ -f "${claude_plugin}" ]] || fail ".claude-plugin/plugin.json must exist so Claude Code can discover the plugin"
python3 -m json.tool "${claude_plugin}" >/dev/null || fail ".claude-plugin/plugin.json must be valid JSON"

plugin_name="$(json_field "${claude_plugin}" "name")"
[[ "${plugin_name}" == "velo" ]] \
  || fail ".claude-plugin/plugin.json name must be exactly 'velo' so the command surfaces as /velo:plan, but it is '${plugin_name}'"

assert_frontmatter_block "${command_file}"

[[ -n "$(frontmatter_value "${command_file}" "description")" ]] \
  || fail "commands/plan.md frontmatter must carry a non-empty description"
[[ -n "$(frontmatter_value "${command_file}" "argument-hint")" ]] \
  || fail "commands/plan.md frontmatter must carry a non-empty argument-hint"
grep -qF '$ARGUMENTS' "${command_file}" \
  || fail "commands/plan.md must consume \$ARGUMENTS so /velo:plan receives the work to plan"

# --- 2. Codex discoverability: velo:plan ------------------------------------------

[[ -f "${codex_plugin}" ]] || fail ".codex-plugin/plugin.json must exist so Codex can discover the plugin"
python3 -m json.tool "${codex_plugin}" >/dev/null || fail ".codex-plugin/plugin.json must be valid JSON"

codex_name="$(json_field "${codex_plugin}" "name")"
[[ "${codex_name}" == "velo" ]] \
  || fail ".codex-plugin/plugin.json name must be exactly 'velo' so the skill surfaces as velo:plan, but it is '${codex_name}'"

skills_path="$(json_field "${codex_plugin}" "skills")"
[[ "${skills_path}" == "./.agents/skills/" ]] \
  || fail ".codex-plugin/plugin.json skills must be './.agents/skills/', but it is '${skills_path}'"
[[ -f "${repo_root}/${skills_path}/velo-plan/SKILL.md" ]] \
  || fail ".codex-plugin/plugin.json skills directory must contain the velo-plan skill"

assert_frontmatter_block "${skill_file}"

skill_name="$(frontmatter_value "${skill_file}" "name")"
# Whole-value match, per V1's lesson: `name: planning` would satisfy a
# substring check for `name: plan` while exposing the wrong Codex command.
[[ "${skill_name}" == "plan" ]] \
  || fail ".agents/skills/velo-plan/SKILL.md frontmatter name must be exactly 'plan' so Codex exposes velo:plan, but it is '${skill_name}'"

skill_description="$(frontmatter_value "${skill_file}" "description")"
[[ -n "${skill_description}" ]] \
  || fail ".agents/skills/velo-plan/SKILL.md frontmatter must carry a non-empty description"

# V1's prefix + boundary check: the description must trigger on exactly
# /velo:plan — anchored to the start, and the mode name must end at a word
# boundary rather than run on into a longer name (e.g. /velo:planner).
trigger="Use when the user asks for /velo:plan"
description_tail="${skill_description#"${trigger}"}"
if [[ "${description_tail}" == "${skill_description}" ]]; then
  fail ".agents/skills/velo-plan/SKILL.md frontmatter description must start with '${trigger}', but it is '${skill_description}'"
fi
if [[ "${description_tail}" == [a-z0-9_-]* ]]; then
  fail ".agents/skills/velo-plan/SKILL.md frontmatter description must trigger on exactly '${trigger}', but it runs on into a longer mode name"
fi

# --- 3. Codex capability claim: Plan needs Write -----------------------------------

# Plan writes the carrier and the index row under .velo/, so the manifest must
# claim Write (alongside Interactive). The exact-set assertion (nothing beyond
# these two) lives in tests/ask-packaging.test.sh; this suite pins the half
# Plan depends on. Asserted on the parsed capabilities list, not a grep.
python3 - "${codex_plugin}" <<'PY'
import json, sys

def fail(msg):
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

caps = json.load(open(sys.argv[1])).get("interface", {}).get("capabilities")
if not isinstance(caps, list) or not caps:
    fail(".codex-plugin/plugin.json interface.capabilities must be a non-empty list")
if "Interactive" not in caps:
    fail('.codex-plugin/plugin.json capabilities must include "Interactive" — Plan is a conversational mode')
if "Write" not in caps:
    fail('.codex-plugin/plugin.json capabilities must include "Write" — Plan writes the .velo carrier and index')
PY

echo "PASS: tests/plan-packaging.test.sh"

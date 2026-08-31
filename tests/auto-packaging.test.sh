#!/usr/bin/env bash
# Packaging / discoverability tests for Velo V2 Auto.
#
# Proves Auto is discoverable on both hosts:
#   1. Claude Code — the plugin manifest names the plugin 'velo' (so the
#      command surfaces as /velo:auto) and commands/auto.md exists with
#      well-formed frontmatter (description, argument-hint) and consumes
#      $ARGUMENTS.
#   2. Codex — the Codex manifest's `skills` path resolves to the velo-auto
#      skill, whose frontmatter name is exactly 'auto' (so it surfaces as
#      velo:auto) with a description that triggers on exactly /velo:auto.
#   3. The Codex manifest claims exactly Interactive + Write capability — Auto
#      writes only through the Plan and Run seams it drives (the carrier, the
#      index row, local commits), so Write is required and anything beyond the
#      two would claim surface no mode has.
#
# Manifest shape (key whitelists), the three-way version drift check, and the
# surface enumeration (exactly {ask, plan, run, auto}) live in
# tests/ask-packaging.test.sh and are not duplicated here. The textual
# behavior contract lives in tests/auto-contract.test.sh.
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
command_file="${repo_root}/commands/auto.md"
skill_file="${repo_root}/.agents/skills/velo-auto/SKILL.md"

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

# --- 1. Claude Code discoverability: /velo:auto -------------------------------------

[[ -f "${claude_plugin}" ]] || fail ".claude-plugin/plugin.json must exist so Claude Code can discover the plugin"
python3 -m json.tool "${claude_plugin}" >/dev/null || fail ".claude-plugin/plugin.json must be valid JSON"

plugin_name="$(json_field "${claude_plugin}" "name")"
[[ "${plugin_name}" == "velo" ]] \
  || fail ".claude-plugin/plugin.json name must be exactly 'velo' so the command surfaces as /velo:auto, but it is '${plugin_name}'"

assert_frontmatter_block "${command_file}"

[[ -n "$(frontmatter_value "${command_file}" "description")" ]] \
  || fail "commands/auto.md frontmatter must carry a non-empty description"
[[ -n "$(frontmatter_value "${command_file}" "argument-hint")" ]] \
  || fail "commands/auto.md frontmatter must carry a non-empty argument-hint"
grep -qF '$ARGUMENTS' "${command_file}" \
  || fail "commands/auto.md must consume \$ARGUMENTS so /velo:auto receives the work to deliver"

# --- 2. Codex discoverability: velo:auto --------------------------------------------

[[ -f "${codex_plugin}" ]] || fail ".codex-plugin/plugin.json must exist so Codex can discover the plugin"
python3 -m json.tool "${codex_plugin}" >/dev/null || fail ".codex-plugin/plugin.json must be valid JSON"

codex_name="$(json_field "${codex_plugin}" "name")"
[[ "${codex_name}" == "velo" ]] \
  || fail ".codex-plugin/plugin.json name must be exactly 'velo' so the skill surfaces as velo:auto, but it is '${codex_name}'"

skills_path="$(json_field "${codex_plugin}" "skills")"
[[ "${skills_path}" == "./.agents/skills/" ]] \
  || fail ".codex-plugin/plugin.json skills must be './.agents/skills/', but it is '${skills_path}'"
[[ -f "${repo_root}/${skills_path}/velo-auto/SKILL.md" ]] \
  || fail ".codex-plugin/plugin.json skills directory must contain the velo-auto skill"

assert_frontmatter_block "${skill_file}"

skill_name="$(frontmatter_value "${skill_file}" "name")"
# Whole-value match, per V1's lesson: `name: automatic` would satisfy a
# substring check for `name: auto` while exposing the wrong Codex command.
[[ "${skill_name}" == "auto" ]] \
  || fail ".agents/skills/velo-auto/SKILL.md frontmatter name must be exactly 'auto' so Codex exposes velo:auto, but it is '${skill_name}'"

skill_description="$(frontmatter_value "${skill_file}" "description")"
[[ -n "${skill_description}" ]] \
  || fail ".agents/skills/velo-auto/SKILL.md frontmatter must carry a non-empty description"

# V1's prefix + boundary check: the description must trigger on exactly
# /velo:auto — anchored to the start, and the mode name must end at a word
# boundary rather than run on into a longer name (e.g. /velo:autopilot).
trigger="Use when the user asks for /velo:auto"
description_tail="${skill_description#"${trigger}"}"
if [[ "${description_tail}" == "${skill_description}" ]]; then
  fail ".agents/skills/velo-auto/SKILL.md frontmatter description must start with '${trigger}', but it is '${skill_description}'"
fi
if [[ "${description_tail}" == [a-z0-9_-]* ]]; then
  fail ".agents/skills/velo-auto/SKILL.md frontmatter description must trigger on exactly '${trigger}', but it runs on into a longer mode name"
fi

# --- 3. Codex capability claim: exactly {Interactive, Write} ------------------------

# Auto writes nothing of its own — its carrier writes and local commits land
# through the Plan and Run playbooks it drives — so Write is required, and
# anything beyond Interactive + Write would be undeclared surface drift for
# the whole plugin. Asserted as the exact set on parsed JSON, mirroring
# tests/ask-packaging.test.sh, so a widened claim fails here too even if that
# suite's copy is ever loosened.
python3 - "${codex_plugin}" <<'PY'
import json, sys

def fail(msg):
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

caps = json.load(open(sys.argv[1])).get("interface", {}).get("capabilities")
if not isinstance(caps, list) or not caps:
    fail(".codex-plugin/plugin.json interface.capabilities must be a non-empty list")
if "Interactive" not in caps:
    fail('.codex-plugin/plugin.json capabilities must include "Interactive" — Auto is a conversational mode')
if "Write" not in caps:
    fail('.codex-plugin/plugin.json capabilities must include "Write" — Auto writes the carrier and commits locally through the Plan and Run seams')
extra = sorted(set(caps) - {"Interactive", "Write"})
if extra:
    fail(f'.codex-plugin/plugin.json capabilities must be exactly ["Interactive", "Write"] — unexpected {extra} would claim surface no mode has')
PY

# ---------------------------------------------------------------------------
# MUTATION MATRIX (verified on scratch copies — the repo itself is never
# mutated). Mutants relevant to THIS suite; the full T2 matrix, including the
# auto-contract rows and the review-round survivors closed after it (B5
# co-occurrence, B1c quorum-denominator, R1 relay net), is persisted at the
# bottom of tests/auto-contract.test.sh. Every row below is CAUGHT.
#
#  id  | file                   | exact edit                                   | expected | caught by
#  M11 | velo-auto/SKILL.md     | frontmatter "name: auto" -> "name: automate" | FAIL     | whole-value name check (sec 2)
#  M01 | commands/velo.md (new) | add a 5th command file                       | FAIL     | (x-suite) ask-packaging commands
#      |                        |                                              |          | enumeration — the surface
#      |                        |                                              |          | enumeration is owned there
# ---------------------------------------------------------------------------

echo "PASS: tests/auto-packaging.test.sh"

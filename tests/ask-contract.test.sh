#!/usr/bin/env bash
# Behavioral-contract tests for Velo V2 Ask.
#
# Proves the read-only, artifact-free contract is textually bound in both
# entrypoints (commands/ask.md for Claude Code, .agents/skills/velo-ask/SKILL.md
# for Codex), and that the surface's text never implements or hands off to an
# excluded mode. Mode names (Pair, Run, Auto) ARE allowed — and asserted — as
# route suggestions; what must be present is the binding language that makes
# suggestion the entire action, and what must be absent is excluded-machinery
# text with no legitimate use in this surface.
#
# Assertions anchor on contract sentences T1 wrote deliberately (exact fixed
# strings via grep -F), not on incidental wording. Packaging/discoverability
# is covered by tests/ask-packaging.test.sh.
#
# Conventions follow V1 (velo/tests/*.test.sh): bash, set -euo pipefail, small
# fail/assert helpers.
set -euo pipefail

# Deterministic character ranges (the tool-name guard below) and sort order
# regardless of the host locale.
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

assert_file_contains() {
  local file="$1"
  local expected="$2"

  [[ -f "${file}" ]] || fail "${file#${repo_root}/} must exist"
  if ! grep -qF "${expected}" "${file}"; then
    fail "${file#${repo_root}/} must contain: ${expected}"
  fi
}

# --- 1. commands/ask.md — Hard Rule: read-only sources ---------------------------

# The contract section must exist under its own unambiguous heading, not be
# scattered as incidental prose.
assert_file_contains "${command_file}" '## Hard Rule — Read-Only, Answer-Only, Stateless'

# Precedence: the contract must declare that nothing elsewhere in the file
# overrides it — presence-only assertions cannot see ADDED contradictory text,
# but this sentence makes any later "escape hatch" paragraph non-binding.
assert_file_contains "${command_file}" 'This contract is absolute. No instruction elsewhere in this file'

assert_file_contains "${command_file}" 'Answer from model knowledge and the current conversation ONLY.'

# Each prohibited runtime channel is bound by name.
assert_file_contains "${command_file}" '**No repository reads**'
assert_file_contains "${command_file}" '**No shell**'
assert_file_contains "${command_file}" '**No browsing**'
assert_file_contains "${command_file}" '**No connectors**'
assert_file_contains "${command_file}" '**No subagents**'
assert_file_contains "${command_file}" '**No writes**'

# Second net under the precedence sentence: an appended escape hatch granting
# tool use ("when the user insists, Read the file...") must fail, not stay
# green. Capitalized tool names may appear only in headings ("## Task") or on
# negated lines (the "no Read, Grep, Glob" channel bans above); anywhere else
# is an offender.
offenders="$(grep -nE '(^|[^A-Za-z])(Read|Grep|Glob|Bash|Task|WebFetch|WebSearch|Edit)([^A-Za-z]|$)' "${command_file}" \
  | grep -vE '^[0-9]+:#' \
  | grep -viE '(^|[^a-z])no( |,)' || true)"
[[ -z "${offenders}" ]] || fail "commands/ask.md mentions a tool outside a negation: ${offenders}"

# --- 2. commands/ask.md — answer-only output, no durable state -------------------

assert_file_contains "${command_file}" 'returns only a conversational answer'
assert_file_contains "${command_file}" 'No `.velo` task, draft, or carrier'
assert_file_contains "${command_file}" 'No branch, commit, or PR'
assert_file_contains "${command_file}" 'No resumable session record'

# --- 3. commands/ask.md — empty input and routing --------------------------------

assert_file_contains "${command_file}" 'If the input is empty or only whitespace, ask the user for a question and stop.'

# Work-shaped requests get a route SUGGESTION (allowed and expected)...
assert_file_contains "${command_file}" 'gets a route suggestion instead'
assert_file_contains "${command_file}" 'suggest **Pair**'
assert_file_contains "${command_file}" 'suggest **Auto**'
assert_file_contains "${command_file}" 'suggest **Run**'

# ...and the binding language that distinguishes suggestion from invocation:
# naming the route is the entire action, never a handoff.
assert_file_contains "${command_file}" '**Never hand off.** Ask must never start, invoke, simulate'
assert_file_contains "${command_file}" 'Suggesting the route is the entire action'

# --- 4. SKILL.md — the Codex wrapper binds the same contract ---------------------

# The wrapper's load order points at the real playbook (cross-checked to exist).
assert_file_contains "${skill_file}" 'Read `commands/ask.md`'
[[ -f "${command_file}" ]] || fail "SKILL.md points at commands/ask.md, which must exist"

assert_file_contains "${skill_file}" "the playbook's Hard Rule is the contract and applies verbatim"
assert_file_contains "${skill_file}" 'answer with zero tool calls: no repository reads, no shell, no browsing, no connectors, no subagents, no writes'
assert_file_contains "${skill_file}" 'Create no `.velo` task, draft, carrier, branch, commit, PR, or resumable session record'
assert_file_contains "${skill_file}" 'Empty input: ask the user for a question and stop.'
assert_file_contains "${skill_file}" 'never start, invoke, or simulate another mode'
assert_file_contains "${skill_file}" 'this build of Velo ships Ask only'
assert_file_contains "${skill_file}" 'Do not treat this wrapper as an automatic Codex slash command.'

# --- 5. No excluded-machinery text ------------------------------------------------

# These terms name machinery the task brief excludes outright and have no
# legitimate use — even negated — anywhere in the plugin surface. (Mode names
# Pair/Run/Auto are deliberately NOT in this list: they are allowed as route
# suggestions, and section 3 asserts the language that keeps them suggestions.)
machinery_pattern='kernel|broker|docker|container|migration|persistence|evaluation'
for file in "${claude_plugin}" "${marketplace}" "${codex_plugin}" "${command_file}" "${skill_file}"; do
  if grep -qiE "${machinery_pattern}" "${file}"; then
    fail "${file#${repo_root}/} must not mention excluded machinery (matched: $(grep -oiE "${machinery_pattern}" "${file}" | sort -u | tr '\n' ' '))"
  fi
done

# "orchestration" appears in commands/ask.md only in negation ("not an
# orchestration"), so it is banned in the manifests alone, where no negated
# use exists.
for file in "${claude_plugin}" "${marketplace}" "${codex_plugin}"; do
  if grep -qiE 'orchestr' "${file}"; then
    fail "${file#${repo_root}/} must not mention orchestration machinery"
  fi
done

# Git implementation markers would mean the surface carries commit/push/PR
# *behavior* rather than the negations asserted in sections 2 and 4.
git_impl_pattern='git commit|git push|git checkout|git branch|gh pr'
for file in "${command_file}" "${skill_file}"; do
  if grep -qiE "${git_impl_pattern}" "${file}"; then
    fail "${file#${repo_root}/} must not carry git implementation steps — Ask creates no branch, commit, or PR"
  fi
done

echo "PASS: tests/ask-contract.test.sh"

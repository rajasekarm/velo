#!/usr/bin/env bash
set -euo pipefail

# Every Claude slash command (commands/<name>.md) must have a matching Codex
# wrapper (.agents/skills/velo-<name>/SKILL.md), and vice versa. Both sides are
# derived from the filesystem on purpose: a hardcoded mode list is what let
# velo:plan ship Claude-only. AGENTS.md documents the same set in prose, so it is
# reconciled against the derived set here for exactly the same reason.
#
# INVARIANT: every commands/*.md is a Velo mode that owes Codex a wrapper. If a
# non-mode reference doc ever belongs in commands/, give it a leading underscore
# (commands/_shared.md) and it is excluded from parity; anything else is treated
# as a mode.
#
# bash 3.2 (stock macOS /bin/bash, what `#!/usr/bin/env bash` resolves to on a
# default macOS dev machine) is the floor. Under `set -u` bash 3.2 errors on
# "${arr[@]}" when arr is empty, so every array loop below is length-guarded.
# Guarding is not the same as passing: zero wrappers with commands present is the
# exact drift this test exists to report, and must produce the normal MISSING
# report rather than a guard failure or a bash-internal crash.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
commands_dir="${repo_root}/commands"
skills_dir="${repo_root}/.agents/skills"
agents_file="${repo_root}/AGENTS.md"
backtick='`'

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

canonical_set() {
  # stdin: one member per line. stdout: members blank-stripped, deduped, sorted
  # and space-joined — a canonical form for comparing two collections as
  # unordered sets.
  awk 'NF { print }' | sort -u | tr '\n' ' ' | sed 's/ $//'
}

documented_mode_mentions() {
  # Prints the <name> of every `velo:<name>` mention in "$1", one per line.
  # Never fails: "no mentions at all" is drift for the caller to report, not a
  # reason to abort the run.
  printf '%s\n' "$1" \
    | grep -o -E "${backtick}velo:[a-z0-9_-]+${backtick}" \
    | tr -d "${backtick}" \
    | sed 's/^velo://' || true
}

[[ -d "${commands_dir}" ]] || fail "commands/ must exist as the Claude slash-command surface"
[[ -d "${skills_dir}" ]] || fail ".agents/skills/ must exist as the Codex wrapper surface"
[[ -f "${agents_file}" ]] || fail "AGENTS.md must exist; it documents the Codex wrapper set this test reconciles"

shopt -s nullglob

command_names=()
for command_file in "${commands_dir}"/*.md; do
  command_name="$(basename "${command_file}" .md)"
  # Underscore-prefixed files are shared reference docs, not modes.
  if [[ "${command_name}" == _* ]]; then
    continue
  fi
  command_names+=("${command_name}")
done

# Split the velo-*/ directories by whether they actually carry a wrapper. A
# directory with no SKILL.md is not a wrapper — it is a half-created one, and
# Direction 3 is the only check that can see it.
wrapper_names=()
scaffold_names=()
for wrapper_dir in "${skills_dir}"/velo-*/; do
  wrapper_name="$(basename "${wrapper_dir}")"
  wrapper_name="${wrapper_name#velo-}"
  if [[ -f "${skills_dir}/velo-${wrapper_name}/SKILL.md" ]]; then
    wrapper_names+=("${wrapper_name}")
  else
    scaffold_names+=("${wrapper_name}")
  fi
done

shopt -u nullglob

# A missing commands/ surface is a broken checkout, not drift — fail loudly.
# Note the deliberate asymmetry: there is no equivalent guard on wrapper_names,
# because zero wrappers is drift the report below must describe.
(( ${#command_names[@]} > 0 )) || fail "commands/ contains no mode playbooks; the parity check has nothing to compare"

violations=()

# Direction 1: Claude command with no Codex wrapper (mode ships Claude-only).
for command_name in "${command_names[@]}"; do
  if [[ ! -f "${skills_dir}/velo-${command_name}/SKILL.md" ]]; then
    violations+=("MISSING CODEX WRAPPER: commands/${command_name}.md exists but .agents/skills/velo-${command_name}/SKILL.md does not, so velo:${command_name} is Claude-only. Create .agents/skills/velo-${command_name}/SKILL.md as a wrapper pointing at commands/${command_name}.md (copy an existing wrapper such as .agents/skills/velo-task/SKILL.md and swap the mode name), and add an assert_wrapper_skill \"velo-${command_name}\" \"${command_name}\" \"commands/${command_name}.md\" call to tests/codex-velo-skill.test.sh. If commands/${command_name}.md is not a mode at all but a shared reference doc, rename it to commands/_${command_name}.md to exclude it from parity.")
  fi
done

# Direction 2: Codex wrapper with no Claude command (wrapper outlived its mode).
if (( ${#wrapper_names[@]} > 0 )); then
  for wrapper_name in "${wrapper_names[@]}"; do
    if [[ ! -f "${commands_dir}/${wrapper_name}.md" ]]; then
      violations+=("ORPHANED CODEX WRAPPER: .agents/skills/velo-${wrapper_name}/SKILL.md exists but commands/${wrapper_name}.md does not, so the Codex wrapper points at a playbook that is gone. Either restore commands/${wrapper_name}.md or delete .agents/skills/velo-${wrapper_name}/ along with its assert_wrapper_skill call in tests/codex-velo-skill.test.sh and its mention in AGENTS.md.")
    fi
  done
fi

# Direction 3: velo-<name>/ directory with no SKILL.md and no command behind it.
# A failed copy or an abandoned rename leaves exactly this shape, and neither
# direction above can see it: Direction 1 only walks commands/, and Direction 2
# only considers directories that already have a SKILL.md. When
# commands/<name>.md does exist, Direction 1 already reports the same directory
# as MISSING, so this stays quiet rather than double-reporting it.
if (( ${#scaffold_names[@]} > 0 )); then
  for scaffold_name in "${scaffold_names[@]}"; do
    if [[ ! -f "${commands_dir}/${scaffold_name}.md" ]]; then
      violations+=("INCOMPLETE CODEX WRAPPER: .agents/skills/velo-${scaffold_name}/ exists but contains no SKILL.md, and commands/${scaffold_name}.md does not exist either, so nothing on either surface backs it — this is the shape a failed copy or an abandoned rename leaves behind. Either finish the mode (add commands/${scaffold_name}.md and .agents/skills/velo-${scaffold_name}/SKILL.md, plus an assert_wrapper_skill \"velo-${scaffold_name}\" \"${scaffold_name}\" \"commands/${scaffold_name}.md\" call in tests/codex-velo-skill.test.sh) or delete .agents/skills/velo-${scaffold_name}/.")
    fi
  done
fi

# Direction 4: AGENTS.md's wrapper sentence is hand-written prose that names the
# mode set twice — once as a brace expansion, once as a run of `velo:<name>`
# mentions. Reconcile both against the derived wrapper set so a sixth mode cannot
# ship with a wrapper and a green parity test while the prose still lists five.
#
# Compared as unordered SETS on purpose. AGENTS.md lists modes in workflow order
# (yo, plan, task, hunt, discuss), which is neither alphabetical nor glob order.
# That ordering is editorial and deliberate; this test reconciles membership only
# and must never force the prose to be re-sorted for the test's convenience.
#
# Skipped when there are no wrappers at all: Direction 1 has already reported
# every mode as MISSING, and demanding that the prose document an empty set on
# top of that is noise, not signal.
if (( ${#wrapper_names[@]} > 0 )); then
  expected_modes="$(printf '%s\n' "${wrapper_names[@]}" | canonical_set)"
  wrapper_sentence="$(grep -F ".agents/skills/velo-{" "${agents_file}" | head -1 || true)"

  if [[ -z "${wrapper_sentence}" ]]; then
    violations+=("MISSING AGENTS.md WRAPPER SENTENCE: AGENTS.md has no line containing \`.agents/skills/velo-{...}/SKILL.md\`, so the documented Codex wrapper set cannot be reconciled against the filesystem. Restore the bullet describing the wrapper files; it must cover exactly these modes: ${expected_modes}.")
  else
    brace_list="${wrapper_sentence#*.agents/skills/velo-\{}"
    brace_list="${brace_list%%\}*}"
    documented_brace_modes="$(printf '%s' "${brace_list}" | tr ',' '\n' | canonical_set)"
    documented_name_modes="$(documented_mode_mentions "${wrapper_sentence}" | canonical_set)"

    if [[ "${documented_brace_modes}" != "${expected_modes}" ]]; then
      violations+=("AGENTS.md WRAPPER SET DRIFT: the \`.agents/skills/velo-{...}/SKILL.md\` brace list in AGENTS.md names [${documented_brace_modes}] but .agents/skills/ actually provides [${expected_modes}]. Update the brace list in AGENTS.md to cover exactly the wrapper set. Only membership is checked, so keep AGENTS.md's existing workflow ordering.")
    fi

    if [[ "${documented_name_modes}" != "${expected_modes}" ]]; then
      violations+=("AGENTS.md SKILL NAME DRIFT: the wrapper sentence in AGENTS.md exposes \`velo:\` names for [${documented_name_modes}] but .agents/skills/ actually provides [${expected_modes}]. Update the \`velo:<mode>\` list in that sentence to cover exactly the wrapper set. Only membership is checked, so keep AGENTS.md's existing workflow ordering.")
    fi
  fi
fi

if (( ${#violations[@]} > 0 )); then
  message="Velo mode surfaces (commands/, .agents/skills/velo-*/, AGENTS.md) are out of parity (${#violations[@]} issue(s)):"
  for violation in "${violations[@]}"; do
    message+=$'\n  - '"${violation}"
  done
  fail "${message}"
fi

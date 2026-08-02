#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
task_file="${repo_root}/commands/task.md"
readme_file="${repo_root}/README.md"
plan_file="${repo_root}/commands/plan.md"
pm_file="${repo_root}/agents/product-manager.md"
tl_file="${repo_root}/agents/tech-lead.md"
de_file="${repo_root}/agents/distinguished-engineer.md"
carrier_file="${repo_root}/skills/velo-task-status.md"
retired_package_skill="${repo_root}/skills/velo-plan-package.md"
skill_files=("${repo_root}"/skills/*.md)

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# Negative guards are case-INSENSITIVE (grep -qiF), so sentence-start
# capitalization flips ("Lightweight delegated flow") and lowercase paraphrases
# don't slip past the guard. Patterns stay full phrases — false-positive risk
# lives in shortened patterns, not in the case flag.
assert_file_not_contains() {
  local file="$1"
  local unexpected="$2"

  if grep -qiF "${unexpected}" "${file}"; then
    fail "${file#${repo_root}/} must not contain stale task workflow claim (case-insensitive): ${unexpected}"
  fi
}

# Positive identifier pins: case-SENSITIVE (grep -qF) — these are literal
# machine-facing tokens with cross-file consumers, so a case change IS a
# break. They close the gutting gap: emptying commands/task.md (or deleting
# its integration surface) passes every negative guard above; these fail it.
assert_file_contains() {
  local file="$1"
  local expected="$2"
  local why="$3"

  if ! grep -qF "${expected}" "${file}"; then
    fail "${file#${repo_root}/} must contain integration token: ${expected} — ${why}"
  fi
}

# Retired-artifact guards. Case-INSENSITIVE by default, for the same reason
# assert_file_not_contains is: these guards read PROSE, and prose capitalizes at
# a sentence start. `Product.txt is no longer created by Step 0.` is a dangling
# instruction about a deleted file, and a case-SENSITIVE `grep -qF "product.txt"`
# reports it clean. An earlier revision of this file argued the opposite — that a
# filename's case is part of its identity, so the guard should be sensitive. That
# argument is right about how a filename behaves on a filesystem and wrong about
# what this guard is scanning: markdown, where the same filename appears
# title-cased in a heading and sentence-cased at a paragraph start and means the
# same retired artifact every time. The false-negative (a retired reference slips
# through) is the failure that matters; the false-positive (an unrelated token
# that differs only in case) has no plausible instance for these filenames.
#
# Pass `sensitive` as the 4th argument to opt out. Exactly one call site does —
# `Depends On`, where case is the whole discriminator between the retired
# title-cased table column header and the ordinary prose phrase "depends on".
assert_file_not_contains_artifact() {
  local file="$1"
  local artifact="$2"
  local why="$3"
  local case_mode="${4:-insensitive}"

  local grep_flags="-qiF"
  local case_note=" (case-insensitive)"
  if [[ "${case_mode}" == "sensitive" ]]; then
    grep_flags="-qF"
    case_note=" (case-sensitive on purpose)"
  fi

  if grep "${grep_flags}" "${artifact}" "${file}"; then
    fail "${file#${repo_root}/} must not reference retired artifact${case_note}: ${artifact} — ${why}"
  fi
}

# Line-scoped conjunction guard: at least one SINGLE line of the file must
# match EVERY pattern. Patterns are case-insensitive EREs (escape the `.` in a
# filename: `architecture\.md`). A pattern prefixed with `!` is a negative
# conjunct — the same line must NOT match it. Negative conjuncts exist because
# some claims are about an edge that must be ABSENT ("the light-path approval
# goes to DAG_PHASE and nowhere near a design state"); without one the guard
# would be satisfied by a neighbouring line and would not bite.
#
# Why a conjunction and not a phrase. The claims this guards are semantic, not
# lexical — "the light path never produces architecture.md" survives a hundred
# rewordings, and a `grep -qF` on any one of them is red the first time someone
# edits the sentence. A guard that dies on rewording is worse than no guard: it
# teaches the next author to delete it. What CANNOT survive is dropping the
# meaning-bearing tokens themselves — you cannot state the restriction without
# naming the artifact, the path it is barred from, and a negation.
#
# Why line-scoped and not file-scoped. File-scoped, the conjunction is vacuous:
# `architecture.md`, `light path`, and `no` all appear somewhere in any file
# that discusses the feature at all, so the guard would pass on a file whose
# restriction had been deleted. Co-occurrence on one line is what makes the
# match a single assertion rather than three unrelated words. Prose in these
# files is one paragraph per line, so a paragraph is the natural unit.
#
# On failure the headline reports the `why` and WHICH conjunct narrowed the
# candidate set to zero — that ordinal is the diagnostic, and it is the one
# thing a raw dump of the EREs does not give you. The patterns themselves go to
# stderr underneath, unindexed by relevance, because printing a 60-character
# negation alternation in the headline buries the sentence that explains what
# broke.
assert_line_matches_all() {
  local file="$1"
  local why="$2"
  shift 2

  local total=$#
  local surviving
  surviving="$(cat "${file}")"

  local pattern
  local index=0
  local emptied_at=0
  for pattern in "$@"; do
    index=$(( index + 1 ))
    if [[ "${pattern}" == '!'* ]]; then
      surviving="$(printf '%s\n' "${surviving}" | grep -Eiv -- "${pattern#!}" || true)"
    else
      surviving="$(printf '%s\n' "${surviving}" | grep -Ei -- "${pattern}" || true)"
    fi
    if [[ -z "${surviving}" ]]; then
      emptied_at=${index}
      break
    fi
  done

  if [[ -z "${surviving}" ]]; then
    printf 'conjuncts (%d): %s\n' "${total}" "$*" >&2
    fail "${file#${repo_root}/} has no single line satisfying all ${total} conjuncts of this guard; conjunct ${emptied_at}/${total} left zero candidates — ${why}"
  fi
}

# --- Negation conjuncts: what they catch, and what they provably do not ---
#
# READ THIS BEFORE TRUSTING THE US4 GUARDS BELOW.
#
# The previous conjunct was a bare `(never|no|not)` presence test anywhere on
# the line. That is categorically unsound as a test of a prohibition: it asserts
# a negation token EXISTS, never what it negates. A paragraph-length line that
# mentions `architecture.md`, mentions `light path`, and says "writes nothing"
# about something else entirely satisfied all three conjuncts with the actual
# restriction deleted.
#
# The two patterns below fix the accidental half of that: they require the
# negation and its object to sit in the SAME CLAUSE — same line, within a short
# window, with no sentence terminator (`.`/`!`/`;`) between them. That kills the
# "negation floating elsewhere in a long paragraph" false pass, which is the
# failure mode a normal edit actually produces.
#
# They do NOT make the guard sound, and no line-scoped regex can. A regex has no
# model of negation SCOPE, so a meaning-inverting rewrite — "`architecture.md`
# is no longer excluded: the light path writes it too" — still places a negation
# next to the artifact and still matches. Mutation-tested and confirmed: see the
# inversion results in the mutation notes at the bottom of this file.
#
# So the honest label: these are DELETION AND DRIFT detectors, and only a weak
# canary against inversion. They catch the restriction being removed or its
# meaning-bearing tokens being lost. They catch some inversion phrasings by
# accident of word order (the artifact-bound pattern requires the negation
# BEFORE the artifact, which the natural inverting phrasings do not always
# produce). They will not reliably catch an author who deliberately writes the
# opposite claim. Nothing in this suite will. That is a real gap in US4 coverage
# and it is stated here rather than papered over.
#
# Boundaries are explicit non-letter classes rather than `\b`, a GNU extension
# BSD/macOS grep does not portably honour in EREs. Bare `no` without the
# boundary would match "north", "note", "nothing".

# Negation bound to the ARTIFACT: "...no `architecture.md`...", "never write
# `architecture.md`". Used where the source states the prohibition by naming the
# file as the thing withheld.
negated_artifact='(^|[^a-zA-Z])(never|no|not)[^a-zA-Z][^.!;]{0,60}architecture\.md'

# Negation bound to the PATH: "Never created on the light path", "not produced
# on the light path". Used where the source states the prohibition by naming the
# path on which nothing is produced, with the artifact established earlier in
# the paragraph. Weaker than the artifact-bound form — the object of the
# negation is the path, not the file — but it is the shape the carrier spec and
# the TL agent actually use, and demanding the other shape would be a guard that
# is red against correct prose.
negated_light_path='(^|[^a-zA-Z])(never|no|not)[^a-zA-Z][^.!;]{0,60}light[- ]path'

# Occurrence counter for the count-identity guard below. `-F` keeps the
# pattern literal so the `.` in `status.md` cannot match an arbitrary
# character (`-o` alone would count `velo-task-status-md` style false hits);
# `-o` emits one line per match, so multiple hits on one line all count.
# `|| true` keeps a legitimate zero count from tripping `set -e`/`pipefail`.
#
# `-i` matters here and its absence was a real hole. A sentence-initial
# `Status.md` contributed 0 to BOTH sides of the identity below, so the equality
# held undisturbed while a dangling instruction to write a deleted file sat in
# the document. Case-folding is safe for the identity because it folds both
# sides symmetrically: `status.md` is a substring of `velo-task-status.md`
# exactly once under either case rule, so the arithmetic is unchanged for the
# legitimate mentions and only the retired ones — in whatever case they are
# written — now register. Verified empirically against a mixed-capitalization
# fixture, not assumed.
count_occurrences() {
  local file="$1"
  local literal="$2"

  { grep -oiF "${literal}" "${file}" || true; } | wc -l | tr -d '[:space:]'
}

# `status.md` cannot use a blunt guard: the skill file
# `skills/velo-task-status.md` keeps its name (EDD D3) and both commands must
# keep citing it, so `grep -qF "status.md"` would be permanently red. A
# path-anchored `grep -qF "/status.md"` is too weak in the other direction —
# it matches only the handful of `<slug>/status.md` path forms and misses the
# ~17 bare prose write-instructions ("rewrites `status.md` at EVERY state
# transition", the terminal stamps), so a builder could strip the paths, leave
# prose telling Velo to write a deleted file, and still pass.
#
# The COUNT IDENTITY closes both gaps. Every legitimate surviving mention of
# `status.md` is a substring of the skill filename `velo-task-status.md`, so:
#
#     count("status.md") == count("velo-task-status.md")
#
# holds exactly when zero retired references — bare or path-form — remain. Any
# leftover retired mention increments the left side only and turns this red.
assert_no_retired_status_references() {
  local file="$1"
  local why="$2"

  local retired_total carrier_total
  retired_total="$(count_occurrences "${file}" "status.md")"
  carrier_total="$(count_occurrences "${file}" "velo-task-status.md")"

  if [[ "${retired_total}" != "${carrier_total}" ]]; then
    fail "${file#${repo_root}/} has $(( retired_total - carrier_total )) retired status.md reference(s): 'status.md' appears ${retired_total}x but the surviving skill filename 'velo-task-status.md' only ${carrier_total}x — ${why}"
  fi
}

# Subject files must exist — a missing file would make every grep-based
# negative check below pass vacuously.
[[ -f "${task_file}" ]] || fail "commands/task.md is missing; remaining checks would pass vacuously"
[[ -f "${readme_file}" ]] || fail "README.md is missing; remaining checks would pass vacuously"
[[ -f "${plan_file}" ]] || fail "commands/plan.md is missing; remaining checks would pass vacuously"
[[ -f "${pm_file}" ]] || fail "agents/product-manager.md is missing; remaining checks would pass vacuously"
[[ -f "${tl_file}" ]] || fail "agents/tech-lead.md is missing; remaining checks would pass vacuously"
[[ -f "${de_file}" ]] || fail "agents/distinguished-engineer.md is missing; remaining checks would pass vacuously"
[[ -f "${carrier_file}" ]] || fail "skills/velo-task-status.md is missing; remaining checks would pass vacuously"
[[ -f "${skill_files[0]:-}" ]] || fail "skills/*.md matched no files; the product.txt blast-radius sweep would pass vacuously"

# The mirror image of the existence preamble: a file that must be GONE (US1).
# skills/velo-plan-package.md specified the retired plan-package artifact, now
# folded into task-breakdown.md's Velo-owned header. The `plan-package.md`
# content guards below catch surviving *links* into this file; only this check
# catches the file itself still standing on disk with those links removed —
# a dead spec that a future author would read as live. Static repo fact,
# checkable in exactly the style of the guards above.
[[ ! -f "${retired_package_skill}" ]] || fail "skills/velo-plan-package.md must be deleted (US1): the plan package folds into task-breakdown.md's Velo-owned header, and a surviving spec file is a live-looking description of a retired artifact"

# Retired-claim guards only. This test does not pin current prose to disk
# state (that mechanism produced the rot fixed in 761128a and again after
# f891b27/0618a29); it guards specific retired claims from creeping back.

# Task mode has a planning/announce step and a contract gate.
assert_file_not_contains "${task_file}" "No planning phase"
assert_file_not_contains "${readme_file}" "No planning phase"
assert_file_not_contains "${task_file}" "no contract gate"

# The inline transient task-spec sub-system was retired (f891b27, completed
# in 0618a29): task mode has no spec states; underspecified work escalates
# to /velo:plan. This phrase returning means the dead sub-system is being
# resurrected in prose.
assert_file_not_contains "${task_file}" "inline transient task-spec"
assert_file_not_contains "${readme_file}" "inline transient task-spec"

# "lightweight delegated flow" is the retired name for task mode (renamed in
# f891b27; commands/task.md is the authority and calls it "a single adaptive
# delegated flow"). The old name returning in either file recreates the
# naming drift between README and task.md.
assert_file_not_contains "${task_file}" "lightweight delegated flow"
assert_file_not_contains "${readme_file}" "Lightweight delegated flow"

# Integration-token pins for commands/task.md. The existence checks above
# close file *deletion*; these close content *gutting* — an emptied or
# hollowed-out task.md passes every negative guard, but cannot pass these.
# Each token is a machine-facing identifier other files dispatch on, so its
# disappearance is an integration break, not benign rewording.

# `Planned-via:` — the plan->task dispatch key (frozen carrier-header
# contract, skills/velo-task-status.md; producer commands/plan.md). task.md's
# escalation Hard Rule carries an explicit Planned-via exception; if task.md
# loses the token, package-bearing invocations re-escalate to /velo:plan in
# a loop.
assert_file_contains "${task_file}" "Planned-via:" \
  "plan->task dispatch key; without it, planned work re-escalates to /velo:plan in a loop"

# `handoff-mode` — ADAPTER.md-defined routing concept (ADAPTER.md:
# concept table). task.md's escalation rule and VALIDATE redirect route to
# /velo:plan through it; if task.md loses the token, escalation has no
# routing mechanism.
assert_file_contains "${task_file}" "handoff-mode" \
  "ADAPTER.md routing concept; without it, escalation to /velo:plan has no mechanism"

# `Task-folder` — carrier header key (frozen contract,
# skills/velo-task-status.md; consumed by commands/plan.md and
# commands/task.md). task.md reuses a carried Task-folder for breadcrumb and
# resume continuity; if the token vanishes, task mode derives a fresh slug
# and orphans the plan's carrier and index row.
assert_file_contains "${task_file}" "Task-folder" \
  "carrier folder-continuity key; without it, handoff orphans the plan's breadcrumbs"

# Retired-artifact guards for the plan-artifacts restructure (PRD US1, US5).
# The three pins above are the frozen half of that contract — they stay green
# because the tokens survive into the new carrier header. These guards are the
# other half: the files those tokens used to live in are gone, and no command
# may keep instructing Velo to write one. A dangling write-instruction is worse
# than a dropped one — it silently produces an artifact nothing reads.

# `plan-package.md` (US1) — folded into task-breakdown.md's Velo-owned header.
# The skill that specified it, skills/velo-plan-package.md, is deleted, so the
# blunt token also catches surviving `skills/velo-plan-package.md` links, which
# would be dead references into a removed file.
assert_file_not_contains_artifact "${plan_file}" "plan-package.md" \
  "US1: the plan package folds into task-breakdown.md's header; the skill specifying it is deleted"
assert_file_not_contains_artifact "${task_file}" "plan-package.md" \
  "US1: the plan package folds into task-breakdown.md's header; the skill specifying it is deleted"

# `product.txt` (US5) — the slug becomes the carrier's `Product:` header key.
# Blast radius per the PRD's grep-verifiable AC: both commands, the PM agent
# (whose Step 0 wrote the file and whose Advisory-mode exception named it), and
# every skill. The PM agent never writes the header itself — Velo transcribes
# the slug from the PM's report — so the agent must stop naming the file at all.
assert_file_not_contains_artifact "${plan_file}" "product.txt" \
  "US5: the product slug lives in the carrier's Product: header key, not a side-car file"
assert_file_not_contains_artifact "${task_file}" "product.txt" \
  "US5: the product slug lives in the carrier's Product: header key, not a side-car file"
assert_file_not_contains_artifact "${pm_file}" "product.txt" \
  "US5: the PM reports the slug; Velo writes it into the carrier header"
for skill_file in "${skill_files[@]}"; do
  assert_file_not_contains_artifact "${skill_file}" "product.txt" \
    "US5: the product slug lives in the carrier's Product: header key, not a side-car file"
done

# `status.md` (US1) — folded into the carrier header. Count identity, not a
# blunt or path-anchored guard; see assert_no_retired_status_references.
assert_no_retired_status_references "${plan_file}" \
  "US1: live phase/counters fold into task-breakdown.md's header; only the skill filename may survive"
assert_no_retired_status_references "${task_file}" \
  "US1: live phase/counters fold into task-breakdown.md's header; only the skill filename may survive"

# `architecture.md` is heavy-path only (PRD US4, third AC).
#
# The AC is written as a runtime outcome — "light-path task folders contain no
# architecture.md" — but this suite is a static contract test over markdown and
# there is no plan run to inspect. Simulating one would test a fake. What is
# testable, and what actually causes the outcome, is the contract: the light
# path is never *told* to write the file, and the state that does write it is
# one the light path never enters. Three guards, on the three files that carry
# those two claims.

# 1. commands/plan.md, at the point of production. The heavy-path-only
# restriction appears in several places in this file (the DESIGN_PHASE
# authoring instruction, the Artifacts line, the final-summary lines), but only
# one is load-bearing: the `DAG_PHASE` light-path bullet, which is the
# instruction Velo executes when it spawns the TL on the light path. The others
# describe; this one directs. Today it reads "no engineering design doc and no
# `architecture.md` on the light path" — the tokens, not the sentence, are what
# is pinned.
#
# The negation conjunct is the artifact-bound form: the source states the
# restriction as "no `architecture.md` on the light path", so the negation and
# the filename sit in one clause. See the negation-conjunct notes above for
# what this does and does not catch — it is not a soundness proof, it is a
# deletion detector with a partial inversion canary attached.
assert_line_matches_all "${plan_file}" \
  "US4: the light-path TL spawn must state that no architecture.md is produced; without it the light path has nothing barring the write" \
  'architecture\.md' 'light path' "${negated_artifact}"

# 2. commands/plan.md, the structural half. The restriction above is a rule an
# author could contradict; this is the reason it cannot be contradicted — the
# light tier's approval exit lands on `DAG_PHASE` and never touches a design
# state. Pinned on `ANNOUNCE`'s exit-conditions line rather than the Workflow
# prose, because the file itself designates exit conditions as "the
# authoritative source for transitions out of that state"; the prose paragraph
# and the ASCII diagram both restate it.
#
# The `!DESIGN` conjunct is what makes this bite. Without it the guard is also
# satisfied by `PLAN_APPROVAL`'s light-path revise line, so re-pointing the
# light approval at the design depth would leave it green. With it, the guard
# matches exactly the one transition it is about.
assert_line_matches_all "${plan_file}" \
  "US4: the light tier's approval must exit to DAG_PHASE with no design state on the path — that structural skip, not prose, is what makes architecture.md unreachable on the light path" \
  'light' 'user-gate: approve' 'DAG_PHASE' '!DESIGN'

# 3. commands/plan.md, the binding half: production is attached to
# DESIGN_PHASE. Combined with guard 2, the outcome follows mechanically —
# written only at a state the light path never reaches.
assert_line_matches_all "${plan_file}" \
  "US4: architecture.md production must stay bound to DESIGN_PHASE; unbound, it could be written from any state including DAG_PHASE" \
  'architecture\.md' 'DESIGN_PHASE'

# 4. skills/velo-task-status.md — the carrier spec, which is the authority the
# commands and agents cite rather than restate. A restriction living only in
# commands/plan.md is one file away from being lost when an agent is rewritten
# against the spec instead of against the command.
#
# One guard here, not two. A second assertion pinning the spec's
# DESIGN_PHASE/heavy write point was written and dropped: mutation-testing
# showed it resolved to the same line as this one, so deleting the write-point
# table row left it green. Two assertions anchored on one line are one
# assertion with extra failure text.
#
# Path-bound negation here, not artifact-bound: the spec states the restriction
# as "Never created on the light path", with `architecture.md` named earlier in
# the same paragraph. The artifact-bound form would be red against correct
# prose. That makes this the weaker of the two US4 negation guards — the
# inversion canary that the plan.md guard gets from word order is absent here.
assert_line_matches_all "${carrier_file}" \
  "US4: the carrier spec must record that architecture.md is heavy-path only and never created on the light path" \
  'architecture\.md' 'heavy' "${negated_light_path}"

# 5-7. The two agent files that do the work. Guards 1-4 all point at
# commands/plan.md and the carrier spec — the files that DESCRIBE the
# restriction — and none at the files whose text the agents actually read at
# spawn time. That was a silent gap, not a declared trade-off: US4 names both
# agents as dependencies, and agents/tech-lead.md is where the light-path
# exclusion instruction the TL obeys lives. A rewrite that strips the filename
# from either agent breaks US4 while leaving guards 1-4 green.
#
# Pinned the same way as the task.md integration tokens: a filename is a
# machine-facing identifier both agents dispatch on (the TL writes it, the DE
# refuses to review without it), so its disappearance is an integration break
# rather than rewording.
assert_file_contains "${tl_file}" "architecture.md" \
  "US4: the TL is the author of architecture.md; losing the filename leaves the heavy path with no instruction to write the diagram"
assert_file_contains "${de_file}" "architecture.md" \
  "US4: the DE reads architecture.md at DESIGN_REVIEW and stops on its absence; losing the filename means heavy-path designs get reviewed with no diagram"

# The TL's own light-path exclusion, bound to the state that does produce the
# file. This is the instruction that actually causes the US4 outcome — guards
# 1-4 pin the specification of it; this pins the copy the agent executes.
assert_line_matches_all "${tl_file}" \
  "US4: the TL agent must carry the light-path exclusion itself, bound to DESIGN_PHASE as the one state that writes architecture.md; the plan.md and carrier-spec guards do not cover the text the TL actually reads" \
  'architecture\.md' 'DESIGN_PHASE' "${negated_light_path}"

# The DE's half: the diagram is a heavy-path input. If the DE stops tying
# architecture.md to the heavy path, it will either demand the file on light
# reviews (which never produce it) or stop demanding it at all.
assert_line_matches_all "${de_file}" \
  "US4: the DE must treat architecture.md as a heavy-path input; untied from the path, it either blocks light reviews on a file that is never created or stops enforcing it on heavy ones" \
  'architecture\.md' 'heavy'

# --- Beyond the AC: milestone shape (green-gate finding C5, partial) ---
#
# C5 reports no coverage for the new milestone shape or the per-milestone ship
# gate. The ship gate is not cheaply testable here — it is executor behaviour
# spread across task.md and the carrier spec, and any grep for it would be
# either vacuous or a prose pin. The *shape* is different: it is machine-facing
# structure with cross-file consumers, so it pins like the task.md tokens above
# rather than like prose. These three guards are what fell out of the AC work;
# they are not an attempt to close C5.

# `## M` — the ownership seam. commands/plan.md and skills/velo-task-status.md
# both define the boundary as "the first `## M` heading": Velo owns everything
# above it, the TL writes at and below. If the TL's output template stops
# emitting the heading, the seam has no anchor and Velo cannot tell its own
# header region from the TL's body.
assert_file_contains "${tl_file}" "## M1" \
  "milestone-shape seam anchor; plan.md and the carrier spec locate Velo/TL ownership at the first '## M' heading"

# `Status: pending` — the executor's per-task vocabulary (pending | in-flight |
# done) and the token resume reads to decide what still needs running. The TL
# only ever emits `pending`; losing it means resumed plans re-run finished work.
assert_file_contains "${tl_file}" "Status: pending" \
  "per-task status field; the executor and resume read it to tell done work from outstanding work"

# `Depends On` — the column header of the retired flat
# `| # | Task | Owner | Depends On |` breakdown table, replaced by nested
# milestones with inline `needs:` edges. Case-sensitive and title-cased on
# purpose: prose writes "depends on", only a table header writes "Depends On",
# so this catches the retired shape without tripping on ordinary sentences.
# `sensitive` — the only opt-out from the default case-insensitive matching, and
# the reason the parameter exists. Case IS the discriminator here: ordinary prose
# writes "depends on", only a table column header writes "Depends On". Folding
# case would make this guard red against every correct sentence in the file.
assert_file_not_contains_artifact "${tl_file}" "Depends On" \
  "retired flat breakdown-table column header; dependency edges are inline 'needs:' on task lines under '## M' milestones" \
  sensitive

# --- Mutation notes ---
#
# Every guard above was mutation-tested against a copy of the tree: apply one
# targeted edit, run this file, record the exit code. 24 mutations, 23 matched
# expectation. The results worth carrying forward:
#
# CAUGHT (deletion and drift)
#   - the US4 restriction clause deleted from plan.md's DAG_PHASE spawn
#   - the restriction deleted but a negation left floating elsewhere in the same
#     paragraph alongside `architecture.md` and `light path` — this is the exact
#     false pass the old bare-presence conjunct allowed, and clause-binding is
#     what turned it red
#   - `Never created on the light path` deleted from the carrier spec
#   - the TL's own Step 2b light-path exclusion stripped
#   - `architecture.md` renamed out of either agent file
#   - `architecture.md` unbound from `DESIGN_PHASE`
#   - the DE untied from the heavy path
#   - retired `status.md` / `product.txt` / `plan-package.md` references in any
#     capitalization, including sentence-initial and all-caps
#   - `skills/velo-plan-package.md` recreated
#   - `Depends On` table header restored
#   - task.md gutted, `Planned-via:` renamed, `## M1` renamed
#
# NOT CAUGHT — the known, deliberate limit
#   - Meaning inversion where the negation precedes the artifact:
#     `no longer excluded: `architecture.md` is written on the light path too`
#     replacing the restriction leaves this suite GREEN. It matches
#     `architecture\.md`, matches `light path`, and matches the artifact-bound
#     negation pattern, while asserting precisely what US4 forbids.
#
#     The sibling inversion with the negation AFTER the artifact
#     (`architecture.md is **not** skipped on the light path`) DOES go red, but
#     only by word order, not by anything the guard understands. Do not read
#     that pass as coverage.
#
#     This is not a pattern that can be tightened away. A regex has no model of
#     what a negation scopes over, so "X is forbidden on path Y" is not
#     expressible as a line-scoped match; any pattern that accepts the correct
#     sentence also accepts its inversion. Catching this needs a different
#     mechanism — a runtime assertion on a real light-path plan folder, or a
#     semantic review step — not a better ERE.
#
# NOT PROBED
#   - Reword controls confirm the guards survive rephrasing that preserves
#     meaning; they cannot, by construction, probe inversion. That is why the
#     inversion mutations above were added as a separate class.

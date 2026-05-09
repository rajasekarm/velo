#!/usr/bin/env bash
# audit.sh
# Audits the integrity of the Velo agent system — verifies all file references
# within the system are valid and reports any broken paths or unreferenced files.
#
# Usage (run from any directory):
#   ./scripts/audit.sh
#
# Exit codes:
#   0 — no errors (warnings are OK)
#   1 — one or more broken references found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Allow-list: agents that legitimately have no skill file references.
# Utility/verifier agents whose work doesn't depend on a skill manual.
AGENTS_WITHOUT_SKILLS=(
  "commit"
  "distinguished-engineer"
  "gpt-reviewer"
  "learnings-agent"
  "spec-checker"
  "tech-lead"
)

# Allow-list: commands that legitimately have no agent file references.
# Generic routers that spawn agents dynamically based on the task.
COMMANDS_WITHOUT_AGENTS=(
  "hunt"
  "task"
)

errors=0
warnings=0

# Temp file to accumulate all referenced skill paths (for check 4 dead-file detection)
umask 0077
REFERENCED_SKILLS_TMP="$(mktemp)"
trap 'rm -f "${REFERENCED_SKILLS_TMP}"' EXIT

echo "=== Velo Agent Audit ==="
echo ""

# ---------------------------------------------------------------------------
# CHECK 1 — TEAM.md → agent files
# ---------------------------------------------------------------------------
echo "[CHECK 1] TEAM.md → agent files"

team_file="${REPO_ROOT}/TEAM.md"

if [[ ! -f "${team_file}" ]]; then
  echo "  ✗ TEAM.md — NOT FOUND (cannot continue check 1)"
  errors=$((errors + 1))
else
  # Extract backtick-wrapped paths matching agents/*.md from table rows.
  # Example line: | **be-engineer** | `agents/be-engineer.md` | nodejs |
  team_agents="$(grep -oE '`agents/[^`]+\.md`' "${team_file}" | tr -d '`' | sort -u)"

  if [[ -z "${team_agents}" ]]; then
    echo "  ⚠ WARNING — no agent file references found in TEAM.md"
    warnings=$((warnings + 1))
  else
    while IFS= read -r agent_path; do
      # Reject paths containing .. to prevent path traversal
      if [[ "${agent_path}" == *".."* ]]; then
        echo "  ✗ TEAM.md → ${agent_path} — REJECTED (path traversal)"
        errors=$((errors + 1))
        continue
      fi
      full_path="${REPO_ROOT}/${agent_path}"
      if [[ -f "${full_path}" ]]; then
        echo "  ✓ ${agent_path}"
      else
        echo "  ✗ ${agent_path} — NOT FOUND"
        errors=$((errors + 1))
      fi
    done <<< "${team_agents}"
  fi
fi

echo ""

# ---------------------------------------------------------------------------
# CHECK 2 — Agent files → skill files
# ---------------------------------------------------------------------------
echo "[CHECK 2] Agent files → skill files"

agents_dir="${REPO_ROOT}/agents"

if [[ ! -d "${agents_dir}" ]]; then
  echo "  (agents/ directory not found — skipping)"
else
  found_any_skill_ref=0

  while IFS= read -r agent_file; do
    agent_rel="agents/$(basename "${agent_file}")"
    agent_name="$(basename "${agent_file}" .md)"

    # Extract backtick-wrapped paths matching skills/... that point to a file
    # (last component must contain a dot — filters out bare directory references).
    # Handles `skills/foo.md` and nested forms like `skills/dir/file.md`.
    # Filter out glob patterns (*, ?, [) — these are descriptive, not literal refs.
    # || true: grep exits 1 on no match; we handle the empty-string case below.
    skill_refs="$(grep -oE '`skills/[^` ]+\.[^` /]+`' "${agent_file}" | tr -d '`' | grep -v '[][*?]' || true)"

    if [[ -z "${skill_refs}" ]]; then
      # Allow-list check: skip warning for utility/verifier agents
      skip_warning=0
      for allowed in "${AGENTS_WITHOUT_SKILLS[@]}"; do
        if [[ "${agent_name}" == "${allowed}" ]]; then
          skip_warning=1
          break
        fi
      done
      if [[ ${skip_warning} -eq 0 ]]; then
        echo "  ⚠ WARNING — ${agent_rel}: no skill file references found"
        warnings=$((warnings + 1))
      fi
      continue
    fi

    while IFS= read -r skill_path; do
      found_any_skill_ref=1
      # Reject paths containing .. to prevent path traversal
      if [[ "${skill_path}" == *".."* ]]; then
        echo "  ✗ ${agent_rel} → ${skill_path} — REJECTED (path traversal)"
        errors=$((errors + 1))
        continue
      fi
      # Record for check 4
      echo "${skill_path}" >> "${REFERENCED_SKILLS_TMP}"
      full_path="${REPO_ROOT}/${skill_path}"
      if [[ -f "${full_path}" ]]; then
        echo "  ✓ ${agent_rel} → ${skill_path}"
      else
        echo "  ✗ ${agent_rel} → ${skill_path} — NOT FOUND"
        errors=$((errors + 1))
      fi
    done <<< "${skill_refs}"
  done < <(find "${agents_dir}" -name '*.md' | sort)

  if [[ ${found_any_skill_ref} -eq 0 ]]; then
    echo "  (no skill file references found in any agent file)"
  fi
fi

echo ""

# ---------------------------------------------------------------------------
# CHECK 3 — Command files → agent files
# ---------------------------------------------------------------------------
echo "[CHECK 3] Command files → agent files"

commands_dir="${REPO_ROOT}/commands"

if [[ ! -d "${commands_dir}" ]]; then
  echo "  (commands/ directory not found — skipping)"
else
  found_any_cmd_ref=0

  while IFS= read -r cmd_file; do
    cmd_rel="commands/$(basename "${cmd_file}")"
    cmd_name="$(basename "${cmd_file}" .md)"

    # Filter out glob patterns (*, ?, [) — these are descriptive, not literal refs.
    # || true: grep exits 1 on no match; we handle the empty-string case below.
    agent_refs="$(grep -oE '`agents/[^`]+\.md`' "${cmd_file}" | tr -d '`' | grep -v '[][*?]' | sort -u || true)"

    if [[ -z "${agent_refs}" ]]; then
      # Allow-list check: skip warning for generic-router commands
      skip_warning=0
      for allowed in "${COMMANDS_WITHOUT_AGENTS[@]}"; do
        if [[ "${cmd_name}" == "${allowed}" ]]; then
          skip_warning=1
          break
        fi
      done
      if [[ ${skip_warning} -eq 0 ]]; then
        echo "  ⚠ WARNING — ${cmd_rel}: no agent file references found"
        warnings=$((warnings + 1))
      fi
      continue
    fi

    while IFS= read -r agent_path; do
      found_any_cmd_ref=1
      # Reject paths containing .. to prevent path traversal
      if [[ "${agent_path}" == *".."* ]]; then
        echo "  ✗ ${cmd_rel} → ${agent_path} — REJECTED (path traversal)"
        errors=$((errors + 1))
        continue
      fi
      full_path="${REPO_ROOT}/${agent_path}"
      if [[ -f "${full_path}" ]]; then
        echo "  ✓ ${cmd_rel} → ${agent_path}"
      else
        echo "  ✗ ${cmd_rel} → ${agent_path} — NOT FOUND"
        errors=$((errors + 1))
      fi
    done <<< "${agent_refs}"
  done < <(find "${commands_dir}" -name '*.md' | sort)

  if [[ ${found_any_cmd_ref} -eq 0 ]]; then
    echo "  (no agent file references found in any command file)"
  fi
fi

echo ""

# ---------------------------------------------------------------------------
# CHECK 4 — Dead skill files (warning only)
# ---------------------------------------------------------------------------
echo "[CHECK 4] Dead skill files (warning only)"

skills_dir="${REPO_ROOT}/skills"

if [[ ! -d "${skills_dir}" ]]; then
  echo "  (skills/ directory not found — skipping)"
else
  found_any_dead=0

  while IFS= read -r skill_file; do
    skill_rel="${skill_file/${REPO_ROOT}\//}"

    # Check whether this path appears in the referenced skills list
    if grep -qxF "${skill_rel}" "${REFERENCED_SKILLS_TMP}" 2>/dev/null; then
      continue
    fi

    # Index-style follow-through:
    # If this file is under skills/<name>-rules/, check whether skills/<name>.md
    # exists as an index and references the rules directory. If so, the file is
    # loaded on-demand via the index — not dead.
    if [[ "${skill_rel}" =~ ^skills/([^/]+)-rules/ ]]; then
      index_name="${BASH_REMATCH[1]}"
      index_file="${REPO_ROOT}/skills/${index_name}.md"
      rules_dir_ref="skills/${index_name}-rules/"
      if [[ -f "${index_file}" ]] && grep -qF "${rules_dir_ref}" "${index_file}"; then
        continue
      fi
    fi

    echo "  ⚠ ${skill_rel} — not referenced by any agent"
    warnings=$((warnings + 1))
    found_any_dead=1
  done < <(find "${skills_dir}" -name '*.md' \
    ! -path '*/rules/*.md' \
    ! -name 'update-skill.md' \
    | sort)

  if [[ ${found_any_dead} -eq 0 ]]; then
    echo "  (all skill files are referenced)"
  fi
fi

echo ""

# ---------------------------------------------------------------------------
# CHECK 5 — Codex layer tests
# ---------------------------------------------------------------------------
echo "[CHECK 5] Codex layer tests"

tests_dir="${REPO_ROOT}/tests"

if [[ ! -d "${tests_dir}" ]]; then
  echo "  (tests/ directory not found — skipping)"
else
  found_any_test=0

  while IFS= read -r test_file; do
    found_any_test=1
    test_rel="${test_file/${REPO_ROOT}\//}"

    if bash "${test_file}"; then
      echo "  ✓ ${test_rel}"
    else
      echo "  ✗ ${test_rel} — FAILED"
      errors=$((errors + 1))
    fi
  done < <(find "${tests_dir}" -name '*.test.sh' | sort)

  if [[ ${found_any_test} -eq 0 ]]; then
    echo "  (no shell tests found)"
  fi
fi

echo ""

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------
if [[ ${errors} -eq 0 && ${warnings} -eq 0 ]]; then
  echo "=== Result: PASS (0 errors, 0 warnings) ==="
  exit 0
elif [[ ${errors} -eq 0 ]]; then
  echo "=== Result: PASS (0 errors, ${warnings} warning(s)) ==="
  exit 0
else
  echo "=== Result: FAIL (${errors} error(s), ${warnings} warning(s)) ==="
  exit 1
fi

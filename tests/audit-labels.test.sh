#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
audit_file="${repo_root}/scripts/audit.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

if grep -qF "PERSONA.md" "${audit_file}"; then
  fail "scripts/audit.sh checks TEAM.md and should not label that check as PERSONA.md"
fi

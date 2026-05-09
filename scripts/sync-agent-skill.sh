#!/usr/bin/env bash
# sync-agent-skill.sh
# Fetch an AGENTS.md from GitHub, split into per-section rule files, and generate a compact skill index.
#
# Usage (run from repo root):
#   ./scripts/sync-agent-skill.sh <skill-name> <owner/repo> <path/to/AGENTS.md>
#
# Example:
#   ./scripts/sync-agent-skill.sh vercel-react-best-practices vercel-labs/agent-skills skills/react-best-practices/AGENTS.md
#
# Output:
#   skills/<skill-name>.md             — compact index (always loaded by agent)
#   skills/<skill-name>-rules/01-*.md  — full section content (read on demand)
#
# Note: produces a flat skill file (not skills/<name>/SKILL.md) so Claude Code's
# auto-discovery does not expose the skill as a /<plugin>:<name> slash command.

set -euo pipefail

SKILL_NAME="${1:?Usage: $0 <skill-name> <owner/repo> <path/to/AGENTS.md>}"
REPO="${2:?Missing owner/repo}"
AGENTS_PATH="${3:?Missing path/to/AGENTS.md}"

REPO_ROOT="$(git rev-parse --show-toplevel)"
SKILL_FILE="${REPO_ROOT}/skills/${SKILL_NAME}.md"
RULES_DIR="${REPO_ROOT}/skills/${SKILL_NAME}-rules"
RULES_REL="skills/${SKILL_NAME}-rules"
SOURCE_URL="https://github.com/${REPO}/blob/main/${AGENTS_PATH}"
UPDATED=$(date -u +"%Y-%m-%d")
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

echo "Fetching ${SOURCE_URL}..."
gh api "repos/${REPO}/contents/${AGENTS_PATH}" --jq '.content' | base64 --decode > "$TMPFILE"

echo "Splitting into sections..."
python3 - "$SKILL_FILE" "$RULES_DIR" "$RULES_REL" "$SOURCE_URL" "$UPDATED" "$SKILL_NAME" "$REPO" "$AGENTS_PATH" "$TMPFILE" <<'PYEOF'
import re, sys
from pathlib import Path

skill_file, rules_dir, rules_rel, source_url, updated, skill_name, repo, agents_path, tmpfile = sys.argv[1:]

with open(tmpfile) as f:
    content = f.read()

Path(rules_dir).mkdir(parents=True, exist_ok=True)

header_comment = (
    f"<!-- SOURCE: {source_url} -->\n"
    f"<!-- UPDATED: {updated} -->\n"
    f"<!-- TO UPDATE: ./scripts/sync-agent-skill.sh {skill_name} {repo} {agents_path} -->\n"
)

# Split on numbered top-level section headers: ## 1. Title
parts = re.split(r'\n(?=## \d+\.)', content)
numbered = [p for p in parts[1:] if re.match(r'## \d+\.', p)]

section_meta = []

for section in numbered:
    m = re.match(r'## (\d+)\.\s+(.+)', section)
    if not m:
        continue
    num = int(m.group(1))
    title = m.group(2).strip()
    slug = re.sub(r'[^\w]+', '-', title.lower()).strip('-')
    filename = f"{num:02d}-{slug}.md"
    filepath = f"{rules_dir}/{filename}"

    with open(filepath, 'w') as f:
        f.write(header_comment + "\n")
        f.write(section.strip() + "\n")
    print(f"  wrote {filepath}")

    subsections = re.findall(r'^### \d+\.\d+\s+(.+)', section, re.MULTILINE)
    section_meta.append((num, title, filename, subsections))

# Build compact index — one or two lines per subsection, enough for the agent to pick
lines = [
    header_comment,
    f"# {skill_name.replace('-', ' ').title()}",
    "",
    f"**{len(section_meta)} categories. Read `{rules_rel}/<file>` for full examples on any category.**",
    "",
]

for num, title, filename, subsections in section_meta:
    lines.append(f"## {num}. {title} — `{rules_rel}/{filename}`")
    for sub in subsections:
        lines.append(f"- {sub.strip()}")
    lines.append("")

with open(skill_file, 'w') as f:
    f.write('\n'.join(lines))

print(f"  wrote {skill_file} ({len(lines)} lines, compact index)")
print(f"Done. {len(section_meta)} rule files + {Path(skill_file).name}")
PYEOF

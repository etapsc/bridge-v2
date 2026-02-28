#!/bin/bash
# sync.sh — Rebuild plugin/ and project/ distributions from _source/
# Run from bridge-claude-code/ directory.
#
# This copies shared content (agents, commands, skills, rules, scripts, docs, CLAUDE.md)
# from _source/ into both plugin/ and project/ distributions.
#
# Distribution-specific files are NOT overwritten:
#   plugin/: .claude-plugin/plugin.json, hooks/hooks.json, settings.json
#   project/: .claude/settings.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/_source"
PLUGIN="$SCRIPT_DIR/plugin"
PROJECT="$SCRIPT_DIR/project"

# Validate _source exists
if [[ ! -d "$SOURCE" ]]; then
  echo "ERROR: _source/ directory not found at $SOURCE"
  exit 1
fi

echo "Syncing from _source/ ..."

# --- Plugin distribution ---
echo "  → plugin/"
for dir in agents commands skills rules scripts docs; do
  rm -rf "$PLUGIN/$dir"
  cp -r "$SOURCE/$dir" "$PLUGIN/$dir"
done
cp "$SOURCE/CLAUDE.md" "$PLUGIN/CLAUDE.md"
chmod +x "$PLUGIN/scripts/"*.sh 2>/dev/null || true

# --- Project distribution ---
echo "  → project/"
for dir in agents commands skills rules; do
  rm -rf "$PROJECT/.claude/$dir"
  cp -r "$SOURCE/$dir" "$PROJECT/.claude/$dir"
done

# Hook scripts go into .claude/hooks/ (not scripts/)
rm -f "$PROJECT/.claude/hooks/session-start.sh" "$PROJECT/.claude/hooks/post-edit-lint.sh" "$PROJECT/.claude/hooks/README.md"
cp "$SOURCE/scripts/session-start.sh" "$PROJECT/.claude/hooks/"
cp "$SOURCE/scripts/post-edit-lint.sh" "$PROJECT/.claude/hooks/"
cp "$SOURCE/hooks-readme.md" "$PROJECT/.claude/hooks/README.md"
chmod +x "$PROJECT/.claude/hooks/"*.sh

# CLAUDE.md and docs at project root
cp "$SOURCE/CLAUDE.md" "$PROJECT/CLAUDE.md"
rm -rf "$PROJECT/docs"
cp -r "$SOURCE/docs" "$PROJECT/docs"

echo "Sync complete."
echo ""
echo "Distribution-specific files (not synced):"
echo "  plugin/settings.json              — permissions only"
echo "  plugin/.claude-plugin/plugin.json — plugin manifest"
echo "  plugin/hooks/hooks.json           — \${CLAUDE_PLUGIN_ROOT} paths"
echo "  project/.claude/settings.json     — permissions + hooks (\$CLAUDE_PROJECT_DIR paths)"

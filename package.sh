#!/bin/bash
# Package BRIDGE v2.1 folders into distributable tar.gz files
# Run from the directory containing the bridge-* folders
#
# Archives contain pack contents at root (no top-level folder),
# ready for direct extraction into a project directory.
#
# bridge-claude-code has two distributions:
#   bridge-claude-code-plugin.tar.gz  — for claude --plugin-dir
#   bridge-claude-code.tar.gz         — project setup (copy .claude/ into project)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKS=("bridge-full" "bridge-standalone" "bridge-codex" "bridge-opencode")

for pack in "${PACKS[@]}"; do
  if [ ! -d "${SCRIPT_DIR}/$pack" ]; then
    echo "  Skipping $pack (folder not found)"
    continue
  fi
  tar -czf "${SCRIPT_DIR}/${pack}.tar.gz" -C "${SCRIPT_DIR}/$pack" .
  echo "  ${pack}.tar.gz"
done

# bridge-claude-code: two separate archives from plugin/ and project/
CLAUDE_CODE="${SCRIPT_DIR}/bridge-claude-code"
if [ -d "${CLAUDE_CODE}/plugin" ]; then
  tar -czf "${SCRIPT_DIR}/bridge-claude-code-plugin.tar.gz" -C "${CLAUDE_CODE}/plugin" .
  echo "  bridge-claude-code-plugin.tar.gz"
fi
if [ -d "${CLAUDE_CODE}/project" ]; then
  tar -czf "${SCRIPT_DIR}/bridge-claude-code.tar.gz" -C "${CLAUDE_CODE}/project" .
  echo "  bridge-claude-code.tar.gz"
fi

echo ""
echo "Done. Archives ready for GitHub Release or local setup.sh."

#!/bin/bash
# Package BRIDGE v2.1 folders into distributable tar.gz files
# Run from the directory containing the bridge-* folders
#
# Archives contain pack contents at root (no top-level folder),
# ready for direct extraction into a project directory.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKS=("bridge-full" "bridge-standalone" "bridge-claude-code" "bridge-codex")

for pack in "${PACKS[@]}"; do
  if [ ! -d "${SCRIPT_DIR}/$pack" ]; then
    echo "  Skipping $pack (folder not found)"
    continue
  fi
  tar -czf "${SCRIPT_DIR}/${pack}.tar.gz" -C "${SCRIPT_DIR}/$pack" .
  echo "  ${pack}.tar.gz"
done

echo ""
echo "Done. Archives ready for GitHub Release or local setup.sh."

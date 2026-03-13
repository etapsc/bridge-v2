#!/bin/bash
# Package BRIDGE v2.1 folders into distributable tar.gz files
# Run from the directory containing the bridge-* folders
#
# Archives contain pack contents at root (no top-level folder),
# ready for direct extraction into a project directory.
#
# bridge-multi-repo archives are built by merging shared infrastructure
# from bridge-claude-code/ or bridge-codex/ with multi-repo-specific files.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Simple packs: archive the folder directly ---
PACKS=("bridge-full" "bridge-standalone" "bridge-claude-code" "bridge-codex" "bridge-opencode" "bridge-controller")

for pack in "${PACKS[@]}"; do
  if [ ! -d "${SCRIPT_DIR}/$pack" ]; then
    echo "  Skipping $pack (folder not found)"
    continue
  fi
  tar -czf "${SCRIPT_DIR}/${pack}.tar.gz" -C "${SCRIPT_DIR}/$pack" .
  echo "  ${pack}.tar.gz"
done

# --- bridge-multi-repo: merge shared infra + multi-repo-specific files ---
MULTI_REPO="${SCRIPT_DIR}/bridge-multi-repo"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# Claude Code variant: shared infra from bridge-claude-code + multi-repo overlay
if [ -d "${MULTI_REPO}/claude-code" ] && [ -d "${SCRIPT_DIR}/bridge-claude-code" ]; then
  MERGE="${TMPDIR}/multi-repo-claude-code"
  mkdir -p "$MERGE"
  # Base: shared agents, skills, rules, hooks, settings, doc templates
  cp -r "${SCRIPT_DIR}/bridge-claude-code/.claude" "$MERGE/.claude"
  cp -r "${SCRIPT_DIR}/bridge-claude-code/docs" "$MERGE/docs"
  # Overlay: multi-repo CLAUDE.md, commands, rules, docs, reference
  cp "${MULTI_REPO}/claude-code/CLAUDE.md" "$MERGE/CLAUDE.md"
  cp -r "${MULTI_REPO}/claude-code/.claude/commands/"* "$MERGE/.claude/commands/"
  cp "${MULTI_REPO}/claude-code/.claude/rules/multi-repo.md" "$MERGE/.claude/rules/"
  cp "${MULTI_REPO}/claude-code/docs/"* "$MERGE/docs/" 2>/dev/null || true
  cp -r "${MULTI_REPO}/claude-code/reference" "$MERGE/reference"
  tar -czf "${SCRIPT_DIR}/bridge-multi-repo-claude-code.tar.gz" -C "$MERGE" .
  echo "  bridge-multi-repo-claude-code.tar.gz"
fi

# Codex variant: shared infra from bridge-codex + multi-repo overlay
if [ -d "${MULTI_REPO}/codex" ] && [ -d "${SCRIPT_DIR}/bridge-codex" ]; then
  MERGE="${TMPDIR}/multi-repo-codex"
  mkdir -p "$MERGE"
  # Base: shared procedures, doc templates
  cp -r "${SCRIPT_DIR}/bridge-codex/.agents" "$MERGE/.agents"
  cp -r "${SCRIPT_DIR}/bridge-codex/.codex" "$MERGE/.codex"
  cp -r "${SCRIPT_DIR}/bridge-codex/docs" "$MERGE/docs"
  # Overlay: multi-repo AGENTS.md, skills, codex config, docs, reference
  cp "${MULTI_REPO}/codex/AGENTS.md" "$MERGE/AGENTS.md"
  cp -r "${MULTI_REPO}/codex/.agents/skills/"* "$MERGE/.agents/skills/"
  cp "${MULTI_REPO}/codex/.codex/config.toml" "$MERGE/.codex/config.toml"
  cp "${MULTI_REPO}/codex/docs/"* "$MERGE/docs/" 2>/dev/null || true
  cp -r "${MULTI_REPO}/codex/reference" "$MERGE/reference"
  tar -czf "${SCRIPT_DIR}/bridge-multi-repo-codex.tar.gz" -C "$MERGE" .
  echo "  bridge-multi-repo-codex.tar.gz"
fi

# --- bridge-dual-agent ---
DUAL_AGENT="${SCRIPT_DIR}/bridge-dual-agent"
if [ -d "${DUAL_AGENT}" ]; then
  tar -czf "${SCRIPT_DIR}/bridge-dual-agent.tar.gz" -C "${DUAL_AGENT}" .
  echo "  bridge-dual-agent.tar.gz"
fi

echo ""
echo "Done. Archives ready for GitHub Release or local setup.sh."

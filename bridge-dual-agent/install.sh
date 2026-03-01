#!/usr/bin/env bash
set -e

ADDON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$(pwd)}"

echo "BRIDGE Dual-Agent Add-On — Installer"
echo "Target project: $PROJECT_DIR"
echo ""

# Detect which packs are present
HAS_CLAUDE=false
HAS_CODEX=false
[[ -d "$PROJECT_DIR/.claude" ]] && HAS_CLAUDE=true
[[ -d "$PROJECT_DIR/.agents" ]] && HAS_CODEX=true

if [[ "$HAS_CLAUDE" == false && "$HAS_CODEX" == false ]]; then
  echo "ERROR: No BRIDGE pack detected (.claude/ or .agents/ not found)"
  echo "Install a BRIDGE pack first, then run this add-on installer."
  exit 1
fi

echo "Detected packs:"
[[ "$HAS_CLAUDE" == true ]] && echo "  ✓ Claude Code (.claude/)"
[[ "$HAS_CODEX"  == true ]] && echo "  ✓ Codex (.agents/)"
echo ""

# Claude Code side
if [[ "$HAS_CLAUDE" == true ]]; then
  echo "Installing Claude Code components..."

  mkdir -p "$PROJECT_DIR/.claude/commands"
  cp "$ADDON_DIR/.claude/commands/bridge-brief.md"     "$PROJECT_DIR/.claude/commands/"
  cp "$ADDON_DIR/.claude/commands/bridge-gate-dual.md" "$PROJECT_DIR/.claude/commands/"

  mkdir -p "$PROJECT_DIR/.claude/skills/bridge-dual-agent"
  cp "$ADDON_DIR/.claude/skills/bridge-dual-agent/SKILL.md" \
     "$PROJECT_DIR/.claude/skills/bridge-dual-agent/"

  # Append role section to CLAUDE.md
  CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
  if ! grep -q "\[DUAL-AGENT ADD-ON\]" "$CLAUDE_MD" 2>/dev/null; then
    echo "" >> "$CLAUDE_MD"
    cat "$ADDON_DIR/claude-md-addon.md" >> "$CLAUDE_MD"
    echo "  ✓ Appended dual-agent role to CLAUDE.md"
  else
    echo "  ⚠ CLAUDE.md already has dual-agent section — skipped"
  fi
fi

# Codex side
if [[ "$HAS_CODEX" == true ]]; then
  echo "Installing Codex components..."

  mkdir -p "$PROJECT_DIR/.agents/skills/bridge-receive"
  cp "$ADDON_DIR/.agents/skills/bridge-receive/SKILL.md" \
     "$PROJECT_DIR/.agents/skills/bridge-receive/"

  # Append role section to AGENTS.md
  AGENTS_MD="$PROJECT_DIR/AGENTS.md"
  if ! grep -q "\[DUAL-AGENT ADD-ON\]" "$AGENTS_MD" 2>/dev/null; then
    echo "" >> "$AGENTS_MD"
    cat "$ADDON_DIR/agents-md-addon.md" >> "$AGENTS_MD"
    echo "  ✓ Appended dual-agent role to AGENTS.md"
  else
    echo "  ⚠ AGENTS.md already has dual-agent section — skipped"
  fi
fi

# Shared handoff docs
echo "Creating handoff doc templates..."
mkdir -p "$PROJECT_DIR/docs"

if [[ ! -f "$PROJECT_DIR/docs/current-task.md" ]]; then
  cp "$ADDON_DIR/docs-templates/current-task.md" "$PROJECT_DIR/docs/"
  echo "  ✓ docs/current-task.md"
else
  echo "  ⚠ docs/current-task.md already exists — skipped"
fi

if [[ ! -f "$PROJECT_DIR/docs/codex-findings.md" ]]; then
  cp "$ADDON_DIR/docs-templates/codex-findings.md" "$PROJECT_DIR/docs/"
  echo "  ✓ docs/codex-findings.md"
else
  echo "  ⚠ docs/codex-findings.md already exists — skipped"
fi

echo ""
echo "Done. Dual-agent add-on installed."
echo ""
echo "Next steps:"
[[ "$HAS_CLAUDE" == true ]] && echo "  Claude Code: /bridge-brief  → write task spec for Codex"
[[ "$HAS_CODEX"  == true ]] && echo "  Codex:       \$bridge-receive → read task and implement"
[[ "$HAS_CLAUDE" == true ]] && echo "  Claude Code: /bridge-gate-dual → read findings and gate"

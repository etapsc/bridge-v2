#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# BRIDGE v2.1 - Add Framework to Existing Project
# Installs BRIDGE tooling into an existing project directory.
# Default packs do NOT overwrite files in docs/, src/, or tests/.
# dual-agent is a managed overlay that can update its owned files
# and writes timestamped backups when it does.
#
# Source resolution (auto-detected):
#   1. Local folder:  ./bridge-{pack}/ exists → copy contents
#   2. Local tar:     ./bridge-{pack}.tar.gz exists → extract
#   3. Remote:        download tar from GitHub Releases
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Defaults ---
PROJECT_NAME=""
PACK=""
TARGET_DIR=""
GITHUB_REPO="${BRIDGE_REPO:-etapsc/bridge-v2}"
VERSION="${BRIDGE_VERSION:-latest}"

# --- Usage ---
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Add BRIDGE v2.1 methodology tooling to an existing project.

Unlike setup.sh (which creates a new project), this script installs
BRIDGE framework files into an existing directory. Default packs do NOT
overwrite files in docs/, src/, or tests/ directories. The dual-agent
overlay updates managed files with timestamped backups.

Options:
  -n, --name NAME        Project name (used for {{PROJECT_NAME}} placeholders)
  -p, --pack PACK        Pack: full, standalone, claude-code, codex, opencode, dual-agent
  -t, --target DIR       Target project directory (default: current directory)
  -r, --repo OWNER/REPO  GitHub repo for remote download (default: $GITHUB_REPO)
  -v, --version TAG      Release tag for remote download (default: latest)
  -h, --help             Show this help

Examples:
  $(basename "$0") --name "My Project" --pack claude-code --target ./my-project
  $(basename "$0") --name "My Project" --pack full                  # add to current dir
  cd my-project && $(basename "$0") --name "My Project" --pack codex
EOF
    exit 0
}

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name)    PROJECT_NAME="$2"; shift 2 ;;
        -p|--pack)    PACK="$2"; shift 2 ;;
        -t|--target)  TARGET_DIR="$2"; shift 2 ;;
        -r|--repo)    GITHUB_REPO="$2"; shift 2 ;;
        -v|--version) VERSION="$2"; shift 2 ;;
        -h|--help)    usage ;;
        *)            echo "Unknown option: $1"; usage ;;
    esac
done

# --- Interactive pack selection if not specified ---
if [[ -z "$PACK" ]]; then
    echo ""
    echo "Available packs:"
    echo "  1) full        - Rules + Skills + thin slash commands for RooCode (recommended)"
    echo "  2) standalone  - Self-contained slash commands for RooCode (no rules/skills)"
    echo "  3) claude-code - CLAUDE.md + agents + skills + commands for Claude Code CLI"
    echo "  4) codex       - AGENTS.md + skills for OpenAI Codex CLI"
    echo "  5) opencode    - AGENTS.md + agents + skills + commands for OpenCode CLI"
    echo "  6) dual-agent  - Overlay for Claude Code + Codex coordination in existing BRIDGE projects"
    echo ""
    read -rp "Select pack [1]: " pack_choice
    case "${pack_choice:-1}" in
        1|full)        PACK="full" ;;
        2|standalone)  PACK="standalone" ;;
        3|claude-code) PACK="claude-code" ;;
        4|codex)       PACK="codex" ;;
        5|opencode)    PACK="opencode" ;;
        6|dual-agent)  PACK="dual-agent" ;;
        *)             echo "Error: Invalid choice."; exit 1 ;;
    esac
fi

# --- Pack validation ---
if [[ "$PACK" != "full" && "$PACK" != "standalone" && "$PACK" != "claude-code" && "$PACK" != "codex" && "$PACK" != "opencode" && "$PACK" != "dual-agent" ]]; then
    echo "Error: Pack must be 'full', 'standalone', 'claude-code', 'codex', 'opencode', or 'dual-agent'. Got: $PACK"
    exit 1
fi

# --- Interactive name if not specified ---
if [[ -z "$PROJECT_NAME" ]]; then
    read -rp "Project name: " PROJECT_NAME
    if [[ -z "$PROJECT_NAME" ]]; then
        echo "Error: Project name is required."
        exit 1
    fi
fi

# --- Interactive target directory if not specified ---
if [[ -z "$TARGET_DIR" ]]; then
    read -rp "Target project directory [.]: " TARGET_DIR
    TARGET_DIR="${TARGET_DIR:-.}"
fi

# --- Verify target exists ---
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Target directory does not exist: $TARGET_DIR"
    exit 1
fi

# Resolve to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# --- Resolve source ---
PACK_FOLDER="${SCRIPT_DIR}/bridge-${PACK}"
PACK_ARCHIVE="${SCRIPT_DIR}/bridge-${PACK}.tar.gz"
SOURCE_MODE=""

if [[ -d "$PACK_FOLDER" ]]; then
    SOURCE_MODE="folder"
elif [[ -f "$PACK_ARCHIVE" ]]; then
    SOURCE_MODE="tar"
else
    SOURCE_MODE="remote"
    if ! command -v curl &>/dev/null; then
        echo "Error: curl is required for remote download but not found."
        exit 1
    fi
fi

# --- Summary ---
echo ""
echo "Adding BRIDGE v2.1 to existing project..."
echo "  Project:   $PROJECT_NAME"
echo "  Pack:      $PACK"
echo "  Target:    $TARGET_DIR"
echo "  Source:    $SOURCE_MODE"
if [[ "$SOURCE_MODE" == "remote" ]]; then
    echo "  Repo:      $GITHUB_REPO"
    echo "  Version:   $VERSION"
fi
echo ""
if [[ "$PACK" == "dual-agent" ]]; then
    echo "  Mode:      managed overlay install (updates include per-file backups)"
else
    echo "  Protected: docs/ src/ tests/ (existing files will NOT be overwritten)"
fi
echo ""

# --- Extract pack to a temporary staging directory ---
STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT

case "$SOURCE_MODE" in
    folder)
        echo "Copying from local source folder..."
        cp -a "$PACK_FOLDER"/. "$STAGING_DIR"/
        ;;
    tar)
        echo "Extracting from local archive..."
        tar -xzf "$PACK_ARCHIVE" -C "$STAGING_DIR"
        ;;
    remote)
        if [[ "$VERSION" == "latest" ]]; then
            DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/latest/download/bridge-${PACK}.tar.gz"
        else
            DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${VERSION}/bridge-${PACK}.tar.gz"
        fi
        echo "Downloading bridge-${PACK}.tar.gz..."
        echo "  URL: $DOWNLOAD_URL"
        TMPFILE="$(mktemp)"
        if ! curl -fsSL -o "$TMPFILE" "$DOWNLOAD_URL"; then
            rm -f "$TMPFILE"
            echo ""
            echo "Error: Failed to download pack archive."
            echo "  - Check that the repo '${GITHUB_REPO}' exists and has releases"
            echo "  - Check that version '${VERSION}' exists"
            echo "  - URL attempted: $DOWNLOAD_URL"
            exit 1
        fi
        tar -xzf "$TMPFILE" -C "$STAGING_DIR"
        rm -f "$TMPFILE"
        ;;
esac

# --- Replace {{PROJECT_NAME}} placeholder in staging files ---
echo "Personalizing files..."

find "$STAGING_DIR" -type f \( -name "*.md" -o -name "*.json" -o -name "*.toml" -o -name ".roomodes" \) | while read -r file; do
    if grep -q '{{PROJECT_NAME}}' "$file" 2>/dev/null; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "s/{{PROJECT_NAME}}/${PROJECT_NAME//\//\\/}/g" "$file"
        else
            sed -i "s/{{PROJECT_NAME}}/${PROJECT_NAME//\//\\/}/g" "$file"
        fi
    fi
done

# --- Report arrays ---
INSTALLED=()
UPDATED=()
SKIPPED=()

# --- Helper functions ---
replace_or_install_file() {
    local src="$1"
    local rel="$2"
    local dest="${TARGET_DIR}/${rel}"
    local dest_dir
    dest_dir="$(dirname "$dest")"

    mkdir -p "$dest_dir"

    if [[ -f "$dest" ]]; then
        if cmp -s "$src" "$dest"; then
            return
        fi
        local backup_rel="${rel}.bak.$(date +%Y%m%d%H%M%S)"
        cp -a "$dest" "${TARGET_DIR}/${backup_rel}"
        cp -a "$src" "$dest"
        UPDATED+=("${rel} (backup: ${backup_rel})")
        return
    fi

    cp -a "$src" "$dest"
    INSTALLED+=("$rel")
}

upsert_markdown_section() {
    local target_file="$1"
    local rel="$2"
    local section_file="$3"
    local section_header="$4"

    if [[ ! -f "$target_file" ]]; then
        SKIPPED+=("${rel} (missing; could not apply dual-agent section)")
        return
    fi

    local tmp_file
    tmp_file="$(mktemp)"

    if grep -Fq "$section_header" "$target_file"; then
        awk -v header="$section_header" '
            BEGIN { skipping = 0 }
            {
                if (!skipping && index($0, header) > 0) {
                    skipping = 1
                    next
                }
                if (skipping && $0 ~ /^## /) {
                    skipping = 0
                }
                if (!skipping) {
                    print
                }
            }
        ' "$target_file" > "$tmp_file"

        # Remove trailing separator/blank lines left from the previous addon block.
        awk '
            { lines[NR] = $0 }
            END {
                end = NR
                while (end > 0 && (lines[end] ~ /^[[:space:]]*$/ || lines[end] ~ /^---[[:space:]]*$/)) {
                    end--
                }
                for (i = 1; i <= end; i++) {
                    print lines[i]
                }
            }
        ' "$tmp_file" > "${tmp_file}.trimmed"
        mv "${tmp_file}.trimmed" "$tmp_file"
    else
        cat "$target_file" > "$tmp_file"
    fi

    echo "" >> "$tmp_file"
    cat "$section_file" >> "$tmp_file"

    if cmp -s "$tmp_file" "$target_file"; then
        rm -f "$tmp_file"
        return
    fi

    local backup_file="${target_file}.bak.$(date +%Y%m%d%H%M%S)"
    cp -a "$target_file" "$backup_file"
    mv "$tmp_file" "$target_file"
    UPDATED+=("${rel} (dual-agent section upserted; backup: $(basename "$backup_file"))")
}

install_dual_agent_overlay() {
    local has_claude=false
    local has_codex=false

    [[ -d "${TARGET_DIR}/.claude" ]] && has_claude=true
    [[ -d "${TARGET_DIR}/.agents" ]] && has_codex=true

    if [[ "$has_claude" == false && "$has_codex" == false ]]; then
        echo "Error: dual-agent pack requires an existing BRIDGE Claude Code or Codex install."
        echo "  Missing both: ${TARGET_DIR}/.claude and ${TARGET_DIR}/.agents"
        exit 1
    fi

    echo "Installing dual-agent overlay..."

    if [[ "$has_claude" == true ]]; then
        replace_or_install_file "$STAGING_DIR/.claude/commands/bridge-brief.md" ".claude/commands/bridge-brief.md"
        replace_or_install_file "$STAGING_DIR/.claude/commands/bridge-gate-dual.md" ".claude/commands/bridge-gate-dual.md"
        replace_or_install_file "$STAGING_DIR/.claude/skills/bridge-dual-agent/SKILL.md" ".claude/skills/bridge-dual-agent/SKILL.md"
        upsert_markdown_section "${TARGET_DIR}/CLAUDE.md" "CLAUDE.md" "$STAGING_DIR/claude-md-addon.md" "## [DUAL-AGENT ADD-ON] — Codex Coordination"
    else
        SKIPPED+=(".claude/* (Claude Code pack not detected)")
    fi

    if [[ "$has_codex" == true ]]; then
        replace_or_install_file "$STAGING_DIR/.agents/skills/bridge-receive/SKILL.md" ".agents/skills/bridge-receive/SKILL.md"
        upsert_markdown_section "${TARGET_DIR}/AGENTS.md" "AGENTS.md" "$STAGING_DIR/agents-md-addon.md" "## [DUAL-AGENT ADD-ON] — Claude Code Coordination"
    else
        SKIPPED+=(".agents/* (Codex pack not detected)")
    fi

    replace_or_install_file "$STAGING_DIR/docs-templates/current-task.md" "docs/current-task.md"
    replace_or_install_file "$STAGING_DIR/docs-templates/codex-findings.md" "docs/codex-findings.md"
}

# --- Protected directories: never overwrite existing files ---
PROTECTED_DIRS=("docs" "doc" "src" "tests" "test")

# --- Install framework files ---
echo "Installing framework files..."

install_file() {
    local src="$1"
    local rel="$2"

    local dest="${TARGET_DIR}/${rel}"
    local dest_dir
    dest_dir="$(dirname "$dest")"

    # Check if this file falls under a protected directory
    local top_dir
    top_dir="$(echo "$rel" | cut -d'/' -f1)"

    local is_protected=false
    for pdir in "${PROTECTED_DIRS[@]}"; do
        if [[ "$top_dir" == "$pdir" ]]; then
            is_protected=true
            break
        fi
    done

    if [[ "$is_protected" == true ]]; then
        if [[ -f "$dest" ]]; then
            SKIPPED+=("$rel (exists)")
            return
        fi
    fi

    mkdir -p "$dest_dir"
    cp -a "$src" "$dest"
    INSTALLED+=("$rel")
}

if [[ "$PACK" == "dual-agent" ]]; then
    install_dual_agent_overlay
else
    while IFS= read -r -d '' file; do
        rel="${file#"$STAGING_DIR"/}"
        install_file "$file" "$rel"
    done < <(find "$STAGING_DIR" -type f -print0)
fi

# --- Report ---
echo ""
echo "BRIDGE v2.1 added to: $TARGET_DIR"
echo ""

if [[ ${#INSTALLED[@]} -gt 0 ]]; then
    echo "Installed (${#INSTALLED[@]} files):"
    for f in "${INSTALLED[@]}"; do
        echo "  + $f"
    done
fi

if [[ ${#UPDATED[@]} -gt 0 ]]; then
    echo ""
    echo "Updated (${#UPDATED[@]} files):"
    for f in "${UPDATED[@]}"; do
        echo "  * $f"
    done
fi

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    echo ""
    echo "Skipped (${#SKIPPED[@]} items):"
    for f in "${SKIPPED[@]}"; do
        echo "  ~ $f"
    done
fi

echo ""
echo "Next steps:"
echo "  1. cd $TARGET_DIR"
if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    if [[ "$PACK" == "dual-agent" ]]; then
        echo "  2. Review skipped items and backups (*.bak.YYYYMMDDHHMMSS)"
        echo "     to confirm the dual-agent overlay update behavior."
    else
        echo "  2. Review skipped docs/ files — BRIDGE templates are in the pack"
        echo "     if you need to manually merge content."
    fi
fi
if [[ "$PACK" == "claude-code" ]]; then
    echo "  3. Run: claude"
    echo "  4. Run /bridge-scope or /bridge-feature to begin"
elif [[ "$PACK" == "codex" ]]; then
    echo "  3. Run: codex"
    echo "  4. Invoke \$bridge-scope or \$bridge-feature to begin"
elif [[ "$PACK" == "opencode" ]]; then
    echo "  3. Run: opencode"
    echo "  4. Run /bridge-scope or /bridge-feature to begin"
elif [[ "$PACK" == "dual-agent" ]]; then
    echo "  3. Claude Code: /bridge-brief"
    echo "  4. Codex:       \$bridge-receive"
    echo "  5. Claude Code: /bridge-gate-dual"
elif [[ "$PACK" == "full" ]]; then
    echo "  3. Open in VS Code with RooCode extension"
    echo "  4. Run /bridge-scope or /bridge-feature to begin"
else
    echo "  3. Open in VS Code with RooCode extension"
    echo "  4. Run /bridge-scope or /bridge-feature to begin"
fi
echo ""

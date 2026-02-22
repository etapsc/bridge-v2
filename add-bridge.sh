#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# BRIDGE v2.1 - Add Framework to Existing Project
# Installs BRIDGE tooling into an existing project directory
# WITHOUT overwriting files in docs/, src/, or tests/.
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
BRIDGE framework files into an existing directory. It will NOT
overwrite files in docs/, src/, or tests/ directories.

Options:
  -n, --name NAME        Project name (used for {{PROJECT_NAME}} placeholders)
  -p, --pack PACK        Pack: full, standalone, claude-code, codex, opencode
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
    echo ""
    read -rp "Select pack [1]: " pack_choice
    case "${pack_choice:-1}" in
        1|full)        PACK="full" ;;
        2|standalone)  PACK="standalone" ;;
        3|claude-code) PACK="claude-code" ;;
        4|codex)       PACK="codex" ;;
        5|opencode)    PACK="opencode" ;;
        *)             echo "Error: Invalid choice."; exit 1 ;;
    esac
fi

# --- Pack validation ---
if [[ "$PACK" != "full" && "$PACK" != "standalone" && "$PACK" != "claude-code" && "$PACK" != "codex" && "$PACK" != "opencode" ]]; then
    echo "Error: Pack must be 'full', 'standalone', 'claude-code', 'codex', or 'opencode'. Got: $PACK"
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
echo "  Protected: docs/ src/ tests/ (existing files will NOT be overwritten)"
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

# --- Protected directories: never overwrite existing files ---
PROTECTED_DIRS=("docs" "doc" "src" "tests" "test")

# --- Install framework files ---
echo "Installing framework files..."

INSTALLED=()
SKIPPED=()

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

while IFS= read -r -d '' file; do
    rel="${file#"$STAGING_DIR"/}"
    install_file "$file" "$rel"
done < <(find "$STAGING_DIR" -type f -print0)

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

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    echo ""
    echo "Skipped (${#SKIPPED[@]} files, already exist in protected dirs):"
    for f in "${SKIPPED[@]}"; do
        echo "  ~ $f"
    done
fi

echo ""
echo "Next steps:"
echo "  1. cd $TARGET_DIR"
if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    echo "  2. Review skipped docs/ files — BRIDGE templates are in the pack"
    echo "     if you need to manually merge content."
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
elif [[ "$PACK" == "full" ]]; then
    echo "  3. Open in VS Code with RooCode extension"
    echo "  4. Run /bridge-scope or /bridge-feature to begin"
else
    echo "  3. Open in VS Code with RooCode extension"
    echo "  4. Run /bridge-scope or /bridge-feature to begin"
fi
echo ""

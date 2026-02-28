#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# BRIDGE v2.1 - Project Setup Script
# Creates a new project directory with BRIDGE tooling.
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
OUTPUT_DIR=""
GITHUB_REPO="${BRIDGE_REPO:-etapsc/bridge-v2}"
VERSION="${BRIDGE_VERSION:-latest}"

# --- Usage ---
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Create a new project with BRIDGE v2.1 methodology tooling.

Options:
  -n, --name NAME        Project name (required unless interactive)
  -p, --pack PACK        Pack: full, standalone, claude-code, codex (default: interactive)
  -o, --output DIR       Output parent directory (default: current directory)
  -r, --repo OWNER/REPO  GitHub repo for remote download (default: $GITHUB_REPO)
  -v, --version TAG      Release tag for remote download (default: latest)
  -h, --help             Show this help

Install modes (auto-detected):
  Local clone:   ./setup.sh --name "My Project" --pack claude-code
  Remote (curl): curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/main/setup.sh | \\
                   bash -s -- --pack claude-code --name "My Project"

Examples:
  $(basename "$0") --name "My Project" --pack full          # RooCode (rules+skills)
  $(basename "$0") --name "My Project" --pack standalone    # RooCode (self-contained)
  $(basename "$0") --name "My Project" --pack claude-code   # Claude Code CLI
  $(basename "$0") --name "My Project" --pack codex         # OpenAI Codex CLI
  $(basename "$0") --name "My Project" --pack opencode      # OpenCode CLI
  $(basename "$0")                                          # interactive mode
EOF
    exit 0
}

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name)    PROJECT_NAME="$2"; shift 2 ;;
        -p|--pack)    PACK="$2"; shift 2 ;;
        -o|--output)  OUTPUT_DIR="$2"; shift 2 ;;
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

# --- Interactive output directory if not specified ---
if [[ -z "$OUTPUT_DIR" ]]; then
    read -rp "Output directory [.]: " OUTPUT_DIR
    OUTPUT_DIR="${OUTPUT_DIR:-.}"
fi

# --- Slugify project name ---
slugify() {
    echo "$1" | \
        tr '[:upper:]' '[:lower:]' | \
        sed -E 's/[^a-z0-9]+/-/g' | \
        sed -E 's/^-+|-+$//g'
}

PROJECT_SLUG="$(slugify "$PROJECT_NAME")"
OUTPUT_DIR="${OUTPUT_DIR:-.}"
PROJECT_DIR="${OUTPUT_DIR}/${PROJECT_SLUG}"

# --- Check target doesn't exist ---
if [[ -d "$PROJECT_DIR" ]]; then
    echo "Error: Directory already exists: $PROJECT_DIR"
    read -rp "Overwrite BRIDGE files? (y/N): " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# --- Resolve source ---
PACK_FOLDER="${SCRIPT_DIR}/bridge-${PACK}"
PACK_ARCHIVE="${SCRIPT_DIR}/bridge-${PACK}.tar.gz"
SOURCE_MODE=""

# claude-code pack uses project/ subdirectory when copying from folder
if [[ "$PACK" == "claude-code" && -d "$PACK_FOLDER/project" ]]; then
    PACK_FOLDER="${PACK_FOLDER}/project"
    SOURCE_MODE="folder"
elif [[ -d "$PACK_FOLDER" ]]; then
    SOURCE_MODE="folder"
elif [[ -f "$PACK_ARCHIVE" ]]; then
    SOURCE_MODE="tar"
else
    SOURCE_MODE="remote"
    # Check for curl
    if ! command -v curl &>/dev/null; then
        echo "Error: curl is required for remote download but not found."
        exit 1
    fi
fi

# --- Summary ---
echo ""
echo "Setting up BRIDGE v2.1..."
echo "  Project:   $PROJECT_NAME"
echo "  Slug:      $PROJECT_SLUG"
echo "  Pack:      $PACK"
echo "  Directory: $PROJECT_DIR"
echo "  Source:    $SOURCE_MODE"
if [[ "$SOURCE_MODE" == "remote" ]]; then
    echo "  Repo:      $GITHUB_REPO"
    echo "  Version:   $VERSION"
fi
echo ""

mkdir -p "$PROJECT_DIR"

# --- Install pack based on source mode ---
case "$SOURCE_MODE" in
    folder)
        echo "Copying from local source folder..."
        cp -a "$PACK_FOLDER"/. "$PROJECT_DIR"/
        ;;
    tar)
        echo "Extracting from local archive..."
        tar -xzf "$PACK_ARCHIVE" -C "$PROJECT_DIR"
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
        trap 'rm -f "$TMPFILE"' EXIT
        if ! curl -fsSL -o "$TMPFILE" "$DOWNLOAD_URL"; then
            echo ""
            echo "Error: Failed to download pack archive."
            echo "  - Check that the repo '${GITHUB_REPO}' exists and has releases"
            echo "  - Check that version '${VERSION}' exists"
            echo "  - URL attempted: $DOWNLOAD_URL"
            exit 1
        fi
        tar -xzf "$TMPFILE" -C "$PROJECT_DIR"
        ;;
esac

# --- Replace {{PROJECT_NAME}} placeholder in all files ---
echo "Personalizing files..."

find "$PROJECT_DIR" -type f \( -name "*.md" -o -name "*.json" -o -name "*.toml" -o -name ".roomodes" \) | while read -r file; do
    if grep -q '{{PROJECT_NAME}}' "$file" 2>/dev/null; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "s/{{PROJECT_NAME}}/${PROJECT_NAME//\//\\/}/g" "$file"
        else
            sed -i "s/{{PROJECT_NAME}}/${PROJECT_NAME//\//\\/}/g" "$file"
        fi
    fi
done

# --- Create additional directories ---
mkdir -p "$PROJECT_DIR/docs/contracts"
mkdir -p "$PROJECT_DIR/tests/unit"
mkdir -p "$PROJECT_DIR/tests/integration"
mkdir -p "$PROJECT_DIR/tests/e2e"
mkdir -p "$PROJECT_DIR/src"

# --- Summary ---
echo ""
echo "BRIDGE v2.1 project created: $PROJECT_DIR"
echo ""
echo "Directory structure:"
find "$PROJECT_DIR" -type f | sort | sed "s|$PROJECT_DIR/|  |"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_DIR"
if [[ "$PACK" == "claude-code" ]]; then
    echo "  2. Open terminal and run: claude"
    echo "  3. Run /bridge-brainstorm or /bridge-requirements-only to start"
elif [[ "$PACK" == "codex" ]]; then
    echo "  2. Open terminal and run: codex"
    echo "  3. Invoke \$bridge-brainstorm or \$bridge-requirements-only to start"
elif [[ "$PACK" == "opencode" ]]; then
    echo "  2. Open terminal and run: opencode"
    echo "  3. Run /bridge-brainstorm or /bridge-requirements-only to start"
elif [[ "$PACK" == "full" ]]; then
    echo "  2. Open in VS Code with RooCode extension"
    echo "  3. Configure model assignments for each mode (see reference/BRIDGE-v2.1-methodology.md)"
    echo "  4. Run /bridge-brainstorm or /bridge-requirements-only to start"
else
    echo "  2. Open in VS Code with RooCode extension"
    echo "  3. Run /bridge-brainstorm or /bridge-requirements-only to start"
fi
echo ""
echo "Slash commands available:"
echo "  /bridge-brainstorm         - Brainstorm a new idea"
echo "  /bridge-requirements       - Generate requirements from brainstorm"
echo "  /bridge-requirements-only  - Generate requirements from description"
echo "  /bridge-scope              - Scope a feature/fix for existing project"
echo "  /bridge-feature            - Incremental requirements for existing project"
echo "  /bridge-design             - Integrate a design document, PRD, or version spec"
echo "  /bridge-migrate            - Migrate BRIDGE v1 project to v2.1"
echo "  /bridge-start              - Start implementation"
echo "  /bridge-resume             - Resume in fresh session"
echo "  /bridge-end                - End session"
echo "  /bridge-gate               - Run quality gate"
echo "  /bridge-eval               - Generate evaluation pack"
echo "  /bridge-feedback           - Process feedback"
echo "  /bridge-offload            - External agent handoff"
echo "  /bridge-reintegrate        - Re-integrate external work"
echo "  /bridge-context-create     - Create context.json"
echo "  /bridge-context-update     - Sync context.json"
echo "  /bridge-advisor            - Strategic advisor: viability, positioning, launch readiness"

#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# BRIDGE — Unified Shell Installer
#
# Single entrypoint for: new, add, orchestrator, pack
#
# Usage:
#   bridge.sh new   [OPTIONS]   — create a new project
#   bridge.sh add   [OPTIONS]   — add to existing project
#   bridge.sh orchestrator      — install controller / multi-repo
#   bridge.sh pack              — rebuild tar.gz archives
#   bridge.sh                   — interactive menu
#
# Source resolution (auto-detected):
#   1. Local folder:  ./bridge-{pack}/ → copy
#   2. Local tar:     ./bridge-{pack}.tar.gz → extract
#   3. Remote:        download from GitHub Releases
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_REPO="${BRIDGE_REPO:-etapsc/bridge}"
VERSION="${BRIDGE_VERSION:-latest}"

# --- Colors ---
if [[ -t 1 ]]; then
    BOLD="\033[1m" DIM="\033[2m" GREEN="\033[32m"
    CYAN="\033[36m" YELLOW="\033[33m" RED="\033[31m" RESET="\033[0m"
else
    BOLD="" DIM="" GREEN="" CYAN="" YELLOW="" RED="" RESET=""
fi

# ============================================================
# SHARED HELPERS
# ============================================================

info()    { echo -e "${GREEN}>${RESET} $*"; }
prompt()  { echo -en "${CYAN}?${RESET} $*" >&2; }
warn()    { echo -e "${YELLOW}!${RESET} $*"; }
header()  { echo -e "\n${BOLD}$*${RESET}\n"; }

ask() {
    local var_name="$1" label="$2" default="${3:-}"
    if [[ -n "$default" ]]; then
        prompt "$label [$default]: "
    else
        prompt "$label: "
    fi
    local answer
    read -r answer
    answer="${answer:-$default}"
    printf -v "$var_name" '%s' "$answer"
}

ask_yn() {
    local label="$1" default="${2:-y}"
    local hint="Y/n"
    [[ "$default" == "n" ]] && hint="y/N"
    prompt "$label ($hint): "
    local answer
    read -r answer
    answer="${answer:-$default}"
    if [[ "$default" == "y" ]]; then
        [[ "${answer,,}" != "n" && "${answer,,}" != "no" ]]
    else
        [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]
    fi
}

slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

resolve_source() {
    local pack_name="$1" target_dir="$2" subfolder="${3:-}"

    local pack_folder="${SCRIPT_DIR}/${pack_name}"
    local pack_archive="${SCRIPT_DIR}/${pack_name}.tar.gz"

    if [[ -n "$subfolder" && -d "$pack_folder/$subfolder" ]]; then
        info "Copying from local source: ${pack_name}/${subfolder}/"
        cp -a "$pack_folder/$subfolder"/. "$target_dir"/
    elif [[ -d "$pack_folder" && -z "$subfolder" ]]; then
        info "Copying from local source: ${pack_name}/"
        cp -a "$pack_folder"/. "$target_dir"/
    elif [[ -f "$pack_archive" ]]; then
        info "Extracting from: ${pack_name}.tar.gz"
        tar -xzf "$pack_archive" -C "$target_dir"
    else
        if ! command -v curl &>/dev/null; then
            echo "Error: curl is required for remote download but not found."
            exit 1
        fi
        local url
        if [[ "$VERSION" == "latest" ]]; then
            url="https://github.com/${GITHUB_REPO}/releases/latest/download/${pack_name}.tar.gz"
        else
            url="https://github.com/${GITHUB_REPO}/releases/download/${VERSION}/${pack_name}.tar.gz"
        fi
        info "Downloading ${pack_name}.tar.gz from GitHub..."
        local tmpfile
        tmpfile="$(mktemp)"
        if ! curl -fsSL -o "$tmpfile" "$url"; then
            rm -f "$tmpfile"
            echo "Error: Failed to download from $url"
            exit 1
        fi
        tar -xzf "$tmpfile" -C "$target_dir"
        rm -f "$tmpfile"
    fi
}

replace_placeholder() {
    local dir="$1" name="$2"
    find "$dir" -type f \( -name "*.md" -o -name "*.json" -o -name "*.toml" -o -name ".roomodes" \) | while read -r file; do
        if grep -q '{{PROJECT_NAME}}' "$file" 2>/dev/null; then
            if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' "s/{{PROJECT_NAME}}/${name//\//\\/}/g" "$file"
            else
                sed -i "s/{{PROJECT_NAME}}/${name//\//\\/}/g" "$file"
            fi
        fi
    done
}

select_pack() {
    local include_dual="${1:-false}"
    echo "" >&2
    echo "  Available packs:" >&2
    echo "    1) full        — Rules + Skills for RooCode (recommended)" >&2
    echo "    2) standalone  — Self-contained commands for RooCode" >&2
    echo "    3) claude-code — CLAUDE.md + agents + commands for Claude Code CLI" >&2
    echo "    4) codex       — AGENTS.md + skills for OpenAI Codex CLI" >&2
    echo "    5) opencode    — AGENTS.md + agents + commands for OpenCode CLI" >&2
    if [[ "$include_dual" == "true" ]]; then
        echo "    6) dual-agent  — Overlay for Claude Code + Codex coordination" >&2
    fi
    echo "" >&2
    local pack_choice
    ask pack_choice "Select pack" "1"
    case "$pack_choice" in
        1|full)        echo "full" ;;
        2|standalone)  echo "standalone" ;;
        3|claude-code) echo "claude-code" ;;
        4|codex)       echo "codex" ;;
        5|opencode)    echo "opencode" ;;
        6|dual-agent)
            if [[ "$include_dual" == "true" ]]; then echo "dual-agent"
            else echo "INVALID"; fi ;;
        *)             echo "INVALID" ;;
    esac
}

validate_pack() {
    local pack="$1" allow_dual="${2:-false}"
    local valid="full standalone claude-code codex opencode"
    [[ "$allow_dual" == "true" ]] && valid="$valid dual-agent"
    for v in $valid; do
        [[ "$pack" == "$v" ]] && return 0
    done
    return 1
}

validate_personality() {
    case "$1" in
        strict|balanced|mentoring) return 0 ;;
        *) return 1 ;;
    esac
}

load_vibe_line() {
    local personality="$1" role="$2"
    local profile_file="${SCRIPT_DIR}/profiles/${personality}.json"
    if [[ ! -f "$profile_file" ]]; then
        echo "Error: Personality profile not found: ${profile_file}"
        exit 1
    fi

    local vibe_line
    vibe_line="$(grep -E "^[[:space:]]*\"${role}\"[[:space:]]*:" "$profile_file" | head -1 | sed -E 's/^[[:space:]]*"[^"]+"[[:space:]]*:[[:space:]]*"(.*)"[[:space:]]*,?[[:space:]]*$/\1/' | sed 's/\\"/"/g')"
    if [[ -z "$vibe_line" ]]; then
        echo "Error: Missing ${role} vibe in ${profile_file}"
        exit 1
    fi

    printf '%s' "$vibe_line"
}

personality_role_for_path() {
    local path="$1"
    local name
    name="$(basename "$path")"
    if [[ "$name" == "SKILL.md" ]]; then
        name="$(basename "$(dirname "$path")")"
    else
        name="${name%.md}"
    fi

    case "$name" in
        bridge-architect|00-architect) echo "architect" ;;
        bridge-coder|00-code) echo "coder" ;;
        bridge-debugger|00-debug) echo "debugger" ;;
        bridge-auditor|00-audit|bridge-gate-audit) echo "auditor" ;;
        bridge-evaluator|00-evaluate|bridge-eval-generate) echo "evaluator" ;;
        bridge-advisor) echo "advisor" ;;
        bridge-brainstorm) echo "brainstorm" ;;
        bridge-start|bridge-resume|00-orchestrator|bridge-slice-plan|bridge-session-management) echo "orchestrator" ;;
        *) return 1 ;;
    esac
}

insert_personality_block() {
    local path="$1" vibe="$2"
    local marker_start="<!-- bridge:personality -->"
    local marker_end="<!-- /bridge:personality -->"
    local block="${marker_start}
**Personality:** ${vibe}
${marker_end}"
    local tmp_file
    tmp_file="$(mktemp)"

    if grep -Fq "$marker_start" "$path"; then
        awk -v start="$marker_start" -v end="$marker_end" -v block="$block" '
            BEGIN { replacing = 0; inserted = 0 }
            index($0, start) > 0 {
                if (!inserted) {
                    print block
                    inserted = 1
                }
                replacing = 1
                next
            }
            replacing && index($0, end) > 0 {
                replacing = 0
                next
            }
            !replacing { print }
        ' "$path" > "$tmp_file"
    else
        local inserted=false
        local closing_frontmatter=""
        if [[ "$(head -1 "$path")" == "---" ]]; then
            closing_frontmatter="$(grep -n '^---$' "$path" | sed -n '2p' | cut -d: -f1 || true)"
        fi

        if [[ -n "$closing_frontmatter" ]]; then
            awk -v line="$closing_frontmatter" -v block="$block" '
                { print }
                NR == line {
                    print ""
                    print block
                }
            ' "$path" > "$tmp_file"
            inserted=true
        else
            local first_heading=""
            first_heading="$(grep -n '^# ' "$path" | head -1 | cut -d: -f1 || true)"
            if [[ -n "$first_heading" ]]; then
                awk -v line="$first_heading" -v block="$block" '
                    { print }
                    NR == line {
                        print ""
                        print block
                    }
                ' "$path" > "$tmp_file"
                inserted=true
            fi
        fi

        if [[ "$inserted" == false ]]; then
            {
                printf '%s\n\n' "$block"
                cat "$path"
            } > "$tmp_file"
        fi
    fi

    mv "$tmp_file" "$path"
}

apply_personality() {
    local target_dir="$1" personality="$2"
    [[ "$personality" == "balanced" ]] && return 0

    local rel_path role vibe patched=0
    local candidates=(
        "CLAUDE.md"
        "AGENTS.md"
        ".roo/rules-orchestrator/00-orchestrator.md"
        ".roo/rules-architect/00-architect.md"
        ".roo/rules-code/00-code.md"
        ".roo/rules-debug/00-debug.md"
        ".roo/rules-audit/00-audit.md"
        ".roo/rules-evaluate/00-evaluate.md"
        ".roo/commands/bridge-start.md"
        ".roo/commands/bridge-resume.md"
        ".roo/commands/bridge-brainstorm.md"
        ".roo/commands/bridge-advisor.md"
        ".claude/agents/bridge-architect.md"
        ".claude/agents/bridge-coder.md"
        ".claude/agents/bridge-debugger.md"
        ".claude/agents/bridge-auditor.md"
        ".claude/agents/bridge-evaluator.md"
        ".claude/commands/bridge-brainstorm.md"
        ".claude/commands/bridge-advisor.md"
        ".opencode/agents/bridge-architect.md"
        ".opencode/agents/bridge-coder.md"
        ".opencode/agents/bridge-debugger.md"
        ".opencode/agents/bridge-auditor.md"
        ".opencode/agents/bridge-evaluator.md"
        ".opencode/commands/bridge-brainstorm.md"
        ".opencode/commands/bridge-advisor.md"
        ".agents/skills/bridge-brainstorm/SKILL.md"
        ".agents/skills/bridge-advisor/SKILL.md"
        ".agents/procedures/bridge-slice-plan.md"
        ".agents/procedures/bridge-session-management.md"
        ".agents/procedures/bridge-gate-audit.md"
        ".agents/procedures/bridge-eval-generate.md"
    )

    for rel_path in "${candidates[@]}"; do
        local full_path="${target_dir}/${rel_path}"
        [[ -f "$full_path" ]] || continue

        if [[ "$rel_path" == "CLAUDE.md" || "$rel_path" == "AGENTS.md" ]]; then
            role="orchestrator"
        else
            role="$(personality_role_for_path "$full_path" || true)"
            [[ -n "$role" ]] || continue
        fi

        vibe="$(load_vibe_line "$personality" "$role")"
        insert_personality_block "$full_path" "$vibe"
        patched=$((patched + 1))
    done

    if [[ "$patched" -gt 0 ]]; then
        info "Applied ${personality} personality to ${patched} files"
    else
        warn "No personality targets found for ${personality}"
    fi
}

print_next_steps() {
    local pack="$1" dir="$2"
    echo ""
    echo "  Next steps:"
    echo "    1. cd $dir"
    case "$pack" in
        claude-code)
            echo "    2. Run: claude"
            echo "    3. Run /bridge-brainstorm or /bridge-requirements-only" ;;
        codex)
            echo "    2. Run: codex"
            echo "    3. Invoke \$bridge-brainstorm or \$bridge-requirements-only" ;;
        opencode)
            echo "    2. Run: opencode"
            echo "    3. Run /bridge-brainstorm or /bridge-requirements-only" ;;
        full)
            echo "    2. Open in VS Code with RooCode extension"
            echo "    3. Run /bridge-brainstorm or /bridge-requirements-only" ;;
        dual-agent)
            echo "    2. Claude Code: /bridge-brief"
            echo "    3. Codex: \$bridge-receive"
            echo "    4. Claude Code: /bridge-gate-dual" ;;
        *)
            echo "    2. Open in VS Code with RooCode extension"
            echo "    3. Run /bridge-brainstorm or /bridge-requirements-only" ;;
    esac
    echo ""
}

# ============================================================
# COMMAND: new — Create a new project
# ============================================================
cmd_new() {
    local PROJECT_NAME="" PACK="" OUTPUT_DIR="" PERSONALITY="balanced"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name)    PROJECT_NAME="$2"; shift 2 ;;
            -p|--pack)    PACK="$2"; shift 2 ;;
            --personality) PERSONALITY="$2"; shift 2 ;;
            -o|--output)  OUTPUT_DIR="$2"; shift 2 ;;
            -r|--repo)    GITHUB_REPO="$2"; shift 2 ;;
            -v|--version) VERSION="$2"; shift 2 ;;
            -h|--help)
                echo "Usage: $(basename "$0") new [OPTIONS]"
                echo ""
                echo "Create a new project with BRIDGE methodology tooling."
                echo ""
                echo "Options:"
                echo "  -n, --name NAME    Project name (required)"
                echo "  -p, --pack PACK    Pack: full, standalone, claude-code, codex, opencode"
                echo "      --personality  Personality: strict, balanced, mentoring (default: balanced)"
                echo "  -o, --output DIR   Output parent directory (default: .)"
                echo "  -r, --repo REPO    GitHub repo (default: $GITHUB_REPO)"
                echo "  -v, --version TAG  Release tag (default: latest)"
                exit 0 ;;
            *)  echo "Unknown option: $1"; exit 1 ;;
        esac
    done

    # Interactive prompts for missing values
    if [[ -z "$PACK" ]]; then
        PACK="$(select_pack)"
        [[ "$PACK" == "INVALID" ]] && { echo "Error: Invalid pack."; exit 1; }
    fi
    if ! validate_pack "$PACK"; then
        echo "Error: Invalid pack '$PACK'. Must be: full, standalone, claude-code, codex, opencode."
        exit 1
    fi
    if ! validate_personality "$PERSONALITY"; then
        echo "Error: Invalid personality '$PERSONALITY'. Must be: strict, balanced, mentoring."
        exit 1
    fi
    if [[ -z "$PROJECT_NAME" ]]; then
        ask PROJECT_NAME "Project name" ""
        [[ -z "$PROJECT_NAME" ]] && { echo "Error: Project name is required."; exit 1; }
    fi
    if [[ -z "$OUTPUT_DIR" ]]; then
        ask OUTPUT_DIR "Output directory" "."
    fi
    OUTPUT_DIR="${OUTPUT_DIR:-.}"

    local PROJECT_SLUG
    PROJECT_SLUG="$(slugify "$PROJECT_NAME")"
    local PROJECT_DIR="${OUTPUT_DIR}/${PROJECT_SLUG}"

    if [[ -d "$PROJECT_DIR" ]]; then
        echo "Error: Directory already exists: $PROJECT_DIR"
        if ! ask_yn "Overwrite BRIDGE files?" "n"; then
            echo "Aborted."; exit 1
        fi
    fi

    header "Setting up BRIDGE..."
    echo "  Project:   $PROJECT_NAME"
    echo "  Slug:      $PROJECT_SLUG"
    echo "  Pack:      $PACK"
    echo "  Personality: $PERSONALITY"
    echo "  Directory: $PROJECT_DIR"
    echo ""

    mkdir -p "$PROJECT_DIR"
    resolve_source "bridge-${PACK}" "$PROJECT_DIR"

    echo "Personalizing files..."
    replace_placeholder "$PROJECT_DIR" "$PROJECT_NAME"
    apply_personality "$PROJECT_DIR" "$PERSONALITY"

    mkdir -p "$PROJECT_DIR/docs/contracts" "$PROJECT_DIR/tests/unit" \
             "$PROJECT_DIR/tests/integration" "$PROJECT_DIR/tests/e2e" \
             "$PROJECT_DIR/src"

    echo ""
    info "BRIDGE project created: $PROJECT_DIR"
    print_next_steps "$PACK" "$PROJECT_DIR"
}

# ============================================================
# COMMAND: add — Add to existing project
# ============================================================

# --- Dual-agent overlay helpers ---
INSTALLED=()
UPDATED=()
SKIPPED=()

replace_or_install_file() {
    local src="$1" rel="$2" target_dir="$3"
    local dest="${target_dir}/${rel}"
    mkdir -p "$(dirname "$dest")"
    if [[ -f "$dest" ]]; then
        if cmp -s "$src" "$dest"; then return; fi
        local backup_rel="${rel}.bak.$(date +%Y%m%d%H%M%S)"
        cp -a "$dest" "${target_dir}/${backup_rel}"
        cp -a "$src" "$dest"
        UPDATED+=("${rel} (backup: ${backup_rel})")
        return
    fi
    cp -a "$src" "$dest"
    INSTALLED+=("$rel")
}

upsert_markdown_section() {
    local target_file="$1" rel="$2" section_file="$3" section_header="$4"
    if [[ ! -f "$target_file" ]]; then
        SKIPPED+=("${rel} (missing; could not apply dual-agent section)")
        return
    fi
    local tmp_file
    tmp_file="$(mktemp)"
    if grep -Fq "$section_header" "$target_file"; then
        awk -v header="$section_header" '
            BEGIN { skipping = 0 }
            { if (!skipping && index($0, header) > 0) { skipping = 1; next }
              if (skipping && $0 ~ /^## /) { skipping = 0 }
              if (!skipping) { print } }
        ' "$target_file" > "$tmp_file"
        awk '{ lines[NR] = $0 } END {
            end = NR
            while (end > 0 && (lines[end] ~ /^[[:space:]]*$/ || lines[end] ~ /^---[[:space:]]*$/)) end--
            for (i = 1; i <= end; i++) print lines[i]
        }' "$tmp_file" > "${tmp_file}.trimmed"
        mv "${tmp_file}.trimmed" "$tmp_file"
    else
        cat "$target_file" > "$tmp_file"
    fi
    echo "" >> "$tmp_file"
    cat "$section_file" >> "$tmp_file"
    if cmp -s "$tmp_file" "$target_file"; then rm -f "$tmp_file"; return; fi
    local backup_file="${target_file}.bak.$(date +%Y%m%d%H%M%S)"
    cp -a "$target_file" "$backup_file"
    mv "$tmp_file" "$target_file"
    UPDATED+=("${rel} (dual-agent section upserted; backup: $(basename "$backup_file"))")
}

install_dual_agent_overlay() {
    local staging_dir="$1" target_dir="$2"
    local has_claude=false has_codex=false
    [[ -d "${target_dir}/.claude" ]] && has_claude=true
    [[ -d "${target_dir}/.agents" ]] && has_codex=true
    if [[ "$has_claude" == false && "$has_codex" == false ]]; then
        echo "Error: dual-agent requires existing Claude Code or Codex install."
        exit 1
    fi
    echo "Installing dual-agent overlay..."
    if [[ "$has_claude" == true ]]; then
        replace_or_install_file "$staging_dir/.claude/commands/bridge-brief.md" ".claude/commands/bridge-brief.md" "$target_dir"
        replace_or_install_file "$staging_dir/.claude/commands/bridge-gate-dual.md" ".claude/commands/bridge-gate-dual.md" "$target_dir"
        replace_or_install_file "$staging_dir/.claude/skills/bridge-dual-agent/SKILL.md" ".claude/skills/bridge-dual-agent/SKILL.md" "$target_dir"
        upsert_markdown_section "${target_dir}/CLAUDE.md" "CLAUDE.md" "$staging_dir/claude-md-addon.md" "## [DUAL-AGENT ADD-ON] — Codex Coordination"
    else
        SKIPPED+=(".claude/* (Claude Code pack not detected)")
    fi
    if [[ "$has_codex" == true ]]; then
        replace_or_install_file "$staging_dir/.agents/skills/bridge-receive/SKILL.md" ".agents/skills/bridge-receive/SKILL.md" "$target_dir"
        upsert_markdown_section "${target_dir}/AGENTS.md" "AGENTS.md" "$staging_dir/agents-md-addon.md" "## [DUAL-AGENT ADD-ON] — Claude Code Coordination"
    else
        SKIPPED+=(".agents/* (Codex pack not detected)")
    fi
    replace_or_install_file "$staging_dir/docs-templates/current-task.md" "docs/current-task.md" "$target_dir"
    replace_or_install_file "$staging_dir/docs-templates/codex-findings.md" "docs/codex-findings.md" "$target_dir"
}

cmd_add() {
    local PROJECT_NAME="" PACK="" TARGET_DIR="" PERSONALITY="balanced"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name)    PROJECT_NAME="$2"; shift 2 ;;
            -p|--pack)    PACK="$2"; shift 2 ;;
            --personality) PERSONALITY="$2"; shift 2 ;;
            -t|--target)  TARGET_DIR="$2"; shift 2 ;;
            -r|--repo)    GITHUB_REPO="$2"; shift 2 ;;
            -v|--version) VERSION="$2"; shift 2 ;;
            -h|--help)
                echo "Usage: $(basename "$0") add [OPTIONS]"
                echo ""
                echo "Add BRIDGE tooling to an existing project."
                echo "Does NOT overwrite files in docs/, src/, or tests/."
                echo ""
                echo "Options:"
                echo "  -n, --name NAME    Project name (required)"
                echo "  -p, --pack PACK    Pack: full, standalone, claude-code, codex, opencode, dual-agent"
                echo "      --personality  Personality: strict, balanced, mentoring (default: balanced)"
                echo "  -t, --target DIR   Target project directory (default: .)"
                echo "  -r, --repo REPO    GitHub repo (default: $GITHUB_REPO)"
                echo "  -v, --version TAG  Release tag (default: latest)"
                exit 0 ;;
            *)  echo "Unknown option: $1"; exit 1 ;;
        esac
    done

    if [[ -z "$PACK" ]]; then
        PACK="$(select_pack true)"
        [[ "$PACK" == "INVALID" ]] && { echo "Error: Invalid pack."; exit 1; }
    fi
    if ! validate_pack "$PACK" true; then
        echo "Error: Invalid pack '$PACK'. Must be: full, standalone, claude-code, codex, opencode, dual-agent."
        exit 1
    fi
    if ! validate_personality "$PERSONALITY"; then
        echo "Error: Invalid personality '$PERSONALITY'. Must be: strict, balanced, mentoring."
        exit 1
    fi
    if [[ -z "$PROJECT_NAME" ]]; then
        ask PROJECT_NAME "Project name" ""
        [[ -z "$PROJECT_NAME" ]] && { echo "Error: Project name is required."; exit 1; }
    fi
    if [[ -z "$TARGET_DIR" ]]; then
        ask TARGET_DIR "Target project directory" "."
    fi
    TARGET_DIR="${TARGET_DIR:-.}"

    if [[ ! -d "$TARGET_DIR" ]]; then
        echo "Error: Target directory does not exist: $TARGET_DIR"
        exit 1
    fi
    TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

    header "Adding BRIDGE to existing project..."
    echo "  Project: $PROJECT_NAME"
    echo "  Pack:    $PACK"
    echo "  Personality: $PERSONALITY"
    echo "  Target:  $TARGET_DIR"
    if [[ "$PACK" == "dual-agent" ]]; then
        echo "  Mode:    managed overlay (updates include per-file backups)"
    else
        echo "  Protected: docs/ src/ tests/ (existing files NOT overwritten)"
    fi
    echo ""

    # Stage to temp dir
    local STAGING_DIR
    STAGING_DIR="$(mktemp -d)"
    trap 'rm -rf "${STAGING_DIR:-}"' EXIT

    resolve_source "bridge-${PACK}" "$STAGING_DIR"

    echo "Personalizing files..."
    replace_placeholder "$STAGING_DIR" "$PROJECT_NAME"

    INSTALLED=()
    UPDATED=()
    SKIPPED=()

    local PROTECTED_DIRS=("docs" "doc" "src" "tests" "test")

    if [[ "$PACK" == "dual-agent" ]]; then
        install_dual_agent_overlay "$STAGING_DIR" "$TARGET_DIR"
    else
        echo "Installing framework files..."
        while IFS= read -r -d '' file; do
            local rel="${file#"$STAGING_DIR"/}"
            local dest="${TARGET_DIR}/${rel}"
            local top_dir
            top_dir="$(echo "$rel" | cut -d'/' -f1)"

            local is_protected=false
            for pdir in "${PROTECTED_DIRS[@]}"; do
                [[ "$top_dir" == "$pdir" ]] && { is_protected=true; break; }
            done

            if [[ "$is_protected" == true && -f "$dest" ]]; then
                SKIPPED+=("$rel (exists)")
                continue
            fi

            mkdir -p "$(dirname "$dest")"
            cp -a "$file" "$dest"
            INSTALLED+=("$rel")
        done < <(find "$STAGING_DIR" -type f -print0)
    fi

    apply_personality "$TARGET_DIR" "$PERSONALITY"

    # Report
    echo ""
    info "BRIDGE added to: $TARGET_DIR"
    if [[ ${#INSTALLED[@]} -gt 0 ]]; then
        echo ""
        echo "  Installed (${#INSTALLED[@]} files):"
        for f in "${INSTALLED[@]}"; do echo "    + $f"; done
    fi
    if [[ ${#UPDATED[@]} -gt 0 ]]; then
        echo ""
        echo "  Updated (${#UPDATED[@]} files):"
        for f in "${UPDATED[@]}"; do echo "    * $f"; done
    fi
    if [[ ${#SKIPPED[@]} -gt 0 ]]; then
        echo ""
        echo "  Skipped (${#SKIPPED[@]} items):"
        for f in "${SKIPPED[@]}"; do echo "    ~ $f"; done
    fi
    print_next_steps "$PACK" "$TARGET_DIR"
}

# ============================================================
# COMMAND: orchestrator — Install controller / multi-repo
# ============================================================

create_bridgeinclude() {
    local path="$1" type="$2" description="$3"
    local workspace="${4:-}" platform="${5:-}" priority="${6:-}"
    local file="${path}/.bridgeinclude"
    {
        echo "type = \"${type}\""
        echo "description = \"${description}\""
        [[ -n "$platform" ]]  && echo "platform = \"${platform}\""
        [[ -n "$workspace" ]] && echo "workspace = \"${workspace}\""
        [[ -n "$priority" ]]  && echo "priority = \"${priority}\""
    } > "$file"
    info "Created ${file}"
}

install_controller() {
    header "BRIDGE Controller Setup"
    echo "The controller manages a portfolio of projects."
    echo "It goes at the root of your project folders."
    echo ""

    local name target_dir
    ask name "Portfolio name" "My Projects"
    ask target_dir "Target directory" "."
    target_dir="$(cd "$target_dir" 2>/dev/null && pwd || echo "$target_dir")"

    if [[ -f "$target_dir/CLAUDE.md" ]]; then
        warn "CLAUDE.md already exists in $target_dir"
        if ! ask_yn "Overwrite BRIDGE controller files?" "n"; then
            echo "Skipped controller installation."; return
        fi
    fi

    mkdir -p "$target_dir"
    resolve_source "bridge-controller" "$target_dir"
    replace_placeholder "$target_dir" "$name"
    info "Controller installed at $target_dir"

    # Register existing projects
    echo ""
    if ask_yn "Register existing projects/folders now?" "y"; then
        while true; do
            echo ""
            local proj_path proj_desc proj_type proj_platform proj_priority
            ask proj_path "Folder path (relative to $target_dir, or 'done')" ""
            [[ "$proj_path" == "done" || -z "$proj_path" ]] && break

            local full_path="$target_dir/$proj_path"
            if [[ ! -d "$full_path" ]]; then
                warn "Directory $full_path does not exist"
                if ! ask_yn "Create it?" "n"; then continue; fi
                mkdir -p "$full_path"
            fi

            ask proj_desc "Description" ""
            ask proj_type "Type (project/repo)" "project"
            local proj_workspace=""
            [[ "$proj_type" == "repo" ]] && ask proj_workspace "Workspace name" ""
            ask proj_platform "Platform (claude-code/codex/opencode/roocode-full/roocode-standalone)" "claude-code"
            ask proj_priority "Priority (high/medium/low)" "medium"

            create_bridgeinclude "$full_path" "$proj_type" "$proj_desc" "$proj_workspace" "$proj_platform" "$proj_priority"
        done
    fi

    echo ""
    info "Controller ready!"
    echo "  Next: cd $target_dir && claude && /bridge-status"
    echo ""
}

install_multi_repo() {
    header "BRIDGE Multi-Repo Workspace Setup"
    echo "The multi-repo orchestrator coordinates cross-repo coding."
    echo ""

    local name platform workspace_dir orch_folder
    ask name "Workspace/product name" ""
    [[ -z "$name" ]] && { echo "Error: Workspace name is required."; return 1; }

    echo ""
    echo "  Platforms:"
    echo "    1) claude-code"
    echo "    2) codex"
    echo ""
    local platform_choice
    ask platform_choice "Platform" "1"
    case "$platform_choice" in
        1|claude-code) platform="claude-code" ;;
        2|codex)       platform="codex" ;;
        *)             echo "Error: Invalid platform."; return 1 ;;
    esac

    ask workspace_dir "Parent directory (folder containing your repos)" "."
    workspace_dir="$(cd "$workspace_dir" 2>/dev/null && pwd || echo "$workspace_dir")"
    ask orch_folder "Orchestrator folder name" "bridge-orchestrator"
    local orch_path="$workspace_dir/$orch_folder"

    if [[ -d "$orch_path" ]]; then
        warn "Directory $orch_path already exists"
        if ! ask_yn "Overwrite?" "n"; then
            echo "Skipped multi-repo installation."; return
        fi
    fi

    mkdir -p "$orch_path"

    # Resolve: local folder (merge) vs tar/remote (pre-merged)
    local pack_name="bridge-multi-repo"
    local multi_repo_dir="${SCRIPT_DIR}/${pack_name}/${platform}"
    local archive="${SCRIPT_DIR}/${pack_name}-${platform}.tar.gz"

    if [[ -d "$multi_repo_dir" ]]; then
        if [[ "$platform" == "claude-code" ]]; then
            local base="${SCRIPT_DIR}/bridge-claude-code"
            if [[ -d "$base" ]]; then
                info "Copying shared infra from bridge-claude-code/"
                cp -r "$base/.claude" "$orch_path/.claude"
                cp -r "$base/docs" "$orch_path/docs"
            else
                warn "bridge-claude-code/ not found"
            fi
        else
            local base="${SCRIPT_DIR}/bridge-codex"
            if [[ -d "$base" ]]; then
                info "Copying shared infra from bridge-codex/"
                cp -r "$base/.agents" "$orch_path/.agents"
                cp -r "$base/.codex" "$orch_path/.codex"
                cp -r "$base/docs" "$orch_path/docs"
            else
                warn "bridge-codex/ not found"
            fi
        fi
        info "Overlaying multi-repo files..."
        cp -r "$multi_repo_dir"/. "$orch_path"/
    elif [[ -f "$archive" ]]; then
        info "Extracting from: ${pack_name}-${platform}.tar.gz"
        tar -xzf "$archive" -C "$orch_path"
    else
        resolve_source "${pack_name}-${platform}" "$orch_path"
    fi

    replace_placeholder "$orch_path" "$name"

    # Collect repo info
    header "Configure Repos"
    echo "Add the repos this workspace manages."
    echo ""

    local repos_json="[" repos_context="[" repo_commands="{" repo_state="["
    local repo_count=0 first=true

    while true; do
        local repo_id repo_path repo_branch repo_owners
        local repo_test repo_lint repo_build

        ask repo_id "Repo ID (short name, or 'done')" ""
        [[ "$repo_id" == "done" || -z "$repo_id" ]] && break

        ask repo_path "Path relative to orchestrator" "../${repo_id}"
        ask repo_branch "Default branch" "main"
        ask repo_owners "Owners (comma-separated)" ""
        echo "  Per-repo commands (leave blank to skip):"
        ask repo_test "  Test command" ""
        ask repo_lint "  Lint command" ""
        ask repo_build "  Build command" ""

        local owners_json="[]"
        if [[ -n "$repo_owners" ]]; then
            owners_json="[$(echo "$repo_owners" | sed 's/[[:space:]]*,[[:space:]]*/", "/g; s/^/"/; s/$/"/' )]"
        fi

        local comma=""
        $first || comma=","
        first=false

        repos_json="${repos_json}${comma}
      { \"repo_id\": \"${repo_id}\", \"path\": \"${repo_path}\", \"default_branch\": \"${repo_branch}\", \"owners\": ${owners_json} }"
        repos_context="${repos_context}${comma} \"${repo_id}\""
        repo_commands="${repo_commands}${comma}
    \"${repo_id}\": {"
        local cmd_first=true
        if [[ -n "$repo_test" ]]; then repo_commands="${repo_commands} \"test\": \"${repo_test}\""; cmd_first=false; fi
        if [[ -n "$repo_lint" ]]; then $cmd_first || repo_commands="${repo_commands},"; repo_commands="${repo_commands} \"lint\": \"${repo_lint}\""; cmd_first=false; fi
        if [[ -n "$repo_build" ]]; then $cmd_first || repo_commands="${repo_commands},"; repo_commands="${repo_commands} \"build\": \"${repo_build}\""; fi
        repo_commands="${repo_commands} }"
        repo_state="${repo_state}${comma}
    { \"repo_id\": \"${repo_id}\", \"branch\": \"${repo_branch}\", \"head_sha\": \"\", \"pr_url\": \"\" }"

        repo_count=$((repo_count + 1))
        info "Added repo: ${repo_id}"
        if ! ask_yn "Add another repo?" "y"; then break; fi
        echo ""
    done

    repos_json="${repos_json} ]"
    repos_context="${repos_context} ]"
    repo_commands="${repo_commands} }"
    repo_state="${repo_state} ]"

    # Cross-repo contracts
    local contracts="[]" integration_tests="[]"
    if [[ $repo_count -gt 0 ]]; then
        echo ""
        header "Cross-Repo Contracts"
        echo "Describe contracts between repos (empty line to finish):"
        local contracts_arr=()
        while true; do
            prompt "  Contract: "
            local contract; read -r contract
            [[ -z "$contract" ]] && break
            contracts_arr+=("$contract")
        done
        if [[ ${#contracts_arr[@]} -gt 0 ]]; then
            contracts="["; local cfirst=true
            for c in "${contracts_arr[@]}"; do
                $cfirst || contracts="${contracts},"
                cfirst=false
                contracts="${contracts} \"${c}\""
            done
            contracts="${contracts} ]"
        fi

        echo ""
        header "Integration Acceptance Tests"
        echo "Describe cross-repo integration tests (empty line to finish):"
        local itests_arr=()
        while true; do
            prompt "  Test: "
            local itest; read -r itest
            [[ -z "$itest" ]] && break
            itests_arr+=("$itest")
        done
        if [[ ${#itests_arr[@]} -gt 0 ]]; then
            integration_tests="["; local ifirst=true
            for t in "${itests_arr[@]}"; do
                $ifirst || integration_tests="${integration_tests},"
                ifirst=false
                integration_tests="${integration_tests} \"${t}\""
            done
            integration_tests="${integration_tests} ]"
        fi
    fi

    # Write requirements.json
    cat > "$orch_path/docs/requirements.json" <<REQEOF
{
  "schema": "bridge.v2",
  "project": { "name": "${name}", "description": "", "type": "", "version": "" },
  "workspace": {
    "topology": "multi-repo",
    "repos": ${repos_json},
    "cross_repo_contracts": ${contracts},
    "integration_acceptance_tests": ${integration_tests}
  },
  "scope": { "in_scope": [], "out_of_scope": [], "non_goals": [] },
  "constraints": { "technical": [], "conventions": [] },
  "features": {},
  "acceptance_tests": {},
  "user_flows": {},
  "risks": {},
  "execution": { "recommended_slices": [], "open_questions": [] }
}
REQEOF

    # Write context.json
    cat > "$orch_path/docs/context.json" <<CTXEOF
{
  "schema": "context.v1",
  "project": { "name": "${name}" },
  "workspace": { "topology": "multi-repo", "repos": ${repos_context} },
  "feature_status": [],
  "handoff": { "stopped_at": "Workspace initialization", "next_immediate": "", "watch_out": [] },
  "slice_history": [],
  "current_slice": null,
  "next_slice": null,
  "repo_commands": ${repo_commands},
  "repo_state": ${repo_state},
  "quality_gates": { "last_run": null, "status": null },
  "recent_decisions": [],
  "blockers": [],
  "discrepancies": []
}
CTXEOF

    info "Updated docs/requirements.json and docs/context.json"

    # .bridgeinclude markers
    if [[ $repo_count -gt 0 ]]; then
        echo ""
        if ask_yn "Create .bridgeinclude markers in repo folders?" "y"; then
            if command -v python3 &>/dev/null; then
                python3 -c "
import json, os
with open('$orch_path/docs/requirements.json') as f:
    data = json.load(f)
for repo in data.get('workspace', {}).get('repos', []):
    rid = repo['repo_id']
    rpath = repo['path']
    abs_path = os.path.normpath(os.path.join('$orch_path', rpath))
    if os.path.isdir(abs_path):
        marker = os.path.join(abs_path, '.bridgeinclude')
        with open(marker, 'w') as mf:
            mf.write(f'type = \"repo\"\ndescription = \"{rid} repo\"\nworkspace = \"${name}\"\nplatform = \"${platform}\"\n')
        print(f'  Created {marker}')
    else:
        print(f'  Skipped {abs_path} (directory not found)')
"
            else
                warn "python3 not found — create .bridgeinclude files manually"
            fi
        fi
    fi

    echo ""
    info "Multi-repo workspace ready!"
    echo "  Orchestrator: $orch_path"
    echo "  Platform:     $platform"
    echo "  Repos:        $repo_count"
    echo ""
    echo "  Next:"
    echo "    cd $orch_path"
    if [[ "$platform" == "claude-code" ]]; then
        echo "    claude && /bridge-repo-status"
    else
        echo "    codex && \$bridge-repo-status"
    fi
    echo ""
}

cmd_orchestrator() {
    header "BRIDGE Orchestrator Installer"
    echo "  1) Controller       — portfolio meta-orchestrator"
    echo "  2) Multi-Repo       — cross-repo coding orchestrator"
    echo "  3) Both"
    echo ""
    local choice
    ask choice "Selection" "3"
    case "$choice" in
        1|controller) install_controller ;;
        2|multi-repo) install_multi_repo ;;
        3|both)       install_controller; install_multi_repo ;;
        *)            echo "Error: Invalid choice."; exit 1 ;;
    esac
}

# ============================================================
# COMMAND: pack — Rebuild tar.gz archives
# ============================================================
cmd_pack() {
    header "Building BRIDGE archives..."

    local packs=("bridge-full" "bridge-standalone" "bridge-claude-code" "bridge-codex" "bridge-opencode" "bridge-controller")
    for p in "${packs[@]}"; do
        if [[ -d "${SCRIPT_DIR}/${p}" ]]; then
            tar -czf "${SCRIPT_DIR}/${p}.tar.gz" -C "${SCRIPT_DIR}/${p}" .
            info "${p}.tar.gz ($(wc -c < "${SCRIPT_DIR}/${p}.tar.gz") bytes)"
        else
            echo "  Skipping $p (folder not found)"
        fi
    done

    # Multi-repo: merge base + overlay
    local multi_dir="${SCRIPT_DIR}/bridge-multi-repo"
    if [[ -d "$multi_dir" ]]; then
        for platform in claude-code codex; do
            [[ ! -d "$multi_dir/$platform" ]] && continue
            local base_pack="bridge-claude-code"
            [[ "$platform" == "codex" ]] && base_pack="bridge-codex"
            local base_dir="${SCRIPT_DIR}/${base_pack}"
            [[ ! -d "$base_dir" ]] && { echo "  Skipping multi-repo-$platform (base not found)"; continue; }

            local tmp
            tmp="$(mktemp -d)"
            cp -a "$base_dir"/. "$tmp"/
            cp -a "$multi_dir/$platform"/. "$tmp"/
            tar -czf "${SCRIPT_DIR}/bridge-multi-repo-${platform}.tar.gz" -C "$tmp" .
            rm -rf "$tmp"
            info "bridge-multi-repo-${platform}.tar.gz"
        done
    fi

    # Dual-agent
    if [[ -d "${SCRIPT_DIR}/bridge-dual-agent" ]]; then
        tar -czf "${SCRIPT_DIR}/bridge-dual-agent.tar.gz" -C "${SCRIPT_DIR}/bridge-dual-agent" .
        info "bridge-dual-agent.tar.gz"
    fi

    echo ""
    info "Done. Archives ready for GitHub Release or local setup."
}

# ============================================================
# MAIN — route subcommand or show interactive menu
# ============================================================
main() {
    local subcmd="${1:-}"

    case "$subcmd" in
        new)          shift; cmd_new "$@" ;;
        add)          shift; cmd_add "$@" ;;
        orchestrator) shift; cmd_orchestrator "$@" ;;
        pack)         shift; cmd_pack "$@" ;;
        -h|--help|help)
            echo "Usage: $(basename "$0") <command> [OPTIONS]"
            echo ""
            echo "BRIDGE — unified shell installer"
            echo ""
            echo "Commands:"
            echo "  new            Create a new project"
            echo "  add            Add BRIDGE to an existing project"
            echo "  orchestrator   Install controller or multi-repo orchestrator"
            echo "  pack           Rebuild tar.gz archives"
            echo ""
            echo "Run without arguments for an interactive menu."
            echo ""
            echo "Environment variables:"
            echo "  BRIDGE_REPO      GitHub repo (default: etapsc/bridge)"
            echo "  BRIDGE_VERSION   Release tag (default: latest)"
            exit 0 ;;
        "")
            header "BRIDGE Shell Installer"
            echo "  1) New project"
            echo "  2) Add to existing project"
            echo "  3) Install orchestrator"
            echo "  4) Pack archives (maintainer)"
            echo ""
            local action
            ask action "What would you like to do?" "1"
            case "$action" in
                1|new)          cmd_new ;;
                2|add)          cmd_add ;;
                3|orchestrator) cmd_orchestrator ;;
                4|pack)         cmd_pack ;;
                *)              echo "Error: Invalid choice."; exit 1 ;;
            esac ;;
        *)
            echo "Unknown command: $subcmd"
            echo "Run '$(basename "$0") --help' for usage."
            exit 1 ;;
    esac
}

main "$@"

#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# BRIDGE v2.1 - Controller & Multi-Repo Installer
#
# Installs:
#   1) BRIDGE Controller  — portfolio meta-orchestrator at project root
#   2) BRIDGE Multi-Repo  — cross-repo coding orchestrator for a workspace
#
# Source resolution (auto-detected):
#   1. Local folder:  ./bridge-{pack}/ exists → copy contents
#   2. Local tar:     ./bridge-{pack}.tar.gz exists → extract
#   3. Remote:        download tar from GitHub Releases
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_REPO="${BRIDGE_REPO:-etapsc/bridge-v2}"
VERSION="${BRIDGE_VERSION:-latest}"

# --- Colors (if terminal supports them) ---
if [[ -t 1 ]]; then
    BOLD="\033[1m"
    DIM="\033[2m"
    GREEN="\033[32m"
    CYAN="\033[36m"
    YELLOW="\033[33m"
    RESET="\033[0m"
else
    BOLD="" DIM="" GREEN="" CYAN="" YELLOW="" RESET=""
fi

# --- Helpers ---
info()    { echo -e "${GREEN}>${RESET} $*"; }
prompt()  { echo -en "${CYAN}?${RESET} $*"; }
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

# --- Source resolution ---
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
            echo "Error: Failed to download from $url"
            rm -f "$tmpfile"
            exit 1
        fi
        tar -xzf "$tmpfile" -C "$target_dir"
        rm -f "$tmpfile"
    fi
}

# --- Replace {{PROJECT_NAME}} placeholder ---
replace_placeholder() {
    local dir="$1" name="$2"
    find "$dir" -type f \( -name "*.md" -o -name "*.json" -o -name "*.toml" \) | while read -r file; do
        if grep -q '{{PROJECT_NAME}}' "$file" 2>/dev/null; then
            if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' "s/{{PROJECT_NAME}}/${name//\//\\/}/g" "$file"
            else
                sed -i "s/{{PROJECT_NAME}}/${name//\//\\/}/g" "$file"
            fi
        fi
    done
}

# --- Create .bridgeinclude marker ---
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

# ============================================================
# CONTROLLER INSTALLATION
# ============================================================
install_controller() {
    header "BRIDGE Controller Setup"
    echo "The controller manages a portfolio of projects."
    echo "It goes at the root of your project folders."
    echo ""

    local name target_dir
    ask name "Portfolio name" "My Projects"
    ask target_dir "Target directory (where your projects live)" "."

    # Resolve to absolute
    target_dir="$(cd "$target_dir" 2>/dev/null && pwd || echo "$target_dir")"

    if [[ -f "$target_dir/CLAUDE.md" ]]; then
        warn "CLAUDE.md already exists in $target_dir"
        if ! ask_yn "Overwrite BRIDGE controller files?" "n"; then
            echo "Skipped controller installation."
            return
        fi
    fi

    mkdir -p "$target_dir"

    # Extract pack
    resolve_source "bridge-controller" "$target_dir"

    # Replace placeholder
    replace_placeholder "$target_dir" "$name"

    info "Controller installed at $target_dir"

    # Register existing projects
    echo ""
    if ask_yn "Register existing projects/folders now?" "y"; then
        while true; do
            echo ""
            local proj_path proj_desc proj_type proj_platform proj_priority

            ask proj_path "Folder path (relative to $target_dir, or 'done' to finish)" ""
            [[ "$proj_path" == "done" || -z "$proj_path" ]] && break

            local full_path="$target_dir/$proj_path"
            if [[ ! -d "$full_path" ]]; then
                warn "Directory $full_path does not exist"
                if ! ask_yn "Create it?" "n"; then
                    continue
                fi
                mkdir -p "$full_path"
            fi

            ask proj_desc "Description" ""
            ask proj_type "Type (project/repo)" "project"

            local proj_workspace=""
            if [[ "$proj_type" == "repo" ]]; then
                ask proj_workspace "Workspace name (groups repos together)" ""
            fi

            ask proj_platform "Platform (claude-code/codex/opencode/roocode-full/roocode-standalone)" "claude-code"
            ask proj_priority "Priority (high/medium/low)" "medium"

            create_bridgeinclude "$full_path" "$proj_type" "$proj_desc" "$proj_workspace" "$proj_platform" "$proj_priority"
        done
    fi

    echo ""
    info "Controller ready!"
    echo ""
    echo "  Next steps:"
    echo "    cd $target_dir"
    echo "    claude"
    echo "    /bridge-status"
    echo ""
}

# ============================================================
# MULTI-REPO INSTALLATION
# ============================================================
install_multi_repo() {
    header "BRIDGE Multi-Repo Workspace Setup"
    echo "The multi-repo orchestrator coordinates cross-repo coding."
    echo "It lives alongside the repos it manages."
    echo ""

    local name platform workspace_dir orch_folder

    ask name "Workspace/product name" ""
    if [[ -z "$name" ]]; then
        echo "Error: Workspace name is required."
        return 1
    fi

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
            echo "Skipped multi-repo installation."
            return
        fi
    fi

    mkdir -p "$orch_path"

    # Resolve the right variant
    # For local folder installs: merge shared infra from base pack + multi-repo overlay
    # For tar/remote installs: archive is already pre-merged by package.sh
    local pack_name="bridge-multi-repo"
    local subfolder="$platform"
    local multi_repo_dir="${SCRIPT_DIR}/${pack_name}/${subfolder}"
    local archive="${SCRIPT_DIR}/${pack_name}-${platform}.tar.gz"

    if [[ -d "$multi_repo_dir" ]]; then
        # Local folder: merge shared infra from base pack + multi-repo overlay
        if [[ "$platform" == "claude-code" ]]; then
            local base="${SCRIPT_DIR}/bridge-claude-code"
            if [[ -d "$base" ]]; then
                info "Copying shared infra from bridge-claude-code/"
                cp -r "$base/.claude" "$orch_path/.claude"
                cp -r "$base/docs" "$orch_path/docs"
            else
                warn "bridge-claude-code/ not found — shared infra will be missing"
            fi
        else
            local base="${SCRIPT_DIR}/bridge-codex"
            if [[ -d "$base" ]]; then
                info "Copying shared infra from bridge-codex/"
                cp -r "$base/.agents" "$orch_path/.agents"
                cp -r "$base/.codex" "$orch_path/.codex"
                cp -r "$base/docs" "$orch_path/docs"
            else
                warn "bridge-codex/ not found — shared infra will be missing"
            fi
        fi
        info "Overlaying multi-repo files from ${pack_name}/${subfolder}/"
        cp -r "$multi_repo_dir"/. "$orch_path"/
    elif [[ -f "$archive" ]]; then
        info "Extracting from: ${pack_name}-${platform}.tar.gz"
        tar -xzf "$archive" -C "$orch_path"
    else
        resolve_source "${pack_name}-${platform}" "$orch_path"
    fi

    # Replace placeholder
    replace_placeholder "$orch_path" "$name"

    # --- Collect repo info ---
    header "Configure Repos"
    echo "Add the repos this workspace manages."
    echo ""

    local repos_json="["
    local repos_context="["
    local repo_commands="{"
    local repo_state="["
    local repo_list=""
    local repo_count=0
    local first=true

    while true; do
        local repo_id repo_path repo_branch repo_owners
        local repo_test repo_lint repo_build

        ask repo_id "Repo ID (short name, or 'done' to finish)" ""
        [[ "$repo_id" == "done" || -z "$repo_id" ]] && break

        ask repo_path "Path relative to orchestrator" "../${repo_id}"
        ask repo_branch "Default branch" "main"
        ask repo_owners "Owners (comma-separated)" ""

        echo ""
        echo "  Per-repo commands (leave blank to skip):"
        ask repo_test "  Test command" ""
        ask repo_lint "  Lint command" ""
        ask repo_build "  Build command" ""

        # Build JSON fragments
        local owners_json="[]"
        if [[ -n "$repo_owners" ]]; then
            owners_json="[$(echo "$repo_owners" | sed 's/[[:space:]]*,[[:space:]]*/", "/g; s/^/"/; s/$/"/' )]"
        fi

        local comma=""
        $first || comma=","
        first=false

        repos_json="${repos_json}${comma}
      {
        \"repo_id\": \"${repo_id}\",
        \"path\": \"${repo_path}\",
        \"default_branch\": \"${repo_branch}\",
        \"owners\": ${owners_json}
      }"

        repos_context="${repos_context}${comma} \"${repo_id}\""

        repo_commands="${repo_commands}${comma}
    \"${repo_id}\": {"
        local cmd_first=true
        if [[ -n "$repo_test" ]]; then
            repo_commands="${repo_commands} \"test\": \"${repo_test}\""
            cmd_first=false
        fi
        if [[ -n "$repo_lint" ]]; then
            $cmd_first || repo_commands="${repo_commands},"
            repo_commands="${repo_commands} \"lint\": \"${repo_lint}\""
            cmd_first=false
        fi
        if [[ -n "$repo_build" ]]; then
            $cmd_first || repo_commands="${repo_commands},"
            repo_commands="${repo_commands} \"build\": \"${repo_build}\""
        fi
        repo_commands="${repo_commands} }"

        repo_state="${repo_state}${comma}
    { \"repo_id\": \"${repo_id}\", \"branch\": \"${repo_branch}\", \"head_sha\": \"\", \"pr_url\": \"\" }"

        repo_list="${repo_list}  - ${repo_id} (${repo_path})\n"
        repo_count=$((repo_count + 1))

        echo ""
        info "Added repo: ${repo_id}"

        if ! ask_yn "Add another repo?" "y"; then
            break
        fi
        echo ""
    done

    repos_json="${repos_json}
    ]"
    repos_context="${repos_context} ]"
    repo_commands="${repo_commands}
  }"
    repo_state="${repo_state}
  ]"

    # --- Cross-repo contracts ---
    local contracts="[]"
    local integration_tests="[]"

    if [[ $repo_count -gt 0 ]]; then
        echo ""
        header "Cross-Repo Contracts"
        echo "Describe contracts between repos (one per line, empty to finish):"
        local contracts_arr=()
        while true; do
            prompt "  Contract: "
            local contract
            read -r contract
            [[ -z "$contract" ]] && break
            contracts_arr+=("$contract")
        done

        if [[ ${#contracts_arr[@]} -gt 0 ]]; then
            contracts="["
            local cfirst=true
            for c in "${contracts_arr[@]}"; do
                $cfirst || contracts="${contracts},"
                cfirst=false
                contracts="${contracts}
      \"${c}\""
            done
            contracts="${contracts}
    ]"
        fi

        echo ""
        header "Integration Acceptance Tests"
        echo "Describe cross-repo integration tests (one per line, empty to finish):"
        local itests_arr=()
        while true; do
            prompt "  Test: "
            local itest
            read -r itest
            [[ -z "$itest" ]] && break
            itests_arr+=("$itest")
        done

        if [[ ${#itests_arr[@]} -gt 0 ]]; then
            integration_tests="["
            local ifirst=true
            for t in "${itests_arr[@]}"; do
                $ifirst || integration_tests="${integration_tests},"
                ifirst=false
                integration_tests="${integration_tests}
      \"${t}\""
            done
            integration_tests="${integration_tests}
    ]"
        fi
    fi

    # --- Write requirements.json ---
    cat > "$orch_path/docs/requirements.json" <<REQEOF
{
  "schema": "bridge.v2",
  "project": {
    "name": "${name}",
    "description": "",
    "type": "",
    "version": ""
  },
  "workspace": {
    "topology": "multi-repo",
    "repos": ${repos_json},
    "cross_repo_contracts": ${contracts},
    "integration_acceptance_tests": ${integration_tests}
  },
  "scope": {
    "in_scope": [],
    "out_of_scope": [],
    "non_goals": []
  },
  "constraints": {
    "technical": [],
    "conventions": []
  },
  "features": {},
  "acceptance_tests": {},
  "user_flows": {},
  "risks": {},
  "execution": {
    "recommended_slices": [],
    "open_questions": []
  }
}
REQEOF

    # --- Write context.json ---
    cat > "$orch_path/docs/context.json" <<CTXEOF
{
  "schema": "context.v1",
  "project": {
    "name": "${name}"
  },
  "workspace": {
    "topology": "multi-repo",
    "repos": ${repos_context}
  },
  "feature_status": [],
  "handoff": {
    "stopped_at": "Workspace initialization",
    "next_immediate": "",
    "watch_out": []
  },
  "slice_history": [],
  "current_slice": null,
  "next_slice": null,
  "repo_commands": ${repo_commands},
  "repo_state": ${repo_state},
  "quality_gates": {
    "last_run": null,
    "status": null
  },
  "recent_decisions": [],
  "blockers": [],
  "discrepancies": []
}
CTXEOF

    info "Updated docs/requirements.json and docs/context.json"

    # --- Optionally create .bridgeinclude markers in repo folders ---
    if [[ $repo_count -gt 0 ]]; then
        echo ""
        if ask_yn "Create .bridgeinclude markers in repo folders?" "y"; then
            # Re-parse repos from requirements.json using simple extraction
            # We stored repo info during collection, so use repo_id/path pairs
            # Re-read from the generated file
            local req_file="$orch_path/docs/requirements.json"
            if command -v python3 &>/dev/null; then
                python3 -c "
import json, os, sys
with open('$req_file') as f:
    data = json.load(f)
for repo in data.get('workspace', {}).get('repos', []):
    rid = repo['repo_id']
    rpath = repo['path']
    # Resolve relative to orchestrator
    abs_path = os.path.normpath(os.path.join('$orch_path', rpath))
    if os.path.isdir(abs_path):
        marker = os.path.join(abs_path, '.bridgeinclude')
        with open(marker, 'w') as mf:
            mf.write(f'type = \"repo\"\n')
            mf.write(f'description = \"{rid} repo\"\n')
            mf.write(f'workspace = \"${name}\"\n')
            mf.write(f'platform = \"${platform}\"\n')
        print(f'  Created {marker}')
    else:
        print(f'  Skipped {abs_path} (directory not found)')
"
            else
                warn "python3 not found — create .bridgeinclude files manually in each repo"
            fi
        fi
    fi

    # --- Summary ---
    echo ""
    info "Multi-repo workspace ready!"
    echo ""
    echo "  Orchestrator: $orch_path"
    echo "  Platform:     $platform"
    echo "  Repos:        $repo_count"
    echo ""
    echo "  Next steps:"
    echo "    cd $orch_path"
    if [[ "$platform" == "claude-code" ]]; then
        echo "    claude"
        echo "    /bridge-repo-status    # verify repos are found"
        echo "    /bridge-scope          # scope a cross-repo feature"
    else
        echo "    codex"
        echo "    \$bridge-repo-status    # verify repos are found"
        echo "    \$bridge-scope          # scope a cross-repo feature"
    fi
    echo ""
}

# ============================================================
# MAIN
# ============================================================
header "BRIDGE v2.1 Installer"
echo "What would you like to install?"
echo ""
echo "  1) BRIDGE Controller       — portfolio meta-orchestrator (manages all projects)"
echo "  2) BRIDGE Multi-Repo       — cross-repo coding orchestrator (manages one workspace)"
echo "  3) Both"
echo ""

ask choice "Selection" "3"

case "$choice" in
    1|controller)
        install_controller
        ;;
    2|multi-repo)
        install_multi_repo
        ;;
    3|both)
        install_controller
        install_multi_repo
        ;;
    *)
        echo "Error: Invalid choice."
        exit 1
        ;;
esac

echo ""
info "Installation complete."

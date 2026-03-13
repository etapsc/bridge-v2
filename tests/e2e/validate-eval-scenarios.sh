#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

EVAL_ROOT="/tmp/bridge-eval"
LIVE_ROOT="/tmp/bridge-live"
PKG_TEST_ROOT="/tmp/bridge-pkg-test"
INTERACTIVE_PROJECT="${BRIDGE_ROOT}/interactive-test"
LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/bridge-eval-validator.XXXXXX")"

SKIP_INTERACTIVE=0
SKIP_LIVE=0
KEEP_ARTIFACTS=0
LIVE_PLATFORM="${BRIDGE_LIVE_PLATFORM:-auto}"

PASSED=0
FAILED=0
SKIPPED=0
FAILURES=()
SKIPS=()

COMMANDS=(
  bridge-advisor bridge-brainstorm bridge-context-create bridge-context-update
  bridge-design bridge-end bridge-eval bridge-feature bridge-feedback
  bridge-gate bridge-requirements-only bridge-requirements bridge-resume
  bridge-scope bridge-start
)

EXPECTED_ARCHIVES=(
  bridge-full
  bridge-standalone
  bridge-claude-code
  bridge-codex
  bridge-opencode
  bridge-controller
  bridge-multi-repo-claude-code
  bridge-multi-repo-codex
  bridge-dual-agent
)

cleanup() {
  rm -rf "${LOG_DIR}"
  if [[ "${KEEP_ARTIFACTS}" -eq 0 && "${FAILED}" -eq 0 ]]; then
    rm -rf "${EVAL_ROOT}" "${LIVE_ROOT}" "${PKG_TEST_ROOT}" "${INTERACTIVE_PROJECT}"
  fi
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: bash tests/e2e/validate-eval-scenarios.sh [options]

Runs the evaluation scenarios from docs/gates-evals/eval-scenarios.md.

Options:
  --skip-interactive       Skip Scenario 6 and Scenario 7 interactive setup.sh runs
  --skip-live              Skip Scenario 23 live platform validation
  --live-platform NAME     auto (default), claude, codex, opencode
  --keep-artifacts         Keep /tmp/bridge-eval, /tmp/bridge-live, /tmp/bridge-pkg-test
  -h, --help               Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-interactive) SKIP_INTERACTIVE=1; shift ;;
    --skip-live) SKIP_LIVE=1; shift ;;
    --live-platform)
      LIVE_PLATFORM="${2:-}"
      shift 2
      ;;
    --keep-artifacts) KEEP_ARTIFACTS=1; shift ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "${LIVE_PLATFORM}" != "auto" && "${LIVE_PLATFORM}" != "claude" && "${LIVE_PLATFORM}" != "codex" && "${LIVE_PLATFORM}" != "opencode" ]]; then
  echo "Error: --live-platform must be one of: auto, claude, codex, opencode" >&2
  exit 1
fi

cd "${BRIDGE_ROOT}"

pass() {
  PASSED=$((PASSED + 1))
  printf "  \033[32m+\033[0m %s\n" "$1"
}

fail() {
  FAILED=$((FAILED + 1))
  FAILURES+=("$1")
  printf "  \033[31m-\033[0m %s\n" "$1"
}

skip() {
  SKIPPED=$((SKIPPED + 1))
  SKIPS+=("$1")
  printf "  \033[33m~\033[0m %s\n" "$1"
}

note() {
  printf "  %s\n" "$1"
}

section() {
  printf "\n\033[1m=== %s ===\033[0m\n" "$1"
}

run_logged() {
  local log="$1"
  shift

  : > "${log}"
  "$@" 2>&1 | tee "${log}"
  return "${PIPESTATUS[0]}"
}

strip_ansi() {
  sed -E $'s/\x1B\\[[0-9;]*[[:alpha:]]//g' "$1"
}

extract_summary_value() {
  local log="$1"
  local key="$2"
  strip_ansi "${log}" | awk -F': *' -v key="${key}" '$1 ~ key {print $2; exit}'
}

count_files() {
  local dir="$1"
  local pattern="$2"
  find "${dir}" -mindepth 1 -maxdepth 1 -type f -name "${pattern}" | wc -l | tr -d '[:space:]'
}

count_dirs() {
  local dir="$1"
  find "${dir}" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d '[:space:]'
}

compare_lists() {
  local lhs="$1"
  local rhs="$2"
  [[ "${lhs}" == "${rhs}" ]]
}

toml_valid() {
  local file="$1"
  python3 - "$file" <<'PY' >/dev/null 2>&1
import sys, tomllib
with open(sys.argv[1], "rb") as handle:
    tomllib.load(handle)
PY
}

tty_available() {
  [[ -t 0 && -t 1 ]]
}

prompt_continue() {
  local message="$1"
  read -r -p "${message}" < /dev/tty
}

prompt_yes_no() {
  local prompt="$1"
  local response
  read -r -p "${prompt} [y/N]: " response < /dev/tty
  [[ "${response,,}" == "y" ]]
}

detect_live_platform() {
  if [[ "${LIVE_PLATFORM}" != "auto" ]]; then
    printf "%s\n" "${LIVE_PLATFORM}"
    return 0
  fi

  if command -v claude >/dev/null 2>&1; then
    printf "claude\n"
    return 0
  fi

  if command -v codex >/dev/null 2>&1; then
    printf "codex\n"
    return 0
  fi

  if command -v opencode >/dev/null 2>&1; then
    printf "opencode\n"
    return 0
  fi

  printf "none\n"
}

check_readme_pack_mentions() {
  local missing=0
  local pack
  for pack in full standalone claude-code codex opencode; do
    if grep -qi "${pack}" README.md; then
      :
    else
      missing=$((missing + 1))
    fi
  done

  [[ "${missing}" -eq 0 ]]
}

reset_artifacts() {
  rm -rf "${EVAL_ROOT}" "${LIVE_ROOT}" "${PKG_TEST_ROOT}" "${INTERACTIVE_PROJECT}"
  mkdir -p "${EVAL_ROOT}"
}

reset_artifacts

section "Scenario 1: Setup Script -- Full Pack"
SC01_LOG="${LOG_DIR}/scenario01.log"
if run_logged "${SC01_LOG}" bash ./setup.sh --name "Eval Full" --pack full -o "${EVAL_ROOT}"; then
  pass "setup.sh creates /tmp/bridge-eval/eval-full"
else
  fail "setup.sh --pack full exited non-zero"
fi

SC01_PROJECT="${EVAL_ROOT}/eval-full"
[[ -d "${SC01_PROJECT}" ]] && pass "eval-full project directory exists" || fail "eval-full project directory missing"

SC01_COMMANDS="$(count_files "${SC01_PROJECT}/.roo/commands" '*.md')"
[[ "${SC01_COMMANDS}" == "15" ]] && pass "Full pack has 15 command files" || fail "Full pack expected 15 command files, got ${SC01_COMMANDS}"

SC01_SKILLS="$(count_dirs "${SC01_PROJECT}/.roo/skills")"
[[ "${SC01_SKILLS}" == "6" ]] && pass "Full pack has 6 skill directories" || fail "Full pack expected 6 skill directories, got ${SC01_SKILLS}"

if grep -R -n '{{PROJECT_NAME}}' "${SC01_PROJECT}" >/dev/null 2>&1; then
  fail "Full pack still contains {{PROJECT_NAME}} placeholders"
else
  pass "Full pack placeholders are fully replaced"
fi

if grep -q 'Eval Full' "${SC01_PROJECT}/docs/requirements.json"; then
  pass "Full pack requirements.json contains the project name"
else
  fail "Full pack requirements.json is missing the project name"
fi

SC01_DOCS_MISSING=0
for doc in context.json decisions.md human-playbook.md requirements.json; do
  [[ -f "${SC01_PROJECT}/docs/${doc}" ]] || SC01_DOCS_MISSING=$((SC01_DOCS_MISSING + 1))
done
[[ "${SC01_DOCS_MISSING}" == "0" ]] && pass "Full pack docs templates are present" || fail "Full pack is missing ${SC01_DOCS_MISSING} docs template files"

if [[ -f "${SC01_PROJECT}/.roomodes" ]] && grep -q 'customModes:' "${SC01_PROJECT}/.roomodes"; then
  pass ".roomodes exists with YAML mode definitions"
else
  fail ".roomodes missing or does not look like a RooCode YAML config"
fi

section "Scenario 2: Setup Script -- Claude Code Pack"
SC02_LOG="${LOG_DIR}/scenario02.log"
if run_logged "${SC02_LOG}" bash ./setup.sh --name "Eval Claude" --pack claude-code -o "${EVAL_ROOT}"; then
  pass "setup.sh creates /tmp/bridge-eval/eval-claude"
else
  fail "setup.sh --pack claude-code exited non-zero"
fi

SC02_PROJECT="${EVAL_ROOT}/eval-claude"
if [[ -f "${SC02_PROJECT}/CLAUDE.md" ]] && grep -q 'Eval Claude' "${SC02_PROJECT}/CLAUDE.md"; then
  pass "Claude Code pack has CLAUDE.md with the project name"
else
  fail "Claude Code pack CLAUDE.md missing or not personalized"
fi

SC02_COMMANDS="$(count_files "${SC02_PROJECT}/.claude/commands" '*.md')"
[[ "${SC02_COMMANDS}" == "15" ]] && pass "Claude Code pack has 15 command files" || fail "Claude Code pack expected 15 command files, got ${SC02_COMMANDS}"

SC02_AGENTS="$(count_files "${SC02_PROJECT}/.claude/agents" '*.md')"
[[ "${SC02_AGENTS}" == "5" ]] && pass "Claude Code pack has 5 agent files" || fail "Claude Code pack expected 5 agent files, got ${SC02_AGENTS}"

SC02_SKILLS="$(count_dirs "${SC02_PROJECT}/.claude/skills")"
[[ "${SC02_SKILLS}" == "6" ]] && pass "Claude Code pack has 6 skill directories" || fail "Claude Code pack expected 6 skill directories, got ${SC02_SKILLS}"

if grep -R -n '{{PROJECT_NAME}}' "${SC02_PROJECT}" >/dev/null 2>&1; then
  fail "Claude Code pack still contains {{PROJECT_NAME}} placeholders"
else
  pass "Claude Code pack placeholders are fully replaced"
fi

section "Scenario 3: Setup Script -- Codex Pack"
SC03_LOG="${LOG_DIR}/scenario03.log"
if run_logged "${SC03_LOG}" bash ./setup.sh --name "Eval Codex" --pack codex -o "${EVAL_ROOT}"; then
  pass "setup.sh creates /tmp/bridge-eval/eval-codex"
else
  fail "setup.sh --pack codex exited non-zero"
fi

SC03_PROJECT="${EVAL_ROOT}/eval-codex"
if [[ -f "${SC03_PROJECT}/AGENTS.md" ]] && grep -q 'Eval Codex' "${SC03_PROJECT}/AGENTS.md"; then
  pass "Codex pack has AGENTS.md with the project name"
else
  fail "Codex pack AGENTS.md missing or not personalized"
fi

SC03_SKILLS="$(count_dirs "${SC03_PROJECT}/.agents/skills")"
[[ "${SC03_SKILLS}" == "15" ]] && pass "Codex pack has 15 workflow skill directories" || fail "Codex pack expected 15 workflow skill directories, got ${SC03_SKILLS}"

SC03_PROCS="$(count_files "${SC03_PROJECT}/.agents/procedures" '*.md')"
[[ "${SC03_PROCS}" == "6" ]] && pass "Codex pack has 6 procedure files" || fail "Codex pack expected 6 procedure files, got ${SC03_PROCS}"

if [[ -f "${SC03_PROJECT}/.codex/config.toml" ]] && toml_valid "${SC03_PROJECT}/.codex/config.toml"; then
  pass "Codex config.toml exists and parses as TOML"
else
  fail "Codex config.toml missing or invalid"
fi

if grep -R -n '{{PROJECT_NAME}}' "${SC03_PROJECT}" >/dev/null 2>&1; then
  fail "Codex pack still contains {{PROJECT_NAME}} placeholders"
else
  pass "Codex pack placeholders are fully replaced"
fi

section "Scenario 4: Setup Script -- Standalone Pack"
SC04_LOG="${LOG_DIR}/scenario04.log"
if run_logged "${SC04_LOG}" bash ./setup.sh --name "Eval Standalone" --pack standalone -o "${EVAL_ROOT}"; then
  pass "setup.sh creates /tmp/bridge-eval/eval-standalone"
else
  fail "setup.sh --pack standalone exited non-zero"
fi

SC04_PROJECT="${EVAL_ROOT}/eval-standalone"
if [[ -f "${SC04_PROJECT}/.roo/commands/bridge-start.md" ]]; then
  SC04_LINES="$(wc -l < "${SC04_PROJECT}/.roo/commands/bridge-start.md" | tr -d '[:space:]')"
  if [[ "${SC04_LINES}" -gt 50 ]]; then
    pass "Standalone bridge-start.md is self-contained (${SC04_LINES} lines)"
  else
    fail "Standalone bridge-start.md is unexpectedly short (${SC04_LINES} lines)"
  fi
else
  fail "Standalone bridge-start.md missing"
fi

if [[ -d "${SC04_PROJECT}/.roo/skills" ]]; then
  fail "Standalone pack should not create .roo/skills"
else
  pass "Standalone pack does not create .roo/skills"
fi

SC04_COMMANDS="$(count_files "${SC04_PROJECT}/.roo/commands" '*.md')"
[[ "${SC04_COMMANDS}" == "15" ]] && pass "Standalone pack has 15 command files" || fail "Standalone pack expected 15 command files, got ${SC04_COMMANDS}"

section "Scenario 5: Setup Script -- OpenCode Pack"
SC05_LOG="${LOG_DIR}/scenario05.log"
if run_logged "${SC05_LOG}" bash ./setup.sh --name "Eval OpenCode" --pack opencode -o "${EVAL_ROOT}"; then
  pass "setup.sh creates /tmp/bridge-eval/eval-opencode"
else
  fail "setup.sh --pack opencode exited non-zero"
fi

SC05_PROJECT="${EVAL_ROOT}/eval-opencode"
if [[ -f "${SC05_PROJECT}/AGENTS.md" ]] && grep -q 'Eval OpenCode' "${SC05_PROJECT}/AGENTS.md"; then
  pass "OpenCode pack has AGENTS.md with the project name"
else
  fail "OpenCode pack AGENTS.md missing or not personalized"
fi

SC05_COMMANDS="$(count_files "${SC05_PROJECT}/.opencode/commands" '*.md')"
[[ "${SC05_COMMANDS}" == "15" ]] && pass "OpenCode pack has 15 command files" || fail "OpenCode pack expected 15 command files, got ${SC05_COMMANDS}"

SC05_SKILLS="$(count_dirs "${SC05_PROJECT}/.opencode/skills")"
[[ "${SC05_SKILLS}" == "6" ]] && pass "OpenCode pack has 6 skill directories" || fail "OpenCode pack expected 6 skill directories, got ${SC05_SKILLS}"

SC05_AGENTS="$(count_files "${SC05_PROJECT}/.opencode/agents" '*.md')"
[[ "${SC05_AGENTS}" == "5" ]] && pass "OpenCode pack has 5 agent files" || fail "OpenCode pack expected 5 agent files, got ${SC05_AGENTS}"

if grep -R -n '{{PROJECT_NAME}}' "${SC05_PROJECT}" >/dev/null 2>&1; then
  fail "OpenCode pack still contains {{PROJECT_NAME}} placeholders"
else
  pass "OpenCode pack placeholders are fully replaced"
fi

section "Scenario 6: Setup Script -- Interactive Mode"
if [[ "${SKIP_INTERACTIVE}" -eq 1 ]]; then
  skip "Scenario 6 skipped by --skip-interactive"
elif ! tty_available; then
  skip "Scenario 6 requires a real TTY"
else
  SC06_LOG="${LOG_DIR}/scenario06.log"
  note "Answer these prompts before the interactive run starts:"
  note "  Select pack [1]: 3"
  note "  Project name: Interactive Test"
  note "  Output directory [.]: press Enter"
  prompt_continue "Press Enter to launch Scenario 6 interactive setup.sh..."
  if run_logged "${SC06_LOG}" bash ./setup.sh; then
    pass "Interactive setup.sh run exits successfully"
  else
    fail "Interactive setup.sh run exited non-zero"
  fi

  if grep -q 'Select pack \[1\]:' "${SC06_LOG}" && grep -q 'Project name:' "${SC06_LOG}" && grep -q 'Output directory \[\.\]:' "${SC06_LOG}"; then
    pass "Interactive prompts were displayed"
  else
    fail "Interactive prompts were not all visible in the transcript"
  fi

  if [[ -f "${INTERACTIVE_PROJECT}/CLAUDE.md" ]]; then
    pass "Interactive run created ./interactive-test/CLAUDE.md"
  else
    fail "Interactive run did not create ./interactive-test/CLAUDE.md"
  fi

  rm -rf "${INTERACTIVE_PROJECT}"
  [[ ! -e "${INTERACTIVE_PROJECT}" ]] && pass "Interactive test project cleaned up" || fail "Interactive test project cleanup failed"
fi

section "Scenario 7: Setup Script -- Error Handling"
SC07A_LOG="${LOG_DIR}/scenario07-invalid-pack.log"
if run_logged "${SC07A_LOG}" bash ./setup.sh --pack invalid-pack --name Test -o "${EVAL_ROOT}"; then
  fail "Invalid pack run should fail but exited 0"
else
  pass "Invalid pack run exits non-zero"
fi

if grep -q "Pack must be 'full', 'standalone', 'claude-code', 'codex', or 'opencode'" "${SC07A_LOG}"; then
  pass "Invalid pack run prints a clear error"
else
  fail "Invalid pack run did not print the expected validation error"
fi

if [[ "${SKIP_INTERACTIVE}" -eq 1 ]]; then
  skip "Scenario 7 overwrite prompt skipped by --skip-interactive"
elif ! tty_available; then
  skip "Scenario 7 overwrite prompt requires a real TTY"
else
  SC07B_LOG="${LOG_DIR}/scenario07-overwrite.log"
  note "Answer this prompt before the overwrite check starts:"
  note "  Overwrite BRIDGE files? (y/N): N"
  prompt_continue "Press Enter to launch Scenario 7 overwrite prompt..."
  if run_logged "${SC07B_LOG}" bash ./setup.sh --pack full --name "Eval Full" -o "${EVAL_ROOT}"; then
    fail "Overwrite-decline run should exit non-zero after aborting"
  else
    pass "Overwrite-decline run exits non-zero after abort"
  fi

  if grep -q 'Overwrite BRIDGE files? (y/N):' "${SC07B_LOG}" && grep -q 'Aborted\.' "${SC07B_LOG}"; then
    pass "Overwrite prompt appears and declining prints Aborted."
  else
    fail "Overwrite prompt transcript missing the prompt or Aborted."
  fi
fi

section "Scenario 8: Package Rebuild"
SC08_LOG="${LOG_DIR}/scenario08.log"
sleep 1
if run_logged "${SC08_LOG}" bash ./package.sh; then
  pass "package.sh exits successfully"
else
  fail "package.sh exited non-zero"
fi

SC08_ARCHIVE_COUNT="$(find "${BRIDGE_ROOT}" -maxdepth 1 -type f -name '*.tar.gz' | wc -l | tr -d '[:space:]')"
[[ "${SC08_ARCHIVE_COUNT}" == "9" ]] && pass "Exactly 9 release archives are present" || fail "Expected 9 release archives, got ${SC08_ARCHIVE_COUNT}"

SC08_SIZE_FAILURES=0
for archive in "${EXPECTED_ARCHIVES[@]}"; do
  archive_path="${BRIDGE_ROOT}/${archive}.tar.gz"
  if [[ -f "${archive_path}" ]]; then
    archive_size="$(stat -c %s "${archive_path}" 2>/dev/null || stat -f %z "${archive_path}" 2>/dev/null)"
    if [[ "${archive_size}" -gt 1000 ]]; then
      pass "${archive}.tar.gz has a reasonable size (${archive_size} bytes)"
    else
      fail "${archive}.tar.gz is too small (${archive_size} bytes)"
      SC08_SIZE_FAILURES=$((SC08_SIZE_FAILURES + 1))
    fi
  else
    fail "${archive}.tar.gz is missing"
    SC08_SIZE_FAILURES=$((SC08_SIZE_FAILURES + 1))
  fi
done

rm -rf "${PKG_TEST_ROOT}"
mkdir -p "${PKG_TEST_ROOT}"
if tar -xzf "${BRIDGE_ROOT}/bridge-full.tar.gz" -C "${PKG_TEST_ROOT}"; then
  pass "bridge-full.tar.gz extracts cleanly"
else
  fail "bridge-full.tar.gz failed to extract"
fi

SC08_EXTRACTED_COMMANDS="$(count_files "${PKG_TEST_ROOT}/.roo/commands" '*.md')"
[[ "${SC08_EXTRACTED_COMMANDS}" == "15" ]] && pass "Extracted bridge-full archive contains 15 commands" || fail "Extracted bridge-full archive expected 15 commands, got ${SC08_EXTRACTED_COMMANDS}"

section "Scenario 9: Command Consistency Across Packs"
EXPECTED_COMMAND_LIST="$(printf '%s\n' "${COMMANDS[@]}" | sort)"
FULL_COMMAND_LIST="$(find bridge-full/.roo/commands -mindepth 1 -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sed 's/\.md$//' | sort)"
STANDALONE_COMMAND_LIST="$(find bridge-standalone/.roo/commands -mindepth 1 -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sed 's/\.md$//' | sort)"
CLAUDE_COMMAND_LIST="$(find bridge-claude-code/.claude/commands -mindepth 1 -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sed 's/\.md$//' | sort)"
OPENCODE_COMMAND_LIST="$(find bridge-opencode/.opencode/commands -mindepth 1 -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sed 's/\.md$//' | sort)"
CODEX_COMMAND_LIST="$(find bridge-codex/.agents/skills -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)"

compare_lists "${FULL_COMMAND_LIST}" "${EXPECTED_COMMAND_LIST}" && pass "Full pack command list matches the 15 expected commands" || fail "Full pack command list does not match the expected 15 commands"
compare_lists "${STANDALONE_COMMAND_LIST}" "${EXPECTED_COMMAND_LIST}" && pass "Standalone pack command list matches the 15 expected commands" || fail "Standalone pack command list does not match the expected 15 commands"
compare_lists "${CLAUDE_COMMAND_LIST}" "${EXPECTED_COMMAND_LIST}" && pass "Claude Code command list matches the 15 expected commands" || fail "Claude Code command list does not match the expected 15 commands"
compare_lists "${OPENCODE_COMMAND_LIST}" "${EXPECTED_COMMAND_LIST}" && pass "OpenCode command list matches the 15 expected commands" || fail "OpenCode command list does not match the expected 15 commands"
compare_lists "${CODEX_COMMAND_LIST}" "${EXPECTED_COMMAND_LIST}" && pass "Codex skill list matches the 15 expected commands" || fail "Codex skill list does not match the expected 15 commands"

section "Scenario 10: Existing Project Support Commands"
SC10_MISSING=0
for pack_dir in \
  bridge-full/.roo/commands \
  bridge-standalone/.roo/commands \
  bridge-claude-code/.claude/commands \
  bridge-opencode/.opencode/commands; do
  [[ -f "${pack_dir}/bridge-scope.md" && -f "${pack_dir}/bridge-feature.md" ]] || SC10_MISSING=$((SC10_MISSING + 1))
done
[[ -d bridge-codex/.agents/skills/bridge-scope && -d bridge-codex/.agents/skills/bridge-feature ]] || SC10_MISSING=$((SC10_MISSING + 1))
[[ "${SC10_MISSING}" == "0" ]] && pass "bridge-scope and bridge-feature are present in all 5 packs" || fail "bridge-scope or bridge-feature missing in ${SC10_MISSING} pack targets"

if grep -Eiq 'existing|codebase|scope|analy' bridge-claude-code/.claude/commands/bridge-scope.md; then
  pass "bridge-scope instructs analysis of an existing codebase"
else
  fail "bridge-scope is missing existing-codebase analysis guidance"
fi

if grep -Eiq 'incremental|append|existing.*requirements|add.*feature' bridge-claude-code/.claude/commands/bridge-feature.md; then
  pass "bridge-feature instructs incremental requirements work"
else
  fail "bridge-feature is missing incremental requirements guidance"
fi

section "Scenario 11: Post-Delivery Feedback Loop"
SC11_COUNT="$(grep -RIl 'ISSUES REPORTED' bridge-full bridge-standalone bridge-claude-code bridge-codex bridge-opencode | wc -l | tr -d '[:space:]')"
if [[ "${SC11_COUNT}" -ge 10 ]]; then
  pass "\"ISSUES REPORTED\" is embedded across the canonical pack surfaces (${SC11_COUNT} files)"
else
  fail "\"ISSUES REPORTED\" expected in at least 10 canonical pack files, found ${SC11_COUNT}"
fi

if grep -q 'ISSUES REPORTED' bridge-full/.roo/rules-orchestrator/00-orchestrator.md && grep -q 'APPROVED' bridge-full/.roo/rules-orchestrator/00-orchestrator.md; then
  pass "Full pack orchestrator rules contain the feedback loop classifications"
else
  fail "Full pack orchestrator rules are missing ISSUES REPORTED or APPROVED"
fi

if grep -q 'ISSUES REPORTED' bridge-standalone/.roo/commands/bridge-start.md; then
  pass "Standalone bridge-start embeds the feedback loop"
else
  fail "Standalone bridge-start is missing the feedback loop"
fi

if grep -q 'ISSUES REPORTED' bridge-codex/AGENTS.md; then
  pass "Codex AGENTS.md includes the feedback loop"
else
  fail "Codex AGENTS.md is missing the feedback loop"
fi

section "Scenario 12: Design Integration Command"
SC12_MISSING=0
for design_path in \
  bridge-full/.roo/commands/bridge-design.md \
  bridge-standalone/.roo/commands/bridge-design.md \
  bridge-claude-code/.claude/commands/bridge-design.md \
  bridge-codex/.agents/skills/bridge-design/SKILL.md \
  bridge-opencode/.opencode/commands/bridge-design.md; do
  [[ -f "${design_path}" ]] || SC12_MISSING=$((SC12_MISSING + 1))
done
[[ "${SC12_MISSING}" == "0" ]] && pass "bridge-design is present in all 5 packs" || fail "bridge-design missing in ${SC12_MISSING} pack targets"

if grep -Eiq 'design document|PRD|version spec|design input' bridge-claude-code/.claude/commands/bridge-design.md; then
  pass "Claude Code bridge-design covers design document integration"
else
  fail "Claude Code bridge-design is missing design document guidance"
fi

if grep -Eiq 'design document|PRD|version spec|design input' bridge-codex/.agents/skills/bridge-design/SKILL.md; then
  pass "Codex bridge-design mirrors the design integration guidance"
else
  fail "Codex bridge-design is missing design document guidance"
fi

section "Scenario 13: Strategic Advisor Command"
SC13_MISSING=0
for advisor_path in \
  bridge-full/.roo/commands/bridge-advisor.md \
  bridge-standalone/.roo/commands/bridge-advisor.md \
  bridge-claude-code/.claude/commands/bridge-advisor.md \
  bridge-codex/.agents/skills/bridge-advisor/SKILL.md \
  bridge-opencode/.opencode/commands/bridge-advisor.md; do
  [[ -f "${advisor_path}" ]] || SC13_MISSING=$((SC13_MISSING + 1))
done
[[ "${SC13_MISSING}" == "0" ]] && pass "bridge-advisor is present in all 5 packs" || fail "bridge-advisor missing in ${SC13_MISSING} pack targets"

SC13_FILE="bridge-claude-code/.claude/commands/bridge-advisor.md"
if grep -q 'Product Strategist' "${SC13_FILE}" && grep -q 'Developer Advocate' "${SC13_FILE}" && grep -q 'Critical Friend' "${SC13_FILE}"; then
  pass "bridge-advisor defines all 3 advisor roles"
else
  fail "bridge-advisor is missing one or more advisor roles"
fi

if grep -Eiq 'viability|positioning|launch|roadmap|community' "${SC13_FILE}"; then
  pass "bridge-advisor covers strategic concerns"
else
  fail "bridge-advisor is missing strategic concern coverage"
fi

section "Scenario 14: Controller Pack Structure"
if [[ -f bridge-controller/CLAUDE.md ]] && grep -Eiq 'BRIDGE Controller|controller|portfolio|meta' bridge-controller/CLAUDE.md; then
  pass "Controller CLAUDE.md documents the controller role"
else
  fail "Controller CLAUDE.md missing or incomplete"
fi

SC14_COMMANDS="$(count_files bridge-controller/.claude/commands '*.md')"
[[ "${SC14_COMMANDS}" == "3" ]] && pass "Controller pack has 3 command files" || fail "Controller pack expected 3 command files, got ${SC14_COMMANDS}"

SC14_MISSING=0
for controller_cmd in bridge-init-project bridge-status bridge-sync; do
  [[ -f "bridge-controller/.claude/commands/${controller_cmd}.md" ]] || SC14_MISSING=$((SC14_MISSING + 1))
done
[[ "${SC14_MISSING}" == "0" ]] && pass "Controller pack includes init-project, status, and sync" || fail "Controller pack is missing ${SC14_MISSING} required commands"

if grep -qi 'bridgeinclude' bridge-controller/.claude/commands/bridge-status.md; then
  pass "bridge-status scans for .bridgeinclude markers"
else
  fail "bridge-status does not mention .bridgeinclude markers"
fi

if [[ -f bridge-controller/.claude/rules/controller.md ]] && grep -Eiq 'meta|portfolio|never.*application.*code' bridge-controller/.claude/rules/controller.md; then
  pass "Controller rules enforce meta-only scope"
else
  fail "Controller rules missing meta-only scope guidance"
fi

[[ -f bridge-controller/docs/portfolio.json ]] && pass "Controller portfolio.json template exists" || fail "Controller portfolio.json template missing"
[[ -f bridge-controller/reference/controller-guide.md ]] && pass "Controller reference guide exists" || fail "Controller reference guide missing"
[[ -f bridge-controller.tar.gz ]] && pass "Controller archive exists" || fail "Controller archive missing"

section "Scenario 15: Multi-Repo Pack -- Claude Code Variant"
if [[ -f bridge-multi-repo/claude-code/CLAUDE.md ]] && grep -Eiq 'multi-repo|workspace|cross-repo' bridge-multi-repo/claude-code/CLAUDE.md; then
  pass "Multi-repo Claude Code CLAUDE.md describes the workspace role"
else
  fail "Multi-repo Claude Code CLAUDE.md missing or incomplete"
fi

SC15_COMMANDS="$(count_files bridge-multi-repo/claude-code/.claude/commands '*.md')"
[[ "${SC15_COMMANDS}" == "12" ]] && pass "Multi-repo Claude Code pack has 12 command files" || fail "Multi-repo Claude Code pack expected 12 command files, got ${SC15_COMMANDS}"

SC15_MISSING=0
for cmd in bridge-cross-design bridge-cross-review bridge-cross-sync bridge-repo-status; do
  [[ -f "bridge-multi-repo/claude-code/.claude/commands/${cmd}.md" ]] || SC15_MISSING=$((SC15_MISSING + 1))
done
[[ "${SC15_MISSING}" == "0" ]] && pass "All 4 cross-repo Claude Code commands are present" || fail "Multi-repo Claude Code pack is missing ${SC15_MISSING} cross-repo commands"

if grep -Eiq 'contract|schema|migration' bridge-multi-repo/claude-code/.claude/commands/bridge-cross-design.md; then
  pass "bridge-cross-design covers contracts and migration strategy"
else
  fail "bridge-cross-design is missing contract or migration guidance"
fi

if [[ -f bridge-multi-repo/claude-code/.claude/rules/multi-repo.md ]] && grep -Eiq 'relative.*path|branch.*coord|cross.*repo' bridge-multi-repo/claude-code/.claude/rules/multi-repo.md; then
  pass "Multi-repo Claude Code rules cover coordinated branch work"
else
  fail "Multi-repo Claude Code rules missing coordinated branch guidance"
fi

[[ -f bridge-multi-repo/claude-code/docs/context.json ]] && pass "Multi-repo Claude Code docs/context.json exists" || fail "Multi-repo Claude Code docs/context.json missing"
[[ -f bridge-multi-repo/claude-code/docs/requirements.json ]] && pass "Multi-repo Claude Code docs/requirements.json exists" || fail "Multi-repo Claude Code docs/requirements.json missing"
[[ -f bridge-multi-repo/claude-code/reference/multi-repo-playbook.md ]] && pass "Multi-repo Claude Code playbook exists" || fail "Multi-repo Claude Code playbook missing"

section "Scenario 16: Multi-Repo Pack -- Codex Variant"
if [[ -f bridge-multi-repo/codex/AGENTS.md ]] && grep -Eiq 'multi-repo|workspace|cross-repo' bridge-multi-repo/codex/AGENTS.md; then
  pass "Multi-repo Codex AGENTS.md describes the workspace role"
else
  fail "Multi-repo Codex AGENTS.md missing or incomplete"
fi

SC16_SKILLS="$(count_dirs bridge-multi-repo/codex/.agents/skills)"
[[ "${SC16_SKILLS}" == "12" ]] && pass "Multi-repo Codex pack has 12 skill directories" || fail "Multi-repo Codex pack expected 12 skill directories, got ${SC16_SKILLS}"

SC16_MISSING=0
for skill in bridge-cross-design bridge-cross-review bridge-cross-sync bridge-repo-status; do
  [[ -d "bridge-multi-repo/codex/.agents/skills/${skill}" ]] || SC16_MISSING=$((SC16_MISSING + 1))
done
[[ "${SC16_MISSING}" == "0" ]] && pass "All 4 cross-repo Codex skills are present" || fail "Multi-repo Codex pack is missing ${SC16_MISSING} cross-repo skills"

if [[ -f bridge-multi-repo/codex/.codex/config.toml ]] && toml_valid bridge-multi-repo/codex/.codex/config.toml; then
  pass "Multi-repo Codex config.toml exists and parses as TOML"
else
  fail "Multi-repo Codex config.toml missing or invalid"
fi

[[ -f bridge-multi-repo/codex/docs/context.json ]] && pass "Multi-repo Codex docs/context.json exists" || fail "Multi-repo Codex docs/context.json missing"
[[ -f bridge-multi-repo/codex/docs/requirements.json ]] && pass "Multi-repo Codex docs/requirements.json exists" || fail "Multi-repo Codex docs/requirements.json missing"

SC16_CLAUDE_NAMES="$(find bridge-multi-repo/claude-code/.claude/commands -mindepth 1 -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sed 's/\.md$//' | sort)"
SC16_CODEX_NAMES="$(find bridge-multi-repo/codex/.agents/skills -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)"
compare_lists "${SC16_CLAUDE_NAMES}" "${SC16_CODEX_NAMES}" && pass "Codex skill names mirror Claude Code command names" || fail "Codex skill names do not mirror Claude Code command names"

section "Scenario 17: Methodology Reference Document"
SC17_LINES="$(wc -l < reference/BRIDGE-v2.1-methodology.md | tr -d '[:space:]')"
if [[ "${SC17_LINES}" -ge 100 ]]; then
  pass "Methodology reference is substantial (${SC17_LINES} lines)"
else
  fail "Methodology reference expected at least 100 lines, got ${SC17_LINES}"
fi

SC17_PHASE_MATCHES="$(grep -Eic 'brainstorm|requirements|implementation design|develop|gate|evaluate' reference/BRIDGE-v2.1-methodology.md)"
if [[ "${SC17_PHASE_MATCHES}" -ge 6 ]]; then
  pass "Methodology reference covers all 6 BRIDGE phases"
else
  fail "Methodology reference does not clearly cover all 6 BRIDGE phases"
fi

if grep -q 'ISSUES REPORTED' reference/BRIDGE-v2.1-methodology.md; then
  pass "Methodology reference documents the feedback loop"
else
  fail "Methodology reference is missing the feedback loop"
fi

if grep -q 'context.json' reference/BRIDGE-v2.1-methodology.md && grep -q 'requirements.json' reference/BRIDGE-v2.1-methodology.md; then
  pass "Methodology reference documents both JSON schemas"
else
  fail "Methodology reference is missing one or both JSON schema references"
fi

section "Scenario 18: Smoke + E2E Suite"
SC18_SMOKE_LOG="${LOG_DIR}/scenario18-test.log"
if run_logged "${SC18_SMOKE_LOG}" bash ./test.sh; then
  pass "test.sh exits successfully"
else
  fail "test.sh exited non-zero"
fi

SC18_SMOKE_PASSED="$(extract_summary_value "${SC18_SMOKE_LOG}" 'Passed' | tr -d '[:space:]')"
SC18_SMOKE_FAILED="$(extract_summary_value "${SC18_SMOKE_LOG}" 'Failed' | tr -d '[:space:]')"
[[ "${SC18_SMOKE_PASSED}" == "45" && "${SC18_SMOKE_FAILED}" == "0" ]] && pass "test.sh reports 45/45 smoke checks" || fail "test.sh expected 45 passed / 0 failed, got ${SC18_SMOKE_PASSED:-?} passed / ${SC18_SMOKE_FAILED:-?} failed"

if grep -q 'shellcheck not installed, skipping' "${SC18_SMOKE_LOG}"; then
  pass "test.sh reported only the expected shellcheck skip warning"
fi

SC18_E2E_TOTAL=0
SC18_E2E_FAILED=0
for spec in \
  "tests/e2e/test-setup-packs.sh:32" \
  "tests/e2e/test-pack-consistency.sh:24" \
  "tests/e2e/test-advanced-packs.sh:37" \
  "tests/e2e/test-workflow-content.sh:21"; do
  script_path="${spec%%:*}"
  expected_passes="${spec##*:}"
  log_file="${LOG_DIR}/$(basename "${script_path}").log"

  if run_logged "${log_file}" bash "${script_path}"; then
    pass "$(basename "${script_path}") exits successfully"
  else
    fail "$(basename "${script_path}") exited non-zero"
  fi

  script_passed="$(extract_summary_value "${log_file}" 'Passed' | tr -d '[:space:]')"
  script_failed="$(extract_summary_value "${log_file}" 'Failed' | tr -d '[:space:]')"
  if [[ "${script_passed}" == "${expected_passes}" && "${script_failed}" == "0" ]]; then
    pass "$(basename "${script_path}") reports ${expected_passes}/${expected_passes}"
  else
    fail "$(basename "${script_path}") expected ${expected_passes} passed / 0 failed, got ${script_passed:-?} passed / ${script_failed:-?} failed"
  fi

  if [[ -n "${script_passed}" ]]; then
    SC18_E2E_TOTAL=$((SC18_E2E_TOTAL + script_passed))
  fi
  if [[ -n "${script_failed}" ]]; then
    SC18_E2E_FAILED=$((SC18_E2E_FAILED + script_failed))
  fi
done

[[ "${SC18_E2E_TOTAL}" == "114" && "${SC18_E2E_FAILED}" == "0" ]] && pass "E2E suite totals 114/114 assertions" || fail "E2E suite expected 114 passed / 0 failed, got ${SC18_E2E_TOTAL} passed / ${SC18_E2E_FAILED} failed"

section "Scenario 19: Greenfield Workflow Walkthrough"
SC19_CMD_DIR="${SC02_PROJECT}/.claude/commands"
if grep -Eiq 'brainstorm|idea|concept|clarifying' "${SC19_CMD_DIR}/bridge-brainstorm.md"; then
  pass "bridge-brainstorm captures and structures an idea"
else
  fail "bridge-brainstorm is missing idea-structuring guidance"
fi

if grep -Eiq 'requirements.json|feature|acceptance|user flow' "${SC19_CMD_DIR}/bridge-requirements.md"; then
  pass "bridge-requirements generates structured requirements"
else
  fail "bridge-requirements is missing structured requirements guidance"
fi

if grep -Eiq 'slice|implement|plan|vertical' "${SC19_CMD_DIR}/bridge-start.md"; then
  pass "bridge-start plans and executes slices"
else
  fail "bridge-start is missing slice planning guidance"
fi

if grep -Eiq 'gate|quality|audit|verify' "${SC19_CMD_DIR}/bridge-gate.md"; then
  pass "bridge-gate runs quality checks"
else
  fail "bridge-gate is missing gate guidance"
fi

if grep -Eiq 'scenario|evaluation|feedback template|e2e' "${SC19_CMD_DIR}/bridge-eval.md"; then
  pass "bridge-eval generates evaluation outputs"
else
  fail "bridge-eval is missing evaluation guidance"
fi

if grep -Eiq 'feedback|iterate|launch|triage' "${SC19_CMD_DIR}/bridge-feedback.md"; then
  pass "bridge-feedback processes evaluation results"
else
  fail "bridge-feedback is missing feedback-processing guidance"
fi

section "Scenario 20: Session Continuity"
if grep -Eiq 'context.json|resume|brief|state' "${SC19_CMD_DIR}/bridge-resume.md"; then
  pass "bridge-resume reads context.json and produces a session brief"
else
  fail "bridge-resume is missing context/session brief guidance"
fi

if grep -Eiq 'context.json|handoff|save|state|session' "${SC19_CMD_DIR}/bridge-end.md"; then
  pass "bridge-end saves state and handoff notes"
else
  fail "bridge-end is missing state/handoff guidance"
fi

grep -q 'context.json' "${SC19_CMD_DIR}/bridge-resume.md" && pass "bridge-resume explicitly references context.json" || fail "bridge-resume does not reference context.json"
grep -q 'context.json' "${SC19_CMD_DIR}/bridge-end.md" && pass "bridge-end explicitly references context.json" || fail "bridge-end does not reference context.json"

section "Scenario 21: Context Management Commands"
if grep -Eiq 'context.json|create|initial|scan' bridge-claude-code/.claude/commands/bridge-context-create.md; then
  pass "bridge-context-create generates an initial context.json"
else
  fail "bridge-context-create is missing initialization guidance"
fi

if grep -Eiq 'context.json|sync|update|current' bridge-claude-code/.claude/commands/bridge-context-update.md; then
  pass "bridge-context-update syncs context.json with current state"
else
  fail "bridge-context-update is missing sync guidance"
fi

SC21_MISSING=0
for pack_dir in \
  bridge-full/.roo/commands \
  bridge-standalone/.roo/commands \
  bridge-claude-code/.claude/commands \
  bridge-opencode/.opencode/commands; do
  [[ -f "${pack_dir}/bridge-context-create.md" && -f "${pack_dir}/bridge-context-update.md" ]] || SC21_MISSING=$((SC21_MISSING + 1))
done
[[ -d bridge-codex/.agents/skills/bridge-context-create && -d bridge-codex/.agents/skills/bridge-context-update ]] || SC21_MISSING=$((SC21_MISSING + 1))
[[ "${SC21_MISSING}" == "0" ]] && pass "Context-create and context-update are present in all packs" || fail "Context-create or context-update missing in ${SC21_MISSING} pack targets"

section "Scenario 22: Documentation Quality"
check_readme_pack_mentions && pass "README mentions all 5 core packs" || fail "README does not mention all 5 core packs"

if [[ -f reference/platform-guides.md ]] && [[ "$(wc -l < reference/platform-guides.md | tr -d '[:space:]')" -ge 30 ]]; then
  pass "reference/platform-guides.md exists and is substantial"
else
  fail "reference/platform-guides.md missing or too short"
fi

if grep -Ei 'bridge-migrate|bridge-offload|bridge-reintegrate' README.md reference/platform-guides.md reference/BRIDGE-v2.1-methodology.md >/dev/null 2>&1; then
  fail "Documentation still references deleted commands"
else
  pass "Documentation is clean of deleted command references"
fi

SC22_COMMAND_COUNT=0
for cmd in "${COMMANDS[@]}"; do
  if grep -q "${cmd}" README.md; then
    SC22_COMMAND_COUNT=$((SC22_COMMAND_COUNT + 1))
  fi
done
[[ "${SC22_COMMAND_COUNT}" == "15" ]] && pass "README references all 15 current commands" || fail "README references ${SC22_COMMAND_COUNT}/15 current commands"

section "Scenario 23: End-to-End Live Test"
if [[ "${SKIP_LIVE}" -eq 1 ]]; then
  skip "Scenario 23 skipped by --skip-live"
else
  LIVE_CHOICE="$(detect_live_platform)"
  if [[ "${LIVE_CHOICE}" == "none" ]]; then
    skip "Scenario 23 skipped because no supported live CLI was found (claude, codex, opencode)"
  elif ! tty_available; then
    skip "Scenario 23 requires a real TTY"
  else
    case "${LIVE_CHOICE}" in
      claude)
        LIVE_PACK="claude-code"
        LIVE_LAUNCH=(claude)
        ;;
      codex)
        LIVE_PACK="codex"
        LIVE_LAUNCH=(codex)
        ;;
      opencode)
        LIVE_PACK="opencode"
        LIVE_LAUNCH=(opencode)
        ;;
    esac

    SC23_SETUP_LOG="${LOG_DIR}/scenario23-setup.log"
    rm -rf "${LIVE_ROOT}"
    if run_logged "${SC23_SETUP_LOG}" bash ./setup.sh --name "Live Test" --pack "${LIVE_PACK}" -o "${LIVE_ROOT}"; then
      pass "Live test project setup succeeds for ${LIVE_PACK}"
    else
      fail "Live test project setup failed for ${LIVE_PACK}"
    fi

    LIVE_PROJECT="${LIVE_ROOT}/live-test"
    if [[ -d "${LIVE_PROJECT}" ]]; then
      pass "Live test project directory exists"
    else
      fail "Live test project directory missing"
    fi

    note "Live scenario platform: ${LIVE_CHOICE}"
    if [[ "${LIVE_CHOICE}" == "claude" || "${LIVE_CHOICE}" == "opencode" ]]; then
      note "Run these commands inside the live agent session:"
      note "  /bridge-brainstorm"
      note "    Idea: a CLI tool that counts words in a file"
      note "  /bridge-requirements-only"
      note "    Description: a CLI tool that counts words in a file and prints totals"
      note "  /bridge-advisor"
      note "  /bridge-end"
    else
      note "Run these commands inside the live agent session:"
      note '  $bridge-brainstorm'
      note "    Idea: a CLI tool that counts words in a file"
      note '  $bridge-requirements-only'
      note "    Description: a CLI tool that counts words in a file and prints totals"
      note '  $bridge-advisor'
      note '  $bridge-end'
    fi
    prompt_continue "Press Enter to launch the live agent CLI. Exit the CLI when you finish the scenario..."

    (
      cd "${LIVE_PROJECT}" || exit 1
      "${LIVE_LAUNCH[@]}"
    )
    SC23_STATUS=$?
    if [[ "${SC23_STATUS}" -eq 0 ]]; then
      pass "Live agent CLI exited successfully"
    else
      fail "Live agent CLI exited non-zero (${SC23_STATUS})"
    fi

    if prompt_yes_no "Did the agent recognize and execute the BRIDGE command(s)?"; then
      pass "Live agent recognized and executed the BRIDGE command(s)"
    else
      fail "Live agent did not recognize or execute the BRIDGE command(s)"
    fi

    if prompt_yes_no "Did the output follow BRIDGE methodology structure?"; then
      pass "Live agent output followed BRIDGE methodology structure"
    else
      fail "Live agent output did not follow BRIDGE methodology structure"
    fi

    if prompt_yes_no "Did the agent output end with a HUMAN: block when expected?"; then
      pass "Live agent output included a HUMAN: block"
    else
      fail "Live agent output did not include the expected HUMAN: block"
    fi

    if prompt_yes_no "Were docs/ files created or updated appropriately during the live run?"; then
      pass "Live run updated docs/ files appropriately"
    else
      fail "Live run did not update docs/ files as expected"
    fi

    if prompt_yes_no "Did the agent stay in role throughout the interaction?"; then
      pass "Live agent stayed in role"
    else
      fail "Live agent drifted out of role"
    fi
  fi
fi

section "Results"
printf "  Passed: \033[32m%d\033[0m\n" "${PASSED}"
printf "  Failed: \033[31m%d\033[0m\n" "${FAILED}"
printf "  Skipped: \033[33m%d\033[0m\n" "${SKIPPED}"

if [[ "${FAILED}" -gt 0 ]]; then
  echo ""
  echo "  Failures:"
  for failure in "${FAILURES[@]}"; do
    printf "    \033[31m-\033[0m %s\n" "${failure}"
  done
fi

if [[ "${SKIPPED}" -gt 0 ]]; then
  echo ""
  echo "  Skipped:"
  for skipped in "${SKIPS[@]}"; do
    printf "    \033[33m~\033[0m %s\n" "${skipped}"
  done
fi

if [[ "${KEEP_ARTIFACTS}" -eq 1 || "${FAILED}" -gt 0 ]]; then
  echo ""
  echo "Artifacts retained:"
  echo "  ${EVAL_ROOT}"
  echo "  ${LIVE_ROOT}"
  echo "  ${PKG_TEST_ROOT}"
fi

exit "${FAILED}"

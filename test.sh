#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# BRIDGE v2.1 — Smoke Tests
# Validates pack structure, commands, setup.sh, and package.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSED=0
FAILED=0
ERRORS=()

# --- Helpers ---
pass() { PASSED=$((PASSED + 1)); printf "  \033[32m✓\033[0m %s\n" "$1"; }
fail() { FAILED=$((FAILED + 1)); ERRORS+=("$1"); printf "  \033[31m✗\033[0m %s\n" "$1"; }
section() { printf "\n\033[1m━━━ %s ━━━\033[0m\n" "$1"; }

# --- Expected 18 commands ---
COMMANDS=(
  bridge-advisor bridge-brainstorm bridge-context-create bridge-context-update
  bridge-design bridge-end bridge-eval bridge-feature bridge-feedback
  bridge-gate bridge-migrate bridge-offload bridge-reintegrate
  bridge-requirements-only bridge-requirements bridge-resume bridge-scope bridge-start
)

# --- Expected 8 procedure skills ---
SKILLS=(
  bridge-context-sync bridge-eval-generate bridge-external-handoff
  bridge-external-reintegrate bridge-feedback-process bridge-gate-audit
  bridge-session-management bridge-slice-plan
)

# --- Expected 5 agents ---
AGENTS=(bridge-architect bridge-auditor bridge-coder bridge-debugger bridge-evaluator)

# --- Expected docs templates ---
DOCS=(context.json decisions.md human-playbook.md requirements.json)

# --- Generic checkers ---
check_files() {
  local label="$1" base="$2" suffix="$3"
  shift 3
  local names=("$@")
  local missing=0
  for name in "${names[@]}"; do
    [[ -f "${base}/${name}${suffix}" ]] || missing=$((missing + 1))
  done
  if [[ $missing -eq 0 ]]; then
    pass "${label}: all ${#names[@]} items present"
  else
    fail "${label}: ${missing} of ${#names[@]} items missing"
  fi
}

check_file() {
  local label="$1" path="$2"
  if [[ -f "$path" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

# ============================================================
# 1. Pack structure — bridge-full
# ============================================================
section "Pack Structure — bridge-full"
if [[ -d "${SCRIPT_DIR}/bridge-full" ]]; then
  check_files "commands" "${SCRIPT_DIR}/bridge-full/.roo/commands" ".md" "${COMMANDS[@]}"
  check_files "skills" "${SCRIPT_DIR}/bridge-full/.roo/skills" "/SKILL.md" "${SKILLS[@]}"
  check_files "docs" "${SCRIPT_DIR}/bridge-full/docs" "" "${DOCS[@]}"
  check_file ".roomodes" "${SCRIPT_DIR}/bridge-full/.roomodes"
  check_file "global rules" "${SCRIPT_DIR}/bridge-full/.roo/rules/00-bridge-global.md"
else
  fail "bridge-full: folder not found"
fi

# ============================================================
# 2. Pack structure — bridge-standalone
# ============================================================
section "Pack Structure — bridge-standalone"
if [[ -d "${SCRIPT_DIR}/bridge-standalone" ]]; then
  check_files "commands" "${SCRIPT_DIR}/bridge-standalone/.roo/commands" ".md" "${COMMANDS[@]}"
  check_files "docs" "${SCRIPT_DIR}/bridge-standalone/docs" "" "${DOCS[@]}"
  check_file ".roomodes" "${SCRIPT_DIR}/bridge-standalone/.roomodes"
else
  fail "bridge-standalone: folder not found"
fi

# ============================================================
# 3. Pack structure — bridge-claude-code
# ============================================================
section "Pack Structure — bridge-claude-code"
if [[ -d "${SCRIPT_DIR}/bridge-claude-code" ]]; then
  check_files "commands" "${SCRIPT_DIR}/bridge-claude-code/.claude/commands" ".md" "${COMMANDS[@]}"
  check_files "skills" "${SCRIPT_DIR}/bridge-claude-code/.claude/skills" "/SKILL.md" "${SKILLS[@]}"
  check_files "agents" "${SCRIPT_DIR}/bridge-claude-code/.claude/agents" ".md" "${AGENTS[@]}"
  check_files "docs" "${SCRIPT_DIR}/bridge-claude-code/docs" "" "${DOCS[@]}"
  check_file "CLAUDE.md" "${SCRIPT_DIR}/bridge-claude-code/CLAUDE.md"
else
  fail "bridge-claude-code: folder not found"
fi

# ============================================================
# 4. Pack structure — bridge-codex
# ============================================================
section "Pack Structure — bridge-codex"
if [[ -d "${SCRIPT_DIR}/bridge-codex" ]]; then
  check_files "command-skills" "${SCRIPT_DIR}/bridge-codex/.agents/skills" "/SKILL.md" "${COMMANDS[@]}"
  check_files "procedure-skills" "${SCRIPT_DIR}/bridge-codex/.agents/skills" "/SKILL.md" "${SKILLS[@]}"
  check_files "docs" "${SCRIPT_DIR}/bridge-codex/docs" "" "${DOCS[@]}"
  check_file "AGENTS.md" "${SCRIPT_DIR}/bridge-codex/AGENTS.md"
  check_file "config.toml" "${SCRIPT_DIR}/bridge-codex/.codex/config.toml"
else
  fail "bridge-codex: folder not found"
fi

# ============================================================
# 5. Pack structure — bridge-opencode
# ============================================================
section "Pack Structure — bridge-opencode"
if [[ -d "${SCRIPT_DIR}/bridge-opencode" ]]; then
  check_files "commands" "${SCRIPT_DIR}/bridge-opencode/.opencode/commands" ".md" "${COMMANDS[@]}"
  check_files "skills" "${SCRIPT_DIR}/bridge-opencode/.opencode/skills" "/SKILL.md" "${SKILLS[@]}"
  check_files "agents" "${SCRIPT_DIR}/bridge-opencode/.opencode/agents" ".md" "${AGENTS[@]}"
  check_files "docs" "${SCRIPT_DIR}/bridge-opencode/docs" "" "${DOCS[@]}"
  check_file "AGENTS.md" "${SCRIPT_DIR}/bridge-opencode/AGENTS.md"
  check_file "opencode.json" "${SCRIPT_DIR}/bridge-opencode/opencode.json"
else
  fail "bridge-opencode: folder not found"
fi

# ============================================================
# 6. setup.sh — runs for each pack
# ============================================================
section "setup.sh Smoke Tests"

TMPDIR_BASE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

for pack in full standalone claude-code codex opencode; do
  OUT="${TMPDIR_BASE}/${pack}"
  mkdir -p "$OUT"
  if bash "${SCRIPT_DIR}/setup.sh" --name "Test Project" --pack "$pack" -o "$OUT" >/dev/null 2>&1; then
    pass "setup.sh --pack ${pack}: exits successfully"

    PROJECT="${OUT}/test-project"

    # Placeholder replacement
    if grep -rq '{{PROJECT_NAME}}' "$PROJECT" 2>/dev/null; then
      fail "setup.sh --pack ${pack}: {{PROJECT_NAME}} not fully replaced"
    else
      pass "setup.sh --pack ${pack}: placeholder replaced"
    fi

    # docs/ directory created
    if [[ -d "${PROJECT}/docs" ]]; then
      pass "setup.sh --pack ${pack}: docs/ created"
    else
      fail "setup.sh --pack ${pack}: docs/ not created"
    fi
  else
    fail "setup.sh --pack ${pack}: exited with error"
  fi
done

# ============================================================
# 7. package.sh — builds all tar.gz
# ============================================================
section "package.sh"

if bash "${SCRIPT_DIR}/package.sh" >/dev/null 2>&1; then
  pass "package.sh: exits successfully"
  for pack in bridge-full bridge-standalone bridge-claude-code bridge-codex bridge-opencode; do
    archive="${SCRIPT_DIR}/${pack}.tar.gz"
    if [[ -f "$archive" ]]; then
      size=$(stat -c%s "$archive" 2>/dev/null || stat -f%z "$archive" 2>/dev/null)
      if [[ "$size" -gt 1000 ]]; then
        pass "${pack}.tar.gz created (${size} bytes)"
      else
        fail "${pack}.tar.gz suspiciously small (${size} bytes)"
      fi
    else
      fail "${pack}.tar.gz not created"
    fi
  done
else
  fail "package.sh: exited with error"
fi

# ============================================================
# 8. Shellcheck (optional)
# ============================================================
section "Shell Lint"

if command -v shellcheck &>/dev/null; then
  for script in setup.sh package.sh test.sh; do
    if shellcheck "${SCRIPT_DIR}/${script}" >/dev/null 2>&1; then
      pass "shellcheck: ${script} clean"
    elif shellcheck -S error "${SCRIPT_DIR}/${script}" >/dev/null 2>&1; then
      pass "shellcheck: ${script} (warnings only)"
    else
      fail "shellcheck: ${script} has errors"
    fi
  done
else
  echo "  - shellcheck not installed, skipping"
fi

# ============================================================
# Summary
# ============================================================
section "Results"
echo ""
printf "  Passed: \033[32m%d\033[0m\n" "$PASSED"
printf "  Failed: \033[31m%d\033[0m\n" "$FAILED"

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo ""
  echo "  Failures:"
  for err in "${ERRORS[@]}"; do
    printf "    \033[31m✗\033[0m %s\n" "$err"
  done
fi

echo ""
if [[ $FAILED -eq 0 ]]; then
  printf "\033[32mAll tests passed.\033[0m\n"
else
  printf "\033[31m%d test(s) failed.\033[0m\n" "$FAILED"
fi
exit "$FAILED"

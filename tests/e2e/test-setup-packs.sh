#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# BRIDGE v2.1 -- E2E Tests: Setup Script Pack Creation
# Tests AT01-AT04, AT11 (bridge.sh new creates working projects)
# Maps to: UF01 (Greenfield Project), F01-F05, F11
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_ROOT="${SCRIPT_DIR}/../.."
PASSED=0
FAILED=0
ERRORS=()

# --- Helpers ---
pass() { PASSED=$((PASSED + 1)); printf "  \033[32m+\033[0m %s\n" "$1"; }
fail() { FAILED=$((FAILED + 1)); ERRORS+=("$1"); printf "  \033[31m-\033[0m %s\n" "$1"; }
section() { printf "\n\033[1m--- %s ---\033[0m\n" "$1"; }

# --- Setup temp dir ---
TMPDIR_BASE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ============================================================
# Test: Full Pack (AT01)
# ============================================================
section "AT01: bridge.sh new --pack full"

OUT="${TMPDIR_BASE}/full"
mkdir -p "$OUT"

if bash "${BRIDGE_ROOT}/bridge.sh" new --name "E2E Full Test" --pack full -o "$OUT" >/dev/null 2>&1; then
  pass "bridge.sh new --pack full exits 0"
  PROJECT="${OUT}/e2e-full-test"

  # 15 commands
  CMD_COUNT=$(ls "${PROJECT}/.roo/commands/" 2>/dev/null | grep -c '.md$' || echo 0)
  [[ "$CMD_COUNT" -eq 15 ]] && pass "15 command files present" || fail "Expected 15 commands, got ${CMD_COUNT}"

  # 6 skills
  SKILL_COUNT=$(ls -d "${PROJECT}/.roo/skills/"*/ 2>/dev/null | wc -l || echo 0)
  [[ "$SKILL_COUNT" -eq 6 ]] && pass "6 skill directories present" || fail "Expected 6 skills, got ${SKILL_COUNT}"

  # Placeholder replaced
  if grep -rq '{{PROJECT_NAME}}' "$PROJECT" 2>/dev/null; then
    fail "{{PROJECT_NAME}} placeholder not fully replaced"
  else
    pass "All placeholders replaced"
  fi

  # Project name in files
  if grep -rq 'E2E Full Test' "$PROJECT/docs/requirements.json" 2>/dev/null; then
    pass "Project name appears in requirements.json"
  else
    fail "Project name not found in requirements.json"
  fi

  # docs templates
  for doc in context.json decisions.md human-playbook.md requirements.json; do
    [[ -f "${PROJECT}/docs/${doc}" ]] || { fail "Missing docs/${doc}"; continue; }
  done
  pass "All 4 docs templates present"

  # .roomodes
  [[ -f "${PROJECT}/.roomodes" ]] && pass ".roomodes exists" || fail ".roomodes missing"

  # Directory structure (tests, src, docs/contracts)
  [[ -d "${PROJECT}/tests/e2e" ]] && pass "tests/e2e/ directory created" || fail "tests/e2e/ missing"
  [[ -d "${PROJECT}/src" ]] && pass "src/ directory created" || fail "src/ missing"
else
  fail "bridge.sh new --pack full exited with error"
fi

# ============================================================
# Test: Claude Code Pack (AT03)
# ============================================================
section "AT03: bridge.sh new --pack claude-code"

OUT="${TMPDIR_BASE}/claude-code"
mkdir -p "$OUT"

if bash "${BRIDGE_ROOT}/bridge.sh" new --name "E2E Claude Test" --pack claude-code -o "$OUT" >/dev/null 2>&1; then
  pass "bridge.sh new --pack claude-code exits 0"
  PROJECT="${OUT}/e2e-claude-test"

  # CLAUDE.md with project name
  if [[ -f "${PROJECT}/CLAUDE.md" ]] && grep -q 'E2E Claude Test' "${PROJECT}/CLAUDE.md"; then
    pass "CLAUDE.md present with project name"
  else
    fail "CLAUDE.md missing or project name not found"
  fi

  # 15 commands
  CMD_COUNT=$(ls "${PROJECT}/.claude/commands/" 2>/dev/null | grep -c '.md$' || echo 0)
  [[ "$CMD_COUNT" -eq 15 ]] && pass "15 command files present" || fail "Expected 15 commands, got ${CMD_COUNT}"

  # 5 agents
  AGENT_COUNT=$(ls "${PROJECT}/.claude/agents/" 2>/dev/null | grep -c '.md$' || echo 0)
  [[ "$AGENT_COUNT" -eq 5 ]] && pass "5 agent files present" || fail "Expected 5 agents, got ${AGENT_COUNT}"

  # 6 skills
  SKILL_COUNT=$(ls -d "${PROJECT}/.claude/skills/"*/ 2>/dev/null | wc -l || echo 0)
  [[ "$SKILL_COUNT" -eq 6 ]] && pass "6 skill directories present" || fail "Expected 6 skills, got ${SKILL_COUNT}"

  # Placeholder
  if grep -rq '{{PROJECT_NAME}}' "$PROJECT" 2>/dev/null; then
    fail "{{PROJECT_NAME}} placeholder not fully replaced"
  else
    pass "All placeholders replaced"
  fi
else
  fail "bridge.sh new --pack claude-code exited with error"
fi

# ============================================================
# Test: Codex Pack (AT04)
# ============================================================
section "AT04: bridge.sh new --pack codex"

OUT="${TMPDIR_BASE}/codex"
mkdir -p "$OUT"

if bash "${BRIDGE_ROOT}/bridge.sh" new --name "E2E Codex Test" --pack codex -o "$OUT" >/dev/null 2>&1; then
  pass "bridge.sh new --pack codex exits 0"
  PROJECT="${OUT}/e2e-codex-test"

  # AGENTS.md
  if [[ -f "${PROJECT}/AGENTS.md" ]] && grep -q 'E2E Codex Test' "${PROJECT}/AGENTS.md"; then
    pass "AGENTS.md present with project name"
  else
    fail "AGENTS.md missing or project name not found"
  fi

  # 15 workflow skills
  SKILL_COUNT=$(ls -d "${PROJECT}/.agents/skills/"*/ 2>/dev/null | wc -l || echo 0)
  [[ "$SKILL_COUNT" -eq 15 ]] && pass "15 skill directories present" || fail "Expected 15 skills, got ${SKILL_COUNT}"

  # 6 procedures
  PROC_COUNT=$(ls "${PROJECT}/.agents/procedures/" 2>/dev/null | grep -c '.md$' || echo 0)
  [[ "$PROC_COUNT" -eq 6 ]] && pass "6 procedure files present" || fail "Expected 6 procedures, got ${PROC_COUNT}"

  # config.toml
  [[ -f "${PROJECT}/.codex/config.toml" ]] && pass "config.toml present" || fail "config.toml missing"

  # Placeholder
  if grep -rq '{{PROJECT_NAME}}' "$PROJECT" 2>/dev/null; then
    fail "{{PROJECT_NAME}} placeholder not fully replaced"
  else
    pass "All placeholders replaced"
  fi
else
  fail "bridge.sh new --pack codex exited with error"
fi

# ============================================================
# Test: Standalone Pack (AT02)
# ============================================================
section "AT02: bridge.sh new --pack standalone"

OUT="${TMPDIR_BASE}/standalone"
mkdir -p "$OUT"

if bash "${BRIDGE_ROOT}/bridge.sh" new --name "E2E Standalone Test" --pack standalone -o "$OUT" >/dev/null 2>&1; then
  pass "bridge.sh new --pack standalone exits 0"
  PROJECT="${OUT}/e2e-standalone-test"

  # 15 commands
  CMD_COUNT=$(ls "${PROJECT}/.roo/commands/" 2>/dev/null | grep -c '.md$' || echo 0)
  [[ "$CMD_COUNT" -eq 15 ]] && pass "15 command files present" || fail "Expected 15 commands, got ${CMD_COUNT}"

  # Commands are self-contained (bridge-start should be large)
  if [[ -f "${PROJECT}/.roo/commands/bridge-start.md" ]]; then
    LINE_COUNT=$(wc -l < "${PROJECT}/.roo/commands/bridge-start.md")
    [[ "$LINE_COUNT" -gt 50 ]] && pass "bridge-start.md is self-contained (${LINE_COUNT} lines)" || fail "bridge-start.md too short for standalone (${LINE_COUNT} lines)"
  else
    fail "bridge-start.md not found"
  fi

  # No skills directory
  if [[ -d "${PROJECT}/.roo/skills" ]]; then
    fail "Standalone pack should not have .roo/skills/"
  else
    pass "No .roo/skills/ directory (correct for standalone)"
  fi

  # Placeholder
  if grep -rq '{{PROJECT_NAME}}' "$PROJECT" 2>/dev/null; then
    fail "{{PROJECT_NAME}} placeholder not fully replaced"
  else
    pass "All placeholders replaced"
  fi
else
  fail "bridge.sh new --pack standalone exited with error"
fi

# ============================================================
# Test: OpenCode Pack (AT11)
# ============================================================
section "AT11: bridge.sh new --pack opencode"

OUT="${TMPDIR_BASE}/opencode"
mkdir -p "$OUT"

if bash "${BRIDGE_ROOT}/bridge.sh" new --name "E2E OpenCode Test" --pack opencode -o "$OUT" >/dev/null 2>&1; then
  pass "bridge.sh new --pack opencode exits 0"
  PROJECT="${OUT}/e2e-opencode-test"

  # AGENTS.md
  if [[ -f "${PROJECT}/AGENTS.md" ]] && grep -q 'E2E OpenCode Test' "${PROJECT}/AGENTS.md"; then
    pass "AGENTS.md present with project name"
  else
    fail "AGENTS.md missing or project name not found"
  fi

  # 15 commands
  CMD_COUNT=$(ls "${PROJECT}/.opencode/commands/" 2>/dev/null | grep -c '.md$' || echo 0)
  [[ "$CMD_COUNT" -eq 15 ]] && pass "15 command files present" || fail "Expected 15 commands, got ${CMD_COUNT}"

  # 6 skills
  SKILL_COUNT=$(ls -d "${PROJECT}/.opencode/skills/"*/ 2>/dev/null | wc -l || echo 0)
  [[ "$SKILL_COUNT" -eq 6 ]] && pass "6 skill directories present" || fail "Expected 6 skills, got ${SKILL_COUNT}"

  # 5 agents
  AGENT_COUNT=$(ls "${PROJECT}/.opencode/agents/" 2>/dev/null | grep -c '.md$' || echo 0)
  [[ "$AGENT_COUNT" -eq 5 ]] && pass "5 agent files present" || fail "Expected 5 agents, got ${AGENT_COUNT}"

  # Placeholder
  if grep -rq '{{PROJECT_NAME}}' "$PROJECT" 2>/dev/null; then
    fail "{{PROJECT_NAME}} placeholder not fully replaced"
  else
    pass "All placeholders replaced"
  fi
else
  fail "bridge.sh new --pack opencode exited with error"
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
    printf "    \033[31m-\033[0m %s\n" "$err"
  done
fi

echo ""
exit "$FAILED"

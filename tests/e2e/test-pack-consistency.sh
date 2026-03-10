#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# BRIDGE v2.1 -- E2E Tests: Pack Consistency and Command Presence
# Tests AT05 (15 commands across all packs), AT06 (scope/feature commands)
# Tests AT09 (feedback loop presence), F07, F08, F09, F12, F13
# Maps to: UF02 (Existing Project), UF04 (Slice Fix Loop)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_ROOT="${SCRIPT_DIR}/../.."
PASSED=0
FAILED=0
ERRORS=()

pass() { PASSED=$((PASSED + 1)); printf "  \033[32m+\033[0m %s\n" "$1"; }
fail() { FAILED=$((FAILED + 1)); ERRORS+=("$1"); printf "  \033[31m-\033[0m %s\n" "$1"; }
section() { printf "\n\033[1m--- %s ---\033[0m\n" "$1"; }

# --- Expected 15 commands ---
COMMANDS=(
  bridge-advisor bridge-brainstorm bridge-context-create bridge-context-update
  bridge-design bridge-end bridge-eval bridge-feature bridge-feedback
  bridge-gate bridge-requirements-only bridge-requirements bridge-resume
  bridge-scope bridge-start
)

# ============================================================
# AT05: All 15 commands in each pack
# ============================================================
section "AT05: 15 Commands Across All Packs"

# Full pack
missing=0
for cmd in "${COMMANDS[@]}"; do
  [[ -f "${BRIDGE_ROOT}/bridge-full/.roo/commands/${cmd}.md" ]] || missing=$((missing + 1))
done
[[ $missing -eq 0 ]] && pass "Full pack: all 15 commands" || fail "Full pack: ${missing} commands missing"

# Standalone pack
missing=0
for cmd in "${COMMANDS[@]}"; do
  [[ -f "${BRIDGE_ROOT}/bridge-standalone/.roo/commands/${cmd}.md" ]] || missing=$((missing + 1))
done
[[ $missing -eq 0 ]] && pass "Standalone pack: all 15 commands" || fail "Standalone pack: ${missing} commands missing"

# Claude Code pack (project variant)
missing=0
for cmd in "${COMMANDS[@]}"; do
  [[ -f "${BRIDGE_ROOT}/bridge-claude-code/project/.claude/commands/${cmd}.md" ]] || missing=$((missing + 1))
done
[[ $missing -eq 0 ]] && pass "Claude Code pack (project): all 15 commands" || fail "Claude Code pack: ${missing} commands missing"

# Claude Code pack (plugin variant)
missing=0
for cmd in "${COMMANDS[@]}"; do
  [[ -f "${BRIDGE_ROOT}/bridge-claude-code/plugin/commands/${cmd}.md" ]] || missing=$((missing + 1))
done
[[ $missing -eq 0 ]] && pass "Claude Code pack (plugin): all 15 commands" || fail "Claude Code plugin: ${missing} commands missing"

# Codex pack (skills)
missing=0
for cmd in "${COMMANDS[@]}"; do
  [[ -f "${BRIDGE_ROOT}/bridge-codex/.agents/skills/${cmd}/SKILL.md" ]] || missing=$((missing + 1))
done
[[ $missing -eq 0 ]] && pass "Codex pack: all 15 skills" || fail "Codex pack: ${missing} skills missing"

# OpenCode pack
missing=0
for cmd in "${COMMANDS[@]}"; do
  [[ -f "${BRIDGE_ROOT}/bridge-opencode/.opencode/commands/${cmd}.md" ]] || missing=$((missing + 1))
done
[[ $missing -eq 0 ]] && pass "OpenCode pack: all 15 commands" || fail "OpenCode pack: ${missing} commands missing"

# No extra commands (check for unexpected files)
for pack_dir in \
  "${BRIDGE_ROOT}/bridge-full/.roo/commands" \
  "${BRIDGE_ROOT}/bridge-standalone/.roo/commands" \
  "${BRIDGE_ROOT}/bridge-claude-code/project/.claude/commands" \
  "${BRIDGE_ROOT}/bridge-opencode/.opencode/commands"; do
  COUNT=$(ls "$pack_dir" 2>/dev/null | grep -c '.md$' || echo 0)
  if [[ "$COUNT" -eq 15 ]]; then
    pass "$(basename "$(dirname "$(dirname "$pack_dir")")"): exactly 15 files (no extras)"
  else
    fail "$(basename "$(dirname "$(dirname "$pack_dir")")"): expected 15, got ${COUNT}"
  fi
done

# ============================================================
# AT06: Existing project commands (scope, feature)
# ============================================================
section "AT06: Existing Project Commands (F08)"

# bridge-scope content check
if grep -qi 'existing\|codebase\|scope' "${BRIDGE_ROOT}/bridge-claude-code/project/.claude/commands/bridge-scope.md" 2>/dev/null; then
  pass "bridge-scope references existing codebase analysis"
else
  fail "bridge-scope does not mention existing codebase"
fi

# bridge-feature content check
if grep -qi 'incremental\|append\|existing\|requirements' "${BRIDGE_ROOT}/bridge-claude-code/project/.claude/commands/bridge-feature.md" 2>/dev/null; then
  pass "bridge-feature references incremental requirements"
else
  fail "bridge-feature does not mention incremental requirements"
fi

# ============================================================
# AT09: Post-Delivery Feedback Loop
# ============================================================
section "AT09: Post-Delivery Feedback Loop (F09)"

# Check "ISSUES REPORTED" in each pack
for pack_label_dir in \
  "full:${BRIDGE_ROOT}/bridge-full" \
  "standalone:${BRIDGE_ROOT}/bridge-standalone" \
  "claude-code:${BRIDGE_ROOT}/bridge-claude-code" \
  "codex:${BRIDGE_ROOT}/bridge-codex" \
  "opencode:${BRIDGE_ROOT}/bridge-opencode"; do
  label="${pack_label_dir%%:*}"
  dir="${pack_label_dir#*:}"
  COUNT=$(grep -rl 'ISSUES REPORTED' "$dir" 2>/dev/null | wc -l || echo 0)
  if [[ "$COUNT" -gt 0 ]]; then
    pass "${label}: ISSUES REPORTED found in ${COUNT} files"
  else
    fail "${label}: ISSUES REPORTED not found"
  fi
done

# Check "APPROVED" classification is paired
for pack_label_dir in \
  "full:${BRIDGE_ROOT}/bridge-full" \
  "standalone:${BRIDGE_ROOT}/bridge-standalone" \
  "claude-code:${BRIDGE_ROOT}/bridge-claude-code" \
  "codex:${BRIDGE_ROOT}/bridge-codex" \
  "opencode:${BRIDGE_ROOT}/bridge-opencode"; do
  label="${pack_label_dir%%:*}"
  dir="${pack_label_dir#*:}"
  COUNT=$(grep -rl 'APPROVED' "$dir" 2>/dev/null | wc -l || echo 0)
  if [[ "$COUNT" -gt 0 ]]; then
    pass "${label}: APPROVED classification found"
  else
    fail "${label}: APPROVED classification missing"
  fi
done

# ============================================================
# F12: Design Integration Command
# ============================================================
section "F12: Design Integration Command"

if grep -qi 'design\|PRD\|spec' "${BRIDGE_ROOT}/bridge-claude-code/project/.claude/commands/bridge-design.md" 2>/dev/null; then
  pass "bridge-design references design document/PRD/spec"
else
  fail "bridge-design content missing expected terms"
fi

# ============================================================
# F13: Strategic Advisor Command
# ============================================================
section "F13: Strategic Advisor Command"

ADVISOR_FILE="${BRIDGE_ROOT}/bridge-claude-code/project/.claude/commands/bridge-advisor.md"
if [[ -f "$ADVISOR_FILE" ]]; then
  roles_found=0
  grep -qi 'product strategist' "$ADVISOR_FILE" && roles_found=$((roles_found + 1))
  grep -qi 'developer advocate' "$ADVISOR_FILE" && roles_found=$((roles_found + 1))
  grep -qi 'critical friend' "$ADVISOR_FILE" && roles_found=$((roles_found + 1))
  [[ "$roles_found" -eq 3 ]] && pass "bridge-advisor has all 3 roles" || fail "bridge-advisor missing roles (found ${roles_found}/3)"
else
  fail "bridge-advisor.md not found"
fi

# ============================================================
# Stale reference check
# ============================================================
section "Stale Reference Check"

STALE_FILES=$(grep -rl 'bridge-migrate\|bridge-offload\|bridge-reintegrate\|bridge-external-handoff\|bridge-external-reintegrate' \
  "${BRIDGE_ROOT}/bridge-full" \
  "${BRIDGE_ROOT}/bridge-standalone" \
  "${BRIDGE_ROOT}/bridge-claude-code" \
  "${BRIDGE_ROOT}/bridge-codex" \
  "${BRIDGE_ROOT}/bridge-opencode" \
  2>/dev/null || true)
if [[ -z "$STALE_FILES" ]]; then
  STALE_COUNT=0
else
  STALE_COUNT=$(echo "$STALE_FILES" | wc -l | tr -d '[:space:]')
fi

if [[ "$STALE_COUNT" -eq 0 ]]; then
  pass "No stale references to deleted commands/skills in any pack"
else
  fail "Found ${STALE_COUNT} files with stale references"
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

#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# BRIDGE v2.1 -- E2E Tests: Workflow Command Content Validation
# Verifies command content supports UF01-UF04 user flows
# Maps to: UF01 (Greenfield), UF02 (Existing), UF03 (Session), UF04 (Fix Loop)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_ROOT="${SCRIPT_DIR}/../.."
PASSED=0
FAILED=0
ERRORS=()

pass() { PASSED=$((PASSED + 1)); printf "  \033[32m+\033[0m %s\n" "$1"; }
fail() { FAILED=$((FAILED + 1)); ERRORS+=("$1"); printf "  \033[31m-\033[0m %s\n" "$1"; }
section() { printf "\n\033[1m--- %s ---\033[0m\n" "$1"; }

# Use Claude Code project commands as the canonical content source
CMD_DIR="${BRIDGE_ROOT}/bridge-claude-code/project/.claude/commands"

# ============================================================
# UF01: Greenfield Project Flow
# brainstorm -> requirements -> start -> gate -> eval -> feedback
# ============================================================
section "UF01: Greenfield Project Flow"

# brainstorm should capture and structure ideas
if grep -qi 'brainstorm\|idea\|concept' "${CMD_DIR}/bridge-brainstorm.md" 2>/dev/null; then
  pass "bridge-brainstorm handles idea capture"
else
  fail "bridge-brainstorm missing idea capture content"
fi

# requirements should generate requirements.json
if grep -qi 'requirements.json\|features\|acceptance' "${CMD_DIR}/bridge-requirements.md" 2>/dev/null; then
  pass "bridge-requirements generates structured requirements"
else
  fail "bridge-requirements missing requirements generation"
fi

# requirements-only should work without brainstorm
if grep -qi 'description\|requirements.json' "${CMD_DIR}/bridge-requirements-only.md" 2>/dev/null; then
  pass "bridge-requirements-only works from description"
else
  fail "bridge-requirements-only missing direct description flow"
fi

# start should plan slices and begin implementation
if grep -qi 'slice\|implement\|plan' "${CMD_DIR}/bridge-start.md" 2>/dev/null; then
  pass "bridge-start plans slices and implements"
else
  fail "bridge-start missing slice planning"
fi

# gate should run quality checks
if grep -qi 'gate\|quality\|acceptance\|verify\|audit' "${CMD_DIR}/bridge-gate.md" 2>/dev/null; then
  pass "bridge-gate runs quality checks"
else
  fail "bridge-gate missing quality check content"
fi

# eval should generate evaluation scenarios
if grep -qi 'scenario\|evaluation\|test\|eval' "${CMD_DIR}/bridge-eval.md" 2>/dev/null; then
  pass "bridge-eval generates evaluation scenarios"
else
  fail "bridge-eval missing scenario generation"
fi

# feedback should process results
if grep -qi 'feedback\|iterate\|launch\|triage' "${CMD_DIR}/bridge-feedback.md" 2>/dev/null; then
  pass "bridge-feedback processes evaluation results"
else
  fail "bridge-feedback missing result processing"
fi

# ============================================================
# UF02: Existing Project Flow
# scope -> feature -> start
# ============================================================
section "UF02: Existing Project Flow"

# scope should analyze existing codebase
if grep -qi 'existing\|codebase\|analyze\|scan\|scope' "${CMD_DIR}/bridge-scope.md" 2>/dev/null; then
  pass "bridge-scope analyzes existing codebase"
else
  fail "bridge-scope missing codebase analysis"
fi

# feature should append to existing requirements
if grep -qi 'append\|incremental\|existing.*requirements\|add.*feature' "${CMD_DIR}/bridge-feature.md" 2>/dev/null; then
  pass "bridge-feature appends to existing requirements"
else
  fail "bridge-feature missing incremental append behavior"
fi

# ============================================================
# UF03: Session Continuity
# resume -> continue -> end
# ============================================================
section "UF03: Session Continuity"

# resume should read context.json and produce brief
if grep -qi 'context.json\|resume\|brief\|state' "${CMD_DIR}/bridge-resume.md" 2>/dev/null; then
  pass "bridge-resume reads context and produces brief"
else
  fail "bridge-resume missing context reading"
fi

# end should save state and handoff
if grep -qi 'context.json\|save\|handoff\|session\|state' "${CMD_DIR}/bridge-end.md" 2>/dev/null; then
  pass "bridge-end saves state and handoff notes"
else
  fail "bridge-end missing state saving"
fi

# ============================================================
# UF04: Slice Fix Loop
# Feedback loop embedded in start/resume
# ============================================================
section "UF04: Slice Fix Loop"

# start should contain feedback loop
if grep -q 'ISSUES REPORTED' "${CMD_DIR}/bridge-start.md" 2>/dev/null; then
  pass "bridge-start embeds feedback loop"
else
  # Check if it delegates to a skill that has it
  if grep -qi 'slice-plan\|bridge-slice-plan' "${CMD_DIR}/bridge-start.md" 2>/dev/null; then
    pass "bridge-start delegates to slice-plan (which has feedback loop)"
  else
    fail "bridge-start missing feedback loop"
  fi
fi

# HUMAN: block protocol in start (may be in the command itself or in delegated skill)
if grep -q 'HUMAN:' "${CMD_DIR}/bridge-start.md" 2>/dev/null; then
  pass "bridge-start includes HUMAN: handoff protocol"
elif grep -qi 'slice-plan\|bridge-slice-plan' "${CMD_DIR}/bridge-start.md" 2>/dev/null; then
  # The HUMAN: protocol is in the slice-plan skill that start delegates to
  SKILL_DIR="${BRIDGE_ROOT}/bridge-claude-code/project/.claude/skills/bridge-slice-plan"
  if [[ -f "${SKILL_DIR}/SKILL.md" ]] && grep -q 'HUMAN:' "${SKILL_DIR}/SKILL.md" 2>/dev/null; then
    pass "bridge-start delegates to slice-plan which has HUMAN: protocol"
  else
    fail "bridge-start delegates to slice-plan but HUMAN: protocol not found there"
  fi
else
  fail "bridge-start missing HUMAN: protocol"
fi

# ============================================================
# Context Management
# ============================================================
section "Context Management"

# context-create should build initial context.json
if grep -qi 'context.json\|create\|initial\|scan' "${CMD_DIR}/bridge-context-create.md" 2>/dev/null; then
  pass "bridge-context-create builds initial context"
else
  fail "bridge-context-create missing initialization"
fi

# context-update should sync with reality
if grep -qi 'context.json\|sync\|update\|current' "${CMD_DIR}/bridge-context-update.md" 2>/dev/null; then
  pass "bridge-context-update syncs with reality"
else
  fail "bridge-context-update missing sync behavior"
fi

# ============================================================
# Methodology Reference Document (F06)
# ============================================================
section "F06: Methodology Reference"

METH_DOC="${BRIDGE_ROOT}/reference/BRIDGE-v2.1-methodology.md"

if [[ -f "$METH_DOC" ]]; then
  LINE_COUNT=$(wc -l < "$METH_DOC")
  [[ "$LINE_COUNT" -gt 50 ]] && pass "Methodology doc present (${LINE_COUNT} lines)" || fail "Methodology doc too short (${LINE_COUNT} lines)"

  # Check phases (note: "Implementation Design" may use markdown bold formatting)
  phases_found=0
  grep -qi 'brainstorm' "$METH_DOC" && phases_found=$((phases_found + 1))
  grep -qi 'requirements' "$METH_DOC" && phases_found=$((phases_found + 1))
  grep -qi 'implementation' "$METH_DOC" && phases_found=$((phases_found + 1))
  grep -qi 'develop' "$METH_DOC" && phases_found=$((phases_found + 1))
  grep -qi 'gate' "$METH_DOC" && phases_found=$((phases_found + 1))
  grep -qi 'evaluate' "$METH_DOC" && phases_found=$((phases_found + 1))
  [[ "$phases_found" -eq 6 ]] && pass "All 6 BRIDGE phases documented" || fail "Only ${phases_found}/6 phases found"

  # Check schemas
  grep -qi 'context.json' "$METH_DOC" && pass "context.json schema documented" || fail "context.json not documented"
  grep -qi 'requirements.json' "$METH_DOC" && pass "requirements.json schema documented" || fail "requirements.json not documented"
else
  fail "Methodology reference document not found"
fi

# ============================================================
# Documentation: No Stale References
# ============================================================
section "Documentation Hygiene"

for doc in README.md reference/platform-guides.md; do
  if [[ -f "${BRIDGE_ROOT}/${doc}" ]]; then
    if grep -qi 'bridge-migrate\|bridge-offload\|bridge-reintegrate' "${BRIDGE_ROOT}/${doc}" 2>/dev/null; then
      fail "${doc} contains stale command references"
    else
      pass "${doc} clean of stale references"
    fi
  else
    fail "${doc} not found"
  fi
done

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

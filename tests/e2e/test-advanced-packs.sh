#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# BRIDGE v2.1 -- E2E Tests: Controller and Multi-Repo Packs
# Tests AT12 (Controller Pack), AT13 (Multi-Repo Pack)
# Maps to: UF05 (Portfolio Management), UF06 (Cross-Repo Feature)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_ROOT="${SCRIPT_DIR}/../.."
PASSED=0
FAILED=0
ERRORS=()

pass() { PASSED=$((PASSED + 1)); printf "  \033[32m+\033[0m %s\n" "$1"; }
fail() { FAILED=$((FAILED + 1)); ERRORS+=("$1"); printf "  \033[31m-\033[0m %s\n" "$1"; }
section() { printf "\n\033[1m--- %s ---\033[0m\n" "$1"; }

# ============================================================
# AT12: Controller Pack Structure (F14)
# ============================================================
section "AT12: Controller Pack (F14, UF05)"

CTRL="${BRIDGE_ROOT}/bridge-controller"

# CLAUDE.md
if [[ -f "${CTRL}/CLAUDE.md" ]]; then
  if grep -qi 'controller\|meta.*orchestrator\|portfolio' "${CTRL}/CLAUDE.md"; then
    pass "CLAUDE.md present with controller role"
  else
    fail "CLAUDE.md missing controller/portfolio terminology"
  fi
else
  fail "CLAUDE.md not found"
fi

# 3 commands
CTRL_COMMANDS=(bridge-init-project bridge-status bridge-sync)
missing=0
for cmd in "${CTRL_COMMANDS[@]}"; do
  [[ -f "${CTRL}/.claude/commands/${cmd}.md" ]] || missing=$((missing + 1))
done
[[ $missing -eq 0 ]] && pass "All 3 controller commands present" || fail "${missing} of 3 commands missing"

# Command count is exactly 3 (no extras)
CMD_COUNT=$(ls "${CTRL}/.claude/commands/" 2>/dev/null | grep -c '.md$' || echo 0)
[[ "$CMD_COUNT" -eq 3 ]] && pass "Exactly 3 command files (no extras)" || fail "Expected 3 commands, got ${CMD_COUNT}"

# bridge-status content: should reference .bridgeinclude
if grep -qi 'bridgeinclude' "${CTRL}/.claude/commands/bridge-status.md" 2>/dev/null; then
  pass "bridge-status references .bridgeinclude markers"
else
  fail "bridge-status does not mention .bridgeinclude"
fi

# Controller rules
if [[ -f "${CTRL}/.claude/rules/controller.md" ]]; then
  if grep -qi 'meta.*controller\|never.*application.*code\|portfolio' "${CTRL}/.claude/rules/controller.md"; then
    pass "Controller rules enforce meta-only scope"
  else
    fail "Controller rules missing scope constraints"
  fi
else
  fail "Controller rules file not found"
fi

# portfolio.json
[[ -f "${CTRL}/docs/portfolio.json" ]] && pass "portfolio.json template present" || fail "portfolio.json missing"

# Reference guide
[[ -f "${CTRL}/reference/controller-guide.md" ]] && pass "controller-guide.md present" || fail "controller-guide.md missing"

# Archive
[[ -f "${BRIDGE_ROOT}/bridge-controller.tar.gz" ]] && pass "bridge-controller.tar.gz archive exists" || fail "bridge-controller.tar.gz missing"

# CLAUDE.md should mention .bridgeinclude
if grep -qi 'bridgeinclude' "${CTRL}/CLAUDE.md" 2>/dev/null; then
  pass "CLAUDE.md documents .bridgeinclude discovery"
else
  fail "CLAUDE.md does not mention .bridgeinclude"
fi

# ============================================================
# AT13: Multi-Repo Pack -- Claude Code Variant (F15)
# ============================================================
section "AT13a: Multi-Repo Claude Code Variant (F15, UF06)"

MR_CC="${BRIDGE_ROOT}/bridge-multi-repo/claude-code"

# CLAUDE.md
if [[ -f "${MR_CC}/CLAUDE.md" ]]; then
  if grep -qi 'multi.*repo\|cross.*repo\|workspace' "${MR_CC}/CLAUDE.md"; then
    pass "Claude Code CLAUDE.md has multi-repo role"
  else
    fail "CLAUDE.md missing multi-repo terminology"
  fi
else
  fail "Claude Code CLAUDE.md not found"
fi

# 12 commands
CMD_COUNT=$(ls "${MR_CC}/.claude/commands/" 2>/dev/null | grep -c '.md$' || echo 0)
[[ "$CMD_COUNT" -eq 12 ]] && pass "12 commands present" || fail "Expected 12 commands, got ${CMD_COUNT}"

# 4 cross-repo commands
CROSS_CMDS=(bridge-cross-design bridge-cross-review bridge-cross-sync bridge-repo-status)
missing=0
for cmd in "${CROSS_CMDS[@]}"; do
  [[ -f "${MR_CC}/.claude/commands/${cmd}.md" ]] || missing=$((missing + 1))
done
[[ $missing -eq 0 ]] && pass "All 4 cross-repo commands present" || fail "${missing} of 4 cross-repo commands missing"

# Standard workflow commands
STANDARD_CMDS=(bridge-start bridge-resume bridge-end bridge-gate bridge-scope bridge-design bridge-context-update bridge-advisor)
missing=0
for cmd in "${STANDARD_CMDS[@]}"; do
  [[ -f "${MR_CC}/.claude/commands/${cmd}.md" ]] || missing=$((missing + 1))
done
[[ $missing -eq 0 ]] && pass "All 8 standard workflow commands present" || fail "${missing} of 8 standard commands missing"

# Multi-repo rules
if [[ -f "${MR_CC}/.claude/rules/multi-repo.md" ]]; then
  if grep -qi 'relative.*path\|branch.*coord\|cross.*repo' "${MR_CC}/.claude/rules/multi-repo.md"; then
    pass "Multi-repo rules enforce coordinated branches"
  else
    fail "Multi-repo rules missing branch coordination"
  fi
else
  fail "multi-repo.md rules file not found"
fi

# Docs templates
[[ -f "${MR_CC}/docs/context.json" ]] && pass "Workspace context.json template present" || fail "context.json missing"
[[ -f "${MR_CC}/docs/requirements.json" ]] && pass "Workspace requirements.json template present" || fail "requirements.json missing"

# Reference playbook
[[ -f "${MR_CC}/reference/multi-repo-playbook.md" ]] && pass "multi-repo-playbook.md present" || fail "playbook missing"

# Cross-design content check
if grep -qi 'contract\|schema\|migration' "${MR_CC}/.claude/commands/bridge-cross-design.md" 2>/dev/null; then
  pass "bridge-cross-design covers API contracts and migration"
else
  fail "bridge-cross-design missing contract/migration content"
fi

# Archive
[[ -f "${BRIDGE_ROOT}/bridge-multi-repo-claude-code.tar.gz" ]] && pass "bridge-multi-repo-claude-code.tar.gz exists" || fail "Archive missing"

# ============================================================
# AT13: Multi-Repo Pack -- Codex Variant (F15)
# ============================================================
section "AT13b: Multi-Repo Codex Variant (F15)"

MR_CX="${BRIDGE_ROOT}/bridge-multi-repo/codex"

# AGENTS.md
if [[ -f "${MR_CX}/AGENTS.md" ]]; then
  if grep -qi 'multi.*repo\|cross.*repo\|workspace' "${MR_CX}/AGENTS.md"; then
    pass "Codex AGENTS.md has multi-repo role"
  else
    fail "AGENTS.md missing multi-repo terminology"
  fi
else
  fail "Codex AGENTS.md not found"
fi

# 12 skills
SKILL_COUNT=$(ls -d "${MR_CX}/.agents/skills/"*/ 2>/dev/null | wc -l || echo 0)
[[ "$SKILL_COUNT" -eq 12 ]] && pass "12 skill directories present" || fail "Expected 12 skills, got ${SKILL_COUNT}"

# 4 cross-repo skills
CROSS_SKILLS=(bridge-cross-design bridge-cross-review bridge-cross-sync bridge-repo-status)
missing=0
for skill in "${CROSS_SKILLS[@]}"; do
  [[ -d "${MR_CX}/.agents/skills/${skill}" ]] || missing=$((missing + 1))
done
[[ $missing -eq 0 ]] && pass "All 4 cross-repo skills present" || fail "${missing} of 4 cross-repo skills missing"

# config.toml
[[ -f "${MR_CX}/.codex/config.toml" ]] && pass "config.toml present" || fail "config.toml missing"

# Docs templates
[[ -f "${MR_CX}/docs/context.json" ]] && pass "Workspace context.json template present" || fail "context.json missing"
[[ -f "${MR_CX}/docs/requirements.json" ]] && pass "Workspace requirements.json template present" || fail "requirements.json missing"

# Archive
[[ -f "${BRIDGE_ROOT}/bridge-multi-repo-codex.tar.gz" ]] && pass "bridge-multi-repo-codex.tar.gz exists" || fail "Archive missing"

# Skill names match claude-code command names
echo ""
echo "  Cross-checking skill names vs command names..."
CC_CMDS=$(ls "${MR_CC}/.claude/commands/" 2>/dev/null | sed 's/.md$//' | sort)
CX_SKILLS=$(ls "${MR_CX}/.agents/skills/" 2>/dev/null | sort)
if [[ "$CC_CMDS" == "$CX_SKILLS" ]]; then
  pass "Codex skill names match Claude Code command names"
else
  fail "Codex skill names differ from Claude Code command names"
fi

# ============================================================
# Cross-cutting: Two-phase gate in multi-repo
# ============================================================
section "Multi-Repo Gate: Two-Phase"

if grep -qi 'repo.*phase\|integration.*phase\|two.*phase\|per.*repo' "${MR_CC}/.claude/commands/bridge-gate.md" 2>/dev/null; then
  pass "Claude Code gate references two-phase (repo + integration)"
elif grep -qi 'repo.*phase\|integration.*phase\|two.*phase\|per.*repo' "${MR_CC}/CLAUDE.md" 2>/dev/null; then
  pass "Two-phase gate documented in CLAUDE.md"
else
  fail "Two-phase gate not documented"
fi

# ============================================================
# Package.sh builds all archives (AT10 extended)
# ============================================================
section "AT10: Package Script Archives"

EXPECTED_ARCHIVES=(
  bridge-full bridge-standalone bridge-claude-code
  bridge-codex bridge-opencode bridge-controller
  bridge-multi-repo-claude-code bridge-multi-repo-codex
  bridge-dual-agent
)

for archive in "${EXPECTED_ARCHIVES[@]}"; do
  if [[ -f "${BRIDGE_ROOT}/${archive}.tar.gz" ]]; then
    size=$(stat -c%s "${BRIDGE_ROOT}/${archive}.tar.gz" 2>/dev/null || stat -f%z "${BRIDGE_ROOT}/${archive}.tar.gz" 2>/dev/null)
    [[ "$size" -gt 1000 ]] && pass "${archive}.tar.gz (${size} bytes)" || fail "${archive}.tar.gz too small (${size} bytes)"
  else
    fail "${archive}.tar.gz not found"
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

#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# BRIDGE v2.2 -- E2E Tests: Shell Personality Overlays
# Tests F16, AT14, AT15
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_ROOT="${SCRIPT_DIR}/../.."
TMPDIR_BASE="$(mktemp -d)"
PASSED=0
FAILED=0
ERRORS=()

pass() { PASSED=$((PASSED + 1)); printf "  \033[32m+\033[0m %s\n" "$1"; }
fail() { FAILED=$((FAILED + 1)); ERRORS+=("$1"); printf "  \033[31m-\033[0m %s\n" "$1"; }
section() { printf "\n\033[1m--- %s ---\033[0m\n" "$1"; }

cleanup() {
  rm -rf "${TMPDIR_BASE}"
}
trap cleanup EXIT

section "bridge.sh new --personality strict"

STRICT_OUT="${TMPDIR_BASE}/strict"
mkdir -p "${STRICT_OUT}"

if bash "${BRIDGE_ROOT}/bridge.sh" new --name "Strict Persona" --pack claude-code --personality strict -o "${STRICT_OUT}" >/dev/null 2>&1; then
  pass "bridge.sh new --personality strict exits 0"
else
  fail "bridge.sh new --personality strict exited non-zero"
fi

STRICT_PROJECT="${STRICT_OUT}/strict-persona"
STRICT_ARCHITECT="${STRICT_PROJECT}/.claude/agents/bridge-architect.md"
STRICT_BRAINSTORM="${STRICT_PROJECT}/.claude/commands/bridge-brainstorm.md"
STRICT_ROOT="${STRICT_PROJECT}/CLAUDE.md"

if [[ -f "${STRICT_ARCHITECT}" ]] && grep -q '<!-- bridge:personality -->' "${STRICT_ARCHITECT}"; then
  pass "Strict architect file includes personality markers"
else
  fail "Strict architect file missing personality markers"
fi

if [[ -f "${STRICT_ARCHITECT}" ]] && grep -qi 'Challenges every abstraction' "${STRICT_ARCHITECT}"; then
  pass "Strict architect vibe injected"
else
  fail "Strict architect vibe missing"
fi

if [[ -f "${STRICT_BRAINSTORM}" ]] && grep -qi 'Kill criteria weighted heavily' "${STRICT_BRAINSTORM}"; then
  pass "Strict brainstorm vibe injected"
else
  fail "Strict brainstorm vibe missing"
fi

if [[ -f "${STRICT_ROOT}" ]] && grep -qi 'Tight scope enforcement' "${STRICT_ROOT}"; then
  pass "Strict orchestrator vibe injected into CLAUDE.md"
else
  fail "Strict orchestrator vibe missing from CLAUDE.md"
fi

section "bridge.sh add --personality mentoring"

MENTOR_TARGET="${TMPDIR_BASE}/existing"
mkdir -p "${MENTOR_TARGET}/src"
printf 'existing\n' > "${MENTOR_TARGET}/README.md"
printf 'keep-me\n' > "${MENTOR_TARGET}/src/app.txt"

if bash "${BRIDGE_ROOT}/bridge.sh" add --name "Mentor Persona" --pack claude-code --personality mentoring --target "${MENTOR_TARGET}" >/dev/null 2>&1; then
  pass "bridge.sh add --personality mentoring exits 0"
else
  fail "bridge.sh add --personality mentoring exited non-zero"
fi

MENTOR_ARCHITECT="${MENTOR_TARGET}/.claude/agents/bridge-architect.md"
MENTOR_ROOT="${MENTOR_TARGET}/CLAUDE.md"

if grep -q 'existing' "${MENTOR_TARGET}/README.md" && grep -q 'keep-me' "${MENTOR_TARGET}/src/app.txt"; then
  pass "Existing project files preserved during bridge.sh add"
else
  fail "Existing project files were overwritten during bridge.sh add"
fi

if [[ -f "${MENTOR_ARCHITECT}" ]] && grep -qi 'Walks through design options with rationale' "${MENTOR_ARCHITECT}"; then
  pass "Mentoring architect vibe injected"
else
  fail "Mentoring architect vibe missing"
fi

if [[ -f "${MENTOR_ROOT}" ]] && grep -qi 'Provides more context in HUMAN: blocks' "${MENTOR_ROOT}"; then
  pass "Mentoring orchestrator vibe injected into CLAUDE.md"
else
  fail "Mentoring orchestrator vibe missing from CLAUDE.md"
fi

section "Results"
echo ""
printf "  Passed: \033[32m%d\033[0m\n" "${PASSED}"
printf "  Failed: \033[31m%d\033[0m\n" "${FAILED}"

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo ""
  echo "  Failures:"
  for err in "${ERRORS[@]}"; do
    printf "    \033[31m-\033[0m %s\n" "${err}"
  done
fi

echo ""
exit "${FAILED}"

---
description: Gate review after Codex has implemented a task. Reads codex-findings.md, runs audit, updates context. Part of the dual-agent add-on.
---

# Bridge Gate (Dual-Agent) — Audit Codex's Work

You are acting as **auditor** in a dual-agent workflow.

## Steps

1. Read `docs/codex-findings.md` — understand what Codex did and any watch items
2. Read `docs/current-task.md` — verify the work matches the spec
3. Run the project's test suite and lint (from `context.json → commands_to_run`)
4. Check each acceptance criterion from `docs/current-task.md`
5. Review any **Watch out for** items Codex flagged — assess actual risk
6. Write decision to `docs/gate-report.md` (append, don't overwrite)
7. Update `docs/context.json` — gate_history entry + status

## Gate Decision

### PASS — if all of:
- Tests pass
- Acceptance criteria met
- Watch items assessed and acceptable or tracked

Update `context.json` feature status → `done`. Output:
```
GATE PASSED ✓

Feature: [ID] | Commit: [hash]
Tests: pass | Coverage: [%]
Watch items: [n] tracked in decisions.md

Next: /bridge-brief for next feature, or /bridge-slice-complete if slice done
```

### FAIL — if any criterion unmet or risk unacceptable:

Write specific fix tasks. Update `context.json` feature status → `in-progress`. Output:
```
GATE FAILED ✗

Reason: [specific failure]
Fix required:
  1. [exact issue and file]
  2. [exact issue and file]

Next: Share this with Codex → $bridge-receive (Codex will re-read current-task.md + this output)
```

Do not fix the issues yourself. Specify them precisely so Codex can act.

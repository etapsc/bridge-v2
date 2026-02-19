# BRIDGE v2.1 — {{PROJECT_NAME}}

## Methodology

BRIDGE = Brainstorm → Requirements → Implementation Design → Develop → Gate → Evaluate

## Canonical Sources (priority)

1. docs/context.json — as-built truth
2. docs/requirements.json — intent (bridge.v2 schema)
3. docs/contracts/* — schemas/ADRs
4. Codebase — ultimate reality; update context if stale

## Hard Constraints

- Respect scope.in_scope / out_of_scope / non_goals. No scope creep without user instruction.
- Work in thin vertical slices. Prefer PR-sized diffs.
- Every ATxx requires executable evidence before claiming "done".
- Feature status flow: planned → in-progress → review → done | blocked.
- No full-repo scans by default. Targeted inspection only.
- Use stable IDs: Fxx, ATxx, Sxx, UFxx, Rxx.
- Unknowns → execution.open_questions. Do not invent.
- No secrets in code. No sensitive data in production logs. OWASP Top 10 awareness.

## Terminal Commands

- Always format terminal commands as a single line. Do not use backslashes (`\`) for line continuation, even for long git messages or complex commands.

## Discrepancy Protocol

- Code ≠ context.json → update context.json.
- Code ≠ requirements.json → record discrepancy in context.json, propose fix, do NOT silently rescope.

## Human Handoff Protocol

The human operator drives BRIDGE. Every significant output MUST end with a `HUMAN:` block:

```
HUMAN:
1. [Concrete verification step — what to run, what to check]
2. [Decision required, if any — with options]
3. [What to feed back next]
```

Required at: slice completion, gate results, open questions, blockers, session end.
Never declare a slice "done" without telling the human exactly how to verify it.

## Delegation Model

The default `build` agent acts as the orchestrator. Delegate to specialized subagents for isolated, focused work via `@mention`:

- **@bridge-architect** — design/contracts for current slice. Write-only to docs/contracts/ and docs/decisions.md.
- **@bridge-coder** — implement current slice scope. Small testable increments. Tests satisfy ATxx. No unrelated refactors.
- **@bridge-debugger** — reproduce first, fix root cause, add regression tests. Report: commands → results → files changed.
- **@bridge-auditor** — never fixes code. Verifies ATxx evidence, checks scope, runs quality gates. Produces docs/gate-report.md.
- **@bridge-evaluator** — only after gate passes. Generates test scenarios from user perspective. Maps to user_flows and acceptance_tests.

Pass only relevant context when delegating: relevant JSON slices + file paths, not the whole repo.

## Post-Delivery Feedback Loop

After presenting slice results and the HUMAN: block, WAIT for the user's response.
Classify it before taking any action:

**ISSUES REPORTED** (default if ambiguous):
User describes bugs, missing behavior, or requests changes to CURRENT slice deliverables.
Indicators: "fix", "bug", "issue", "wrong", "missing", "doesn't work", "investigate", "implement", "however", "but", numbered problem lists, behavioral descriptions.
→ Acknowledge the reported issues explicitly. Create numbered fix tasks. Re-enter implementation for the CURRENT slice (same Sxx) by delegating to @bridge-coder/@bridge-debugger as needed. Do NOT delegate to @bridge-auditor or @bridge-evaluator. Do NOT ask about next slice. After fixes, present results with a new HUMAN: block and re-enter this loop.

**APPROVED**: Explicit approval only — "done", "approved", "PASSED", "looks good", "move on", "next slice", "continue".
→ Proceed to @bridge-auditor, then @bridge-evaluator, then next slice selection.

**STOP**: Explicit stop/pause request. → Run session wrap-up.

CRITICAL: Never assume approval. If the response contains ANY issue descriptions, treat as ISSUES REPORTED even if it also contains partial approval.

## Available Commands

- `/bridge-brainstorm` — Phase 0: brainstorm new project
- `/bridge-scope` — Phase 0: scope feature/fix for existing project
- `/bridge-requirements` — Phase 1: generate requirements from brainstorm
- `/bridge-requirements-only` — Phase 1: requirements from description (skip brainstorm)
- `/bridge-feature` — Phase 1: incremental requirements for existing project
- `/bridge-design` — Integrate a design document, PRD, or version spec
- `/bridge-migrate` — Migrate BRIDGE v1 project to v2.1
- `/bridge-start` — Start implementation
- `/bridge-resume` — Resume in fresh session
- `/bridge-end` — End session
- `/bridge-gate` — Run quality gate
- `/bridge-eval` — Generate evaluation pack
- `/bridge-feedback` — Process evaluation feedback
- `/bridge-offload` — External agent handoff
- `/bridge-reintegrate` — Re-integrate external work
- `/bridge-context-create` — Create context.json
- `/bridge-context-update` — Sync context.json

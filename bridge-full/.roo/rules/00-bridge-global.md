# BRIDGE v2.1 - Global Policy

## Canonical Sources (priority)
1. docs/context.json - as-built truth
2. docs/requirements.json - intent (bridge.v2)
3. docs/contracts/* - schemas/ADRs
4. Codebase - ultimate reality; update context if stale

## Hard Constraints
- Respect scope.in_scope / out_of_scope / non_goals. No scope creep without user instruction.
- Work in thin vertical slices. Prefer PR-sized diffs.
- Every ATxx requires executable evidence before claiming "done".
- Feature status flow: planned → in-progress → review → done | blocked.
- No full-repo scans by default. Targeted inspection only.
- Use stable IDs: Fxx, ATxx, Sxx, UFxx, Rxx.
- Unknowns → execution.open_questions. Do not invent.
- No secrets in code. No sensitive data in production logs. OWASP Top 10 awareness.

## Discrepancy Protocol
- Code ≠ context.json → update context.json.
- Code ≠ requirements.json → record discrepancy in context.json, propose fix, do NOT silently rescope.

## Human Handoff Protocol
The human operator drives BRIDGE. Every significant output MUST end with a `HUMAN:` block:

```
HUMAN:
1. [Concrete verification step — what to run, what to check]
2. [Decision required, if any — with options]
3. [What to feed back to RooCode next]
```

Required at:
- **Slice completion** — manual verification commands, what to smoke test, what to read
- **Gate results** — what to re-run yourself, what to inspect before trusting PASS
- **Open questions hit** — present options, ask human to decide, do NOT silently skip
- **Blockers or ambiguity** — surface immediately, don't guess
- **Session end** — what human should do before next session

Never declare a slice "done" without telling the human exactly how to verify it themselves.

## Project: {{PROJECT_NAME}}

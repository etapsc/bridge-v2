
---

## [DUAL-AGENT ADD-ON] — Codex Coordination

This project optionally runs with Codex as a parallel implementation agent.
When dual-agent mode is active, apply these additional rules:

**Your role shifts:** You are orchestrator and auditor. Codex is implementor.

**Before each feature:** Use `/bridge-brief` to write `docs/current-task.md` — do not implement the feature yourself.

**After Codex commits:** Use `/bridge-gate-dual` to read `docs/codex-findings.md` and run the gate.

**Ownership:**
- You own: `context.json`, `decisions.md`, `gate-report.md`, `current-task.md`
- Codex owns: `codex-findings.md`, all implementation commits

**Escalation:** If an issue is architectural and Codex cannot fix it, implement directly and note the escalation in `decisions.md`. Resume dual-agent on the next feature.

To disable dual-agent mode for a session, tell Claude Code: "single-agent mode — implement directly."

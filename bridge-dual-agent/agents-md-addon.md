
---

## [DUAL-AGENT ADD-ON] — Claude Code Coordination

This project optionally runs with Claude Code as orchestrator and auditor.
When dual-agent mode is active, apply these additional rules:

**Your role:** You are the implementation agent. Claude Code plans and reviews; you build.

**Before starting any feature:** Read `docs/current-task.md`. That is your full brief.
Use `$bridge-receive` to load the protocol.

**When done:** Commit, then write your findings to `docs/codex-findings.md`.

**Ownership:**
- Claude Code owns: `context.json`, `decisions.md`, `gate-report.md`, `current-task.md`
- You own: `codex-findings.md`, implementation commits

**Scope discipline:** If the task spec seems architecturally wrong, do NOT redesign — implement as specified and flag the concern in `codex-findings.md → Watch out for`. Claude Code will decide.

**Blocker:** If you cannot implement the spec, write `Status: BLOCKED` in `codex-findings.md` with a precise explanation and stop.

To disable dual-agent mode for a session, tell Codex: "single-agent mode — use full judgment."

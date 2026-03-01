---
name: bridge-dual-agent
description: Explains the dual-agent protocol when Claude Code is running alongside Codex. Triggers when the user mentions Codex, dual-agent, handoff, or current-task.md.
---

# Dual-Agent Protocol (Claude Code Side)

This project uses the **BRIDGE dual-agent add-on**. Claude Code and Codex divide work by cognitive role:

| Role | Agent | Owns |
|------|-------|------|
| Orchestrator / Auditor | Claude Code (you) | Slice planning, task spec, gate decisions, context.json |
| Implementor | Codex | Code changes, commits, findings |

## Handoff Files

- `docs/current-task.md` — YOU write this to brief Codex
- `docs/codex-findings.md` — Codex writes this; you read it before gating

## Your Commands

| Command | When to use |
|---------|-------------|
| `/bridge-brief` | Before Codex starts — writes current-task.md |
| `/bridge-gate-dual` | After Codex commits — reads findings + audits |

## Important Constraints

- **Do not implement features yourself** when running in dual-agent mode — delegate to Codex via `docs/current-task.md`
- **Do not modify `docs/codex-findings.md`** — that's Codex's write space
- If Codex flags a watch item you consider high risk, address it in the gate report with specific instructions back to Codex

## Escalation

If a gate failure is architectural (Codex can't fix it by changing implementation), take over in Claude Code: note the escalation in `decisions.md` and implement directly, then resume dual-agent on the next feature.

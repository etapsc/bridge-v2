# BRIDGE Dual-Agent Add-On

Optional overlay for BRIDGE v2.1 projects. Activates coordinated Claude Code + Codex workflows without modifying your existing pack.

## What It Does

Adds a file-based handoff layer between Claude Code (orchestrator/auditor) and Codex (implementor), with dedicated slash commands and skills for each agent.

```
Claude Code ──writes──▶ docs/current-task.md ──reads──▶ Codex
Codex ──writes──▶ docs/codex-findings.md ──reads──▶ Claude Code
```

## Install

```bash
bash install.sh
```

The script appends role sections to your existing `CLAUDE.md` and `AGENTS.md`, copies commands and skills into `.claude/` and `.agents/`, and creates the handoff doc templates in `docs/`.

## Uninstall

Remove the appended sections from `CLAUDE.md` and `AGENTS.md` (clearly marked with `## [DUAL-AGENT ADD-ON]` headers), delete the added commands/skills, and delete `docs/current-task.md` and `docs/codex-findings.md`.

## Usage

**Start a slice (in Claude Code):**
```
/bridge-brief
```
Claude Code reads `requirements.json` + `context.json`, writes a task spec to `docs/current-task.md`.

**Implement (in Codex):**
```
$bridge-receive
```
Codex reads `docs/current-task.md`, implements, commits, writes findings to `docs/codex-findings.md`.

**Gate (in Claude Code):**
```
/bridge-gate-dual
```
Claude Code reads `docs/codex-findings.md`, runs the audit, updates `context.json`.

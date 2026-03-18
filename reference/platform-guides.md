# BRIDGE Platform Guides

How to drive BRIDGE on each supported platform.

## How to Read This Guide

BRIDGE commands work in two modes:

- **Orchestrator-driven** — You invoke `/bridge-start` and the agent handles phase transitions (architect → coder → debugger → gate → eval) automatically. You interact via HUMAN: blocks.
- **Command-driven** — You invoke each command explicitly (`/bridge-gate`, `/bridge-eval`, etc.) to control exactly when phase transitions happen.

Both modes are valid. The orchestrator-driven flow is simpler; command-driven gives you more control. Every platform supports both.

---

## RooCode (Full Pack)

### Setup

```bash
./bridge.sh new --name "My Project" --pack full
```

Installs into your project:
- `.roomodes` — custom mode definitions (audit, evaluate)
- `.roo/rules-*` — persistent rules per mode (orchestrator, architect, code, debug, audit, evaluate)
- `.roo/commands/bridge-*.md` — 15 slash commands
- `docs/` — requirements.json, context.json, decisions.md, human-playbook.md

### Invocation

```
/bridge-brainstorm
/bridge-start
/bridge-gate
```

Slash commands in RooCode are typed in the chat input. The agent reads the command file and follows its instructions.

### Architecture

RooCode uses **mode switching** with persistent rules:

| Mode | Role | Rules File |
|------|------|-----------|
| orchestrator | Drives slices, coordinates | rules-orchestrator/00-orchestrator.md |
| architect | Designs contracts/ADRs | rules-architect/00-architect.md |
| code | Implements features + tests | rules-code/00-code.md |
| debug | Reproduces and fixes bugs | rules-debug/00-debug.md |
| audit | Quality gate checks (read-only) | rules-audit/00-audit.md |
| evaluate | Test scenarios + E2E tests | rules-evaluate/00-evaluate.md |

The orchestrator mode delegates to other modes during `/bridge-start`. Each mode inherits the global rules from `rules/00-bridge-global.md` plus its own role-specific rules.

### Greenfield Workflow

1. `/bridge-brainstorm` — Pitch your idea. Agent produces brainstorm document with kill criteria.
2. Review the brainstorm. Approve or refine.
3. `/bridge-requirements` — Agent generates `requirements.json` and `context.json`.
4. Review requirements. Adjust scope if needed.
5. `/bridge-start` — Agent plans slices, implements S01, delivers working code.
6. Test using the HUMAN: block instructions. Report issues or approve.
7. On approval: agent runs gate → eval → proceeds to S02.
8. Repeat steps 5-7 for each slice.
9. `/bridge-end` — Save session state when done.

### Existing Project Workflow

1. `/bridge-context-create` — Generate context.json from your existing codebase.
2. `/bridge-scope` or `/bridge-feature` — Scope the work you want to do.
3. `/bridge-requirements-only` — Generate requirements (skips brainstorm).
4. `/bridge-start` — Begin implementation.
5. Follow steps 5-9 from the greenfield workflow.

### Session Continuity

- `/bridge-resume` — Start a new chat session. Agent loads context.json and outputs a brief.
- `/bridge-end` — End session. Agent updates handoff state in context.json.

### Tips

- The orchestrator handles mode transitions automatically. You rarely need to switch modes manually.
- Use HUMAN: blocks as your verification checklist — run exactly what the agent tells you to run.
- `/bridge-gate` can be invoked explicitly if you want to run a quality check before the orchestrator triggers it.
- `/bridge-advisor` works in any mode — use it for strategic review at any point.

---

## RooCode (Standalone Pack)

### Setup

```bash
./bridge.sh new --name "My Project" --pack standalone
```

Installs into your project:
- `.roomodes` — custom mode definitions
- `.roo/commands/bridge-*.md` — 15 slash commands (self-contained, full prompts)
- `docs/` — requirements.json, context.json, decisions.md, human-playbook.md

### Differences from Full Pack

| Aspect | Full Pack | Standalone Pack |
|--------|-----------|----------------|
| Rules | Persistent per-mode rules in `.roo/rules-*` | No rules files — all instructions in command prompts |
| Commands | Thin — reference rules | Self-contained — full prompt in each command |
| Context usage | Lower per-message (rules loaded once) | Higher per-message (full prompt every time) |
| Setup complexity | More files | Fewer files |

### When to Choose Standalone

- Quick setup or evaluation
- You want all instructions visible in command files (no hidden rules)
- Portability — easier to inspect and modify
- You don't need persistent cross-command rules

The workflows (greenfield, existing project, session continuity) are identical to the full pack. Same commands, same phases, same HUMAN: blocks.

---

## Claude Code

### Setup

```bash
./bridge.sh new --name "My Project" --pack claude-code
```

Installs into your project:
- `CLAUDE.md` — project instructions (methodology, constraints, delegation model)
- `.claude/commands/bridge-*.md` — 15 slash commands
- `.claude/agents/bridge-*.md` — 5 subagent definitions
- `.claude/skills/bridge-*/SKILL.md` — 6 composable skills
- `.claude/rules/` — security.md, methodology.md
- `.claude/settings.json` — agent configuration
- `docs/` — requirements.json, context.json, decisions.md, human-playbook.md

### Invocation

```
/bridge-brainstorm
/bridge-start
/bridge-gate
```

Slash commands in Claude Code are typed with `/` prefix in the CLI. The agent reads the command file and follows its instructions.

### Architecture

Claude Code uses **subagent delegation**. The main session acts as orchestrator and spawns specialized agents:

| Subagent | File | Role |
|----------|------|------|
| bridge-architect | `.claude/agents/bridge-architect.md` | Design contracts, schemas, ADRs |
| bridge-coder | `.claude/agents/bridge-coder.md` | Implement features + tests |
| bridge-debugger | `.claude/agents/bridge-debugger.md` | Reproduce, fix, add regression tests |
| bridge-auditor | `.claude/agents/bridge-auditor.md` | Quality gate checks (never fixes code) |
| bridge-evaluator | `.claude/agents/bridge-evaluator.md` | Test scenarios + E2E tests |

Each subagent gets isolated context — only the relevant JSON slices and file paths, not the whole repo. This keeps context windows focused and reduces noise.

### Greenfield Workflow

1. `/bridge-brainstorm` — Pitch your idea. Agent produces brainstorm document.
2. Review the brainstorm. Approve or refine.
3. `/bridge-requirements` — Agent generates `requirements.json` and `context.json`.
4. Review requirements. Adjust scope if needed.
5. `/bridge-start` — Agent plans slices, delegates to bridge-architect → bridge-coder. Delivers working code.
6. Test using the HUMAN: block instructions. Report issues or approve.
7. On approval: agent delegates to bridge-auditor (gate) → bridge-evaluator (eval) → proceeds to next slice.
8. Repeat steps 5-7 for each slice.
9. `/bridge-end` — Save session state.

### Existing Project Workflow

1. `/bridge-context-create` — Generate context.json from your existing codebase.
2. `/bridge-scope` or `/bridge-feature` — Scope the work.
3. `/bridge-requirements-only` — Generate requirements (skips brainstorm).
4. `/bridge-start` — Begin implementation.
5. Follow steps 5-9 from the greenfield workflow.

### Session Continuity

- `/bridge-resume` — Start a new session. Agent loads context.json and outputs a brief.
- `/bridge-end` — End session. Agent updates handoff state in context.json.

### Tips

- You CAN invoke `/bridge-gate` and `/bridge-eval` directly — the orchestrator delegates to subagents automatically, but explicit commands give you more control over phase transitions.
- Subagents run in isolated context. If a subagent needs info it doesn't have, the orchestrator will pass it.
- `/bridge-advisor` works anytime — use it for an honest strategic review of your project.
- The fix loop works the same as other platforms: report issues → agent stays on current slice → fixes → re-delivers.

---

## Codex

### Setup

```bash
./bridge.sh new --name "My Project" --pack codex
```

Installs into your project:
- `AGENTS.md` — project instructions (methodology, constraints, role modes)
- `.agents/skills/bridge-*/SKILL.md` — 15 skill definitions
- `.agents/procedures/bridge-*.md` — 6 procedure definitions
- `.codex/config.toml` — Codex configuration
- `docs/` — requirements.json, context.json, decisions.md, human-playbook.md

### Invocation

```
$bridge-brainstorm
$bridge-start
$bridge-gate
```

Skills in Codex are invoked with `$` prefix. Type `$` to see the skill list, then select or type the skill name.

### Architecture

Codex uses a **single-agent with role modes**. There are no subagents — instead, the agent switches between conceptual roles (orchestrator, architect, coder, debugger, auditor, evaluator) based on what the current skill/procedure requires.

Procedures (`.agents/procedures/`) define multi-step workflows that skills can invoke internally. For example, `$bridge-start` triggers the `bridge-slice-plan` procedure which coordinates the architect → coder → debugger flow within a single agent context.

### Greenfield Workflow

1. `$bridge-brainstorm` — Pitch your idea. Agent produces brainstorm document.
2. Review the brainstorm. Approve or refine.
3. `$bridge-requirements` — Agent generates `requirements.json` and `context.json`.
4. Review requirements. Adjust scope if needed.
5. `$bridge-start` — Agent plans slices, implements S01, delivers working code.
6. Test using the HUMAN: block instructions. Report issues or approve.
7. On approval: agent runs gate → eval → proceeds to next slice.
8. Repeat steps 5-7 for each slice.
9. `$bridge-end` — Save session state.

### Existing Project Workflow

1. `$bridge-context-create` — Generate context.json from your existing codebase.
2. `$bridge-scope` or `$bridge-feature` — Scope the work.
3. `$bridge-requirements-only` — Generate requirements (skips brainstorm).
4. `$bridge-start` — Begin implementation.
5. Follow steps 5-9 from the greenfield workflow.

### Session Continuity

- `$bridge-resume` — Start a new session. Agent loads context.json and outputs a brief.
- `$bridge-end` — End session. Agent updates handoff state in context.json.

### Tips

- `$bridge-start` drives the full slice lifecycle. Call `$bridge-gate` explicitly when you want to run a quality check outside the normal flow.
- Since Codex is single-agent, all context lives in one window. This means the agent has full visibility but also a larger context load — keep slices thin.
- `$bridge-advisor` provides strategic review at any point.
- The fix loop works identically: report issues in response to HUMAN: blocks → agent stays on current slice → fixes → re-delivers.

---

## Command Reference Matrix

| Command | RooCode | Claude Code | Codex | Phase | Typical Predecessor |
|---------|---------|-------------|-------|-------|-------------------|
| bridge-brainstorm | `/bridge-brainstorm` | `/bridge-brainstorm` | `$bridge-brainstorm` | Phase 0 | — (entry point) |
| bridge-requirements | `/bridge-requirements` | `/bridge-requirements` | `$bridge-requirements` | Phase 1 | brainstorm |
| bridge-requirements-only | `/bridge-requirements-only` | `/bridge-requirements-only` | `$bridge-requirements-only` | Phase 1 | — (skips brainstorm) |
| bridge-scope | `/bridge-scope` | `/bridge-scope` | `$bridge-scope` | Phase 0 | — (existing project) |
| bridge-feature | `/bridge-feature` | `/bridge-feature` | `$bridge-feature` | Phase 1 | scope |
| bridge-design | `/bridge-design` | `/bridge-design` | `$bridge-design` | Phase 1 | requirements |
| bridge-context-create | `/bridge-context-create` | `/bridge-context-create` | `$bridge-context-create` | Setup | — (existing project) |
| bridge-context-update | `/bridge-context-update` | `/bridge-context-update` | `$bridge-context-update` | Any | after code changes |
| bridge-start | `/bridge-start` | `/bridge-start` | `$bridge-start` | Phase 2 | requirements |
| bridge-gate | `/bridge-gate` | `/bridge-gate` | `$bridge-gate` | Phase 3 | slice complete |
| bridge-eval | `/bridge-eval` | `/bridge-eval` | `$bridge-eval` | Phase 4 | gate PASS |
| bridge-feedback | `/bridge-feedback` | `/bridge-feedback` | `$bridge-feedback` | Phase 5 | eval + human testing |
| bridge-resume | `/bridge-resume` | `/bridge-resume` | `$bridge-resume` | Session | — (new session) |
| bridge-end | `/bridge-end` | `/bridge-end` | `$bridge-end` | Session | — (end session) |
| bridge-advisor | `/bridge-advisor` | `/bridge-advisor` | `$bridge-advisor` | Any | — (strategic review) |

# BRIDGE v2.2

**B**rainstorm → **R**equirements → **I**mplementation Design → **D**evelop → **G**ate → **E**valuate

A structured development methodology for AI coding agents. Ships as ready-to-use packs for Claude Code, RooCode, Codex, and OpenCode.

## Why BRIDGE?

AI coding agents are powerful, but without structure you get scope creep, context loss, and no quality signal. Every new chat starts from zero. You're shipping and praying.

BRIDGE fixes this by wrapping your AI agent in a disciplined lifecycle:

- **Brainstorm** with kill criteria — know when to stop before you start
- **Requirements** as structured JSON — not scattered across chat history
- **Thin vertical slices** — PR-sized increments, not thousand-line diffs
- **Quality gates** — evidence-based completion, not "looks good to me"
- **Feedback loops** — the agent fixes current issues before moving on
- **Session continuity** — resume exactly where you left off

It's not another prompt collection. It's a complete methodology with 15 commands, role-based delegation, and cross-platform portability.

### What's new in v2.2

- **Personality overlays** — shell installs can apply `strict`, `balanced`, or `mentoring` tone overlays to the orchestrator, advisor, brainstorm flow, and agent definitions
- **Unified shell entrypoint** — `bridge.sh` now covers new project setup, existing-project install, orchestrators, and archive packaging
- **Human handoff enforcement** — every agent now outputs `HUMAN:` blocks so you always know what to verify next

## Example Session

```text
you:   /bridge-brainstorm
agent: [analyzes idea, produces pitch, wedge, kill criteria, architecture sketch]
       HUMAN: Review the brainstorm. Approve to continue, or refine.

you:   /bridge-requirements
agent: [generates requirements.json with features, acceptance tests, user flows]
       HUMAN: Review requirements. Adjust scope if needed.

you:   /bridge-start
agent: [plans slices, implements S01, delivers working code]
       HUMAN: Test the login endpoint. Run: curl -X POST /api/login

you:   "The endpoint returns 500 when email is empty"
agent: [stays on S01 — does NOT move to S02]
       [fixes validation, adds test, re-delivers]
       HUMAN: Retry: curl -X POST /api/login -d '{}'

you:   "Approved"
agent: [runs quality gate → PASS → generates eval scenarios → proceeds to S02]
```

The key insight: BRIDGE keeps the agent in a fix loop on the current slice until you explicitly approve. No more chasing an agent that moved on while bugs remain.

## Quick Start

### Option A: Unified shell installer

```bash
# Remote one-liner — downloads the pack from GitHub Releases
curl -fsSL https://raw.githubusercontent.com/etapsc/bridge/main/bridge.sh | bash -s -- \
  new --pack claude-code --name "My Project" --personality strict

# Or clone and run locally
git clone https://github.com/etapsc/bridge.git
cd bridge
./bridge.sh new --name "My Project" --pack claude-code --personality strict
```

### Option B: Manual copy

Each pack is a self-contained folder. Copy its contents into your project root:

```bash
# From a cloned repo
cp -r bridge-claude-code/. /path/to/your-project/

# From a release archive
tar -xzf bridge-claude-code.tar.gz -C /path/to/your-project/
```

Then find-and-replace `{{PROJECT_NAME}}` with your project name in all `.md` and `.json` files.

## What Gets Installed

Every pack installs two things into your project root:

1. **A top-level config file** — tells the AI agent about BRIDGE methodology, delegation rules, and workflow constraints
2. **A `docs/` folder** — template `requirements.json`, `context.json`, `human-playbook.md`, and `decisions.md`

Some packs also install platform-specific tooling under a hidden directory. Here's what each pack contains:

### Claude Code (`bridge-claude-code/`)

```
your-project/
├── CLAUDE.md                          # Methodology rules, delegation model, feedback loop
├── .claude/
│   ├── agents/                        # 5 subagent definitions
│   │   ├── bridge-architect.md        #   design contracts and interfaces
│   │   ├── bridge-coder.md            #   implement slices with tests
│   │   ├── bridge-debugger.md         #   diagnose and fix failures
│   │   ├── bridge-auditor.md          #   quality gate verification (read-only)
│   │   └── bridge-evaluator.md        #   generate test scenarios
│   ├── commands/                      # 15 slash commands (/bridge-*)
│   ├── skills/                        # 6 composable skills
│   ├── hooks/                         # 3 lifecycle hooks
│   │   ├── session-start.sh           #   check context.json freshness on startup
│   │   ├── auto-approve-cd-git.sh     #   auto-approve safe git read commands
│   │   └── post-edit-lint.sh          #   auto-lint after file edits
│   ├── rules/                         # persistent rules (methodology, security)
│   └── settings.json                  # permissions, hook configuration
└── docs/
    ├── requirements.json              # structured project requirements (bridge.v2 schema)
    ├── context.json                   # as-built project state and handoff
    ├── human-playbook.md              # verification procedures (generated)
    └── decisions.md                   # architectural decision log
```

**How to use:** Run `claude` in your project directory. All 15 `/bridge-*` commands are available immediately. Start with `/bridge-brainstorm` for a new idea or `/bridge-requirements-only` to jump straight to requirements.

### RooCode Full (`bridge-full/`)

Rules + skills for VS Code with the RooCode extension. Uses mode-switching (orchestrator, architect, code, debug, audit, evaluate). Smaller context per message.

### RooCode Standalone (`bridge-standalone/`)

Self-contained slash commands with full prompts embedded. No rules or skills needed — everything is in the command prompts. Good for portability.

### Codex (`bridge-codex/`)

`AGENTS.md` + skills for the OpenAI Codex CLI. Single-agent with skill invocation via `$skill-name`.

### OpenCode (`bridge-opencode/`)

`AGENTS.md` + agents + skills + commands for the OpenCode CLI. Subagents via `@mention`, native skill discovery.

## Packs at a Glance

| Pack | Config File | Agent Model | Best For |
|------|-------------|-------------|----------|
| `claude-code` | `CLAUDE.md` + `.claude/` | Subagents (5 roles) | Claude Code CLI users |
| `full` | `.roo/rules/` + `.roo/skills/` | Mode-switching (7 modes) | RooCode in VS Code |
| `standalone` | Self-contained commands | Single-agent | Quick RooCode setup |
| `codex` | `AGENTS.md` + `.agents/` | Single-agent + skills | OpenAI Codex CLI |
| `opencode` | `AGENTS.md` + `opencode.json` | Subagents + commands | OpenCode CLI |

## Setup Commands

The unified `bridge.sh` script supports these subcommands:

| Command | Purpose |
|---------|---------|
| `new` | Create a new project directory with BRIDGE tooling |
| `add` | Add BRIDGE to an existing project (won't overwrite `docs/`, `src/`, `tests/`) |
| `orchestrator` | Install a portfolio controller or multi-repo workspace |
| `pack` | Rebuild `.tar.gz` archives from source folders (maintainers) |

```bash
# Examples
bridge.sh new  --name "My API" --pack claude-code --personality strict
bridge.sh add  --name "My API" --pack claude-code --target . --personality mentoring
bridge.sh new  --name "My App" --pack full -o ~/projects
bridge.sh orchestrator
bridge.sh pack
```

Source resolution is automatic: local folder → local `.tar.gz` → GitHub Releases download.

## Slash Commands

Once installed, these commands are available inside your AI agent:

| Command | Purpose |
|---------|---------|
| `/bridge-brainstorm` | Phase 0: brainstorm a new idea with kill criteria |
| `/bridge-requirements` | Phase 1: generate requirements from brainstorm output |
| `/bridge-requirements-only` | Phase 1: generate requirements (skip brainstorm) |
| `/bridge-scope` | Phase 0: scope a feature/fix for an existing project |
| `/bridge-feature` | Phase 1: incremental requirements for existing project |
| `/bridge-design` | Integrate a design document, PRD, or version spec |
| `/bridge-start` | Start implementation — plan slices, delegate to agents |
| `/bridge-context-create` | Create `context.json` from codebase |
| `/bridge-context-update` | Sync `context.json` with code reality |
| `/bridge-resume` | Resume a session — load context, output re-entry brief |
| `/bridge-end` | End session — update handoff state |
| `/bridge-gate` | Run quality gate audit |
| `/bridge-eval` | Generate evaluation scenarios and E2E tests |
| `/bridge-feedback` | Process evaluation feedback — iterate or launch |
| `/bridge-advisor` | Strategic project review and launch readiness check |

## Typical Flow

```
/bridge-brainstorm → /bridge-requirements
         │
         ▼
/bridge-start ──→ [develop slices] → /bridge-gate
                                          │
                                ┌─────────┴─────────┐
                                ▼                   ▼
                             [FAIL]              [PASS]
                                │                   │
                                ▼                   ▼
                          [fix → gate]       /bridge-eval
                                                    │
                                                    ▼
                                              [human tests]
                                                    │
                                                    ▼
                                            /bridge-feedback
                                                    │
                                          ┌─────────┴─────────┐
                                          ▼                   ▼
                                       [issues]           [ready]
                                          │                   │
                                          ▼                   ▼
                                    [back to dev]         LAUNCH

Session: /bridge-resume (start) · /bridge-end (stop)
Context: /bridge-context-create · /bridge-context-update
```

## Advanced Setups

### Multi-Repo Projects

If your product spans multiple repositories, use `bridge.sh orchestrator` to set up a cross-repo workspace with a single BRIDGE control plane. See **[reference/multi-repo-playbook.md](reference/multi-repo-playbook.md)**.

### Dual-Agent (Claude Code + Codex)

Use `bridge.sh add --pack dual-agent` to overlay coordination commands on an existing Claude Code or Codex install. Claude handles architecture and coding; Codex handles research and validation.

### Platform Guides

Each platform has a different architecture (mode-switching, subagents, single-agent) and invocation syntax. See **[reference/platform-guides.md](reference/platform-guides.md)** for detailed workflows and a full command reference matrix.

## Model Recommendations (RooCode)

| Role | Mode | Model | Reasoning |
|------|------|-------|-----------|
| Orchestrator | `orchestrator` | Gemini 3.1 Pro | Standard |
| Architect | `architect` | Opus 4.6 | Reasoning |
| Developer | `code` | Opus 4.6 | Reasoning |
| Debugger | `debug` | Sonnet 4.6 | Reasoning |
| Auditor | `audit` | GPT-5.3 Codex | Medium |
| Evaluator | `evaluate` | Opus 4.6 | Standard |
| Ask | `ask` | GPT 5.2 | Low |

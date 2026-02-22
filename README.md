# BRIDGE v2.1

**B**rainstorm → **R**equirements → **I**mplementation Design → **D**evelop → **G**ate → **E**valuate

A structured development workflow for AI coding agents. Works across RooCode, Claude Code, Codex, and OpenCode.

## Why BRIDGE?

AI coding agents are powerful, but without structure you get scope creep, context loss, and no quality signal. Every new chat starts from zero. You're shipping and praying.

BRIDGE fixes this by wrapping your AI agent in a disciplined lifecycle:

- **Brainstorm** with kill criteria — know when to stop before you start
- **Requirements** as structured JSON — not scattered across chat history
- **Thin vertical slices** — PR-sized increments, not thousand-line diffs
- **Quality gates** — evidence-based completion, not "looks good to me"
- **Feedback loops** — the agent fixes current issues before moving on
- **Session continuity** — resume exactly where you left off

It's not another prompt collection. It's a complete methodology with 18 commands, role-based delegation, and cross-platform portability.

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

## Packs

| Pack | Description | When to Use |
|------|-------------|-------------|
| `full/` | Thin slash commands + persistent rules + composable skills for **RooCode**. | Recommended for RooCode users. Smaller context per message, consistent behavior. |
| `standalone/` | Self-contained slash commands with full prompts for **RooCode**. No rules or skills. | Quick RooCode setup, portability, or if you prefer all instructions in prompts. |
| `claude-code/` | CLAUDE.md + subagent definitions + skills + commands for **Claude Code CLI**. | Use with the `claude` CLI. Leverages subagents for isolated context per role. |
| `codex/` | AGENTS.md + skills for **OpenAI Codex CLI**. | Use with the `codex` CLI. Single-agent with skill invocation via `$skill-name`. |
| `opencode/` | AGENTS.md + agents + skills + commands for **OpenCode CLI**. | Use with the `opencode` CLI. Subagents via `@mention`, native skill discovery. |

## Quick Start (remote install)

```bash
# One-liner — downloads the pack from GitHub Releases
curl -fsSL https://raw.githubusercontent.com/etapsc/bridge-v2/main/setup.sh | bash -s -- \
  --pack claude-code --name "My Project"

# With a specific version
curl -fsSL https://raw.githubusercontent.com/etapsc/bridge-v2/main/setup.sh | bash -s -- \
  --pack claude-code --name "My Project" --version v2.1.0

# With a custom output directory
curl -fsSL https://raw.githubusercontent.com/etapsc/bridge-v2/main/setup.sh | bash -s -- \
  --pack full --name "My Project" -o ~/projects
```

## Setup (from cloned repo)

```bash
git clone https://github.com/etapsc/bridge-v2.git
cd bridge-v2

# Interactive
./setup.sh

# Or specify options directly
./setup.sh --name "My Project" --pack full          # RooCode (rules+skills)
./setup.sh --name "My Project" --pack standalone    # RooCode (self-contained)
./setup.sh --name "My Project" --pack claude-code   # Claude Code CLI
./setup.sh --name "My Project" --pack codex         # OpenAI Codex CLI
./setup.sh --name "My Project" --pack opencode      # OpenCode CLI
```

The script auto-detects its source:

- **Local folder** — copies directly from `bridge-{pack}/` (fastest, for development)
- **Local tar** — extracts from `bridge-{pack}.tar.gz` (offline use)
- **Remote** — downloads from GitHub Releases (curl one-liner)

## Quick Reference

| Slash Command | Mode | Purpose |
|---------------|------|---------|
| `/bridge-brainstorm` | any | Phase 0: brainstorm a new idea |
| `/bridge-requirements` | any | Phase 1: generate requirements from brainstorm |
| `/bridge-requirements-only` | any | Phase 1: generate requirements (skip brainstorm) |
| `/bridge-scope` | orchestrator | Phase 0: scope a feature/fix for an existing project |
| `/bridge-feature` | orchestrator | Phase 1: incremental requirements for existing project |
| `/bridge-design` | orchestrator | Integrate a design document, PRD, or version spec |
| `/bridge-migrate` | orchestrator | Migrate existing BRIDGE v1 project to v2.1 |
| `/bridge-start` | orchestrator | Start implementation from requirements |
| `/bridge-context-create` | orchestrator | Create context.json from codebase |
| `/bridge-context-update` | orchestrator | Sync context.json with code reality |
| `/bridge-resume` | orchestrator | Fresh session re-entry with brief |
| `/bridge-end` | orchestrator | End session, update handoff |
| `/bridge-gate` | audit | Run quality gate |
| `/bridge-eval` | evaluate | Generate evaluation pack |
| `/bridge-feedback` | orchestrator | Process evaluation feedback |
| `/bridge-offload` | orchestrator | Prepare external agent handoff |
| `/bridge-reintegrate` | orchestrator | Re-integrate external agent work |
| `/bridge-advisor` | any | Strategic project review and launch readiness |

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
                                    [back to dev]         LAUNCH 🚀

Session: /bridge-resume (start) · /bridge-end (stop)
Context: /bridge-context-create · /bridge-context-update
External: /bridge-offload · /bridge-reintegrate
```

## Model Recommendations

| Role | Mode | Model | Reasoning |
|------|------|-------|-----------|
| Orchestrator | `orchestrator` | Gemini 3.1 Pro | Standard |
| Architect | `architect` | Opus 4.6 | Reasoning |
| Developer | `code` | Opus 4.6 | Reasoning |
| Debugger | `debug` | GPT-5.3 Codex | Medium |
| Auditor | `audit` | GPT-5.3 Codex | Medium |
| Evaluator | `evaluate` | Opus 4.6 | Standard |
| Ask | `ask` | GPT 5.2 | Low |

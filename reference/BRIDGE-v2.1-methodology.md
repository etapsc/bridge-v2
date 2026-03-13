# BRIDGE v2.1 Methodology

**B**rainstorm → **R**equirements → **I**mplementation Design → **D**evelop → **G**ate → **E**valuate

## Overview

BRIDGE is a methodology for solo-preneur software development using AI coding agents (RooCode). It provides structured phases, role-based delegation, and quality gates to produce production-ready software.

## Phases

| Phase | Location | Modes Used | Output |
|-------|----------|------------|--------|
| 0. Brainstorm | Outside RooCode or /bridge-brainstorm | orchestrator | Pitch, wedge, kill criteria, architecture, market analysis |
| 1. Requirements | /bridge-requirements or /bridge-requirements-only | orchestrator | requirements.json + context.json |
| 2. Develop | /bridge-start | orchestrator → architect → code → debug | Working code in vertical slices |
| 3. Gate | /bridge-gate | audit | gate-report.md with PASS/FAIL |
| 4. Evaluate | /bridge-eval | evaluate | eval-scenarios.md, E2E tests, feedback template |
| 5. Feedback | /bridge-feedback | orchestrator | Issue triage, iterate or launch decision |

## Roles & Models

| Role | Mode Slug | Model | Reasoning |
|------|-----------|-------|-----------|
| Orchestrator | orchestrator | Gemini 3 Pro | Standard |
| Architect | architect | Opus 4.6 | Reasoning |
| Developer | code | Opus 4.6 | Reasoning |
| Debugger | debug | GPT-5.2 Codex | Medium |
| Auditor | audit (custom) | GPT-5.2 Codex | Medium |
| Evaluator | evaluate (custom) | Opus 4.6 | Standard |
| Ask | ask | GPT 5.2 | Low |

## Key Principles

1. **Thin Vertical Slices** - Design → implement → verify one slice at a time. PR-sized diffs.
2. **Stable IDs** - Fxx (features), ATxx (acceptance tests), Sxx (slices), UFxx (user flows), Rxx (risks).
3. **Evidence-based Completion** - Every ATxx maps to executable evidence (test + result).
4. **Scope Discipline** - Respect in_scope/out_of_scope/non_goals. No creep without user instruction.
5. **Context Discipline** - No full-repo scans. Targeted inspection. Minimal context passed to sub-modes.
6. **Discrepancy Protocol** - Code is reality. Context tracks reality. Requirements track intent. Conflicts are recorded, not silently resolved.

## JSON Schemas

### requirements.json (bridge.v2)
[See docs/requirements.json skeleton]

### context.json (context.v1)
[See docs/context.json skeleton]

## Slash Commands Quick Reference

| Command | Mode | Purpose |
|---------|------|---------|
| /bridge-brainstorm | orchestrator | Brainstorm new idea |
| /bridge-requirements | orchestrator | Generate requirements from brainstorm |
| /bridge-requirements-only | orchestrator | Generate requirements from description |
| /bridge-scope | orchestrator | Scope a feature/fix for existing project |
| /bridge-feature | orchestrator | Incremental requirements for existing project |
| /bridge-design | orchestrator | Integrate a design document, PRD, or version spec |
| /bridge-start | orchestrator | Start implementation |
| /bridge-context-create | orchestrator | Create context.json |
| /bridge-context-update | orchestrator | Sync context.json |
| /bridge-resume | orchestrator | Resume in fresh session |
| /bridge-end | orchestrator | End session |
| /bridge-gate | audit | Quality gate |
| /bridge-eval | evaluate | Generate eval pack |
| /bridge-feedback | orchestrator | Process feedback |
| /bridge-advisor | orchestrator | Strategic product and launch review |

## Typical Flow

```
/bridge-brainstorm → /bridge-requirements
         │
         ▼
/bridge-start ──→ [slices] → /bridge-gate
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
                            [iterate]             LAUNCH 🚀
```

## Post-Delivery Feedback Loop

After each slice, the orchestrator ends with a `HUMAN:` block that tells the operator exactly what to verify, what decision is needed, and what to feed back next.

When the human responds, classify the result before taking any action:

- **ISSUES REPORTED**: Bugs, missing behavior, regressions, investigation requests, or any ambiguous feedback. Stay on the current slice, create fix tasks, re-implement, and present a new `HUMAN:` block. Do not move to gate/evaluate.
- **APPROVED**: Explicit approval only ("done", "PASSED", "looks good", "continue", "next slice"). Proceed to gate/evaluate or the next slice.
- **STOP**: Explicit pause or stop request. Save state and hand off the current status.

This loop is strict: never assume approval when the feedback includes problems. Issue reports always win over partial praise.

## Two Packs

| Pack | Contents | Use When |
|------|----------|----------|
| standalone/ | Self-contained slash commands (full prompts). No rules/skills. | Quick setup, portability |
| full/ | Thin slash commands + rules (policy) + skills (procedures). | Recommended for serious projects |

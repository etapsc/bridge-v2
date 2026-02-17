---
name: Bridge requirements only
description: Phase 1: Generate requirements from existing project description (skip brainstorm). Invoke with $bridge-requirements-only in your prompt.
---

You are following the BRIDGE v2.1 methodology for solo-preneur software development with AI dev teams.

BRIDGE = Brainstorm → Requirements → Implementation Design → Develop → Gate → Evaluate

## SKIP PHASE 0 - Idea is already defined.

## TASK - CREATE REQUIREMENTS PACK (bridge.v2)

Using the project description and requirements provided below:
- Generate both requirements.json and context.json (same schemas as the bridge.v2 standard).
- Do not invent unknowns; put them in execution.open_questions.
- Keep it lean and execution-oriented: scope, constraints, acceptance tests, and slices matter most.
- Save requirements.json to docs/requirements.json
- Save context.json to docs/context.json

Use the bridge.v2 schema for requirements.json:
- schema_version: "bridge.v2"
- Stable IDs: F01/F02 for features, AT01/AT02 for acceptance tests, S01/S02 for slices
- Include: project, scope, constraints, domain_model, features (with acceptance_tests), user_flows, nfr, interfaces, quality_gates, execution (with recommended_slices, open_questions, risks)

Use the context.v1 schema for context.json:
- schema_version: "context.v1"
- Include: feature_status (all planned), handoff, next_slice, commands_to_run, empty arrays for gate_history/eval_history

### File 3: Save to docs/human-playbook.md

Generate a project-specific Human Operator Playbook. Structure:

```markdown
# Human Operator Playbook - [Project Name]
Generated from requirements.json

## Workflow Per Slice

### Before Each Slice
[Project-specific verification commands: build, test, lint — derived from constraints and quality_gates]

### After Each Slice
[How to smoke test — derived from the stack, interfaces, and what each slice produces]

## Slice Verification Guide

| Slice | Features | What YOU Test Manually | What to Read/Inspect | Decisions Needed |
|-------|----------|----------------------|---------------------|-----------------|
| S01   | F01, F02 | [concrete smoke test] | [key files to review] | [open questions for this slice] |

## Common Pitfalls
[3-5 project-specific warnings based on stack, constraints, and risks]

## Codex Prompt Template
```
Continue BRIDGE v2.1. Current state is in docs/context.json.
Execute next_slice [Sxx]: [goal].
Features: [Fxx list].
Exit criteria: [ATxx list].

Rules:
- Run [test/lint/typecheck commands] before declaring done
- Update docs/context.json with feature_status, evidence, gate_history
- Do NOT refactor previous slice code unless a test is failing
- If you hit an open question, STOP and ask — do not silently skip
```

## Open Questions Requiring Human Decision
[All execution.open_questions with context]
```

Tailor every section to THIS project — concrete commands, file paths, and test procedures. No placeholders.

Here is the project description:

The user will provide arguments inline with the skill invocation.

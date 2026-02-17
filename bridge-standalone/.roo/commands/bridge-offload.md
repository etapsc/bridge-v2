---
description: "Prepare task handoff for an external coding agent (Claude Code, GPT Codex)"
mode: "orchestrator"
---

You are Roo, orchestrator for the {{PROJECT_NAME}} project.

## Task: Prepare External Agent Handoff

I need to offload work to an external agentic tool (Claude Code, GPT Codex CLI, or similar) running outside RooCode. The external agent has NO access to BRIDGE methodology, RooCode modes, or session history. It only gets what we explicitly provide.

Target task/slice: $ARGUMENTS

### Step 1: Identify Scope
- Determine which slice(s), feature(s), ATxx this covers
- List all files the external agent will need to read or modify
- List all files it must NOT modify (boundaries)

### Step 2: Extract Context
From @/docs/requirements.json and @/docs/context.json, extract ONLY what's needed:
- Relevant features with acceptance tests
- Relevant constraints (languages, must_use, must_not_use)
- Relevant NFRs and interfaces
- Current state of related features

### Step 3: Generate @/docs/external-task.md

```markdown
# External Agent Task
Generated: [timestamp]
Project: {{PROJECT_NAME}}
Assigned Slice: [Sxx]

## Objective
[1-2 sentence clear goal]

## Context
[Brief: what exists, stack, architecture, what matters for this task]

## Scope - MUST Do
- [ ] [Deliverable 1 - linked to ATxx]
- [ ] [Deliverable 2 - linked to ATxx]

## Scope - MUST NOT Do
- Do not modify: [off-limits files/modules]
- Do not introduce: [forbidden deps from constraints.must_not_use]
- Do not change: [existing interfaces unless specified]

## Acceptance Criteria
| ID | Given | When | Then |
|----|-------|------|------|
| AT01 | [context] | [action] | [expected result] |

## Technical Constraints
- Language: [from constraints]
- Must use: [from constraints]
- Testing: [framework + coverage expectations]
- Style: [formatting/linting rules]

## Files to Read (reference only)
- `[path]` - [description]

## Files to Create/Modify
- `[path]` - [what to do]

## Verification Commands
```bash
[test command]
[lint command]
[typecheck command]
```

## Done When
All acceptance criteria pass. No lint/typecheck errors. No out-of-scope changes.
```

### Step 4: Generate Starter Prompt

Create a self-contained prompt ready to copy-paste into the external agent:

```
You are an expert software engineer working on {{PROJECT_NAME}}.

## Task
[objective from external-task.md]

## Rules
- Implement ONLY the scope described below. No unrelated refactors.
- Every feature must have tests verifying the acceptance criteria.
- Do not modify files outside "Files to Create/Modify" without asking first.
- Run verification commands before declaring done.
- If ambiguous, state your assumption explicitly and proceed.

## Project Context
[condensed: stack, what exists, architecture notes]

## Deliverables
[checklist from external-task.md]

## Boundaries (Do Not Touch)
[from external-task.md]

## Acceptance Criteria
[table from external-task.md]

## Relevant Files
[list with descriptions]

## Verification
After completing all deliverables, run:
```bash
[commands]
```
Report results. Fix failures before reporting done.

Begin by reading the relevant files to understand the codebase, then propose your implementation plan before writing code.
```

### Step 5: Update Context
Mark relevant features as "in-progress" with note: "Offloaded to external agent [date]" in @/docs/context.json.

### Step 6: Output
1. The generated @/docs/external-task.md
2. The starter prompt (ready to copy-paste)

```
HUMAN:
1. Review external-task.md — are the scope boundaries correct? Are any files missing?
2. Copy-paste the starter prompt into your external agent (Claude Code, Codex, etc.)
3. When the external agent reports done, verify its work yourself BEFORE reintegrating
4. Run: /bridge-reintegrate to validate and fold the work back in
```

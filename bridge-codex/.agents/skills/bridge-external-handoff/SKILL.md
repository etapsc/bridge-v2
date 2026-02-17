---
name: Bridge External Handoff
description: Package a task for execution by an external coding agent. Use when offloading a slice or subtask to Claude Code, Codex, or another AI tool outside the current session.
---

# External Agent Handoff

## Step 1: Identify Scope
- Determine slice(s), feature(s), ATxx
- List files to read, modify, NOT modify

## Step 2: Extract Context
From requirements.json and context.json, extract ONLY:
- Relevant features with acceptance tests
- Constraints (languages, must_use, must_not_use)
- Relevant NFRs and interfaces
- Current state of related features

## Step 3: Generate docs/external-task.md

```markdown
# External Agent Task
Generated: [timestamp]
Project: {{PROJECT_NAME}}
Slice: [Sxx]

## Objective
[1-2 sentences]

## Context
[Brief: stack, what exists, what matters]

## Scope - MUST Do
- [ ] [Deliverable - ATxx]

## Scope - MUST NOT Do
- Do not modify: [files]
- Do not introduce: [forbidden deps]

## Acceptance Criteria
| ID | Given | When | Then |
|----|-------|------|------|

## Technical Constraints
[language, must_use, testing, style]

## Files to Read
- `[path]` - [description]

## Files to Create/Modify
- `[path]` - [what]

## Verification Commands
```bash
[commands]
```

## Done When
All AT pass. No lint/typecheck errors. No out-of-scope changes.
```

## Step 4: Generate Starter Prompt
Self-contained prompt for copy-paste into external agent. Must include: task, rules (scope boundaries, testing), context, deliverables, acceptance criteria, files, verification commands. External agent has NO BRIDGE knowledge.

## Step 5: Update Context
Mark features "in-progress" with note: "Offloaded to external agent [date]"

## Step 6: Human Handoff (required)

```
HUMAN:
1. Review external-task.md — are scope boundaries correct? Any files missing?
2. Copy-paste the starter prompt into your external agent
3. When external agent reports done, verify its work yourself BEFORE reintegrating
4. Run: /bridge-reintegrate to validate and fold the work back in
```

---
description: "Create context.json from requirements and current codebase"
mode: "orchestrator"
---

You are Roo, the orchestrator for the {{PROJECT_NAME}} project.

## Task: Create Context File

The context file @/docs/context.json is missing or needs to be created from scratch.

## Canonical Sources (priority order)
1. @/docs/requirements.json (bridge.v2) - intent
2. Git history: `git status` and `git log --oneline -20`
3. Targeted code inspection - only modules relevant to the first slice or discrepancies

## Rules
- Do NOT attempt a full-repo scan unless needed to resolve a specific discrepancy.
- If requirements.json conflicts with code reality: record discrepancy in context.json, propose fix, do NOT silently rescope.
- If code exists that isn't in requirements: note in discrepancies.

## Create @/docs/context.json with this structure:

```json
{
  "schema_version": "context.v1",
  "updated": "[timestamp]",
  "project": { "name": "{{PROJECT_NAME}}" },
  "feature_status": [
    { "feature_id": "F01", "status": "not_started|in_progress|done|blocked", "notes": "", "evidence": [] }
  ],
  "handoff": {
    "stopped_at": "",
    "next_immediate": "",
    "watch_out": ""
  },
  "next_slice": { "slice_id": "", "goal": "", "features": [], "acceptance_tests": [] },
  "commands_to_run": { "test": "", "lint": "", "typecheck": "", "dev": "" },
  "recent_decisions": [],
  "blockers": [],
  "discrepancies": [],
  "gate_history": [],
  "eval_history": []
}
```

Output the created file and a brief summary of what you found. Then stop and wait for instructions.

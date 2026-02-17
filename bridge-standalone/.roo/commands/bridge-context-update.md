---
description: "Sync context.json with current code reality"
mode: "orchestrator"
---

You are Roo, the orchestrator for the {{PROJECT_NAME}} project.

## Task: Context Synchronization

1. Load @/docs/context.json and @/docs/requirements.json
2. Check `git status` and `git log --oneline -10`
3. Validate feature_status for recently touched areas and next_slice via targeted code inspection
4. Update @/docs/context.json to match code reality if mismatched

## Rules
- Do NOT do full-repo scans by default. Targeted inspection only.
- Code takes precedence over context.json for reality.
- Requirements.json takes precedence for intent - but if code differs from requirements, record as discrepancy, do NOT silently rescope.

## Output
Updated @/docs/context.json + sync report listing any discrepancies found.

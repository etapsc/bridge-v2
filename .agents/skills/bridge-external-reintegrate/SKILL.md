---
name: Bridge External Reintegrate
description: Validate and re-integrate work from an external coding agent. Use after an offloaded task is complete and needs to be folded back into the project.
---

# External Agent Re-integration

## Step 1: Review
- Load docs/external-task.md for scope and criteria
- Run `git diff` / `git status`
- Verify changes within declared scope

## Step 2: Validate
- Run verification commands from external-task.md
- Check each ATxx has passing evidence
- Flag out-of-scope modifications

## Step 3: Report
```
EXTERNAL WORK INTEGRATION
Slice: [Sxx]
Status: [INTEGRATED | NEEDS FIXES | REJECTED]
Acceptance Tests: ✓/✗ per ATxx
Scope Compliance: [CLEAN | VIOLATIONS]
Verification: Tests/Lint/Typecheck [pass/fail]
Next: [proceed | fix | /bridge-gate]
```

## Step 4: Update Context
- Update feature_status with evidence
- Update handoff and next_slice
- Archive external-task.md

## Step 5: Decision
- All pass + clean → next slice or /bridge-gate
- Issues → tasks for code/debug
- Scope violations → revert, targeted fix tasks

## Step 6: Human Handoff (required)

```
HUMAN:
1. Verify the integration report — run [test/lint commands] yourself
2. Check git diff for any out-of-scope changes the report may have missed
3. [If INTEGRATED] Proceed with: /bridge-gate or next slice
4. [If NEEDS FIXES] Review the specific issues, then feed fix instructions back
```

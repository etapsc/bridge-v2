---
description: "Re-integrate and validate work completed by an external coding agent"
mode: "orchestrator"
---

You are Roo, orchestrator for the {{PROJECT_NAME}} project.

## Task: Re-integrate External Agent Work

An external agent completed work described in @/docs/external-task.md.

### Step 1: Review Changes
- Load @/docs/external-task.md for scope and acceptance criteria
- Run `git diff` or `git status` to see what changed
- Verify changes are within the declared scope boundaries

### Step 2: Validate
- Run verification commands from external-task.md
- Check each acceptance criterion (ATxx) has passing evidence
- Flag any out-of-scope modifications

### Step 3: Report

```
EXTERNAL WORK INTEGRATION

Slice: [Sxx]
Status: [INTEGRATED | NEEDS FIXES | REJECTED]

Acceptance Tests:
✓ ATxx - [description] - [evidence]
✗ ATxx - [description] - [gap]

Scope Compliance: [CLEAN | VIOLATIONS: list]

Verification:
- Tests: [pass/fail]
- Lint: [pass/fail]
- Typecheck: [pass/fail]

Next: [proceed to next slice | fix issues | run /bridge-gate]
```

### Step 4: Update Context
- Update feature_status in @/docs/context.json with evidence
- Update handoff and next_slice
- Archive: rename external-task.md to external-task-[Sxx]-done.md or delete

### Step 5: Decision
- All ATxx pass + scope clean → proceed to next slice or /bridge-gate
- Issues found → create tasks for code/debug mode
- Scope violations → revert out-of-scope changes, create targeted fix tasks

### Step 6: Human Handoff

```
HUMAN:
1. Verify the integration report — run [test/lint commands] yourself
2. Check git diff for any out-of-scope changes the report may have missed
3. [If INTEGRATED] Proceed with: /bridge-gate or next slice
4. [If NEEDS FIXES] Review the specific issues, then feed fix instructions back
```

$ARGUMENTS

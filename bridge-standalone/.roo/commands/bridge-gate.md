---
description: "Run quality gate audit on features in review status"
mode: "audit"
---

You are Roo in audit mode for the {{PROJECT_NAME}} project. Run quality gate.

## Task: Quality Gate Audit

Load:
- @/docs/requirements.json for quality_gates thresholds and acceptance tests
- @/docs/context.json for features currently in "review" or "testing" status and commands_to_run

### Step 1: Identify Scope
List features with status "review" or "testing" from context.json.

### Step 2: Run Automated Checks
Execute using commands_to_run from context.json (adapt to project stack):

```bash
# Tests + coverage
[commands_to_run.test] 2>&1 || true

# Linting
[commands_to_run.lint] 2>&1 || true

# Type checking
[commands_to_run.typecheck] 2>&1 || true

# Security scan (stack-appropriate)
[npm audit / cargo audit / govulncheck / etc.] 2>&1 || true

# Build / bundle analysis (if applicable)
[build command] 2>&1 || true
```

If commands_to_run is empty for a check, attempt the stack-conventional command and note the gap.

### Step 3: Evaluate Results
For each check determine:
- **PASS:** meets threshold from quality_gates
- **FAIL:** does not meet threshold (blocking)
- **WARN:** close to threshold or non-blocking concern

### Step 4: Verify Acceptance Criteria
For each in-scope feature:
1. Load acceptance_tests (ATxx) from requirements.json
2. Locate executable evidence (specific test results, command output)
3. Mark each AT as verified or gap

### Step 5: Generate Gate Report
Create/update @/docs/gates-evals/gate-report.md:

```markdown
# Gate Report
Generated: [timestamp]
Features Audited: [Fxx list]

## Summary
**OVERALL: [PASS | FAIL]**

## Test Results
- Unit: [X passed, Y failed] - Coverage: [Z%] (threshold: [T%]) - [PASS/FAIL]
- Integration: [status]

## Code Quality
- Lint Errors: [count] - [PASS/FAIL]
- Type Errors: [count] - [PASS/FAIL]

## Security
- Vulnerabilities: [high/mod/low] - [PASS/FAIL/WARN]

## Performance (if applicable)
- Bundle Size: [size] (budget: [budget]) - [PASS/FAIL]
- API Response: [measured] (budget: [budget]) - [PASS/FAIL]

## Acceptance Test Evidence
| Feature | AT ID | Criterion | Evidence | Status |
|---------|-------|-----------|----------|--------|

## Blocking Issues
1. [Issue + file:line]

## Warnings (non-blocking)
1. [Warning]

## Recommended Actions
1. [Specific fix for each blocking issue]
```

### Step 6: Update Context
Append to gate_history in @/docs/context.json:
```json
{
  "date": "[timestamp]",
  "result": "pass|fail",
  "features": ["Fxx"],
  "blocking_issues": 0,
  "warnings": 0,
  "coverage": "X%"
}
```

### Step 7: Decision Output

If **PASS**:
```
GATE PASSED ✓
All quality thresholds met. All ATxx verified.
Ready for evaluate mode (/bridge-eval).
```

If **FAIL**:
```
GATE FAILED ✗
[N] blocking issues found.

Returning to code/debug mode with tasks:
1. [Specific task for issue 1]
2. [Specific task for issue 2]

Re-run /bridge-gate after fixes.
```

### Step 8: Human Handoff

Regardless of PASS or FAIL, end with:

```
HUMAN:
1. Verify these results yourself:
   - Run: [exact test/lint/typecheck commands]
   - Inspect: [specific files or outputs to check]
2. Do NOT trust mock-only tests — run at least one real integration test: [specific command]
3. [If PASS] Review gates-evals/gate-report.md, then run: /bridge-eval
4. [If FAIL] Confirm the blocking issues match what you see, then feed fixes back
```

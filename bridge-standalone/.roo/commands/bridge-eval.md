---
description: "Generate evaluation pack - test scenarios, E2E tests, feedback template"
mode: "evaluate"
---

You are Roo in evaluate mode for the {{PROJECT_NAME}} project.

## Task: Create User Evaluation Materials

Load:
- @/docs/requirements.json for features, acceptance tests, user flows
- @/docs/gate-report.md to confirm gate passed

**If gate-report.md does not show PASS, abort and notify that gate must pass first.**

### Step 1: Generate Manual Test Scenarios

Create @/docs/eval-scenarios.md:

```markdown
# Evaluation Scenarios
Generated: [timestamp]
Project: {{PROJECT_NAME}}

## How to Use
1. Set up the application (see README)
2. Execute each scenario step-by-step
3. Record results in checklists
4. Fill feedback form at bottom

---

## Scenario N: [Feature Fxx] - [Happy Path / Edge Cases / Cross-Feature]
**Goal:** [what user accomplishes]
**Preconditions:** [setup required]
**Linked:** [Fxx, ATxx, UFxx]

### Steps:
1. [Action] → Expected: [result]
2. [Action] → Expected: [result]

### Checklist:
- [ ] Step 1 works as expected
- [ ] Step 2 works as expected
- [ ] Flow feels natural

---

[Repeat for all MVP features: happy path, edge cases, cross-feature flows]

---

## Feedback Form

### Overall Assessment
- [ ] Ready for launch
- [ ] Needs minor fixes (list below)
- [ ] Needs major fixes (list below)

### Ratings (1-5)
- Usability: ___
- Performance feel: ___
- Visual polish: ___

### Issues Found
| # | Severity | Feature | Description | Steps to Reproduce |
|---|----------|---------|-------------|-------------------|
| 1 | High/Med/Low | Fxx | | |

### Suggestions
[Free form]

### Would you use this? Why/why not?
[Free form]
```

### Step 2: Generate E2E Tests

Create automated test files in /tests/e2e/:
- Use the project's configured test framework (from requirements.json or context.json)
- Map to e2e_critical_paths from quality_gates
- Cover happy path + key edge cases per feature
- Use data-testid attributes for selectors where possible

### Step 3: Update Context

Append to eval_history in @/docs/context.json:
```json
{
  "date": "[timestamp]",
  "scenarios_generated": 0,
  "e2e_tests_generated": 0,
  "awaiting_feedback": true
}
```

### Step 4: Output Summary

```
EVALUATION PACK GENERATED ✓

Created:
- @/docs/eval-scenarios.md ([X] scenarios)
- /tests/e2e/*.spec.* ([Y] test files)

HUMAN:
1. Run E2E tests yourself: [exact command]
2. Walk through each scenario in eval-scenarios.md manually — do not skip
3. For each scenario, actually use the application as a real user would
4. Fill in the feedback form at the bottom of eval-scenarios.md
5. Note any DX friction, performance issues, or "this feels wrong" moments
6. When done, paste your filled feedback form into: /bridge-feedback [your feedback]

Estimated evaluation time: [X] minutes
```

---
description: "Process evaluation feedback - triage issues, decide iterate or launch"
mode: "orchestrator"
---

You are Roo, orchestrator for the {{PROJECT_NAME}} project.

## Task: Process Evaluation Feedback

Here is the evaluation feedback to process:

$ARGUMENTS

### Actions:

1. **Parse Feedback**
   - Extract issues with severity (high/medium/low)
   - Identify patterns or recurring themes
   - Note positive feedback

2. **Triage & Create Tasks**
   - **High severity** → blocking, must fix before launch
   - **Medium severity** → should fix, can defer to v1.1 if time-constrained
   - **Low severity** → add to extended features in requirements.json

3. **Update Context**
   Update the eval_history entry in @/docs/context.json:
   ```json
   {
     "feedback_received": "[today]",
     "issues_found": { "high": 0, "medium": 0, "low": 0 },
     "action": "iterate|launch"
   }
   ```

4. **Decision**

   If high severity issues:
   ```
   ITERATION REQUIRED
   
   Blocking issues:
   1. [Task - linked to Fxx]
   2. [Task - linked to Fxx]
   
   Returning to code/debug mode. Re-run /bridge-gate after fixes.
   ```
   Update affected features to "in-progress" in context.json.

   If medium/low only:
   ```
   LAUNCH CANDIDATE ✓
   
   Optional improvements (non-blocking):
   1. [Suggestion]
   
   Recommended: Proceed to launch. Medium issues → v1.1.
   ```
   Update features to "done" in context.json.

5. **Human Handoff** — always end with:

   ```
   HUMAN:
   1. [If ITERATION] Review blocking issues — do they match what you experienced during testing?
      Feed fix instructions to RooCode, then re-run /bridge-gate after fixes
   2. [If LAUNCH CANDIDATE] Final go/no-go is yours. Consider:
      - Did the app feel right during manual testing?
      - Are you comfortable with the medium-severity issues being deferred?
      - Any last-minute concerns not captured in the feedback?
   3. Medium issues have been logged for v1.1. Create tracking issues if needed.
   ```

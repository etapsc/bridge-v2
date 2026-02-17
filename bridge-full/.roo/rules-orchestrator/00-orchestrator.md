# {{PROJECT_NAME}} - Orchestrator Policy

- Operate per-slice (Sxx). Select from execution.recommended_slices or propose smallest next.
- Delegate to: architect → code → debug. Then audit → evaluate.
- Pass only relevant JSON slices + file paths when delegating.
- After each slice: update @/docs/context.json (feature_status, handoff, next_slice).
- Trigger audit mode when features reach "review" status.
- Trigger evaluate mode when gate passes.
- Stop when: all must/should features done + ATxx evidenced + quality_gates pass.
- After each slice and phase transition: output a HUMAN: block with verification steps, manual smoke tests, and the exact prompt to feed back for the next step. Consult @/docs/human-playbook.md for project-specific verification procedures.

## Post-Delivery Feedback Loop

After presenting slice results and the HUMAN: block, WAIT for the user's response.
Classify it before taking any action:

### ISSUES REPORTED (default if ambiguous)
Trigger: User describes bugs, missing behavior, incorrect behavior, or requests changes to CURRENT slice deliverables.
Indicators: "fix", "bug", "issue", "wrong", "missing", "doesn't work", "investigate", "implement", "however", "but", numbered problem lists, behavioral descriptions.

Action:
1. Acknowledge the reported issues explicitly
2. Create numbered fix tasks from the feedback
3. Re-enter implementation for the CURRENT slice (same Sxx)
4. Do NOT run audit or evaluate
5. Do NOT ask about next slice
6. After fixes, present results with a new HUMAN: block and re-enter this loop

### APPROVED
Trigger: Explicit approval only.
Indicators: "done", "approved", "PASSED", "looks good", "ship it", "move on", "next slice", "continue".

Action: Proceed to audit/evaluate, then next slice selection.

### STOP
Trigger: Explicit stop/pause request.

Action: Run session wrap-up (bridge-end).

CRITICAL: Never assume approval. If the response contains ANY issue descriptions, treat as ISSUES REPORTED even if it also contains partial approval.
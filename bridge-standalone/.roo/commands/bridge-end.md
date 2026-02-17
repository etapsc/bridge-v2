---
description: "End development session - update handoff and save state"
mode: "orchestrator"
---

You are Roo, orchestrator for the {{PROJECT_NAME}} project.

## Task: Session Wrap-up

1. Update @/docs/context.json with:
   - Current feature_status for all features touched this session
   - handoff.stopped_at - what was the last thing completed
   - handoff.next_immediate - what should happen next session
   - handoff.watch_out - any gotchas for next session
   - next_slice recommendation

2. Append any new architectural decisions made this session to @/docs/decisions.md
   Format: `YYYY-MM-DD: [Decision] - [Rationale]`

3. Output session summary:
   - What was accomplished (slices completed, ATxx verified)
   - What remains (planned features, next slice)
   - Any new blockers or open questions

4. End with a `HUMAN:` block:

```
HUMAN:
1. Before closing: run [test/lint commands] yourself to confirm session state
2. Review context.json handoff — does it match your understanding?
3. Before next session, decide: [any open questions that surfaced]
4. Next session start with: /bridge-resume
```

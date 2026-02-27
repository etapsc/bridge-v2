---
name: Bridge Session Management
description: Session start (re-entry brief) and end (wrap-up) procedures. Use when resuming work in a fresh session or ending a development session.
disable-model-invocation: true
---

# Session Management

## Fresh Session Re-entry

Output brief:

```
═══════════════════════════════════════
PROJECT: [name]
STACK: [from constraints]
═══════════════════════════════════════

HANDOFF:
└─ Stopped at: [handoff.stopped_at]
└─ Next: [handoff.next_immediate]
└─ Watch out: [handoff.watch_out]

FEATURE STATUS:
✓ Done: [Fxx list]
→ Active: [list]
○ Planned: [list]
⊘ Blocked: [list]

LAST GATE: [pass/fail/none] on [date]
LAST EVAL: [date] or none

NEXT SLICE: [Sxx] - [goal]
  Features: [Fxx list]
  Exit Criteria: [ATxx list]

TASK GRAPH (3-10 tasks):
  [task_id] → [goal] | [inputs] | [tests/evidence]

OPEN QUESTIONS / BLOCKERS:
[if any]
═══════════════════════════════════════
```

Then output:
```
HUMAN:
1. Review the brief — does it match your understanding of where things stand?
2. Run `git status` and [test command] to confirm code state matches context.json
3. Consult docs/human-playbook.md for what to verify for the current slice
4. Reply "continue" to proceed with next_slice, or give specific instructions
```

Then STOP and wait.

## Session Wrap-up

1. Update docs/context.json:
   - feature_status
   - handoff (stopped_at, next_immediate, watch_out)
   - next_slice
2. Append decisions to docs/decisions.md (YYYY-MM-DD: [Decision] - [Rationale])
3. Output summary: accomplished, remaining, blockers
4. End with:

```
HUMAN:
1. Before closing: run [test/lint commands] to confirm session state
2. Review context.json handoff — does it match your understanding?
3. Before next session, decide: [any open questions that surfaced]
4. Next session: /bridge-resume
```

---
name: bridge-receive
description: Read and execute a task briefed by Claude Code in the dual-agent workflow. Triggers when the user says "receive brief", "implement current task", or invokes $bridge-receive.
---

# Bridge Receive — Implement Claude Code's Task Spec

## Steps

1. **Read `docs/current-task.md`** — this is your full brief. Do not start without it.
2. **Read `docs/codex-findings.md`** — check if there are any unresolved watch items from a previous pass
3. **Implement** exactly what's specified in current-task.md
   - Respect all **Constraints** listed — do not exceed the specified scope
   - Match existing code patterns in the files you touch
4. **Run tests** using the command in `context.json → commands_to_run`
5. **Commit** with the message format specified in current-task.md
6. **Write findings** to `docs/codex-findings.md` (overwrite the file)

## codex-findings.md Format

```markdown
# Codex Findings — [Slice ID] / [Feature ID]
Completed: [timestamp]
Commit: [hash]

## What I built
[Brief summary of changes — files touched, approach taken]

## Deviations from spec
[Anything you did differently from current-task.md, and why. "None" if spec was followed exactly]

## Watch out for
[Risks, edge cases, or future concerns you noticed during implementation]
[Be specific: file, line range, issue description]
["None" if nothing notable]

## Tests
[Pass/fail, coverage if available]
```

## Constraints

- Do NOT update `context.json` — Claude Code owns that
- Do NOT redesign architecture — if the spec seems wrong, note it in **Watch out for** and implement as specified
- If you hit a blocker that makes the spec unimplementable, write it to `docs/codex-findings.md` with `Status: BLOCKED` and stop

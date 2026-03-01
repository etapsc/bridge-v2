---
description: Write a task spec for Codex based on the current BRIDGE slice. Part of the dual-agent add-on.
---

# Bridge Brief — Write Codex Task Spec

You are acting as **orchestrator** in a dual-agent workflow.

## Steps

1. Read `docs/requirements.json` and `docs/context.json`
2. Identify the current active slice and next unimplemented feature
3. Write `docs/current-task.md` using the format below
4. Report what you wrote and what Codex should do next

## current-task.md Format

```markdown
# Current Task — [Slice ID] / [Feature ID]
Generated: [timestamp]
Status: ready-for-codex

## Objective
[1-2 sentence description of what Codex should build]

## Files to touch
[List specific files and what changes are expected in each]

## Constraints
[What Codex must NOT do — scope boundaries, patterns to preserve, files off-limits]

## Acceptance criteria
[Copied from requirements.json for this feature — exact conditions for done]

## Done signal
When complete:
- [ ] All tests pass (`[test command from context.json]`)
- [ ] Commit with message: `[type(scope): description]`
- [ ] Update docs/codex-findings.md with summary and any watch items
```

## After Writing

Output a brief confirmation:
```
BRIEF WRITTEN ✓

Slice: [ID] | Feature: [ID]
Task: docs/current-task.md updated
Ready for Codex → $bridge-receive
```

Do not implement anything yourself. Your role here is to specify, not build.

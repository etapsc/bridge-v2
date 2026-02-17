# BRIDGE Hooks for Claude Code

Hooks run deterministic scripts in response to Claude Code events.
They're optional but recommended for automating quality enforcement.

## Available Hooks

### post-tool-use: Auto-lint after file edits

Create `.claude/hooks/post-edit-lint.sh` to automatically run linting
after Claude edits files. This catches issues before they accumulate.

Example `.claude/settings.json` hook configuration:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": ".claude/hooks/post-edit-lint.sh $TOOL_INPUT_PATH"
      }
    ]
  }
}
```

### notification: Alert when subagents finish

If you're using subagents for long-running tasks (like bridge-auditor
running a full test suite), hooks can notify you when they're done.

```json
{
  "hooks": {
    "Stop": [
      {
        "command": "notify-send 'Claude Code' 'Task complete — check results'"
      }
    ]
  }
}
```

## Customizing for Your Project

After running `/bridge-requirements` or `/bridge-requirements-only`,
update the hook scripts with your project's actual lint/test commands
from `docs/context.json` → `commands_to_run`.

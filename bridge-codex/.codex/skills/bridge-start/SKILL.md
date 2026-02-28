---
name: Bridge start
description: Start BRIDGE implementation - plan and execute slices from requirements. Invoke with $bridge-start in your prompt.
---

Load docs/requirements.json and docs/context.json.

Plan and execute the next slice using the bridge-slice-plan skill. Switch to architect mode (if design needed), code mode (implementation), debug mode (if tests fail).

Start with the first recommended slice or the slice indicated in context.json next_slice.

The user will provide arguments inline with the skill invocation.

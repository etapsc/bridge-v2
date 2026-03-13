---
name: Bridge Cross Design
description: Design a cross-repo feature — API contracts, shared schemas, migration strategy. Invoke with $bridge-cross-design in your prompt.
---

The user will describe a feature or change that spans multiple repos.

## Steps

1. Load `docs/requirements.json` to understand workspace topology, repo paths, and existing contracts.
2. Load `docs/context.json` for current state, recent repo activity, and handoff notes.
3. Identify impacted repos for this design.
4. For each impacted repo, inspect relevant source files (API definitions, schema files, shared types).
5. Produce a cross-repo design document:

```
### Cross-Repo Design — [Feature/Change Title]

#### Impacted Repos
- repo-id: what changes and why

#### Contract Changes
- [API/schema/protocol changes with before/after]

#### Migration Strategy
- [How to roll out across repos — order matters]
- [Backward compatibility considerations]

#### Acceptance Criteria
- [Per-repo criteria]
- [Integration criteria]

#### Risks
- [What could break across repo boundaries]
```

6. Save the design to `docs/contracts/` if the user approves.

```
HUMAN:
1. Review the design — are the impacted repos correct?
2. Approve contract changes before implementation begins
3. Specify any ordering constraints for the migration
```

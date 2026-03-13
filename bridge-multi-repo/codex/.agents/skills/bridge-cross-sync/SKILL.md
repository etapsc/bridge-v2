---
name: Bridge Cross Sync
description: Sync contracts, shared types, and configs across workspace repos. Invoke with $bridge-cross-sync in your prompt.
---

Propagate changes from a source repo to consuming repos within the workspace.

The user will specify what to sync (or the skill will detect drift).

## Steps

1. Load `docs/requirements.json` for workspace topology, repo paths, and `cross_repo_contracts`.
2. Load `docs/context.json` for `repo_commands` and `repo_state`.
3. Identify sync targets:
   - If user specified: sync the named contract/type/config.
   - If not specified: scan declared contracts for drift (compare source definition vs consumer usage).
4. For each sync target:
   - Read the source definition in the source repo.
   - Read the consumer's current copy/usage.
   - Generate the update for the consumer repo.
   - Show the diff to the user before applying.
5. After applying (with user approval):
   - Update `repo_state` in context.json.
   - Report what changed in which repos.

Common sync targets:
- OpenAPI / protobuf / GraphQL schema files
- Shared TypeScript/Go/Python type definitions
- Configuration files (auth, feature flags, environment schemas)
- Database migration sequences

```
HUMAN:
1. Review the proposed sync diffs before approving
2. Verify consumer repos still build/test after sync
3. If drift detected: decide which direction to sync (source → consumer or vice versa)
```

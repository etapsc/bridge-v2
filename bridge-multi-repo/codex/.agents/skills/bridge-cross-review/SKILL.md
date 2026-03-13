---
name: Bridge Cross Review
description: Review cross-repo changes for consistency — types, contracts, versions. Invoke with $bridge-cross-review in your prompt.
---

Review pending or recent changes across workspace repos for cross-repo consistency.

## Steps

1. Load `docs/requirements.json` to get repo paths from `workspace.repos` and cross-repo contracts.
2. Load `docs/context.json` to get current `repo_state`.
3. For each repo with an active feature branch (from `repo_state`):
   - Read the diff or recent commits on the feature branch.
   - Check: do contract changes in one repo have matching updates in consumers?
4. Verify:
   - **Type consistency**: shared types/interfaces match across repos.
   - **Contract compliance**: API contracts (OpenAPI, protobuf, GraphQL schemas) are honored.
   - **Version alignment**: dependency versions referencing sibling repos are correct.
   - **Migration ordering**: schema/data migrations are sequenced correctly across repos.
5. Output a review report:

```
### Cross-Repo Review — S{xx}

#### Repos Reviewed
- [repo-id]: [branch] — [summary of changes]

#### Consistency Checks
- [ ] Types/interfaces match across repos
- [ ] API contracts honored (source → consumers)
- [ ] Dependency versions aligned
- [ ] Migration order valid

#### Issues Found
1. [Issue description — which repos, what's mismatched]

#### Verdict
[CONSISTENT / ISSUES FOUND — with specific fix instructions]
```

```
HUMAN:
1. Review the consistency verdict — any false positives?
2. If ISSUES FOUND: fix the issues, then re-run $bridge-cross-review
3. If CONSISTENT: proceed to gate
```

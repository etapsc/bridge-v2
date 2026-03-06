# BRIDGE Multi-Repo Playbook

Use this when one product spans multiple repositories (for example: `api`, `web`, `infra`).

## Core Model

1. Keep exactly one canonical BRIDGE control plane (`docs/requirements.json` + `docs/context.json`) in a single control repo.
2. Treat each implementation repo as an execution target referenced by stable `repo_id`.
3. Require every slice to declare impacted repos and provide per-repo evidence before moving to gate.

## Requirements Template (bridge.v2)

Add and maintain `workspace`:

```json
"workspace": {
  "topology": "multi-repo",
  "control_repo": "orchestrator",
  "repos": [
    {
      "repo_id": "api",
      "path": "../api",
      "default_branch": "main",
      "owners": ["backend"]
    },
    {
      "repo_id": "web",
      "path": "../web",
      "default_branch": "main",
      "owners": ["frontend"]
    }
  ],
  "cross_repo_contracts": [
    "web -> api OpenAPI contract in api/openapi.yaml"
  ],
  "integration_acceptance_tests": [
    "UF03 end-to-end checkout flow across web + api"
  ]
}
```

## Context Template (context.v1)

Track commands and state per repo:

```json
"workspace": {
  "topology": "multi-repo",
  "control_repo": "orchestrator",
  "repos": ["api", "web", "infra"]
},
"commands_to_run": {
  "test": "make test-all",
  "lint": "make lint-all",
  "typecheck": "make typecheck-all",
  "dev": "make dev"
},
"repo_commands": {
  "api": { "test": "cd ../api && npm test", "lint": "cd ../api && npm run lint" },
  "web": { "test": "cd ../web && npm test", "lint": "cd ../web && npm run lint" }
},
"repo_state": [
  { "repo_id": "api", "branch": "feature/S12-auth", "head_sha": "", "pr_url": "" },
  { "repo_id": "web", "branch": "feature/S12-auth", "head_sha": "", "pr_url": "" }
]
```

`commands_to_run.*` should stay as aggregate commands used by gate automation. `repo_commands` adds per-repo drill-down.

## Slice Rules

For each slice:

1. Declare `impacted_repos` in slice notes/handoff.
2. Record evidence per repo (tests, lint, typecheck, artifact, PR link).
3. Do not mark feature `done` until all impacted repos are merged or pinned and integration acceptance tests pass.

## Gate Rules

Run gate in two phases:

1. Repo phase: run checks for each impacted repo.
2. Integration phase: run cross-repo checks (contract checks, E2E, migrations, compatibility).

Gate is `PASS` only if both phases pass.

## Operational Guardrails

1. Use a shared slice branch naming convention across repos (for example `feature/S12-*`).
2. Require explicit compatibility notes for schema/API changes.
3. Keep all PR links and commit SHAs in `repo_state` during active slices.
4. If a repo is external or read-only, record that as a blocker in context and treat dependent slices as blocked.

## Concrete Example: Daemon + Server + SDK-Go + SDK-JS

Recommended layout:

```text
workspace/
  server/   # BRIDGE control repo (docs/requirements.json + docs/context.json)
  daemon/
  sdk-go/
  sdk-js/
```

`requirements.json` workspace excerpt:

```json
"workspace": {
  "topology": "multi-repo",
  "control_repo": "server",
  "repos": [
    { "repo_id": "server", "path": ".", "default_branch": "main", "owners": ["backend"] },
    { "repo_id": "daemon", "path": "../daemon", "default_branch": "main", "owners": ["platform"] },
    { "repo_id": "sdk-go", "path": "../sdk-go", "default_branch": "main", "owners": ["sdk"] },
    { "repo_id": "sdk-js", "path": "../sdk-js", "default_branch": "main", "owners": ["sdk"] }
  ],
  "cross_repo_contracts": [
    "Server API contract is source of truth (OpenAPI/proto in server repo)",
    "sdk-go and sdk-js must match the same server API version and auth semantics",
    "daemon event/protocol changes must be backward-compatible with server + SDK consumers"
  ],
  "integration_acceptance_tests": [
    "Daemon registration + heartbeat visible via both SDKs",
    "Read/write workflow succeeds via sdk-go and sdk-js against same server build",
    "Auth/token flow parity across daemon, server, sdk-go, sdk-js"
  ]
}
```

`context.json` execution excerpt:

```json
"workspace": {
  "topology": "multi-repo",
  "control_repo": "server",
  "repos": ["server", "daemon", "sdk-go", "sdk-js"]
},
"repo_commands": {
  "server": { "test": "cd . && make test", "lint": "cd . && make lint", "typecheck": "cd . && make typecheck" },
  "daemon": { "test": "cd ../daemon && make test", "lint": "cd ../daemon && make lint", "typecheck": "cd ../daemon && make typecheck" },
  "sdk-go": { "test": "cd ../sdk-go && go test ./...", "lint": "cd ../sdk-go && golangci-lint run", "typecheck": "cd ../sdk-go && go test ./..." },
  "sdk-js": { "test": "cd ../sdk-js && pnpm test", "lint": "cd ../sdk-js && pnpm lint", "typecheck": "cd ../sdk-js && pnpm typecheck" }
},
"repo_state": [
  { "repo_id": "server", "branch": "feature/S12-stream-ack", "head_sha": "", "pr_url": "" },
  { "repo_id": "daemon", "branch": "feature/S12-stream-ack", "head_sha": "", "pr_url": "" },
  { "repo_id": "sdk-go", "branch": "feature/S12-stream-ack", "head_sha": "", "pr_url": "" },
  { "repo_id": "sdk-js", "branch": "feature/S12-stream-ack", "head_sha": "", "pr_url": "" }
]
```

---
description: "Migrate an existing BRIDGE v1 project to BRIDGE v2.1 schema and tooling"
mode: "orchestrator"
---

You are Roo, orchestrator for the {{PROJECT_NAME}} project. This project was built using BRIDGE v1 and is being upgraded to BRIDGE v2.1.

BRIDGE v2.1 = Brainstorm → Requirements → Implementation Design → Develop → Gate → Evaluate

## Goal

Migrate all existing project state into the v2.1 schema WITHOUT losing any progress, decisions, or context. This is a schema migration, not a restart.

## Step 1: Discover Existing v1 Artifacts

Search the project for any existing BRIDGE v1 artifacts. Common v1 locations and formats:

- `docs/requirements.json` (v1 schema — may have different field names or structure)
- `docs/context.json` (v1 schema)
- `docs/decisions.md` or `docs/adr/` (architectural decisions)
- `docs/brainstorm.md` or similar brainstorm output
- `docs/reports-evals/gate-report.md` (existing gate results)
- `docs/reports-evals/eval-scenarios.md` (existing eval materials)
- `docs/external-task.md` (offloaded work)
- `.bridge/` or any other BRIDGE-specific directory
- `README.md` (may contain project description, stack info)
- Any `NOTES.md`, `TODO.md`, or similar human notes

Also inspect:
- `git log --oneline -30` — recent activity and progress
- `git status` — current working state
- Project structure (`src/`, `tests/`, `Cargo.toml` / `package.json` / `go.mod` / etc.) — infer stack and commands

List everything found. If an artifact is missing, note it — do not invent.

## Step 2: Map v1 → v2.1 Schema

### File 1: @/docs/requirements.json (bridge.v2)

Map existing requirements into the v2.1 schema:

```json
{
  "schema_version": "bridge.v2",
  "project": {
    "name": "",
    "one_liner": "",
    "mission": "",
    "target_users": [""],
    "success_metrics": [""]
  },
  "scope": {
    "in_scope": [""],
    "out_of_scope": [""],
    "non_goals": [""],
    "assumptions": [""]
  },
  "constraints": {
    "languages": [""],
    "platforms": [""],
    "must_use": [""],
    "must_not_use": [""],
    "compliance_security_notes": [""]
  },
  "domain_model": {
    "core_entities": [
      { "name": "", "description": "", "key_fields": [""] }
    ],
    "state_machine_notes": [""]
  },
  "features": [
    {
      "id": "F01",
      "title": "",
      "priority": "must|should|could",
      "description": "",
      "acceptance_tests": [
        { "id": "AT01", "given": "", "when": "", "then": "" }
      ],
      "dependencies": [],
      "non_goals": [""]
    }
  ],
  "user_flows": [],
  "nfr": {
    "performance_budgets": [],
    "reliability": [],
    "security": [],
    "observability": [],
    "scalability": []
  },
  "interfaces": {
    "apis": [],
    "external_services": []
  },
  "quality_gates": {
    "ci_required": true,
    "tests": {
      "unit": true,
      "integration": true,
      "e2e": "optional",
      "coverage_target": "80%"
    },
    "linters_typechecks": [""],
    "security_checks": [""],
    "performance_budgets": {
      "bundle_size": "",
      "api_response": "",
      "page_load": ""
    }
  },
  "execution": {
    "recommended_slices": [],
    "open_questions": [""],
    "risks": []
  }
}
```

Migration rules:
- Preserve ALL existing feature IDs if they follow Fxx pattern. If v1 used different IDs, create a mapping and note it.
- Preserve ALL existing acceptance test IDs (ATxx). Re-number only if v1 had no stable IDs.
- Preserve existing slice definitions and their order.
- Infer `commands_to_run` from the project's build system (Cargo.toml → `cargo test`, package.json → `npm test`, etc.)
- Infer `quality_gates` thresholds from any existing CI config, linter config, or v1 gate settings.
- Move any v1 fields that don't map to v2.1 into `execution.open_questions` with a note.
- Do NOT discard information. If unsure where it goes, put it in `execution.open_questions`.

### File 2: @/docs/context.json (context.v1)

Map existing progress into the v2.1 context schema:

```json
{
  "schema_version": "context.v1",
  "updated": "[NOW]",
  "project": { "name": "{{PROJECT_NAME}}" },
  "feature_status": [
    { "feature_id": "F01", "status": "not_started|in_progress|review|done|blocked", "notes": "", "evidence": [] }
  ],
  "handoff": {
    "stopped_at": "",
    "next_immediate": "",
    "watch_out": "Migrated from BRIDGE v1 — verify feature_status accuracy"
  },
  "next_slice": { "slice_id": "", "goal": "", "features": [], "acceptance_tests": [] },
  "commands_to_run": { "test": "", "lint": "", "typecheck": "", "dev": "" },
  "recent_decisions": [],
  "blockers": [],
  "discrepancies": [],
  "gate_history": [],
  "eval_history": []
}
```

Migration rules:
- Map existing feature progress accurately. Use git history and test results as evidence.
- If v1 had gate history, migrate it into `gate_history` array.
- If v1 had eval history, migrate it into `eval_history` array.
- Set `handoff.stopped_at` to describe current project state accurately.
- Set `next_slice` to the next logical work item based on current progress.
- Populate `commands_to_run` from the actual project build system.
- Record any v1→v2.1 schema changes in `recent_decisions`.

### File 3: @/docs/human-playbook.md

Generate a project-specific Human Operator Playbook based on the migrated requirements:

```markdown
# Human Operator Playbook - [Project Name]
Migrated from BRIDGE v1 to v2.1

## Migration Notes
[What changed in the migration, what to verify, any manual steps needed]

## Workflow Per Slice

### Before Each Slice
[Project-specific build/test/lint commands]

### After Each Slice
[How to smoke test based on this project's stack and interfaces]

## Slice Verification Guide

| Slice | Features | What YOU Test Manually | What to Read/Inspect | Decisions Needed |
|-------|----------|----------------------|---------------------|-----------------|

## Common Pitfalls
[Project-specific warnings]

## RooCode Prompt Template
```
Continue BRIDGE v2.1. Current state is in docs/context.json.
Execute next_slice [Sxx]: [goal].
Features: [Fxx list].
Exit criteria: [ATxx list].

Rules:
- Run [commands] before declaring done
- Update docs/context.json with feature_status, evidence, gate_history
- Do NOT refactor previous slice code unless a test is failing
- If you hit an open question, STOP and ask — do not silently skip
```

## Open Questions Requiring Human Decision
[Including any questions surfaced during migration]
```

## Step 3: Preserve Existing Documents

- If `docs/decisions.md` exists with content, preserve it. Append a migration entry:
  `[TODAY]: Migrated from BRIDGE v1 to v2.1 — schema upgrade, no functional changes`
- If gate reports, eval scenarios, or other docs exist, keep them in place. They remain valid.
- Back up original v1 files before overwriting:
  - `docs/requirements.json` → `docs/requirements.v1.backup.json`
  - `docs/context.json` → `docs/context.v1.backup.json`

## Step 4: Validate Migration

After generating all files:
1. Run the project's test command to confirm nothing is broken
2. Verify `feature_status` in context.json matches code reality via targeted inspection
3. Check that all v1 features appear in v2.1 requirements.json (no data loss)

## Step 5: Output Migration Report

```
BRIDGE v1 → v2.1 MIGRATION COMPLETE

Migrated:
- requirements.json: [N] features, [N] acceptance tests, [N] slices
- context.json: [N] features ([done]/[in-progress]/[planned]/[blocked])
- human-playbook.md: generated with [N] slice verification entries
- decisions.md: migration entry appended

Backups:
- docs/requirements.v1.backup.json
- docs/context.v1.backup.json

Schema changes:
- [list any fields that were added, renamed, or restructured]

Data preserved from v1:
- [list what was carried over: gate history, eval history, decisions, etc.]

Potential issues:
- [anything that couldn't be cleanly mapped]

HUMAN:
1. Review the migrated requirements.json — are all features accounted for?
2. Review context.json feature_status — does it match your understanding of progress?
3. Run: [test command] to verify project still builds and tests pass
4. Check docs/human-playbook.md — are the smoke test procedures accurate?
5. If everything looks right, continue development with: /bridge-resume
6. If issues found, fix them manually then run: /bridge-context-update
```

Now scan the project and perform the migration.

$ARGUMENTS

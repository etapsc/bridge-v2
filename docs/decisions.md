# BRIDGE v2.1 Toolkit — Decisions Log

## 2026-02-16: Post-Delivery Feedback Loop (F09)

**Problem:** After presenting slice results, the orchestrator asks "what's next slice?" even when the user reports issues with the current slice. User feedback is misclassified as input for slice selection rather than as fix requests.

**Decision:** Add a Post-Delivery Feedback Loop to all orchestrator-level files. User responses are classified into three categories with ISSUES REPORTED as the default:

- **ISSUES REPORTED** (default if ambiguous) — stay in current slice, create fix tasks, re-implement, re-present
- **APPROVED** (explicit only) — proceed to gate/eval/next slice
- **STOP** (explicit only) — wrap up session

**Rationale:** The orchestrator's linear flow (slice → audit → eval → next) had no branch for "user found problems." Making ISSUES REPORTED the default prevents premature advancement, which was the observed failure mode.

**Files requiring edits (6 total):**

1. `bridge-full/.roo/rules-orchestrator/00-orchestrator.md` — append new section
2. `bridge-full/.roo/skills/bridge-slice-plan/SKILL.md` — replace `## Completion` with `## Completion & Feedback Loop`
3. `bridge-standalone/.roo/commands/bridge-start.md` — insert before final load line
4. `bridge-standalone/.roo/commands/bridge-resume.md` — insert before final STOP line
5. `bridge-claude-code/CLAUDE.md` — insert between Delegation Model and Available Skills
6. `bridge-codex/AGENTS.md` — insert inside Orchestrator (default) section

Additionally, `bridge-slice-plan/SKILL.md` exists in 3 packs and all must be updated:
- `bridge-full/.roo/skills/bridge-slice-plan/SKILL.md`
- `bridge-claude-code/.claude/skills/bridge-slice-plan/SKILL.md`
- `bridge-codex/.agents/skills/bridge-slice-plan/SKILL.md`

**Key design choice:** The slice-plan skill's `## Completion` section was the primary culprit — it updated feature status to "review" immediately upon ATxx evidence passing, without waiting for user confirmation. The fix changes this: status only updates to "review" or "done" after explicit approval.

---

## 2026-02-16: Pack Architecture Decisions (established)

- **.roomodes uses YAML** — not JSON. Emoji mode names (🔍 Audit, 📋 Evaluate).
- **Audit fileRegex:** `docs/(gates-evals/(gate-report|gate-report-S\d+)|context)\..+$`
- **Evaluate fileRegex:** `docs/(gates-evals/(eval-scenarios|eval-scenarios-S\d+)|context)\..+$|tests/e2e/.+$`
- **Distribution: tar.gz only** — no zip files.
- **setup.sh flags:** `--name`, `--pack`, `-o` (output directory).
- **{{PROJECT_NAME}} placeholder** — replaced by setup.sh at init time.

---

## 2026-02-16: Codex Pack Architecture

**Decision:** Codex uses single-agent with role modes (mental mode switching) rather than subagents.

**Rationale:** Codex CLI doesn't support isolated subagents like Claude Code. Commands are converted to skills invoked with `$skill-name` syntax. All 16 commands + 8 procedures = 24 skills total.

**Structure:** `AGENTS.md` (global rules), `.agents/skills/` (all skills), `.codex/config.toml`.

---

## 2026-02-16: Existing Project Support

**Decision:** Added two new commands for existing projects (not just greenfield):
- `bridge-scope` — analyze existing codebase, scope a feature or fix
- `bridge-feature` — generate incremental requirements that append to existing requirements.json

**Rationale:** Original BRIDGE assumed greenfield. Most real usage is adding features to existing projects.

---

## 2026-02-16: Claude Code Delegation Model

**Decision:** Claude Code uses subagents (architect, coder, debugger, auditor, evaluator) operating in isolated context windows. Main session acts as orchestrator.

**Rationale:** Claude Code's subagent model provides natural context isolation, preventing the context bloat that occurs in RooCode's mode-switching. Each agent gets only relevant JSON slices + file paths.

---

## 2026-02-16: Packaging Script

**Decision:** Created `package.sh` to rebuild tar.gz files from source folders.

**Rationale:** Enables manual editing of individual files and quick reconstruction of the distributable state. Run from the parent directory containing the four `bridge-*` folders.

---

## 2026-02-28: Codex Native Skills + Config Alignment

**Decision:** Align `bridge-codex` with current Codex conventions by adding `.codex/skills/` as the native skills location, while keeping `.agents/skills/` as an authoring mirror.

**Rationale:** Current Codex documentation loads reusable project skills from `.codex/skills/*/SKILL.md`. Keeping a native skill tree improves compatibility with latest Codex behavior while preserving existing BRIDGE authoring workflows.

**Also Updated:**
- Switched in-pack human instructions from `/bridge-*` to `$bridge-*` for Codex skill invocation.
- Added a `profiles.bridge` block in `.codex/config.toml` with `gpt-5-codex` and `model_reasoning_summary = "auto"`; omitted `web_search` from profile defaults for cross-version compatibility (use `--search` at runtime).
- Fixed internal consistency gaps: status vocabulary (`planned|in-progress|review|done|blocked`), eval output filename expectation (`eval-scenarios.md`), and requirements schema support for `quality_gates.e2e_critical_paths`.

---

## 2026-02-28: Codex `web_search` Profile Compatibility Fix

**Decision:** Keep `profiles.bridge` minimal and remove the static `web_search` key from `bridge-codex/.codex/config.toml`.

**Rationale:** Codex config parsing for `profiles.bridge.web_search` has changed across versions; removing it avoids startup failures in generated projects. Users can explicitly enable web search at runtime with `codex --profile bridge --search`.

---

## 2026-03-09: Remove Obsolete Commands (migrate, offload, reintegrate)

**Decision:** Permanently remove 3 commands (`bridge-migrate`, `bridge-offload`, `bridge-reintegrate`) and 2 skills (`bridge-external-handoff`, `bridge-external-reintegrate`) from all 5 packs. Update all references from 18→15 commands and 8→6 skills.

**Rationale:** These commands were redundant and obsolete. `bridge-migrate` (v1→v2.1 migration) is no longer needed. `bridge-offload`/`bridge-reintegrate` (external agent handoff) were superseded by the multi-repo pack's cross-repo coordination model.

**Impact:** requirements.json, test.sh, README.md, CLAUDE.md, AGENTS.md, methodology doc, platform guides — all updated. 52/52 smoke tests pass after fix.

---

## 2026-03-09: Add Controller Pack (F14) and Multi-Repo Pack (F15)

**Decision:** Track `bridge-controller/` and `bridge-multi-repo/` as new features F14 and F15 in requirements.json with acceptance tests AT12 and AT13.

**Rationale:** Both packs were already built and packaged but not tracked in the requirements or context. F14 is a portfolio-level orchestrator (3 commands: status, init-project, sync). F15 is a cross-repo workspace orchestrator (12 commands, available in claude-code and codex variants).

**Architecture note:** Multi-repo orchestrator and individual repo BRIDGE docs coexist at different levels — workspace-level docs in the orchestrator, repo-level docs in each repo. No migration of existing repo docs needed.

---

## 2026-03-09: Fix install.sh ask_yn to Handle Non-y/n Input

**Decision:** Changed `ask_yn` function so that when default is "y", only explicit "n"/"no" declines — all other input (including typos/accidental text) follows the default.

**Rationale:** During manual testing, typing a repo name at the "Add another repo? (Y/n):" prompt caused the loop to exit silently because the function only matched exact "y". This UX bug caused data loss (second repo never collected).

---

## 2026-03-10: Canonical Claude Code Pack Layout

**Decision:** Treat `bridge-claude-code/` root (`CLAUDE.md` + `.claude/`) as the only canonical Claude Code pack layout. Generated tests, gate/eval artifacts, and packaging expectations now target that root layout only.

**Rationale:** The recent restructuring removed the old `project/` and `plugin/` duplicates. Validation and operator docs must match the shipped pack shape or they produce false failures and unusable manual instructions.

---

## 2026-03-10: Multi-Repo Workspace Schema Ownership

**Decision:** Multi-repo repo paths are sourced from `docs/requirements.json` `workspace.repos[].path`. `docs/context.json` in multi-repo packs stores runtime state only (`repo_commands`, `repo_state`, handoff/history) and no longer carries a stale `commands_to_run` block.

**Rationale:** The prior docs mixed topology data with runtime state, which made the Claude Code and Codex multi-repo instructions disagree about where repo paths live. Keeping topology in requirements and runtime execution state in context matches the shipped schema and reduces drift.

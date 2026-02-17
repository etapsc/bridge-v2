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
- **Audit fileRegex:** `docs/(gate-report|gate-report-S\d+|context)\..+$`
- **Evaluate fileRegex:** `docs/(eval-scenarios-S\d+|context)\..+$|tests/e2e/.+$`
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
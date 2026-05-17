# Implementation Plan: Session-State Durability & In-Flight Progress Tracking

**Branch**: `020-session-state-durability` | **Date**: 2026-05-19 | **Spec**: [specs/020-session-state-durability/spec.md](spec.md)
**Input**: Feature specification from `/specs/020-session-state-durability/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

This feature establishes durable session-state tracking to prevent Squad confusion after system restarts, boundary events, and cross-worktree scenarios. The core problems addressed are: (1) Squad acting on stale feature references after closeout, (2) lost in-flight progress on reboot, and (3) lack of authoritative "where am I?" reporting.

**Technical Approach**: Active-write session-state files with stale-state detection at `specrew start`. Boundary-event synchronization via helper script invoked at seven lifecycle boundaries. Pure-derivation cross-worktree awareness from `git worktree list`. Task progress tracking in sibling `tasks-progress.yml` files. Module and PSGallery version checks with non-blocking warnings.

**Iteration Structure**: Two-iteration delivery. Iteration 1 establishes foundational correctness (boundary sync, stale detection, module version check). Iteration 2 adds visibility and UX refinement (task progress, cross-worktree awareness, recovery prompts, PSGallery check). Plus a companion chore commit to establish `.squad/identity/now.md` closeout pattern before Iteration 1 starts.

## Technical Context

**Language/Version**: PowerShell 5.1+ / PowerShell Core 7+ (cross-platform)  
**Primary Dependencies**: Git 2.25+, PowerShell YAML module (PSYaml or similar for parsing)  
**Storage**: File-based (`.specrew/`, `.squad/`, `specs/` directories; no database)  
**Testing**: Pester 5.x for unit and integration tests; if only Windows PowerShell's bundled Pester 3.4.0 is present, install Pester 5.5.0 in CurrentUser scope before Phase 0 testing (`Install-Module Pester -RequiredVersion 5.5.0 -Scope CurrentUser`)  
**Target Platform**: Windows (PowerShell 5.1), Linux/macOS (PowerShell Core 7+)  
**Project Type**: CLI governance framework (PowerShell module)  
**Performance Goals**: `specrew start` stale-state checks complete within 2 seconds; cross-worktree derivation within 2 seconds for up to 10 worktrees; PSGallery version check within 5 seconds (cached)  
**Constraints**: Must support offline operation (PSGallery check degrades gracefully); must preserve atomicity for session-state writes (write-temp-then-rename pattern); must not block `specrew start` on any version check warnings  
**Scale/Scope**: Single-developer workflows with up to 10 concurrent worktrees; up to 50 features per project lifecycle; session-state files typically <10KB each

## Phase 1 Quality Planning

> This section documents the Phase 1 quality-bar approach for this feature.

**Phase Scope**: `phase-1-first-slice` (Iteration 1: Pillars 1, 4, Scope Addition 1)  
**Inferred Quality Profile**: `quality-profile.powershell-cli-tool.v1` (custom composition based on PowerShell governance CLI characteristics)  
**Selected preset ref or explicit custom composition**: Custom composition—no exact preset match for PowerShell governance framework with multi-file state synchronization and git integration  
**Bounded custom composition**: This feature combines (1) file I/O correctness (atomic writes), (2) git command integration (worktree list, log queries), (3) CLI user experience (non-blocking warnings, informative prompts). Manual unknowns: session-state synchronization race conditions under concurrent `specrew` invocations (addressed via testing), filesystem-specific atomic-rename compatibility (mitigated via write-temp-then-rename with fallback).

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `powershell-scripts` | `scripts/*.ps1`, `extensions/*/scripts/*.ps1` | PowerShell 5.1+/Core 7+ | Core feature implementation surface: boundary sync, stale detection, version checks |
| `session-state-files` | `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/identity/now.md`, `.squad/decisions.md` | YAML/JSON/Markdown | Critical data correctness surface: must remain mutually consistent |
| `git-integration` | `git worktree list`, `git log`, `git rev-parse` | Git 2.25+ | Stale-state detection and cross-worktree derivation rely on git command correctness |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| `data-integrity` | required | Session-state files must remain consistent; corrupted state causes Squad to act on wrong feature (high user impact) |
| `atomicity-correctness` | required | Boundary-event sync updates multiple files; partial writes must be detectable and recoverable |
| `concurrent-access` | required | Multiple `specrew` invocations (rare but possible) must not corrupt session-state files |
| `cross-platform-compatibility` | required | Must work identically on Windows (PS 5.1), Linux/macOS (PS Core 7+) |
| `performance-regression` | required | `specrew start` is hot path; stale-state checks must not add >2s overhead |
| `security` | not-applicable | No trust boundaries crossed; all files are local worktree-scoped; no credential handling |
| `backward-compatibility` | required | Existing projects without session-state files must gracefully initialize on first `specrew start` |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `powershell-governance-cli-v1` | Custom bundle for Specrew PowerShell CLI features |
| Mechanical Checks | `dead-field` (unused YAML fields), `anti-pattern` (unsafe file writes), `test-integrity` (coverage for atomic-write paths) | Checked via custom linter and Pester tests |
| Ecosystem Tools | Pester 5.x preferred for unit/integration tests (install in CurrentUser scope if only 3.4.0 is present), PSScriptAnalyzer (static analysis), manual git-worktree scenario testing | Free/community baseline |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `atomic-write-correctness` | mechanical | Pester test suite: `tests/unit/sync-boundary-state.tests.ps1` | planned |
| `stale-state-detection-coverage` | mechanical | Pester test suite: `tests/integration/stale-state-detection.tests.ps1` | planned |
| `cross-platform-validation` | tooling | CI runs on Windows, Linux, macOS with PowerShell version matrix | planned |
| `performance-baseline` | tooling | `specrew start` execution time measured in CI; must be <2s overhead | planned |
| `backward-compatibility-check` | manual-evidence | Manual test: bootstrap new project, verify graceful session-state initialization | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| `security-surface-analysis` | No external trust boundaries; all files are local worktree-scoped; no network I/O except PSGallery check (best-effort, non-blocking) | none |
| `concurrency-correctness-review` | Concurrent `specrew` invocations are edge case (user must deliberately run multiple commands simultaneously); mitigated via file locking in future iteration if needed | defer to Phase 3+ if user reports incidents |
| `API-contract-stability` | Internal implementation only; no public API contracts | none |

### Explicit Phase 2+ Deferrals

- Pre-implementation hardening gate sign-off and blocking semantics remain deferred in this template.
- Dedicated bug-hunter lens execution and strongest-class routing remain deferred in this template.
- Quality-drift logic, mixed-stack override workflows, and reference-implementation comparison remain deferred in this template.

## Phase 2 Hardening and Specialist Review Planning

> This section documents Phase 2 hardening strategy post-Iteration 1 completion.

**Phase 2 Slice Scope**: Iteration 1 hardening gate (boundary sync + stale detection + module version check)  
**Hardening Gate Artifact**: `specs/020-session-state-durability/quality/hardening-gate-iteration-1.md` (to be created post-implementation)  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/020-session-state-durability/quality/trap-reapplication.md` (deferred to hardening gate execution)

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Atomicity failure modes | Write-temp-then-rename may fail on disk-full, permission-denied, or network filesystem race conditions; partial writes must be detectable and recoverable | `hardening-gate-iteration-1.md` section: "Atomic Write Failure Scenarios" | required |
| Stale-state false negatives | If git-log bounded search misses a merged feature (e.g., merge commit lacks feature number in message), Squad may act on closed feature | `hardening-gate-iteration-1.md` section: "Stale-State Detection Edge Cases" | required |
| Cross-file consistency | Session-state files updated sequentially; system crash during sync leaves inconsistent state (e.g., `.specrew/last-start-prompt.md` updated, `.squad/identity/now.md` not) | Stale-state detection must identify inconsistencies; recovery prompt guides user | required |
| Filesystem-specific atomic-rename compatibility | NTFS, ext4, APFS may have different rename atomicity guarantees (especially on network filesystems or Docker volumes) | Test plan: validate on Windows NTFS, Linux ext4, macOS APFS, Docker bind mounts | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `data-integrity-issues-v1` | required | Session-state consistency is critical; corrupted state has high user impact (Squad acts on wrong feature) | `quality/lenses/data-integrity-iteration-1.md` |
| `error-handling-issues-v1` | required | Boundary sync failures, git command errors, filesystem errors must surface user-actionable messages | `quality/lenses/error-handling-iteration-1.md` |
| `performance-regression-v1` | required | `specrew start` is hot path; stale-state checks must not degrade startup time | `quality/lenses/performance-iteration-1.md` |
| `backward-compatibility-v1` | required | Existing projects must gracefully initialize session-state files on first `specrew start` | `quality/lenses/backward-compatibility-iteration-1.md` |
| `security-issues-v1` | not-applicable | No trust boundaries, credential handling, or network trust decisions in Iteration 1 scope | N/A |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | strongest-available (default policy per `.specrew/config.yml`) | TBD at execution time | none | Default routing applies; no override requested |

### Explicit Later Deferrals

- Full line-by-line lens execution evidence and runtime-only final proof remain deferred until the approved implementation/review slice authorizes them.
- Known-traps corpus seeding, approved additions, and trap reapplication remain deferred until the dedicated known-traps slice is in scope.
- Strongest-class routing enforcement details and requested-versus-effective execution evidence remain deferred until the routed lens execution path exists.
- Quality-drift comparison, mixed-stack override workflows, and reference-implementation checks remain deferred unless the approved slice explicitly includes them.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Planning-Time Clarifications Applied

This plan resolves three planning blockers identified in `research.md` without modifying the approved spec:

1. **Module-vs-project version check source** (FR-025): Use `.specrew/config.yml` `specrew_version` field as project version-of-record (NOT `.specify/init-options.json` `speckit_version`). Rationale: `specrew_version` is maintained by `specrew update` and represents project's expected Specrew module version; `speckit_version` is immutable bootstrap metadata for Spec Kit extension version. See `research.md` Blocker 1.

2. **Distribution Owner role mapping** (TG-002): Map "Distribution Owner" to existing **Implementer** baseline role. Rationale: Version-check tasks (FR-025 through FR-035) are runtime operational checks (read version, compare, format warning), not release/publishing operations. Implementer role is semantically correct and precedented by F-019 distribution tasks. See `research.md` Blocker 2.

3. **Bounded git-history strategy** (FR-015): Use `git log main --since="<bootstrap_date>"` where `<bootstrap_date>` comes from `.specrew/config.yml` `bootstrap_date` field. Fallback to `--since="90 days ago"` if `bootstrap_date` missing. Rationale: Bounds stale-state detection to project lifecycle; no Specrew feature can be merged before bootstrap date. See `research.md` Blocker 3.

### Constitution Gates

- ✅ **Spec Authority Gate**: Plan scope maps to approved spec artifacts (FR-001 through FR-035, US1 through US5, TG-001 through TG-004). All functional requirements traced to user stories. No scope additions beyond approved spec.

- ✅ **Layering Gate**: Changes classified as **Spec Kit layer** (boundary-event sync, stale-state detection, version checks are core Specrew lifecycle mechanisms). No Squad layer changes required. Session-state files are Specrew governance artifacts (`.specrew/`, `.squad/` directories per Specrew conventions).

- ✅ **Traceability Gate**: 
  - US1 (Post-Reboot Recovery) → FR-015 through FR-024 (stale detection + recovery prompts)
  - US2 (Boundary-Event State Sync) → FR-001 through FR-005 (sync helper script + lifecycle boundaries)
  - US3 (Where-Am-I Query) → FR-011 through FR-014 + FR-021 through FR-024 (cross-worktree + recovery prompts)
  - US4 (Module Version Mismatch) → FR-025 through FR-028 (module-vs-project check)
  - US5 (PSGallery Latest-Version Check) → FR-029 through FR-035 (PSGallery check)
  - All requirements link to specific implementation tasks (see Iteration Plans below)

- ✅ **Ownership Gate**: 
  - **Spec Steward**: Specification integrity (Alon Fliess per spec line 212)
  - **Planner**: This document (AI agent - Claude/Copilot per workflow)
  - **Implementer**: All implementation tasks (Pillars 1-5, Scope Additions 1-2, Companion Chore)
  - **Reviewer**: Review/Demo ceremony post-implementation
  - **Retro Facilitator**: Retrospective post-feature-closeout
  - No new project-specific roles required (Distribution Owner mapped to Implementer)

- ✅ **Capacity Gate**: 
  - **Unit**: Story points (SP) per spec line 214
  - **Iteration 1 Budget**: 16 SP (Pillars 1, 4, Scope Addition 1)
  - **Iteration 2 Budget**: 15 SP (Pillars 2, 3, 5, Scope Addition 2)
  - **Companion Chore**: 2 SP (ship before Iteration 1)
  - **Total Feature Estimate**: 33 SP (refined from the initial 25-30 SP estimate and accepted at planning-boundary signoff)

- ✅ **Drift/Reconciliation Gate**: 
  - Drift detection: (1) Validator checks for session-state consistency at `specrew start`, (2) Manual review of `.squad/decisions.md` for missing boundary records, (3) User-reported "Squad confused about feature state" incidents
  - Conflict escalation: Stale-state detection prompts user with re-anchor/continue-anyway/investigate options; never silently acts on stale state
  - Implementation reality changes require explicit spec reconciliation (per Constitution Principle I)

- ✅ **Verification Gate**: 
  - **Process Verification**: Pester test suite for boundary sync atomicity, stale-state detection coverage, cross-platform compatibility, performance baseline
  - **Outcome Verification**: Acceptance criteria from US1-US5 validated via manual test scenarios post-implementation
  - **Constitution Compliance**: This plan passes all six gates; re-check post-Phase 1 design to verify data-model and contracts align with constitutional principles

## Project Structure

### Documentation (this feature)

```text
specs/020-session-state-durability/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (pre-existing; resolves planning blockers)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── session-state-schema.yml      # Session-state file structure
│   └── sync-boundary-state-api.md    # Helper script contract
├── quality/             # Phase 2 output (post-implementation)
│   ├── hardening-gate-iteration-1.md
│   └── lenses/
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Root-level Specrew module structure (existing)
scripts/
├── specrew-start.ps1    # Modified: add stale-state detection, version checks
├── specrew-where.ps1    # Modified: add cross-worktree awareness
├── specrew-init.ps1     # Modified: add PSGallery version check
├── specrew-update.ps1   # Modified: add PSGallery version check
└── internal/
    └── sync-boundary-state.ps1  # NEW: boundary-event state synchronization helper

extensions/
└── specrew-speckit/
    └── scripts/
        └── sync-boundary-state.ps1  # Symlink or copy of internal helper (TBD in implementation)

.specrew/
├── config.yml           # Existing: read `specrew_version`, `bootstrap_date`
├── last-start-prompt.md # Modified: updated by boundary-event sync
├── start-context.json   # Modified: updated by boundary-event sync
└── version-check-cache.json  # NEW: PSGallery latest-version cache

.squad/
├── identity/
│   └── now.md           # Modified: updated by boundary-event sync (companion chore establishes pattern)
└── decisions.md         # Modified: updated by boundary-event sync

specs/<feature>/
└── iterations/<NNN>/
    └── tasks-progress.yml  # NEW: per-task progress tracking (Iteration 2)

tests/
├── unit/
│   └── sync-boundary-state.tests.ps1  # NEW: atomic write, cross-file consistency
└── integration/
    ├── stale-state-detection.tests.ps1  # NEW: merge-detection, branch-missing, inconsistency
    ├── cross-worktree-awareness.tests.ps1  # NEW: multi-worktree scenarios
    └── version-checks.tests.ps1  # NEW: module mismatch, PSGallery check, caching
```

**Structure Decision**: This feature modifies existing Specrew CLI scripts (`specrew-start.ps1`, `specrew-where.ps1`, `specrew-init.ps1`, `specrew-update.ps1`) and adds a new internal helper script (`sync-boundary-state.ps1`). Session-state files (`.specrew/`, `.squad/`) are updated in-place. No new top-level directories required. Test coverage added to existing `tests/unit/` and `tests/integration/` directories.

## Complexity Tracking

> No constitutional violations requiring justification. This section documents boundary cases for transparency.

| Consideration | Design Choice | Simpler Alternative Rejected Because |
| ------------- | ------------- | ----------------------------------- |
| Cross-file session-state consistency | Write-temp-then-rename per file + stale-state detection | Transactional multi-file update (filesystem transaction log) rejected: not universally supported across NTFS/ext4/APFS; adds significant complexity for marginal benefit; stale-detect compensates adequately |
| Task progress tracking location | Sibling `tasks-progress.yml` file (separate from `tasks.md`) | Inline in `tasks.md` as frontmatter rejected: regenerating `tasks.md` would overwrite progress; separate file preserves planning stability per clarification Q2 |
| Cross-worktree state mechanism | Pure derivation from `git worktree list` (no persistent state) | Persistent cross-worktree index file rejected: introduces sync drift risk; derivation is fast enough (<2s for 10 worktrees) and always accurate per clarification Q3 |
| Stale-state detection git-log bound | Bounded by `bootstrap_date` from `.specrew/config.yml` | Unbounded `git log main` rejected: O(all commits) worst-case performance; bounded search is O(commits since bootstrap) and semantically correct (no Specrew features pre-bootstrap) per clarification blocker 3 |

**Constitutional Alignment**: All design choices align with Principle I (Spec Is Authoritative—implementation follows approved spec), Principle VII (Artifact Hierarchy of Authority—session-state files are lower authority than spec/plan), and Principle VIII (Reconciliation Over Silent Divergence—stale-state detection surfaces conflicts explicitly).

---

## Companion Chore: Establish `.squad/identity/now.md` Closeout Pattern

**Purpose**: Ship a small chore commit before Iteration 1 to establish the pattern of updating `.squad/identity/now.md` at feature closeout. This unblocks FR-004 implementation without requiring F-020 to invent the pattern.

**Context**: Clarification Q5 approved shipping a companion chore to fix the existing `.squad/identity/now.md` closeout bug (Squad currently doesn't update `now.md` at closeout, causing stale references). F-020's FR-004 extends this pattern to full boundary-event coverage, so establishing the closeout-specific case first reduces F-020's scope.

**Scope**: Modify existing closeout logic to update `.squad/identity/now.md` when feature closeout completes. Does NOT implement full boundary-event sync (that's Iteration 1's job).

**Phase 0 prerequisite**: Ensure Pester 5.5.0 is installed before Phase 0 validation begins (`Install-Module Pester -RequiredVersion 5.5.0 -Scope CurrentUser`) so the planned unit/integration suites run against the expected test surface.

### Companion Chore Task List

| Task ID | Task Title | Owner | Estimate | Dependencies | Description |
| ------- | ---------- | ----- | -------- | ------------ | ----------- |
| CHORE-001 | Identify closeout update point | Implementer | 0.5 SP | None | Locate where feature-closeout commit/merge happens in existing Specrew scripts (likely `specrew-review.ps1` or custom closeout script). Document current closeout flow. |
| CHORE-002 | Implement `.squad/identity/now.md` closeout update | Implementer | 0.5 SP | CHORE-001 | At feature closeout, write to `.squad/identity/now.md`: "No active feature. Last completed: Feature NNN at [timestamp]. Next roadmap item: [from roadmap.yml] (not yet authorized)". Use simple direct write (no write-temp-then-rename needed for single-location chore). |
| CHORE-003 | Test closeout update manually | Reviewer | 0.5 SP | CHORE-002 | Manually test: complete a feature closeout, verify `.squad/identity/now.md` updates correctly, verify Squad on next `specrew start` doesn't reference closed feature. |
| CHORE-004 | Commit chore to main | Implementer | 0.5 SP | CHORE-003 | Commit with message: "chore: establish .squad/identity/now.md closeout pattern (pre-F020)". Merge to main before F-020 Iteration 1 starts. |

**Total Companion Chore Estimate**: 2 SP  
**Delivery Requirement**: Must merge to `main` before F-020 Iteration 1 implementation begins.  
**Validation**: Post-chore, manually verify that a feature closeout updates `.squad/identity/now.md` and Squad no longer references the closed feature on next startup.

---

## Iteration 1 Plan: Foundational Correctness

**Scope**: Pillars 1 (Boundary-Event State Synchronization), 4 (Stale-State Detection), and Scope Addition 1 (Module Version Check)  
**Iteration Goal**: Establish durable session-state tracking with atomic updates and staleness detection. Users can safely reboot mid-work and Squad will accurately resume or prompt for re-orientation.  
**Success Metrics**: Zero Squad-acts-on-stale-state incidents post-deployment; `specrew start` staleness checks complete in <2s; boundary-event sync atomicity 95%+ across 100 events.

**Functional Requirements Delivered**:
- FR-001 through FR-005 (Pillar 1: Boundary-Event State Synchronization)
- FR-015 through FR-020 (Pillar 4: Stale-State Detection)
- FR-025 through FR-028 (Scope Addition 1: Module Version Check)

**User Stories Validated**:
- US1: Post-Reboot Recovery (acceptance scenarios 1, 2, 3, 4)
- US2: Boundary-Event State Synchronization (acceptance scenarios 1, 2, 3, 4, 5)
- US4: Module Version Mismatch Detection (acceptance scenarios 1, 2, 3)

### Iteration 1 Task Breakdown

#### Workstream 1.1: Boundary-Event Sync Helper (Pillar 1)

| Task ID | Task Title | Owner | Estimate | Dependencies | Acceptance Criteria |
| ------- | ---------- | ----- | -------- | ------------ | ------------------- |
| I1-T001 | Design `sync-boundary-state.ps1` API | Implementer | 1 SP | Companion Chore complete | API contract documented in `contracts/sync-boundary-state-api.md`: parameters (boundary type, feature number, iteration number, task ID), output (success/failure status), error handling. Contract reviewed and approved. |
| I1-T002 | Implement write-temp-then-rename for single file | Implementer | 1.5 SP | I1-T001 | Helper function `Write-FileAtomically` implemented: writes to `.tmp` file, renames to target. Unit tests cover: success case, disk-full simulation, permission-denied simulation. Passes on Windows/Linux/macOS. |
| I1-T003 | Implement multi-file sync orchestration | Implementer | 2 SP | I1-T002 | `sync-boundary-state.ps1` updates all four session-state files (`.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/identity/now.md`, `.squad/decisions.md`) using `Write-FileAtomically`. Updates are sequential (best-effort cross-file atomicity). Records timestamp, boundary type, feature ID, auth commit hash per FR-005. |
| I1-T004 | Integrate sync-boundary-state into seven boundaries | Implementer | 2 SP | I1-T003 | Seven lifecycle boundaries invoke `sync-boundary-state.ps1` per FR-003: specify, clarify, plan, tasks, review-signoff, iteration-closeout, feature-closeout. Integration points identified in existing Specrew commands. Tested manually for each boundary type. |
| I1-T005 | Test boundary-event sync atomicity | Reviewer | 1 SP | I1-T004 | Integration test suite `tests/integration/boundary-sync-atomicity.tests.ps1` validates: (1) all four files updated after boundary event, (2) content mutually consistent, (3) partial-write recovery (simulate crash mid-sync, verify stale-detect catches inconsistency). Manual backward-compatibility check also bootstraps a fresh project with no prior session-state files, runs `specrew start`, and verifies graceful initialization on first run (`backward-compatibility-check` gate). Test passes on Windows/Linux/macOS. |

**Workstream 1.1 Total**: 7.5 SP

#### Workstream 1.2: Stale-State Detection (Pillar 4)

| Task ID | Task Title | Owner | Estimate | Dependencies | Acceptance Criteria |
| ------- | ---------- | ----- | -------- | ------------ | ------------------- |
| I1-T006 | Implement merge-detection check (FR-015) | Implementer | 1.5 SP | None | At `specrew start`, read active feature from session-state files. Run `git log main --since="<bootstrap_date>" --merges --grep="<feature-number>"` (bootstrap_date from `.specrew/config.yml`). If commit found, feature was merged → stale state detected. Fallback to `--since="90 days ago"` if bootstrap_date missing (per research blocker 3). Unit tests cover: feature merged 1 day ago (found), feature merged 6 months ago (found), feature never merged (not found), bootstrap_date missing (fallback). |
| I1-T007 | Implement branch-existence check (FR-016) | Implementer | 0.5 SP | None | At `specrew start`, run `git rev-parse --verify <feature-branch>`. If exit code non-zero, branch doesn't exist → stale state signal. Combined with merge-detection for full staleness picture. |
| I1-T008 | Implement authorization-record check (FR-017) | Implementer | 1 SP | None | At `specrew start`, verify active feature has matching authorization record in `.squad/decisions.md` with commit reference. If missing, stale state detected. |
| I1-T009 | Implement cross-file consistency check (FR-018) | Implementer | 1.5 SP | None | At `specrew start`, verify `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/identity/now.md`, `.squad/decisions.md` all reference same feature and boundary. If mismatch, stale state detected. Detailed comparison logic: extract feature number and boundary type from each file, compare. |
| I1-T010 | Implement stale-state user prompt (FR-019, FR-020) | Implementer | 1.5 SP | I1-T006, I1-T007, I1-T008, I1-T009 | On staleness detection, present user with prompt: "Stale state detected: <specific details>. Options: (A) re-anchor to correct feature, (B) create new feature, (C) exit and manually fix state." No silent action on stale state. Error messages include what's stale, why it's stale, what user should do per FR-020. |
| I1-T011 | Test stale-state detection coverage | Reviewer | 1 SP | I1-T010 | Integration test suite `tests/integration/stale-state-detection.tests.ps1` validates: (1) feature merged yesterday (detected), (2) branch missing (detected), (3) auth record missing (detected), (4) cross-file inconsistency (detected), (5) all checks pass (no false positives). 100% of test cases pass. |

**Workstream 1.2 Total**: 7 SP

#### Workstream 1.3: Module Version Check (Scope Addition 1)

| Task ID | Task Title | Owner | Estimate | Dependencies | Acceptance Criteria |
| ------- | ---------- | ----- | -------- | ------------ | ------------------- |
| I1-T012 | Implement module-vs-project version comparison (FR-025) | Implementer | 0.5 SP | None | At `specrew start`, read installed module version via `(Get-Module Specrew).Version`. Read project version from `.specrew/config.yml` `specrew_version` field (per research blocker 1). Compare. If differ, set warning flag. |
| I1-T013 | Implement version mismatch warning (FR-026, FR-027, FR-028) | Implementer | 0.5 SP | I1-T012 | Display non-blocking warning: "Module version mismatch detected: installed X.Y.Z, project expects A.B.C. To update: specrew update". No interactive prompt. Does not prevent `specrew start` from continuing. |
| I1-T014 | Test module version check in CI | Reviewer | 0.5 SP | I1-T013 | Integration test `tests/integration/version-checks.tests.ps1` validates: (1) installed=project version → no warning, (2) installed≠project version → warning appears, (3) no interactive prompt, (4) `specrew start` continues after warning, and (5) CI captures a `specrew start` performance baseline showing <2s overhead across Windows/Linux/macOS (`performance-baseline` gate). |

**Workstream 1.3 Total**: 1.5 SP

### Iteration 1 Summary

**Total Estimate**: 16 SP (7.5 + 7 + 1.5)  
**Critical Path**: Companion Chore → I1-T001 → I1-T002 → I1-T003 → I1-T004 → I1-T005 (workstream 1.1 must complete before integration tests)  
**Parallel Work**: Workstreams 1.2 (stale-detect) and 1.3 (version check) can proceed independently after Companion Chore completes.  
**Risk Mitigation**: Workstream 1.1 (boundary sync) is foundational; if it slips, defer workstream 1.3 (version check) to Iteration 2 to preserve core correctness goal.

**Hardening Gate**: Post-implementation, run hardening gate per Phase 2 plan. Focus areas: atomicity failure modes, stale-state false negatives, cross-file consistency, filesystem-specific atomic-rename compatibility.

---

## Iteration 2 Plan: Visibility & UX Refinement

**Scope**: Pillars 2 (Task Progress Tracking), 3 (Cross-Worktree Awareness), 5 (Recovery Prompts), and Scope Addition 2 (PSGallery Check)  
**Iteration Goal**: Add in-flight progress visibility, cross-worktree "where am I?" reporting, substantive recovery prompts, and PSGallery update awareness. Users can query current state across multiple worktrees and receive actionable next-step guidance after reboot.  
**Success Metrics**: `specrew where` query <2s for 10 worktrees; recovery prompts include substantive next-step guidance 100% of the time; PSGallery check completes in <5s (cached), fails silently in <10s (offline).

**Functional Requirements Delivered**:
- FR-006 through FR-010 (Pillar 2: Task Progress Tracking)
- FR-011 through FR-014 (Pillar 3: Cross-Worktree Awareness)
- FR-021 through FR-024 (Pillar 5: Recovery Prompts)
- FR-029 through FR-035 (Scope Addition 2: PSGallery Check)

**User Stories Validated**:
- US3: Authoritative Where-Am-I Query (acceptance scenarios 1, 2, 3, 4)
- US5: PSGallery Latest-Version Check (acceptance scenarios 1, 2, 3, 4, 5)

### Iteration 2 Task Breakdown

#### Workstream 2.1: Task Progress Tracking (Pillar 2)

| Task ID | Task Title | Owner | Estimate | Dependencies | Acceptance Criteria |
| ------- | ---------- | ----- | -------- | ------------ | ------------------- |
| I2-T001 | Define `tasks-progress.yml` schema | Implementer | 0.5 SP | None | Schema documented in `contracts/session-state-schema.yml`: per-task fields (task ID, status [`pending`, `in-progress`, `complete`, `blocked`], started_at, completed_at, blocked_reason). Stable task IDs (e.g., `T001`, `T002`) per FR-010. Schema reviewed and approved. |
| I2-T002 | Implement task status update functions | Implementer | 1.5 SP | I2-T001 | Helper functions: `Set-TaskStatus -TaskId T001 -Status "in-progress"`, `Set-TaskComplete -TaskId T001`, `Set-TaskBlocked -TaskId T001 -Reason "..."`. Functions update `specs/<feature>/iterations/<NNN>/tasks-progress.yml`. Timestamps recorded per FR-008, FR-009. |
| I2-T003 | Integrate task progress into coordinator resume logic (FR-007) | Implementer | 1 SP | I2-T002 | At `specrew start`, coordinator reads `tasks-progress.yml` and surfaces in-progress task state in welcome-back prompt (see workstream 2.3). Manual integration test: mark T005 in-progress, reboot, verify prompt shows "Task T005 (in-progress)". |
| I2-T004 | Test task progress tracking stability | Reviewer | 1 SP | I2-T003 | Integration test suite validates: (1) task marked in-progress → `started_at` recorded, (2) task marked complete → `completed_at` recorded, (3) task marked blocked → `blocked_reason` required, (4) tasks-progress.yml survives `tasks.md` regeneration (stable IDs). Test passes on Windows/Linux/macOS. |

**Workstream 2.1 Total**: 4 SP

#### Workstream 2.2: Cross-Worktree Awareness (Pillar 3)

| Task ID | Task Title | Owner | Estimate | Dependencies | Acceptance Criteria |
| ------- | ---------- | ----- | -------- | ------------ | ------------------- |
| I2-T005 | Implement worktree derivation from `git worktree list` (FR-011) | Implementer | 1.5 SP | None | Function `Get-WorktreeState` calls `git worktree list --porcelain`, parses output, reads `.specify/feature.json` from each worktree, derives active feature number, current boundary, last activity timestamp per FR-011. No persistent cross-worktree state file (pure derivation per research blocker clarification Q3). |
| I2-T006 | Implement `specrew where --worktrees` command (FR-012) | Implementer | 1 SP | I2-T005 | `specrew where --worktrees` lists all worktrees with paths, active feature numbers, current boundaries, last activity timestamps per FR-012. If worktree path doesn't exist, annotate "(path not found)" and suggest `git worktree prune` per FR-013. |
| I2-T007 | Optimize cross-worktree derivation performance (FR-014) | Implementer | 1 SP | I2-T006 | Derivation completes in <2s for up to 10 worktrees. Performance measured in CI. If >2s, optimize by caching `git worktree list` output or parallelizing `.specify/feature.json` reads. |
| I2-T008 | Test cross-worktree awareness in multi-worktree scenarios | Reviewer | 1 SP | I2-T007 | Integration test suite validates: (1) single worktree (current only), (2) two worktrees with different features, (3) worktree path missing (annotated), (4) performance <2s for 10 worktrees. All tests pass. |

**Workstream 2.2 Total**: 4.5 SP

#### Workstream 2.3: Recovery Prompts (Pillar 5)

| Task ID | Task Title | Owner | Estimate | Dependencies | Acceptance Criteria |
| ------- | ---------- | ----- | -------- | ------------ | ------------------- |
| I2-T009 | Design substantive welcome-back prompt structure (FR-021) | Implementer | 0.5 SP | None | Prompt structure documented: active feature name/path/worktree, current boundary or task, last completed item with timestamp, validator state summary, suggested next actions. Reuses F-016 handoff style per clarification Q8. Structure reviewed and approved. |
| I2-T010 | Implement welcome-back prompt for mid-implementation (FR-022) | Implementer | 1.5 SP | I2-T001, I2-T009 | Welcome-back prompt shows which tasks are complete, in-progress, pending (from `tasks-progress.yml` per FR-022). Displays last completed boundary commit hash and timestamp from `.squad/decisions.md` per FR-023. Manual test: mark T003 complete, T004 in-progress, reboot, verify prompt shows "T001-T003 complete, T004 in-progress, T005 pending". |
| I2-T011 | Implement validator state summary in prompt (FR-024) | Implementer | 0.5 SP | I2-T010 | If validator warnings exist, prompt includes summary: "3 warnings: 2 soft, 1 medium" with command to view details per FR-024. Reads validator output from last run (if available). |
| I2-T012 | Test recovery prompt content quality | Reviewer | 0.5 SP | I2-T011 | Manual review: 5 recovery scenarios (post-reboot, post-boundary, mid-task, blocked task, validator warnings). Each prompt includes substantive next-step guidance (not just "do a review"). User feedback: 100% of prompts meet substantive-content bar per SC-006. |

**Workstream 2.3 Total**: 3 SP

#### Workstream 2.4: PSGallery Check (Scope Addition 2)

| Task ID | Task Title | Owner | Estimate | Dependencies | Acceptance Criteria |
| ------- | ---------- | ----- | -------- | ------------ | ------------------- |
| I2-T013 | Implement PSGallery latest-version query (FR-029) | Implementer | 1 SP | None | Function `Get-PSGalleryLatestVersion` queries `Find-Module Specrew -Repository PSGallery` for latest version. Caches result in `.specrew/version-check-cache.json` with timestamp per FR-030. Cache valid for 24h. Shared across `specrew start`, `specrew init`, `specrew update` per research blocker clarification Q12. |
| I2-T014 | Implement PSGallery update warning (FR-031, FR-035) | Implementer | 0.5 SP | I2-T013 | If installed < PSGallery latest, display non-blocking warning: "Newer version available: X.Y.Z (current: A.B.C). To update: Update-Module Specrew". No interactive prompt per FR-035. |
| I2-T015 | Implement skip-update-check flag and env var (FR-032, FR-033) | Implementer | 0.5 SP | I2-T014 | `--skip-update-check` flag suppresses PSGallery check per FR-032. Environment variable `SPECREW_SKIP_UPDATE_CHECK=1` also suppresses check per FR-033 (for CI/automation). |
| I2-T016 | Implement PSGallery check graceful degradation (FR-034) | Implementer | 0.5 SP | I2-T013 | If PSGallery unreachable (network error, timeout >10s), check fails silently with verbose logging only per FR-034. Does not block `specrew start`. |
| I2-T017 | Test PSGallery check in CI and offline scenarios | Reviewer | 1 SP | I2-T016 | Integration test suite validates: (1) cache hit (no network call), (2) cache miss (network call, <5s), (3) offline (graceful failure, <10s), (4) `--skip-update-check` suppresses check, (5) env var suppresses check. All tests pass. |

**Workstream 2.4 Total**: 3.5 SP

### Iteration 2 Summary

**Total Estimate**: 15 SP (4 + 4.5 + 3 + 3.5)  
**Critical Path**: I2-T001 → I2-T002 → I2-T003 → I2-T010 (task progress tracking feeds into recovery prompts)  
**Parallel Work**: Workstreams 2.2 (cross-worktree) and 2.4 (PSGallery) can proceed independently after Iteration 1 completes.  
**Risk Mitigation**: If task progress tracking (workstream 2.1) slips, deliver recovery prompts without task-level detail (boundary-level only) to preserve US3 acceptance criteria.

**Review Gate**: Post-implementation, conduct Review/Demo ceremony per Specrew governance. Validate acceptance criteria for US3 and US5. Confirm cross-worktree derivation performance (<2s) and PSGallery check graceful degradation (offline scenarios).

---

## Delivery Schedule

**Pre-Iteration 1**: Companion Chore (2 SP) → merge to `main`  
**Iteration 1**: 16 SP (2-3 weeks)  
**Hardening Gate**: Post-Iteration 1 (1-2 days)  
**Iteration 2**: 15 SP (2-3 weeks)  
**Review Gate**: Post-Iteration 2 (1 day)  
**Feature Closeout**: Final validation, retrospective, merge to `main`

**Total Feature Estimate**: 33 SP (2 + 16 + 15)  
**Variance from Spec Estimate**: +3 SP over spec's 25-30 SP estimate. Variance attributed to detailed task breakdown revealing additional integration and testing work. Within acceptable tolerance; no scope reduction required.

---

## Phase 1 Design Artifacts (Generated Next)

The following artifacts will be generated by continuing `/speckit.plan` execution:

1. **`data-model.md`**: Entity definitions for Session-State Record, Task Progress Entry, Worktree State, Version Check Cache (per spec lines 179-184)
2. **`contracts/session-state-schema.yml`**: YAML schema v1 for session-state file structure (per clarification Q6)
3. **`contracts/sync-boundary-state-api.md`**: Helper script API contract (parameters, return values, error handling)
4. **`quickstart.md`**: Developer quickstart for implementing boundary-event sync integration and stale-state detection checks

Post-Phase 1, re-check Constitution gates to ensure data-model and contracts align with constitutional principles.


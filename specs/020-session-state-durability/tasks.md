# Implementation Tasks: Session-State Durability & In-Flight Progress Tracking

> **Feature**: Session-State Durability & In-Flight Progress Tracking (F-020)  
> **Generated**: 2025-01-29  
> **Planning Commit**: 207eea1  
> **Total Story Points**: 33 SP (2 SP companion chore + 16 SP Iteration 1 + 15 SP Iteration 2)

## Task Format

Each task follows this structure:

```
- [ ] [TaskID] [P?] [Story?] [assigned_to: Role] [effort: N SP] Description (Trace: requirements)
```

- **[P]**: Parallelizable task (different files, no dependencies on incomplete tasks)
- **[US#]**: User story label from spec.md (US1, US2, US3, US4, US5)
- **assigned_to**: Role name from plan.md (Implementer, Reviewer)
- **effort**: Story point estimate from plan.md
- **Trace**: Functional requirements and source documents

---

## Phase 0: Companion Chore (Pre-F-020)

**Delivery Requirement**: Must merge to `main` BEFORE F-020 Iteration 1 begins.

**Goal**: Establish `.squad/identity/now.md` closeout pattern to prevent stale-state races at feature boundaries.

**Phase 0 prerequisite**: Ensure Pester 5.5.0 is installed before validation begins (`Install-Module Pester -RequiredVersion 5.5.0 -Scope CurrentUser`) so the planned unit/integration suites run against the expected test surface.

### Closeout Pattern Establishment

- [ ] CHORE-001 [assigned_to: Implementer] [effort: 0.5 SP] Identify closeout update point - Locate where feature-closeout commit/merge happens in existing Specrew scripts (likely `specrew-review.ps1` or custom closeout script); document current closeout flow (Trace: plan.md companion chore table)
- [ ] CHORE-002 [assigned_to: Implementer] [effort: 0.5 SP] Implement `.squad/identity/now.md` closeout update - At feature closeout, write to `.squad/identity/now.md`: "No active feature. Last completed: Feature NNN at [timestamp]. Next roadmap item: [from roadmap.yml] (not yet authorized)"; use simple direct write (no write-temp-then-rename needed for single-location chore) (Trace: plan.md companion chore table)
- [ ] CHORE-003 [assigned_to: Reviewer] [effort: 0.5 SP] Test closeout update manually - Manually test: complete a feature closeout, verify `.squad/identity/now.md` updates correctly, verify Squad on next `specrew start` doesn't reference closed feature (Trace: plan.md companion chore table)
- [ ] CHORE-004 [assigned_to: Implementer] [effort: 0.5 SP] Commit chore to main - Commit with message: "chore: establish .squad/identity/now.md closeout pattern (pre-F020)"; merge to main before F-020 Iteration 1 starts (Trace: plan.md companion chore table)

**Phase 0 Total**: 4 tasks, 2 SP

---

## Phase 1: Iteration 1 - Foundational Correctness

**Iteration Goal**: Establish durable session-state tracking with atomic updates and staleness detection. Users can safely reboot mid-work and Squad will accurately resume or prompt for re-orientation.

**Functional Requirements**: FR-001 through FR-005 (Pillar 1), FR-015 through FR-020 (Pillar 4), FR-025 through FR-028 (Scope Addition 1)

**User Stories Validated**: US1 (Post-Reboot Recovery), US2 (Boundary-Event State Synchronization), US4 (Module Version Mismatch Detection)

**Success Metrics**: Zero Squad-acts-on-stale-state incidents post-deployment; `specrew start` staleness checks complete in <2s; boundary-event sync atomicity 95%+ across 100 events.

### Phase 1.1: Boundary-Event Sync Helper (Pillar 1)

**Goal**: Implement atomic session-state updates at seven lifecycle boundaries using write-temp-then-rename pattern.

- [ ] I1-T001 [US2] [assigned_to: Implementer] [effort: 1 SP] Design `sync-boundary-state.ps1` API - Document API contract in `contracts/sync-boundary-state-api.md`: parameters (boundary type, feature number, iteration number, task ID), output (success/failure status), error handling; contract reviewed and approved (Trace: FR-001, FR-002, FR-003, plan.md I1-T001)
- [ ] I1-T002 [US2] [assigned_to: Implementer] [effort: 1.5 SP] Implement write-temp-then-rename for single file - Create helper function `Write-FileAtomically` in `scripts/powershell/sync-boundary-state.ps1`: writes to `.tmp` file, renames to target; unit tests cover success case, disk-full simulation, permission-denied simulation; passes on Windows/Linux/macOS (Trace: FR-004, plan.md I1-T002)
- [ ] I1-T003 [US2] [assigned_to: Implementer] [effort: 2 SP] Implement multi-file sync orchestration - Implement `sync-boundary-state.ps1` to update all four session-state files (`.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/identity/now.md`, `.squad/decisions.md`) using `Write-FileAtomically`; updates are sequential (best-effort cross-file atomicity); records timestamp, boundary type, feature ID, auth commit hash per FR-005 (Trace: FR-005, plan.md I1-T003)
- [ ] I1-T004 [US2] [assigned_to: Implementer] [effort: 2 SP] Integrate sync-boundary-state into seven boundaries - Integrate `sync-boundary-state.ps1` invocation at seven lifecycle boundaries per FR-003: specify, clarify, plan, tasks, review-signoff, iteration-closeout, feature-closeout; identify integration points in existing Specrew commands; test manually for each boundary type (Trace: FR-003, plan.md I1-T004)
- [ ] I1-T005 [US2] [assigned_to: Reviewer] [effort: 1 SP] Test boundary-event sync atomicity - Create integration test suite `tests/integration/boundary-sync-atomicity.tests.ps1` validating: (1) all four files updated after boundary event, (2) content mutually consistent, (3) partial-write recovery (simulate crash mid-sync, verify stale-detect catches inconsistency); add manual backward-compatibility evidence by bootstrapping a fresh project with no prior session-state files, running `specrew start`, and verifying graceful initialization on first run; test passes on Windows/Linux/macOS (Trace: FR-001, FR-004, backward-compatibility-check gate, plan.md I1-T005)

**Phase 1.1 Total**: 5 tasks, 7.5 SP

### Phase 1.2: Stale-State Detection (Pillar 4)

**Goal**: Detect stale session state at `specrew start` via merge-detection, branch-existence, authorization-record, and cross-file consistency checks.

- [ ] I1-T006 [P] [US1] [assigned_to: Implementer] [effort: 1.5 SP] Implement merge-detection check (FR-015) - At `specrew start`, read active feature from session-state files; run `git log main --since="<bootstrap_date>" --merges --grep="<feature-number>"` (bootstrap_date from `.specrew/config.yml`); if commit found, feature was merged → stale state detected; fallback to `--since="90 days ago"` if bootstrap_date missing; unit tests cover: feature merged 1 day ago (found), feature merged 6 months ago (found), feature never merged (not found), bootstrap_date missing (fallback) (Trace: FR-015, plan.md I1-T006)
- [ ] I1-T007 [P] [US1] [assigned_to: Implementer] [effort: 0.5 SP] Implement branch-existence check (FR-016) - At `specrew start`, run `git rev-parse --verify <feature-branch>`; if exit code non-zero, branch doesn't exist → stale state signal; combined with merge-detection for full staleness picture (Trace: FR-016, plan.md I1-T007)
- [ ] I1-T008 [P] [US1] [assigned_to: Implementer] [effort: 1 SP] Implement authorization-record check (FR-017) - At `specrew start`, verify active feature has matching authorization record in `.squad/decisions.md` with commit reference; if missing, stale state detected (Trace: FR-017, plan.md I1-T008)
- [ ] I1-T009 [P] [US1] [assigned_to: Implementer] [effort: 1.5 SP] Implement cross-file consistency check (FR-018) - At `specrew start`, verify `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/identity/now.md`, `.squad/decisions.md` all reference same feature and boundary; if mismatch, stale state detected; detailed comparison logic: extract feature number and boundary type from each file, compare (Trace: FR-018, plan.md I1-T009)
- [ ] I1-T010 [US1] [assigned_to: Implementer] [effort: 1.5 SP] Implement stale-state user prompt (FR-019, FR-020) - On staleness detection, present user with prompt: "Stale state detected: <specific details>. Options: (A) re-anchor to correct feature, (B) create new feature, (C) exit and manually fix state"; no silent action on stale state; error messages include what's stale, why it's stale, what user should do per FR-020 (Trace: FR-019, FR-020, plan.md I1-T010)
- [ ] I1-T011 [US1] [assigned_to: Reviewer] [effort: 1 SP] Test stale-state detection coverage - Create integration test suite `tests/integration/stale-state-detection.tests.ps1` validating: (1) feature merged yesterday (detected), (2) branch missing (detected), (3) auth record missing (detected), (4) cross-file inconsistency (detected), (5) all checks pass (no false positives); 100% of test cases pass (Trace: FR-015, FR-016, FR-017, FR-018, plan.md I1-T011)

**Phase 1.2 Total**: 6 tasks, 7 SP

### Phase 1.3: Module Version Check (Scope Addition 1)

**Goal**: Detect module-vs-project version mismatches and display non-blocking warnings with update guidance.

- [ ] I1-T012 [P] [US4] [assigned_to: Implementer] [effort: 0.5 SP] Implement module-vs-project version comparison (FR-025) - At `specrew start`, read installed module version via `(Get-Module Specrew).Version`; read project version from `.specrew/config.yml` `specrew_version` field; compare; if differ, set warning flag (Trace: FR-025, plan.md I1-T012)
- [ ] I1-T013 [US4] [assigned_to: Implementer] [effort: 0.5 SP] Implement version mismatch warning (FR-026, FR-027, FR-028) - Display non-blocking warning: "Module version mismatch detected: installed X.Y.Z, project expects A.B.C. To update: specrew update"; no interactive prompt; does not prevent `specrew start` from continuing (Trace: FR-026, FR-027, FR-028, plan.md I1-T013)
- [ ] I1-T014 [US4] [assigned_to: Reviewer] [effort: 0.5 SP] Test module version check in CI - Create integration test `tests/integration/version-checks.tests.ps1` validating: (1) installed=project version → no warning, (2) installed≠project version → warning appears, (3) no interactive prompt, (4) `specrew start` continues after warning, and (5) CI captures a `specrew start` performance baseline showing <2s overhead on Windows/Linux/macOS; test passes on Windows/Linux/macOS (Trace: FR-025, FR-026, FR-027, FR-028, performance-baseline gate, plan.md I1-T014)

**Phase 1.3 Total**: 3 tasks, 1.5 SP

---

## Phase 2: Iteration 2 - In-Flight Progress Tracking

**Iteration Goal**: Add task-level progress tracking, cross-worktree awareness, substantive recovery prompts, and PSGallery update checks.

**Functional Requirements**: FR-006 through FR-014 (Pillars 2, 3), FR-021 through FR-024 (Pillar 5), FR-029 through FR-035 (Scope Addition 2)

**User Stories Validated**: US3 (In-Flight Progress Tracking), US5 (Cross-Worktree Awareness)

**Success Metrics**: 100% of recovery prompts include substantive next-step guidance; cross-worktree derivation completes in <2s for up to 10 worktrees; PSGallery check cache hit rate >80%.

### Phase 2.1: Task Progress Tracking (Pillar 2)

**Goal**: Track task-level status (pending, in-progress, complete, blocked) in `tasks-progress.yml` with stable IDs and timestamps.

- [ ] I2-T001 [US3] [assigned_to: Implementer] [effort: 0.5 SP] Define `tasks-progress.yml` schema - Document schema in `contracts/session-state-schema.yml`: per-task fields (task ID, status [`pending`, `in-progress`, `complete`, `blocked`], started_at, completed_at, blocked_reason); stable task IDs (e.g., `T001`, `T002`) per FR-010; schema reviewed and approved (Trace: FR-006, FR-007, FR-008, FR-009, FR-010, plan.md I2-T001)
- [ ] I2-T002 [US3] [assigned_to: Implementer] [effort: 1.5 SP] Implement task status update functions - Create helper functions in `scripts/powershell/task-progress.ps1`: `Set-TaskStatus -TaskId T001 -Status "in-progress"`, `Set-TaskComplete -TaskId T001`, `Set-TaskBlocked -TaskId T001 -Reason "..."`; functions update `specs/<feature>/iterations/<NNN>/tasks-progress.yml`; timestamps recorded per FR-008, FR-009 (Trace: FR-007, FR-008, FR-009, plan.md I2-T002)
- [ ] I2-T003 [US3] [assigned_to: Implementer] [effort: 1 SP] Integrate task progress into coordinator resume logic (FR-007) - At `specrew start`, coordinator reads `tasks-progress.yml` and surfaces in-progress task state in welcome-back prompt (see Phase 2.3); manual integration test: mark T005 in-progress, reboot, verify prompt shows "Task T005 (in-progress)" (Trace: FR-007, plan.md I2-T003)
- [ ] I2-T004 [US3] [assigned_to: Reviewer] [effort: 1 SP] Test task progress tracking stability - Create integration test suite `tests/integration/task-progress-tracking.tests.ps1` validating: (1) task marked in-progress → `started_at` recorded, (2) task marked complete → `completed_at` recorded, (3) task marked blocked → `blocked_reason` required, (4) tasks-progress.yml survives `tasks.md` regeneration (stable IDs); test passes on Windows/Linux/macOS (Trace: FR-006, FR-008, FR-009, FR-010, plan.md I2-T004)

**Phase 2.1 Total**: 4 tasks, 4 SP

### Phase 2.2: Cross-Worktree Awareness (Pillar 3)

**Goal**: Derive cross-worktree state from `git worktree list` and `.specify/feature.json` files; support `specrew where --worktrees` command.

- [ ] I2-T005 [P] [US5] [assigned_to: Implementer] [effort: 1.5 SP] Implement worktree derivation from `git worktree list` (FR-011) - Create function `Get-WorktreeState` in `scripts/powershell/worktree-awareness.ps1`: calls `git worktree list --porcelain`, parses output, reads `.specify/feature.json` from each worktree, derives active feature number, current boundary, last activity timestamp per FR-011; no persistent cross-worktree state file (pure derivation) (Trace: FR-011, plan.md I2-T005)
- [ ] I2-T006 [US5] [assigned_to: Implementer] [effort: 1 SP] Implement `specrew where --worktrees` command (FR-012) - Implement `specrew where --worktrees` in `Specrew.psm1`: lists all worktrees with paths, active feature numbers, current boundaries, last activity timestamps per FR-012; if worktree path doesn't exist, annotate "(path not found)" and suggest `git worktree prune` per FR-013 (Trace: FR-012, FR-013, plan.md I2-T006)
- [ ] I2-T007 [US5] [assigned_to: Implementer] [effort: 1 SP] Optimize cross-worktree derivation performance (FR-014) - Ensure derivation completes in <2s for up to 10 worktrees; measure performance in CI; if >2s, optimize by caching `git worktree list` output or parallelizing `.specify/feature.json` reads (Trace: FR-014, plan.md I2-T007)
- [ ] I2-T008 [US5] [assigned_to: Reviewer] [effort: 1 SP] Test cross-worktree awareness in multi-worktree scenarios - Create integration test suite `tests/integration/cross-worktree-awareness.tests.ps1` validating: (1) single worktree (current only), (2) two worktrees with different features, (3) worktree path missing (annotated), (4) performance <2s for 10 worktrees; all tests pass (Trace: FR-011, FR-012, FR-013, FR-014, plan.md I2-T008)

**Phase 2.2 Total**: 4 tasks, 4.5 SP

### Phase 2.3: Recovery Prompts (Pillar 5)

**Goal**: Present substantive welcome-back prompts showing active feature, current boundary/task, completed items, validator state, and next actions.

- [ ] I2-T009 [US3] [assigned_to: Implementer] [effort: 0.5 SP] Design substantive welcome-back prompt structure (FR-021) - Document prompt structure in `contracts/welcome-back-prompt.md`: active feature name/path/worktree, current boundary or task, last completed item with timestamp, validator state summary, suggested next actions; reuses F-016 handoff style; structure reviewed and approved (Trace: FR-021, plan.md I2-T009)
- [ ] I2-T010 [US3] [assigned_to: Implementer] [effort: 1.5 SP] Implement welcome-back prompt for mid-implementation (FR-022) - Implement welcome-back prompt in `scripts/powershell/coordinator-resume.ps1`: shows which tasks are complete, in-progress, pending (from `tasks-progress.yml` per FR-022); displays last completed boundary commit hash and timestamp from `.squad/decisions.md` per FR-023; manual test: mark T003 complete, T004 in-progress, reboot, verify prompt shows "T001-T003 complete, T004 in-progress, T005 pending" (Trace: FR-022, FR-023, plan.md I2-T010)
- [ ] I2-T011 [US3] [assigned_to: Implementer] [effort: 0.5 SP] Implement validator state summary in prompt (FR-024) - If validator warnings exist, prompt includes summary: "3 warnings: 2 soft, 1 medium" with command to view details per FR-024; reads validator output from last run (if available) (Trace: FR-024, plan.md I2-T011)
- [ ] I2-T012 [US3] [assigned_to: Reviewer] [effort: 0.5 SP] Test recovery prompt content quality - Manual review: 5 recovery scenarios (post-reboot, post-boundary, mid-task, blocked task, validator warnings); each prompt includes substantive next-step guidance (not just "do a review"); user feedback: 100% of prompts meet substantive-content bar per success criteria (Trace: FR-021, FR-022, FR-023, FR-024, plan.md I2-T012)

**Phase 2.3 Total**: 4 tasks, 3 SP

### Phase 2.4: PSGallery Check (Scope Addition 2)

**Goal**: Check PSGallery for newer Specrew versions with 24h caching, skip flag, and graceful degradation for offline scenarios.

- [ ] I2-T013 [P] [] [assigned_to: Implementer] [effort: 1 SP] Implement PSGallery latest-version query (FR-029) - Create function `Get-PSGalleryLatestVersion` in `scripts/powershell/version-check.ps1`: queries `Find-Module Specrew -Repository PSGallery` for latest version; caches result in `.specrew/version-check-cache.json` with timestamp per FR-030; cache valid for 24h; shared across `specrew start`, `specrew init`, `specrew update` (Trace: FR-029, FR-030, plan.md I2-T013)
- [ ] I2-T014 [] [assigned_to: Implementer] [effort: 0.5 SP] Implement PSGallery update warning (FR-031, FR-035) - If installed < PSGallery latest, display non-blocking warning: "Newer version available: X.Y.Z (current: A.B.C). To update: Update-Module Specrew"; no interactive prompt per FR-035 (Trace: FR-031, FR-035, plan.md I2-T014)
- [ ] I2-T015 [] [assigned_to: Implementer] [effort: 0.5 SP] Implement skip-update-check flag and env var (FR-032, FR-033) - Add `--skip-update-check` flag to `specrew start` command: suppresses PSGallery check per FR-032; add environment variable `SPECREW_SKIP_UPDATE_CHECK=1` support: also suppresses check per FR-033 (for CI/automation) (Trace: FR-032, FR-033, plan.md I2-T015)
- [ ] I2-T016 [] [assigned_to: Implementer] [effort: 0.5 SP] Implement PSGallery check graceful degradation (FR-034) - If PSGallery unreachable (network error, timeout >10s), check fails silently with verbose logging only per FR-034; does not block `specrew start` (Trace: FR-034, plan.md I2-T016)
- [ ] I2-T017 [] [assigned_to: Reviewer] [effort: 1 SP] Test PSGallery check in CI and offline scenarios - Create integration test suite `tests/integration/psgallery-check.tests.ps1` validating: (1) cache hit (no network call), (2) cache miss (network call, <5s), (3) offline (graceful failure, <10s), (4) `--skip-update-check` suppresses check, (5) env var suppresses check; all tests pass (Trace: FR-029, FR-030, FR-032, FR-033, FR-034, plan.md I2-T017)

**Phase 2.4 Total**: 5 tasks, 3.5 SP

---

## Dependencies & Execution Order

### Companion Chore Critical Path

```
CHORE-001 → CHORE-002 → CHORE-003 → CHORE-004
```

**Delivery Gate**: CHORE-004 must merge to `main` before I1-T001 begins.

### Iteration 1 Critical Path

```
I1-T001 → I1-T002 → I1-T003 → I1-T004 → I1-T005
```

**Explanation**: Workstream 1.1 (Boundary-Event Sync) is the critical path because atomic session-state updates must be operational before integration tests can validate end-to-end correctness. Tasks I1-T001 through I1-T004 build the sync infrastructure sequentially, and I1-T005 depends on I1-T004 to test the integrated system.

**Note on User's Expected Critical Path**: The user anticipated `I1-T001 -> I1-T004 -> I1-T007`, but the actual critical path goes through I1-T002 and I1-T003 first (atomic write helper and multi-file orchestration must be implemented before integration at I1-T004). Task I1-T007 (branch-existence check) is part of workstream 1.2 and can proceed in parallel after the companion chore completes.

**Parallel Work (Iteration 1)**:

- Workstream 1.2 (Stale-State Detection): I1-T006, I1-T007, I1-T008, I1-T009 (four tasks marked [P]) can proceed in parallel with each other after Companion Chore completes; I1-T010 depends on all four; I1-T011 depends on I1-T010
- Workstream 1.3 (Module Version Check): I1-T012 (marked [P]) can start immediately after Companion Chore; I1-T013 depends on I1-T012; I1-T014 depends on I1-T013

### Iteration 2 Critical Path

```
I2-T001 → I2-T002 → I2-T003 → I2-T010
```

**Explanation**: Task progress tracking (workstream 2.1) feeds into recovery prompts (workstream 2.3). I2-T010 (welcome-back prompt implementation) depends on I2-T003 (coordinator resume logic integration) to read `tasks-progress.yml` and surface in-progress task state.

**Parallel Work (Iteration 2)**:

- Workstream 2.2 (Cross-Worktree Awareness): I2-T005 (marked [P]) can start immediately after Iteration 1 completes; I2-T006, I2-T007, I2-T008 follow sequentially
- Workstream 2.4 (PSGallery Check): I2-T013 (marked [P]) can start immediately after Iteration 1 completes; I2-T014, I2-T015, I2-T016, I2-T017 follow sequentially

### Inter-Iteration Dependencies

```
Companion Chore → Iteration 1 → Iteration 2
```

No task in Iteration 2 can begin until Iteration 1 is complete (integration tested and merged).

---

## Parallel Execution Opportunities

### Companion Chore

- **Sequential only**: All tasks have dependencies on previous task

### Iteration 1

- **Parallel streams after Companion Chore**:
  - Stream A (critical path): I1-T001 → I1-T002 → I1-T003 → I1-T004 → I1-T005
  - Stream B (stale-detect): I1-T006, I1-T007, I1-T008, I1-T009 in parallel → I1-T010 → I1-T011
  - Stream C (version check): I1-T012 → I1-T013 → I1-T014

**Max Parallelization (Iteration 1)**: 5 tasks simultaneously (I1-T006, I1-T007, I1-T008, I1-T009 + one task from Stream A or C)

### Iteration 2

- **Parallel streams after Iteration 1**:
  - Stream A (critical path): I2-T001 → I2-T002 → I2-T003 → I2-T009 (design) → I2-T010 → I2-T011 → I2-T012
  - Stream B (cross-worktree): I2-T005 → I2-T006 → I2-T007 → I2-T008
  - Stream C (PSGallery): I2-T013 → I2-T014 → I2-T015 → I2-T016 → I2-T017

**Max Parallelization (Iteration 2)**: 3 tasks simultaneously (one from each stream, e.g., I2-T001 + I2-T005 + I2-T013)

---

## Implementation Strategy

### MVP Scope

**Companion Chore** (2 SP): Establishes baseline closeout pattern to prevent stale-state races at feature boundaries. This is the minimum viable foundation for F-020.

### Incremental Delivery

1. **Companion Chore** → Merge to main, validate manually
2. **Iteration 1** (16 SP) → Deliver foundational correctness (boundary sync + stale-detect + version check)
3. **Iteration 2** (15 SP) → Add in-flight progress tracking, cross-worktree awareness, recovery prompts, PSGallery check

### Risk Mitigation

- **If workstream 2.1 (task progress) slips**: Deliver recovery prompts without task-level detail (boundary-level only) to preserve US3 acceptance criteria
- **If cross-worktree performance >2s**: Document workaround (manual `git worktree prune`) and add performance optimization to tech debt backlog

---

## Task Completion Summary

- **Phase 0 (Companion Chore)**: 4 tasks, 2 SP
- **Phase 1 (Iteration 1)**: 14 tasks, 16 SP
  - Phase 1.1 (Boundary Sync): 5 tasks, 7.5 SP
  - Phase 1.2 (Stale-State Detection): 6 tasks, 7 SP
  - Phase 1.3 (Module Version Check): 3 tasks, 1.5 SP
- **Phase 2 (Iteration 2)**: 17 tasks, 15 SP
  - Phase 2.1 (Task Progress): 4 tasks, 4 SP
  - Phase 2.2 (Cross-Worktree): 4 tasks, 4.5 SP
  - Phase 2.3 (Recovery Prompts): 4 tasks, 3 SP
  - Phase 2.4 (PSGallery Check): 5 tasks, 3.5 SP

**Total**: 35 tasks, 33 SP

---

## Format Validation

✅ All tasks follow checklist format: `- [ ] [TaskID] [P?] [Story?] [assigned_to: ...] [effort: ...] Description (Trace: ...)`  
✅ Task IDs are sequential and stable (CHORE-001 through CHORE-004, I1-T001 through I1-T014, I2-T001 through I2-T017)  
✅ [P] markers applied only to parallelizable tasks (11 tasks marked [P])  
✅ User story labels (US1, US2, US3, US4, US5) map to priorities from spec.md  
✅ Owner and effort fields populated from plan.md  
✅ Trace fields reference functional requirements and plan.md task table

---

## Next Steps

1. **Execute Companion Chore**: Start with CHORE-001, complete all four tasks, merge to main
2. **Begin Iteration 1**: After Companion Chore merge, start parallel streams (I1-T001 + I1-T006 + I1-T012)
3. **Integration Testing**: I1-T005 and I1-T011 must pass before Iteration 1 closeout
4. **Iteration 1 Closeout**: Merge Iteration 1 branch to main, validate success metrics
5. **Begin Iteration 2**: After Iteration 1 merge, start parallel streams (I2-T001 + I2-T005 + I2-T013)
6. **Iteration 2 Closeout**: Merge Iteration 2 branch to main, validate success metrics
7. **Feature Closeout**: Complete F-020 closeout per established pattern from Companion Chore

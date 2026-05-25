# Tasks: F-046 Specrew Bug-Bash Bundle

**Input**: Design documents from `specs/046-046-bug-bash/`  
**Prerequisites**: `plan.md`, `spec.md`, `findings.md`, `data-model.md`, `contracts/sync-contract.md`, `quickstart.md`  
**Scope Guardrail**: Strictly limited to the 5-item F-046 defect bundle in plan/spec.

## Phase 1: Setup & US1 - Stale-State Allow-List

**Purpose**: Map `retro` as a valid boundary in the stale-state detector to prevent false-positive drift warnings.

- [ ] T001 [P] [assigned_to: Implementer] [effort: S] Create stale-state allow-list regression fixtures in `tests/integration/stale-state-retro.tests.ps1` asserting that a `retro` boundary with an accepted `review.md` passes without warning, while a `tasks` boundary still triggers (Trace: FR-001, SC-001, SC-006)
- [ ] T002 [assigned_to: Implementer] [effort: S] Map `retro` as an allowed boundary in `scripts/specrew-start.ps1` and `scripts/specrew-review.ps1` allow-lists (Trace: FR-001, SC-001)

---

## Phase 2: US2 - Atomic Boundary Sync

**Purpose**: Implement atomic inline verdict recording during boundary synchronization to prevent cursor-to-audit-trail drift.

- [ ] T003 [P] [assigned_to: Implementer] [effort: M] Create atomic boundary sync validation fixtures in `tests/integration/boundary-sync-atomic.tests.ps1` verifying that `sync-boundary-state.ps1` advances both cursor and verdict history atomically (Trace: FR-002, FR-003, SC-002, SC-006)
- [ ] T004 [assigned_to: Implementer] [effort: M] Implement inline verdict writer and `Add-SpecrewBoundaryAuthorization` call in `scripts/internal/sync-boundary-state.ps1` to atomically update both sections in the same write pass (Trace: FR-002, FR-003, SC-002)

---

## Phase 3: US3 - Scaffolder Protection

**Purpose**: Protect accepted and populated review/retro artifacts from being overwritten by template defaults during subsequent runs.

- [ ] T005 [P] [assigned_to: Reviewer] [effort: M] Create artifact protection validation tests in `tests/integration/scaffolder-protection.tests.ps1` verifying that scaffolders skip overwrite and output to `.pending` when populated verdicts are found (Trace: FR-004, SC-003, SC-006)
- [ ] T006 [assigned_to: Reviewer] [effort: M] Implement `Test-SpecrewFileHasPopulatedVerdict` check and pending-redirect logic in `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1`, `scaffold-review-artifact.ps1`, and `scaffold-retro-artifact.ps1` (Trace: FR-004, SC-003)
- [ ] T007 [assigned_to: Reviewer] [effort: S] Mirror scaffolder changes to `.specify/extensions/specrew-speckit/scripts/` counterparts to preserve template parity (Trace: FR-004, FR-007, SC-003)

---

## Phase 4: US4 - Resilient Alias Translation

**Purpose**: Remove static parameter ValidateSets and implement resilient, prose-friendly alias translation for boundary names.

- [ ] T008 [P] [assigned_to: Implementer] [effort: S] Create prose alias translation fixtures in `tests/integration/prose-alias-sync.tests.ps1` verifying that aliases map correctly and helpful error messages suggest did-you-mean options for bad input (Trace: FR-005, SC-004, SC-006)
- [ ] T009 [assigned_to: Implementer] [effort: S] Remove parameter `[ValidateSet]` and implement dynamic alias mapping in `extensions/specrew-speckit/scripts/sync-boundary-state.ps1` wrappers and `scripts/internal/sync-boundary-state.ps1` handlers (Trace: FR-005, SC-004)
- [ ] T010 [assigned_to: Implementer] [effort: S] Mirror boundary-sync alias changes to `.specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1` wrapper (Trace: FR-005, FR-007, SC-004)

---

## Phase 5: US5 - findings.md Ledger Completion & Polish

**Purpose**: Validate findings ledger, run mechanical checks, and confirm complete governance compliance.

- [ ] T011 [assigned_to: Doc Steward] [effort: S] Complete `specs/046-046-bug-bash/findings.md` logging all repro, root cause, and validation evidence, including the detailed documentation note for Bug 5 (Trace: FR-006, SC-005)
- [ ] T012 [P] [assigned_to: Reviewer] [effort: S] Run mechanical checks via `.specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1` and validate outputs (Trace: FR-007, SC-006)
- [ ] T013 [assigned_to: Reviewer] [effort: S] Execute governance validation via `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` and record results (Trace: FR-007, SC-006)

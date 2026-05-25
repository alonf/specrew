# Tasks: Specrew v0.27.1 Bug-Fix Bundle

**Input**: Design documents from `specs/045-v0271-bugfix-bundle/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/cli-behavior-contract.md`, `quickstart.md`  
**Scope Guardrail**: Strictly limited to the 7-item v0.27.1 post-release bug-fix bundle in plan/spec.

## Phase 1: Setup (Patch Bundle Initialization)

**Purpose**: Initialize patch-slice artifacts and bounded finding ledger before code changes.

- [ ] T001 [assigned_to: Reviewer] [effort: S] Create patch finding ledger in `specs/045-v0271-bugfix-bundle/iterations/001/finding-disposition.md` for F1-F7 actionable-vs-stale tracking (Trace: FR-003, TG-006, TG-007)
- [ ] T002 [P] [assigned_to: Reviewer] [effort: S] Create traceability matrix in `specs/045-v0271-bugfix-bundle/iterations/001/traceability-matrix.md` mapping US1-US3 to FR-001..FR-008 and SC-001..SC-006 (Trace: TG-001, TG-002, TG-003, TG-004)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish shared lifecycle primitives and governance mirror integrity required by all stories.  
**⚠️ Critical**: Complete this phase before user-story implementation.

- [ ] T003 [assigned_to: Implementer] [effort: M] Create shared skill-catalog state helpers in `scripts/internal/skill-catalog-state.ps1` for missing-root detection and repair/deploy gap evaluation (Trace: FR-004, FR-005, SC-003)
- [ ] T004 [P] [assigned_to: Implementer] [effort: S] Wire shared helper into `scripts/specrew-start.ps1` import/bootstrap path without changing unrelated startup behavior (Trace: FR-004, FR-008, TG-004)
- [ ] T005 [P] [assigned_to: Implementer] [effort: S] Wire shared helper into `scripts/specrew-init.ps1` import/bootstrap path for both force and non-force entry paths (Trace: FR-005, FR-008, TG-004)
- [ ] T006 [assigned_to: Reviewer] [effort: S] Validate governance mirror parity for helper imports across `extensions/specrew-speckit/scripts/` and `.specify/extensions/specrew-speckit/scripts/` affected loaders (Trace: FR-008, TG-004)

**Checkpoint**: Shared runtime and governance foundations are in place; user stories can proceed.

---

## Phase 3: User Story 1 - Reliable Patch Behavior for Core Commands (Priority: P1) 🎯 MVP

**Goal**: Restore version alias parity, correct warning behavior, and recoverable start/init skill-catalog flows.  
**Independent Test**: Run `tests/integration/validate-versions-cli-behavior.ps1` and `tests/integration/start-recovery-flow.tests.ps1` in project and non-project contexts.

### Tests for User Story 1

- [ ] T007 [P] [US1] [assigned_to: Implementer] [effort: M] Extend version CLI regression coverage in `tests/integration/validate-versions-cli-behavior.ps1` for `--version`/`-v` parity and false-warning suppression checks (Trace: FR-001, FR-002, SC-001, SC-002, SC-006, TG-001)
- [ ] T008 [P] [US1] [assigned_to: Implementer] [effort: M] Extend start/init recovery regression coverage in `tests/integration/start-recovery-flow.tests.ps1` for missing skill-catalog auto-repair and deployable-gap behavior in force/non-force paths (Trace: FR-004, FR-005, SC-003, SC-006, TG-001)

### Implementation for User Story 1

- [ ] T009 [US1] [assigned_to: Implementer] [effort: S] Add top-level `--version` and `-v` routing parity in `scripts/specrew.ps1` to dispatch through canonical version behavior (Trace: FR-001, SC-001, TG-001)
- [ ] T010 [US1] [assigned_to: Implementer] [effort: S] Gate warning emission in `scripts/specrew-version.ps1` so "version could not be determined" appears only for true unknown states (Trace: FR-002, SC-002, TG-001)
- [ ] T011 [US1] [assigned_to: Implementer] [effort: M] Implement missing skill-catalog auto-repair before normal continuation in `scripts/specrew-start.ps1` using shared state helper (Trace: FR-004, SC-003, TG-001)
- [ ] T012 [US1] [assigned_to: Implementer] [effort: M] Implement deployable-gap continuation for non-force init path in `scripts/specrew-init.ps1` when skill-catalog roots are missing (Trace: FR-005, SC-003, TG-001)
- [ ] T013 [US1] [assigned_to: Implementer] [effort: M] Implement deployable-gap continuation for force init path in `scripts/specrew-init.ps1` with no false early-success branch (Trace: FR-005, SC-003, TG-001)
- [ ] T014 [US1] [assigned_to: Reviewer] [effort: S] Update `specs/045-v0271-bugfix-bundle/contracts/cli-behavior-contract.md` to lock Contracts 1-4 to implemented behavior and command expectations (Trace: FR-001, FR-002, FR-004, FR-005, SC-001, SC-002, SC-003, TG-001)
- [ ] T015 [US1] [assigned_to: Reviewer] [effort: S] Execute `pwsh -NoProfile -File tests/integration/validate-versions-cli-behavior.ps1` and `pwsh -NoProfile -File tests/integration/start-recovery-flow.tests.ps1`, then record evidence in `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` (Trace: SC-001, SC-002, SC-003, SC-006, TG-001)

**Checkpoint**: US1 behavior is independently functional and regression-backed.

---

## Phase 4: User Story 2 - Accurate Conflict and Brownfield Detection (Priority: P1)

**Goal**: Enforce canonical `.squad/agents/` ownership classification in self-hosting repos while preserving default conflict rules elsewhere.  
**Independent Test**: Run brownfield checks in fixtures with and without `extensions/specrew-speckit/` and verify `.squad/agents/` classification outcomes.

### Tests for User Story 2

- [ ] T016 [P] [US2] [assigned_to: Implementer] [effort: M] Extend brownfield ownership regression fixtures in `tests/integration/brownfield-conflict-handling.ps1` for self-hosting and non-self-hosting `.squad/agents/` classification (Trace: FR-006, SC-004, SC-006, TG-002)

### Implementation for User Story 2

- [ ] T017 [US2] [assigned_to: Implementer] [effort: M] Update canonical-source classification logic in `extensions/specrew-speckit/scripts/brownfield-merge.ps1` to treat `.squad/agents/` as canonical when `extensions/specrew-speckit/` signal exists (Trace: FR-006, SC-004, TG-002)
- [ ] T018 [US2] [assigned_to: Implementer] [effort: S] Mirror the same brownfield classification change in `.specify/extensions/specrew-speckit/scripts/brownfield-merge.ps1` to preserve governance parity (Trace: FR-006, FR-008, SC-004, TG-002, TG-004)
- [ ] T019 [US2] [assigned_to: Reviewer] [effort: S] Record F6 closure disposition and evidence pointers in `specs/045-v0271-bugfix-bundle/iterations/001/finding-disposition.md` (Trace: FR-003, FR-006, TG-002, TG-007)
- [ ] T020 [US2] [assigned_to: Reviewer] [effort: S] Execute `pwsh -NoProfile -File tests/integration/brownfield-conflict-handling.ps1` and append pass evidence to `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` (Trace: SC-004, SC-006, TG-002)

**Checkpoint**: US2 conflict handling is independently correct in both ownership modes.

---

## Phase 5: User Story 3 - Clear Update and Redeployment Guidance (Priority: P2)

**Goal**: Deliver explicit operator guidance for update paths, risk semantics, and re-deployment triggers.  
**Independent Test**: Perform guided operator review from docs and verify update-path + redeploy decisions are actionable in under 3 minutes.

### Tests for User Story 3

- [ ] T021 [P] [US3] [assigned_to: Doc Steward] [effort: S] Create doc validation checklist and timing rubric in `specs/045-v0271-bugfix-bundle/iterations/001/quality/update-guidance-review.md` for SC-005 measurement (Trace: FR-007, SC-005, TG-003)

### Implementation for User Story 3

- [ ] T022 [US3] [assigned_to: Doc Steward] [effort: M] Update update-path guidance in `docs/getting-started.md` covering normal update, `-Force`, and publisher-check bypass safety boundaries (Trace: FR-007, SC-005, TG-003)
- [ ] T023 [US3] [assigned_to: Doc Steward] [effort: M] Update operator guidance in `docs/user-guide.md` with explicit init re-deployment triggers for missing skill-catalog/runtime gaps (Trace: FR-007, SC-005, TG-003)
- [ ] T024 [US3] [assigned_to: Doc Steward] [effort: S] Add stale-finding closure narrative and bounded-scope note for v0.27.1 bundle in `specs/045-v0271-bugfix-bundle/iterations/001/finding-disposition.md` without runtime behavior inflation (Trace: FR-003, FR-007, TG-003, TG-007)
- [ ] T025 [US3] [assigned_to: Doc Steward] [effort: S] Refresh verification walkthrough in `specs/045-v0271-bugfix-bundle/quickstart.md` with post-update redeploy decision checks (Trace: FR-007, SC-005, TG-003)
- [ ] T026 [US3] [assigned_to: Reviewer] [effort: S] Execute guided doc review and capture <3 minute decision evidence in `specs/045-v0271-bugfix-bundle/iterations/001/quality/update-guidance-review.md` (Trace: SC-005, TG-003)

**Checkpoint**: US3 guidance is independently actionable and operator-validated.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Consolidate release evidence, governance checks, and bounded closeout artifacts across all stories.

- [ ] T027 [P] [assigned_to: Reviewer] [effort: S] Run mechanical checks via `.specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1` and confirm outputs in `specs/045-v0271-bugfix-bundle/iterations/001/quality/mechanical-findings.json` and `.../quality/quality-evidence.md` (Trace: FR-008, SC-006, TG-004)
- [ ] T028 [assigned_to: Reviewer] [effort: S] Execute governance validation via `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` and record result in `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` (Trace: FR-008, TG-004)
- [ ] T029 [assigned_to: Reviewer] [effort: S] Verify all patch regression suites pass (`validate-versions-cli-behavior`, `start-recovery-flow`, `brownfield-conflict-handling`) and summarize zero failing P0/P1 status in `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` (Trace: SC-006, TG-001, TG-002, TG-003)
- [ ] T030 [assigned_to: Doc Steward] [effort: S] Update v0.27.1 patch notes in `CHANGELOG.md` with the 7-item bundle closure summary and stale-finding disposition references (Trace: FR-003, FR-008, TG-006, TG-007)

---

## Dependencies & Execution Order

### Phase Dependencies

1. **Phase 1 (Setup)** → no dependencies.  
2. **Phase 2 (Foundational)** → depends on Phase 1; blocks all user stories.  
3. **Phase 3 (US1, P1)** → depends on Phase 2.  
4. **Phase 4 (US2, P1)** → depends on Phase 2; can run in parallel with US1 after foundation is complete.  
5. **Phase 5 (US3, P2)** → depends on completion of US1 + US2 behavior outcomes for accurate operator guidance.  
6. **Phase 6 (Polish)** → depends on US1, US2, US3 completion.

### User Story Dependencies

- **US1**: No dependency on other stories; MVP anchor.  
- **US2**: No dependency on US1 implementation; shares foundational prerequisites only.  
- **US3**: Depends on finalized behavior from US1 and US2 to document accurate update/redeploy decisions.

### Task-Level Dependency Highlights

- T007-T008 must precede T009-T013 (tests before implementation in US1).  
- T016 must precede T017-T018 (test fixture coverage before US2 logic changes).  
- T021 must precede T022-T026 (measurement rubric before documentation work).  
- T027-T029 require completion of all story implementation/testing tasks.

---

## Parallel Execution Examples

### User Story 1 Parallel Block

- Run T007 and T008 in parallel (different test files).  
- After T009/T010 complete, T011 can proceed while T012/T013 are handled as split branches in `scripts/specrew-init.ps1` by sequence (not parallel on same file).

### User Story 2 Parallel Block

- T016 can run in parallel with late US1 verification task T015 once Phase 2 is done.  
- T017 and T018 are sequential mirrors (same logic, different trees) but can be assigned back-to-back without cross-story blocking.

### User Story 3 Parallel Block

- T021 can run in parallel with US2 evidence capture T020.  
- T022 and T023 can run in parallel (different docs), then converge into T025 and T026.

---

## Implementation Strategy

### MVP First (US1)

1. Complete Phase 1 and Phase 2.  
2. Deliver US1 end-to-end (T007-T015).  
3. Validate SC-001/SC-002/SC-003/SC-006 before expanding scope.

### Incremental Delivery

1. Add US2 (T016-T020) after US1 baseline is stable.  
2. Add US3 (T021-T026) with operator-facing validation.  
3. Close cross-cutting release evidence (T027-T030).

### Scope Discipline for v0.27.1

- Do not introduce new lifecycle commands, new runtime boundaries, or non-bug feature work.  
- Keep all edits traceable to FR-001..FR-008 and SC-001..SC-006 only.  
- Treat non-actionable stale findings as documented closure artifacts only.

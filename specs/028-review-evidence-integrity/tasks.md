# Tasks: Review Evidence Integrity (F-028)

**Input**: Design documents from `specs/028-review-evidence-integrity/`  
**Prerequisites**: ✅ plan.md, ✅ spec.md, ✅ research.md, ✅ data-model.md, ✅ contracts/, ✅ quickstart.md  
**Status**: Implementation complete; validation in progress pending review-boundary handoff  
**Tests**: Standalone PowerShell integration script required per SC-006

---

## Organization & Phasing

This feature implements **four pillars** (five design points):

1. **Pillar 1**: Pre-review commit gate validator rule (US-2)
2. **Pillar 2**: Form-vs-meaning parity helper (US-3)
3. **Pillar 3**: Scaffolder defensive warnings (US-1)
4. **Pillar 4**: Idempotent scaffolder re-runnability (US-4)

**Task Organization**: Organized by user story (P1 first, then P2) to enable independent implementation and testing.

---

## Phase 1: Setup (Minimal - Modifications Only)

**Purpose**: Prepare codebase for modifications (no new scaffold; all files already exist)

- [X] T001 Review existing `extensions/specrew-speckit/scripts/` structure and validate modification points in `validate-governance.ps1`, `scaffold-reviewer-artifacts.ps1`, `shared-governance.ps1`
- [X] T002 Verify git baseline ref resolution and `git diff --name-only` invocation in current governance scripts
- [X] T003 Confirm Pester test framework availability in `tests/` directory and review existing integration test patterns

---

## Phase 2: User Story 1 – Reviewer Detects Uncommitted Implementation (Priority: P1) 🎯

**Goal**: Emit loud, visible warnings when review evidence may be misleading (form-vs-meaning gap detected)

**Independent Test**: Running scaffolder on an iteration with declared completion but empty git diff produces a prominent warning at the top of all review artifacts. Reviewer can read the artifact and immediately understand the issue.

**Acceptance Criteria**:

- SC-003: Warning ⚠️ is emitted at top of every review artifact when gap detected
- FR-005, FR-006, FR-007: Scaffolder continues producing output (non-blocking) with warning message

### Implementation for User Story 1

- [X] T004 [US1] Implement form-vs-meaning gap detection in `scaffold-reviewer-artifacts.ps1` to read declared task count from `state.md` and compare to git diff file count
- [X] T005 [US1] Add warning emission logic at top of `review-diagrams.md` when gap detected (FR-005, FR-006) in `scaffold-reviewer-artifacts.ps1`
- [X] T006 [P] [US1] Extend warning to `code-map.md` artifact with identical message (FR-005)
- [X] T007 [P] [US1] Extend warning to `dependency-report.md` artifact (FR-005)
- [X] T008 [P] [US1] Extend warning to `coverage-evidence.md` artifact (FR-005)
- [X] T009 [US1] Ensure scaffolder continues producing diagrams/output even when gap detected (FR-007); gap does not block artifact generation

**Checkpoint**: US-1 warnings complete; reviewers see loud signals when uncommitted work detected

---

## Phase 3: User Story 2 – Validator Gate Blocks Incomplete Iterations (Priority: P1) 🎯

**Goal**: Hard-block iteration advancement from implement→review if declared tasks don't match committed files

**Independent Test**: Running `validate-governance.ps1` against an iteration with declared ≥1 completed task but empty git diff produces a validation failure with category `review-evidence-integrity` and severity `error` that blocks advancement. Running same validator on clean iterations (both declared and observed match) produces no false positives.

**Acceptance Criteria**:

- SC-001: Pre-review validator blocks advancement on form-vs-meaning gap
- SC-008: Existing iterations F-009–F-072 continue to validate cleanly (no regressions)
- FR-001 through FR-004: Validator reads state.md, computes git diff, emits error with remediation

### Implementation for User Story 2

- [X] T010 [US2] Implement `Test-PreReviewCommitGate` rule in `validate-governance.ps1` that reads the iteration `plan.md` Tasks table for completed task count, with `state.md` task tables as legacy fallback (FR-001)
- [X] T011 [US2] Add git diff computation using `git diff --name-only <baseline>...HEAD` in validator rule (FR-002)
- [X] T012 [US2] Invoke `Test-FormMeaningParity` helper in pre-review gate rule to determine severity (FR-003)
- [X] T013 [US2] Emit ValidationResult with category `review-evidence-integrity`, severity `error`, and detailed remediation hint in validator rule message (FR-003, FR-004)
- [X] T014 [US2] Integrate `Test-PreReviewCommitGate` rule into `validate-governance.ps1` invocation chain at review-boundary advance (FR-003)
- [X] T015 [US2] Ensure false-positive prevention: empty iterations where the `plan.md` Tasks table declares zero completed tasks (or the legacy `state.md` fallback resolves to zero) and the diff is empty do NOT trigger validation failure per Q4 resolution (FR-001, AC2, AC3)
- [X] T016 [US2] Validate baseline ref is read from iteration metadata (no override flags per Q2 decision) (FR-002)

**Checkpoint**: US-2 validator gate complete; review boundary now enforces form-vs-meaning parity

---

## Phase 4: User Story 3 – Test-FormMeaningParity Helper Enables Broader Checks (Priority: P2)

**Goal**: Provide reusable form-vs-meaning parity helper for other validators and Proposal 030 composition

**Independent Test**: Calling `Test-FormMeaningParity -Declared <count> -Observed <count>` returns a PSCustomObject with Declared, Observed, Gap (bool), Severity (error|warning|info) fields. Helper works independently with test-case inputs without side effects.

**Acceptance Criteria**:

- SC-002: `Test-FormMeaningParity` is production-ready and composable by other rules
- FR-008: Helper accepts Declared and Observed parameters; returns structured object
- Contracts: Function signature matches `test-formmeaningparity-contract.md` immutable API v1

### Implementation for User Story 3

- [X] T017 [US3] Create `Test-FormMeaningParity` helper function in `extensions/specrew-speckit/scripts/shared-governance.ps1` with signature per contract (FR-008)
- [X] T018 [US3] Implement severity logic: zero-diff (Declared>0, Observed=0) → error; partial (Declared>Observed, Observed>0) → warning; match or empty → info (data-model.md)
- [X] T019 [US3] Return PSCustomObject with fields: Declared [int], Observed [int], Gap [bool], Severity [string] (FR-008, contract)
- [X] T020 [US3] Add inline documentation to helper function explaining parameters, return values, and severity logic
- [X] T021 [US3] Ensure function is purely functional (no I/O, no side effects) per composition contract
- [ ] T022 [P] [US3] Document example usage in quickstart.md and reference in api-reference.md (SC-002)
- [X] T023 [US3] Validate helper against 4 Proposal 030 use cases from research.md (Q6 requirement): feature status verification, iteration scope calculation, output-mode environment check, test coverage verification

**Checkpoint**: US-3 helper complete; reusable API ready for Proposal 030 and other validators

---

## Phase 5: User Story 4 – Idempotent Review Artifact Regeneration (Priority: P2)

**Goal**: Enable safe re-running of scaffolder after late commits with interactive confirmation and non-interactive escape hatch

**Independent Test**: Running `scaffold-reviewer-artifacts.ps1 -Force` twice on the same iteration produces identical output without duplicates or errors. Subsequent runs with updated git history reflect new diff accurately. `-Confirm:$true` shows prompt; `-Confirm:$false` bypasses.

**Acceptance Criteria**:

- SC-004: Scaffolder `-Force` flag safely re-runs with confirmation prompt (default) and `-Confirm:$false` escape hatch
- SC-005: Documentation confirms human annotations belong in `review.md`, not generated artifacts
- FR-009 through FR-012: `-Force` switch, confirmation logic, idempotency, annotation convention

### Implementation for User Story 4

- [X] T024 [US4] Add `-Force` switch parameter to `scaffold-reviewer-artifacts.ps1` function signature (FR-009)
- [X] T025 [US4] Implement `[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]` and `$PSCmdlet.ShouldProcess()` in scaffolder for built-in `-Confirm` parameter handling (FR-010, Q3 decision)
- [X] T026 [US4] Add interactive confirmation prompt when `-Force` is used with `-Confirm:$true` (default): "⚠️ Re-running with `-Force` will overwrite existing review artifacts..." (FR-010)
- [X] T027 [US4] Ensure confirmation prompt is skipped when `-Confirm:$false` is used (non-interactive contexts like CI/CD) (FR-010, Q3)
- [X] T028 [US4] Implement idempotency: re-running scaffolder on same iteration produces identical output without duplicates (FR-011)
- [X] T029 [US4] Update `scaffold-reviewer-artifacts.ps1` to detect existing artifacts and overwrite cleanly when `-Force` used with confirmation
- [X] T030 [P] [US4] Document annotation preservation convention in `docs/user-guide.md`: annotations belong in `review.md`, not generated artifacts (FR-012, SC-005)
- [X] T031 [P] [US4] Document `-Force` flag usage and confirmation behavior in `docs/api-reference.md` with examples for interactive and non-interactive contexts

**Checkpoint**: US-4 idempotent re-run complete; review evidence can be safely regenerated after late commits

---

## Phase 6: Integration Tests & Quality Gates

**Purpose**: Comprehensive test coverage for all four pillars; validate against regression baselines

**Test Requirement**: Integration test suite mandatory per SC-006

- [X] T032 Create integration test suite `tests/integration/review-evidence-integrity.tests.ps1` as a standalone PowerShell regression script
- [X] T033 Implement test: Gap detected when declared ≥1 task, empty git diff (SC-001, SC-003)
- [X] T034 Implement test: No false positives when declared and observed match (SC-001, SC-008)
- [X] T035 Implement test: No false positives for empty iterations (declared=0, diff empty) per Q4 resolution (AC2, AC3, FR-001)
- [X] T036 Implement test: Validator blocks advancement on form-vs-meaning gap (SC-001)
- [ ] T037 Implement test: Scaffolder emits warning at top of all artifacts when gap detected (SC-003)
- [ ] T038 Implement test: Scaffolder continues producing output even when gap detected (FR-007)
- [X] T039 Implement test: `Test-FormMeaningParity` returns correct severity for all cases (no gap, zero-diff, partial, empty iteration, over-delivery) (SC-002)
- [ ] T040 Implement test: Scaffolder `-Force` flag with `-Confirm:$true` shows prompt (SC-004)
- [X] T041 Implement test: Scaffolder `-Force` flag with `-Confirm:$false` skips prompt (non-interactive) (SC-004, Q3)
- [X] T042 Implement test: Re-running scaffolder with `-Force` produces identical output (idempotency) (FR-011)
- [ ] T043 Implement regression test: Run `validate-governance.ps1` against existing iterations F-009–F-072; verify no validation failures (SC-008)
- [ ] T044 Implement smoke-trial replay: Replay 2026-05-21 snake-game scenario under new gate; verify blocks at review boundary with clear error (SC-007)
- [X] T045 Run full integration test suite and verify all tests pass before feature closure

**Checkpoint**: Integration tests pass; regression baseline clean; all quality gates met

---

## Phase 7: Documentation & Project Updates

**Purpose**: Surface new validator failure mode, document helper API, update project metadata

- [X] T046 [P] Update `docs/user-guide.md`: Add troubleshooting section for "form-vs-meaning gap detected" validator failure mode (plan.md, line 217)
- [X] T047 [P] Update `docs/api-reference.md`: Document `Test-FormMeaningParity` helper signature, parameters, return values, severity logic, and composition examples (SC-002, FR-008)
- [X] T048 [P] Document scaffolder `-Force` flag and confirmation behavior in `docs/api-reference.md` (SC-004, FR-009–FR-012)
- [X] T049 [P] Document annotation preservation convention (human notes in `review.md`, not generated artifacts) in user guide (SC-005, FR-012)
- [X] T050 Update `CHANGELOG.md`: Add entry under "## Unreleased → ### Added" listing new validator rule, helper function, scaffolder flag, and warning behavior (plan.md, line 225)
- [ ] T051 Update `INDEX.md`: Update feature 028 status to reflect completion after feature closes (plan.md, line 225)

**Checkpoint**: Documentation complete; user-facing changes clear; project metadata updated

---

## Phase 8: Validation & Closure

**Purpose**: Final verification against acceptance criteria and success metrics

- [ ] T052 Verify SC-001 (Pre-review gate blocks incomplete iterations, no false positives)
- [ ] T053 Verify SC-002 (Helper function is production-ready, composable)
- [ ] T054 Verify SC-003 (Loud warnings emitted when gap detected)
- [ ] T055 Verify SC-004 (Scaffolder `-Force` flag works with confirmation and non-interactive escape)
- [ ] T056 Verify SC-005 (Documentation confirms annotation preservation convention)
- [ ] T057 Verify SC-006 (Integration test suite passes all scenarios)
- [ ] T058 Verify SC-007 (Smoke trial replay blocks at review boundary)
- [ ] T059 Verify SC-008 (Existing iterations F-009–F-072 validate cleanly)
- [ ] T060 Verify SC-009 (Proposal 030 composition: `Test-FormMeaningParity` API immutable, absorbs into 030 without modification)
- [ ] T061 Final sign-off: All acceptance criteria met; feature ready for merge

---

## Dependencies & Parallelization

### Dependency Graph

```
Phase 1 (Setup) [T001–T003]
    ↓
Phase 2 (US-1: Warnings) [T004–T009]
    ↓
Phase 3 (US-2: Validator) [T010–T016]
    ├─ T010–T012 can run in parallel (different detection paths)
    └─ T013–T016 depend on T012 (gate integration)
    ↓
Phase 4 (US-3: Helper) [T017–T023]
    └─ Can run in parallel with Phase 3 after Phase 1 completes
    ↓
Phase 5 (US-4: Idempotent) [T024–T031]
    └─ Can run in parallel with US-3 after Phase 1 completes
    ↓
Phase 6 (Tests) [T032–T045]
    └─ Depends on all implementation phases; can run in parallel after impls complete
    ↓
Phase 7 (Documentation) [T046–T051]
    └─ Can run in parallel with Phase 6
    ↓
Phase 8 (Validation) [T052–T061]
    └─ Final sequential validation
```

### Parallel Execution Opportunities

**Parallel Group A** (after Phase 1 & Phase 2/3 validators ready):

- T017–T023 (US-3 helper implementation)
- T024–T031 (US-4 scaffolder flag implementation)
- These are independent; one group doesn't block the other

**Parallel Group B** (after all implementation complete):

- T032–T045 (Integration tests) [can run in parallel with T046–T051 (Documentation)]

### Suggested MVP Scope

**Phase 1 MVP** (Minimum for first review):

- Phase 1: Setup (T001–T003)
- Phase 2: US-1 Warnings (T004–T009) ✅ **Reviewer sees loud signals**
- Phase 3: US-2 Validator (T010–T016) ✅ **Gate blocks incomplete iterations**
- Phase 6: Integration Tests (T032–T045) ✅ **Quality assurance**

This MVP delivers the core form-vs-meaning detection and blocks incomplete iterations at the review boundary—satisfying the primary user-facing outcome (SC-001, SC-003).

**Phase 2 Follow-up** (after MVP merges):

- Phase 4: US-3 Helper (T017–T023) - feeds Proposal 030
- Phase 5: US-4 Idempotent (T024–T031) - enables re-run after late commits
- Phase 7: Documentation (T046–T051) - full user/API docs

---

## Traceability

| User Story | Priority | Functional Requirement | Task Range | Acceptance Criteria |
|---|---|---|---|---|
| US-1: Reviewer detects uncommitted work | P1 | FR-005, FR-006, FR-007 | T004–T009 | SC-003 |
| US-2: Validator gate blocks incomplete | P1 | FR-001, FR-002, FR-003, FR-004 | T010–T016 | SC-001, SC-008 |
| US-3: Helper enables broader checks | P2 | FR-008 | T017–T023 | SC-002 |
| US-4: Idempotent re-run | P2 | FR-009, FR-010, FR-011, FR-012 | T024–T031 | SC-004, SC-005 |

---

## Testing & Validation Commands

```powershell
# Run integration test suite
Invoke-Pester -Path 'tests/integration/review-evidence-integrity.tests.ps1' -Verbose

# Validate a test iteration (manual check)
& '.\extensions\specrew-speckit\scripts\validate-governance.ps1' `
  -IterationPath './specs/028-review-evidence-integrity'

# Regenerate review artifacts with gap detection
& '.\extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1' `
  -IterationPath './specs/028-review-evidence-integrity' `
  -Force `
  -Confirm:$false

# Validate regression baseline (existing iterations)
$iterations = @('F-009', 'F-010', 'F-011')  # Sample
foreach ($it in $iterations) {
  & '.\extensions\specrew-speckit\scripts\validate-governance.ps1' `
    -IterationPath "./specs/$it"
}
```

---

## Constitution Alignment

✅ **All gates from plan.md (Constitution Check) passed**:

- Spec Authority: Feature spec approved; all Q1–Q6 resolved
- Layering: Spec Kit layer extension (no Squad layer changes)
- Traceability: Each deliverable traces to user stories and requirements
- Ownership: Alon Fliess (Spec Steward), Squad (Iteration Facilitator)
- Capacity: 15–20 story points, one feature iteration
- Drift/Reconciliation: Validator rule detects and blocks gaps; scaffolder warns; integration tests validate
- Verification: AC1–AC9 from spec covered by integration tests

---

## Status

✅ **Phase 1 Design Complete** (all research, specs, contracts finalized)  
⏳ **Ready for Implementation** (61 tasks, organized by user story, P1 MVP identified)

**Next Step**: Execute Phase 1 MVP (Phases 1–3 + Tests), then Phase 2 Follow-up (Phases 4–5 + Documentation).

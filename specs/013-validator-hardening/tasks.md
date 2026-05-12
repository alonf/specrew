# Tasks: Validator Hardening

**Input**: Design documents from `C:\Dev\Specrew\specs\013-validator-hardening\`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/iteration-state-schema.md`, `contracts/hardening-gate-concerns.md`  
**Tests**: Deterministic PowerShell integration coverage is required because `spec.md` explicitly requires violating/compliant fixtures for every new rule (FR-008) plus zero raw exceptions across representative failure modes (SC-005).  
**Scope Boundary**: Keep the backlog aligned to the approved two-iteration split from `plan.md`; preserve the existing `validate-governance.ps1` / `shared-governance.ps1` / `specrew-start.ps1` command surfaces; keep the feature additive and mechanical-only per TG-007; do not add iteration-artifact scaffolding tasks in this backlog.

## Format: `[ID] [P?] [Story?] [Owner] [Effort] Description`

- **[P]**: Can run in parallel once dependencies are satisfied
- **[Story?]**: Present only for user-story tasks as `[US1]`, `[US2]`, `[US3]`, `[US4]`, or `[US5]`
- **[Owner]**: Primary owner role aligned to `spec.md` governance ownership
- **[Effort]**: Relative implementation effort estimate (`S`, `M`, `L`)
- Every task includes exact file path(s) and explicit `(Trace: ...)` references

---

## Phase 1: Setup

**Purpose**: Lock the approved boundary, capture the pre-implementation baseline, and confirm the implementation surface before shared validator changes begin.

- [ ] T001 [P] [Owner: Reviewer] [Effort: M] Run the pre-implementation baseline from repo root using `tests/integration/quality-profile-foundation.ps1`, `tests/integration/hardening-gate-contract.ps1`, `tests/integration/quality-evidence-governance.ps1`, `tests/integration/validation-contract-lane.ps1`, `tests/integration/project-path-resolution-regression.ps1`, and `extensions/specrew-speckit/scripts/validate-governance.ps1`, then record the baseline result in `specs/013-validator-hardening/quickstart.md`. (Trace: FR-010, TG-007, SC-005, quickstart.md Full governance lane)
- [ ] T002 [P] [Owner: Planner] [Effort: S] Review `specs/013-validator-hardening/spec.md`, `specs/013-validator-hardening/plan.md`, `specs/013-validator-hardening/research.md`, `specs/013-validator-hardening/data-model.md`, `specs/013-validator-hardening/quickstart.md`, `specs/013-validator-hardening/contracts/iteration-state-schema.md`, and `specs/013-validator-hardening/contracts/hardening-gate-concerns.md`, then reconcile any drift back into `specs/013-validator-hardening/plan.md` and initialize `specs/013-validator-hardening/quality/trap-reapplication.md` for the Iteration 1 implementation start if it is missing. (Trace: FR-007, FR-010, TG-001, TG-002, TG-003, TG-004, TG-005, SC-007, plan.md Capacity Gate, plan.md Trap Reapplication Artifact)

---

## Phase 2: Foundational (Blocking Prerequisites for Iteration 1)

**Purpose**: Land the shared structured-failure foundation, contract alignment, and test harness that every user story depends on.

**⚠️ CRITICAL**: No user-story work should begin until this phase preserves additive validator behavior and the shared contracts remain authoritative.

- [ ] T003 [Owner: Validator maintainer] [Effort: L] Implement structured FAIL builders, error accumulation, and exception-wrapping helpers across `extensions/specrew-speckit/scripts/shared-governance.ps1` and `extensions/specrew-speckit/scripts/validate-governance.ps1` so all validator paths touched by this feature return file path, line number, category, message, and remediation hint without raw PowerShell exceptions before Iteration 2 begins. (Trace: FR-005, TG-008, SC-005)
- [ ] T004 [P] [Owner: Test maintainer] [Effort: M] Create the shared integration harness in `tests/integration/validator-hardening-iteration1.ps1` and `tests/integration/validator-hardening-iteration2.ps1`, including reusable assertions for structured FAIL output and additive command-surface compatibility. (Trace: FR-008, FR-010, TG-007, TG-008, SC-005, SC-006)
- [ ] T005 [P] [Owner: Governance-contract steward] [Effort: S] Reconcile `specs/013-validator-hardening/contracts/iteration-state-schema.md` and `specs/013-validator-hardening/contracts/hardening-gate-concerns.md` with `specs/013-validator-hardening/data-model.md` and the planned validator behavior before rule-specific implementation begins. (Trace: FR-009, TG-001, TG-002, SC-001, SC-002)

**Checkpoint**: Structured FAIL plumbing, harness scaffolding, and normative contracts are ready for Iteration 1 implementation.

---

## Phase 3: Iteration 1 - User Story 1 - Enforce canonical iteration metadata (Priority: P1) 🎯 MVP

**Goal**: Ensure non-canonical or incomplete iteration `state.md` metadata fails clearly and compliant files pass without validator crashes.

**Independent Test**: Create compliant and non-compliant `state.md` fixtures, run `tests/integration/validator-hardening-iteration1.ps1`, and confirm schema violations are reported with structured FAIL output while compliant and grandfathered cases pass cleanly.

### Tests for User Story 1

- [ ] T006 [P] [US1] [Owner: Test maintainer] [Effort: M] Create compliant and violating iteration-state fixtures in `tests/integration/fixtures/013-validator-hardening/state-canonical/` and `tests/integration/fixtures/013-validator-hardening/state-noncanonical/`, including missing-field, non-canonical-label, grandfathered, and extra-narrative cases. (Trace: FR-001, FR-008, TG-001, SC-001)
- [ ] T007 [P] [US1] [Owner: Test maintainer] [Effort: M] Add canonical-schema assertions to `tests/integration/validator-hardening-iteration1.ps1` covering missing canonical fields, non-canonical field names, compliant files, and grandfathered iterations with zero unhandled exceptions. (Trace: FR-001, FR-008, TG-001, TG-008, SC-001, SC-005)

### Implementation for User Story 1

- [ ] T008 [US1] [Owner: Validator maintainer] [Effort: L] Implement canonical iteration metadata detection, missing-field reporting, and grandfathered-iteration filtering in `extensions/specrew-speckit/scripts/shared-governance.ps1` and `extensions/specrew-speckit/scripts/validate-governance.ps1` using `specs/013-validator-hardening/contracts/iteration-state-schema.md` as the normative reference. (Trace: FR-001, FR-009, TG-001, SC-001)
- [ ] T009 [US1] [Owner: Reviewer] [Effort: S] Run `tests/integration/validator-hardening-iteration1.ps1` and `extensions/specrew-speckit/scripts/validate-governance.ps1` against the `tests/integration/fixtures/013-validator-hardening/state-canonical/` and `tests/integration/fixtures/013-validator-hardening/state-noncanonical/` cases, then record the evidence in `specs/013-validator-hardening/quickstart.md`. (Trace: FR-001, FR-010, TG-001, SC-001, SC-005)

**Checkpoint**: User Story 1 is complete when canonical iteration metadata is enforced mechanically without raw validator exceptions.

---

## Phase 4: Iteration 1 - User Story 2 - Enforce canonical hardening-gate concerns (Priority: P1)

**Goal**: Ensure the first five hardening-gate concerns stay canonical, ordered, and explicitly validated.

**Independent Test**: Create compliant and non-compliant `hardening-gate.md` fixtures, run `tests/integration/validator-hardening-iteration1.ps1`, and confirm missing or reordered canonical concerns fail with exact concern/position reporting.

### Tests for User Story 2

- [ ] T010 [P] [US2] [Owner: Test maintainer] [Effort: M] Create compliant and violating hardening-gate fixtures in `tests/integration/fixtures/013-validator-hardening/hardening-gate-canonical/` and `tests/integration/fixtures/013-validator-hardening/hardening-gate-noncanonical/`, including missing, reordered, partial, and additional-concern scenarios. (Trace: FR-002, FR-008, TG-002, SC-002)
- [ ] T011 [P] [US2] [Owner: Test maintainer] [Effort: M] Add canonical-concern assertions to `tests/integration/validator-hardening-iteration1.ps1` covering missing concerns, incorrect ordering, partial tables, and valid tables with additional feature-specific rows. (Trace: FR-002, FR-008, TG-002, TG-008, SC-002, SC-005)

### Implementation for User Story 2

- [ ] T012 [US2] [Owner: Validator maintainer] [Effort: M] Implement `Concern Review` table parsing and first-five canonical concern enforcement in `extensions/specrew-speckit/scripts/shared-governance.ps1` and `extensions/specrew-speckit/scripts/validate-governance.ps1` using `specs/013-validator-hardening/contracts/hardening-gate-concerns.md` as the normative reference. (Trace: FR-002, FR-009, TG-002, SC-002)
- [ ] T013 [US2] [Owner: Reviewer] [Effort: S] Run `tests/integration/validator-hardening-iteration1.ps1` and `extensions/specrew-speckit/scripts/validate-governance.ps1` against the `tests/integration/fixtures/013-validator-hardening/hardening-gate-canonical/` and `tests/integration/fixtures/013-validator-hardening/hardening-gate-noncanonical/` cases, then update `specs/013-validator-hardening/quickstart.md` with Iteration 1 concern-order evidence. (Trace: FR-002, FR-010, TG-002, SC-002, SC-005)

**Checkpoint**: Iteration 1 is complete when canonical schema enforcement, canonical concern enforcement, structured FAIL output, and additive compatibility all hold together.

---

## Phase 5: Iteration 2 - User Story 3 - Detect reused approval evidence across iterations (Priority: P1)

**Goal**: Reject duplicated approval evidence across sibling iterations unless an explicit blanket authorization scope exists.

**Independent Test**: Seed sibling-iteration approval fixtures, run `tests/integration/validator-hardening-iteration2.ps1`, and confirm duplicate normalized quotes fail while explicit blanket-authorization cases pass.

### Tests for User Story 3

- [ ] T014 [P] [US3] [Owner: Test maintainer] [Effort: M] Create sibling-iteration approval fixtures in `tests/integration/fixtures/013-validator-hardening/approval-reuse/` covering duplicate normalized quotes in `plan.md` / `state.md`, distinct quotes, and explicit blanket multi-iteration authorization cases. (Trace: FR-003, FR-008, TG-003, SC-003)
- [ ] T015 [P] [US3] [Owner: Test maintainer] [Effort: M] Add approval-reuse assertions to `tests/integration/validator-hardening-iteration2.ps1` for duplicated evidence detection, quote normalization, and blanket-scope exemptions. (Trace: FR-003, FR-008, TG-003, TG-008, SC-003, SC-005)

### Implementation for User Story 3

- [ ] T016 [US3] [Owner: Validator maintainer] [Effort: L] Implement sibling-iteration approval collection, whitespace/emphasis normalization, duplicate-quote detection, and structured FAIL reporting in `extensions/specrew-speckit/scripts/shared-governance.ps1` and `extensions/specrew-speckit/scripts/validate-governance.ps1`. (Trace: FR-003, FR-005, TG-003, SC-003, SC-005)
- [ ] T017 [US3] [Owner: Governance-corpus steward] [Effort: S] Mark the approval-evidence reuse row as validator-enforced in `.specrew/quality/known-traps.md` with citations to requirement `FR-003`, proving test `tests/integration/validator-hardening-iteration2.ps1`, and implementation files `extensions/specrew-speckit/scripts/shared-governance.ps1` and `extensions/specrew-speckit/scripts/validate-governance.ps1`. (Trace: FR-007, TG-003, TG-006, SC-007)

**Checkpoint**: User Story 3 is complete when duplicated approval evidence is mechanically rejected and the corresponding known-traps row is graduated.

---

## Phase 6: Iteration 2 - User Story 4 - Block unsupported closeout claims (Priority: P1)

**Goal**: Reject closed-status iterations that lack required review, retro, hardening evidence, or a clean iteration-directory working tree.

**Independent Test**: Seed over-claim fixtures, run `tests/integration/validator-hardening-iteration2.ps1`, and confirm each missing or inconsistent closeout evidence element produces an explicit structured FAIL.

### Tests for User Story 4

- [ ] T018 [P] [US4] [Owner: Test maintainer] [Effort: M] Create closeout-evidence fixtures in `tests/integration/fixtures/013-validator-hardening/overclaim/` covering missing `retro.md`, missing or non-accepted `review.md`, pending post-implementation hardening evidence, clean pass cases, and iteration-directory dirty-tree scenarios. (Trace: FR-004, FR-008, TG-004, SC-004)
- [ ] T019 [P] [US4] [Owner: Test maintainer] [Effort: M] Add over-claim assertions to `tests/integration/validator-hardening-iteration2.ps1` covering closed-status detection, required evidence-set checks, and iteration-directory-only `git status --porcelain` filtering. (Trace: FR-004, FR-008, TG-004, TG-008, SC-004, SC-005)

### Implementation for User Story 4

- [ ] T020 [US4] [Owner: Validator maintainer] [Effort: L] Implement closeout-evidence validation and scoped dirty-tree filtering in `extensions/specrew-speckit/scripts/shared-governance.ps1` and `extensions/specrew-speckit/scripts/validate-governance.ps1`, ensuring `.squad/decisions.md` and `.squad/identity/now.md` remain evidence-only inputs rather than dirty-tree blockers. (Trace: FR-004, FR-005, TG-004, SC-004, SC-005)
- [ ] T021 [US4] [Owner: Governance-corpus steward] [Effort: S] Mark the over-claim row as validator-enforced in `.specrew/quality/known-traps.md` with citations to requirement `FR-004`, proving test `tests/integration/validator-hardening-iteration2.ps1`, and implementation files `extensions/specrew-speckit/scripts/shared-governance.ps1` and `extensions/specrew-speckit/scripts/validate-governance.ps1`. (Trace: FR-007, TG-004, TG-006, SC-007)

**Checkpoint**: User Story 4 is complete when unsupported closeout claims fail mechanically and the over-claim corpus trap is graduated.

---

## Phase 7: Iteration 2 - User Story 5 - Improve validator failure reporting and restart guidance (Priority: P2)

**Goal**: Distinguish bookkeeping-only `.github/copilot-instructions.md` changes from behavior-affecting changes for restart guidance while verifying the Iteration 1 structured FAIL surface remains additive.

**Independent Test**: Run `tests/integration/validator-hardening-iteration2.ps1 -ClassifierOnly`, run the full `tests/integration/validator-hardening-iteration2.ps1`, and confirm classifier outcomes plus additive compatibility match the approved spec without changing the validator command surface.

### Tests for User Story 5

- [ ] T022 [P] [US5] [Owner: Test maintainer] [Effort: M] Create `.github/copilot-instructions.md` diff fixtures in `tests/integration/fixtures/013-validator-hardening/copilot-instructions/` covering bookkeeping-only, behavior-affecting, and mixed diffs. (Trace: FR-006, FR-008, TG-005, SC-006)
- [ ] T023 [P] [US5] [Owner: Test maintainer] [Effort: M] Extend `tests/integration/validator-hardening-iteration2.ps1` with `-ClassifierOnly` coverage and additive compatibility assertions proving classifier execution does not change the existing validator command surface or exit-code expectations. (Trace: FR-006, FR-010, TG-005, SC-006)

### Implementation for User Story 5

- [ ] T024 [US5] [Owner: Restart-policy steward] [Effort: M] Implement `extensions/specrew-speckit/scripts/Test-CopilotInstructionsChangeType.ps1` and integrate it into `scripts/specrew-start.ps1`, ensuring bookkeeping-only changes avoid restart guidance while behavior changes still trigger restart handling. (Trace: FR-006, TG-005, SC-006)
- [ ] T025 [US5] [Owner: Validator maintainer] [Effort: S] Wire any validator-side reuse of `extensions/specrew-speckit/scripts/Test-CopilotInstructionsChangeType.ps1` into `extensions/specrew-speckit/scripts/validate-governance.ps1` only as additive compatibility validation, keeping restart-policy ownership in `scripts/specrew-start.ps1`. (Trace: FR-006, FR-010, TG-005, TG-007, SC-006)
- [ ] T026 [US5] [Owner: Reviewer] [Effort: S] Run `tests/integration/validator-hardening-iteration2.ps1 -ClassifierOnly`, `tests/integration/validator-hardening-iteration2.ps1`, `scripts/specrew-start.ps1`, and `extensions/specrew-speckit/scripts/validate-governance.ps1`, then record the classifier and additive-compatibility evidence in `specs/013-validator-hardening/quickstart.md`. (Trace: FR-006, FR-010, TG-005, SC-006)

**Checkpoint**: User Story 5 is complete when restart guidance is correctly classified and the classifier remains additive to current validator workflows.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Close the remaining corpus/documentation work and rerun the full governance lane before feature closure.

- [ ] T027 [P] [Owner: Governance-corpus steward] [Effort: S] Mark the canonical iteration schema and canonical hardening-gate concern rows as validator-enforced in `.specrew/quality/known-traps.md` with citations to requirements `FR-001` and `FR-002`, proving test `tests/integration/validator-hardening-iteration1.ps1`, and implementation files `extensions/specrew-speckit/scripts/shared-governance.ps1` and `extensions/specrew-speckit/scripts/validate-governance.ps1`. (Trace: FR-007, TG-006, SC-007)
- [ ] T028 [P] [Owner: Documentation maintainer] [Effort: M] Update `specs/013-validator-hardening/plan.md`, `specs/013-validator-hardening/quickstart.md`, and `specs/013-validator-hardening/quality/trap-reapplication.md` with final Iteration 1 and Iteration 2 validation commands, evidence references, and closeout notes after implementation completes. (Trace: FR-007, FR-010, TG-006, SC-007)
- [ ] T029 [Owner: Reviewer] [Effort: M] Run the full closeout lane using `tests/integration/quality-profile-foundation.ps1`, `tests/integration/hardening-gate-contract.ps1`, `tests/integration/quality-evidence-governance.ps1`, `tests/integration/validation-contract-lane.ps1`, `tests/integration/project-path-resolution-regression.ps1`, `tests/integration/validator-hardening-iteration1.ps1`, `tests/integration/validator-hardening-iteration2.ps1`, and `extensions/specrew-speckit/scripts/validate-governance.ps1`, then audit the final diff across the touched validator, classifier, fixture, contract, and corpus paths before closure. (Trace: FR-010, TG-007, SC-001, SC-002, SC-003, SC-004, SC-005, SC-006, SC-007)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup** → no dependencies
- **Phase 2: Foundational** → depends on Phase 1 and blocks all user-story work
- **Phase 3: Iteration 1 - US1** → depends on Phase 2
- **Phase 4: Iteration 1 - US2** → depends on Phase 2 and should complete before Iteration 1 is considered done
- **Phase 5: Iteration 2 - US3** → depends on completed Iteration 1 (Phases 3-4)
- **Phase 6: Iteration 2 - US4** → depends on completed Iteration 1 (Phases 3-4)
- **Phase 7: Iteration 2 - US5** → depends on completed Iteration 1 and uses the shared structured-FAIL foundation from Phase 2
- **Phase 8: Polish & Cross-Cutting** → depends on completion of Phases 5-7

### User Story Dependencies

- **US1 (P1)**: No user-story dependency after the foundational phase; this is the narrowest MVP slice
- **US2 (P1)**: Depends on the shared structured FAIL foundation and contract alignment from Phase 2, but not on later iteration work
- **US3 (P1)**: Depends on Iteration 1 being stable because approval-reuse enforcement inherits the shared FAIL surface and Iteration 2 harness
- **US4 (P1)**: Depends on Iteration 1 being stable and shares the Iteration 2 harness with US3
- **US5 (P2)**: Depends on completed Iteration 1 because FR-005 structured FAIL work lands there; Iteration 2 only adds classifier behavior and additive compatibility validation

### Iteration Dependencies

- **Iteration 1** = T001-T013. This iteration covers FR-001, FR-002, FR-005, FR-008 slice 1, FR-009, and FR-010 slice 1.
- **Iteration 2** = T014-T029. This iteration covers FR-003, FR-004, FR-006, FR-007, FR-008 slice 2, and FR-010 slice 2 while reusing the structured FAIL foundation from Iteration 1.

### Within Each User Story

- Write fixture tasks before assertion tasks
- Land test assertions before implementation changes and confirm they fail for violating fixtures
- Keep `extensions/specrew-speckit/scripts/shared-governance.ps1` helpers ahead of `validate-governance.ps1` call-site wiring where both are touched
- Update `specs/013-validator-hardening/quickstart.md` only after the relevant story-level validation lane passes

### Parallel Opportunities

- `T001` and `T002` can overlap at the start
- `T004` and `T005` can run in parallel after the baseline is captured
- `T006` and `T007` can run in parallel for US1
- `T010` and `T011` can run in parallel for US2
- `T014` and `T015` can run in parallel for US3
- `T018` and `T019` can run in parallel for US4
- `T022` and `T023` can run in parallel for US5
- `T027` and `T028` can run in parallel after implementation is complete

---

## Parallel Example: User Story 1

```text
Task: "T006 [US1] Create state fixtures in tests/integration/fixtures/013-validator-hardening/state-canonical/ and state-noncanonical/"
Task: "T007 [US1] Add canonical-schema assertions to tests/integration/validator-hardening-iteration1.ps1"
```

## Parallel Example: User Story 2

```text
Task: "T010 [US2] Create hardening-gate fixtures in tests/integration/fixtures/013-validator-hardening/hardening-gate-canonical/ and hardening-gate-noncanonical/"
Task: "T011 [US2] Add canonical-concern assertions to tests/integration/validator-hardening-iteration1.ps1"
```

## Parallel Example: User Story 3

```text
Task: "T014 [US3] Create approval-reuse fixtures in tests/integration/fixtures/013-validator-hardening/approval-reuse/"
Task: "T015 [US3] Add approval-reuse assertions to tests/integration/validator-hardening-iteration2.ps1"
```

## Parallel Example: User Story 4

```text
Task: "T018 [US4] Create overclaim fixtures in tests/integration/fixtures/013-validator-hardening/overclaim/"
Task: "T019 [US4] Add over-claim assertions to tests/integration/validator-hardening-iteration2.ps1"
```

## Parallel Example: User Story 5

```text
Task: "T022 [US5] Create copilot-instructions diff fixtures in tests/integration/fixtures/013-validator-hardening/copilot-instructions/"
Task: "T023 [US5] Extend tests/integration/validator-hardening-iteration2.ps1 with classifier compatibility assertions"
```

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2
2. Deliver User Story 1 (`T006`-`T009`) as the smallest independent value slice
3. Complete User Story 2 (`T010`-`T013`) to finish the approved Iteration 1 scope
4. Stop and validate Iteration 1 before starting Iteration 2 work

### Incremental Delivery

1. Ship Iteration 1: canonical schema enforcement, canonical concern enforcement, structured FAIL foundation, and contract alignment
2. Ship Iteration 2: approval-reuse detection, over-claim detection, restart-guidance classifier, corpus graduation, and final closeout validation
3. Finish with corpus/documentation polish and the full governance lane rerun

### Story-Independent Test Criteria

- `tests/integration/validator-hardening-iteration1.ps1` must prove canonical schema and canonical concern enforcement with violating and compliant fixtures
- `tests/integration/validator-hardening-iteration2.ps1` must prove approval-reuse detection, over-claim detection, and classifier behavior while preserving additive compatibility
- `extensions/specrew-speckit/scripts/validate-governance.ps1` must preserve the existing command surface and additive PASS/FAIL behavior across both iterations
- `scripts/specrew-start.ps1` must consume the classifier without forcing restarts for bookkeeping-only `.github/copilot-instructions.md` changes

### Suggested MVP Scope

- **Minimum MVP**: Phase 1 + Phase 2 + Phase 3 (`T001`-`T009`)
- **Approved Iteration 1 scope**: Phase 1 through Phase 4 (`T001`-`T013`)

---

## Notes

- All tasks follow the required checklist format: checkbox, task ID, optional `[P]`, optional story label, explicit `[Owner: ...]`, explicit `[Effort: ...]`, exact file path(s), and explicit `(Trace: ...)`
- The backlog preserves the approved two-iteration split from `specs/013-validator-hardening/plan.md`
- FR/TG/SC traceability is explicit on every task line
- This backlog intentionally avoids separate `specs/013-validator-hardening/iterations/**` scaffolding tasks in this generation pass

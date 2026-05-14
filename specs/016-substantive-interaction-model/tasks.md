# Tasks: Substantive Interaction Model — Iteration 002

**Input**: Design documents from `C:\Dev\Specrew\specs\016-substantive-interaction-model\`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/boundary-authorization-and-handoff.md`, `contracts/interaction-model-validator-contract.md`, `iterations/002/plan.md`  
**Iteration Scope**: Revised Iteration 002 only — original FR-020 through FR-024 scope plus the approved carryovers for FR-008 Commit Reference sync, canonical UTC seconds-precision handling, post-commit verification protocol formalization, stale-reference scan discipline, and the approved passive-guidance corpus rows  
**Capacity Guardrail**: Keep the executable backlog at **17.0 / 20.0 story_points** and keep all explicit deferrals visible in this artifact  
**Tests**: Required. `spec.md` explicitly requires violating/compliant/exempt proof fixtures, bounded-false-positive proof before FR-016 graduation, and replay-path validation on real validator entrypoints

## Format: `- [ ] T### [P?] [US#?] [Owner: ...] [Effort: ...] Description with exact path(s) (Trace: ...)`

- **[P]**: Task can run in parallel after its stated dependencies are satisfied
- **[US#]**: Present only for user-story phases (`[US1]`, `[US2]`, `[US3]`)
- **[Owner]**: Specrew role aligned to the owning FRs
- **[Effort]**: Planned story-point cost used in the 17.0 / 20.0 capacity ledger
- Every task names the concrete implementation surface(s) and trace metadata needed for safe execution

---

## Phase 1: Setup

**Purpose**: Prepare the shared replay/evidence lane for the revised Iteration 002 slice before story execution begins.

- [X] T001 [Owner: Quality steward] [Effort: 1.0 SP] Extend `specs/016-substantive-interaction-model/quickstart.md`, `tests/integration/substantive-interaction-model-iteration2.ps1`, and `tests/unit/validate-governance.interaction-model.tests.ps1` with the Iteration 002 command matrix and named scenario groups for authorization fidelity, docs/template truth, navigation graduation, and post-commit verification evidence. (Trace: FR-021, plan.md Required Quality Gates, quickstart.md Iteration 2 Steps, iterations/002/plan.md I2-01)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the one shared post-commit protocol that all Iteration 002 stories reuse.

**⚠️ CRITICAL**: No user-story work should start until the shared helper protocol below is in place.

- [X] T002 [Owner: Validator steward] [Effort: 1.0 SP] Add shared post-commit verification helpers in `extensions/specrew-speckit/scripts/shared-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` for UTC-seconds `Recorded At` normalization, `pending` -> boundary-hash Commit Reference synchronization, and stale-reference scan invocation so all later proof/doc/template tasks rely on one bounded implementation path. (Trace: FR-008 carryover, data-model.md Post-Commit Verification Record, research.md §11-12, iterations/002/plan.md I2-07-I2-09)

**Checkpoint**: Shared helper protocol is stable; user-story work can now proceed without redefining commit-sync or verification semantics per story.

---

## Phase 3: User Story 1 - Keep authorization records truthful through the post-commit cycle (Priority: P1) 🎯 MVP

**Goal**: Close the carryover gap where authorization entries and timestamps drift away from the exact committed boundary state.

**Independent Test**: Replay a boundary sequence where authorization entries start as `pending`, synchronize them to the real commit hash on the committed tree, and confirm the validator/tests accept short/full hash matches while preserving canonical UTC seconds precision.

### Tests for User Story 1

- [X] T003 [P] [US1] [Owner: Quality steward] [Effort: 1.5 SP] Create authorization-fidelity fixtures under `tests/integration/fixtures/016-substantive-interaction-model/authorization-fidelity/` and `tests/unit/fixtures/016-substantive-interaction-model/authorization-fidelity/`, then extend `tests/integration/substantive-interaction-model-iteration2.ps1` and `tests/unit/validate-governance.interaction-model.tests.ps1` to cover `pending` Commit References, synchronized short/full hash matches, and canonical UTC-seconds timestamps. (Trace: FR-021, FR-008 carryover, SC-002, SC-010, iterations/002/plan.md I2-01/I2-07/I2-08)

### Implementation for User Story 1

- [X] T004 [US1] [Owner: Governance steward] [Effort: 2.0 SP] Implement post-commit Commit Reference synchronization and canonical UTC seconds-precision authoring in `.squad/decisions.md`, `extensions/specrew-speckit/scripts/shared-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1`, and `specs/016-substantive-interaction-model/contracts/boundary-authorization-and-handoff.md` so generated authorization entries use `pending` only as an in-flight placeholder and settle to the real boundary hash during the same verification cycle. (Trace: FR-008, plan.md Summary, research.md §10-12, data-model.md Boundary Authorization Record)
- [X] T005 [US1] [Owner: Quality steward] [Effort: 1.0 SP] Formalize exact-tree post-commit verification evidence in `specs/016-substantive-interaction-model/quickstart.md`, `README.md`, and `extensions/specrew-speckit/governance/validation-lane.md` so the committed-tree rerun, unresolved-defer disclosure, and synchronized authorization-entry expectations are explicit before later story work builds on them. (Trace: FR-022 carryover, research.md §12, data-model.md Post-Commit Verification Record, iterations/002/plan.md I2-05/I2-07)

**Checkpoint**: User Story 1 is complete when authorization entries, timestamps, and proof commands stay synchronized with the real boundary commit instead of relying on stale `pending` state.

---

## Phase 4: User Story 2 - Keep public guidance and handoff templates substantively truthful (Priority: P1)

**Goal**: Make the human-facing guidance describe the actual Iteration 002 interaction model, including the post-commit verification and stale-reference discipline needed to trust handoffs.

**Independent Test**: Review only the updated README/template/checklist surfaces and confirm they accurately explain the seven-boundary workflow, the three-pillar model, the exact-tree post-commit protocol, and the stale-reference scan requirement without opening implementation code first.

### Tests for User Story 2

- [X] T006 [US2] [Owner: Quality steward] [Effort: 0.5 SP] Add documentation-truth scenarios to `specs/016-substantive-interaction-model/quickstart.md` and `tests/integration/substantive-interaction-model-iteration2.ps1` that verify the shipped README/template/checklist wording matches the revised Iteration 002 authority, including exact-tree reruns and explicit defer disclosure. (Trace: FR-021, FR-022, FR-023, SC-004, SC-009, iterations/002/plan.md I2-05/I2-06/I2-09)

### Implementation for User Story 2

- [X] T007 [P] [US2] [Owner: Documentation steward] [Effort: 2.0 SP] Update `README.md` and `extensions/specrew-speckit/governance/validation-lane.md` to describe the three-pillar interaction model, the 7-authorization pattern, validator scope, canonical UTC-seconds `Recorded At` policy, post-commit exact-tree reruns, and the mandatory stale-reference scan after boundary commits. (Trace: FR-022, plan.md Summary, quickstart.md Iteration 2 Deliverables, iterations/002/plan.md I2-05/I2-09)
- [X] T008 [US2] [Owner: Documentation steward] [Effort: 1.5 SP] Update `specs/001-specrew-product/contracts/coordinator-handoff-template.md`, `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`, and `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` with seven worked boundary examples plus the required post-commit verification and stale-reference-scan steps so handoffs stay substantively actionable after the final boundary commit. (Trace: FR-023, FR-022 carryover, research.md §12, iterations/002/plan.md I2-06/I2-09)

**Checkpoint**: User Story 2 is complete when a reviewer can understand the revised workflow from the shipped docs/templates alone and those surfaces tell the truth about post-commit verification.

---

## Phase 5: User Story 3 - Prove navigation graduation and durable corpus coverage (Priority: P1)

**Goal**: Ship the Iteration 002 proof, corpus memory, and config-only graduation path for click-through navigation without widening scope into deferred validator families.

**Independent Test**: Run violating/compliant/exempt replay fixtures and confirm `file:///` navigation stays clean in exempt contexts, `bare-path-in-boundary-handoff` graduates to hard FAIL by configuration only after proof passes, and the corpus rows document both active enforcement and approved passive guidance.

### Tests for User Story 3

- [X] T009 [P] [US3] [Owner: Quality steward] [Effort: 2.5 SP] Create violating, compliant, and exempt navigation fixtures under `tests/integration/fixtures/016-substantive-interaction-model/navigation/` and `tests/unit/fixtures/016-substantive-interaction-model/navigation/`, then extend `tests/integration/substantive-interaction-model-iteration2.ps1` and `tests/unit/validate-governance.interaction-model.tests.ps1` to prove bounded false positives, exact-tree stale-reference scans, and zero regression for valid `file:///` references. (Trace: FR-021, FR-016, SC-006, SC-007, SC-008, SC-010, iterations/002/plan.md I2-01/I2-02/I2-09)

### Implementation for User Story 3

- [X] T010 [US3] [Owner: Validator steward] [Effort: 1.0 SP] Promote `bare-path-in-boundary-handoff` from soft warning to hard FAIL by configuration/rule-table only in `extensions/specrew-speckit/scripts/validate-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` after the bounded-false-positive fixtures pass, without rewriting the detector logic. (Trace: FR-016, FR-021, research.md §5, iterations/002/plan.md I2-02)
- [X] T011 [P] [US3] [Owner: Quality steward] [Effort: 1.5 SP] Update `.specrew/quality/known-traps.md` with the required Feature 016 rows (`bundled-boundary-advance`, `thin-handoff-summary`, `bare-path-in-handoff`, `thin-artifact-content`), the historical cross-references to Feature 012/014, and the approved passive-guidance rows `fr-008-pending-commit-reference-vs-validator-hash-match`, `nfr-budget-calibrated-against-pre-refactor-baseline`, `boundary-regex-substring-match`, and `validator-catch-22-pre-commit-vs-post-commit`, while keeping deferred rows explicitly marked out of active scope. (Trace: FR-020, FR-024, plan.md Summary, iterations/002/plan.md I2-03/I2-04, iterations/001/retro.md Corpus Row Candidates)

**Checkpoint**: User Story 3 is complete when navigation proof is green, the severity flip is config-only, and the corpus truthfully captures both enforced and passive Iteration 002 learning.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Run the full validation lane for the revised slice and preserve the explicit boundary between in-scope work and deferred follow-up.

- [X] T012 [P] [Owner: Quality steward] [Effort: 1.0 SP] Run the full Iteration 002 validation lane using `tests/integration/substantive-interaction-model-iteration2.ps1`, `tests/unit/validate-governance.interaction-model.tests.ps1`, `tests/integration/handoff-governance-jargon-response-test.ps1`, `tests/integration/handoff-governance-plain-language-response-test.ps1`, `tests/integration/handoff-governance-review-file-reference-test.ps1`, `tests/integration/handoff-governance-descriptive-narration-test.ps1`, `tests/integration/handoff-governance-descriptive-stop-message-test.ps1`, and `extensions/specrew-speckit/scripts/validate-governance.ps1`, then record exact-tree execution evidence in `specs/016-substantive-interaction-model/quickstart.md` and `specs/016-substantive-interaction-model/iterations/002/quality/quality-evidence.md`. (Trace: FR-021, SC-010, plan.md Required Quality Gates, iterations/002/plan.md Required Quality Gates)
- [X] T013 [Owner: Iteration facilitator] [Effort: 0.5 SP] Reconcile `specs/016-substantive-interaction-model/tasks.md`, `specs/016-substantive-interaction-model/plan.md`, `specs/016-substantive-interaction-model/iterations/002/plan.md`, and `.specrew/quality/known-traps.md` so the 17.0 / 20.0 SP slice, explicit deferrals, and complete FR-008/FR-016/FR-020 through FR-024 traceability remain visible at the next planning-boundary handoff. (Trace: TG-004, plan.md Capacity Gate, iterations/002/plan.md Traceability Summary, user directive 2026-05-14)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup**: Starts immediately.
- **Phase 2: Foundational**: Depends on T001 and blocks all user stories.
- **Phase 3: US1**: Depends on T002.
- **Phase 4: US2**: Depends on T002 and can proceed in parallel with US1 after the shared helper protocol is stable.
- **Phase 5: US3**: Depends on T002 and can proceed in parallel with US1/US2 after the shared helper protocol is stable.
- **Phase 6: Polish**: Depends on T003-T011.

### Dependency Graph

```text
T001
  -> T002
    -> { T003 -> T004 -> T005,
         T006 -> { T007, T008 },
         T009 -> T010,
         T009 -> T011 }
      -> T012
        -> T013
```

### User Story Dependencies

- **US1 (P1)**: First executable MVP slice after T002 because the carryover authorization-fidelity gap underpins later docs and proof claims.
- **US2 (P1)**: Independent after T002, but its wording should use the settled US1 post-commit protocol rather than invent a parallel one.
- **US3 (P1)**: Independent after T002, but T010 must wait for T009 fixture proof before the severity flip.

### Parallel Opportunities

- **Setup vs documentation prep**: T001 is standalone and can start immediately.
- **US1**: T003 can run in parallel with early wording prep for T005 once T002 lands; T004 remains serial after T003 because it implements the verified protocol.
- **US2**: T007 can run in parallel with T008 after T006 stabilizes the documentation-truth expectations.
- **US3**: T009 and T011 can run in parallel after T002 because they touch different proof/corpus surfaces; T010 stays serial after T009.
- **Polish**: T012 can begin as soon as all story tasks finish; T013 closes the slice after evidence is recorded.

## Parallel Example: User Story 1

```text
Task: "T003 Create authorization-fidelity fixtures under tests/integration/fixtures/016-substantive-interaction-model/authorization-fidelity/ and tests/unit/fixtures/016-substantive-interaction-model/authorization-fidelity/"
Task: "T005 Formalize exact-tree post-commit verification evidence in specs/016-substantive-interaction-model/quickstart.md, README.md, and extensions/specrew-speckit/governance/validation-lane.md"
```

## Parallel Example: User Story 2

```text
Task: "T007 Update README.md and extensions/specrew-speckit/governance/validation-lane.md for the three-pillar model, validator scope, UTC-seconds policy, and stale-reference scan mandate"
Task: "T008 Update specs/001-specrew-product/contracts/coordinator-handoff-template.md, extensions/specrew-speckit/checklists/coordinator-handoff-governance.md, and .specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md with post-commit verification examples"
```

## Parallel Example: User Story 3

```text
Task: "T009 Create violating/compliant/exempt navigation fixtures under tests/integration/fixtures/016-substantive-interaction-model/navigation/ and tests/unit/fixtures/016-substantive-interaction-model/navigation/"
Task: "T011 Update .specrew/quality/known-traps.md with Feature 016 enforced rows, historical cross-references, and approved passive-guidance rows"
```

---

## Capacity Ledger

| Phase / Story | Tasks | Planned Effort |
| --- | --- | --- |
| Setup | T001 | 1.0 SP |
| Foundational | T002 | 1.0 SP |
| US1 — authorization fidelity carryovers | T003-T005 | 4.5 SP |
| US2 — docs/template truth | T006-T008 | 4.0 SP |
| US3 — proof, corpus, graduation | T009-T011 | 5.0 SP |
| Polish & cross-cutting | T012-T013 | 1.5 SP |
| **Total** | **T001-T013** | **17.0 / 20.0 SP** |

---

## Traceability Map

- **US1 -> FR-008 carryover + post-commit protocol / UTC seconds precision**: Covered by T003-T005.
- **US2 -> FR-022, FR-023 + stale-reference / exact-tree guidance carryovers**: Covered by T006-T008.
- **US3 -> FR-016 Iteration 2 graduation, FR-020, FR-021, FR-024 + approved passive-guidance corpus rows**: Covered by T009-T011.
- **Cross-cutting replay and reconciliation**: Covered by T001-T002 and T012-T013.

---

## Implementation Strategy

### MVP First

1. Complete T001-T002 to stabilize the shared replay lane and helper protocol.
2. Complete **US1 (T003-T005)** first.
3. Stop and validate Commit Reference synchronization plus UTC-seconds authoring before expanding documentation or severity graduation work.

### Incremental Delivery

1. Setup + Foundational -> shared post-commit protocol ready.
2. Deliver **US1** -> validate authorization fidelity.
3. Deliver **US2** -> validate public guidance and handoff truthfulness.
4. Deliver **US3** -> validate proof, corpus memory, and config-only graduation.
5. Run T012-T013 to close the revised Iteration 002 slice cleanly.

### Explicit Deferrals (Out of Active Task Scope)

- Standalone fractional-second parser broadening, including the deferred `decisions-ledger-parser-fractional-second-timestamp-incompatibility` follow-up
- Standalone stale-reference soft-validator family beyond the mandated stale-reference scan protocol and replay expectations
- Validator performance optimization beyond truthful baseline-locked calibration and documentation
- The non-feature-local corpus row `self-referential-feature-sp-surcharge`
- The unapproved passive-guidance candidates from Iteration 001 retro that are **not** named in `iterations/002/plan.md`

---

## Notes

- All checklist items follow the required unchecked-checkbox, Task ID, optional `[P]`, optional `[US#]`, `[Owner: ...]`, `[Effort: ...]`, exact-path, and `(Trace: ...)` format.
- No task silently drops in-scope carryovers; items left out of active execution are listed explicitly in **Explicit Deferrals**.
- This backlog stays planning-scoped: it prepares future implementation work only and does **not** authorize hardening-gate execution, implementation, review, retro, closeout, or feature-closeout in this session.

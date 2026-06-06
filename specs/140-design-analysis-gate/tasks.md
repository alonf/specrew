# Tasks: Minimal Design Alternatives / Architecture Intake Gate

**Input**: Design documents from `specs/140-design-analysis-gate/`
**Prerequisites**: `plan.md`, `spec.md`, `data-model.md`, `quickstart.md`, `contracts/design-analysis-gate.md`, `review-diagrams.md`
**Branch**: `140-design-analysis-gate`
**Capacity**: 18/20 story_points
**Protected Core**: Keep helper plus active plan-boundary sync enforcement and focused tests intact. If capacity pressure appears, defer full command/workflow metadata first.

## Phase 1: Foundation and Scope Guardrails

**Goal**: Establish the implementation guardrails before touching lifecycle code.

**Independent Test Criteria**: Scope review can prove no task requires full Proposal 137, broad validator rollout, broad multi-host slash-command deployment, Unix wrapper/install work, or release publishing.

- [ ] T001 [US0] [Owner: Spec Steward] [Capacity: 1 story_points] Confirm implementation scope against `specs/140-design-analysis-gate/plan.md`, document any found overrun in `specs/140-design-analysis-gate/iterations/001/drift-log.md`, and preserve Option B as the selected architecture. (Trace: FR-018, FR-019, FR-020, FR-021, TG-004, TG-005, SC-011, SC-012, SC-013)
- [ ] T002 [US0] [Owner: Implementer] [Capacity: 1 story_points] Add the first-slice applicability constants and excluded-surface guard comments in the new design-analysis helper area without touching Unix install, shell wrapper, bootstrap, beta, or stable publish files. (Trace: FR-002, FR-018, FR-019, FR-020, TG-005, SC-011, SC-012)

**Checkpoint**: Scope and exclusions are explicit before implementation begins.

---

## Phase 2: Protected Core - Design Analysis Artifact Helper

**Goal**: Build the reusable helper that validates the per-iteration `design-analysis.md` artifact shape.

**Independent Test Criteria**: A valid artifact under `specs/<feature>/iterations/<NNN>/design-analysis.md` passes helper validation, while missing sections, missing alternatives, missing option fields, missing recommendation, and missing decision evidence fail with actionable messages.

- [ ] T003 [US1] [Owner: Implementer] [Capacity: 2 story_points] Create `scripts/internal/design-analysis-gate.ps1` with a validator for `specs/<feature>/iterations/<NNN>/design-analysis.md`, including required sections for problem framing, decision points, alternatives, Crew recommendation, and Human Decision. (Trace: FR-003, FR-004, FR-013, FR-014, SC-001, SC-002, SC-010)
- [ ] T004 [US1] [Owner: Implementer] [Capacity: 2 story_points] Extend `scripts/internal/design-analysis-gate.ps1` to validate at least Simplest and Reasonable options, required per-option fields, conditional By-the-book handling, and Mermaid diagram or diagram-link evidence. (Trace: FR-005, FR-006, FR-007, FR-015, SC-003, SC-004, SC-005, SC-010)
- [ ] T005 [US1] [Owner: Implementer] [Capacity: 1 story_points] Add recommendation and Human Decision validation in `scripts/internal/design-analysis-gate.ps1`, requiring one named Crew recommendation plus chosen option, reason or modifications, and commit hash before plan. (Trace: FR-008, FR-009, FR-011, FR-016, SC-006, SC-008, SC-010)

**Checkpoint**: Artifact validation can be tested independently before boundary sync integration.

---

## Phase 3: Protected Core - Active Plan-Boundary Enforcement

**Goal**: Block active new substantive plan-boundary advancement until design-analysis evidence is complete.

**Independent Test Criteria**: Plan-boundary sync for a new substantive feature fails before a valid artifact and human decision, then passes after the artifact and decision are present.

- [ ] T006 [US1] [Owner: Implementer] [Capacity: 2 story_points] Wire the design-analysis helper into the active `plan` boundary path in `scripts/internal/sync-boundary-state.ps1` so new substantive iterations fail closed when the artifact, recommendation, or Human Decision is missing. (Trace: FR-001, FR-002, FR-010, FR-017, SC-001, SC-007, SC-010)
- [ ] T007 [US2] [Owner: Implementer] [Capacity: 1 story_points] Ensure the plan-boundary enforcement reads the selected option and modifications from `design-analysis.md` and exposes them as authoritative plan input or sync evidence for downstream planning. (Trace: FR-011, FR-012, SC-008, SC-009)
- [ ] T008 [US3] [Owner: Implementer] [Capacity: 1 story_points] Implement compatibility behavior so existing projects and existing in-flight features do not hard-fail solely because they predate `design-analysis.md`, while new substantive iterations still block. (Trace: FR-002, FR-018, FR-021, SC-012, SC-013)

**Checkpoint**: Enforcement and compatibility are complete before command or prompt polish.

---

## Phase 4: Protected Core - Tests and Fixtures

**Goal**: Prove the helper and plan-boundary enforcement with positive and negative tests.

**Independent Test Criteria**: Focused tests fail on missing artifact, missing required sections, missing recommendation, missing human decision, and invalid option structure; they pass for valid active evidence and legacy-compatible cases.

- [ ] T009 [US1] [Owner: Implementer] [Capacity: 2 story_points] Add `tests/unit/design-analysis-gate.tests.ps1` and fixtures for valid artifact, missing artifact, missing required sections, one-option artifact, missing option fields, and conditional By-the-book behavior. (Trace: FR-003, FR-004, FR-005, FR-006, FR-007, FR-013, FR-014, FR-015, SC-001, SC-002, SC-003, SC-004, SC-005, SC-010)
- [ ] T010 [US2] [Owner: Implementer] [Capacity: 1 story_points] Extend `tests/unit/design-analysis-gate.tests.ps1` with recommendation and Human Decision fixtures for chosen option, reason/modifications, commit hash, and placeholder recommendation rejection. (Trace: FR-008, FR-009, FR-011, FR-016, SC-006, SC-008, SC-010)
- [ ] T011 [US3] [Owner: Implementer] [Capacity: 2 story_points] Add `tests/integration/design-analysis-boundary.tests.ps1` covering active plan-boundary block/pass behavior, compatibility skip/warn behavior, and no broad validator hard-fail for existing or in-flight projects. (Trace: FR-010, FR-017, FR-018, FR-021, SC-007, SC-010, SC-012, SC-013)
- [ ] T012 [US0] [Owner: Reviewer] [Capacity: 1 story_points] Run or preserve coverage for `tests/integration/boundary-sync-atomic.tests.ps1` to confirm design-analysis enforcement does not break boundary sync atomicity or verdict-history updates. (Trace: FR-010, FR-011, FR-017, TG-006, SC-007, SC-008, SC-010)

**Checkpoint**: Protected enforcement and test core is complete. Do not continue to command metadata if capacity overruns.

---

## Phase 5: Lifecycle Guidance and Minimal Metadata

**Goal**: Make the new stop visible to coordinators without expanding into full Proposal 137 deployment.

**Independent Test Criteria**: Generated lifecycle guidance and low-risk command text describe `clarify/before-plan -> design-analysis -> plan`, while full multi-host slash-command deployment remains deferred.

- [ ] T013 [US1] [Owner: Spec Steward] [Capacity: 1 story_points] Update `scripts/specrew-start.ps1` generated lifecycle guidance to include the design-analysis stop for substantive features and the explicit `approved for plan with Option <X>` verdict shape. (Trace: FR-001, FR-008, FR-009, FR-012, SC-006, SC-008, SC-009)
- [ ] T014 [US0] [Owner: Spec Steward] [Capacity: 1 story_points] Update only cheap, existing command/workflow metadata if needed under `extensions/specrew-speckit/commands/` and `.specify/extensions/specrew-speckit/commands/` to reference the design-analysis stop; defer full slash-command deployment if this exceeds the narrow pattern. (Trace: FR-001, FR-018, FR-021, TG-005, SC-012, SC-013)

**Checkpoint**: Coordinator-visible guidance is consistent with the protected core and still first-slice scoped.

---

## Phase 6: Documentation, Evidence, and Review Readiness

**Goal**: Close documentation and evidence gaps before implementation review.

**Independent Test Criteria**: Quickstart commands run or are updated to the final test file names, compatibility behavior is documented, and review can classify implemented/enforced/observable/documented.

- [ ] T015 [US3] [Owner: Planner] [Capacity: 1 story_points] Update `specs/140-design-analysis-gate/quickstart.md` and `specs/140-design-analysis-gate/contracts/design-analysis-gate.md` with final command names, compatibility notes, and any selected-option evidence path changes discovered during implementation. (Trace: FR-018, FR-021, TG-004, TG-005, SC-010, SC-012, SC-013)
- [ ] T016 [US0] [Owner: Reviewer] [Capacity: 1 story_points] Run `pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .`, record warnings in review evidence, and confirm excluded surfaces were not touched. (Trace: FR-019, FR-020, TG-006, SC-011)

**Checkpoint**: Ready for before-implement approval when all tasks are traced and capacity remains within 20 story_points.

---

## Dependencies and Execution Order

- T001 and T002 must complete before helper or sync edits.
- T003-T005 build the helper and must complete before T006-T008.
- T006-T008 are the protected enforcement core and must complete before T013-T014 command metadata.
- T009-T012 can begin after the corresponding helper/sync behavior exists and should fail before implementation is completed.
- T013-T014 are deferrable first if capacity overruns; do not defer T003-T012 without human approval.
- T015-T016 close documentation and review evidence after implementation surfaces stabilize.

## Parallel Opportunities

- T009 and T010 can be prepared in parallel after T003-T005 define the helper API.
- T015 documentation updates can proceed in parallel with T016 validation after implementation stabilizes.
- Avoid parallel edits to `scripts/internal/sync-boundary-state.ps1`; T006, T007, and T008 should be sequenced.

## Verification Commands

```powershell
pwsh -File tests/unit/design-analysis-gate.tests.ps1
pwsh -File tests/integration/design-analysis-boundary.tests.ps1
pwsh -File tests/integration/boundary-sync-atomic.tests.ps1
pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

## Traceability Summary

| Requirement / Success Criterion | Covering Tasks |
| --- | --- |
| FR-001 | T006, T013, T014 |
| FR-002 | T002, T006, T008 |
| FR-003 | T003, T009 |
| FR-004 | T003, T009 |
| FR-005 | T004, T009 |
| FR-006 | T004, T009 |
| FR-007 | T004, T009 |
| FR-008 | T005, T013 |
| FR-009 | T005, T010, T013 |
| FR-010 | T006, T011, T012 |
| FR-011 | T005, T007, T010, T012 |
| FR-012 | T007, T013 |
| FR-013 | T003, T009 |
| FR-014 | T003, T009 |
| FR-015 | T004, T009 |
| FR-016 | T005, T010 |
| FR-017 | T006, T011, T012 |
| FR-018 | T001, T002, T008, T011, T014, T015 |
| FR-019 | T001, T002, T016 |
| FR-020 | T001, T002, T016 |
| FR-021 | T001, T008, T011, T014, T015 |
| TG-001 | T001-T016 |
| TG-002 | T001-T016 |
| TG-003 | T001-T016 |
| TG-004 | T001, T015 |
| TG-005 | T001, T002, T014, T015 |
| TG-006 | T012, T016 |
| SC-001 | T003, T006, T009 |
| SC-002 | T003, T009 |
| SC-003 | T004, T009 |
| SC-004 | T004, T009 |
| SC-005 | T004, T009 |
| SC-006 | T005, T010, T013 |
| SC-007 | T006, T011, T012 |
| SC-008 | T005, T007, T010, T012, T013 |
| SC-009 | T007, T013 |
| SC-010 | T009, T010, T011, T012, T015 |
| SC-011 | T001, T002, T016 |
| SC-012 | T001, T008, T011, T014, T015 |
| SC-013 | T001, T008, T011, T014, T015 |

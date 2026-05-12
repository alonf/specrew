# Tasks: Handoff Format Scoping

**Input**: Design documents from `specs/014-handoff-format-scoping/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/coordinator-handoff-scoping.md`, `quickstart.md`

**Iteration Boundary**: This backlog is intentionally limited to **Iteration 001**. Iteration 002 proof/calibration work stays explicitly deferred and is **not** scaffolded here.

**Tests**: The spec mandates testing scenarios, so this backlog includes only the Iteration 001 validation work already requested by the approved artifacts. New Iteration 002 warning-fixture and calibration tasks are deferred rather than scaffolded.

## Phase 1: Setup

**Purpose**: Lock the approved execution boundary before any governed surface is edited.

- [ ] T001 Confirm the approved Iteration 001 boundary and two-iteration split in `specs/014-handoff-format-scoping/plan.md`

---

## Phase 2: Foundational

**Purpose**: Anchor all implementation decisions to the approved contract and defer-proof boundary before story work starts.

- [ ] T002 Confirm the deferred proof-work boundary and preserved regression lane in `specs/014-handoff-format-scoping/quickstart.md`

**Checkpoint**: Iteration 001 scope is locked; user-story work can begin without scaffolding Iteration 002 artifacts.

---

## Phase 3: User Story 1 - Use the right response type (Priority: P1) 🎯 MVP

**Goal**: Make the coordinator consistently choose a final stop message only for real human blockers and use a single-line in-flight progress update otherwise.

**Independent Test**: Review the worked examples and synthetic scenarios in the updated governed guidance and confirm genuine human-blocked stops use the three-section format while in-flight transitions and first acknowledgements use single-line progress prose.

- [ ] T003 [P] [US1] Update response-type selector criteria and first-acknowledgement guidance in `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`
- [ ] T004 [P] [US1] Update coordinator response instructions and worked examples in `extensions/specrew-speckit/prompts/coordinator-response.md`
- [ ] T005 [US1] Update dual response-type examples while preserving the existing stop-message format in `specs/001-specrew-product/contracts/coordinator-handoff-template.md`

**Checkpoint**: User Story 1 is complete when prompt and template surfaces all classify stop vs progress the same way.

---

## Phase 4: User Story 2 - Detect handoff-format misuse (Priority: P1)

**Goal**: Add additive low-noise validator warnings for empty user-action sections and transitional stop claims without introducing Iteration 002 proof scaffolding.

**Independent Test**: For Iteration 001, manually exercise the updated validator against the approved contract examples and synthetic misuse scenarios, confirm the two warnings are additive and advisory, and leave deterministic violating/compliant fixtures deferred to Iteration 002.

- [ ] T006 [US2] Add fixed placeholder-phrase matching and `soft-warning.empty-user-action-section` logic in `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`
- [ ] T007 [US2] Add `soft-warning.transitional-stop-claim` logic and preserve additive soft-warning behavior in `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`
- [ ] T008 [US2] Manually exercise the new warning paths against the approved scenarios in `specs/014-handoff-format-scoping/contracts/coordinator-handoff-scoping.md`

**Checkpoint**: User Story 2 is complete when the validator behavior matches the approved warning contract without adding new Iteration 002 fixtures or calibration artifacts.

---

## Phase 5: User Story 3 - Keep governance artifacts aligned (Priority: P2)

**Goal**: Keep the checklist, runtime agent guidance, template wording, and `human-handoff-id-context` applicability aligned with the approved selector.

**Independent Test**: Compare the updated checklist, runtime guidance, template examples, and `human-handoff-id-context` wording for the same synthetic scenarios and confirm they classify final stop messages and in-flight progress updates consistently.

- [ ] T009 [P] [US3] Update selector and mixed-case review criteria in `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`
- [ ] T010 [P] [US3] Update coordinator runtime guidance for stop-vs-progress scoping in `.github/agents/squad.agent.md`
- [ ] T011 [P] [US3] Update generated Squad template guidance for stop-vs-progress scoping in `.squad/templates/squad.agent.md`
- [ ] T012 [US3] Extend the existing `human-handoff-id-context` row to cover both governed response types in `.specrew/quality/known-traps.md` without adding the deferred Iteration 002 misapplied-stop graduation
- [ ] T013 [US3] Reconcile cross-artifact wording against the approved selector contract in `specs/014-handoff-format-scoping/contracts/coordinator-handoff-scoping.md`

**Checkpoint**: User Story 3 is complete when all coordinator-facing governance surfaces express the same stop-vs-progress rule and the existing `human-handoff-id-context` row covers both response types without adding the deferred Iteration 002 trap graduation.

---

## Phase 6: Polish & Cross-Cutting Validation

**Purpose**: Re-run preserved validation without creating deferred warning-fixture or calibration artifacts.

- [ ] T014 Run preserved handoff-governance regression scripts for additive-warning compatibility in `tests/integration/handoff-governance-jargon-response-test.ps1`, `tests/integration/handoff-governance-plain-language-response-test.ps1`, `tests/integration/handoff-governance-review-file-reference-test.ps1`, `tests/integration/handoff-governance-descriptive-narration-test.ps1`, and `tests/integration/handoff-governance-descriptive-stop-message-test.ps1`
- [ ] T015 Run repository governance validation for bounded Iteration 001 compliance in `extensions/specrew-speckit/scripts/validate-governance.ps1`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Starts immediately.
- **Foundational (Phase 2)**: Depends on T001.
- **User Story 1 (Phase 3)**: Depends on T001-T002.
- **User Story 2 (Phase 4)**: Depends on T001-T002 and can start in parallel with US1 after the boundary is locked.
- **User Story 3 (Phase 5)**: Depends on T003-T007 so the selector language and warning identifiers are stable before alignment work.
- **Polish (Phase 6)**: Depends on T003-T013.

### User Story Dependencies

- **US1 (P1)**: First MVP slice; no dependency on other user stories after setup/foundational confirmation.
- **US2 (P1)**: Parallelizable with US1 after setup/foundational confirmation, but its validator wording should finish before US3 reconciliation.
- **US3 (P2)**: Follows US1 and US2 because it aligns downstream governance surfaces to the settled selector and warning language.

### Within Each User Story

- Update guidance or validator logic before performing the story's verification task.
- Keep all work inside existing Iteration 001 files; do not create deferred Iteration 002 artifacts.
- Complete story-level verification before moving to cross-cutting regression validation.

---

## Parallel Opportunities

- **US1**: T003 and T004 can run in parallel; T005 follows after wording stabilizes.
- **US2**: No safe same-file parallelism inside `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`; complete T006 before T007.
- **US3**: T009, T010, and T011 can run in parallel; T012 and T013 follow once those edits land.
- **Cross-story**: US1 and US2 can proceed in parallel after T001-T002 if separate owners handle prompt/template work and validator work.

## Parallel Example: User Story 1

```text
Task: "T003 Update response-type selector criteria and first-acknowledgement guidance in extensions/specrew-speckit/prompts/coordinator-decision-guidance.md"
Task: "T004 Update coordinator response instructions and worked examples in extensions/specrew-speckit/prompts/coordinator-response.md"
```

## Parallel Example: User Story 3

```text
Task: "T009 Update selector and mixed-case review criteria in extensions/specrew-speckit/checklists/coordinator-handoff-governance.md"
Task: "T010 Update coordinator runtime guidance for stop-vs-progress scoping in .github/agents/squad.agent.md"
Task: "T011 Update generated Squad template guidance for stop-vs-progress scoping in .squad/templates/squad.agent.md"
```

---

## Ownership & Capacity Plan

**Capacity Unit**: Story points (`sp`) within the approved Iteration 001 budget.

| Task | Owner | Ownership Rationale | Capacity | Primary Trace |
| --- | --- | --- | --- | --- |
| T001 | Spec steward | Locks the approved two-iteration boundary before execution begins | 0.25 sp | `plan.md` summary, Constitution XVI-XVIII |
| T002 | Iteration facilitator | Confirms the preserved regression lane and deferred proof-work boundary | 0.25 sp | `quickstart.md` sections 1, 4, 5 |
| T003 | Governance prompt stewards | Selector criteria live in the decision guidance surface | 0.75 sp | US1, FR-001, FR-002 |
| T004 | Governance prompt stewards | Coordinator-facing wording and worked examples live in the runtime prompt surface | 0.75 sp | US1, FR-001, FR-002 |
| T005 | Handoff-template stewards | The governed response template must show both response types without redesigning the stop format | 0.50 sp | US1, FR-003 |
| T006 | Validator maintainers | Placeholder phrase matching belongs in the shared validator path | 1.00 sp | US2, FR-004 |
| T007 | Validator maintainers | Transitional-stop detection must stay additive inside the same validator surface | 1.00 sp | US2, FR-005, FR-006 |
| T008 | Validator maintainers | Manual Iteration 001 warning checks confirm contract alignment before deferred fixture work | 0.50 sp | US2, contract, FR-006 |
| T009 | Governance prompt stewards | The reviewer checklist must mirror the same selector and mixed-case guidance | 0.50 sp | US3, FR-002 |
| T010 | Agent-guidance stewards | Runtime Squad guidance must stay aligned with coordinator-facing rules | 0.50 sp | US3, FR-002 |
| T011 | Agent-guidance stewards | Generated Squad template guidance must match the runtime agent wording | 0.50 sp | US3, FR-002 |
| T012 | Governance corpus stewards | FR-007 requires only the existing `human-handoff-id-context` row applicability update, not the deferred new trap graduation | 0.50 sp | US3, FR-007, plan.md Iteration 001 |
| T013 | Iteration facilitator | A single reconciliation pass prevents prompt/template/corpus drift before validation | 0.25 sp | US3, TG-003, TG-004 |
| T014 | Test maintainers | Preserved regression scripts protect the additive validator workflow and backward-compatible handoff behavior during the bounded rollout | 0.50 sp | FR-006, NFR-003, TG-004 |
| T015 | Validator maintainers | Repository governance validation confirms the bounded Iteration 001 rollout still satisfies additive, coordinator-scoped governance rules | 0.25 sp | FR-006, NFR-003, TG-004 |

## Traceability Map

- **US1 → FR-001, FR-002, FR-003**: Covered by T003-T005.
- **US2 → FR-004, FR-005, FR-006**: Covered by T006-T008.
- **US3 → FR-002, FR-003, FR-007**: Covered by T009-T013.
- **Cross-cutting validation → FR-006, NFR-003, TG-004**: Covered by T014-T015.
- **FR-008 and FR-009**: Explicitly deferred to Iteration 002 and therefore intentionally excluded from executable tasks in this backlog.
- **TG-004 clarified decisions**: Preserved by T001-T002, T003-T012, and the explicit Iteration 002 deferral section below.

---

## Implementation Strategy

### MVP First

1. Complete T001-T002 to lock the approved boundary.
2. Complete **US1** (T003-T005) as the MVP slice for visible stop-vs-progress behavior.
3. Validate the updated guidance against the US1 independent test before widening scope.

### Iteration 001 Delivery Strategy

1. Finish T001-T002.
2. Deliver **US1** and **US2** as the bounded Iteration 001 selector + warning rollout.
3. Deliver **US3** to align downstream governance artifacts and `human-handoff-id-context`.
4. Run T014-T015 before declaring Iteration 001 ready.

### Explicit Iteration 002 Deferral

The following work is intentionally **deferred** and must not be scaffolded in this backlog:

- `tests/integration/handoff-governance-empty-user-action-test.ps1`
- `tests/integration/handoff-governance-transitional-stop-claim-test.ps1`
- `tests/integration/fixtures/handoff-format-scoping/`
- `extensions/specrew-speckit/governance/validation-lane.md` follow-through for the new warnings
- New misapplied-stop known-traps graduation and proof citations beyond the existing `human-handoff-id-context` applicability update in `.specrew/quality/known-traps.md`
- Planned `specs/014-handoff-format-scoping/quality/` proof artifacts

---

## Notes

- Every checklist item uses the required `- [ ] T### [P?] [Story?] Description with file path` format.
- User-story tasks are ordered by priority from the approved spec: P1, P1, then P2.
- This backlog is planning-only; it does not authorize implementation beyond the scoped Iteration 001 files above.

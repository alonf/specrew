# Tasks: F-049 Release Pipeline Hardening + Substantive Intake Slice

**Input**: Design documents from `specs/049-pipeline-hardening-intake/`  
**Prerequisites**: `plan.md`, `spec.md`, `data-model.md`, `contracts/pipeline-hardening-intake.md`, `quickstart.md`, `proposals/120-handoff-block-validator-enforcement.md`, `iterations/001/retro.md`  
**Roadmap Guardrail**: Four iterations total. Iteration `001` is closed history and MUST NOT be reopened. Iteration `002` stays limited to troubleshooting docs, onboarding cross-references, `specrew update` vs `Update-Module Specrew` clarification, and the Shape-5 durability lesson. Iteration `003` stays limited to the bounded Proposal `063` persona-driven `/speckit.specify` slice. Iteration `004` delivers Proposal `120` full five-pillar bypass detection, explicitly including Pillar `5` committed-tree versus working-tree-only-state enforcement.

**Organization**: Remaining executable tasks are grouped by approved user story / iteration so each slice can be completed and reviewed independently without reopening closed Iteration `001`.

---

## Phase 1: Closed History - Iteration 001 (Delivered, Do Not Reopen)

**Purpose**: Preserve the already accepted release-hardening work as historical context only.

**Delivered scope**:

- Iteration `001` closed with delivered task IDs `T001-T007` and `T018-T020`.
- Delivered history is authoritative in `specs/049-pipeline-hardening-intake/iterations/001/retro.md`.
- No executable tasks are reopened in this refresh.

---

## Phase 2: Foundational Guardrails for Remaining Iterations

**Purpose**: Keep Iterations `002-004` aligned to the approved four-iteration roadmap without adding new shared infrastructure scope.

**Guardrails**:

- Reuse the delivered Iteration `001` publish-harness and release-hardening baseline.
- Keep traceability explicit for `TG-006`, `TG-007`, and `TG-008`.
- Reserve all Proposal `120` five-pillar enforcement work for Iteration `004`.

---

## Phase 3: User Story 2 - Troubleshooting Guide and Documentation (Priority: P2) / Iteration 002

**Goal**: Deliver the durable troubleshooting and onboarding recovery slice without expanding beyond the approved documentation focus.

**Independent Test**: `docs/troubleshooting.md` exists, is listed in `Specrew.psd1`, is linked from `README.md`, `docs/getting-started.md`, and `docs/user-guide.md`, and explicitly explains both `specrew update` vs `Update-Module Specrew` and the Shape-5 committed-tree durability lesson.

- [ ] T008 [US2] [assigned_to: Implementer] [effort: 1.75 SP] Draft `docs/troubleshooting.md` with sections for PSGallery side-by-side cache cleanup, FileList omissions, deploy-script exceptions, clean reinstall flows, `specrew update` vs `Update-Module Specrew` scope boundaries, and the Shape-5 lesson that accepted review evidence must match committed tree state. (Trace: FR-006, FR-015, FR-017, TG-006, TG-007, SC-002)
- [ ] T009 [US2] [assigned_to: Implementer] [effort: 0.50 SP] Register `docs/troubleshooting.md` in `Specrew.psd1` `FileList` in the same change that introduces the guide. (Trace: FR-007, TG-006, TG-007, SC-002)
- [ ] T010 [US2] [assigned_to: Implementer] [effort: 1.00 SP] Add onboarding cross-reference links to `docs/troubleshooting.md` from `README.md`, `docs/getting-started.md`, and `docs/user-guide.md`. (Trace: FR-016, TG-006, TG-007, SC-002)
- [ ] T011 [US2] [assigned_to: Reviewer] [effort: 0.75 SP] Review `docs/troubleshooting.md`, `README.md`, `docs/getting-started.md`, `docs/user-guide.md`, and `Specrew.psd1`, then record Iteration `002` documentation acceptance evidence in `specs/049-pipeline-hardening-intake/iterations/002/quality/quality-evidence.md`. (Trace: FR-006, FR-007, FR-015, FR-016, FR-017, TG-006, TG-007, SC-002)

**Checkpoint**: Iteration `002` is complete when recovery guidance is durable, discoverable, and explicitly teaches the Shape-5 durability lesson without changing runtime behavior.

---

## Phase 4: User Story 3 - Persona-Driven Substantive Specification Intake (Priority: P3) / Iteration 003

**Goal**: Deliver the bounded Proposal `063` persona-driven `/speckit.specify` slice without silently widening into the full proposal footprint.

**Independent Test**: The `/speckit.specify` flow presents only the approved four personas, uses the 12-category intake catalog, branches cleanly across Modes A/B/C, and supports `"Other"` / `"I don't know, you decide"` defaults while keeping the slice bounded to the approved intake behavior.

- [ ] T012 [P] [US3] [assigned_to: Reviewer] [effort: 1.50 SP] Add failing bounded-slice persona intake coverage to `tests/integration/substantive-interaction-model-iteration2.ps1` and `tests/integration/skill-templates.tests.ps1` for Product Manager, UX/UI, Architect, and AI Researcher / Project Manager selection. (Trace: FR-008, FR-009, TG-006, TG-007, SC-003)
- [ ] T013 [US3] [assigned_to: Implementer] [effort: 1.50 SP] Update `.github/prompts/speckit.specify.prompt.md` and `.github/agents/speckit.specify.agent.md` so `/speckit.specify` offers only the approved four personas and stays bounded to the Proposal `063` intake slice. (Trace: FR-008, TG-006, TG-007, SC-003)
- [ ] T014 [US3] [assigned_to: Implementer] [effort: 2.00 SP] Update `.specify/workflows/speckit/workflow.yml` and `.specify/workflow-registry.json` to drive the approved 12-category intake catalog without widening beyond the Iteration `003` slice. (Trace: FR-009, TG-006, TG-007, SC-003)
- [ ] T015 [US3] [assigned_to: Implementer] [effort: 2.00 SP] Implement Mode A / Mode B / Mode C branching and prompt sequencing in `.github/prompts/speckit.specify.prompt.md` and `.specify/workflows/speckit/workflow.yml` based on input completeness. (Trace: FR-010, TG-006, TG-007, SC-003)
- [ ] T016 [US3] [assigned_to: Implementer] [effort: 1.50 SP] Add `"Other"` and `"I don't know, you decide"` fallback guidance plus stack-aware defaulting behavior in `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md`, and `.specify/workflows/speckit/workflow.yml`. (Trace: FR-011, TG-006, TG-007, SC-003)
- [ ] T017 [US3] [assigned_to: Reviewer] [effort: 1.00 SP] Run the bounded persona-intake regression path with `tests/integration/substantive-interaction-model-iteration2.ps1` and `tests/integration/skill-templates.tests.ps1`, then record Iteration `003` verification evidence in `specs/049-pipeline-hardening-intake/iterations/003/quality/quality-evidence.md`. (Trace: FR-008, FR-009, FR-010, FR-011, TG-006, TG-007, SC-003)

**Checkpoint**: Iteration `003` is complete when the persona-driven intake slice works end-to-end and remains visibly bounded to the approved Proposal `063` scope.

---

## Phase 5: User Story 4 - Governance Bypass Detection Before Closeout (Priority: P4) / Iteration 004

**Goal**: Deliver the full Proposal `120` five-pillar bypass-detection slice, including fail-closed Pillar `5` enforcement for committed-tree versus working-tree-only-state mismatches.

**Independent Test**: Governance validation surfaces all five approved bypass pillars, and accepted closeout evidence fails when `review.md` cites production files that are absent from the committed `Tree Under Review`.

- [ ] T021 [P] [US4] [assigned_to: Reviewer] [effort: 1.25 SP] Extend `tests/integration/non-specrew-session-bypass.tests.ps1` with red-path coverage for all five Proposal `120` pillars, including a Pillar `5` case where `review.md` cites production files absent from the committed `Tree Under Review`. (Trace: FR-018, FR-019, FR-020, FR-021, FR-022, TG-006, TG-007, TG-008, SC-004)
- [ ] T022 [P] [US4] [assigned_to: Implementer] [effort: 1.00 SP] Add shared helper support to `extensions/specrew-speckit/scripts/shared-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` for handoff detection, verdict-history lookup, and review-evidence versus tree inspection used by the five pillars. (Trace: FR-018, FR-021, FR-022, TG-007, TG-008, SC-004)
- [ ] T023 [US4] [assigned_to: Implementer] [effort: 1.00 SP] Implement Pillar `1` missing-handoff detection and Pillar `2` trigger-bypass classification in `extensions/specrew-speckit/scripts/validate-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`. (Trace: FR-018, FR-019, TG-007, TG-008, SC-004)
- [ ] T024 [US4] [assigned_to: Implementer] [effort: 0.75 SP] Implement Pillar `3` ephemeral-host wrong-location detection and canonical-path remediation messaging in `extensions/specrew-speckit/scripts/validate-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`. (Trace: FR-020, TG-007, TG-008, SC-004)
- [ ] T025 [US4] [assigned_to: Implementer] [effort: 1.00 SP] Add Pillar `4` state-advance-without-verdict enforcement to `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `extensions/specrew-speckit/scripts/sync-boundary-state.ps1`, and `.specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1` so human-judgment boundary advances require matching verdict history. (Trace: FR-021, TG-007, TG-008, SC-004)
- [ ] T026 [US4] [assigned_to: Implementer] [effort: 1.25 SP] Implement Pillar `5` committed-tree versus working-tree-only-state enforcement in `extensions/specrew-speckit/scripts/validate-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, blocking accepted closeout evidence when production files cited in `review.md` are absent from the committed `Tree Under Review` while leaving test-only mismatches as warnings. (Trace: FR-022, TG-007, TG-008, SC-004)
- [ ] T027 [P] [US4] [assigned_to: Reviewer] [effort: 0.75 SP] Add or update governance fixtures under `tests/integration/fixtures/` and `tests/unit/fixtures/` to exercise handoff gaps, trigger-bypass artifact gaps, ephemeral-location artifacts, verdict-history gaps, and Pillar `5` review-evidence mismatches. (Trace: FR-018, FR-019, FR-020, FR-021, FR-022, TG-007, TG-008, SC-004)
- [ ] T028 [US4] [assigned_to: Reviewer] [effort: 1.00 SP] Run `tests/integration/non-specrew-session-bypass.tests.ps1` and `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .`, verify mirror parity between `extensions/` and `.specify/extensions/`, and record Iteration `004` closeout-blocking evidence in `specs/049-pipeline-hardening-intake/iterations/004/quality/quality-evidence.md`. (Trace: FR-018, FR-019, FR-020, FR-021, FR-022, TG-006, TG-007, TG-008, SC-004)

**Checkpoint**: Iteration `004` is complete only when all five pillars surface correctly and Pillar `5` blocks closeout on working-tree-only production evidence.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Preserve roadmap discipline and avoid adding unapproved scope while the remaining iterations close in order.

- No additional polish tasks are authorized in this refresh; finish Iterations `002`, `003`, and `004` exactly as scoped above.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Closed History)**: Already delivered; reference only.
- **Phase 2 (Guardrails)**: Informational guardrails for all remaining work.
- **Phase 3 / Iteration 002**: Starts immediately; unblocks the approved documentation slice.
- **Phase 4 / Iteration 003**: Starts after Iteration `002` acceptance to preserve the approved bounded roadmap.
- **Phase 5 / Iteration 004**: Starts after Iteration `003` acceptance; contains all Proposal `120` five-pillar enforcement work.
- **Phase 6 (Polish)**: No additional execution scope.

### User Story Dependencies

- **US2 / Iteration 002**: No dependency on new code changes; relies on the delivered Iteration `001` baseline.
- **US3 / Iteration 003**: Depends on roadmap continuity after Iteration `002`; must remain bounded to Proposal `063` intake scope.
- **US4 / Iteration 004**: Depends on the approved final Proposal `120` slice and MUST preserve `TG-008` Pillar `5` enforcement.

### Within Each User Story

- Validation-first tasks run before implementation changes where applicable.
- Content / prompt / validator implementation follows after red-path coverage is defined.
- Verification evidence is recorded only after the slice passes its independent test.

### Parallel Opportunities

- `T012` can run in parallel with early persona-scope review before prompt/workflow edits begin.
- `T021` and `T022` can start in parallel because test red paths and shared helper scaffolding touch different files.
- `T027` can run in parallel with validator implementation once the five pillar shapes are frozen.

---

## Parallel Example: User Story 4 / Iteration 004

```text
Task: "T021 Extend tests/integration/non-specrew-session-bypass.tests.ps1 with five-pillar red coverage"
Task: "T022 Add shared helper support in extensions/.../shared-governance.ps1 and .specify/.../shared-governance.ps1"
Task: "T027 Add/update governance fixtures under tests/integration/fixtures/ and tests/unit/fixtures/"
```

---

## Implementation Strategy

### Next Approved Slice First (Iteration 002)

1. Preserve Iteration `001` as closed history.
2. Complete Iteration `002` documentation tasks `T008-T011`.
3. Stop and validate discoverability before touching `/speckit.specify`.

### Incremental Delivery

1. Finish Iteration `002` docs and onboarding discoverability.
2. Finish Iteration `003` bounded persona-intake slice.
3. Finish Iteration `004` Proposal `120` five-pillar enforcement with Pillar `5` fail-closed behavior.

### Team Strategy

1. Spec Steward and Implementer close Iteration `002`.
2. Prompt/workflow work for Iteration `003` proceeds after doc acceptance.
3. Validator and fixture work for Iteration `004` proceeds with helper/test parallelism where marked `[P]`.

---

## Notes

- Task IDs `T001-T007` and `T018-T020` remain closed historical records for Iteration `001`.
- New executable work starts at `T008` and reserves `T021+` for Iteration `004`.
- `[P]` marks tasks that can run in parallel without conflicting file ownership.
- `[US2]`, `[US3]`, and `[US4]` map directly to the approved remaining user stories / iterations.
- This refresh intentionally avoids reopening Iteration `001` or widening Iterations `002-004` beyond the approved roadmap.

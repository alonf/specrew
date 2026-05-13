# Tasks: Substantive Interaction Model

**Input**: Design documents from `C:\Dev\Specrew\specs\016-substantive-interaction-model\`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/boundary-authorization-and-handoff.md`, `contracts/interaction-model-validator-contract.md`  
**Authority**: `specs/016-substantive-interaction-model/spec.md` and `specs/016-substantive-interaction-model/plan.md` are authoritative for this backlog; preserve the approved two-iteration split and the three-pillar framing exactly.  
**Scope Boundary**: Keep this backlog bounded to the approved Feature 016 implementation surfaces in prompt guidance, validator scripts, contracts, corpus, README/template documentation, and replay fixtures. Do **not** scaffold `specs/016-substantive-interaction-model/iterations/` artifacts in this backlog.  
**Capacity Guardrail**: Preserve **Iteration 1 ~13 SP** for coordinator prompt, authorization-shape, bundled-boundary, Pillar 2 soft-rule, and Iteration 1 bare-path soft-warning work only; preserve **Iteration 2 ~9 SP** for violating/compliant fixtures, three active corpus-row updates plus passive `thin-artifact-content`, historical cross-references, README lifecycle + validator-doc updates, per-feature handoff-template updates, and the bare-path hard-fail config flip only.  
**Tests**: PowerShell integration replay, validator unit coverage, and fresh-context handoff review are required because `spec.md` explicitly requires violating/compliant fixtures, bounded false-positive proof, and independent console-only validation across the three user stories.

## Format: `- [ ] T### [P?] [US#?] [Owner: ...] [Effort: ...] Description with exact file path(s) (Trace: ...)`

- **[P]**: Task can run in parallel once dependencies are satisfied
- **[US#]**: Present only for user-story work (`[US1]`, `[US2]`, `[US3]`)
- **[Owner]**: Primary owner role aligned to `spec.md`
- **[Effort]**: Relative effort estimate (`S`, `M`, `L`)
- Every task includes exact file path(s) and explicit `(Trace: ...)` references

## Ownership Rationale

Owner role assignments are derived from the authoritative specification in `spec.md` and traced to the functional requirements (FRs) each owner implements:

- **Governance steward** (FR-001–FR-005, FR-008, FR-009, FR-010, FR-014, FR-015): Responsible for updating coordinator prompt surfaces, defining canonical authorization-record shapes, and ensuring boundary discipline guidance is clear and worked-example-rich.
- **Validator steward** (FR-006, FR-007, FR-011–FR-013, FR-016–FR-019): Responsible for implementing hard-validator rules (bundled-boundary-advance, parameterized bare-path severity), soft-warning rules (thin-what-i-just-did, unspecific-stop-boundary, unactionable-user-request, bare-path variants), and maintaining exemption-context correctness and performance budgets.
- **Quality steward** (FR-020, FR-021, T001, T024, T026): Responsible for baseline capture, integration test fixtures (violating/compliant), known-trap corpus rows, validator enforcement verification, and final closeout validation.
- **Documentation steward** (FR-022, FR-023): Responsible for README "Recommended Lifecycle" updates, validator-scope documentation, and per-feature handoff template examples reflecting all three pillars.
- **Iteration facilitator** (T002, T027): Responsible for reconciling planning surfaces, confirming scope boundaries, and validating that the feature completed without creating unauthorized iteration scaffolds.

---

## Phase 1: Setup

**Purpose**: Lock the approved authority boundary, capture the current baseline, and prepare execution without creating iteration scaffolds.

- [ ] T001 [Owner: Quality steward] [Effort: M] Run the pre-Feature-016 baseline from repo root using `tests/integration/handoff-governance-jargon-response-test.ps1`, `tests/integration/handoff-governance-plain-language-response-test.ps1`, `tests/integration/handoff-governance-review-file-reference-test.ps1`, `tests/integration/handoff-governance-descriptive-narration-test.ps1`, `tests/integration/handoff-governance-descriptive-stop-message-test.ps1`, and `extensions/specrew-speckit/scripts/validate-governance.ps1`, then record the baseline result in `specs/016-substantive-interaction-model/quickstart.md`. (Trace: TG-005, TG-006, SC-010, quickstart.md Suggested validation commands, plan.md Required Quality Gates)
- [ ] T002 [Owner: Iteration facilitator] [Effort: S] Reconcile `specs/016-substantive-interaction-model/plan.md`, `specs/016-substantive-interaction-model/research.md`, `specs/016-substantive-interaction-model/data-model.md`, `specs/016-substantive-interaction-model/quickstart.md`, `specs/016-substantive-interaction-model/contracts/boundary-authorization-and-handoff.md`, and `specs/016-substantive-interaction-model/contracts/interaction-model-validator-contract.md` against the approved Iteration 1 / Iteration 2 split, keeping the no-iteration-scaffold boundary explicit. (Trace: TG-005, TG-006, plan.md Summary, plan.md Capacity Gate, quickstart.md Scope Reminder)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Freeze the normative contract surfaces and shared helper plumbing that all three user stories depend on.

**⚠️ CRITICAL**: No user-story work should begin until the contract vocabulary, scope limits, and shared helper surfaces are aligned.

- [ ] T003 [P] [Owner: Governance steward] [Effort: S] Reconcile `specs/016-substantive-interaction-model/contracts/boundary-authorization-and-handoff.md` and `specs/016-substantive-interaction-model/contracts/interaction-model-validator-contract.md` with `specs/016-substantive-interaction-model/data-model.md` and `specs/016-substantive-interaction-model/research.md` so boundary names, canonical authorization fields, warning/FAIL IDs, exemption contexts, and scope limits remain mechanically aligned before implementation. (Trace: FR-008, FR-009, FR-016, FR-018, TG-001, TG-002, TG-003)
- [ ] T004 [Owner: Validator steward] [Effort: M] Add shared Feature 016 helper plumbing in `extensions/specrew-speckit/scripts/shared-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` for canonical boundary-signature classification, decisions-ledger authorization parsing, handoff-section extraction, and parameterized rule-severity lookup used by the three pillar validators. (Trace: FR-006, FR-007, FR-011, FR-016, NFR-001, NFR-003)

**Checkpoint**: Normative contracts and shared helper primitives are ready; user-story work can begin without scope drift.

---

## Phase 3: User Story 1 - Enforce one authorization per boundary (Priority: P1) 🎯 MVP

**Goal**: Make per-boundary authorization, single-step `continue`, and paired authorization recording mechanically enforceable.

**Independent Test**: Replay a lifecycle sequence that previously bundled multiple boundaries and confirm Squad now stops after each boundary commit, requests fresh authorization, records paired hardening-gate + implementation approvals as two entries, and FAILs on missing intervening authorization.

### Iteration 1 implementation slice

- [ ] T005 [US1] [Owner: Governance steward] [Effort: M] Update boundary-discipline guidance in `.github/agents/squad.agent.md`, `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`, `extensions/specrew-speckit/prompts/coordinator-response.md`, `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, and `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` so the 7 per-iteration boundaries are enumerated by name, bundled advances are forbidden, compliant and violating examples are explicit, and `continue` is defined as a single-boundary step. (Trace: FR-001, FR-002, FR-003, FR-004, FR-005, TG-001, SC-001, SC-003)
- [ ] T006 [US1] [Owner: Governance steward] [Effort: M] Add the canonical authorization-record shape and paired-authorization recording contract to `specs/016-substantive-interaction-model/contracts/boundary-authorization-and-handoff.md`, `.github/agents/squad.agent.md`, and `extensions/specrew-speckit/prompts/coordinator-response.md` so Squad generates reviewable single-boundary `.squad/decisions.md` entries and expands one hardening-gate + implementation paste into two distinct records. (Trace: FR-008, FR-009, TG-001, SC-001, data-model.md Boundary Authorization Record)
- [ ] T007 [US1] [Owner: Validator steward] [Effort: L] Implement `validation-fail.bundled-boundary-advance`, canonical boundary subject-line recognition, and paired-authorization gap detection in `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `extensions/specrew-speckit/scripts/shared-governance.ps1`, and `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1`. (Trace: FR-006, FR-007, FR-008, FR-009, TG-001, SC-002, NFR-004, NFR-006)
- [ ] T008 [US1] [Owner: Quality steward] [Effort: S] Replay the boundary-discipline scenarios from `specs/016-substantive-interaction-model/quickstart.md` against `.github/agents/squad.agent.md` and `extensions/specrew-speckit/scripts/validate-governance.ps1`, then record the single-step `continue` and paired-authorization evidence in `specs/016-substantive-interaction-model/quickstart.md`. (Trace: SC-001, SC-002, SC-003, quickstart.md Iteration 1 Steps, plan.md Required Quality Gates)

### Iteration 2 proof + sustainability slice

- [ ] T009 [P] [US1] [Owner: Quality steward] [Effort: M] Create violating and compliant boundary-discipline fixtures in `tests/integration/fixtures/016-substantive-interaction-model/boundary-discipline/` and extend `tests/integration/substantive-interaction-model-iteration2.ps1` so bundled advances FAIL, paired authorization records pass, and grandfathered pre-016 history remains clean. (Trace: FR-021, SC-001, SC-002, SC-010, plan.md Proof surfaces)
- [ ] T010 [P] [US1] [Owner: Quality steward] [Effort: S] Add the `bundled-boundary-advance` row to `.specrew/quality/known-traps.md` with citations to `FR-006`, `tests/integration/substantive-interaction-model-iteration2.ps1`, and the Feature 016 validator implementation files, preserving the validator-enforced status and remediation path. (Trace: FR-020, TG-004, SC-002)

**Checkpoint**: User Story 1 is complete when per-boundary authorization is enforced mechanically and replay proof exists for compliant, violating, and grandfathered cases.

---

## Phase 4: User Story 2 - Understand the substance from the console alone (Priority: P1)

**Goal**: Make boundary handoffs substantive enough that a human can understand the work, the boundary, and the required verdict without opening artifacts first.

**Independent Test**: Present a fresh-context reviewer with only the boundary handoff and confirm they can summarize what changed, why Squad stopped, and what explicit next decision is required without opening any `.md` files.

### Iteration 1 implementation slice

- [ ] T011 [P] [US2] [Owner: Governance steward] [Effort: M] Update substantive-handoff guidance in `.github/agents/squad.agent.md`, `extensions/specrew-speckit/prompts/coordinator-response.md`, `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, and `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md` with phase-specific substantive-vs-thin examples, fixed thresholds, explicit boundary naming, and explicit verdict-request wording. (Trace: FR-010, FR-014, TG-002, SC-004)
- [ ] T012 [US2] [Owner: Validator steward] [Effort: L] Implement `soft-warning.thin-what-i-just-did`, `soft-warning.unspecific-stop-boundary`, and `soft-warning.unactionable-user-request` in `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`, `extensions/specrew-speckit/scripts/validate-governance.ps1`, and `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, keeping the warnings additive and advisory only. (Trace: FR-011, FR-012, FR-013, TG-002, SC-005, NFR-005, NFR-006)
- [ ] T013 [US2] [Owner: Quality steward] [Effort: S] Perform the fresh-context handoff-only review from `specs/016-substantive-interaction-model/quickstart.md`, run `extensions/specrew-speckit/scripts/validate-governance.ps1` against the updated handoff examples, and record the console-substance evidence in `specs/016-substantive-interaction-model/quickstart.md`. (Trace: SC-004, SC-005, quickstart.md Iteration 1 Steps, plan.md manual-handoff-readability-check)

### Iteration 2 proof + sustainability slice

- [ ] T014 [P] [US2] [Owner: Quality steward] [Effort: M] Create violating and compliant substantive-handoff fixtures in `tests/unit/fixtures/016-substantive-interaction-model/console-substance/` and `tests/integration/fixtures/016-substantive-interaction-model/console-substance/`, then add assertions to `tests/unit/validate-governance.interaction-model.tests.ps1` and `tests/integration/substantive-interaction-model-iteration2.ps1` for thin summaries, unspecific boundaries, and aggregated unactionable-request omissions. (Trace: FR-021, SC-004, SC-005, SC-010)
- [ ] T015 [P] [US2] [Owner: Quality steward] [Effort: S] Add the `thin-handoff-summary` row and its historical cross-references to `.specrew/quality/known-traps.md`, citing `FR-011` through `FR-013`, `tests/unit/validate-governance.interaction-model.tests.ps1`, and the Feature 014 rows `empty-user-action-section` plus `transitional-stop-claim`. (Trace: FR-020, FR-024, TG-004)
- [ ] T016 [P] [US2] [Owner: Documentation steward] [Effort: M] Update the three-pillar lifecycle and validator-scope documentation in `README.md` and `extensions/specrew-speckit/governance/validation-lane.md` so the Recommended Lifecycle explains the 7-authorization pattern, essence-in-console expectation, click-through navigation rule, and Squad-authored-surface-only validator scope. (Trace: FR-022, TG-004, SC-004, SC-009)
- [ ] T017 [US2] [Owner: Documentation steward] [Effort: M] Update `specs/001-specrew-product/contracts/coordinator-handoff-template.md` with explicit substantive boundary-handoff examples for all 7 per-iteration boundaries, including exact boundary names, inspection targets, and verdict wording without introducing Feature 017 visual-artifact scope. (Trace: FR-023, TG-004, SC-004, SC-006)

**Checkpoint**: User Story 2 is complete when console handoffs are substantively understandable on their own, the warnings remain soft-only, and the public guidance/template surfaces reflect the new contract.

---

## Phase 5: User Story 3 - Navigate directly from handoffs into artifacts (Priority: P1)

**Goal**: Make `file:///` artifact references the default in Squad-authored narration and boundary handoffs, while keeping exempt contexts quiet and promoting boundary-handoff bare paths to hard-fail only after proof exists.

**Independent Test**: Inspect boundary handoffs and ordinary narration and confirm artifact references use `file:///` links, bare-path findings stay soft in Iteration 1, exempt contexts remain clean, and the same detector promotes to hard-fail in Iteration 2 by configuration only.

### Iteration 1 implementation slice

- [ ] T018 [P] [US3] [Owner: Governance steward] [Effort: M] Update `.github/agents/squad.agent.md`, `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`, `extensions/specrew-speckit/prompts/coordinator-response.md`, `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, and `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` so Squad uses `file:///` links in narration and boundary handoffs, preserves the approved exemption contexts, and keeps navigation validation scoped to Squad-authored outputs only. (Trace: FR-015, FR-018, FR-019, TG-003, SC-006)
- [ ] T019 [US3] [Owner: Validator steward] [Effort: L] Implement `soft-warning.bare-path-in-boundary-handoff`, `soft-warning.bare-path-in-narration`, `soft-warning.broken-file-url-reference`, approved exemption-context detection, and project-extension approval handling via `.specrew/config.yml` across `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`, `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `extensions/specrew-speckit/scripts/shared-governance.ps1`, and `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1`. (Trace: FR-016, FR-017, FR-018, FR-019, TG-003, SC-006, SC-008, NFR-003)
- [ ] T020 [US3] [Owner: Quality steward] [Effort: S] Run the Iteration 1 navigation checks from `specs/016-substantive-interaction-model/quickstart.md` against the updated handoff examples and `extensions/specrew-speckit/scripts/validate-governance.ps1`, then record the soft-warning-only bare-path evidence in `specs/016-substantive-interaction-model/quickstart.md`. (Trace: SC-006, SC-007, SC-008, quickstart.md Iteration 1 Steps, plan.md Required Quality Gates)

### Iteration 2 proof + sustainability slice

- [ ] T021 [P] [US3] [Owner: Quality steward] [Effort: M] Create violating, compliant, and exempt-context navigation fixtures in `tests/unit/fixtures/016-substantive-interaction-model/navigation/` and `tests/integration/fixtures/016-substantive-interaction-model/navigation/`, then extend `tests/unit/validate-governance.interaction-model.tests.ps1` and `tests/integration/substantive-interaction-model-iteration2.ps1` to prove bounded false positives before severity promotion. (Trace: FR-021, SC-006, SC-007, SC-008, SC-010)
- [ ] T022 [P] [US3] [Owner: Quality steward] [Effort: S] Add the `bare-path-in-handoff` row and its historical cross-reference to Feature 012's `human-handoff-id-context` in `.specrew/quality/known-traps.md`, documenting the Iteration 1 soft-warning state, the Iteration 2 hard-fail graduation, and the proving fixture paths. (Trace: FR-020, FR-024, TG-004, SC-007)
- [ ] T023 [US3] [Owner: Validator steward] [Effort: S] Promote `bare-path-in-boundary-handoff` from `soft-warning` to `validation-fail` by configuration/rule-table flip only in `extensions/specrew-speckit/scripts/validate-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` after the exemption fixtures in `tests/integration/substantive-interaction-model-iteration2.ps1` pass, without rewriting the detector logic. (Trace: FR-016, FR-021, TG-003, TG-004, SC-007)

**Checkpoint**: User Story 3 is complete when `file:///` navigation is the governed default, exempt contexts stay quiet, and the bare-path boundary rule promotes by configuration instead of detector rewrite.

---

## Phase 6: Polish & Cross-Cutting Validation

**Purpose**: Re-run the full governance lane, preserve the approved iteration split, and confirm no unauthorized iteration scaffolds were introduced.

- [ ] T024 [P] [Owner: Quality steward] [Effort: S] Add the passive `thin-artifact-content` row to `.specrew/quality/known-traps.md`, citing `FR-020`, `specs/016-substantive-interaction-model/research.md`, and `specs/016-substantive-interaction-model/data-model.md`, and document that artifact-body substantive enforcement remains out of scope for Feature 016 while preserving future graduation candidacy notes. (Trace: FR-020, TG-004)
- [ ] T025 [P] [Owner: Documentation steward] [Effort: S] Update `specs/016-substantive-interaction-model/plan.md` and `specs/016-substantive-interaction-model/quickstart.md` with the final validation commands, proof references, and the preserved Iteration 1 `~13 SP` / Iteration 2 `~9 SP` split after implementation lands. (Trace: plan.md Capacity Gate, spec.md Iteration Breakdown, TG-005)
- [ ] T026 [P] [Owner: Quality steward] [Effort: M] Run the full Feature 016 closeout lane using `tests/integration/substantive-interaction-model-iteration2.ps1`, `tests/unit/validate-governance.interaction-model.tests.ps1`, `tests/integration/handoff-governance-jargon-response-test.ps1`, `tests/integration/handoff-governance-plain-language-response-test.ps1`, `tests/integration/handoff-governance-review-file-reference-test.ps1`, `tests/integration/handoff-governance-descriptive-narration-test.ps1`, `tests/integration/handoff-governance-descriptive-stop-message-test.ps1`, and `extensions/specrew-speckit/scripts/validate-governance.ps1`, then audit the final diff across the touched prompt, validator, corpus, README, and template paths. (Trace: TG-004, TG-005, TG-006, SC-001, SC-002, SC-004, SC-005, SC-006, SC-007, SC-008, SC-010)
- [ ] T027 [Owner: Iteration facilitator] [Effort: S] Reconcile `specs/016-substantive-interaction-model/tasks.md`, `specs/016-substantive-interaction-model/spec.md`, and the final touched implementation surfaces, and confirm the feature completed without creating `specs/016-substantive-interaction-model/iterations/` scaffolds. (Trace: TG-005, TG-006, spec.md Governance Alignment, quickstart.md Scope Reminder)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup** -> starts immediately.
- **Phase 2: Foundational** -> depends on T001-T002 and blocks all user-story work.
- **Phase 3: US1** -> depends on T003-T004.
- **Phase 4: US2** -> depends on T003-T004 and can proceed in parallel with US1 after the foundation lands.
- **Phase 5: US3** -> depends on T003-T004 and can proceed in parallel with US1/US2 after the foundation lands.
- **Phase 6: Polish** -> depends on T009-T023 and the story-level validation tasks T008, T013, and T020.

### Dependency Graph

```text
T001-T002
  -> T003-T004
    -> { T005-T008, T011-T013, T018-T020 }
      -> { T009-T010, T014-T017, T021-T023 }
        -> T024-T027

Additional edge:
- T023 depends on T019 and T021 so the severity flip happens only after detector + exemption proof are stable.
```

### User Story Dependencies

- **US1 (P1)**: First MVP slice after the foundational phase; no dependency on other user stories.
- **US2 (P1)**: Independent after the foundational phase; shares prompt surfaces with US1 but remains independently testable via handoff-only review and warning fixtures.
- **US3 (P1)**: Independent after the foundational phase; its hard-fail promotion depends only on its own navigation fixtures, not on US1 or US2 completion.

### Iteration Capacity Guardrails

- **Iteration 1 (~13 SP)**: T004-T008, T011-T013, and T018-T020. Scope is limited to coordinator prompt updates, bundled-boundary hard fail, canonical authorization-record shape, Pillar 2 soft rules, and the Iteration 1 soft-warning form of bare-path-in-boundary-handoff.
- **Iteration 2 (~9 SP)**: T009-T010, T014-T017, T021-T024, and T023. Scope is limited to violating/compliant fixtures, the three active corpus rows plus passive `thin-artifact-content`, README lifecycle + validator-doc updates, the per-feature handoff-template update, and the bare-path hard-fail promotion by config flip.
- **Setup/Foundation/Polish support**: T001-T003 and T025-T027 support execution and closeout but do not authorize additional feature scope beyond the approved two-iteration split.

### Within Each User Story

- Complete the Iteration 1 slice before starting that story's Iteration 2 proof/doc/corpus follow-through.
- Land validator/helper changes before story-level replay or reviewer evidence tasks.
- Do not promote `bare-path-in-boundary-handoff` to hard-fail before T021 proves bounded false positives.
- Keep all work inside existing prompt, validator, docs, corpus, and replay surfaces; do not create `specs/016-substantive-interaction-model/iterations/` artifacts.

### Parallel Opportunities

- **Foundation**: T003 can run in parallel with T004.
- **US1**: T009 and T010 can run in parallel after T007-T008 stabilize the rule IDs and proof surface.
- **US2**: T011 and T012 can run in parallel after Phase 2; T014, T015, and T016 can run in parallel after T012 stabilizes the warning IDs.
- **US3**: T018 and T019 can run in parallel after Phase 2; T021 and T022 can run in parallel after T019 stabilizes the detector contract.
- **Polish**: T024-T026 can run in parallel; T027 closes after they finish.

## Parallel Example: User Story 1

```text
Task: "T009 Create violating and compliant boundary-discipline fixtures in tests/integration/fixtures/016-substantive-interaction-model/boundary-discipline/ and extend tests/integration/substantive-interaction-model-iteration2.ps1"
Task: "T010 Add the bundled-boundary-advance row to .specrew/quality/known-traps.md"
```

## Parallel Example: User Story 2

```text
Task: "T011 Update substantive-handoff guidance in .github/agents/squad.agent.md, extensions/specrew-speckit/prompts/coordinator-response.md, extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md, .specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md, and extensions/specrew-speckit/checklists/coordinator-handoff-governance.md"
Task: "T012 Implement thin-what-i-just-did, unspecific-stop-boundary, and unactionable-user-request in extensions/specrew-speckit/validators/handoff-governance-validator.ps1 and the validate-governance entrypoints"
```

## Parallel Example: User Story 3

```text
Task: "T021 Create violating, compliant, and exempt-context navigation fixtures in tests/unit/fixtures/016-substantive-interaction-model/navigation/ and tests/integration/fixtures/016-substantive-interaction-model/navigation/, then extend tests/unit/validate-governance.interaction-model.tests.ps1 and tests/integration/substantive-interaction-model-iteration2.ps1"
Task: "T022 Add the bare-path-in-handoff row and historical cross-reference to .specrew/quality/known-traps.md"
```

---

## Traceability Map

- **US1 -> FR-001 through FR-009 / TG-001**: Covered by T005-T010.
- **US2 -> FR-010 through FR-014 / TG-002**: Covered by T011-T017.
- **US3 -> FR-015 through FR-019 / TG-003**: Covered by T018-T023.
- **Cross-cutting sustainability -> FR-020 through FR-024 / TG-004**: Covered by T009-T010, T014-T017, T021-T024, and T025-T027.
- **Spec authority and scope boundary -> TG-005 and TG-006**: Preserved by T001-T004, T025-T027.

---

## Implementation Strategy

### MVP First

1. Complete T001-T004 to lock the baseline and shared helper/contract foundation.
2. Deliver **US1 Iteration 1** (T005-T008) as the MVP slice.
3. Stop and validate the per-boundary authorization behavior before broadening to the other pillars.

### Incremental Delivery

1. Finish Setup + Foundational (T001-T004).
2. Deliver **Iteration 1 / US1** -> validate.
3. Deliver **Iteration 1 / US2** -> validate.
4. Deliver **Iteration 1 / US3** -> validate.
5. Deliver **Iteration 2 proof/doc/corpus follow-through** for US1, US2, and US3 in that order or in parallel by staffing.
6. Run T024-T027 as the final closeout lane.

### Explicit Scope Guardrails

- Do not add Feature 017 visual-artifact work.
- Do not rewrite the bare-path detector between Iteration 1 and Iteration 2.
- Do not promote Pillar 2 rules beyond soft warnings in Feature 016.
- Do not scaffold `specs/016-substantive-interaction-model/iterations/` artifacts in this backlog.

---

## Notes

- All checklist items use unchecked checkboxes and the required `T###`, `[Owner: ...]`, `[Effort: ...]`, exact-path, and `(Trace: ...)` metadata.
- User stories remain independently testable through their explicit independent-test criteria and story-level evidence tasks.
- The backlog preserves the approved split: Iteration 1 delivers the coordinator/validator semantics; Iteration 2 delivers fixtures, corpus/docs/template follow-through, and the bare-path config flip.

# Tasks: Public-Readiness Pass

**Input**: Design documents from `specs/015-public-readiness-pass/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/public-readiness-warning-schema.md`  
**Authority**: `specs/015-public-readiness-pass/spec.md` and `specs/015-public-readiness-pass/plan.md` are authoritative for this backlog; the repaired feature branch is `015-public-readiness-pass`.  
**Scope Boundary**: Keep the backlog decomposed across the approved two-iteration split. Include the planning-boundary work required to scaffold Iteration 001, but do **not** create `specs/015-public-readiness-pass/iterations/001/review.md` or `specs/015-public-readiness-pass/iterations/001/retro.md` placeholders during planning.

**Tests**: Manual reviewer checks are required for User Story 1, and PowerShell/Pester coverage is required for the public-readiness validator work in User Story 2 per `plan.md`.

## Format: `- [ ] T### [P?] [US#?] [Owner: ...] [Effort: ...] Description with exact file path(s) (Trace: ...)`

- **[P]**: Task can run in parallel once dependencies are satisfied
- **[US#]**: Present only for user-story work (`[US1]`, `[US2]`, `[US3]`)
- **[Owner]**: Primary owner role aligned to `spec.md`
- **[Effort]**: Relative effort estimate (`S`, `M`, `L`)
- Every task includes exact file path(s) and explicit traceability references

---

## Phase 1: Setup

**Purpose**: Lock the repaired authority boundary and scaffold only the approved Iteration 001 planning surface.

- [ ] T001 [Owner: Planner] [Effort: S] Reconfirm the repaired branch name, the two-iteration split, and the FR-015 approval boundary in `specs/015-public-readiness-pass/spec.md` and `specs/015-public-readiness-pass/plan.md`. (Trace: FR-015, TG-004, plan.md Summary, plan.md Capacity Gate)
- [ ] T002 [Owner: Planner] [Effort: S] Run `extensions/specrew-speckit/scripts/scaffold-iteration-plan.ps1` to create or refresh `specs/015-public-readiness-pass/iterations/001/plan.md` only, and leave `specs/015-public-readiness-pass/iterations/001/review.md` plus `specs/015-public-readiness-pass/iterations/001/retro.md` uncreated during planning. (Trace: FR-015, TG-004, spec.md Out of Scope, spec.md Governance Alignment, plan.md Phase 1 Quality Planning)

---

## Phase 2: Foundational

**Purpose**: Establish the shared release-truth and iteration boundaries that every user story depends on.

**⚠️ CRITICAL**: No user-story work should begin until the canonical version source and iteration split are explicitly locked.

- [ ] T003 [Owner: Release steward] [Effort: S] Confirm `.specrew/config.yml` as the canonical version source and reconcile the shared implementation surface in `specs/015-public-readiness-pass/plan.md` and `specs/015-public-readiness-pass/contracts/public-readiness-warning-schema.md`. (Trace: FR-008, FR-014, FR-016, TG-002, plan.md Summary)
- [ ] T004 [Owner: Planner] [Effort: S] Record the Iteration 001 versus Iteration 002 execution split in `specs/015-public-readiness-pass/iterations/001/plan.md` so licensing/README/product-status work stays separate from versioning/changelog/tags/governance-extension work. (Trace: FR-015, TG-004, spec.md Governance Alignment, plan.md Capacity Gate)

**Checkpoint**: The repaired planning boundary is locked and the canonical release-truth surfaces are identified.

---

## Phase 3: Iteration 001 - User Story 1 - Understand the repo at a glance (Priority: P1) 🎯 MVP

**Goal**: Give a first-time public observer accurate top-level licensing, attribution, status, and README guidance without insider explanation.

**Independent Test**: Give a fresh-context reviewer `README.md`, `LICENSE`, and `NOTICE.md`, then confirm they can explain Specrew's alpha state, version, working scope, known gaps, and legal reuse posture within 60 seconds.

### Implementation for User Story 1

- [ ] T005 [P] [US1] [Owner: Repository steward] [Effort: S] Create the MIT license text in `LICENSE` with the required copyright line `Copyright (c) 2026 Alon Fliess and contributors`. (Trace: FR-001, TG-001, SC-002)
- [ ] T006 [P] [US1] [Owner: Repository steward] [Effort: M] Author top-level upstream attribution in `NOTICE.md` for Squad and Spec Kit, explicitly naming derived directories `.specify/`, `.specify/extensions/specrew-speckit/squad-templates/`, and `extensions/specrew-speckit/`. (Trace: FR-002, TG-001, SC-002)
- [ ] T007 [US1] [Owner: Documentation steward] [Effort: L] Rewrite `README.md` to add **Current State**, **What's working**, **What's NOT working yet**, **Recommended Lifecycle**, **PR-at-feature-close Workflow**, **Roadmap**, **License**, and **Contributing** sections with the approved alpha-only external contribution posture. (Trace: FR-003, FR-004, FR-005, FR-006, FR-007, NFR-001, NFR-002, TG-001, SC-001)
- [ ] T008 [US1] [Owner: Product spec steward] [Effort: S] Update `specs/001-specrew-product/spec.md` from draft status to `Active 0.14.0` and add the brief note that 14 implementing features now back the product vision. (Trace: FR-011, TG-001, TG-002, SC-003)
- [ ] T009 [US1] [Owner: human reviewer] [Effort: M] Run the first-time-reader review plus markdown lint for `LICENSE`, `NOTICE.md`, `README.md`, and `specs/001-specrew-product/spec.md`, then record the Iteration 001 evidence in `specs/015-public-readiness-pass/quickstart.md`. (Trace: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-011, SC-001, SC-002)

**Checkpoint**: User Story 1 is complete when the repo landing surfaces accurately communicate public-readiness status and legal reuse posture.

---

## Phase 4: Iteration 002 - User Story 2 - Reconcile release truth across repo artifacts (Priority: P1)

**Goal**: Make the declared version, versioning policy, changelog, tags, product status, and validator warnings tell one coherent release story.

**Independent Test**: Review `.specrew/config.yml`, `README.md`, `docs/versioning.md`, `CHANGELOG.md`, `specs/001-specrew-product/spec.md`, and the `v0.13.0` / `v0.14.0` tags together, then confirm they all represent the 14-feature `0.14.0` baseline with additive public-readiness drift warnings.

### Tests for User Story 2

- [ ] T010 [P] [US2] [Owner: Governance steward] [Effort: M] Create clean and drifted validator fixtures in `tests/unit/fixtures/015-public-readiness-pass/public-readiness-clean/` and `tests/unit/fixtures/015-public-readiness-pass/public-readiness-drift/` covering missing `LICENSE`, `NOTICE.md`, `CHANGELOG.md`, `docs/versioning.md`, and stale `README.md` scenarios. (Trace: FR-016, TG-002, SC-007, contracts/public-readiness-warning-schema.md)
- [ ] T011 [P] [US2] [Owner: Governance steward] [Effort: M] Add Pester coverage for `Test-PublicReadinessSurfaces` in `tests/unit/validate-governance.public-readiness.tests.ps1` so warning categories stay additive and never promote soft drift into a hard failure. (Trace: FR-016, NFR-005, TG-002, SC-007, plan.md Testing)

### Implementation for User Story 2

- [ ] T012 [US2] [Owner: Release steward] [Effort: S] Update `.specrew/config.yml` from `specrew_version: "0.1.0-dev"` to `specrew_version: "0.14.0"` as the canonical active-version declaration. (Trace: FR-008, TG-002, SC-003)
- [ ] T013 [US2] [Owner: Documentation steward] [Effort: S] Add the concise version summary and `docs/versioning.md` reference to `README.md` so the landing page mirrors `.specrew/config.yml` without becoming a long-form manual. (Trace: FR-008, FR-014, NFR-001, NFR-004, TG-002)
- [ ] T014 [P] [US2] [Owner: Documentation steward] [Effort: M] Author the detailed alpha versioning policy in `docs/versioning.md`, including the `0.NN.0` feature-release rule and the `0.NN.M` hotfix rule. (Trace: FR-014, FR-008, TG-002, SC-003)
- [ ] T015 [P] [US2] [Owner: Release steward] [Effort: M] Create retroactive release entries for Features 001 through 014 in `CHANGELOG.md`, including feature ordinal, one-line summary, and historical commit or merge references where known. (Trace: FR-009, TG-002, SC-003, SC-004)
- [ ] T016 [US2] [Owner: Governance steward] [Effort: M] Implement `Test-PublicReadinessSurfaces` in `extensions/specrew-speckit/scripts/validate-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` so every validator run emits additive `WARN [public-readiness]` lines for missing or stale surfaces without changing hard-fail behavior. (Trace: FR-016, NFR-003, NFR-005, TG-002, contracts/public-readiness-warning-schema.md)
- [ ] T017 [US2] [Owner: Release steward] [Effort: S] Create annotated repository tags `v0.13.0` and `v0.14.0` from the release anchors documented in `CHANGELOG.md` and `.specrew/config.yml`, then verify the targets against commits `21d9e7f` and `3ff32d4`. (Trace: FR-010, TG-002, SC-003, SC-004)
- [ ] T018 [US2] [Owner: human reviewer] [Effort: M] Run `tests/unit/validate-governance.public-readiness.tests.ps1`, `Invoke-ScriptAnalyzer` for `extensions/specrew-speckit/scripts/validate-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `extensions/specrew-speckit/scripts/validate-governance.ps1`, and `git tag -l "v0.13.0" "v0.14.0"`, then record the aligned release-truth evidence in `specs/015-public-readiness-pass/quickstart.md`. (Trace: FR-008, FR-009, FR-010, FR-014, FR-016, TG-002, SC-003, SC-004, SC-007)

**Checkpoint**: User Story 2 is complete when version, changelog, tags, product status, and validator output all align to the same 0.14.0 shipped baseline.

---

## Phase 5: Iteration 002 - User Story 3 - Close future features with release discipline (Priority: P2)

**Goal**: Make version bumping, changelog updates, release tagging, and post-tag validation part of future closeout by default.

**Independent Test**: Review the coordinator governance guidance and confirm the next real feature closeout would have to update version, changelog, and release tags without a fresh human reminder or a synthetic proving feature.

### Implementation for User Story 3

- [ ] T019 [US3] [Owner: Governance steward] [Effort: M] Add a `Feature Closeout Version Management` section to `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` and `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` covering version bump, changelog update, release-tag creation, README version refresh, and post-tag validation. (Trace: FR-012, FR-013, FR-016, TG-003, SC-005)
- [ ] T020 [US3] [Owner: Governance steward] [Effort: S] Update `specs/015-public-readiness-pass/quickstart.md` to record that closeout-version-management proof is deferred to the next real feature closeout rather than a synthetic proving feature. (Trace: FR-012, FR-013, TG-003, SC-005, spec.md Clarifications, spec.md User Story 3 Acceptance Scenarios)
- [ ] T021 [US3] [Owner: human reviewer] [Effort: S] Review `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, and `specs/015-public-readiness-pass/quickstart.md` to confirm future closeouts now require synchronized release bookkeeping. (Trace: FR-012, FR-013, TG-003, SC-005)

**Checkpoint**: User Story 3 is complete when future closeout guidance mechanically carries release-discipline expectations forward.

---

## Phase 6: Polish & Cross-Cutting Validation

**Purpose**: Re-run the shared quality gates, confirm additive validator behavior, and preserve the approval boundary after story work lands.

- [ ] T022 [P] [Owner: Documentation steward] [Effort: S] Run markdown lint across `README.md`, `NOTICE.md`, `CHANGELOG.md`, `docs/versioning.md`, and `specs/001-specrew-product/spec.md`, then resolve any remaining public-facing wording drift in those files. (Trace: NFR-001, NFR-002, plan.md Required Quality Gates)
- [ ] T023 [P] [Owner: human reviewer] [Effort: S] Run `extensions/specrew-speckit/scripts/validate-governance.ps1` against a clean repo and the drift fixtures in `tests/unit/fixtures/015-public-readiness-pass/public-readiness-drift/`, then confirm public-readiness warnings remain advisory in `specs/015-public-readiness-pass/quickstart.md`. (Trace: FR-016, NFR-005, SC-007, plan.md Required Quality Gates)
- [ ] T024 [Owner: Planner] [Effort: S] Reconcile `specs/015-public-readiness-pass/plan.md`, `specs/015-public-readiness-pass/quickstart.md`, and `specs/015-public-readiness-pass/tasks.md` with the final two-iteration execution order while preserving the explicit deferral of hardening-gate sign-off and implementation authorization. (Trace: FR-015, TG-004, spec.md Governance Alignment, plan.md Explicit Later Deferrals)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup** → starts immediately.
- **Phase 2: Foundational** → depends on T001-T002 and blocks all user-story work.
- **Phase 3: Iteration 001 / US1** → depends on T001-T004.
- **Phase 4: Iteration 002 / US2** → depends on T001-T004 and on US1 landing the product-status update plus public README baseline.
- **Phase 5: Iteration 002 / US3** → depends on US2 so release-version management language matches the settled versioning and validator workflow.
- **Phase 6: Polish** → depends on T005-T021.

### User Story Dependencies

- **US1 (P1)**: First MVP slice after setup/foundational work; no dependency on other user stories.
- **US2 (P1)**: Depends on the shared release-truth boundary from Phase 2 and on the product-status baseline from US1.
- **US3 (P2)**: Depends on US2 so closeout guidance references the final release/version workflow rather than placeholders.

### Iteration Dependencies

- **Iteration 001** = T001-T009. This is the only slice with planning-boundary scaffolding work.
- **Iteration 002** = T010-T024. This slice executes only after explicit later human authorization.

### Within Each User Story

- Create test fixtures and Pester coverage before editing validator code for US2.
- Update canonical version and versioning docs before creating retroactive tags.
- Finish story-level validation before moving to Phase 6 cross-cutting checks.

---

## Parallel Opportunities

- **Setup/Foundation**: No safe parallelism; these tasks lock the repaired authority and iteration boundary.
- **US1**: T005 and T006 can run in parallel; T007 follows after those landing files exist; T008 can run in parallel with T007; T009 follows all US1 edits.
- **US2**: T010 and T011 can run in parallel; T014 and T015 can run in parallel after T012-T013 establish the canonical version story; T016 follows the test scaffolding; T017-T018 follow changelog/version completion.
- **US3**: T019 can begin after US2; T020 can run in parallel with the governance template edit; T021 follows both.
- **Polish**: T022 and T023 can run in parallel; T024 closes after both validation lanes finish.

## Parallel Example: User Story 1

```text
Task: "T005 Create the MIT license text in LICENSE"
Task: "T006 Author top-level upstream attribution in NOTICE.md"
Task: "T008 Update specs/001-specrew-product/spec.md to Active 0.14.0"
```

## Parallel Example: User Story 2

```text
Task: "T010 Create clean and drifted validator fixtures in tests/unit/fixtures/015-public-readiness-pass/public-readiness-clean/ and tests/unit/fixtures/015-public-readiness-pass/public-readiness-drift/"
Task: "T011 Add Pester coverage in tests/unit/validate-governance.public-readiness.tests.ps1"
Task: "T014 Author the detailed alpha versioning policy in docs/versioning.md"
Task: "T015 Create retroactive release entries in CHANGELOG.md"
```

## Parallel Example: User Story 3

```text
Task: "T019 Add Feature Closeout Version Management to extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md and .specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md"
Task: "T020 Update specs/015-public-readiness-pass/quickstart.md with the next-real-feature proof note"
```

---

## Traceability Map

- **US1 → FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-011**: Covered by T005-T009.
- **US2 → FR-008, FR-009, FR-010, FR-011, FR-014, FR-016**: Covered by T010-T018, with FR-011 alignment inherited from T008 and verified in US2 validation.
- **US3 → FR-012, FR-013, FR-016**: Covered by T019-T021.
- **Planning boundary / TG-004**: Covered by T001-T004 and T024.

---

## Implementation Strategy

### MVP First

1. Complete T001-T004 to lock the repaired planning boundary.
2. Deliver **US1** (T005-T009) as the MVP public-readiness slice.
3. Stop and validate the first-time-reader outcome before authorizing Iteration 002 work.

### Incremental Delivery

1. **Iteration 001**: T001-T009 for planning-boundary scaffolding plus public landing-surface accuracy.
2. **Iteration 002 / Release truth**: T010-T018 for versioning, changelog, tags, and validator coverage.
3. **Iteration 002 / Future closeout discipline**: T019-T021 for governance-template carry-forward.
4. **Closeout validation**: T022-T024 after all desired story work completes.

### Explicit Authorization Boundary

- Only the planning-boundary scaffolding in T001-T004 is authorized immediately by FR-015.
- T005-T024 remain sequenced here for execution after later explicit human approval.
- Do not create `specs/015-public-readiness-pass/iterations/001/review.md` or `specs/015-public-readiness-pass/iterations/001/retro.md` as part of planning-boundary work.

---

## Notes

- All checklist items use the required `- [ ] T### [P?] [US#?] [Owner: ...] [Effort: ...] ... (Trace: ...)` format.
- User stories remain independently testable: US1 via fresh-context review, US2 via version/tag/validator alignment, and US3 via governance-guidance inspection.
- The backlog follows the authoritative repaired branch and scope from `spec.md` and `plan.md`, not the older branch identifier present in non-authoritative design artifacts.

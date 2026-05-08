# Tasks: Stack-Aware Quality Bar (Phase 2 / Deferred Quality Gates)

**Input**: Design documents from `C:\Dev\Specrew\specs\005-stack-aware-quality-bar\`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/`  
**Tests**: Deterministic integration coverage is required for this slice because `plan.md` and `quickstart.md` require explicit verification for hardening-gate behavior, bug-hunter lens execution, strongest-class routing, and known-traps governance.  
**Scope Boundary**: This task list covers only FR-031–FR-033, FR-016–FR-019a, FR-034–FR-040. It excludes FR-041–FR-046, FR-013–FR-015, mixed-stack expansion, reference-baseline comparison, and any other work explicitly deferred in `C:\Dev\Specrew\specs\005-stack-aware-quality-bar\plan.md`.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Publish the bounded Phase 2 configuration and fixture surfaces that every later task depends on.

- [ ] T001 Extend downstream Phase 2 quality defaults in `extensions/specrew-speckit/scripts/scaffold-governance.ps1`, `extensions/specrew-speckit/templates/iteration-config.yml`, and `.specrew/iteration-config.yml`
- [ ] T002 [P] Seed `quality.known_traps_path` and `quality.routing` defaults in `.specrew/config.yml`, `tests/integration/fixtures/quality-evidence-governance/complete-evidence/project/.specrew/config.yml`, and `tests/integration/fixtures/quality-evidence-governance/missing-evidence/project/.specrew/config.yml`
- [ ] T003 [P] Add agent `strength_rank` fixture coverage in `tests/integration/fixtures/quality-evidence-governance/complete-evidence/project/.specrew/iteration-config.yml` and `tests/integration/fixtures/quality-evidence-governance/missing-evidence/project/.specrew/iteration-config.yml`
- [ ] T004 [P] Create Phase 2 fixture roots in `tests/integration/fixtures/hardening-gate-contract/`, `tests/integration/fixtures/bug-hunter-lens-execution/`, `tests/integration/fixtures/strongest-class-routing/`, and `tests/integration/fixtures/known-traps-corpus/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add the shared artifact scaffolding and guidance required before any Phase 2 user story can be implemented.

**⚠️ CRITICAL**: No user story work should start until this phase is complete.

- [ ] T005 Extend `extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1` and `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1` to scaffold `hardening-gate.md`, `quality/lenses/`, and `trap-reapplication.md`
- [ ] T006 [P] Add Phase 2 parsing and approval helpers in `extensions/specrew-speckit/scripts/shared-governance.ps1`
- [ ] T007 [P] Update Phase 2 lifecycle guidance in `extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md`, `extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md`, and `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`
- [ ] T008 [P] Extend Phase 2 plan rendering in `.specify/templates/plan-template.md` for hardening focus areas, lens activation, routing policy, known-traps location, and explicit Phase 3/4 deferrals

**Checkpoint**: Phase 2 scaffolding, planning guidance, and shared helpers are ready for user-story implementation.

---

## Phase 3: User Story 2 - Make quality gates explicit and reviewable across the lifecycle (Priority: P1) 🎯 MVP for this Phase 2 slice

**Goal**: Make pre-implementation hardening explicit, reviewable, and blocking before implementation begins.

**Independent Test**: Run `tests/integration/hardening-gate-contract.ps1` and `tests/integration/quality-evidence-governance.ps1` to confirm `extensions/specrew-speckit/scripts/validate-governance.ps1` blocks unresolved critical `tbd` concerns and only allows explicit human-approved deferrals.

### Tests for User Story 2

- [ ] T009 [P] [US2] Add hardening gate fixtures in `tests/integration/fixtures/hardening-gate-contract/blocked/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md`, `tests/integration/fixtures/hardening-gate-contract/approved-deferral/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md`, and `tests/integration/fixtures/hardening-gate-contract/ready/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md`
- [ ] T010 [P] [US2] Add governance fixtures for hardening readiness in `tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/project/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md` and `tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md`
- [ ] T011 [US2] Add deterministic hardening-gate contract coverage in `tests/integration/hardening-gate-contract.ps1`

### Implementation for User Story 2

- [ ] T012 [P] [US2] Implement pre-implementation hardening orchestration in `extensions/specrew-speckit/scripts/run-hardening-gate.ps1`
- [ ] T013 [P] [US2] Extend Phase 2 hardening planning data in `extensions/specrew-speckit/scripts/resolve-quality-profile.ps1` and `.specify/templates/plan-template.md`
- [ ] T014 [US2] Enforce hardening-gate blocking semantics and human deferral approval in `extensions/specrew-speckit/scripts/validate-governance.ps1`

**Checkpoint**: User Story 2 is complete when hardening review evidence is generated, hardening expectations are visible in planning artifacts, and unresolved critical concerns block implementation readiness.

---

## Phase 4: User Story 3 - Activate dedicated specialist bug-hunter review when defect classes demand it (Priority: P2)

**Goal**: Add versioned specialist bug-hunter lenses, mechanical-first execution, and known-traps follow-through without implying deferred Phase 3/4 behavior.

**Independent Test**: Run `tests/integration/bug-hunter-lens-execution.ps1` and `tests/integration/known-traps-corpus.ps1`, then confirm `extensions/specrew-speckit/scripts/validate-governance.ps1` fails when required lens evidence is missing, row-level execution is skipped, mechanical findings are absent, or trap artifacts are not reviewable.

### Tests for User Story 3

- [ ] T015 [P] [US3] Add required-lens and missing-mechanical fixtures in `tests/integration/fixtures/bug-hunter-lens-execution/required-lenses/specs/005-quality-evidence/iterations/001/quality/lenses/` and `tests/integration/fixtures/bug-hunter-lens-execution/missing-mechanical/specs/005-quality-evidence/iterations/001/quality/`
- [ ] T016 [P] [US3] Add seeded corpus and trap reapplication fixtures in `tests/integration/fixtures/known-traps-corpus/seeded/project/.specrew/quality/known-traps.md` and `tests/integration/fixtures/known-traps-corpus/seeded/project/specs/005-quality-evidence/iterations/001/quality/trap-reapplication.md`
- [ ] T017 [US3] Add deterministic bug-hunter lens execution coverage in `tests/integration/bug-hunter-lens-execution.ps1`
- [ ] T018 [US3] Add deterministic known-traps corpus coverage in `tests/integration/known-traps-corpus.ps1`

### Implementation for User Story 3

- [ ] T019 [P] [US3] Author required Phase 2 lens checklists in `extensions/specrew-speckit/templates/quality/lenses/security-issues-v1.md`, `extensions/specrew-speckit/templates/quality/lenses/error-handling-failure-semantics-v1.md`, `extensions/specrew-speckit/templates/quality/lenses/configuration-secret-handling-v1.md`, and `extensions/specrew-speckit/templates/quality/lenses/state-transition-correctness-v1.md`
- [ ] T020 [P] [US3] Author optional and explicitly not-applicable support lenses in `extensions/specrew-speckit/templates/quality/lenses/idempotency-retry-safety-v1.md`, `extensions/specrew-speckit/templates/quality/lenses/concurrency-race-risk-v1.md`, `extensions/specrew-speckit/templates/quality/lenses/dependency-package-health-v1.md`, and `extensions/specrew-speckit/templates/quality/lenses/algorithmic-complexity-performance-path-traps-v1.md`
- [ ] T021 [US3] Extend lens activation planning in `extensions/specrew-speckit/scripts/resolve-quality-profile.ps1` and `.specify/templates/plan-template.md`
- [ ] T022 [US3] Implement mechanical-first lens execution and row-level artifact publishing in `extensions/specrew-speckit/scripts/run-bug-hunter-lenses.ps1`
- [ ] T023 [US3] Implement known-traps corpus seeding and approved additions in `extensions/specrew-speckit/scripts/apply-known-traps.ps1` and `extensions/specrew-speckit/scripts/scaffold-governance.ps1`
- [ ] T024 [US3] Implement trap reapplication recording in `extensions/specrew-speckit/scripts/apply-known-traps.ps1` and `extensions/specrew-speckit/scripts/validate-governance.ps1`

**Checkpoint**: User Story 3 is complete when required lenses execute only after deterministic findings exist, row-level lens evidence is published, and the known-traps corpus plus trap reapplication artifacts are enforced.

---

## Phase 5: User Story 4 - Handle overrides, mixed stacks, and impractical tooling safely (Priority: P2)

**Goal**: For this Phase 2 slice only, make strongest-available routing and approved lower-tier overrides explicit and reviewable for hardening and bug-hunter review.

**Independent Test**: Run `tests/integration/strongest-class-routing.ps1` and confirm required hardening/lens review uses the strongest available ranked agent by default, while any lower-tier override must carry approval, justification, and requested/effective class evidence.

### Tests for User Story 4

- [ ] T025 [P] [US4] Add strongest-class routing fixtures in `tests/integration/fixtures/strongest-class-routing/available-strongest/project/.specrew/iteration-config.yml`, `tests/integration/fixtures/strongest-class-routing/missing-rank/project/.specrew/iteration-config.yml`, and `tests/integration/fixtures/strongest-class-routing/approved-lower-tier/project/specs/005-routing/iterations/001/quality/lenses/security-issues.md`
- [ ] T026 [US4] Add deterministic strongest-class routing coverage in `tests/integration/strongest-class-routing.ps1`

### Implementation for User Story 4

- [ ] T027 [US4] Implement strongest-available routing resolution in `extensions/specrew-speckit/scripts/resolve-strongest-available-routing.ps1`
- [ ] T028 [US4] Integrate requested/effective class recording and override references in `extensions/specrew-speckit/scripts/run-hardening-gate.ps1` and `extensions/specrew-speckit/scripts/run-bug-hunter-lenses.ps1`
- [ ] T029 [US4] Enforce routing approval and evidence rules in `extensions/specrew-speckit/scripts/validate-governance.ps1` and `extensions/specrew-speckit/scripts/shared-governance.ps1`

**Checkpoint**: User Story 4 is complete when routing defaults are explicit, strongest-available selection is reproducible from config, and lower-tier overrides cannot pass without approval and justification.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finalize documentation, reporting, and shipped-extension sync for the Phase 2 slice without expanding into deferred work.

- [ ] T030 [P] Update Phase 2 operator guidance in `C:\Dev\Specrew\specs\005-stack-aware-quality-bar\quickstart.md` and `extensions/specrew-speckit/templates/quality/README.md`
- [ ] T031 [P] Extend shared regression and reporting coverage in `tests/integration/quality-evidence-governance.ps1`, `tests/integration/process-quality-scorer.ps1`, and `tests/integration/process-quality-report.ps1`
- [ ] T032 Update shipped extension mirrors with `extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1` for `.specify/extensions/specrew-speckit/` and `.specify/templates/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; start immediately.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user stories.
- **User Story 2 (Phase 3)**: Depends on Foundational.
- **User Story 3 (Phase 4)**: Depends on Foundational and should follow the hardening-gate contract from User Story 2 before full governance validation.
- **User Story 4 (Phase 5)**: Depends on Foundational and the lens/hardening artifact shapes established by User Stories 2 and 3.
- **Polish (Phase 6)**: Depends on all desired user stories being complete.

### User Story Dependencies

- **US2**: First deliverable for the scoped Phase 2 slice; no dependency on other user stories.
- **US3**: Depends on the shared scaffolding and should consume the hardening-ready lifecycle surfaces introduced for US2.
- **US4**: Depends on the hardening and lens orchestration surfaces because routing evidence must be recorded where those flows execute.

### Within Each User Story

- Tests and fixtures must be written before the corresponding implementation tasks.
- Plan rendering must be updated before governance validation depends on new fields.
- Lens catalog authoring must complete before lens execution orchestration consumes those files.
- Mechanical-first ordering must be enforced before routing and governance checks are finalized.
- Known-traps promotion and trap reapplication follow confirmed lens execution behavior.

---

## Parallel Opportunities

- `T002`, `T003`, and `T004` can run in parallel after `T001`.
- `T006`, `T007`, and `T008` can run in parallel after `T005`.
- `T009` and `T010` can run in parallel before `T011`.
- `T012` and `T013` can run in parallel before `T014`.
- `T015` and `T016` can run in parallel before `T017` and `T018`.
- `T019` and `T020` can run in parallel before `T021` and `T022`.
- `T025` can run before `T026`, while `T027` can begin once Phase 2 config scaffolding is stable.
- `T030` and `T031` can run in parallel after US2-US4 are complete.

---

## Parallel Example: User Story 2

```text
Task: "T009 [US2] Add hardening gate fixtures in tests/integration/fixtures/hardening-gate-contract/blocked/.../hardening-gate.md, approved-deferral/.../hardening-gate.md, and ready/.../hardening-gate.md"
Task: "T010 [US2] Add governance fixtures for hardening readiness in tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/.../hardening-gate.md and hardening-gate-approved/.../hardening-gate.md"
Task: "T012 [US2] Implement pre-implementation hardening orchestration in extensions/specrew-speckit/scripts/run-hardening-gate.ps1"
Task: "T013 [US2] Extend Phase 2 hardening planning data in extensions/specrew-speckit/scripts/resolve-quality-profile.ps1 and .specify/templates/plan-template.md"
```

---

## Parallel Example: User Story 3

```text
Task: "T019 [US3] Author required Phase 2 lens checklists in extensions/specrew-speckit/templates/quality/lenses/security-issues-v1.md, error-handling-failure-semantics-v1.md, configuration-secret-handling-v1.md, and state-transition-correctness-v1.md"
Task: "T020 [US3] Author optional and explicitly not-applicable support lenses in extensions/specrew-speckit/templates/quality/lenses/idempotency-retry-safety-v1.md, concurrency-race-risk-v1.md, dependency-package-health-v1.md, and algorithmic-complexity-performance-path-traps-v1.md"
Task: "T015 [US3] Add required-lens and missing-mechanical fixtures in tests/integration/fixtures/bug-hunter-lens-execution/required-lenses/... and tests/integration/fixtures/bug-hunter-lens-execution/missing-mechanical/..."
Task: "T016 [US3] Add seeded corpus and trap reapplication fixtures in tests/integration/fixtures/known-traps-corpus/seeded/project/.specrew/quality/known-traps.md and .../trap-reapplication.md"
```

---

## Parallel Example: User Story 4

```text
Task: "T025 [US4] Add strongest-class routing fixtures in tests/integration/fixtures/strongest-class-routing/available-strongest/project/.specrew/iteration-config.yml, missing-rank/project/.specrew/iteration-config.yml, and approved-lower-tier/.../quality/lenses/security-issues.md"
Task: "T027 [US4] Implement strongest-available routing resolution in extensions/specrew-speckit/scripts/resolve-strongest-available-routing.ps1"
Task: "T028 [US4] Integrate requested/effective class recording and override references in extensions/specrew-speckit/scripts/run-hardening-gate.ps1 and extensions/specrew-speckit/scripts/run-bug-hunter-lenses.ps1"
```

---

## Implementation Strategy

### MVP First (Scoped Phase 2)

1. Complete Setup.
2. Complete Foundational work.
3. Deliver **User Story 2** and validate `tests/integration/hardening-gate-contract.ps1`.
4. Stop and verify implementation readiness now fails closed on unresolved hardening concerns.
5. Then layer in **User Story 3** and **User Story 4**.

### Incremental Delivery

1. Publish Phase 2 config defaults and artifact scaffolding.
2. Add pre-implementation hardening enforcement (US2) as the first independently testable increment.
3. Add specialist lens execution and known-traps follow-through (US3).
4. Add strongest-class routing and approved lower-tier overrides (US4).
5. Finish with shared reporting, documentation, and shipped-extension sync.

### Scope Guardrails

- Do **not** add quality-drift detection or quality gap ledger work from FR-041–FR-043.
- Do **not** add reference-implementation companion work from FR-044–FR-046.
- Do **not** broaden this slice into general override workflows beyond the routing override required by FR-039.
- Do **not** imply execution has started; this file remains a planning artifact until a later implementation pass begins.

---

## Notes

- All tasks remain unchecked so the file does not claim work has started.
- Setup, Foundational, and Polish tasks intentionally omit story labels.
- User-story tasks use `[US2]`, `[US3]`, and `[US4]` labels to match the scoped Phase 2 stories from `spec.md`.
- `[P]` marks tasks that can proceed in parallel because they touch different files or fixture trees.
- Deterministic verification stays explicit because `quickstart.md` and `plan.md` require fail-closed validation for this slice.

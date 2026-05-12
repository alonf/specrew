# Tasks: Stack-Aware Quality Bar (Hardening Evidence Boundary Repair)

**Input**: Design documents from `C:\Dev\Specrew\specs\005-stack-aware-quality-bar\`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/`, `iterations/004/plan.md`, `iterations/004/state.md`
**Tests**: Deterministic integration coverage is required for this repair because `plan.md`, `quickstart.md`, and `contracts/quality-governance-artifacts.md` define an explicit validation lane.
**Scope Boundary**: This task list is limited to the Iteration `004` hardening-evidence boundary repair for FR-031, FR-032, FR-033, FR-033a, TG-013, SC-009, and SC-009a. Do **not** reopen User Story 3, User Story 4, quality-drift, known-traps, routing expansion, or reference-implementation work.
**Iteration Focus**: Keep one `hardening-gate.md` artifact, require planning-time analysis before implementation, and preserve later runtime-evidence closure requirements in the same lifecycle-visible review chain.

## Phase 1: Setup (Project Initialization)

**Purpose**: Create the iteration-local artifact surface and keep the active repair slice anchored to Iteration `004`.

- [X] T001 Create the iteration-local hardening artifact scaffold in `specs/005-stack-aware-quality-bar/iterations/004/quality/hardening-gate.md`
- [X] T002 [P] Align the repair validation entry points in `specs/005-stack-aware-quality-bar/iterations/004/plan.md`, `specs/005-stack-aware-quality-bar/iterations/004/state.md`, and `specs/005-stack-aware-quality-bar/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Repair the shared governance and planning surfaces that all hardening-boundary enforcement depends on.

**⚠️ CRITICAL**: No User Story 2 work should start until this phase is complete.

- [X] T003 Add hardening gate metadata and concern-row parsing helpers in `extensions/specrew-speckit/scripts/shared-governance.ps1`
- [X] T004 [P] Render the phase-aware hardening boundary in `extensions/specrew-speckit/scripts/resolve-quality-profile.ps1` and `.specify/templates/plan-template.md`
- [X] T005 Repair pre-implementation hardening artifact generation in `extensions/specrew-speckit/scripts/run-hardening-gate.ps1`
- [X] T006 Repair fail-closed hardening enforcement in `extensions/specrew-speckit/scripts/validate-governance.ps1`

**Checkpoint**: Shared governance parsing, plan rendering, hardening-gate generation, and readiness enforcement all reflect the repaired planning-time-versus-runtime evidence boundary.

---

## Phase 3: User Story 2 - Make quality gates explicit and reviewable across the lifecycle (Priority: P1) 🎯 MVP

**Goal**: Make the pre-implementation hardening gate accept planning-time evidence without weakening the later requirement to record runtime evidence before closure.

**Independent Test**: Run `pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1`, `pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1`, `pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1`, `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\run-hardening-gate.ps1 -ProjectPath . -IterationPath .\specs\005-stack-aware-quality-bar\iterations\004 -OutputFormat Json`, and `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .` to confirm planning-time analysis, expected controls, and rationale are accepted before implementation, missing analysis still blocks, `deferred-with-approval` stays narrow, and runtime-only concerns remain open until later evidence is recorded.

### Tests for User Story 2

- [X] T007 [P] [US2] Update blocked, approved-deferral, and ready contract fixtures in `tests/integration/fixtures/hardening-gate-contract/blocked/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md`, `tests/integration/fixtures/hardening-gate-contract/approved-deferral/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md`, `tests/integration/fixtures/hardening-gate-contract/approved-deferral/.squad/decisions.md`, and `tests/integration/fixtures/hardening-gate-contract/ready/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md`
- [X] T008 [P] [US2] Update blocked and approved governance fixtures in `tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/project/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md`, `tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/project/specs/005-quality-evidence/iterations/001/quality/quality-evidence.md`, `tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md`, `tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/specs/005-quality-evidence/iterations/001/quality/quality-evidence.md`, and `tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/.squad/decisions.md`
- [X] T009 [P] [US2] Extend planning-boundary regression coverage in `tests/integration/quality-profile-foundation.ps1`
- [X] T010 [P] [US2] Extend hardening contract assertions for `Evidence Basis`, `Runtime Evidence Status`, reviewer identity, reviewed-at, and approval references in `tests/integration/hardening-gate-contract.ps1`
- [X] T011 [P] [US2] Extend governance regression assertions in `tests/integration/quality-evidence-governance.ps1`

### Implementation for User Story 2

- [X] T012 [P] [US2] Persist `Evidence Basis` and `Runtime Evidence Status` rows in `extensions/specrew-speckit/scripts/run-hardening-gate.ps1` and `specs/005-stack-aware-quality-bar/iterations/004/quality/hardening-gate.md`
- [X] T013 [US2] Enforce narrow `deferred-with-approval` semantics and later runtime-closure checks in `extensions/specrew-speckit/scripts/validate-governance.ps1` and `extensions/specrew-speckit/scripts/shared-governance.ps1`

**Checkpoint**: User Story 2 is complete when the hardening gate stays lifecycle-visible, planning-time analysis is sufficient for pre-implementation readiness, and runtime-only proof is still required later before closure.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Capture explicit audit metadata and close the iteration-local repair artifacts after the validation lane passes.

- [X] T014 [P] Record TG-013 planning-artifact links, `Evidence Basis`, reviewer identity, reviewed-at, and approval audit fields in `specs/005-stack-aware-quality-bar/iterations/004/quality/hardening-gate.md` and `tests/integration/hardening-gate-contract.ps1`
- [X] T015 Capture the green Iteration `004` repair state in `specs/005-stack-aware-quality-bar/iterations/004/state.md` and `specs/005-stack-aware-quality-bar/iterations/004/plan.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; start immediately.
- **Foundational (Phase 2)**: Depends on Setup; blocks all User Story 2 work.
- **User Story 2 (Phase 3)**: Depends on Foundational completion.
- **Polish (Phase 4)**: Depends on User Story 2 completion and a green deterministic validation lane.

### User Story Dependencies

- **User Story 2 (P1)**: The only in-scope delivery for this repair slice; it starts after the Foundational phase and does not depend on any other user story.

### Within User Story 2

- Fixture updates (`T007`-`T008`) must land before test assertions (`T009`-`T011`).
- Shared helper parsing (`T003`) must land before hardening generation (`T005`) and hardening enforcement (`T006`/`T013`).
- Plan rendering (`T004`) must land before `quality-profile-foundation.ps1` is finalized in `T009`.
- Hardening artifact generation (`T005`) should land before `T012`.
- Governance enforcement (`T006`) should land before the narrow deferral and runtime-closure checks in `T013`.

---

## Parallel Opportunities

- `T001` and `T002` can run in parallel.
- `T004` can run in parallel with `T003` once the Iteration `004` artifact surface exists.
- `T007` and `T008` can run in parallel.
- `T009`, `T010`, and `T011` can run in parallel after the relevant fixtures are updated.
- `T012` can run in parallel with `T013` once the foundational enforcement logic is in place.
- `T014` can run in parallel with `T015` after User Story 2 validation passes.

---

## Parallel Example: User Story 2

```text
Task: "T007 [US2] Update blocked, approved-deferral, and ready contract fixtures in tests/integration/fixtures/hardening-gate-contract/blocked/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md, tests/integration/fixtures/hardening-gate-contract/approved-deferral/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md, tests/integration/fixtures/hardening-gate-contract/approved-deferral/.squad/decisions.md, and tests/integration/fixtures/hardening-gate-contract/ready/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md"
Task: "T008 [US2] Update blocked and approved governance fixtures in tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/project/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md, tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/project/specs/005-quality-evidence/iterations/001/quality/quality-evidence.md, tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md, tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/specs/005-quality-evidence/iterations/001/quality/quality-evidence.md, and tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/.squad/decisions.md"
Task: "T009 [US2] Extend planning-boundary regression coverage in tests/integration/quality-profile-foundation.ps1"
Task: "T010 [US2] Extend hardening contract assertions for Evidence Basis, Runtime Evidence Status, reviewer identity, reviewed-at, and approval references in tests/integration/hardening-gate-contract.ps1"
Task: "T011 [US2] Extend governance regression assertions in tests/integration/quality-evidence-governance.ps1"
```

---

## Implementation Strategy

### MVP First (Scoped Bugfix Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational.
3. Complete Phase 3: User Story 2.
4. **STOP and VALIDATE**: Run the full hardening-boundary validation lane before any audit-metadata or state-capture work.

### Incremental Delivery

1. Publish the Iteration `004` hardening artifact surface and validation entry points.
2. Repair shared parsing, plan rendering, hardening generation, and fail-closed enforcement.
3. Add deterministic fixture and regression coverage for the planning-time-versus-runtime evidence boundary.
4. Record TG-013 audit metadata and capture the green iteration-local hardening artifact set.

### Scope Guardrails

- Do **not** add User Story 3 bug-hunter lens execution or known-traps work.
- Do **not** add User Story 4 routing overrides or mixed-stack fallback work.
- Do **not** add quality-drift or reference-implementation tasks.
- Do **not** reopen completed Iteration `003`; all execution evidence belongs to Iteration `004`.

---

## Notes

- All tasks are now complete for this bounded repair slice; `iterations/004/state.md` is the authoritative execution status record.
- Setup, Foundational, and Polish tasks intentionally omit story labels.
- User-story tasks use `[US2]` because this bounded repair affects only User Story 2 in the current task-generation pass.
- `[P]` marks tasks that can be completed in parallel because they touch different files or can proceed after the stated prerequisite checkpoint.
- Every task includes explicit file paths so the repair remains dependency-ordered and traceable to the active bugfix slice.

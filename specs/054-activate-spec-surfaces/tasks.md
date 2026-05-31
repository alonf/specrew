# Tasks: Discoverable Spec Kit Surfaces

**Feature**: `054-activate-spec-surfaces`  
**Iteration**: `001`  
**Input**: Design documents from `specs/054-activate-spec-surfaces/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`  
**Tests**: Required — `spec.md` defines mandatory user-story validation and `quickstart.md` defines the validation command set  
**Capacity Target**: 8.75 story points

**Organization**: Tasks are grouped by lifecycle foundation and user story so `/speckit.checklist` and `/speckit.analyze` can be surfaced independently while `/speckit.taskstoissues` remains explicitly deferred.

## Format

`- [ ] T### [P?] [US#?] [assigned_to: ...] [effort: ...] Description with exact file path(s) (Trace: ...)`

---

## Phase 1: Setup

**Purpose**: Create the shared evidence scaffold that all later discovery and validation work will write into.

**Verification**: Confirm `specs/054-activate-spec-surfaces/iterations/001/quality/` exists and the iteration plan links to the planned evidence files.

- [ ] T001 [US3] [assigned_to: Planner] [effort: 0.25 SP] Create the F-054 quality-evidence scaffold in `specs/054-activate-spec-surfaces/iterations/001/quality/quality-evidence.md` and `specs/054-activate-spec-surfaces/iterations/001/quality/mechanical-findings.json`, and link those evidence targets from `specs/054-activate-spec-surfaces/iterations/001/plan.md` (Trace: FR-009, FR-011, SC-004, `contracts/quality-governance-artifacts.md`)

---

## Phase 2: Foundational

**Purpose**: Lock the authoritative lifecycle metadata and contract-validation lanes before story-specific discovery changes begin.

**⚠️ CRITICAL**: User-story work starts only after lifecycle truth is anchored in mirrored extension metadata and regression lanes.

**Verification**: Run `pwsh -NoProfile -File tests/integration/lifecycle-boundary-sync.tests.ps1` and `pwsh -NoProfile -File tests/integration/validation-contract-lane.ps1`.

- [ ] T002 [US1, US2, US3] [assigned_to: Spec Steward] [effort: 0.50 SP] Align lifecycle-adjacent command metadata in `extensions/specrew-speckit/extension.yml` and `.specify/extensions/specrew-speckit/extension.yml` with `/speckit.checklist` before-plan surfacing, `/speckit.analyze` before-implement surfacing, and `/speckit.taskstoissues` deferred status (Trace: FR-001, FR-005, FR-010, FR-011)
- [ ] T003 [P] [US2, US3] [assigned_to: Reviewer] [effort: 0.50 SP] Extend `tests/integration/lifecycle-boundary-sync.tests.ps1` to enforce the authoritative placements for `/speckit.checklist` and `/speckit.analyze`, including rejection of premature analyze guidance before `tasks.md` exists (Trace: FR-006, FR-008, FR-011, SC-003)
- [ ] T004 [P] [US3] [assigned_to: Reviewer] [effort: 0.50 SP] Extend `tests/integration/validation-contract-lane.ps1` to verify discovery-surface wording and `/speckit.taskstoissues` deferment remain consistent with `specs/054-activate-spec-surfaces/contracts/discovery-surfaces.md`, `specs/054-activate-spec-surfaces/contracts/lifecycle-placement.md`, and `specs/054-activate-spec-surfaces/contracts/quality-governance-artifacts.md` (Trace: FR-009, FR-010, FR-011, TG-001, SC-005)

**Checkpoint**: Lifecycle metadata, contract parity, and quality-evidence paths are ready for story work.

---

## Phase 3: User Story 1 - Discover checklist before planning (Priority: P1) 🎯 MVP

**Goal**: Surface `/speckit.checklist` at the before-plan boundary with plain-language, proportional guidance about when it helps.

**Independent Test**: A user arriving at before-plan sees `/speckit.checklist`, understands it improves requirement clarity/completeness before planning, and can tell it is recommended for substantive work but optional for lightweight slices.

**Verification**: Run `pwsh -NoProfile -File tests/integration/slash-command-routing.tests.ps1`.

### Tests for User Story 1

- [ ] T005 [US1] [assigned_to: Reviewer] [effort: 0.50 SP] Add before-plan checklist regression coverage to `tests/integration/slash-command-routing.tests.ps1` for requirement-quality messaging, substantive-slice recommendation, and lightweight-slice proportionality (Trace: FR-001, FR-002, FR-003, FR-004, SC-001, SC-002)

### Implementation for User Story 1

- [ ] T006 [US1] [assigned_to: Planner] [effort: 0.50 SP] Update `extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md` and `.specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md` so the before-plan boundary explicitly surfaces `/speckit.checklist` as a requirements-quality aid with proportional guidance for low-risk slices (Trace: FR-001, FR-002, FR-004, SC-001, SC-002)
- [ ] T007 [US1] [assigned_to: Spec Steward] [effort: 0.50 SP] Revise `.github/agents/speckit.plan.agent.md` and `.github/prompts/speckit.checklist.prompt.md` so the planning-boundary handoff positions `/speckit.checklist` before planning and explains its requirements-quality role in plain language (Trace: FR-001, FR-002, FR-003, FR-004)
- [ ] T008 [P] [US1] [assigned_to: Spec Steward] [effort: 0.25 SP] Update `.github/agents/speckit.checklist.agent.md` so `/speckit.checklist` is described as a lifecycle-adjacent review aid for substantive requirements work without implying it replaces planning or becomes mandatory for every tiny slice (Trace: FR-002, FR-003, FR-004, SC-002)

**Checkpoint**: `/speckit.checklist` is discoverable and correctly framed at the before-plan boundary.

---

## Phase 4: User Story 2 - Discover analyze at the right lifecycle point (Priority: P2)

**Goal**: Surface `/speckit.analyze` only after `/speckit.tasks` completes, and explain that it adds cross-artifact consistency review without replacing Specrew governance.

**Independent Test**: A user can identify `/speckit.analyze` as a before-implement step that requires `spec.md`, `plan.md`, and `tasks.md`, and they are redirected back to the correct stage if those artifacts are incomplete.

**Verification**: Run `pwsh -NoProfile -File tests/integration/slash-command-coexistence.tests.ps1`.

### Tests for User Story 2

- [ ] T009 [US2] [assigned_to: Reviewer] [effort: 0.50 SP] Add before-implement analyze regression coverage to `tests/integration/slash-command-coexistence.tests.ps1` for additive-governance framing, required artifact prerequisites, and early-stage redirect behavior (Trace: FR-005, FR-006, FR-007, FR-008, SC-003)

### Implementation for User Story 2

- [ ] T010 [US2] [assigned_to: Planner] [effort: 0.50 SP] Update `extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md` and `.specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md` so the boundary explicitly surfaces `/speckit.analyze` only after complete `tasks.md` exists and describes it as additive to governance validation (Trace: FR-005, FR-006, FR-007, FR-008, SC-003)
- [ ] T011 [US2] [assigned_to: Spec Steward] [effort: 0.50 SP] Revise `.github/agents/speckit.tasks.agent.md` and `.github/prompts/speckit.analyze.prompt.md` so analyze appears after task generation with explicit `spec.md`/`plan.md`/`tasks.md` prerequisites and non-replacement guidance (Trace: FR-005, FR-006, FR-007, FR-008)
- [ ] T012 [P] [US2] [assigned_to: Spec Steward] [effort: 0.25 SP] Update `.github/agents/speckit.analyze.agent.md` so its discovery copy reinforces before-implement timing, complete-artifact prerequisites, and additive governance positioning (Trace: FR-005, FR-007, FR-008, SC-003)

**Checkpoint**: `/speckit.analyze` is surfaced only at the approved lifecycle point and never framed as a governance replacement.

---

## Phase 5: User Story 3 - Understand surfaced vs deferred lifecycle-adjacent commands (Priority: P2)

**Goal**: Make the standard discovery surfaces explain which lifecycle-adjacent commands are active in this slice and which remain deferred.

**Independent Test**: A user reading standard Specrew guidance can identify `/speckit.checklist` and `/speckit.analyze` as active surfaced commands, understand when to use each, and see `/speckit.taskstoissues` explicitly marked deferred.

**Verification**: Run `pwsh -NoProfile -File tests/integration/slash-command-discovery.tests.ps1`.

### Tests for User Story 3

- [ ] T013 [US3] [assigned_to: Reviewer] [effort: 0.50 SP] Add lifecycle-adjacent discovery coverage to `tests/integration/slash-command-discovery.tests.ps1` for `README.md`, `docs/user-guide.md`, and explicit `/speckit.taskstoissues` deferment messaging (Trace: FR-009, FR-010, FR-011, SC-004, SC-005)

### Implementation for User Story 3

- [ ] T014 [US3] [assigned_to: Spec Steward] [effort: 0.75 SP] Update `README.md` and `docs/user-guide.md` with a consistent lifecycle-adjacent command matrix that surfaces `/speckit.checklist` before plan, surfaces `/speckit.analyze` before implement after complete tasks, and marks `/speckit.taskstoissues` deferred for Feature 054 (Trace: FR-009, FR-010, FR-011, SC-004, SC-005)
- [ ] T015 [P] [US3] [assigned_to: Spec Steward] [effort: 0.50 SP] Update `.github/agents/speckit.taskstoissues.agent.md` and `.github/prompts/speckit.taskstoissues.prompt.md` to state that `/speckit.taskstoissues` is known but deferred and not part of the default Feature 054 lifecycle (Trace: FR-010, FR-011, SC-005)

**Checkpoint**: Standard discovery surfaces consistently distinguish active surfaced commands from deferred commands.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Capture the required mechanical and integration evidence for the entire surfaced-command slice.

**Verification**: Complete the markdownlint run, all five integration lanes, and the mechanical-check output reserved in the quality evidence plan.

- [ ] T016 [P] [US3] [assigned_to: Implementer] [effort: 0.50 SP] Run `npx --yes markdownlint-cli README.md docs/user-guide.md .github/agents/*.md .github/prompts/*.md specs/054-activate-spec-surfaces/*.md` and record the stack-tooling evidence in `specs/054-activate-spec-surfaces/iterations/001/quality/quality-evidence.md` (Trace: FR-009, FR-011, SC-004, `contracts/quality-governance-artifacts.md`)
- [ ] T017 [P] [US1, US2, US3] [assigned_to: Implementer] [effort: 0.75 SP] Run `pwsh -NoProfile -File tests/integration/slash-command-discovery.tests.ps1`, `pwsh -NoProfile -File tests/integration/slash-command-routing.tests.ps1`, `pwsh -NoProfile -File tests/integration/slash-command-coexistence.tests.ps1`, `pwsh -NoProfile -File tests/integration/lifecycle-boundary-sync.tests.ps1`, and `pwsh -NoProfile -File tests/integration/validation-contract-lane.ps1`, then record the results in `specs/054-activate-spec-surfaces/iterations/001/quality/quality-evidence.md` (Trace: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, SC-001, SC-002, SC-003, SC-004, SC-005)
- [ ] T018 [US3] [assigned_to: Reviewer] [effort: 0.50 SP] Run `extensions/specrew-speckit/scripts/run-mechanical-checks.ps1` (or `.specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1` when validating the managed mirror) and write the dead-field, anti-pattern, and test-integrity summary to `specs/054-activate-spec-surfaces/iterations/001/quality/mechanical-findings.json` (Trace: FR-009, FR-011, `contracts/quality-governance-artifacts.md`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 → Phase 2**: Evidence paths must exist before validation lanes and metadata changes can target them.
- **Phase 2 → Phase 3/4/5**: Extension metadata and contract parity block all user-story surfacing work.
- **Phase 3 (US1)**: Delivers the MVP before-plan checklist experience.
- **Phase 4 (US2)**: Depends on Phase 2 and can proceed in parallel with Phase 5 once foundational lifecycle truth is locked.
- **Phase 5 (US3)**: Depends on Phase 2 and consolidates top-level discovery guidance plus deferred-command messaging.
- **Phase 6**: Starts only after the desired story phases are code-complete.

### User Story Dependencies

- **US1 (P1)**: Starts immediately after Phase 2 and is the MVP scope.
- **US2 (P2)**: Starts after Phase 2; independent of US1 implementation files but must preserve the same lifecycle contract.
- **US3 (P2)**: Starts after Phase 2; should reconcile documentation with the same lifecycle truths established for US1 and US2.

### Parallel Opportunities

- **Phase 2**: `T003` and `T004` can run in parallel once `T002` defines the authoritative lifecycle metadata.
- **US1**: `T008` can run in parallel with `T006`/`T007` after `T005` defines the failing expectation.
- **US2**: `T012` can run in parallel with `T010`/`T011` after `T009` defines the failing expectation.
- **US3**: `T015` can run in parallel with `T014` after `T013` defines the failing expectation.
- **Phase 6**: `T016` and `T017` can run in parallel after implementation stabilizes; `T018` should consume the final settled surface set.

---

## Parallel Example: User Story 1

```text
Task: T006 Update mirrored before-plan command surfaces in extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md and .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md
Task: T008 Update .github/agents/speckit.checklist.agent.md with proportional checklist guidance
```

## Parallel Example: User Story 2

```text
Task: T010 Update mirrored before-implement command surfaces in extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md and .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md
Task: T012 Update .github/agents/speckit.analyze.agent.md with additive before-implement messaging
```

## Parallel Example: User Story 3

```text
Task: T014 Update README.md and docs/user-guide.md with lifecycle-adjacent command guidance
Task: T015 Update .github/agents/speckit.taskstoissues.agent.md and .github/prompts/speckit.taskstoissues.prompt.md with deferred-status messaging
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 setup.
2. Complete Phase 2 foundational lifecycle metadata + contract validation.
3. Complete Phase 3 (US1) to surface `/speckit.checklist` at before-plan.
4. Validate `tests/integration/slash-command-routing.tests.ps1`.
5. Stop and review the before-plan experience before expanding to analyze and broader discovery docs.

### Incremental Delivery

1. Foundation (`T001-T004`)
2. Before-plan checklist surfacing (`T005-T008`) → validate US1
3. Before-implement analyze surfacing (`T009-T012`) → validate US2
4. Cross-surface active vs deferred command guidance (`T013-T015`) → validate US3
5. Quality evidence + mechanical proof (`T016-T018`)

### Suggested MVP Scope

**US1 only** after `T001-T004` completes.

---

## Task Count Summary

- **Total Tasks**: 18
- **Setup**: 1
- **Foundational**: 3
- **US1**: 4
- **US2**: 4
- **US3**: 3
- **Polish**: 3
- **Parallel Opportunities**: 7 tasks marked `[P]`

---

## Notes

- This task plan intentionally stays inside the approved F-054 scope: checklist surfacing, analyze surfacing, discovery/docs consistency, deferred `/speckit.taskstoissues`, and the agreed quality-evidence path.
- No task in this file activates `/speckit.taskstoissues` as a default workflow step.
- Hardening-only artifacts reserved by the plan (`specs/054-activate-spec-surfaces/iterations/001/quality/hardening-gate.md` and `specs/054-activate-spec-surfaces/iterations/001/quality/trap-reapplication.md`) remain deferred until a later approved boundary.

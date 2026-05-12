# Tasks: Make Resume-Mode Visible in Specrew Onboarding

**Input**: Design documents from `/specs/010-onboarding-resume-visibility/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/onboarding-text-surface.md`, `quickstart.md`

**Tests**: Use the required six-command validation lane plus the manual rendered-surface checks defined in `spec.md` and `quickstart.md`.

**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently while keeping scope limited to documentation and banner text only.

## Format: `[ID] [P?] [Story?] [Owner] [Effort] Description`

- **[P]**: Can run in parallel once dependencies are satisfied
- **[Story?]**: Present only for user-story work as `[US1]` or `[US2]`
- **[Owner]**: Primary execution owner aligned to the Specrew baseline roles
- **[Effort]**: Relative effort estimate (`S`, `M`, `L`)
- Every task names concrete files and preserves explicit traceability to the approved spec or plan artifacts

## Phase 1: Setup

**Purpose**: Establish the regression baseline and confirm the approved feature boundary before any edits.

- [X] T001 [Owner: Reviewer] [Effort: M] Run the baseline six-command validation lane from repo root using `tests/integration/quality-profile-foundation.ps1`, `tests/integration/hardening-gate-contract.ps1`, `tests/integration/quality-evidence-governance.ps1`, `tests/integration/validation-contract-lane.ps1`, `tests/integration/project-path-resolution-regression.ps1`, and `extensions/specrew-speckit/scripts/validate-governance.ps1`, then record the baseline result in `specs/010-onboarding-resume-visibility/plan.md` iteration state notes. (Trace: plan.md Validation Lane, plan.md Iteration State Notes, TG-005, SC-006)
- [X] T002 [P] [Owner: Planner] [Effort: S] Review `specs/010-onboarding-resume-visibility/spec.md`, `specs/010-onboarding-resume-visibility/plan.md`, `specs/010-onboarding-resume-visibility/research.md`, `specs/010-onboarding-resume-visibility/data-model.md`, `specs/010-onboarding-resume-visibility/contracts/onboarding-text-surface.md`, and `specs/010-onboarding-resume-visibility/quickstart.md` to confirm the documentation-and-banner-only scope. (Trace: FR-006, TG-003, plan.md Summary)

---

## Phase 2: Foundational

**Purpose**: Lock the implementation to the approved edit surfaces and validation obligations that block both user stories.

- [X] T003 [Owner: Planner] [Effort: S] Limit the planned implementation diff to `README.md`, `docs/getting-started.md`, `docs/user-guide.md`, and the `Write-PostBootstrapGuidance` text block in `scripts/specrew-init.ps1`, while leaving all `specs/008-*` and `specs/009-*` files untouched. (Trace: FR-006, Non-Goals, quickstart.md bounded workflow)
- [X] T004 [P] [Owner: Reviewer] [Effort: S] Prepare the manual review checklist from `specs/010-onboarding-resume-visibility/quickstart.md` for `README.md`, `docs/getting-started.md`, `docs/user-guide.md`, and `scripts/specrew-init.ps1`. (Trace: TG-004, FR-005, quickstart.md closure checklist)

**Checkpoint**: Scope boundary is locked and the validation approach is ready.

---

## Phase 3: User Story 1 - New user resumes correctly (Priority: P1) 🎯 MVP

**Goal**: Make the primary onboarding surfaces clearly teach that every later session still starts with `specrew start` and that running `copilot` directly is unsupported.

**Independent Test**: Read `README.md`, `docs/getting-started.md`, and the bootstrap completion banner from `scripts/specrew-init.ps1`; each surface must explicitly say resumed sessions also begin with `specrew start`, mention runtime handoff regeneration, and warn against `copilot` directly.

- [X] T005 [P] [US1] [Owner: Implementer] [Effort: S] Add resume-session guidance and the explicit unsupported-`copilot` warning with rationale to `README.md`. (Trace: FR-001, FR-004, US1 acceptance scenarios 1 and 4)
- [X] T006 [P] [US1] [Owner: Implementer] [Effort: M] Add a `Resuming work later` subsection in `docs/getting-started.md` that names `specrew start` as the command for later sessions and explains runtime handoff regeneration. (Trace: FR-002, FR-004, US1 acceptance scenarios 2 and 4)
- [X] T007 [P] [US1] [Owner: Implementer] [Effort: S] Update only the `Write-PostBootstrapGuidance` next-steps text in `scripts/specrew-init.ps1` to add a visible resume-mode banner message and unsupported-`copilot` warning. (Trace: FR-003, FR-004, US1 acceptance scenarios 3 and 4)
- [X] T008 [US1] [Owner: Reviewer] [Effort: M] Validate `README.md`, `docs/getting-started.md`, and the rendered banner from `scripts/specrew-init.ps1` against User Story 1 acceptance criteria in `specs/010-onboarding-resume-visibility/spec.md`. (Trace: TG-001, TG-004, SC-001, SC-002)

**Checkpoint**: User Story 1 is independently understandable from any of the three primary onboarding surfaces.

---

## Phase 4: User Story 2 - Cross-machine resumes stay understandable (Priority: P2)

**Goal**: Make resumed work after restarts or machine switches understandable without expanding scope beyond documentation and banner wording.

**Independent Test**: Re-read the onboarding surfaces and confirm they still name `specrew start` as the resume command after restart or machine switch, and that at least one surface explains the per-machine runtime handoff regeneration from tracked project state.

- [X] T009 [US2] [Owner: Implementer] [Effort: M] Extend the `Resuming work later` subsection in `docs/getting-started.md` with `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.specrew/start-summary.md`, the cross-machine regeneration explanation, and the active-session clarification. (Trace: FR-002, TG-002, US2 acceptance scenarios 1 and 2)
- [X] T010 [P] [US2] [Owner: Reviewer] [Effort: S] Review `docs/user-guide.md` for contradictory first-launch-only or direct-`copilot` language and apply only the minimum alignment edit in `docs/user-guide.md` if a contradiction is found. (Trace: FR-005, SC-004)
- [X] T011 [US2] [Owner: Planner] [Effort: S] Record the FR-005 review outcome for `docs/user-guide.md` in `specs/010-onboarding-resume-visibility/plan.md`. (Trace: FR-005, plan.md Iteration State Notes)
- [X] T012 [US2] [Owner: Reviewer] [Effort: M] Re-read `README.md`, `docs/getting-started.md`, `docs/user-guide.md`, and the rendered banner from `scripts/specrew-init.ps1` to confirm the cross-machine resume contract remains consistent and independently testable. (Trace: TG-002, TG-004, SC-003, SC-004)

**Checkpoint**: Cross-machine and later-session guidance is consistent without changing runtime behavior.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Finish validation, visibility checks, and scope-guard review before the after-tasks gate.

- [X] T013 [Owner: Reviewer] [Effort: M] Run the post-edit six-command validation lane from repo root using `tests/integration/quality-profile-foundation.ps1`, `tests/integration/hardening-gate-contract.ps1`, `tests/integration/quality-evidence-governance.ps1`, `tests/integration/validation-contract-lane.ps1`, `tests/integration/project-path-resolution-regression.ps1`, and `extensions/specrew-speckit/scripts/validate-governance.ps1`, then record the post-implementation result in `specs/010-onboarding-resume-visibility/plan.md` iteration state notes. (Trace: plan.md Validation Lane, plan.md Iteration State Notes, TG-005, SC-006)
- [X] T014 [Owner: Reviewer] [Effort: S] Perform the final rendered-surface visibility review for `README.md`, `docs/getting-started.md`, and the bootstrap banner in `scripts/specrew-init.ps1`, including the 100-column banner check from `specs/010-onboarding-resume-visibility/spec.md`. (Trace: TG-004, SC-005)
- [X] T015 [Owner: Planner] [Effort: S] Audit the final diff for `README.md`, `docs/getting-started.md`, `docs/user-guide.md`, `scripts/specrew-init.ps1`, and `specs/010-onboarding-resume-visibility/plan.md` to confirm no `specs/008-*` or `specs/009-*` edits slipped in and no non-banner logic changed in `scripts/specrew-init.ps1`. (Trace: FR-006, TG-003, quickstart.md scope audit)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup** → no dependencies
- **Phase 2: Foundational** → depends on Phase 1
- **Phase 3: User Story 1** → depends on Phase 2
- **Phase 4: User Story 2** → depends on Phase 3 because it extends the onboarding contract and refines `docs/getting-started.md`
- **Phase 5: Polish & Cross-Cutting Concerns** → depends on Phases 3 and 4

### User Story Dependencies

- **US1 (P1)**: No user-story dependency after Foundational; this is the MVP slice
- **US2 (P2)**: Depends on US1 because the cross-machine clarification builds on the resume guidance already added to the same onboarding surfaces

### Within Each User Story

- Complete direct surface edits before running that story’s manual validation task
- Keep `scripts/specrew-init.ps1` changes limited to banner text inside `Write-PostBootstrapGuidance`
- Record the `docs/user-guide.md` review outcome before final validation closure

### Parallel Opportunities

- `T002` and `T004` can run in parallel with other review-prep work
- `T005`, `T006`, and `T007` can run in parallel because they touch different files
- `T010` can run in parallel with `T009` because `docs/user-guide.md` is separate from `docs/getting-started.md`

---

## Parallel Example: User Story 1

```text
Task: "T005 Add resume-session guidance and the explicit unsupported-copilot warning with rationale to README.md"
Task: "T006 Add a Resuming work later subsection in docs/getting-started.md that names specrew start as the command for later sessions and explains runtime handoff regeneration"
Task: "T007 Update only the Write-PostBootstrapGuidance next-steps text in scripts/specrew-init.ps1 to add a visible resume-mode banner message and unsupported-copilot warning"
```

## Parallel Example: User Story 2

```text
Task: "T009 Extend the Resuming work later subsection in docs/getting-started.md with the three transient file names and cross-machine regeneration explanation"
Task: "T010 Review docs/user-guide.md for contradictory first-launch-only or direct-copilot language and apply only the minimum alignment edit if needed"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2
2. Complete `T005` through `T008`
3. Stop and validate the three primary onboarding surfaces before adding cross-machine refinements

### Incremental Delivery

1. Establish baseline and scope guardrails
2. Deliver User Story 1 across `README.md`, `docs/getting-started.md`, and `scripts/specrew-init.ps1`
3. Add User Story 2 cross-machine and review-only alignment work without widening scope
4. Finish with the full lane, rendered-surface review, and final scope audit

### Scope Guardrails

- Do not edit any `specs/008-*` or `specs/009-*` files
- Do not change runtime behavior, lifecycle rules, or governance behavior
- In `scripts/specrew-init.ps1`, edit banner text only inside `Write-PostBootstrapGuidance`

---

## Notes

- All tasks now follow the required checklist format: checkbox, task ID, optional `[P]`, optional story label, explicit `[Owner: ...]`, explicit `[Effort: ...]`, and concrete file paths
- Validation for this feature is a mix of regression-lane execution and manual rendered-surface review rather than new automated test files
- `docs/user-guide.md` remains review-only unless the contradiction check finds wording that must be corrected

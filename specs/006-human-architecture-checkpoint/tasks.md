# Tasks: Human Architecture Intent Checkpoint

**Input**: Design documents from `/specs/006-human-architecture-checkpoint/`  
**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories)  
**Tests**: Use the repository's real workflow checks only: focused PowerShell integration coverage under `tests\integration\` plus existing contract-lane wiring.  
**Organization**: Tasks are grouped by user story and limited to actual Specrew/Spec Kit workflow surfaces.

## Format: `[ID] [P?] [Story] [Owner] [Capacity] Description`

- **[P]**: Can run in parallel once dependencies are satisfied
- **[Story]**: `US0` = shared foundation, otherwise maps to the user story in `spec.md`
- **[Owner]**: Suggested Specrew role for execution
- **[Capacity]**: Relative effort for iteration planning (`S`, `M`)
- Every task names concrete repository files and includes traceability references

---

## Phase 1: Shared Hook and Routing Foundation

**Purpose**: Establish the real workflow surfaces that the checkpoint depends on before user-story-specific work begins.

- [ ] T001 [US0] [Owner: Planner] [Capacity: M] Update `extensions\specrew-speckit\commands\speckit.specrew-speckit.before-plan.md`, `.specify\extensions\specrew-speckit\commands\speckit.specrew-speckit.before-plan.md`, and `.github\agents\speckit.plan.agent.md` so `/speckit.plan` runs an automatic implementation-intent checkpoint, blocks on missing approval, and sends vague specs back to clarification instead of drafting a plan anyway. (Trace: FR-001, FR-002, TG-002)
- [ ] T002 [US0] [Owner: Planner] [Capacity: M] Update `extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md`, `.specify\extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md`, `.github\agents\squad.agent.md`, and `.specrew\last-start-prompt.md` so the routed lifecycle consistently places the checkpoint between clarify and plan and preserves the escalation path back to the human. (Trace: FR-004, TG-002, TG-004)
- [ ] T003 [P] [US0] [Owner: Reviewer] [Capacity: S] Create deterministic fixtures under `tests\integration\fixtures\human-architecture-checkpoint\` for three cases: a clarified non-trivial feature, a routine low-risk feature, and a vague feature that must be bounced back to clarification. (Trace: FR-001, FR-005, Edge Case: vague spec)

**Checkpoint**: Foundation ready — prompt, routing, and test-fixture surfaces are aligned on real repository files.

---

## Phase 2: User Story 1 - Architect Approves Implementation Direction Before Planning (Priority: P1) 🎯 MVP

**Goal**: `/speckit.plan` produces an implementation intent brief before planning and requires human approval or redirection on major decisions.

**Independent Test**: Run the focused checkpoint integration harness against a clarified feature and verify that the implementation intent brief appears before the plan body, that risky decisions are surfaced for approval, and that vague specs are rejected back to clarification.

- [ ] T004 [US1] [Owner: Planner] [Capacity: S] Update `README.md` and `docs\user-guide.md` so workflow documentation explicitly states that `/speckit.plan` performs the architecture checkpoint automatically before generating the plan body. (Trace: TG-002, SC-001)
- [ ] T005 [US1] [Owner: Reviewer] [Capacity: M] Add `tests\integration\human-architecture-checkpoint.ps1` to verify the implementation intent brief appears before planning, requires human approval for high-impact decisions, and blocks vague specs from proceeding. (Trace: US1 acceptance scenarios 1-2, FR-001, FR-002, TG-002)
- [ ] T006 [P] [US1] [Owner: Reviewer] [Capacity: S] Wire `tests\integration\human-architecture-checkpoint.ps1` into `tests\integration\validation-contract-lane.ps1` so the existing contract lane covers the new pre-plan checkpoint. (Trace: TG-002)

**Checkpoint**: User Story 1 is independently provable through the focused integration harness and the documented lifecycle.

---

## Phase 3: User Story 2 - Human Constraints and Forbidden Paths Are Recorded and Enforced (Priority: P1)

**Goal**: Accepted direction, rejected alternatives, and forbidden paths are recorded in plan artifacts and remain visible to the later approval gate.

**Independent Test**: Generate a plan for a feature with explicit human direction and verify that `plan.md` contains an `Architecture Intent Review` section and that the existing pre-implementation approval gate summarizes the accepted direction instead of bypassing it.

- [ ] T007 [US2] [Owner: Planner] [Capacity: M] Update `.specify\templates\plan-template.md` to add `## Architecture Intent Review` with required fields for accepted direction, rejected alternatives, explicit constraints/forbidden paths, unresolved questions, and `.squad\decisions.md` references when that ledger exists. (Trace: FR-003, TG-003)
- [ ] T008 [US2] [Owner: Planner] [Capacity: S] Update `extensions\specrew-speckit\commands\speckit.specrew-speckit.before-implement.md` and `.specify\extensions\specrew-speckit\commands\speckit.specrew-speckit.before-implement.md` so the existing pre-implementation approval gate remains mandatory and explicitly reads the accepted direction from `plan.md`. (Trace: FR-006, TG-003)
- [ ] T009 [US2] [Owner: Reviewer] [Capacity: M] Extend `tests\integration\human-architecture-checkpoint.ps1` to assert that generated plans contain the `Architecture Intent Review` section and that the pre-implementation gate still runs with the approved direction in view. (Trace: FR-003, FR-006, TG-003, TG-004)

**Checkpoint**: User Story 2 is independently testable through generated plan output and preserved pre-implementation gating.

---

## Phase 4: User Story 3 - Squad Respects Minimal Interruption and Local Autonomy (Priority: P1)

**Goal**: The checkpoint asks the human only about expensive-to-reverse decisions and otherwise defaults to existing conventions for routine local details.

**Independent Test**: Compare the routine-change fixture and the high-impact fixture; the routine case should request only confirmation or constraints, while the high-impact case should ask focused architecture questions.

- [ ] T010 [US3] [Owner: Planner] [Capacity: S] Refine `extensions\specrew-speckit\commands\speckit.specrew-speckit.before-plan.md`, `.specify\extensions\specrew-speckit\commands\speckit.specrew-speckit.before-plan.md`, and `.github\agents\speckit.plan.agent.md` with explicit decision-boundary language that distinguishes "ask the human" cases from "follow existing conventions" cases. (Trace: FR-002, FR-005, SC-005)
- [ ] T011 [US3] [Owner: Planner] [Capacity: S] Update `.specrew\last-start-prompt.md`, `.github\agents\squad.agent.md`, and the coordinator prompt templates so routed sessions consistently state when Squad may proceed autonomously on local reversible details and when it must escalate. (Trace: FR-005, TG-004)
- [ ] T012 [US3] [Owner: Reviewer] [Capacity: S] Extend `tests\integration\fixtures\human-architecture-checkpoint\` and `tests\integration\human-architecture-checkpoint.ps1` with both routine-change and high-impact scenarios to prove minimal-interruption behavior. (Trace: FR-002, FR-005, SC-005)

**Checkpoint**: User Story 3 is independently testable through side-by-side routine vs high-impact checkpoint scenarios.

---

## Phase 5: Final Validation and Readiness

**Purpose**: Re-run the real repository validation path after implementation lands.

- [ ] T013 [P] [USX] [Owner: Reviewer] [Capacity: S] Run `tests\integration\human-architecture-checkpoint.ps1` and `tests\integration\validation-contract-lane.ps1` after the implementation slice lands; if live operator confirmation is still needed, capture it with `tests\manual\copilot-squad-smoke.ps1` rather than inventing a new validation harness. (Trace: SC-001, SC-005, SC-006)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundation)**: No dependencies.
- **Phase 2 (US1)**: Depends on T001-T003.
- **Phase 3 (US2)**: Depends on T001-T003; T009 also depends on T007-T008.
- **Phase 4 (US3)**: Depends on T001-T003; T012 also depends on T010-T011.
- **Phase 5 (Final Validation)**: Depends on the completed US1-US3 implementation slices.

### User Story Dependencies

- **US1** starts immediately after the shared foundation.
- **US2** starts immediately after the shared foundation and shares the same checkpoint/test harness.
- **US3** starts immediately after the shared foundation but should land after the main checkpoint prompt exists so the decision-boundary wording has a stable base.

### Parallel Opportunities

- T003 can run in parallel with T001-T002 once file ownership is coordinated.
- T004 and T007 can proceed in parallel after the foundation is in place.
- T006 is parallel-safe once T005 exists.
- T012 is parallel-safe once T010 and T011 land.
- T013 can batch the final integration runs together.

## Implementation Strategy

### MVP First

1. Complete Phase 1 foundation.
2. Complete US1 and prove the checkpoint runs before planning.
3. Add US2 recording so accepted direction is visible in `plan.md` and the later approval gate.
4. Add US3 minimal-interruption refinements.
5. Finish with the existing integration/manual validation path.

### Notes

- This task list is intentionally limited to actual Specrew/Spec Kit workflow assets: markdown prompts/templates, PowerShell integration scripts, and documentation.
- Do **not** create fictional `src\...`, Python, or TypeScript runtime modules for this feature.
- If helper automation becomes necessary during implementation, keep it under `extensions\specrew-speckit\scripts\` and mirror the installed `.specify\extensions\specrew-speckit\scripts\` copy.

# Tasks: Stack-Aware Quality Bar (Phase 1 / First Slice)

**Input**: Design documents from `C:\Dev\Specrew\specs\005-stack-aware-quality-bar\`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/`

**Scope**: This task list is limited to the Phase 1 / first-slice boundary in `plan.md` (`Slice A -> Slice B -> Slice C -> Slice D`). It excludes later-phase hardening-gate, bug-hunter, strongest-class routing, known-traps, override, mixed-stack, and quality-drift implementation work from `spec.md`.

**Tests**: Deterministic integration coverage is explicitly required by `spec.md` and `quickstart.md`, so test tasks are included for each in-scope slice.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the directory and fixture scaffolding needed for Phase 1 quality-governance work.

- [X] T001 Create the Phase 1 quality asset source roots in `extensions/specrew-speckit/templates/quality/presets/` and `extensions/specrew-speckit/templates/quality/lenses/` (Trace: FR-022, FR-023, FR-024, Slice A1)
- [X] T002 [P] Create deterministic fixture roots in `tests/integration/fixtures/quality-profile-foundation/`, `tests/integration/fixtures/mechanical-findings-contract/`, and `tests/integration/fixtures/quality-evidence-governance/` (Trace: FR-010, FR-011, FR-012, FR-030, Verification Strategy)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the shared quality asset registry and scaffolding contract before planning-time profile inference begins.

**⚠️ CRITICAL**: Complete this phase before starting user-story implementation.

- [X] T003 [P] Add scaffold-and-asset-registry regression coverage in `tests/integration/quality-profile-foundation.ps1` using fixtures in `tests/integration/fixtures/quality-profile-foundation/` (Trace: FR-023, FR-024, FR-025, Slice A2-A3)
- [X] T004 Extend downstream quality asset discovery and scaffold output in `extensions/specrew-speckit/scripts/scaffold-governance.ps1` (Trace: FR-023, FR-024, FR-025, contracts/quality-governance-artifacts.md)
- [X] T005 [P] Create versioned lens checklist sources in `extensions/specrew-speckit/templates/quality/lenses/security-baseline-v1.md`, `extensions/specrew-speckit/templates/quality/lenses/robustness-baseline-v1.md`, and `extensions/specrew-speckit/templates/quality/lenses/test-integrity-v1.md` with Markdown tables, upgrade guidance, and change logs (Trace: FR-022, FR-023, Slice A1-A3)
- [X] T006 [P] Create the Phase 1 preset catalog in `extensions/specrew-speckit/templates/quality/presets/node-public-ws-service-v1.md`, `extensions/specrew-speckit/templates/quality/presets/react-spa-public-v1.md`, `extensions/specrew-speckit/templates/quality/presets/node-rest-with-postgres-v1.md`, `extensions/specrew-speckit/templates/quality/presets/python-fastapi-service-v1.md`, and `extensions/specrew-speckit/templates/quality/presets/dotnet-aspnet-api-v1.md`, including the worked example in `node-public-ws-service-v1.md` (Trace: FR-024, FR-024a, FR-025, FR-026, Slice A3)
- [X] T007 Document the reviewed lens-upgrade workflow and quality asset authoring rules in `extensions/specrew-speckit/templates/quality/README.md` and `extensions/specrew-speckit/README.md` (Trace: FR-026, research.md R1-R2)

**Checkpoint**: Quality assets, scaffold metadata, and registry tests exist for the first slice.

---

## Phase 3: User Story 1 - Infer a stack-aware quality profile during planning (Priority: P1) 🎯 MVP

**Goal**: Make planning artifacts emit an explicit Phase 1 quality profile, preset/tool-bundle selection, required gates, and bounded first-slice deferrals before implementation begins.

**Independent Test**: Run `tests/integration/quality-profile-foundation.ps1` against a recognized-stack fixture and confirm the rendered feature plan includes a Phase 1 marker, inferred quality profile, preset reference or bounded custom composition, tool bundle, required mechanical gates, and not-applicable rationale.

- [X] T008 [P] [US1] Add recognized-stack and bounded-custom-composition plan assertions in `tests/integration/quality-profile-foundation.ps1` (Trace: FR-002, FR-003, FR-003a, FR-004, FR-010, FR-015, Slice B1-B3)
- [X] T009 [US1] Implement stack-signal, risk-dimension, preset-selection, bounded custom-composition resolution, and not-applicable gate reasoning in `extensions/specrew-speckit/scripts/resolve-quality-profile.ps1` (Trace: FR-002, FR-003, FR-003a, FR-004, FR-015, Slice B1)
- [X] T010 [US1] Wire quality-profile resolution into `extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md` and `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (Trace: FR-010, FR-011, FR-015, Slice B2-B3)
- [X] T011 [US1] Render the Phase 1 quality planning section in `C:\Dev\Specrew\.specify\templates\plan-template.md` with preset refs, stack surfaces, risk dimensions, required gates, not-applicable rationale, and explicit Phase 2+ deferrals (Trace: FR-010, FR-011, FR-015, contracts/quality-governance-artifacts.md)

**Checkpoint**: Planning produces a reviewable Phase 1 quality profile without implying later-phase hardening, drift, or bug-hunter execution.

---

## Phase 4: Shared Phase 1 Evidence Foundation

**Purpose**: Publish Phase 1 quality evidence, structured findings, and fail-closed governance for the gates declared by the planning slice, without claiming later-phase User Story 2 scope.

**Independent Test**: Run `extensions/specrew-speckit/scripts/run-mechanical-checks.ps1` on a fixture iteration, confirm `specs/<feature>/iterations/<NNN>/quality/quality-evidence.md` and `mechanical-findings.json` are created, then verify `extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` fails when required evidence is missing and passes when evidence is complete.

- [X] T012 [P] Add findings-schema and demotion regression coverage in `tests/integration/mechanical-findings-contract.ps1` using fixtures in `tests/integration/fixtures/mechanical-findings-contract/` (Trace: FR-027, FR-028, FR-029, FR-030, FR-030a, Slice C1-C3)
- [X] T013 [P] Add lifecycle evidence and missing-evidence regression coverage in `tests/integration/quality-evidence-governance.ps1` using fixtures in `tests/integration/fixtures/quality-evidence-governance/` (Trace: FR-011, FR-012, Slice D1-D2)
- [X] T014 Implement deterministic dead-field, anti-pattern, and test-integrity rule execution with schema-compliant findings and `dispositionRef` support in `extensions/specrew-speckit/scripts/run-mechanical-checks.ps1` (Trace: FR-027, FR-028, FR-029, FR-030, FR-030a, Slice C1-C3)
- [X] T015 Scaffold and publish `quality-evidence.md` and `mechanical-findings.json` in `extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1`, `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1`, and `extensions/specrew-speckit/scripts/run-mechanical-checks.ps1` (Trace: FR-011, FR-012, contracts/quality-governance-artifacts.md, Slice D1)
- [X] T016 Enforce required Phase 1 gate evidence, approved exceptions, and demotion visibility in `extensions/specrew-speckit/scripts/validate-governance.ps1` (Trace: FR-012, FR-030a, Slice D2)
- [X] T017 Keep the existing reporting regressions aligned with the Phase 1 evidence artifacts in `tests/integration/process-quality-scorer.ps1` and `tests/integration/process-quality-report.ps1` (Trace: FR-011, Verification Strategy)

**Checkpoint**: Reviewable lifecycle evidence exists for every declared Phase 1 gate, and governance fails closed on silent omissions.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Finalize the first-slice operator guidance and validation path after both in-scope story slices work end to end.

- [X] T018 Update `C:\Dev\Specrew\specs\005-stack-aware-quality-bar\quickstart.md` and `extensions\specrew-speckit\README.md` so the documented Phase 1 validation flow matches the implemented scaffold, findings, and governance commands (Trace: FR-011, FR-012, quickstart.md)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; start immediately.
- **Foundational (Phase 2 / Slice A)**: Depends on Setup; blocks all later work.
- **User Story 1 (Phase 3 / Slice B)**: Depends on Foundational.
- **Shared Evidence Foundation (Phase 4 / Slices C-D)**: Depends on User Story 1 because lifecycle evidence must enforce the gates declared by the planning artifacts.
- **Polish (Phase 5)**: Depends on both user-story phases completing.

### User Story Dependencies

- **US1**: Starts after Foundational; no dependency on other user stories.
- **Shared Phase 1 evidence work**: Starts after US1 because evidence and findings must align to the Phase 1 quality plan rendered by US1.

### Within Each Story

- Tests must be authored before the corresponding implementation tasks.
- Preset/lens asset scaffolding must complete before profile resolution starts.
- Profile resolution and plan rendering must complete before findings/evidence validation is finalized.
- Governance validation must consume the finalized findings and `quality-evidence.md` contract.

---

## Parallel Opportunities

- **Setup**: `T002` can run while `T001` creates the source roots.
- **Foundational**: `T003`, `T005`, `T006`, and `T007` can proceed in parallel once `T001` exists.
- **US1**: `T008` can be written before resolver work completes so it fails against the current plan output.
- **Shared evidence foundation**: `T012` and `T013` can be authored in parallel before `T014`-`T016`; `T017` can be prepared once the evidence artifact paths stabilize.

---

## Parallel Example: User Story 1

```text
Task: "T008 [US1] Add recognized-stack and bounded-custom-composition plan assertions in tests/integration/quality-profile-foundation.ps1"
Task: "T009 [US1] Implement stack-signal, risk-dimension, preset-selection, and bounded custom-composition resolution in extensions/specrew-speckit/scripts/resolve-quality-profile.ps1"
```

## Parallel Example: Shared Evidence Foundation

```text
Task: "T012 Add findings-schema and demotion regression coverage in tests/integration/mechanical-findings-contract.ps1"
Task: "T013 Add lifecycle evidence and missing-evidence regression coverage in tests/integration/quality-evidence-governance.ps1"
```

---

## Implementation Strategy

### MVP First (Phase 1 / First Slice)

1. Complete Setup.
2. Complete Foundational Slice A work.
3. Deliver **User Story 1** and validate the explicit Phase 1 quality profile in planning artifacts.
4. Deliver the **shared evidence foundation** and validate findings, evidence publication, and fail-closed governance.
5. Finish the quickstart/documentation reconciliation task.

### Incremental Delivery

1. Ship the shared registry and scaffold foundations first.
2. Add planning-time quality profile rendering (US1) and verify it independently.
3. Add deterministic findings, lifecycle evidence publication, and governance enforcement without introducing Phase 2+ workflows.

### Scope Guardrails

- Do **not** add Phase 2 hardening-gate, bug-hunter lens execution, strongest-class routing, or known-traps corpus tasks in this file.
- Do **not** add Phase 3 override, mixed-stack fallback, or quality-drift automation tasks in this file beyond the bounded Phase 1 custom-composition behavior already planned.
- Keep deterministic mechanical checks in the Phase 1 subset of US2 because this slice uses them as lifecycle evidence inputs, not as later-phase bug-hunter routing.

---

## Execution Metadata

**Effort Unit**: `story_points`

| Task ID | Owner | Effort |
| --- | --- | --- |
| T001 | Spec Steward | 1 |
| T002 | Implementer | 1 |
| T003 | Reviewer | 2 |
| T004 | Implementer | 3 |
| T005 | Spec Steward | 2 |
| T006 | Planner | 3 |
| T007 | Spec Steward | 1 |
| T008 | Reviewer | 2 |
| T009 | Planner | 3 |
| T010 | Spec Steward | 2 |
| T011 | Planner | 2 |
| T012 | Reviewer | 2 |
| T013 | Reviewer | 2 |
| T014 | Implementer | 5 |
| T015 | Reviewer | 3 |
| T016 | Reviewer | 3 |
| T017 | Reviewer | 2 |
| T018 | Spec Steward | 1 |

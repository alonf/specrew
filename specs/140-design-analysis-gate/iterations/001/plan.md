# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 20/20 story_points
**Started**: 2026-06-02
**Completed**:

## Scope Summary

Iteration 001 implements the first slice of the design-analysis gate: a reusable artifact helper, active plan-boundary sync enforcement, focused validation tests, and narrow coordinator guidance. The selected architecture remains Option B from the feature plan: helper plus active plan-boundary sync enforcement. Prompt-only enforcement is not acceptable for this slice.

The protected implementation core is T003-T012. Capacity reconciliation during implementation deferred T014 command/workflow metadata first. Broad validator rollout, all existing/in-flight project enforcement, full Proposal 137, broad multi-host slash-command deployment, Unix wrapper/install work, bootstrap work, and release publishing remain out of scope.

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-001-FR-002 | Add the design-analysis lifecycle stop with a simple substantive/trivial applicability rule. | US1, US3 |
| FR-003-FR-008 | Create and validate the per-iteration design-analysis artifact, alternatives, option fields, diagrams, and Crew recommendation. | US1, US2, US3 |
| FR-009-FR-012 | Require and preserve explicit human option selection before plan starts, and make the selected option authoritative plan input. | US1, US2 |
| FR-013-FR-017 | Add focused tests for artifact creation, required sections, alternatives, recommendation, and plan-boundary blocking. | US3 |
| FR-018-FR-021 | Preserve first-slice limits, avoid excluded surfaces, avoid release publishing, and document compatibility for existing/in-flight projects. | US3 |
| TG-001-TG-006 | Maintain traceability, scope discipline, drift handling, and review classification of implemented/enforced/observable/documented behavior. | US1, US2, US3 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T001 | Confirm scope, Option B, and overrun handling before implementation | FR-018, FR-019, FR-020, FR-021, TG-004, TG-005, SC-011, SC-012, SC-013 | US0 | 1 | Spec Steward | `specs/140-design-analysis-gate/**` | done | codex | Option B, protected core, first deferral candidate, and excluded surfaces confirmed. | pass |
| T002 | Add first-slice applicability constants and excluded-surface guard comments | FR-002, FR-018, FR-019, FR-020, TG-005, SC-011, SC-012 | US0 | 1 | Implementer | `scripts/internal/design-analysis-gate.ps1` | done | codex | Helper constrains enforcement to the first-slice active plan-boundary path. | pass |
| T003 | Create design-analysis artifact validator with required top-level sections | FR-003, FR-004, FR-013, FR-014, SC-001, SC-002, SC-010 | US1 | 2 | Implementer | `scripts/internal/design-analysis-gate.ps1` | done | codex | Validator requires populated problem framing, decision points, alternatives, Crew recommendation, and Human Decision. | pass |
| T004 | Validate Simplest/Reasonable options, required option fields, conditional By-the-book, and diagram evidence | FR-005, FR-006, FR-007, FR-015, SC-003, SC-004, SC-005, SC-010 | US1 | 2 | Implementer | `scripts/internal/design-analysis-gate.ps1` | done | codex | Option validation covers Simplest, Reasonable, conditional By-the-book rationale, required fields, and diagram evidence. | pass |
| T005 | Validate populated recommendation and Human Decision evidence | FR-008, FR-009, FR-011, FR-016, SC-006, SC-008, SC-010 | US1, US2 | 1 | Implementer | `scripts/internal/design-analysis-gate.ps1` | done | codex | Recommendation and Human Decision validation reject placeholders and require selected option, reason/modifications, verdict, and commit hash. | pass |
| T006 | Wire helper into the active plan-boundary sync path and fail closed for missing active evidence | FR-001, FR-002, FR-010, FR-017, SC-001, SC-007, SC-010 | US1 | 2 | Implementer | `scripts/internal/sync-boundary-state.ps1` | done | codex | Plan-boundary sync invokes the helper before lifecycle state mutation. | pass |
| T007 | Read selected option/modifications from design-analysis evidence for downstream plan input or sync evidence | FR-011, FR-012, SC-008, SC-009 | US2 | 1 | Implementer | `scripts/internal/sync-boundary-state.ps1`, `scripts/internal/design-analysis-gate.ps1` | done | codex | Artifact validation result extracts the chosen option for gate evidence. | pass |
| T008 | Keep compatibility narrow so historical/in-flight projects do not hard-fail solely for missing artifacts | FR-002, FR-018, FR-021, SC-012, SC-013 | US3 | 1 | Implementer | `scripts/internal/sync-boundary-state.ps1`, `scripts/internal/design-analysis-gate.ps1` | done | codex | Compatibility skips legacy baselines and unrelated active-feature contexts unless an artifact opted in. | pass |
| T009 | Add unit tests and fixtures for artifact presence, sections, alternatives, option fields, and By-the-book conditionality | FR-003, FR-004, FR-005, FR-006, FR-007, FR-013, FR-014, FR-015, SC-001, SC-002, SC-003, SC-004, SC-005, SC-010 | US1, US3 | 2 | Implementer | `tests/unit/design-analysis-gate.tests.ps1`, `tests/fixtures/**` | done | codex | Unit coverage proves artifact presence, sections, alternatives, option fields, and conditional By-the-book handling. | pass |
| T010 | Add unit tests for recommendation and Human Decision validation | FR-008, FR-009, FR-011, FR-016, SC-006, SC-008, SC-010 | US2, US3 | 1 | Implementer | `tests/unit/design-analysis-gate.tests.ps1`, `tests/fixtures/**` | done | codex | Unit coverage rejects placeholder recommendation, missing Human Decision, and missing decision commit hash. | pass |
| T011 | Add integration tests for active plan-boundary block/pass and compatibility skip/warn behavior | FR-010, FR-017, FR-018, FR-021, SC-007, SC-010, SC-012, SC-013 | US3 | 2 | Implementer | `tests/integration/design-analysis-boundary.tests.ps1` | done | codex | Integration coverage proves missing artifact blocks without state advancement, valid artifact passes, and compatibility skips hold. | pass |
| T012 | Preserve boundary-sync atomicity and verdict-history coverage | FR-010, FR-011, FR-017, TG-006, SC-007, SC-008, SC-010 | US0 | 1 | Reviewer | `tests/integration/boundary-sync-atomic.tests.ps1` | done | codex | Existing boundary-sync atomicity regression remains passing. | pass |
| T013 | Update generated lifecycle guidance for the design-analysis stop and verdict shape | FR-001, FR-008, FR-009, FR-012, SC-006, SC-008, SC-009 | US1, US2 | 1 | Spec Steward | `scripts/specrew-start.ps1` | done | codex | Start prompt guidance includes the design-analysis stop and required verdict shape. | pass |
| T014 | Update only cheap existing command/workflow metadata if the narrow pattern is obvious | FR-001, FR-018, FR-021, TG-005, SC-012, SC-013 | US0 | 1 | Spec Steward | `extensions/specrew-speckit/commands/**`, `.specify/extensions/specrew-speckit/commands/**` | deferred | codex | Deferred first during implementation capacity reconciliation; command/workflow metadata edits were not retained. | deferred |
| T015 | Refresh quickstart/contract compatibility notes after implementation details stabilize | FR-018, FR-021, TG-004, TG-005, SC-010, SC-012, SC-013 | US3 | 1 | Planner | `specs/140-design-analysis-gate/quickstart.md`, `specs/140-design-analysis-gate/contracts/design-analysis-gate.md` | done | codex | Quickstart and contract document the helper API, active applicability rule, and compatibility path. | pass |
| T016 | Run governance validation and confirm excluded surfaces were not touched | FR-019, FR-020, TG-006, SC-011 | US0 | 1 | Reviewer | `specs/140-design-analysis-gate/iterations/001/**` | done | codex | Mechanical checks and governance validation passed; excluded install/wrapper/bootstrap/release surfaces were not touched. | pass |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Requirements remain fixed for this iteration. |
| Time Limit (hours) | n/a | Not applicable. |
| Overcommit Threshold | 1.0 | Warn when planned effort exceeds 20 story_points. |
| Defer Strategy | manual | Defer only with explicit human approval. |
| Calibration Enabled | true | Retrospective should suggest future capacity adjustments. |

## Dependency and Sequencing

- T001-T002 establish scope and helper guardrails before lifecycle behavior changes.
- T003-T005 implement the artifact helper before boundary sync consumes it.
- T006-T008 implement active plan-boundary enforcement and compatibility; keep these serial because they touch shared lifecycle state.
- T009-T012 prove the protected core with focused unit/integration coverage before command metadata polish.
- T013-T014 are guidance/metadata polish. If capacity overruns, T014 is the first deferral candidate.
- T015-T016 close documentation and governance evidence after implementation stabilizes.

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Shared-surface conflict risk is high around `scripts/internal/sync-boundary-state.ps1`; keep T006-T008 serial.
- T009 and T010 fixture/test work can be prepared in parallel after T003-T005 define the helper contract.
- T015 and T016 can proceed in parallel after implementation stabilizes.
- No Junior/Senior same-specialty expansion is proposed for this slice.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| --- | --- | --- |
| Discovery/Scope Guardrails | 2 | T001-T002 confirm scope, exclusions, and helper boundary. |
| Implementation | 7 | T003-T008 and T013 implement helper, sync enforcement, compatibility, and guidance. |
| Tests | 6 | T009-T012 cover helper, decision evidence, boundary blocking, and atomicity. |
| Documentation | 1 | T015 refreshes quickstart and contract only after implementation details settle. |
| Review/Governance | 2 | T016 plus expected review evidence and excluded-surface checks. |

## Traceability Summary

- Traceability status before implementation: PASS.
- Tasks checked: 16.
- Spec FR/SC entries covered: 34/34.
- Orphan tasks: none.
- Uncovered FR/SC entries: none.

## Readiness Notes

- **Overall Verdict**: ready
- **Capacity**: 20/20 story_points after deferring T014.
- **Protected core**: T003-T012 are not deferrable without explicit human approval.
- **First deferral candidate**: T014 command/workflow metadata; deferred during implementation capacity reconciliation.
- **Compatibility scope**: active-iteration plan-boundary enforcement only; broad validator rollout and all existing/in-flight project hard enforcement remain deferred.
- **Scope exclusions**: no Unix install, shell wrapper, bootstrap, beta publish, or stable publish surfaces are planned.
- **Implementation hold**: source implementation must not start until the human explicitly approves the before-implement readiness gate.

# Iteration Plan: 001 - Canonical Schema Enforcement and Graceful Structured Errors

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: executing  
**Capacity**: 13/20 story_points  
**Planned Start**: 2026-05-12  
**Started**: 2026-05-12  
**Completed**: pending  
**Closed**: pending  
**Hardening-Gate Sign-Off**: signed-2026-05-12  
**Implementation Authorization**: authorized-2026-05-12  
**Review Completed**: pending  
**Review Verdict**: pending  
**Retrospective Completed**: pending  
**Closeout Validation**: pending

## Summary

Deliver the first validator-hardening slice: canonical iteration `state.md` schema enforcement, canonical hardening-gate concern enforcement, graceful structured FAIL reporting, and the fixture-backed replay coverage needed to prove those rules without changing the existing validator command surface. Approval-evidence reuse checks, over-claim enforcement, bookkeeping classification, and corpus graduation remain deferred to iteration 002.

## Iteration Scope

| Category | Coverage | Boundary |
| --- | --- | --- |
| **User Stories** | US1 (canonical iteration metadata), US2 (canonical hardening-gate concerns) | US3-US5 deferred to iteration 002 |
| **Tasks** | T001-T013 | T014-T029 deferred to iteration 002 |
| **Primary Surfaces** | `validate-governance.ps1`, `shared-governance.ps1`, feature-local contracts, iteration-1 fixture manifests, `validator-hardening-iteration1.ps1`, `validator-hardening-iteration2.ps1` harness scaffolding | Over-claim checks, approval-reuse checks, `.github/copilot-instructions.md` classifier, and corpus graduation remain deferred |
| **Feature Goals** | FR-001, FR-002, FR-005, FR-008 slice 1, FR-009, FR-010 slice 1 | FR-003, FR-004, FR-006, FR-007, FR-008 slice 2, FR-010 slice 2 deferred |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T001 | Record the six-script baseline and current validator behavior | FR-010, TG-007, SC-005 | Foundation | 1 | Reviewer | done | 1 | pass |
| T002 | Reconfirm feature scope and initialize trap reapplication follow-through | FR-007, FR-010, TG-001, TG-002, TG-003, TG-004, TG-005, SC-007 | Foundation | 0.5 | Planner | done | 0.5 | pass |
| T003 | Build structured FAIL helpers and exception-wrapping support | FR-005, TG-008, SC-005 | Foundation | 2 | Validator maintainer | done | 2 | pass |
| T004 | Scaffold the shared integration harness for iteration 001 and iteration 002 | FR-008, FR-010, TG-007, TG-008, SC-005, SC-006 | Foundation | 1 | Test maintainer | done | 1 | pass |
| T005 | Reconcile the canonical contracts with the data model and plan | FR-009, TG-001, TG-002, SC-001, SC-002 | Foundation | 0.5 | Governance-contract steward | done | 0.5 | pass |
| T006 | Create compliant and violating iteration-state fixtures | FR-001, FR-008, TG-001, SC-001 | US1 | 1 | Test maintainer | done | 1 | pass |
| T007 | Add canonical-schema assertions to `validator-hardening-iteration1.ps1` | FR-001, FR-008, TG-001, TG-008, SC-001, SC-005 | US1 | 1 | Test maintainer | done | 1 | pass |
| T008 | Implement canonical iteration metadata detection and grandfathering | FR-001, FR-009, TG-001, SC-001 | US1 | 2 | Validator maintainer | done | 2 | pass |
| T009 | Record schema-rule evidence in `quickstart.md` | FR-001, FR-010, TG-001, SC-001, SC-005 | US1 | 0.5 | Reviewer | done | 0.5 | pass |
| T010 | Create compliant and violating hardening-gate fixtures | FR-002, FR-008, TG-002, SC-002 | US2 | 1 | Test maintainer | done | 1 | pass |
| T011 | Add canonical-concern assertions to `validator-hardening-iteration1.ps1` | FR-002, FR-008, TG-002, TG-008, SC-002, SC-005 | US2 | 1 | Test maintainer | done | 1 | pass |
| T012 | Implement first-five canonical concern enforcement | FR-002, FR-009, TG-002, SC-002 | US2 | 1 | Validator maintainer | done | 1 | pass |
| T013 | Record hardening-gate evidence in `quickstart.md` | FR-002, FR-010, TG-002, SC-002, SC-005 | US2 | 0.5 | Reviewer | done | 0.5 | pass |

**Total Effort**: 13 story_points

## Quality Gates

| Gate | Status | Evidence |
| --- | --- | --- |
| Hardening-gate drafted with canonical concerns first | pass | `iterations/001/quality/hardening-gate.md` signed off 2026-05-12 |
| Canonical `state.md` metadata schema in use from planning onward | pass | `iterations/001/state.md` uses the eight canonical fields in the metadata header |
| Iteration-1 replay coverage scoped and bounded | pass | `tests/integration/validator-hardening-iteration1.ps1` now proves compliant, violating, grandfathered, missing-file, and unexpected-input paths through actual validator output |
| Additive validator CLI surface preserved | pass | Shared regressions plus repo-wide `validate-governance.ps1 -ProjectPath .` stayed green after the Iteration 001 implementation landed |
| Existing validator regression baseline captured before implementation | pass | T001 recorded the six-script baseline on 2026-05-12 with repo-wide `validate-governance.ps1 -ProjectPath .` green |

## Risk Tracking

| Risk | Mitigation | Status |
| --- | --- | --- |
| Canonical-schema enforcement regresses pre-existing iterations | Grandfather pre-rollout iterations and prove that path in fixtures | mitigation-planned |
| Structured FAIL work leaks raw PowerShell exceptions | Build shared exception wrapping first, then assert malformed and missing-file cases in the replay harness | mitigation-planned |
| Hardening-gate rule enforces the wrong concern order | Use `contracts/hardening-gate-concerns.md` as the normative source and prove exact first-five ordering in fixtures | mitigation-planned |
| Iteration-1 work drifts into iteration-2 scope | Keep approval reuse, over-claim, classifier, and corpus graduation explicitly deferred in every planning artifact | mitigation-planned |
| Existing validator behavior regresses while new rules land | Capture T001 baseline and require `validate-governance.ps1 -ProjectPath .` to stay green through reviewer proof tasks | mitigation-planned |

## Dependencies

- T001 and T002 establish the approved baseline and bounded scope.
- T003, T004, and T005 are shared prerequisites for the rule-specific work.
- T006 and T007 must land before T008 evidence is considered complete.
- T010 and T011 must land before T012 evidence is considered complete.
- T009 and T013 record the reviewer evidence after their respective validation lanes pass.

## Explicit Deferrals

- Approval-evidence reuse detection and its corpus graduation are deferred to iteration 002.
- Over-claim and dirty-tree enforcement are deferred to iteration 002.
- `.github/copilot-instructions.md` bookkeeping classification is deferred to iteration 002.
- Known-traps graduation is deferred to iteration 002.
- Any implementation work is deferred until hardening-gate sign-off and explicit implementation authorization are recorded.

## Implementation Authorization

- **Authorization Verdict**: ✅ **AUTHORIZED**
- **Authorized By**: Alon Fliess
- **Recorded Evidence**: "I authorize feature 013 validator-hardening iteration 001 (canonical-schema and graceful-error slice — implement canonical iteration state.md schema enforcement, implement canonical hardening-gate concerns enforcement, maintain the canonical schema contracts under specs/013-validator-hardening/contracts/, replace PowerShell parameter-binding failures and exceptions with structured FAIL lines that name file/line/category/remediation, preserve all existing validator CLI surface and behavior, add scaffold-replay-path integration test coverage for both the schema rules and the graceful error reporting — tasks T001 through T013 per the iteration 001 plan) implementation, review, retrospective, and closeout."
- **Recorded Date**: 2026-05-12
- **Gate Reference**: `specs/013-validator-hardening/iterations/001/quality/hardening-gate.md`
- **Scope Authorized**: Iteration 001 canonical-schema and graceful-error slice (`T001-T013`, 13 story_points)
- **Authorization Effect**: Pre-implementation governance sign-off is complete and the lifecycle may advance to the before-implement gate and execution start.

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies |
| Iteration Bounding | scope | Keep iteration 001 fixed to the canonical-schema and graceful-error slice |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time` |
| Overcommit Threshold | 1.0 | Warn when planned effort exceeds the configured capacity |
| Defer Strategy | manual | Iteration 002 carries the explicitly deferred validator-hardening rules |
| Calibration Enabled | true | Actual effort should be recorded after execution completes |

## Implementation Boundary Result

| Area | Evidence |
| --- | --- |
| Structured FAIL output | `shared-governance.ps1` now formats structured FAIL records, and `validate-governance.ps1` surfaces canonical-schema, concern-order, missing-artifact, and unexpected-input failures without raw PowerShell exception output. |
| Canonical iteration metadata enforcement | `tests/integration/fixtures/013-validator-hardening/state-*` plus `tests/integration/validator-hardening-iteration1.ps1` prove canonical pass cases, non-canonical alias detection, missing-field failures, and grandfathered legacy acceptance. |
| Canonical hardening-gate concern enforcement | `tests/integration/fixtures/013-validator-hardening/hardening-gate-*` plus the replay harness prove the first five canonical concerns stay ordered while allowing feature-specific rows after position five. |
| Regression preservation | `tests/integration/hardening-gate-contract.ps1`, `tests/integration/quality-evidence-governance.ps1`, `tests/integration/project-path-resolution-regression.ps1`, `tests/integration/validator-hardening-iteration1.ps1`, and `validate-governance.ps1 -ProjectPath .` all passed on 2026-05-12. |

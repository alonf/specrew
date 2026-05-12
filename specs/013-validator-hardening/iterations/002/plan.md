# Iteration Plan: 002 - Approval-Reuse Detection, Over-Claim Detection, and Bookkeeping-vs-Behavior Classifier

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: reviewing  
**Capacity**: 15.5/20 story_points  
**Planned Start**: 2026-05-12  
**Started**: 2026-05-12  
**Completed**: pending  
**Closed**: pending  
**Hardening-Gate Sign-Off**: signed (2026-05-12 by Alon Fliess)  
**Implementation Authorization**: authorized (T014-T029, 15.5 story_points)  
**Review Completed**: 2026-05-12  
**Review Verdict**: accepted  
**Retrospective Completed**: pending  
**Closeout Validation**: 2026-05-12 (implementation-boundary lane; final closure still pending review/retro artifacts)

## Summary

Deliver the second and final validator-hardening implementation slice: approval-evidence reuse detection, unsupported closeout claim blocking (over-claim detection and dirty-tree enforcement), the `.github/copilot-instructions.md` bookkeeping-vs-behavior classifier, canonical corpus graduation (marking iteration 001 rules as validator-enforced), final documentation updates, and the implementation-boundary validation lane. The implementation boundary is complete and the independent review is now accepted on 2026-05-12; retrospective and final closeout intentionally remain pending separate authorization and follow-through.

## Iteration Scope

| Category | Coverage | Boundary |
| --- | --- | --- |
| **User Stories** | US3 (approval-reuse detection), US4 (over-claim detection), US5 (bookkeeping classifier), US-Polish (polish, corpus graduation, closeout validation) | Iteration 002 is the final iteration for feature 013 |
| **Tasks** | T014-T029 | No deferrals; iteration 002 covers the complete remaining feature scope |
| **Primary Surfaces** | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `extensions/specrew-speckit/scripts/shared-governance.ps1`, `extensions/specrew-speckit/scripts/Test-CopilotInstructionsChangeType.ps1`, `scripts/specrew-start.ps1`, feature-local fixtures, `tests/integration/validator-hardening-iteration2.ps1`, iteration-2 fixture manifests, `.specrew/quality/known-traps.md`, `specs/013-validator-hardening/plan.md`, `specs/013-validator-hardening/quickstart.md`, `specs/013-validator-hardening/quality/trap-reapplication.md`, full closeout validation lane (quality-profile-foundation, hardening-gate-contract, quality-evidence-governance, validation-contract-lane, project-path-resolution-regression, validator-hardening-iteration1, validator-hardening-iteration2) | All feature work included; no deferrals |
| **Feature Goals** | FR-003 (approval-reuse), FR-004 (over-claim detection), FR-006 (bookkeeping classifier), FR-007 (corpus graduation), FR-008 slice 2 (fixtures), FR-010 slice 2 (evidence recording) | Iteration 002 is the final iteration; all remaining feature scope is included |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T014 | Create sibling-iteration approval fixtures | FR-003, FR-008, TG-003, SC-003 | US3 | 1 | Test maintainer | done | 1 | pass |
| T015 | Add approval-reuse assertions to validator-hardening-iteration2.ps1 | FR-003, FR-008, TG-003, TG-008, SC-003, SC-005 | US3 | 1 | Test maintainer | done | 1 | pass |
| T016 | Implement approval-reuse detection and normalized-quote matching | FR-003, FR-005, TG-003, SC-003, SC-005 | US3 | 2 | Validator maintainer | done | 2 | pass |
| T017 | Classify approval-reuse as validator-enforced and mark in known-traps.md | FR-007, TG-003, TG-006, SC-007 | US3 | 0.5 | Governance-corpus steward | done | 0.5 | pass |
| T018 | Create closeout-evidence and dirty-tree fixtures | FR-004, FR-008, TG-004, SC-004 | US4 | 1 | Test maintainer | done | 1 | pass |
| T019 | Add over-claim assertions to validator-hardening-iteration2.ps1 | FR-004, FR-008, TG-004, TG-008, SC-004, SC-005 | US4 | 1 | Test maintainer | done | 1 | pass |
| T020 | Implement closeout-evidence validation and scoped dirty-tree filtering | FR-004, FR-005, TG-004, SC-004, SC-005 | US4 | 2 | Validator maintainer | done | 2 | pass |
| T021 | Classify over-claim as validator-enforced and mark in known-traps.md | FR-007, TG-004, TG-006, SC-007 | US4 | 0.5 | Governance-corpus steward | done | 0.5 | pass |
| T022 | Create .github/copilot-instructions.md diff fixtures | FR-006, FR-008, TG-005, SC-006 | US5 | 1 | Test maintainer | done | 1 | pass |
| T023 | Extend validator-hardening-iteration2.ps1 with classifier coverage and compatibility assertions | FR-006, FR-010, TG-005, SC-006 | US5 | 1 | Test maintainer | done | 1 | pass |
| T024 | Implement Test-CopilotInstructionsChangeType.ps1 and integrate into specrew-start.ps1 | FR-006, TG-005, SC-006 | US5 | 1 | Restart-policy steward | done | 1 | pass |
| T025 | Wire classifier into validate-governance.ps1 as additive compatibility validation | FR-006, FR-010, TG-005, TG-007, SC-006 | US5 | 0.5 | Validator maintainer | done | 0.5 | pass |
| T026 | Run classifier and validator tests; record evidence in quickstart.md | FR-006, FR-010, TG-005, SC-006 | US5 | 0.5 | Reviewer | done | 0.5 | pass |
| T027 | Mark canonical-schema and canonical-concern rows as validator-enforced in known-traps.md | FR-001, FR-002, FR-007, TG-006, SC-007 | US-Polish | 0.5 | Governance-corpus steward | done | 0.5 | pass |
| T028 | Update feature documentation: plan.md, quickstart.md, trap-reapplication.md | FR-007, FR-010, TG-006, SC-007 | US-Polish | 1 | Documentation maintainer | done | 1 | pass |
| T029 | Run full closeout validation lane and audit final diff | FR-010, TG-007, SC-001, SC-002, SC-003, SC-004, SC-005, SC-006, SC-007 | US-Polish | 1 | Reviewer | done | 1 | pass |

**Total Effort**: 15.5 story_points

## Quality Gates

| Gate | Target | Notes |
| --- | --- | --- |
| Approval-reuse detection with normalization | required | Whitespace-normalized and markdown-emphasis-stripped quote matching; explicit blanket-authorization exemptions; structured FAIL output |
| Over-claim detection and dirty-tree enforcement | required | Closed-status iteration validation; required review/retro/hardening evidence checks; iteration-directory-scoped git status; `.squad/decisions.md` and `.squad/identity/now.md` remain evidence-only |
| Bookkeeping-vs-behavior classifier | required | Distinguishes timestamp-only, `## Active Technologies`, `## Recent Changes` updates from behavior-affecting modifications; integrated into restart guidance without changing validator surface |
| Iteration-2 replay coverage scoped and bounded | required | `tests/integration/validator-hardening-iteration2.ps1` now proves approval-reuse, over-claim, classifier compliance, and unexpected-input paths |
| Additive validator CLI surface preserved | required | Shared regressions plus repo-wide `validate-governance.ps1 -ProjectPath .` must stay green; iteration 001 rules remain stable and compliant |
| All blocking concerns addressed | required | Post-implementation verification against the hardening-gate artifact; pre-implementation design evidence recorded before authorization |

## Risk Tracking

| Risk | Mitigation | Status |
| --- | --- | --- |
| Approval-reuse normalization over-matches legitimate distinct quotes | Define exact whitespace and markdown-emphasis normalization rules in shared-governance.ps1; prove normalization matches both duplicated quotes and preserves distinct ones in fixtures | mitigation-planned |
| Dirty-tree check over-broadens and blocks legitimate evidence paths | Scope dirty-tree filtering to iteration-directory only; explicitly exclude `.squad/decisions.md` and `.squad/identity/now.md` as evidence-only inputs rather than dirt | mitigation-planned |
| Bookkeeping classifier breaks restart guidance workflow | Integrate the classifier into `specrew-start.ps1` as the authoritative source; keep validator-side validation additive only; test that non-behavior changes do not trigger restart messages | mitigation-planned |
| Over-claim rules regress iteration 001 compliance | Preserve canonical-schema and canonical-concern rules stable from iteration 001; run full repo-wide validator after iteration 2 changes land; maintain additive-only semantics | mitigation-planned |
| Iteration-2 replay harness couples to live iteration state | Keep scratch-workspace templates normalized to pending lifecycle fields inside the harness; replay fixtures test validator rules, not the current state of real iteration artifacts | mitigation-planned |
| Approval-reuse or over-claim rules break on historical iterations | Scope rules to feature ordinal `013` and later; grandfather pre-feature-013 iterations consistently with iteration 001 rules | mitigation-planned |

## Dependencies

- T014 and T015 are prerequisites for T016 evidence; T017 depends on T016 being landed.
- T018 and T019 are prerequisites for T020 evidence; T021 depends on T020 being landed.
- T022 and T023 are prerequisites for T024 evidence; T025 depends on T024 being landed.
- T016, T020, T024, and T025 all depend on the iteration 001 structured FAIL foundation (T003 from iteration 001) remaining stable.
- All user-story tests (T015, T019, T023) must land before their respective implementation tasks (T016, T020, T024) so replay fixtures drive validator behavior.

## Explicit Deferrals

None. Iteration 002 is the final authorized iteration for feature 013, validator hardening. All remaining scope (approval-reuse, over-claim, bookkeeping-classifier core implementation, corpus graduation for canonical-schema/canonical-concern/approval-reuse/over-claim rows, final documentation updates, and full closeout validation lane) is included in this iteration. Implementation, review, retrospective, and final closeout are future steps but within the same iteration planning boundary.

## Implementation Authorization

- **Authorization Verdict**: ✅ **AUTHORIZED** — hardening-gate sign-off completed by Alon Fliess on 2026-05-12
- **Scope Authorized**: Iteration 002 approval-reuse, over-claim, bookkeeping-classifier, corpus-graduation, documentation, and closeout-validation slice (`T014-T029`, 15.5 story_points)
- **Gate Reference**: `specs/013-validator-hardening/iterations/002/quality/hardening-gate.md`
- **Next Action**: Begin implementation with T014-T029 scope only; no scope expansion beyond approval-reuse detection, over-claim detection, bookkeeping-classifier, corpus graduation, documentation updates, and closeout validation lane

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies; iteration 002 stays within capacity while covering the full remaining authorized slice |
| Iteration Bounding | scope | Keep iteration 002 fixed to full remaining feature scope (T014-T029) |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time` |
| Overcommit Threshold | 1.0 | The default threshold remains in force because the corrected effort mapping keeps the iteration within capacity |
| Defer Strategy | manual | No deferrals remain, but the iteration model still uses manual scope management |
| Calibration Enabled | true | Actual effort should be recorded after execution completes |

## Implementation Boundary Result

| Area | Evidence |
| --- | --- |
| Approval-reuse detection | `shared-governance.ps1` now extracts implementation-authorization evidence from iteration `plan.md` / `state.md`, normalizes whitespace and markdown emphasis, honors explicit blanket multi-iteration authorization scope lines, and `validate-governance.ps1` emits `approval-reuse` FAIL records naming both sibling iterations when normalized quotes match. |
| Over-claim detection | `validate-governance.ps1` now treats closure-oriented `Iteration Status` text as a closeout claim, requires accepted `review.md`, `retro.md`, recorded hardening-gate verification, and filters dirty-tree checks to canonical artifacts under the iteration directory only. Repo-level evidence-only files such as `.squad/decisions.md` remain outside the dirty-tree blocker. |
| Bookkeeping classifier | `extensions/specrew-speckit/scripts/Test-CopilotInstructionsChangeType.ps1` classifies `.github/copilot-instructions.md` changes as `bookkeeping` or `behavior`, `specrew-start.ps1` now pauses only for behavior-affecting changes, and `validate-governance.ps1` smoke-checks helper compatibility without changing the validator CLI surface. |
| Iteration-2 replay coverage | `tests/integration/validator-hardening-iteration2.ps1` exercises duplicate normalized approval quotes, blanket authorization exemptions, clean/dirty closeout evidence, repo-level evidence-only dirt, direct classifier fixtures, and the `specrew-start.ps1` no-launch replay path. |
| Regression preservation | `tests/integration/validator-hardening-iteration1.ps1`, the Specrew start regression suite, and repo-wide `validate-governance.ps1 -ProjectPath .` all stayed green after the new rules landed. |
| Corpus graduation | `.specrew/quality/known-traps.md` now marks approval-reuse, over-claim, canonical-schema, and canonical-concern rows as validator-enforced with citations to the implementing scripts and replay-path tests. |
| Documentation updates | `quickstart.md`, this iteration plan, the hardening gate, trap reapplication artifact, decision inbox note, and implementer history now record the implementation-boundary evidence without claiming review, retrospective, or closeout completion. |

## Notable Artifacts from Iteration 001

- Review-repair commit `f7a0f4e` (lowercase canonical-label precision fix) is notable dogfooding evidence for the classifier/start-guidance iteration 002 closeout retrospective.
- Iteration 001's structured FAIL surface (`shared-governance.ps1` and `validate-governance.ps1`) is the stable foundation that iteration 002 builds upon.
- The replay harness pattern from iteration 001 (scratch workspaces, fixture-driven tests, user-visible assertions) carries forward unchanged through iteration 002 closeout.

# Iteration Plan: 002 — Replay-Path Integration, Corpus Seeding, and Documentation Polish

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: complete  
**Capacity**: 8/20 story_points  
**Planned Start**: 2026-05-12  
**Started**: 2026-05-12  
**Completed**: 2026-05-12  
**Closed**: 2026-05-12  
**Review Completed**: 2026-05-12  
**Review Verdict**: accepted
**Hardening-Gate Sign-Off**: signed-2026-05-12  
**Implementation Authorization**: authorized-2026-05-12
**Retrospective Completed**: 2026-05-12  
**Closeout Validation**: green-2026-05-12

## Summary

Iteration 002 carries the bounded follow-on slice for feature `012-descriptive-id-handoffs`: replay-path integration coverage, known-traps corpus seeding, feature-level quality follow-through evidence, and documentation polish. The scope stays strictly limited to tasks `T012` through `T020`; Iteration 003 is not scaffolded here, and the feature is now closed through the approved two-iteration plan.

This iteration started after Iteration 001's readable-reference rollout stayed stable. The planning-time hardening gate under `iterations/002/quality/` remains the authorization record, and the implementation slice is now complete with replay-path tests, corpus/documentation updates, feature-level follow-through artifacts, the recorded retrospective, and a green closeout validation lane on disk. Iteration 002 is now closed without widening the rule beyond authored prose.

## Iteration Scope

| Category | Coverage | Boundary |
| --- | --- | --- |
| **User Stories** | US3 (Governance checks reinforce readable references) plus bounded polish work | No new user stories; no Iteration 003 scaffolding |
| **Tasks** | `T012`-`T020` | No work outside replay-path integration, corpus seeding, quality follow-through, and documentation polish |
| **Primary Surfaces** | `tests/integration/descriptive-reference-*.ps1`, replay fixtures, `.specrew/quality/known-traps.md`, `extensions/specrew-speckit/governance/validation-lane.md`, `specs/012-descriptive-id-handoffs/quality/*`, `quickstart.md`, feature plan closeout notes | No changes to Iteration 001 guidance surfaces unless required by the approved T018-T020 polish tasks |
| **Feature Boundary** | Keep the rule additive, non-blocking, and limited to Squad-authored narration and stop messages | Do not widen to tool-rendered output, historical transcripts, or unrelated governance checks |

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
| --- | --- | --- | --- | --- |
| FR-006 | Excluded verbatim surfaces stay outside the descriptive-reference rule | ✅ `T014`, `T017`, `T020` | Test-infrastructure maintainer, Reviewer, Planner | Replay-path coverage must prove excluded surfaces stay ignored |
| FR-007 | Guidance and worked examples stay aligned to the rule | ✅ `T015`, `T018` | Quality governance maintainer, Documentation maintainer | Corpus seeds and documentation polish must preserve readable examples |
| FR-008 | Non-blocking governance review flags authored prose with opaque numeric references | ✅ `T012`, `T013`, `T015`, `T017` | Test-infrastructure maintainer, Quality governance maintainer, Reviewer | Replay-path fixtures and corpus seeds prove the low-noise warning path |
| FR-009 | Governance review distinguishes authored prose from excluded verbatim content | ✅ `T012`, `T013`, `T014`, `T017` | Test-infrastructure maintainer, Reviewer | Authored-prose and excluded-surface replay assertions are both required |
| FR-010 | Descriptive-reference behavior remains additive and must not weaken prior handoff-governance expectations | ✅ `T015`, `T016`, `T017`, `T019`, `T020` | Quality governance maintainer, Reviewer, Planner | Final audit and follow-through artifacts must show no regression |
| TG-003 | User Story 3 maps to FR-006, FR-008, FR-009, and FR-010 | ✅ `T012`-`T017` | Shared across iteration owners | Main execution slice for this iteration |
| TG-005 | Existing handoff-governance review behavior must remain compatible | ✅ `T017`, `T019`, `T020` | Reviewer, Planner | Replay lane and closeout lane must preserve feature 007 behavior |
| TG-006 | Planned slice must keep examples, governance review, and sampled acceptance checks aligned | ✅ `T012`-`T020` | Planner plus execution owners | Iteration 002 exists to deliver this proof without widening scope |

## Governance Consistency Check

| Gate | Verdict | Notes |
| --- | --- | --- |
| **Spec Authority** | ✅ PASS | Scope stays limited to the approved Iteration 002 backlog slice (`T012`-`T020`) from `tasks.md` |
| **Traceability** | ✅ PASS | Every in-scope task maps to FR/TG references and keeps US3 plus polish auditable |
| **Ownership** | ✅ PASS | Owners match the approved feature backlog roles and keep replay, corpus, documentation, and audit responsibilities separate |
| **Capacity** | ✅ PASS | 8/20 story_points using the established 1-point medium / 0.5-point small calibration |
| **Execution Support** | ✅ PASS | Iteration 001 is complete, the canonical state schema is preserved, and the pre-implementation hardening gate is drafted now rather than deferred into execution |

## Hardening Readiness Planning

**Slice Scope**: `iteration-002-replay-path-integration-corpus-seeding-and-documentation-polish`  
**Iteration Hardening Artifact**: `specs/012-descriptive-id-handoffs/iterations/002/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Follow-Through Artifact Paths**: `specs/012-descriptive-id-handoffs/quality/hardening-gate.md`, `specs/012-descriptive-id-handoffs/quality/trap-reapplication.md`

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status |
| --- | --- | --- | --- |
| Replay-path integration coverage | User Story 3 must prove the real authored-message review path, not just static fixtures | `tests/integration/descriptive-reference-authored-prose.ps1`, `tests/integration/descriptive-reference-excluded-surfaces.ps1`, replay fixtures, iteration hardening-gate concern evidence | required |
| Corpus seeding completeness | Known-traps updates are the durable anti-regression memory for this feature's low-noise rule | `.specrew/quality/known-traps.md`, `extensions/specrew-speckit/governance/validation-lane.md` | required |
| Documentation polish fidelity | Quickstart and plan notes must reflect the actual validation lane and follow-through artifact flow | `specs/012-descriptive-id-handoffs/quickstart.md`, feature plan closeout notes | required |
| Regression preservation | Iteration 002 must not weaken existing handoff-governance checks or Iteration 001 readable-reference rollout | Existing three handoff-governance tests plus new replay lane and final diff audit | required |
| Feature 007 integration continuity | The readable-reference proof slice still rides on feature 007's handoff-governance baseline | Replay lane, closeout lane, and final audit evidence | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `coordinator-handoff-governance` checklist | required | Replay-path proof must stay aligned with the live review checklist and validator behavior | `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`, replay assertions |
| `known-traps reapplication` | required | Iteration 002 seeds corpus rows and must preserve explicit follow-through evidence | `specs/012-descriptive-id-handoffs/quality/trap-reapplication.md` |
| `blocking-enforcement escalation` | not-applicable | FR-008 and FR-009 keep this rule non-blocking | none |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and replay-path review | strongest-available | strongest-available | none | Review depth may increase, but execution must preserve the non-blocking descriptive-reference rule |

### Explicit Later Deferrals

- Review, retrospective, and closeout artifacts remain out of scope for this planning boundary.
- No Iteration 003 artifacts are created here.
- Any expansion beyond replay-path integration, corpus seeding, feature-level quality follow-through, and documentation polish remains out of scope.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T012 | Create replay fixtures for authored prose warn/pass cases and excluded-surface coverage | FR-008, FR-009, SC-004, TG-006 | US3 | 1 | Test-infrastructure maintainer | done | 1 | pass |
| T013 | Add authored-prose replay assertions that exercise the real governance review path | FR-008, FR-009, TG-003, SC-004 | US3 | 1 | Test-infrastructure maintainer | done | 1 | pass |
| T014 | Add excluded-surface replay assertions proving verbatim content stays out of scope | FR-006, FR-009, TG-003, SC-004 | US3 | 1 | Test-infrastructure maintainer | done | 1 | pass |
| T015 | Seed descriptive-reference corpus examples and update validation-lane documentation | FR-007, FR-008, FR-009, TG-003, TG-006 | US3 | 1 | Quality governance maintainer | done | 1 | pass |
| T016 | Record feature-level quality follow-through artifacts for replay coverage, feature 007 compatibility, and corpus reapplication | FR-010, TG-006 | US3 | 1 | Quality governance maintainer | done | 1 | pass |
| T017 | Run the Iteration 002 replay lane and record low-noise governance evidence | SC-004, TG-003, TG-005, GOV-C1, GOV-C2, GOV-C3, GOV-C4, GOV-C5 | US3 | 1 | Reviewer | done | 1 | pass |
| T018 | Polish `quickstart.md` and feature plan notes with the final Iteration 002 validation lane and closeout instructions | TG-006 | Polish | 0.5 | Documentation maintainer | done | 0.5 | pass |
| T019 | Run the full closeout lane and record final evidence in quickstart plus trap reapplication | SC-001, SC-002, SC-004, TG-005 | Polish | 1 | Reviewer | done | 1 | pass |
| T020 | Audit the final diff to confirm additive, non-blocking, authored-prose-only scope preservation | FR-010, TG-004, TG-005 | Polish | 0.5 | Planner | done | 0.5 | pass |

**Total Effort**: 8 story_points

## Phase Baseline

| Phase | Estimated Effort |
| --- | --- |
| Planning | 1 |
| Discovery/Spikes | 0 |
| Implementation | 6 |
| Review | 1 |
| Rework | 0 |

## Planned Execution Order

1. `T012`, `T013`, `T014`, and `T015` can begin in parallel once implementation is authorized.
2. `T016` starts after replay coverage and corpus targets are stable enough to define the feature-level follow-through evidence cleanly.
3. `T017` runs the bounded replay lane after T012-T016 land.
4. `T018` can overlap with late US3 work once the final validation commands are known.
5. `T019` runs the full closeout lane after all prior implementation work completes.
6. `T020` is the final planner audit for additive, non-blocking, scope-preserving closeout.

## Deferred Follow-On

| Deferred Item | Target Iteration / Phase | Reason |
| --- | --- | --- |
| Retrospective artifact (`retro.md`) | Completed at the retrospective boundary | The replay-path and corpus follow-through learning is now recorded on the current tree |
| Closeout validation and closeout artifact | Completed at the closeout boundary | The full eight-command closeout lane is now recorded on the closeout tree |
| Any further follow-on slice after `T020` | Future planning only if explicitly authorized | Feature 012 is closed on the current tree; no Iteration 003 decision is made here |

## Implementation Authorization

- **Authorization Verdict**: ✅ **AUTHORIZED**
- **Authorized By**: Alon Fliess
- **Recorded Evidence**: "The user has given both approvals in the same message."
- **Recorded Date**: 2026-05-12
- **Gate Reference**: `specs/012-descriptive-id-handoffs/iterations/002/quality/hardening-gate.md` (signed off 2026-05-12)
- **Scope Authorized**: User Story 3 plus bounded polish (`T012`-`T020`, 8 story_points)
- **Authorization Effect**: Execution may proceed on the approved Iteration 002 slice; the next lifecycle boundary is implementation start

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies |
| Iteration Bounding | scope | Keep the slice fixed to replay/corpus/documentation follow-through work |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time` |
| Overcommit Threshold | 1.0 | Warn when planned effort exceeds the configured capacity |
| Defer Strategy | manual | Any future deferral must be explicit and traceable |
| Calibration Enabled | true | Actual effort should be recorded after execution completes |

## Concurrency Rationale

- Current roster snapshot: Test-infrastructure maintainer, Quality governance maintainer, Documentation maintainer, Reviewer, Planner
- Workstream separability: High. Fixtures, replay assertions, corpus/documentation updates, and final audits land in distinct surfaces.
- Shared-surface conflict risk: Moderate for the two replay-test scripts; keep T013 and T014 coordinated even if they start in the same window.
- Quality follow-through boundary: The planning-time iteration hardening gate is already created here, so T016 stays focused on post-implementation evidence in the feature-level quality artifacts rather than recreating the pre-implementation gate.
- Recommendation: Use the parallel window for T012-T015, then serialize evidence recording and validation (T016-T020).

## Notes

- This iteration exists to complete the approved Iteration 002 portion of the backlog only: replay-path integration tests, corpus seeding, quality follow-through, and documentation polish.
- The canonical Iteration 001 `state.md` metadata schema is intentionally preserved for Iteration 002 to avoid the validator regression caused by the older non-canonical format.
- The richer pre-sign-off hardening-gate convention from feature 008 iteration 005 is applied here; the gate remains `ready`, and the human sign-off metadata is now recorded in `quality/hardening-gate.md`.
- The accepted review boundary, completed retrospective, and green closeout lane are now recorded on the closeout tree.

## Implementation Boundary Result

| Area | Evidence |
| --- | --- |
| Replay-path coverage | `tests\integration\descriptive-reference-authored-prose.ps1` and `tests\integration\descriptive-reference-excluded-surfaces.ps1` replay fixture text through `handoff-governance-validator.ps1` and assert on `status`, `findings`, and `summary` output. |
| Corpus seeding | `.specrew\quality\known-traps.md` now contains the `human-handoff-id-context` row. |
| Feature-level follow-through | `specs/012-descriptive-id-handoffs/quality/hardening-gate.md` and `specs/012-descriptive-id-handoffs/quality/trap-reapplication.md` now record the closeout-boundary evidence for replay coverage, corpus durability, and preserved regressions. |
| Regression preservation | The existing feature 007 tests, the iteration 001 readable-reference tests, the new replay tests, and `validate-governance.ps1 -ProjectPath .` all passed again on the closeout tree on 2026-05-12. |

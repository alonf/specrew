# Iteration Plan: 005

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: planning-only  
**Capacity**: 3/20 story_points  
**Started**: 2026-05-10  
**Completed**: *pending*  
**Closed**: *pending*

## Summary

Iteration 005 carries **Polish and Cross-Cutting Concerns** only: tasks `T027`-`T028` from the approved feature plan. This slice completes the feature by executing the full validation lane and updating user-facing documentation after all three user stories land in Iterations 002, 003, and 004.

This slice is deliberately bounded to Polish work only. User Stories 1, 2, and 3 are completed in prior iterations.

**Primary Focus**: Re-run the full validation lane and update user-facing documentation for reviewer-regression routing, lockout-cap behavior, and withdrawal semantics.  
**Target Slice**: Polish (`T027`-`T028`)  
**Execution Status**: planning-only  
**Prior Completions**: User Story 1 (Iteration 002), User Story 2 (Iteration 003), User Story 3 (Iteration 004)

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| quickstart validation commands | Validation Lane Execution | ✅ `T027` | Review-operations maintainer | Full six-script validation lane re-run after all stories land |
| FR-001, FR-006, FR-008, FR-009, FR-012, FR-014 | Polish Feature Delivery | ✅ `T027`, `T028` | Review-operations maintainer, Coordinator handoff maintainer | Documentation updates and validation confirmation |
| SC-001, SC-004, TG-006 | User-Facing Handoff | ✅ `T028` | Coordinator handoff maintainer | README.md and docs/user-guide.md updates |
| FR-001, FR-002, FR-003, FR-004, FR-005, FR-015 | US1 reviewer-regression routing | ✅ Completed in Iteration 002 | — | Prerequisite event logging and routing infrastructure |
| FR-009, FR-010, FR-011 | US2 implementer lockout-cap | ✅ Completed in Iteration 003 | — | Prerequisite cap enforcement |
| FR-006, FR-008, FR-012, FR-014, FR-015 | US3 withdrawal and carry-forward | ✅ Completed in Iteration 004 | — | Prerequisite withdrawal, carry-forward, and known-traps integration |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | Scope limited to Polish (`T027`-`T028`) from approved `tasks.md`; User Stories 1-3 explicitly completed |
| **Traceability** | ✅ PASS | Every task maps to Polish requirements (quickstart validation, user-facing documentation) with dependencies on completed US1, US2, and US3 |
| **Ownership** | ✅ PASS | Task owners align to baseline Specrew roles in spec.md Requirement Ownership & Delivery |
| **Capacity** | ✅ PASS | 3/20 story_points; truthful slice with explicit deferrals |
| **Execution Support** | ✅ PASS | Planning artifacts, state.md, and validation contracts ready for before-sign-off review |

---

## Phase 6 Quality Planning

**Phase Scope**: `phase-6-polish-cross-cutting` — Polish and full validation lane re-run  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for PowerShell governance scripts, Markdown/YAML/JSON artifact contracts, documentation updates, and deterministic integration tests.

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| Validation lane completeness | `required` | All six integration tests and governance validation must pass after US1, US2, and US3 land |
| Documentation accuracy | `required` | README.md and docs/user-guide.md must correctly describe reviewer-regression routing, lockout-cap behavior, and withdrawal semantics |
| User-visible output correctness | `required` | Any documentation or validation output must be tested through the scaffolded replay path with assertions on user-visible output |
| Cross-story integration correctness | `required` | Validation must confirm that US1, US2, and US3 work together correctly without gaps or regressions |
| Carry-forward integration | `required` | Validation must verify US3 carry-forward logic correctly projects US1 and US2 state into next active iteration |
| Test-integrity scaffold-replay-path | `required` | Any task delivering user-facing handoff or visibility output must be tested through scaffolded replay path (`specrew-review.ps1`, `scaffold-reviewer-artifacts.ps1`) with assertions on user-visible output |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T027 | Run the reviewer-regression validation lane | quickstart validation commands | Polish | 2 | Review-operations maintainer | `tests/integration/reviewer-regression-event.ps1`, `tests/integration/lockout-chain-cap.ps1`, `tests/integration/reviewer-regression-ledger.ps1`, `tests/integration/reviewer-regression-withdrawal.ps1`, `tests/integration/carry-forward-closed-iteration.ps1`, `extensions/specrew-speckit/scripts/validate-governance.ps1` | done | Implementer | Authorized six-command lane passed end-to-end | pending review |
| T028 | Document reviewer-regression routing, lockout-cap behavior, and withdrawal semantics | SC-001, SC-004, TG-006 | Polish | 1 | Coordinator handoff maintainer | `README.md`, `docs/user-guide.md` | done | Implementer | README and user guide updated; replay examples verified against actual scaffold/review output | pending review |

**Total Effort**: 3 story_points

**CRITICAL REPLAY-PATH COVERAGE REQUIREMENT**: For T027-T028, any task that delivers user-facing handoff or visibility output (including but not limited to: validation lane output visible to users, documentation examples visible in README/user-guide) must be tested through the scaffolded replay path (`specrew-review.ps1`, `scaffold-reviewer-artifacts.ps1`) and assert user-visible output. This requirement carries forward the Iteration 003 and 004 lessons.

---

## Planned Execution Order

1. **Validation Lane**: `T027` executes the authorized six-command validation lane (`reviewer-regression-event.ps1`, `lockout-chain-cap.ps1`, `reviewer-regression-ledger.ps1`, `reviewer-regression-withdrawal.ps1`, `carry-forward-closed-iteration.ps1`, `validate-governance.ps1 -ProjectPath .`) to confirm all US1, US2, and US3 work together correctly
2. **Documentation**: `T028` updates README.md and docs/user-guide.md to document reviewer-regression routing, lockout-cap behavior, and withdrawal semantics
3. **Handoff**: After both tasks complete and validation confirms all controls working, iteration 005 is ready for hardening-gate sign-off and closeout

---

## Deferred Follow-On

| Deferred Task(s) | Target Iteration | Reason |
| ---------------- | ---------------- | ------ |
| None | — | All feature 008 tasks are planned or completed; no deferrals remain |

All feature 008 work is now accounted for across all five iterations (Iterations 001-005).

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20.0 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | The Planner must make any future deferral decision explicit. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments when actual variance accumulates. |

## Concurrency Rationale

- Current roster snapshot: Review-operations maintainer, Coordinator handoff maintainer
- Technology and scope signals: PowerShell integration tests, Markdown documentation updates
- Task dependency graph: `T027` → `T028` (validation must pass before documentation can be finalized and reviewed)
- Workstream separability: Moderate. `T027` runs the validation lane independently. `T028` writes documentation that should be verified against validated behavior from `T027`.
- Shared-surface conflict risk: Low. `T027` and `T028` work on distinct surfaces (validation scripts vs. documentation files).
- Recommendation: Run `T027` first to confirm all validation passes, then `T028` to document the confirmed behavior.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Iteration slicing, traceability packaging, this plan document |
| Discovery/Spikes | 0 | No separate spike authorized in this Polish slice |
| Implementation | 3 | T027 (validation lane) and T028 (documentation) |
| Review | 1 | Review validation results and documentation updates |
| Rework | 0 | Small buffer reserved if validation finds issues or documentation needs corrections |

## Implementation Approval

- **Approval Verdict**: ✅ **PLANNING AUTHORIZED**
- **Approved By**: Alon Fliess
- **Recorded Evidence**: I authorize feature 008 iteration 005 (Polish — validation lane re-run and documentation updates, tasks T027 through T028, 3 story points) planning to proceed with hardening-gate preparation. Hardening-gate sign-off and implementation authorization pending.
- **Recorded At**: 2026-05-10
- **Scope Authorized**: Polish (`T027`-`T028`, 3 story_points)
- **Gate Effect**: Planning may proceed immediately; hardening-gate sign-off required before implementation starts

## Implementation Authorization

- **Authorization Verdict**: ✅ **AUTHORIZED**
- **Authorized By**: Alon Fliess
- **Recorded Date**: 2026-05-11
- **Gate Reference**: `specs/008-reviewer-escalation-symmetry/iterations/005/quality/hardening-gate.md` (signed-off 2026-05-11)
- **Scope Authorized**: Polish validation lane (T027) and documentation updates (T028), 3 story_points
- **Boundary Note**: Distinct from planning-level approval; this authorization grants implementation start permission following hardening-gate sign-off.
- **Authorization Effect**: Implementation may proceed immediately upon hardening-gate verification

## Notes

- This plan carries Polish work only—validation lane re-run and user-facing documentation updates—after Iteration 002 delivered US1, Iteration 003 delivered US2, and Iteration 004 delivered US3.
- `T027` runs the full six-script validation lane to confirm all user stories work together correctly.
- `T028` updates README.md and docs/user-guide.md with reviewer-regression routing, lockout-cap behavior, and withdrawal semantics.

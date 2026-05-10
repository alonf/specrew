# Iteration Plan: 004

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: planning  
**Capacity**: 14/20 story_points  
**Started**: *(pending implementation authorization)*  
**Completed**: *(pending implementation authorization)*  
**Closed**: *(pending implementation authorization)*

## Summary

Iteration 004 carries **User Story 3 (withdrawal handling, carry-forward, known-traps integration)** only: tasks `T020`-`T026` from the approved feature plan. This slice builds on the active reviewer-regression chain established by User Story 1 in Iteration 002 and the implementer lockout-cap enforcement delivered by User Story 2 in Iteration 003.

This slice is deliberately bounded to US3 acceptance criteria only. Polish (`T027`-`T028`) remains explicitly deferred to Iteration 005.

**Primary Focus**: Withdrawal reversal, clean-pass de-escalation, repeated-event consolidation, conditional candidate-trap proposal, unapproved-trap cleanup, closed-iteration carry-forward without reopening historical artifacts.  
**Target Slice**: User Story 3 (`T020`-`T026`)  
**Execution Status**: planning-only  
**Deferred Follow-On**: Polish (`T027`-`T028`)

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-006 | Reviewer Regression Ledger | ✅ `T020`, `T023`, `T024` | Governance artifact maintainer, Review-operations maintainer | Ledger consistency, duplicate detection, withdrawal audit trail |
| FR-008 | Withdrawal and Misreport Handling | ✅ `T020`, `T021`, `T024` | Review-operations maintainer, Governance artifact maintainer | Withdrawal reverses pending state only, preserves historical record, cleans up unapproved traps |
| FR-012 | Known-Traps Seeding and Reapplication | ✅ `T020`, `T023`, `T025` | Quality-governance maintainer | Conditional candidate-trap proposal when corpus is enabled |
| FR-014 | Closed-Iteration Carry-Forward | ✅ `T020`, `T022`, `T026` | Spec-governance maintainer | Preserve closed-iteration history, project state into next active iteration |
| FR-015 | Repeated Reviewer Regression Consolidation | ✅ `T020`, `T023`, `T024` | Governance artifact maintainer | Maintain single active chain, dedupe duplicate reports, consolidate distinct findings |
| FR-001, FR-002, FR-003, FR-004, FR-005, FR-015 | US1 reviewer-regression routing | ✅ Completed in Iteration 002 | — | Prerequisite event logging and routing infrastructure |
| FR-009, FR-010, FR-011 | US2 implementer lockout-cap | ✅ Completed in Iteration 003 | — | Prerequisite cap enforcement that US3 must preserve |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | Scope limited to User Story 3 (`T020`-`T026`) from approved `tasks.md`; Polish explicitly deferred |
| **Traceability** | ✅ PASS | Every task maps to US3 FRs (FR-006, FR-008, FR-012, FR-014, FR-015) with dependencies on completed US1 and US2 infrastructure |
| **Ownership** | ✅ PASS | Task owners align to baseline Specrew roles in spec.md Requirement Ownership & Delivery |
| **Capacity** | ✅ PASS | 14/20 story_points; truthful slice with explicit deferrals |
| **Execution Support** | ✅ PASS | Planning artifacts, state.md, and validation contracts ready for before-implement review |

---

## Phase 3 Quality Planning

**Phase Scope**: `phase-3-withdrawal-carry-forward-known-traps` — US3 withdrawal handling, carry-forward, and known-traps integration  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for PowerShell governance scripts, Markdown/YAML/JSON artifact contracts, runtime routing sync, and deterministic integration tests.

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| Withdrawal state-reversal correctness | `required` | Withdrawal must reverse only still-pending escalation or routing state; completed ownership changes stay as historical record |
| Known-traps approval integrity | `required` | Only corpus-enabled repos offer candidate traps; unapproved traps are cleaned on withdrawal; approved traps remain governed by normal corpus-change workflow |
| Carry-forward projection accuracy | `required` | Closed-iteration reports must project into next active iteration without reopening historical artifacts |
| Repeated-event consolidation correctness | `required` | Dedupe duplicate reports for same slice+defect; append distinct findings to ledger; maintain single active chain |
| US1 integration correctness | `required` | Withdrawal and carry-forward must preserve US1 event logging and routing infrastructure |
| US2 integration correctness | `required` | Withdrawal and carry-forward must preserve US2 cap enforcement state and decision evidence |
| Replay-path visibility coverage | `required` | Any handoff-facing behavior must be tested through scaffolded replay path (`specrew-review.ps1`, `scaffold-reviewer-artifacts.ps1`) with assertions on user-visible output |
| Test integrity | `required` | Deterministic coverage for US3 acceptance scenarios 1-5 |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T020 | Build withdrawal, duplicate-report, carry-forward, and corpus-disabled fixtures | US3 | US3 | 2 | Governance artifact maintainer | `tests/integration/fixtures/reviewer-regression-withdrawal/**`, `tests/integration/fixtures/carry-forward-closed-iteration/**`, `tests/integration/fixtures/reviewer-regression-ledger/**` | planned | — | — | — |
| T021 | Add withdrawal and misreport regression coverage | FR-008 | US3 | 2 | Review-operations maintainer | `tests/integration/reviewer-regression-withdrawal.ps1` | planned | — | — | — |
| T022 | Add closed-iteration carry-forward regression coverage | FR-014 | US3 | 2 | Spec-governance maintainer | `tests/integration/carry-forward-closed-iteration.ps1` | planned | — | — | — |
| T023 | Extend ledger consistency and known-traps degraded-path assertions | FR-006, FR-012, FR-015 | US3 | 2 | Quality-governance maintainer | `tests/integration/reviewer-regression-ledger.ps1`, `tests/integration/gap-governance.ps1` | planned | — | — | — |
| T024 | Implement withdrawal reversal, clean-pass de-escalation, and repeated-event consolidation | FR-005, FR-008, FR-015 | US3 | 3 | Governance artifact maintainer | `extensions/specrew-speckit/scripts/manage-reviewer-regression.ps1` | planned | — | — | — |
| T025 | Implement conditional candidate-trap proposal and unapproved-trap cleanup | FR-012, TG-008 | US3 | 2 | Quality-governance maintainer | `extensions/specrew-speckit/scripts/manage-reviewer-regression.ps1`, `extensions/specrew-speckit/scripts/validate-governance.ps1` | planned | — | — | — |
| T026 | Preserve closed-iteration history while projecting unresolved state into next active iteration | FR-014, TG-003 | US3 | 1 | Spec-governance maintainer | `extensions/specrew-speckit/scripts/manage-reviewer-regression.ps1`, `specs/001-specrew-product/contracts/iteration-artifacts.md` | planned | — | — | — |

**Total Effort**: 14 story_points

**CRITICAL REPLAY-PATH COVERAGE REQUIREMENT**: For any T020-T026 task that delivers user-facing handoff or visibility output (including but not limited to: cap-state projection in `specrew-review.ps1`, withdrawal-state reflection in iteration state, carry-forward-state visibility in next-iteration handoff), the plan explicitly requires test coverage that invokes the scaffolded replay path (`specrew-review.ps1`, `scaffold-reviewer-artifacts.ps1`) and asserts user-visible output. This requirement carries forward the Iteration 003 lesson: handoff-facing behavior must be tested through the real scaffolded replay path, not only through runtime state surfaces.

---

## Planned Execution Order

1. **Test Fixtures**: `T020` first (baseline fixtures for withdrawal, carry-forward, and corpus-disabled scenarios)
2. **Test Coverage**: `T021`, `T022`, and `T023` can run in parallel after `T020` (withdrawal tests, carry-forward tests, and ledger consistency assertions)
3. **Implementation**: `T024` (core withdrawal, de-escalation, and consolidation logic), then `T025` and `T026` can run in parallel after `T024` (candidate-trap logic and carry-forward projection)

---

## Deferred Follow-On

| Deferred Task(s) | Target Iteration | Reason |
| ---------------- | ---------------- | ------ |
| `T027`-`T028` | 005 | Polish and full validation lane after all user stories land |

This is a capacity and dependency split, not a descoping decision. The deferred tasks remain part of the approved feature plan and must be carried forward explicitly.

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

- Current roster snapshot: Governance artifact maintainer, Review-operations maintainer, Spec-governance maintainer, Quality-governance maintainer
- Technology and scope signals: PowerShell governance scripts, Markdown/YAML/JSON artifact contracts, runtime config sync, integration fixtures
- Task dependency graph: `T020` → `T021`/`T022`/`T023` parallel → `T024` → `T025`/`T026` parallel
- Workstream separability: Moderate. `T021`, `T022`, and `T023` test different surfaces after `T020` completes. `T024` implements core withdrawal logic and must land first. `T025` and `T026` work on distinct concerns (candidate-trap proposal vs. carry-forward projection).
- Shared-surface conflict risk: Moderate. `T024`, `T025`, and `T026` all touch `manage-reviewer-regression.ps1`, so `T024` must land first; then `T025` and `T026` can run in parallel as they work on distinct mode paths.
- Prior withdrawal/carry-forward implementation evidence: None yet; this is the first US3 slice.
- Recommendation: Use the explicit parallel windows (`T021`/`T022`/`T023` after `T020`, then `T025`/`T026` after `T024`). Monitor shared-governance surface for contention.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 2 | Iteration slicing, traceability packaging, this plan document |
| Discovery/Spikes | 0 | No separate spike authorized in this US3 slice |
| Implementation | 14 | All seven US3 tasks (`T020`-`T026`) |
| Review | 1 | Review US3 withdrawal, carry-forward, and known-traps behavior |
| Rework | 0 | Small buffer reserved if review finds state-reversal or projection misalignments |

## Implementation Approval

- **Approval Verdict**: ⏸️ **AWAITING HARDENING-GATE SIGN-OFF AND IMPLEMENTATION AUTHORIZATION**
- **Approved By**: *(pending)*
- **Recorded Evidence**: *(pending)*
- **Recorded At**: *(pending)*
- **Scope Pending Approval**: User Story 3 (`T020`-`T026`, 14 story_points)
- **Gate Effect**: Planning complete; implementation blocked until hardening-gate sign-off and explicit implementation authorization

## Notes

- This plan carries User Story 3 only—withdrawal handling, carry-forward, and known-traps integration—after Iteration 002 delivered the reviewer-regression routing infrastructure and Iteration 003 delivered the implementer lockout-cap enforcement.
- The slice is deliberately bounded to US3 acceptance criteria: withdrawal reversal, clean-pass de-escalation, repeated-event consolidation, conditional candidate-trap proposal, unapproved-trap cleanup, and closed-iteration carry-forward without reopening historical artifacts.
- User Story 1 (reviewer-regression routing) is complete in Iteration 002; User Story 2 (implementer lockout-cap) is complete in Iteration 003; US3 builds on both.
- Polish (`T027`-`T028`) remains explicitly deferred to Iteration 005. The full six-script validation lane will be executed at Iteration 005 closeout.
- `T020` builds baseline fixtures for withdrawal, duplicate-report, carry-forward, and corpus-disabled scenarios.
- `T021` adds deterministic integration tests for withdrawal and misreport handling.
- `T022` adds deterministic integration tests for closed-iteration carry-forward.
- `T023` extends ledger consistency and known-traps degraded-path assertions.
- `T024` implements the core withdrawal reversal, clean-pass de-escalation, and repeated-event consolidation logic in `manage-reviewer-regression.ps1`.
- `T025` implements conditional candidate-trap proposal when corpus is enabled and unapproved-trap cleanup on withdrawal.
- `T026` preserves closed-iteration history while projecting unresolved reviewer-regression state into the next active iteration.
- **REPLAY-PATH COVERAGE LESSON FROM ITERATION 003**: Any task that delivers user-facing handoff or visibility output must be tested through the scaffolded replay path (`specrew-review.ps1`, `scaffold-reviewer-artifacts.ps1`) with assertions on user-visible output, not only through runtime state surfaces.

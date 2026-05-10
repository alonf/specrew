# Iteration Plan: 002

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: retro  
**Capacity**: 13/20 story_points  
**Started**: 2026-05-10  
**Completed**: 2026-05-10
**Closed**: 2026-05-10

## Summary

Iteration 002 carries **User Story 1 (reviewer-regression routing)** only: tasks `T008`-`T013` from the approved feature plan. This is the first user-story slice after the infrastructure foundation delivered in Iteration 001. It implements the core value proposition—when a human reviewer finds a defect in Squad-approved work, route the remaining review work to a stronger reviewer path or hold for human direction when no safe path exists.

This slice is deliberately bounded to US1 acceptance criteria only. User Story 2 (lockout-chain cap, `T014`-`T019`) is explicitly deferred to Iteration 003, and User Story 3 (withdrawal/carry-forward/known-traps, `T020`-`T026`) is explicitly deferred to Iteration 004. Polish (`T027`-`T028`) remains deferred to Iteration 005.

**Primary Focus**: Reviewer-regression event recording, stronger-class routing selection, same-class independent fallback, maximum-strength human-direction hold, and ledger/active-chain projection assertions  
**Target Slice**: User Story 1 (`T008`-`T013`)  
**Execution Status**: complete - review passed, retrospective complete  
**Deferred Follow-On**: User Story 2 (`T014`-`T019`), User Story 3 (`T020`-`T026`), Polish (`T027`-`T028`)

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-001 | Reviewer Regression Trigger | ✅ `T011` | Reviewer-governance policy maintainer | Event logging on human-found defects in Squad-approved work |
| FR-002 | Reviewer-Side Escalation | ✅ `T011`, `T013` | Reviewer-governance policy maintainer, Coordinator handoff maintainer | Stronger-class routing selection and handoff guidance |
| FR-003 | Stronger-Reviewer Lookup and Same-Class Independent Routing Fallback | ✅ `T011`, `T012` | Reviewer-governance policy maintainer, Lifecycle-routing maintainer | Runtime strength ordering and independent-owner selection |
| FR-004 | Human-Direction Hold at Maximum Review Strength | ✅ `T012`, `T013` | Lifecycle-routing maintainer, Coordinator handoff maintainer | Hold when strongest class active and no independent reviewer available |
| FR-005 | Configurable Reviewer De-Escalation | ✅ `T012` | Lifecycle-routing maintainer | Active-chain readback for de-escalation after clean pass |
| FR-006 | Reviewer Regression Ledger | ✅ `T010` | Governance artifact maintainer | Ledger projection assertions |
| FR-015 | Repeated Reviewer Regression Consolidation | ✅ `T010`, `T011` | Governance artifact maintainer, Reviewer-governance policy maintainer | Chain deduplication and single active chain per feature |
| FR-009, FR-010, FR-011 | US2 lockout-chain cap | ⏳ Deferred to Iteration 003 | — | Depends on US1 active chain |
| FR-008, FR-012, FR-014 | US3 withdrawal, carry-forward, known-traps | ⏳ Deferred to Iteration 004 | — | Depends on US1 event logging |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | Scope limited to User Story 1 (`T008`-`T013`) from approved `tasks.md`; all other story work explicitly deferred |
| **Traceability** | ✅ PASS | Every task maps to US1 FRs (FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-015) |
| **Ownership** | ✅ PASS | Task owners align to baseline Specrew roles in spec.md Requirement Ownership & Delivery |
| **Capacity** | ✅ PASS | 13/20 story_points; truthful slice with explicit deferrals |
| **Execution Support** | ✅ PASS | Planning artifacts, state.md, and validation contracts ready for before-implement review |

---

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-reviewer-regression-routing` — US1 reviewer-regression routing implementation  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for PowerShell governance scripts, Markdown/YAML/JSON artifact contracts, runtime routing sync, and deterministic integration tests.

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| State-transition correctness | `required` | Event logging, chain deduplication, and active-state projection must be truthful |
| Routing integrity | `required` | Stronger-class selection and independent-owner fallback must follow runtime strength ordering |
| Governance artifact consistency | `required` | Ledger, state mirror, config sync, and validation must agree |
| Soft-warning vs. blocker semantics | `required` | Regression events are soft-warning; only FR-004 hold path blocks the next action |
| Test integrity | `required` | Deterministic coverage for US1 acceptance scenarios 1-4 |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T008 | Build stronger-class, same-class-fallback, and maximum-strength-hold fixtures | US1 | US1 | 1 | Review-operations maintainer | `tests/integration/fixtures/reviewer-regression-event/**` | done | copilot-agent | 1 | pass |
| T009 | Add event-reporting and reviewer-routing regression coverage | FR-001, FR-002, FR-003, FR-004 | US1 | 2 | Review-operations maintainer | `tests/integration/reviewer-regression-event.ps1` | done | copilot-agent | 2 | pass |
| T010 | Add ledger and active-chain projection assertions | FR-005, FR-006, FR-015 | US1 | 2 | Governance artifact maintainer | `tests/integration/reviewer-regression-ledger.ps1` | done | copilot-agent | 2 | pass |
| T011 | Implement reviewer-regression event logging, chain deduplication, and strongest-class selection | FR-001, FR-002, FR-003, FR-015 | US1 | 3 | Reviewer-governance policy maintainer | `extensions/specrew-speckit/scripts/manage-reviewer-regression.ps1` | done | copilot-agent | 3 | pass |
| T012 | Implement same-class independent-owner fallback, maximum-strength hold, and active-chain readback | FR-003, FR-004, FR-005 | US1 | 3 | Lifecycle-routing maintainer | `extensions/specrew-speckit/scripts/manage-reviewer-regression.ps1` | done | copilot-agent | 3 | pass |
| T013 | Update routed reviewer/coordinator guidance for stronger-class escalation and human-direction hold | FR-002, FR-004, TG-006 | US1 | 2 | Coordinator handoff maintainer | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, `.squad/agents/reviewer/charter.md`, `.github/agents/squad.agent.md` | done | copilot-agent | 2 | pass |

**Total Effort**: 13 story_points

---

## Planned Execution Order

1. **Test Fixtures**: `T008` first (baseline fixtures for reviewer-regression scenarios)
2. **Test Coverage**: `T009` and `T010` can run in parallel after `T008` (event-reporting tests and ledger assertions)
3. **Implementation**: `T011` and `T012` in sequence (event logging + routing selection, then fallback + hold + readback)
4. **Handoff Integration**: `T013` can run in parallel with `T011`/`T012` (coordinator/reviewer guidance updates)

---

## Deferred Follow-On

| Deferred Task(s) | Target Iteration | Reason |
| ---------------- | ---------------- | ------ |
| `T014`-`T019` | 003 | User Story 2 (lockout-chain cap) depends on US1 active reviewer-regression chain |
| `T020`-`T026` | 004 | User Story 3 (withdrawal, carry-forward, known-traps) depends on US1 event logging |
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

- Current roster snapshot: Governance artifact maintainer, Lifecycle-routing maintainer, Review-operations maintainer, Reviewer-governance policy maintainer, Coordinator handoff maintainer
- Technology and scope signals: PowerShell governance scripts, Markdown/YAML/JSON artifacts, runtime config sync, integration fixtures
- Task dependency graph: `T008` → `T009`/`T010` parallel → `T011` → `T012` with `T013` parallel to `T011`/`T012`
- Workstream separability: Bounded. `T009` and `T010` test different surfaces after `T008` completes. `T011` and `T012` work on the same script sequentially. `T013` works on distinct handoff surfaces.
- Shared-surface conflict risk: Moderate. `T011` and `T012` both touch `manage-reviewer-regression.ps1`, so keep them serial. `T013` works on coordinator/reviewer prompt surfaces.
- Prior reviewer ownership/hotspot evidence: Iteration 001 delivered the foundational infrastructure; this iteration adds the first story-specific routing behavior.
- Recommendation: Use the explicit parallel windows (`T009`/`T010` after `T008`, then `T013` parallel with `T011`/`T012`). Do not add same-specialty Junior/Senior expansion in Iteration 002.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 2 | Iteration slicing, traceability packaging, this plan document |
| Discovery/Spikes | 0 | No separate spike authorized in this US1 slice |
| Implementation | 13 | All six US1 tasks (`T008`-`T013`) |
| Review | 1 | Review US1 routing behavior, test coverage, and handoff integration |
| Rework | 0 | Small buffer reserved if review finds routing misalignments |

## Implementation Approval

- **Approval Verdict**: approved
- **Approved By**: Alon Fliess (user)
- **Recorded Evidence**: Blanket statement: "after you update the above, I approve the 2 pending approval, so you can continue"
- **Recorded At**: 2026-05-10
- **Scope Pending Approval**: Iteration 002 (User Story 1 slice, T008-T013, 13 story_points) and hardening-gate sign-off
- **Blanket Scope Coverage**: This approval covers both the Implementation Approval and the hardening-gate Approval Ref for Iteration 002, expressed as a single blanket statement
- **Gate Effect**: Implementation approval granted; hardening-gate approval granted; execution can proceed

## Notes

- This plan carries User Story 1 only—the MVP reviewer-regression routing behavior—after Iteration 001 delivered the infrastructure foundation.
- The slice is deliberately bounded to US1 acceptance criteria: event recording, stronger-class routing, same-class independent fallback, and maximum-strength hold.
- User Story 2 (lockout-chain cap) is explicitly deferred to Iteration 003 because it depends on the active reviewer-regression chain introduced by US1.
- User Story 3 (withdrawal, carry-forward, known-traps) is explicitly deferred to Iteration 004 because it depends on US1 event logging.
- Polish and full validation lane are explicitly deferred to Iteration 005.
- `T008` builds baseline fixtures for stronger-class, same-class-fallback, and maximum-strength-hold scenarios in `tests/integration/fixtures/reviewer-regression-event/`.
- `T009` adds deterministic integration tests for event-reporting and reviewer-routing in `tests/integration/reviewer-regression-event.ps1`.
- `T010` adds ledger and active-chain projection assertions in `tests/integration/reviewer-regression-ledger.ps1`.
- `T011` implements the core reviewer-regression event logging, chain deduplication, and strongest-class selection logic in `manage-reviewer-regression.ps1`.
- `T012` implements same-class independent-owner fallback, maximum-strength human-direction hold, and active-chain readback in `manage-reviewer-regression.ps1`.
- `T013` updates coordinator and reviewer guidance surfaces to reflect stronger-class escalation and human-direction hold paths.

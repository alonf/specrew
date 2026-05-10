# Iteration Plan: 001

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: complete  
**Capacity**: 12/20 story_points  
**Started**: 2026-05-09  
**Completed**: 2026-05-10

## Summary

Iteration 001 is the infrastructure foundation slice for feature `008-reviewer-escalation-symmetry`. It carries **Phase 1 (Setup) + Phase 2 (Foundational)** only—the minimal artifact and runtime plumbing that all three user stories depend on—so before-implement can review a bounded governance contract before any story-specific routing behavior lands.

This is a truthful 12-point slice deliberately stopped before User Story 1 begins. All user-story work (US1, US2, US3) is explicitly deferred to Iteration 002 and later, giving reviewers a clean checkpoint to validate the shared ledger, state projection, validation, and coordinator surfaces before story-specific escalation logic adds complexity.

**Primary Focus**: Reviewer-regression artifact surface, shared governance helpers, runtime sync, validation integration, and reusable test fixtures  
**Target Slice**: Setup + Foundational (`T001`-`T007`)  
**Execution Status**: awaiting implementation approval  
**Deferred Follow-On**: User Story 1 (`T008`-`T013`), User Story 2 (`T014`-`T019`), User Story 3 (`T020`-`T026`), Polish (`T027`-`T028`)

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-006, FR-014 | Reviewer Regression Ledger | ✅ `T001`, `T003` | Governance artifact maintainer | Ledger seed, managed-block contract, and shared parsing helpers |
| FR-008, FR-011 | Governance artifact orchestration | ✅ `T003`, `T004`, `T006`, `T007` | Governance artifact maintainer, Lifecycle-routing maintainer, Coordinator handoff maintainer | Shared helpers, script interface shell, validation, and reviewer handoff surfaces |
| FR-013 | Additive Symmetry with Existing Policy | ✅ `T005` | Runtime routing maintainer | Runtime sync without changing FR-027 `activeEscalation` behavior |
| FR-001, FR-002, FR-003, FR-004, FR-005 | US1 reviewer-regression routing | ⏳ Deferred to Iteration 002 | — | Story work starts only after foundational infrastructure is reviewed and approved |
| FR-009, FR-010, FR-011 | US2 lockout-chain cap | ⏳ Deferred to Iteration 003 | — | Depends on US1 active chain |
| FR-008, FR-012, FR-014, FR-015 | US3 withdrawal, carry-forward, known-traps | ⏳ Deferred to Iteration 004 | — | Depends on US1 event logging |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | Scope limited to Phase 1 + Phase 2 infrastructure from approved `tasks.md`; all story work explicitly deferred |
| **Traceability** | ✅ PASS | Every task maps to foundational FRs (FR-006, FR-008, FR-011, FR-013, FR-014) |
| **Ownership** | ✅ PASS | Task owners align to baseline Specrew roles in spec.md Requirement Ownership & Delivery |
| **Capacity** | ✅ PASS | 12/20 story_points; truthful slice with explicit deferrals |
| **Execution Support** | ✅ PASS | Planning artifacts, state.md, and validation contracts ready for before-implement review |

---

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice` — reviewer-regression governance surfaces and validation lanes  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for PowerShell governance scripts, Markdown/YAML/JSON artifact contracts, runtime routing sync, and deterministic integration tests.

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| State-transition correctness | `required` | Ledger and state-projection must be truthful before stories add routing logic |
| Routing integrity | `deferred` | No story-specific routing in this slice; defer to US1/US2/US3 iterations |
| Governance artifact consistency | `required` | Ledger, state mirror, config sync, and validation must agree |
| Soft-warning vs. blocker semantics | `required` | Validation must enforce soft-warning default and explicit hold paths |
| Test integrity | `required` | Foundational fixtures for later story tests |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Create the reviewer-regression ledger seed and managed-block contract examples | FR-006, FR-014 | Foundational | 1 | Governance artifact maintainer | `.specrew/reviewer-regression-log.md`, `specs/001-specrew-product/contracts/iteration-artifacts.md` | done | Implementer | 1 | pass |
| T002 | Create baseline scratch-project fixtures for reviewer-regression scenarios | TG-001, TG-002, TG-003 | Foundational | 2 | Review-operations maintainer | `tests/integration/fixtures/reviewer-regression-event/**`, `tests/integration/fixtures/lockout-chain-cap/**`, `tests/integration/fixtures/reviewer-regression-withdrawal/**`, `tests/integration/fixtures/carry-forward-closed-iteration/**` | done | Implementer | 2 | pass |
| T003 | Add reviewer-regression ledger parsing, state helpers, and decision-type support | FR-006, FR-008, FR-011 | Foundational | 2 | Governance artifact maintainer | `extensions/specrew-speckit/scripts/shared-governance.ps1` | done | Implementer | 2 | pass |
| T004 | Create manage-reviewer-regression.ps1 mode shell | FR-001, FR-008, FR-014 | Foundational | 2 | Lifecycle-routing maintainer | `extensions/specrew-speckit/scripts/manage-reviewer-regression.ps1` | done | Implementer | 2 | pass |
| T005 | Extend runtime sync for reviewerRegressionState without changing activeEscalation | FR-013 | Foundational | 1 | Runtime routing maintainer | `extensions/specrew-speckit/scripts/sync-squad-model-overrides.ps1`, `.squad/config.json` | done | Implementer | 1 | pass |
| T006 | Extend governance validation for reviewer-regression ledger, state, and decisions | FR-007, FR-011, FR-015 | Foundational | 2 | Governance artifact maintainer | `extensions/specrew-speckit/scripts/validate-governance.ps1` | done | Implementer | 2 | pass |
| T007 | Surface reviewer-regression signals in coordinator/reviewer handoff | FR-011, SC-004 | Foundational | 2 | Coordinator handoff maintainer | `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1`, `scripts/specrew-review.ps1` | done | Implementer | 2 | pass |

**Total Effort**: 12 story_points

---

## Planned Execution Order

1. **Phase 1 (Setup)**: `T001` and `T002` can run in parallel—artifact seeds and fixture roots
2. **Phase 2 (Foundational)**: `T003` and `T004` first (shared helpers and script shell), then `T005`, `T006`, `T007` in parallel
3. Stop at `T007`; do not start any User Story work in this iteration

---

## Deferred Follow-On

| Deferred Task(s) | Target Iteration | Reason |
| ---------------- | ---------------- | ------ |
| `T008`-`T013` | 002 | User Story 1 (reviewer-regression routing) depends on the foundational infrastructure delivered by Iteration 001 |
| `T014`-`T019` | 003 | User Story 2 (lockout-chain cap) depends on US1 active chain |
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

- Current roster snapshot: Governance artifact maintainer, Lifecycle-routing maintainer, Runtime routing maintainer, Review-operations maintainer, Coordinator handoff maintainer
- Technology and scope signals: PowerShell governance scripts, Markdown/YAML/JSON artifacts, runtime config sync, integration fixtures
- Task dependency graph: Phase 1 (`T001`, `T002`) → Phase 2 Foundational start (`T003`, `T004`) → Phase 2 Parallel (`T005`, `T006`, `T007`)
- Workstream separability: Bounded. `T001` and `T002` are independent. `T005`, `T006`, and `T007` can proceed in parallel after `T003` and `T004` complete.
- Shared-surface conflict risk: Moderate. `T003` and `T006` both touch `shared-governance.ps1` and `validate-governance.ps1`, so keep them serial. `T005` and `T007` work on distinct surfaces.
- Prior reviewer ownership/hotspot evidence: None; this is the first iteration for feature 008.
- Recommendation: Use the explicit parallel windows (`T001`/`T002`, then `T005`/`T006`/`T007` after `T003`/`T004`). Do not add same-specialty Junior/Senior expansion in Iteration 001.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 2 | Iteration slicing, traceability packaging, this plan document |
| Discovery/Spikes | 0 | No separate spike authorized in this foundational slice |
| Implementation | 12 | All seven foundational tasks (`T001`-`T007`) |
| Review | 1 | Review governance contract, artifact shapes, and validation integration |
| Rework | 0 | Small buffer reserved if review finds contract misalignments |

## Implementation Approval

- **Approval Verdict**: approved
- **Approved By**: Alon Fliess (human developer)
- **Recorded Evidence**: "Resume feature 008 and keep working autonomously until the task is truly finished. If you were planning, stop planning and start implementing."
- **Recorded At**: 2026-05-09T20:00:00Z
- **Scope Approved for Execution**: Iteration 001 infrastructure-only slice (T001-T007, 12 story_points)
- **Gate Effect**: Implementation can proceed

## Notes

- This plan repairs the iteration 001 stub after features 009 and 010 completed.
- The slice is deliberately bounded to infrastructure only—no story-specific routing logic—so before-implement can review the governance contract before complexity grows.
- Phase 1 creates the ledger seed, managed-block contract examples, and reusable scratch-project fixture roots that all later stories depend on.
- Phase 2 adds the shared parsing/validation helpers, script interface shell, runtime sync, and coordinator handoff surfaces that every user-story task will build on.
- User Story 1 (MVP reviewer-regression routing) is explicitly deferred to Iteration 002.
- User Story 2 (lockout-chain cap) is explicitly deferred to Iteration 003.
- User Story 3 (withdrawal, carry-forward, known-traps) is explicitly deferred to Iteration 004.
- Polish and full validation lane are explicitly deferred to Iteration 005.
- `T001` creates `.specrew/reviewer-regression-log.md` as the append-only ledger seed and updates `specs/001-specrew-product/contracts/iteration-artifacts.md` with the managed-block contract for `reviewer-regression-state`.
- `T002` scaffolds the four fixture roots (`reviewer-regression-event`, `lockout-chain-cap`, `reviewer-regression-withdrawal`, `carry-forward-closed-iteration`) with baseline `.specrew/iteration-config.yml`, `.squad/decisions.md`, and `specs/008-sample/iterations/001/state.md` stubs for later story tests to extend.
- `T003` adds ledger parsing, `reviewer-regression-state` managed-block helpers, and structured decision-type support (including `reviewer-regression-escalation`, `reviewer-regression-withdrawal`, `lockout-cap`) in `shared-governance.ps1`.
- `T004` creates `manage-reviewer-regression.ps1` with `report`, `resolve`, `withdraw`, `project`, and `get` mode stubs—no story logic yet, just the interface shell for later tasks to implement.
- `T005` extends `sync-squad-model-overrides.ps1` to sync `reviewerRegressionState` into `.squad/config.json` without altering the existing `activeEscalation` FR-027 behavior.
- `T006` extends `validate-governance.ps1` to enforce ledger append-only invariants, state-mirror consistency, and decisions-ledger entry shape for reviewer-regression events.
- `T007` updates `scaffold-reviewer-artifacts.ps1` and `scripts/specrew-review.ps1` to surface reviewer-regression escalation status and routing-fallback signals in coordinator/reviewer handoff outputs.

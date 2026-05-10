# Iteration Plan: 003

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: planning  
**Capacity**: 12/20 story_points  
**Started**: 2026-05-10  
**Completed**: —  
**Closed**: —  

## Summary

Iteration 003 carries **User Story 2 (implementer lockout-chain cap)** only: tasks `T014`-`T019` from the approved feature plan. This slice builds on the active reviewer-regression chain established by User Story 1 in Iteration 002, adding the bounded-rotation policy that prevents unlimited implementer reassignment after repeated reviewer-missed defects.

This slice is deliberately bounded to US2 acceptance criteria only. User Story 3 (withdrawal/carry-forward/known-traps, `T020`-`T026`) is explicitly deferred to Iteration 004, and Polish (`T027`-`T028`) remains deferred to Iteration 005.

**Primary Focus**: Implementer lockout-chain counting, cap activation at configurable default, post-cap human or approved-alternate-owner routing, cap visibility in decisions ledger and handoff outputs.  
**Target Slice**: User Story 2 (`T014`-`T019`)  
**Execution Status**: planning  
**Deferred Follow-On**: User Story 3 (`T020`-`T026`), Polish (`T027`-`T028`)

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-009 | Implementer Lockout-Chain Cap | ✅ `T017`, `T018` | Runtime routing maintainer, Decisions-ledger maintainer | Cap counting and activation at default two rotations beyond original implementer |
| FR-010 | Post-Cap Ownership Rule | ✅ `T017`, `T019` | Runtime routing maintainer, Coordinator handoff maintainer | Route to human or explicitly justified alternate owner recorded in `.squad/decisions.md` |
| FR-011 | Cap and Escalation Visibility | ✅ `T018`, `T019` | Decisions-ledger maintainer, Coordinator handoff maintainer | Surface cap state in decisions ledger, iteration state, and user-facing handoff |
| FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-015 | US1 reviewer-regression routing | ✅ Completed in Iteration 002 | — | Prerequisite infrastructure for US2 cap implementation |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | Scope limited to User Story 2 (`T014`-`T019`) from approved `tasks.md`; all other story work explicitly deferred |
| **Traceability** | ✅ PASS | Every task maps to US2 FRs (FR-009, FR-010, FR-011) with dependencies on completed US1 infrastructure |
| **Ownership** | ✅ PASS | Task owners align to baseline Specrew roles in spec.md Requirement Ownership & Delivery |
| **Capacity** | ✅ PASS | 12/20 story_points; truthful slice with explicit deferrals |
| **Execution Support** | ✅ PASS | Planning artifacts, state.md, and validation contracts ready for before-implement review |

---

## Phase 2 Quality Planning

**Phase Scope**: `phase-2-lockout-chain-cap` — US2 implementer lockout-chain cap implementation  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for PowerShell governance scripts, Markdown/YAML/JSON artifact contracts, runtime routing sync, and deterministic integration tests.

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| Implementer chain counting accuracy | `required` | Chain must count only distinct implementer owners and activate cap at exactly two rotations beyond original |
| Cap activation routing integrity | `required` | Post-cap routing must enforce human or explicitly approved alternate owner path; no synthesis of additional specialists |
| Decision evidence recording | `required` | Every cap activation and alternate-owner approval must be recorded in `.squad/decisions.md` with rationale |
| Handoff visibility | `required` | Locked-out agents, cap status, and planned next-owner path must be visible in user-facing outputs and state artifacts |
| Integration with US1 active chain | `required` | Cap implementation must read and respect the active reviewer-regression chain seeded by US1 |
| Test integrity | `required` | Deterministic coverage for US2 acceptance scenarios 1-3 |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T014 | Build cap-hit, alternate-owner-approved, and awaiting-human-owned-revision fixtures | US2 | US2 | 1 | Review-operations maintainer | `tests/integration/fixtures/lockout-chain-cap/**` | planned | — | — | — |
| T015 | Add implementer lockout-cap regression coverage | FR-009, FR-010 | US2 | 2 | Review-operations maintainer | `tests/integration/lockout-chain-cap.ps1` | planned | — | — | — |
| T016 | Extend reviewer closeout and replay assertions for cap visibility and next-owner summary | FR-011 | US2 | 2 | Coordinator handoff maintainer | `tests/integration/reviewer-closeout-governance.ps1`, `tests/integration/review-command.ps1` | planned | — | — | — |
| T017 | Implement lockout-chain counting, cap activation, and post-cap human or approved-alternate-owner routing | FR-009, FR-010 | US2 | 3 | Runtime routing maintainer | `extensions/specrew-speckit/scripts/manage-reviewer-regression.ps1` | planned | — | — | — |
| T018 | Record `lockout-cap` and reviewer-routing evidence entries through `shared-governance.ps1` into `.squad/decisions.md` | FR-010, FR-011 | US2 | 2 | Decisions-ledger maintainer | `extensions/specrew-speckit/scripts/shared-governance.ps1`, `extensions/specrew-speckit/scripts/manage-reviewer-regression.ps1`, `.squad/decisions.md` | planned | — | — | — |
| T019 | Surface locked-out agents, cap status, and planned next-owner path in `scaffold-reviewer-artifacts.ps1`, `specrew-review.ps1`, and `.squad/routing.md` | FR-011 | US2 | 2 | Coordinator handoff maintainer | `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1`, `scripts/specrew-review.ps1`, `.squad/routing.md` | planned | — | — | — |

**Total Effort**: 12 story_points

---

## Planned Execution Order

1. **Test Fixtures**: `T014` first (baseline fixtures for lockout-chain cap scenarios)
2. **Test Coverage**: `T015` and `T016` can run in parallel after `T014` (lockout-cap regression tests and closeout/replay assertions)
3. **Implementation**: `T017` and `T018` in sequence (chain counting + cap activation, then decision evidence recording)
4. **Handoff Integration**: `T019` can run in parallel with `T017`/`T018` (cap visibility in outputs and state)

---

## Deferred Follow-On

| Deferred Task(s) | Target Iteration | Reason |
| ---------------- | ---------------- | ------ |
| `T020`-`T026` | 004 | User Story 3 (withdrawal, carry-forward, known-traps) depends on stable US1 event logging and US2 cap enforcement |
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

- Current roster snapshot: Review-operations maintainer, Coordinator handoff maintainer, Runtime routing maintainer, Decisions-ledger maintainer
- Technology and scope signals: PowerShell governance scripts, Markdown/YAML/JSON artifact contracts, runtime config sync, integration fixtures
- Task dependency graph: `T014` → `T015`/`T016` parallel → `T017` → `T018` with `T019` parallel to `T017`/`T018`
- Workstream separability: Bounded. `T015` and `T016` test different surfaces after `T014` completes. `T017` and `T018` work on the same script sequentially. `T019` works on distinct handoff surfaces.
- Shared-surface conflict risk: Moderate. `T017` and `T018` both touch `manage-reviewer-regression.ps1` and decisions-recording, so keep them serial. `T019` works on coordinator/reviewer prompt surfaces.
- Prior lockout-cap implementation evidence: None yet; this is the first US2 slice.
- Recommendation: Use the explicit parallel windows (`T015`/`T016` after `T014`, then `T019` parallel with `T017`/`T018`). Monitor shared-governance surface for contention.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 2 | Iteration slicing, traceability packaging, this plan document |
| Discovery/Spikes | 0 | No separate spike authorized in this US2 slice |
| Implementation | 12 | All six US2 tasks (`T014`-`T019`) |
| Review | 1 | Review US2 lockout-cap behavior, test coverage, and handoff integration |
| Rework | 0 | Small buffer reserved if review finds chain-counting or cap-activation misalignments |

## Implementation Approval

- **Approval Verdict**: ✅ **AUTHORIZED**
- **Approved By**: Alon Fliess
- **Recorded Evidence**: I authorize feature 008 iteration 003 (User Story 2 — implementer lockout-chain cap, tasks T014 through T019, 12 story points) implementation, review, retrospective, and closeout. Commit at every lifecycle boundary as you did for iteration 002 (planning, approval-recording, implementation, retro). Continue the plain-language three-section handoff format for every final user-facing response. Run the full six-script validation lane against the committed tree before declaring iteration 003 closed, and audit your own internal review pass for any reviewer-regression events that fired so we can record the first real-world detection if any do.
- **Recorded At**: 2026-05-10
- **Scope Pending Approval**: —
- **Gate Effect**: Implementation approved; execution may proceed

## Notes

- This plan carries User Story 2 only—the implementer lockout-chain cap—after Iteration 002 delivered the reviewer-regression routing infrastructure.
- The slice is deliberately bounded to US2 acceptance criteria: cap counting, cap activation at default two rotations, post-cap human or approved-alternate-owner routing, and cap visibility in decisions/handoff.
- User Story 1 (reviewer-regression routing) is complete in Iteration 002; US2 builds on the active reviewer-regression chain seeded by US1.
- User Story 3 (withdrawal, carry-forward, known-traps) is explicitly deferred to Iteration 004 because it builds on stable US1 event logging and US2 cap enforcement.
- Polish and full validation lane are explicitly deferred to Iteration 005.
- `T014` builds baseline fixtures for cap-hit, alternate-owner-approved, and awaiting-human-owned-revision scenarios in `tests/integration/fixtures/lockout-chain-cap/`.
- `T015` adds deterministic integration tests for lockout-cap behavior in `tests/integration/lockout-chain-cap.ps1`.
- `T016` extends closeout and replay assertions to verify cap visibility in `tests/integration/reviewer-closeout-governance.ps1` and `tests/integration/review-command.ps1`.
- `T017` implements the core lockout-chain counting, cap activation, and post-cap routing logic in `manage-reviewer-regression.ps1`.
- `T018` records cap-activation and reviewer-routing evidence in `.squad/decisions.md` through shared-governance helpers.
- `T019` surfaces locked-out agents, cap status, and planned next-owner path in coordinator guidance and user-facing handoff surfaces.

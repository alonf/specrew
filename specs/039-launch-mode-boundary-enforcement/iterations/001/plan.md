# Iteration Plan: 001

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Feature Tasks**: [../../tasks.md](../../tasks.md)  
**Iteration Tasks**: [tasks.md](tasks.md)  
**Status**: retro  
**Capacity**: 7.0/20 story_points  
**Started**: 2026-05-22  
**Current Boundary**: retro

## Summary

Iteration 001 plans the full Proposal 065 implementation slice for launch-mode boundary enforcement without crossing into implementation. The slice stays inside the user-approved scope lock: schema extension, helper contracts, verdict parsing, nine-boundary gate insertion, emergency bypass, tests, and mirror parity + CHANGELOG + INDEX.

**Target User Stories**: US1 through US3  
**Success Criteria**: Every FR-001 through FR-010 and AC1 through AC11 is mapped to executable work; capacity stays at 7.0 SP; all work remains blocked until a later before-implement authorization.

---

## Tasks

| Task | Title | Requirement | Story | Effort | Actual | Owner | Status |
| --- | --- | --- | --- | ---: | ---: | --- | --- |
| T001 | Audit boundary-entry surfaces and approved implementation scope | FR-001, FR-002, FR-006, AC10 | Setup | 0.25 | 0.25 | Reviewer | done |
| T002 | Extend schema v2 + canonical boundary validation + migration flow | FR-001, FR-006, FR-008, AC6, AC7, AC10 | Foundation | 0.75 | 0.75 | Implementer | done |
| T003 | Implement `Test-SpecrewBoundaryAuthorization` | FR-001, FR-002, FR-003, FR-005, FR-006, FR-007, AC1, AC8 | US1 | 0.50 | 0.50 | Implementer | done |
| T004 | Implement `Add-SpecrewBoundaryAuthorization` | FR-003, FR-006, FR-008, AC2, AC9 | US1 | 0.50 | 0.50 | Implementer | done |
| T005 | Implement `Parse-SpecrewBoundaryVerdict` | FR-003, FR-007, AC2, AC3, AC9 | US1 | 0.50 | 0.50 | Implementer | done |
| T006 | Implement `Write-SpecrewBoundaryAuthorizationDirective` | FR-003, FR-005, AC1, AC3, AC8 | US1 | 0.25 | 0.25 | Spec Steward | done |
| T007 | Insert authorization gate into all nine canonical boundary skills | FR-001, FR-002, FR-003, FR-005, FR-007, AC1, AC2, AC8, AC9 | US1 | 1.25 | 1.25 | Implementer | done |
| T008 | Add enforcement ledger + `specrew where` observability | FR-004, FR-008, FR-009, AC5, AC7, AC10 | US2 | 1.00 | 1.00 | Spec Steward | done |
| T009 | Implement session-scoped emergency bypass with mandatory reason | FR-010, AC4, AC5, AC6 | US2 | 0.75 | 0.75 | Implementer | done |
| T010 | Add Proposal-038 policy adapter seam with hard-stop default | FR-003, FR-006, AC8 | US3 | 0.25 | 0.25 | Spec Steward | done |
| T011 | Add automated coverage for AC1-AC10 surfaces | FR-001, FR-003, FR-004, FR-006, FR-008, FR-009, FR-010, AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8, AC9, AC10 | Polish | 0.50 | 0.50 | Test Owner | done |
| T012 | Replay the 2026-05-22 chain-past-plan incident (AC11) | FR-001, FR-002, FR-003, AC11 | Polish | 0.25 | 0.25 | Test Owner | done |
| T013 | Mirror parity + CHANGELOG + INDEX | FR-004, FR-010, AC10 | Polish | 0.25 | 0.25 | Reviewer | done |

**Total Planned Effort**: 7.0 SP

---

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Matches the repository iteration configuration and the task effort units in this plan. |
| Capacity per Iteration | 20 | Repository-wide default from `.specrew/iteration-config.yml`; this iteration intentionally uses 7.0 planned points within that ceiling. |
| Iteration Bounding | scope | The approved Proposal 065 slice stays fixed; overflow would defer rather than silently widen the iteration. |
| Time Limit (hours) | n/a | Scope-bounded iteration planning does not impose a time-box. |
| Overcommit Threshold | 1.0 | No overcommit is allowed without an explicit planning change. |
| Defer Strategy | manual | Any spillover must be called out explicitly in a later planning repair instead of being hidden in task wording. |
| Calibration Enabled | true | Retro can compare planned versus actual effort after implementation and review occur. |

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1.0 | Proposal 065 reconciliation closure, plan/task packaging, and scope-lock setup before implementation started. |
| Discovery/Spikes | 0.5 | Contract/reconciliation passes and empirical incident framing for the unauthorized boundary-crossing replay. |
| Implementation | 4.5 | Schema, helper, command-gate, dashboard, bypass, and mirror-parity delivery across T002-T010. |
| Review | 1.0 | Automated evidence lanes, review packet synthesis, review-signoff sync, and retro-boundary preparation. |
| Rework | 0.0 | Review accepted the delivered slice without reopening implementation scope. |

---

## Requirements Traceability Matrix

### Functional Requirements

| Spec Ref | Requirement | Task(s) | Owner(s) |
| --- | --- | --- | --- |
| FR-001 | Enforce nine lifecycle approval boundaries in all launch modes | T002, T003, T007, T011, T012 | Implementer, Test Owner |
| FR-002 | Enforce via CLI/tool-call hooks independent of agent prose | T001, T003, T007, T012 | Reviewer, Implementer, Test Owner |
| FR-003 | Block continuation until explicit authorization is recorded | T003, T004, T005, T006, T007, T010, T011, T012 | Implementer, Spec Steward, Test Owner |
| FR-004 | Log every enforcement event to `.squad/decisions.md` | T008, T011, T013 | Spec Steward, Test Owner, Reviewer |
| FR-005 | Detect bypass-attempt prose and override it | T003, T006, T007, T011 | Implementer, Spec Steward, Test Owner |
| FR-006 | Fail closed on hook/state failure | T001, T002, T003, T007, T010, T011 | Reviewer, Implementer, Spec Steward, Test Owner |
| FR-007 | Keep tool approvals and lifecycle approvals independent | T003, T005, T007, T011 | Implementer, Test Owner |
| FR-008 | Persist boundary enforcement state in `.specrew/start-context.json` | T002, T004, T008, T011 | Implementer, Spec Steward, Test Owner |
| FR-009 | Show boundary enforcement summary in `specrew where` | T008, T011 | Spec Steward, Test Owner |
| FR-010 | Provide emergency bypass with mandatory reason and audit trail | T001, T009, T011, T013 | Reviewer, Implementer, Test Owner |

### Acceptance Criteria

| AC Ref | Acceptance Signal | Task(s) | Owner(s) |
| --- | --- | --- | --- |
| AC1 | Chained `plan -> tasks` blocks at `tasks` with directive | T003, T006, T007, T011 | Implementer, Spec Steward, Test Owner |
| AC2 | Explicit `approved for tasks-boundary entry` authorizes retry | T004, T005, T007, T011 | Implementer, Test Owner |
| AC3 | Ambiguous verdicts remain unauthorized and show recognized shapes | T005, T006, T011 | Implementer, Spec Steward, Test Owner |
| AC4 | Bypass without `--reason` exits with error | T009, T011 | Implementer, Test Owner |
| AC5 | Bypass with reason succeeds and logs every bypassed boundary | T008, T009, T011 | Spec Steward, Implementer, Test Owner |
| AC6 | Pre-065 sessions receive migration directive then v2 schema | T002, T009, T011 | Implementer, Test Owner |
| AC7 | Corrupt state surfaces recovery/fail-closed behavior | T002, T008, T011 | Implementer, Spec Steward, Test Owner |
| AC8 | Hook failure propagates as skill failure; boundary stays blocked | T003, T006, T007, T010, T011 | Implementer, Spec Steward, Test Owner |
| AC9 | Compound `AND` verdict authorizes the substantive-review path | T004, T005, T007, T011 | Implementer, Test Owner |
| AC10 | Mirrors stay in parity across `extensions/` and `.specify/` | T002, T008, T011, T013 | Implementer, Spec Steward, Test Owner, Reviewer |
| AC11 | Replay of the 2026-05-22 clarify→plan→tasks incident blocks at tasks | T012 | Test Owner |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
| --- | --- | --- |
| **Spec Authority** | ✅ PASS | Tasks stay inside the user-approved Proposal 065 scope rows and do not add extra implementation surfaces beyond the agreed files. |
| **Layering** | ✅ PASS | Launcher work stays in `scripts\specrew-start.ps1`; reusable authorization logic stays in mirrored `shared-governance.ps1`; dashboard work stays in `scripts\specrew-where.ps1`; command gating stays in boundary command files. |
| **Traceability** | ✅ PASS | Every FR-001..FR-010 and AC1..AC11 maps to at least one planned task; AC11 remains a dedicated replay task. |
| **Ownership** | ✅ PASS | All tasks use the four-role baseline only: Implementer, Spec Steward, Reviewer, Test Owner. |
| **Capacity** | ✅ PASS | Planned effort totals exactly 7.0 SP, matching Proposal 065's stated single-iteration bound. |
| **Terminology** | ✅ PASS | Canonical boundary names use Proposal 090-compatible values: `specify`, `clarify`, `plan`, `tasks`, `before-implement`, `review-signoff`, `retro`, `iteration-closeout`, `feature-closeout`. |

---

## Scope Decisions Captured for Iteration 001

1. **Helper granularity is explicit**: each contract helper (`Test`, `Add`, `Parse`, `Write`) remains its own task instead of being folded into a generic governance-helper bucket.
2. **Gate insertion is singular but enumerated**: one task owns gate insertion, but it explicitly lists all nine canonical boundary skills so progress can be verified boundary by boundary.
3. **Test grouping is split into two layers**: `T011` covers the broad AC1-AC10 automation surface, while `T012` is reserved exclusively for AC11 replay evidence.
4. **Mirror parity + release surfaces are not hidden**: `T013` remains a standalone task covering mirror verification plus `CHANGELOG` and proposal `INDEX` updates.

---

## Dependency Order

1. `T001` → `T002`
2. `T002` → `T003-T010`
3. `T003-T006` → `T007`
4. `T007-T010` → `T011`
5. `T011` → `T012`
6. `T011` and `T012` → `T013`

**Parallelizable window**: After `T007-T010` stabilize, `T011` and `T013` may proceed in parallel because test coverage and release-surface updates touch different files.

---

## Blockers / Non-Goals

- **Implementation remains unopened**: this plan intentionally stops at task generation and does not authorize `before-implement`, `implement`, or later lifecycle work.
- **No production-code edits in this pass**: the paths above are future implementation targets only.
- **No scope outside Proposal 065**: no extra UX polish, no Proposal 098 visibility banner, and no unrelated governance chores are added here.

## Retro Boundary Notes

- Review-signoff is complete and the accepted review records the T011 rationale plus the named AC11 replay as the governing evidence chain.
- Retro-boundary is now the active lifecycle step for Iteration 001; iteration-closeout and feature-closeout remain explicitly unopened.
- The retrospective must elevate the three F-039-specific lessons captured in the retro authorization trail rather than collapsing them into generic process notes.

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22

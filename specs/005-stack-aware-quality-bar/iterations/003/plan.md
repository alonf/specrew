# Iteration Plan: 003

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 20/20 story_points
**Started**: 2026-05-08
**Completed**:

## Summary

Iteration 003 is the MVP execution slice for feature `005-stack-aware-quality-bar` Phase 2. It deliberately carries only the dependency-respecting Setup + Foundational work plus User Story 2 hardening-gate delivery (`T001`-`T014`) so the first execution approval can cover one truthful 20-point slice instead of the entire 32-task Phase 2 package.

Later Phase 2 work is explicitly deferred, not hidden: Iteration 004 will carry User Story 3 plus known-traps follow-through (`T015`-`T024`), and Iteration 005 will carry User Story 4 plus polish (`T025`-`T032`) after the MVP slice is accepted. Human execution approval is now recorded for this iteration, `T001` is complete, and no later task has started yet.

**Primary Focus**: hardening-gate planning surfaces, scaffolding, fail-closed governance, and the minimum prerequisite config/fixture work needed for the Phase 2 MVP  
**Target Slice**: Setup + Foundational + User Story 2 (`T001`-`T014`)  
**Execution Status**: `T001` complete; next ready tasks remain queued  
**Deferred Follow-On**: User Story 3 / known-traps (`T015`-`T024`) and User Story 4 / polish (`T025`-`T032`)

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-031, FR-032, FR-033 | Pre-implementation hardening gate, sign-off visibility, and blocking deferral rules | ✅ `T005`, `T007`, `T008`, `T009`, `T010`, `T011`, `T012`, `T013`, `T014` | Spec Steward + Planner + Implementer + Reviewer | MVP contract for Phase 2; must exist before any later lens/routing execution is approved. |
| FR-016, FR-017, FR-018 | Specialist lens catalog and activation planning surfaces | ✅ Enabling groundwork in `T005`, `T007`, `T008`, `T013`; ⏳ execution/evidence deferred | Spec Steward + Planner | Iteration 003 only creates the minimum planning/scaffold surfaces required before later lens execution. |
| FR-038, FR-039, FR-040 | Strongest-available routing policy and evidence model | ✅ Planning/config groundwork in `T001`, `T002`, `T003`, `T006`, `T008`, `T013`; ⏳ enforcement deferred | Implementer + Planner + Reviewer | Routing execution stays deferred until the lens orchestration surfaces exist. |
| FR-034, FR-035, FR-036, FR-037 | Known-traps corpus seeding, approval flow, and trap reapplication | ⏳ Deferred to Iteration 004 (`T015`-`T024`) | Spec Steward + Reviewer + Implementer | Depends on real lens evidence and should not be front-loaded into the MVP slice. |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | Scope is limited to the Phase 2 MVP slice described in `spec.md`, the repaired feature `plan.md`, and `tasks.md`; later work is named explicitly rather than implied. |
| **Traceability** | ✅ PASS | Every task row below maps to in-scope FRs or to clearly bounded prerequisite work for the same Phase 2 slice. |
| **Ownership** | ✅ PASS | Task owners remain within baseline Specrew roles: Spec Steward, Planner, Implementer, Reviewer. |
| **Capacity** | ✅ PASS | The active slice is capped at 20/20 story_points. Remaining Phase 2 work is deferred to Iterations 004 and 005 instead of overloading this plan. |
| **Execution Support** | ✅ PASS | `plan.md`, `state.md`, `drift-log.md`, and scaffolded `quality/` placeholders exist for Iteration 003, and execution truth now records the approved `T001` completion plus the remaining queued tasks. |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Extend downstream Phase 2 quality defaults in `scaffold-governance.ps1`, `templates/iteration-config.yml`, and `.specrew/iteration-config.yml` | FR-031, FR-038 | US-2, US-4 | 1 | Implementer | `extensions/specrew-speckit/scripts/scaffold-governance.ps1`, `extensions/specrew-speckit/templates/iteration-config.yml`, `.specrew/iteration-config.yml` | done | Implementer | 1 | pass |
| T002 | Seed `quality.known_traps_path` and `quality.routing` defaults in downstream config fixtures | FR-034, FR-038, FR-039 | US-3, US-4 | 1 | Implementer | `.specrew/config.yml`, `tests/integration/fixtures/quality-evidence-governance/**/.specrew/config.yml` | planned |  |  |  |
| T003 | Add agent `strength_rank` fixture coverage in Phase 2 iteration-config fixtures | FR-038, FR-040 | US-4 | 1 | Reviewer | `tests/integration/fixtures/quality-evidence-governance/**/.specrew/iteration-config.yml` | planned |  |  |  |
| T004 | Create Phase 2 fixture roots for hardening, lens execution, routing, and known-traps tests | FR-031, FR-016, FR-034, FR-038 | US-2, US-3, US-4 | 1 | Reviewer | `tests/integration/fixtures/hardening-gate-contract/**`, `tests/integration/fixtures/bug-hunter-lens-execution/**`, `tests/integration/fixtures/strongest-class-routing/**`, `tests/integration/fixtures/known-traps-corpus/**` | planned |  |  |  |
| T005 | Extend iteration/reviewer scaffolding to add `hardening-gate.md`, `quality/lenses/`, and `trap-reapplication.md` | FR-031, FR-016, FR-034 | US-2, US-3 | 2 | Implementer | `extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1`, `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1` | planned |  |  |  |
| T006 | Add Phase 2 parsing and approval helpers in `shared-governance.ps1` | FR-033, FR-038, FR-039 | US-2, US-4 | 1 | Reviewer | `extensions/specrew-speckit/scripts/shared-governance.ps1` | planned |  |  |  |
| T007 | Update Phase 2 lifecycle guidance in before-plan / before-implement / coordinator templates | FR-031, FR-032, FR-033 | US-2 | 1 | Spec Steward | `extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md`, `extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md`, `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | planned |  |  |  |
| T008 | Extend Phase 2 plan rendering for hardening focus areas, lens activation, routing policy, known-traps location, and explicit later deferrals | FR-010, FR-018, FR-031, FR-038 | US-2, US-3, US-4 | 2 | Planner | `.specify/templates/plan-template.md` | planned |  |  |  |
| T009 | Add hardening-gate fixtures for blocked, approved-deferral, and ready cases | FR-031, FR-032, FR-033 | US-2 | 1 | Reviewer | `tests/integration/fixtures/hardening-gate-contract/**/quality/hardening-gate.md` | planned |  |  |  |
| T010 | Add governance fixtures for hardening readiness in quality-evidence-governance tests | FR-031, FR-033 | US-2 | 1 | Reviewer | `tests/integration/fixtures/quality-evidence-governance/**/quality/hardening-gate.md` | planned |  |  |  |
| T011 | Add deterministic hardening-gate contract coverage in `tests/integration/hardening-gate-contract.ps1` | FR-031, FR-032, FR-033 | US-2 | 2 | Reviewer | `tests/integration/hardening-gate-contract.ps1`, `tests/integration/fixtures/hardening-gate-contract/**` | planned |  |  |  |
| T012 | Implement pre-implementation hardening orchestration in `run-hardening-gate.ps1` | FR-031, FR-032 | US-2 | 2 | Implementer | `extensions/specrew-speckit/scripts/run-hardening-gate.ps1` | planned |  |  |  |
| T013 | Extend hardening planning data in `resolve-quality-profile.ps1` and the plan template | FR-018, FR-031, FR-032 | US-2, US-3 | 2 | Planner | `extensions/specrew-speckit/scripts/resolve-quality-profile.ps1`, `.specify/templates/plan-template.md` | planned |  |  |  |
| T014 | Enforce hardening-gate blocking semantics and human deferral approval in `validate-governance.ps1` | FR-033 | US-2 | 2 | Reviewer | `extensions/specrew-speckit/scripts/validate-governance.ps1` | planned |  |  |  |

**Total Effort**: 20 story_points

---

## Planned Execution Order

1. Start with `T001`-`T004` to publish the Phase 2 config and fixture roots every later task depends on.
2. Land `T005` first in the Foundational block, then run `T006`, `T007`, and `T008` as the bounded parallel follow-ons described in the feature task list.
3. Begin User Story 2 with fixtures/tests (`T009`-`T011`) before touching the hardening implementation path.
4. Land `T012` and `T013` before `T014` so the governance validator binds to the final hardening artifact shape and planning metadata.
5. Stop at `T014`; do not start any User Story 3 or User Story 4 work inside this iteration.

---

## Deferred Follow-On

| Deferred Task(s) | Target Iteration | Reason |
| ---------------- | ---------------- | ------ |
| `T015`-`T024` | 004 | Specialist lens execution and known-traps follow-through depend on the hardening/artifact contract delivered by Iteration 003. |
| `T025`-`T032` | 005 | Strongest-class routing enforcement and polish should follow the lens execution surfaces rather than racing ahead of them. |

This is a capacity and dependency split, not a descoping decision. The deferred tasks remain part of the approved Phase 2 feature plan and must be carried forward explicitly.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | The Planner must make any future deferral decision explicit. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments when actual variance accumulates. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Technology and scope signals: this MVP slice mixes PowerShell governance scripts, lifecycle templates, and deterministic integration fixtures, so the work is cross-cutting rather than cleanly separable by same-specialty pairing.
- Task dependency graph: Setup (`T001`-`T004`) → Foundational (`T005`-`T008`) → User Story 2 tests (`T009`-`T011`) → User Story 2 implementation (`T012`-`T014`).
- Workstream separability: bounded. `T006`, `T007`, and `T008` can progress in parallel only after `T005`; `T009` and `T010` can proceed together before `T011`; `T012` and `T013` can proceed together before `T014`.
- Shared-surface conflict risk: elevated around `.specify/templates/plan-template.md`, `validate-governance.ps1`, and the scaffold scripts. Keep the slice serial outside the explicit parallel windows above.
- Recommendation: do not add same-specialty Junior/Senior expansion in Iteration 003. The current role split already exposes the safe parallel windows without overlapping ownership.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 4 | Iteration slicing, traceability packaging, lifecycle-guidance updates, and hardening planning-surface work (`T007`, `T008`, `T013`) |
| Discovery/Spikes | 0 | No separate spike is authorized in this repair pass |
| Implementation | 13 | Config defaults, fixture roots, scaffold updates, and hardening orchestration (`T001`-`T006`, `T009`-`T012`, `T014`) |
| Review | 2 | Reserve for deterministic test review and governance inspection once execution completes |
| Rework | 1 | Small buffer for contract-alignment fixes discovered during MVP execution |

## Implementation Approval

- **Approval Verdict**: approved
- **Approved By**: Alon Fliess
- **Recorded Evidence**: user message "Approve and proceed. No blockers. Commit the two pending changes, record execution approval in iteration 003, then start T001."
- **Recorded At**: 2026-05-08T15:00:23Z
- **Scope Approved for Execution**: Iteration 003 active slice (`T001`-`T014`) only
- **Gate Effect**: the execution approval gate is now cleared for Iteration 003; `T001` is complete and later tasks remain queued behind the planned dependency order.

## Notes

- This plan was repaired to resolve the Phase 2 blocker that previously implied one 20-point implementation iteration for the entire 32-task package.
- `iterations\003\state.md` and `iterations\003\drift-log.md` are synchronized to this task table; execution approval is recorded, `T001` is complete, and no later task is in progress.
- The scaffold-created `quality/` placeholders exist so future artifact helpers have a stable home, but they are not evidence of execution.

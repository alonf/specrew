# Iteration Plan: 001

**Schema**: v1
**Feature**: 019-specrew-distribution-module  
**Branch**: 019-specrew-distribution-module  
**Status**: planning-complete  
**Capacity**: 14/20 story_points
**Started**: 2026-05-16
**Created**: 2026-05-16  
**Updated**: 2026-05-16

## Overview

Iteration 001 covers the full Feature 019 implementation: PowerShell Gallery module packaging for one-line install, removing clone-and-PATH friction before public flip.

**Scope**: All 39 tasks across Phase 0 (T001-T006 design questions) + Pillars 1-5 (module packaging, resource bundling, init refactor, update story, publishing workflow) + final validation (T050-T056).

## Task Summary

Total tasks: 39  
Total effort estimate: 14 Story Points

### Task Breakdown by Phase

- **Phase 0 (Design Questions)**: T001-T006 (6 tasks, blocking decisions)
- **Pillar 1 (Module Packaging)**: T007-T009 (3 tasks, US1/US2/US4)
- **Pillar 2 (Resource Bundling)**: T010-T014 (5 tasks, US1/US2)
- **Pillar 3 (Init Refactor)**: T015-T019 (5 tasks, US2/US5)
- **Pillar 4 (Update Story)**: T030-T035 (6 tasks, US3/US5)
- **Pillar 5 (Publishing Workflow)**: T036-T042 (7 tasks, US4/US5)
- **Phase 6 (Final Validation)**: T050-T056 (7 tasks, US1-US5)

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T001-T006 | Design Questions (Phase 0) | FR-001..FR-032 | Setup | 2.0 | Planner | planned | — | — | — |
| T007-T009 | Module Packaging (Pillar 1) | FR-001..FR-004, FR-032 | US1, US2, US4 | 2.0 | Implementer | planned | — | — | — |
| T010-T014 | Resource Bundling (Pillar 2) | FR-006..FR-009 | US1, US2 | 2.0 | Implementer | planned | — | — | — |
| T015-T019 | Init Refactor (Pillar 3) | FR-010..FR-013, FR-030 | US2, US5 | 2.0 | Implementer | planned | — | — | — |
| T030-T035 | Update Story (Pillar 4) | FR-020..FR-024, FR-030 | US3, US5 | 2.0 | Implementer | planned | — | — | — |
| T036-T042 | Publishing Workflow (Pillar 5) | FR-005, FR-014, FR-025..FR-029 | US4, US5 | 2.0 | Implementer | planned | — | — | — |
| T050-T056 | Final Validation (Phase 6) | SC-001..SC-006 | US1-US5 | 2.0 | Reviewer | planned | — | — | — |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance |
| Capacity per Iteration | 20 | Repository capacity from `.specrew/iteration-config.yml` |
| Planned Effort | 14 | Grouped execution estimate for Iteration 001 |
| Iteration Bounding | scope | Iteration closes only when the approved scope is complete |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time` |
| Overcommit Threshold | 1.0 | No silent overcommit beyond the 20-point ceiling |
| Defer Strategy | manual | Any deferral must be named explicitly |
| Calibration Enabled | true | Retro should compare this grouped baseline against actual delivery |

## Critical Constraints

**⚠️ T001-T006 Design-Question Tasks**: Remain unresolved by design and MUST surface during implementation via pause-for-decision handling. Implementer must not auto-decide them.

## Authorization

- **Planning approval**: Alon Fliess (2026-05-16)
- **Hardening-gate sign-off**: Alon Fliess (2026-05-16T17:42:05Z)
- **Implementation authorization**: Alon Fliess (2026-05-16T17:42:05Z)

## Reference

Full task details in feature-level tasks.md:  
`file:///C:/Dev/Specrew/specs/019-specrew-distribution-module/tasks.md`

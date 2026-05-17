# Iteration Plan: 002

**Schema**: v1
**Feature**: 020-session-state-durability  
**Branch**: 020-session-state-durability  
**Status**: planning
**Capacity**: 15/20 story_points
**Started**: 2026-05-18
**Completed**:
**Created**: 2026-05-18
**Updated**: 2026-05-18

## Overview

Iteration 002 delivers the visibility and recovery slice for Feature 020: durable task-progress tracking, cross-worktree awareness for `specrew where`, substantive welcome-back prompts at `specrew start`, and shared PSGallery latest-version checks across `specrew start`, `specrew init`, and `specrew update`.

**Scope**: Pillar 2 (Task Progress Tracking), Pillar 3 (Cross-Worktree Awareness), Pillar 5 (Recovery Prompts), and Scope Addition 2 (PSGallery Check).

**User Stories Validated**: US3 (Authoritative Where-Am-I Query), US5 (PSGallery Latest-Version Check)

## Task Summary

Total tasks: 17 (I2-T001 through I2-T017)  
Total effort estimate: 15 Story Points

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| I2-T001 | Define `tasks-progress.yml` schema | FR-006, FR-007, FR-008, FR-009, FR-010 | US3 | 0.5 | Implementer | planned | — | — | — |
| I2-T002 | Implement task status update functions | FR-007, FR-008, FR-009 | US3 | 1.5 | Implementer | planned | — | — | — |
| I2-T003 | Integrate task progress into coordinator resume logic | FR-007 | US3 | 1.0 | Implementer | planned | — | — | — |
| I2-T004 | Test task progress tracking stability | FR-006, FR-008, FR-009, FR-010 | US3 | 1.0 | Reviewer | planned | — | — | — |
| I2-T005 | Implement worktree derivation from `git worktree list` | FR-011 | US3 | 1.5 | Implementer | planned | — | — | — |
| I2-T006 | Implement `specrew where --worktrees` command | FR-012, FR-013 | US3 | 1.0 | Implementer | planned | — | — | — |
| I2-T007 | Optimize cross-worktree derivation performance | FR-014 | US3 | 1.0 | Implementer | planned | — | — | — |
| I2-T008 | Test cross-worktree awareness in multi-worktree scenarios | FR-011, FR-012, FR-013, FR-014 | US3 | 1.0 | Reviewer | planned | — | — | — |
| I2-T009 | Design substantive welcome-back prompt structure | FR-021 | US3 | 0.5 | Implementer | planned | — | — | — |
| I2-T010 | Implement welcome-back prompt for mid-implementation | FR-022, FR-023 | US3 | 1.5 | Implementer | planned | — | — | — |
| I2-T011 | Implement validator state summary in prompt | FR-024 | US3 | 0.5 | Implementer | planned | — | — | — |
| I2-T012 | Test recovery prompt content quality | FR-021, FR-022, FR-023, FR-024 | US3 | 0.5 | Reviewer | planned | — | — | — |
| I2-T013 | Implement PSGallery latest-version query | FR-029, FR-030 | US5 | 1.0 | Implementer | planned | — | — | — |
| I2-T014 | Implement PSGallery update warning | FR-031, FR-035 | US5 | 0.5 | Implementer | planned | — | — | — |
| I2-T015 | Implement skip-update-check flag and env var | FR-032, FR-033 | US5 | 0.5 | Implementer | planned | — | — | — |
| I2-T016 | Implement PSGallery check graceful degradation | FR-034 | US5 | 0.5 | Implementer | planned | — | — | — |
| I2-T017 | Test PSGallery check in CI and offline scenarios | FR-029, FR-030, FR-032, FR-033, FR-034, FR-035 | US5 | 1.0 | Reviewer | planned | — | — | — |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance |
| Capacity per Iteration | 20 | Repository capacity from `.specrew/iteration-config.yml` |
| Planned Effort | 15 | Grouped execution estimate for Iteration 002 |
| Iteration Bounding | scope | Iteration closes only when the approved scope is complete |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time` |
| Overcommit Threshold | 1.0 | No overcommit beyond the 20-point ceiling |
| Defer Strategy | manual | Any new deferral requires explicit human approval and plan updates |
| Calibration Enabled | true | Retro should compare this grouped baseline against actual delivery |

## Phase Baseline

| Phase | Estimated Effort | Notes |
| --- | --- | --- |
| Planning | 1.0 | Iteration-start scaffold, task decomposition, and scope-lock bookkeeping |
| Discovery/Spikes | 0.5 | Reserved for bounded implementation discoveries inside the authorized Iteration 002 slice |
| Implementation | 11.5 | Task-progress, worktree awareness, recovery prompts, PSGallery checks, and regression coverage |
| Review | 1.5 | Post-implementation validator and integration evidence replay for US3 and US5 |
| Rework | 0.5 | Small bounded repair reserve without widening beyond Iteration 002 |

## Scope Guardrails

- **Iteration 001 stays closed**: Do not modify `specs\020-session-state-durability\iterations\001\*`.
- **Feature-level governance stays fixed**: Do not edit feature-level `spec.md`, `plan.md`, or `tasks.md`.
- **Task-progress authority**: `tasks-progress.yml` is iteration-local execution state and must preserve stable task IDs across task-list regeneration.
- **Cross-worktree derivation only**: Use `git worktree list --porcelain` plus worktree-local files; do not introduce persistent shared worktree state.
- **Prompt quality bar**: Recovery prompts must stay substantive, include next-step guidance, and surface validator warning summaries when present.
- **Version-check behavior**: PSGallery checks remain non-blocking, cache-backed, skippable, and silent on network failures except for verbose diagnostics.

## Dependencies

- **Critical path**: I2-T001 → I2-T002 → I2-T003 → I2-T010 → I2-T011 → I2-T012
- **Parallel work**: Workstream 2.2 (`I2-T005` through `I2-T008`) and Workstream 2.4 (`I2-T013` through `I2-T017`) may proceed independently once their local prerequisites are met.
- **Review dependencies**: I2-T004 depends on I2-T003, I2-T008 depends on I2-T007, I2-T012 depends on I2-T011, and I2-T017 depends on I2-T016.

## Validation Commands

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath . -IterationPath .\specs\020-session-state-durability\iterations\002
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\task-progress-tracking.tests.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\cross-worktree-awareness.tests.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\psgallery-check.tests.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\stale-state-detection.tests.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\version-checks.tests.ps1
```

## Authorization

- **Iteration-start**: authorized by Alon Fliess for the Iteration 002 scaffold and pre-implement validation run; branch context anchored to commit `e4b4f1f`
- **Planning approval**: this plan is the authoritative scope contract for Iteration 002 and must remain inside FR-006..014, FR-021..024, and FR-029..035
- **Implementation authorization**: pending successful pre-implement validator pass on the scaffolded Iteration 002 artifacts
- **Review / retro / closeout**: not authorized in this run; stop at iteration-completion handoff

## Traceability Summary

- Requirement scope for this iteration: FR-006..014, FR-021..024, FR-029..035
- User stories represented in current scope: US3, US5
- All 17 tasks map directly to the scoped requirements above and preserve the feature-level dependency structure

## Notes

- The iteration-start scaffold was created with repository helper scripts and retains the canonical bookkeeping sections, including `## Phase Baseline`.
- Use concrete commit hashes rather than symbolic refs when recording execution progress, validator evidence, and boundary handoffs.
- Keep warning surfaces observable in captured output so CI and scripted tests can assert the exact user-facing text.

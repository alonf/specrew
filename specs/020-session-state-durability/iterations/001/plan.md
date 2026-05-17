# Iteration Plan: 001

**Schema**: v1
**Feature**: 020-session-state-durability  
**Branch**: 020-session-state-durability  
**Status**: implementation-complete
**Capacity**: 16/20 story_points
**Started**: 2026-05-18
**Created**: 2026-05-18  
**Updated**: 2026-05-18

## Overview

Iteration 001 covers foundational session-state correctness: atomic boundary-event synchronization, stale-state detection at `specrew start`, and module version mismatch warnings. This slice establishes the durability foundation that prevents Squad from acting on stale feature references after system restarts or boundary events.

**Scope**: Pillar 1 (Boundary-Event Sync), Pillar 4 (Stale-State Detection), and Scope Addition 1 (Module Version Check). Phase 0 companion chore prerequisites (CHORE-001 through CHORE-004) completed and merged to main before iteration implementation (commit 9f63790, merged at b5e4461).

**User Stories Validated**: US1 (Post-Reboot Recovery), US2 (Boundary-Event State Synchronization), US4 (Module/Project Version Mismatch Detection)

## Task Summary

Total tasks: 14 (I1-T001 through I1-T014)  
Total effort estimate: 16 Story Points

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| I1-T001 | Design `sync-boundary-state.ps1` API | FR-001, FR-002, FR-003 | US2 | 1.0 | Implementer | done | Implementer | 1.0 | PASS |
| I1-T002 | Implement write-temp-then-rename for single file | FR-004 | US2 | 1.5 | Implementer | done | Implementer | 1.5 | PASS |
| I1-T003 | Implement multi-file sync orchestration | FR-005 | US2 | 2.0 | Implementer | done | Implementer | 2.0 | PASS |
| I1-T004 | Integrate sync-boundary-state into seven boundaries | FR-003 | US2 | 2.0 | Implementer | done | Implementer | 2.0 | PASS |
| I1-T005 | Test boundary-event sync atomicity | FR-001, FR-004 | US2 | 1.0 | Reviewer | done | Implementer | 1.0 | PASS |
| I1-T006 | Implement merge-detection check | FR-015 | US1 | 1.5 | Implementer | done | Implementer | 1.5 | PASS |
| I1-T007 | Implement branch-existence check | FR-016 | US1 | 0.5 | Implementer | done | Implementer | 0.5 | PASS |
| I1-T008 | Implement authorization-record check | FR-017 | US1 | 1.0 | Implementer | done | Implementer | 1.0 | PASS |
| I1-T009 | Implement cross-file consistency check | FR-018 | US1 | 1.5 | Implementer | done | Implementer | 1.5 | PASS |
| I1-T010 | Implement stale-state user prompt | FR-019, FR-020 | US1 | 1.5 | Implementer | done | Implementer | 1.5 | PASS |
| I1-T011 | Test stale-state detection coverage | FR-015, FR-016, FR-017, FR-018 | US1 | 1.0 | Reviewer | done | Implementer | 1.0 | PASS |
| I1-T012 | Implement module-vs-project version comparison | FR-025 | US4 | 0.5 | Implementer | done | Implementer | 0.5 | PASS |
| I1-T013 | Implement version mismatch warning | FR-026, FR-027, FR-028 | US4 | 0.5 | Implementer | done | Implementer | 0.5 | PASS |
| I1-T014 | Test module version check in CI | FR-025, FR-026, FR-027, FR-028 | US4 | 0.5 | Reviewer | done | Implementer | 0.5 | PASS |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance |
| Capacity per Iteration | 20 | Repository capacity from `.specrew/iteration-config.yml` |
| Planned Effort | 16 | Grouped execution estimate for Iteration 001 |
| Iteration Bounding | scope | Iteration closes only when the approved scope is complete |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time` |
| Overcommit Threshold | 1.0 | No overcommit beyond the 20-point ceiling |
| Defer Strategy | manual | Any deferral must be named explicitly and deferred to Iteration 002 |
| Calibration Enabled | true | Retro should compare this grouped baseline against actual delivery |

## Scope Guardrails

- **Phase 0 prerequisite**: ✓ Phase 0 companion chore (CHORE-001 through CHORE-004) completed and merged to main at commit 9f63790 (2026-05-18), merged into branch at b5e4461. Establishes the `.squad/identity/now.md` closeout pattern.
- **Cross-platform baseline**: Tests must pass on Windows/Linux/macOS with PowerShell 5.1 and Core 7+.
- **Iteration 2 deferred**: Task progress tracking, cross-worktree awareness, PSGallery checks, and recovery prompt enhancements remain in Iteration 2.
- **Performance boundary**: `specrew start` stale-state checks must complete within 2 seconds.
- **Atomicity requirement**: Multi-file boundary-event sync must use write-temp-then-rename pattern to prevent partial corruption.

## Authorization

- **Iteration-start**: ✓ Alon Fliess (2026-05-18, commit 0e90d1f restored planning artifacts and preserved Iteration-start authorization)
- **Planning approval**: planning approved at task-validation pass (commit `e456f3b`)
- **Phase 0 completion**: ✓ CHORE-001–CHORE-004 merged to main at 9f63790, integrated at b5e4461 (2026-05-18)
- **Implementation authorization**: before-implement gate passed at commit `6d3aaa7`, implementation authorized
- **Review status**: pending independent review after implementation-complete handoff

## Notes

- T005 and T011 include manual backward-compatibility testing as part of reviewer verification.
- T014 captures the version-check coverage lane for `specrew start`; the bounded repair on 2026-05-18 restored the exact FR-026 warning text by resolving the running-module manifest version and emitting the warning on standard output.
- Iteration-start boundary is explicitly authorized per Feature 020 authorization context (commit 0e90d1f restored planning artifacts and preserved Iteration-start authorization).

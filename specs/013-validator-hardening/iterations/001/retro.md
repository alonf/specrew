# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-05-12

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 1 | 1 | 0 |
| T002 | 0.5 | 0.5 | 0 |
| T003 | 2 | 2 | 0 |
| T004 | 1 | 1 | 0 |
| T005 | 0.5 | 0.5 | 0 |
| T006 | 1 | 1 | 0 |
| T007 | 1 | 1 | 0 |
| T008 | 2 | 2 | 0 |
| T009 | 0.5 | 0.5 | 0 |
| T010 | 1 | 1 | 0 |
| T011 | 1 | 1 | 0 |
| T012 | 1 | 1 | 0 |
| T013 | 0.5 | 0.5 | 0 |

**Average variance**: +/- 0  
**Utilization**: 13/20 story_points (65% of capacity)

The canonical-schema and graceful-error slice landed at the planned effort. The only extra friction came from review-boundary truthfulness repairs, but those stayed inside the original task budget and did not force scope expansion beyond `T001` through `T013`.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1.5 | 1.5 | 0 | Baseline capture and trap reapplication stayed bounded to the approved iteration-001 slice. |
| Discovery/Spikes | 0 | 0 | 0 | No separate discovery spike was needed because the feature-local contracts already bounded the implementation clearly. |
| Implementation | 10.5 | 10.5 | 0 | Structured FAIL plumbing, canonical-schema enforcement, canonical-concern enforcement, fixture creation, and replay-harness proof all landed inside the planned window. |
| Review | 0.5 | 0.5 | 0 | Review accepted after one narrow precision repair for lowercase canonical-label handling and one harness-truthfulness repair. |
| Rework | 0 | 0 | 0 | The review-found fixes stayed small and were absorbed inside the planned execution effort rather than becoming a separate rework phase. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0
- The iteration stayed within the approved canonical-schema and graceful-error boundary; the only late movement was tighter evidence truthfulness during review, not scope drift.

## What Went Well

1. **The validator now fails clearly instead of crashing opaquely.** The shared structured FAIL surface covers missing artifacts, canonical-schema deviations, concern-order violations, and unexpected validator input with file path, line number when known, category, message, and remediation hint. That directly closes the feature line’s original “raw PowerShell exception” failure mode instead of merely hiding it behind generic errors.

2. **Replay-path proof stayed on the real validator surface.** `tests\integration\validator-hardening-iteration1.ps1` builds scratch workspaces and calls the real `validate-governance.ps1` command rather than asserting on helper internals only. That kept the slice aligned with the scaffold/replay-path trap from the known-traps corpus and made the accepted review evidence much stronger.

3. **Grandfathering avoided false positives on historical iterations.** The implementation kept the new canonical-schema and canonical-concern rules scoped to feature ordinal `013` and later. That let the repo-wide validator stay green across features `001`, `005`, `007`, `008`, `009`, `011`, and `012` while still hardening the new feature line.

4. **Readable-reference dogfooding stayed present in the lifecycle prose.** The iteration plan, review, and this retrospective consistently name feature `013`, validator hardening, and iteration `001`, the canonical-schema and graceful-error slice, rather than leaning on naked numbers alone. No `soft-warning.numeric-id-undescribed` event was observed during this iteration’s recorded artifacts.

## What Didn't Go Well

1. **Lowercase canonical-label drift was not covered until review.** The initial implementation correctly failed non-canonical aliases such as `Overall Status:`, but lowercase bold labels such as `**schema**:` still fell through to a generic missing-field path. The review caught that precision gap before acceptance, but the fixture should have existed earlier in the implementation boundary.

2. **The replay harness was coupled to the live iteration plan state.** Once the real iteration plan moved to “review accepted,” scratch workspaces copied that live metadata and started implying `review.md` should exist, which made compliant fixture scenarios fail for the wrong reason. The harness now normalizes those lifecycle fields back to pending inside scratch copies, but that coupling should have been anticipated sooner.

3. **Runtime-evidence bookkeeping remains easy to forget.** The delegated `after-tasks`, `before-implement`, and review routes all needed explicit `.squad\decisions.md` entries. The evidence was recorded correctly, but only after a deliberate follow-through pass rather than naturally emerging from the workflow.

## Improvement Actions

1. **Owner:** Test maintainer | **Phase:** next validator-hardening implementation slice | **Type:** process | **Action:** Add case-drift fixtures for every new canonical label rule at the same time the first alias or missing-field fixture lands.  
   **Expected effect:** Review no longer becomes the first place a rule precision gap appears.

2. **Owner:** Test maintainer | **Phase:** next replay-harness update | **Type:** process | **Action:** Keep scratch-workspace plan templates normalized to pending lifecycle fields so replay fixtures test validator rules, not the current state of the real iteration artifacts.  
   **Expected effect:** Replay-path tests remain stable across implementation, review, retro, and closeout boundaries.

3. **Owner:** Coordinator | **Phase:** next delegated lifecycle step | **Type:** process | **Action:** Record `.squad\decisions.md` runtime-evidence entries immediately after each delegated gate or review agent completes rather than batching them later.  
   **Expected effect:** Lifecycle routing evidence becomes routine and less likely to need boundary-time catch-up.

4. **Owner:** Reviewer | **Phase:** next validator-hardening review lane | **Type:** process | **Action:** Keep rerunning both the iteration replay harness and the repo-wide validator whenever review repairs touch shared validator helpers or canonical-label logic.  
   **Expected effect:** Precision repairs keep proving both the narrow slice and the broader historical corpus together.

## Calibration Suggestion

- **Suggested capacity adjustment**: keep the 20 story_point baseline unchanged.
- **Rationale**: The iteration delivered 13/13 planned story_points with zero task variance, no scope drift, and a first-pass review that required only a narrow precision repair rather than a slice rethink.

## Notes

- This retrospective stays specific to feature `013`, validator hardening, iteration `001`, the canonical-schema and graceful-error slice.
- The retrospective boundary is complete on the current tree. Closeout is still a separate next step and is not claimed here.
- Review and regression evidence come from `specs\013-validator-hardening\iterations\001\review.md`, `specs\013-validator-hardening\iterations\001\quality\hardening-gate.md`, `specs\013-validator-hardening\quickstart.md`, `tests\integration\validator-hardening-iteration1.ps1`, and `extensions\specrew-speckit\scripts\validate-governance.ps1`.

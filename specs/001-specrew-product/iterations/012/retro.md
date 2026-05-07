# Retrospective: Iteration 012

**Schema**: v1
**Date**: 2026-05-07

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T-1201 | 1 | 1 | 0 |
| T-1202 | 2 | 2 | 0 |
| T-1203 | 1 | 1 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | The slice stayed narrow once the start-flow fixes were separated from the governance correction. |
| Implementation | 2 | 2 | 0 | Both defects had direct root causes in the wrapper and same-window launch path, so the repair stayed surgical. |
| Review | 1 | 1 | 0 | The start-command integration suite covered both behaviors in one isolated pass. |
| Rework | 0 | 0 | 0 | No extra repair loop was needed after the isolated validation run. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- The wrapper fix and the Windows launch fix were both small, testable repairs once they were isolated from the governance slice.
- The new regression coverage reproduces the exact user-facing failures instead of relying on indirect smoke signals.
- Keeping the slice separate preserved the forward-only history boundary restored by Iteration 011.

## What Didn't Go Well

- The original wrapper assumed `.` would resolve from the downstream project, but PowerShell resolved it relative to the Specrew script process instead.
- The inline Windows same-window Copilot invocation relied on npm's PowerShell shim behavior, which caused the interactive handoff to return immediately.

## Improvement Actions

1. Owner: Implementer | Phase: next implementation | Type: implementation | Expected effect: keep launch-flow regressions close to the wrapper and handoff logic so future changes cannot bypass the downstream-project path contract.
2. Owner: Planner | Phase: next planning | Type: process | Expected effect: keep unrelated runtime ergonomics fixes out of governance-correction slices so reviewer evidence remains easy to trust.

## Calibration Suggestion

- Suggested capacity adjustment: keep current baseline at 20 story_points
- Rationale: the repair stayed small and predictable once it was isolated into its own iteration.

## Notes

- This artifact closes the `specrew start` ergonomics repair slice.
- The next roadmap slice is the downstream repo-hygiene contract (`FR-055`).

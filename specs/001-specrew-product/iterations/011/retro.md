# Retrospective: Iteration 011

**Schema**: v1
**Date**: 2026-05-07

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T-1101 | 2 | 2 | 0 |
| T-1102 | 1 | 1 | 0 |
| T-1103 | 1 | 1 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | The slice was re-scoped cleanly once Iteration 009 was restored instead of patched in place. |
| Implementation | 2 | 2 | 0 | The cutoff/config/test/defer-evidence edits were already understood; the main work was re-homing them under the correct iteration. |
| Review | 1 | 1 | 0 | Targeted reviewer-closeout regression coverage plus repo governance validation were sufficient to prove the slice. |
| Rework | 0 | 0 | 0 | No extra repair loop was needed after the forward-only boundary was restored. |

## Drift Summary

- Total drift events: 1
- Resolved via spec update: 0
- Resolved via implementation correction: 0
- Resolved via revert: 1
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- Restoring Iteration 009 before continuing prevented the same FR-054 failure from being repeated in the commit history.
- The closeout cutoff is small, understandable, and now locked down with an explicit-target legacy regression test.
- The defer evidence stayed canonical in `.squad\decisions.md` instead of being buried in a closed review packet.

## What Didn't Go Well

- The working tree mixed the governance correction with the unrelated `specrew start` repair, which would have contaminated reviewer evidence if the slice had not been re-isolated first.
- The follow-on governance hot-fix after Iteration 010 was not attributed forward until this corrective slice was created.

## Improvement Actions

1. Owner: Planner | Phase: next planning | Type: process | Expected effect: treat all post-close governance corrections as new iterations immediately instead of preparing edits inside closed iteration directories.
2. Owner: Implementer | Phase: next implementation | Type: implementation | Expected effect: implement the deferred FR-054 immutable-snapshot guardrail so future post-close mutations are blocked automatically.

## Calibration Suggestion

- Suggested capacity adjustment: keep current baseline at 20 story_points
- Rationale: the corrective slice remained small and predictable once the forward-only boundary was re-established.

## Notes

- This artifact closes the forward-only reviewer-closeout cutoff repair.
- Iteration 012 remains the next ready corrective slice before the roadmap resumes with FR-055.

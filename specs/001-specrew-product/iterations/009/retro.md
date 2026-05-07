# Retrospective: Iteration 009

**Schema**: v1
**Date**: 2026-05-07

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T-901 | 2 | 2 | 0 |
| T-902 | 1 | 1 | 0 |
| T-903 | 2 | 2 | 0 |
| T-904 | 2 | 2 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | The corrective slice was easy to isolate once the immutability violation was treated as the primary defect. |
| Implementation | 3 | 3 | 0 | Validator, contract, and test changes stayed tightly scoped to reviewer closeout enforcement. |
| Review | 2 | 2 | 0 | Reviewer regressions plus repo-wide validation were enough to prove the fix and the 008 rollback. |
| Rework | 1 | 1 | 0 | One enforcement-scope edge case needed a quick correction so historical iterations stayed green while the latest iteration remained enforced. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- Treating the Iteration 008 mutation as an FR-054 defect produced a cleaner fix than trying to patch the packet in place.
- The new regression test locked down the exact governance hole that allowed a code-touching iteration to close without the reviewer packet.
- Existing reviewer and gap-governance tests remained reusable after a small fixture update, so the corrective slice did not need a new test harness.

## What Didn't Go Well

- The first enforcement-scope check overreached and briefly treated legacy iterations as explicitly targeted because of a null/Count edge case.
- The original retroactive Iteration 008 fix solved the functional problem but crossed the iteration immutability boundary, which required a second corrective pass.

## Improvement Actions

1. Owner: Reviewer | Phase: next planning | Type: process | Expected effect: treat post-close reviewer-packet gaps as a new corrective iteration by default instead of patching the closed packet in place.
2. Owner: Implementer | Phase: next implementation | Type: implementation | Expected effect: keep validator scope rules explicit whenever new closeout requirements distinguish latest iterations from legacy snapshots.

## Calibration Suggestion

- Suggested capacity adjustment: keep current baseline at 20 story_points
- Rationale: the corrective slice stayed within the planned governance hardening budget with no meaningful variance.

## Notes

- This artifact was scaffolded from plan.md, state.md, drift-log.md, and review.md for Squad's built-in Retrospective ceremony.
- Iteration 009 resolves the reviewer closeout enforcement / immutability breach before the roadmap resumes with FR-042 validation lanes.

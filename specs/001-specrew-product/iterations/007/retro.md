# Retrospective: Iteration 007

**Schema**: v1
**Date**: 2026-05-06

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T-701 | 2 | 2 | 0 |
| T-702 | 2 | 2 | 0 |
| T-703 | 2 | 2 | 0 |
| T-704 | 2 | 2 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | The Iteration 7 contract was crisp once the reviewer-index and validator gaps were isolated. |
| Implementation | 4 | 4 | 0 | Shared helper, validator, and reviewer-surface changes landed without widening the slice. |
| Review | 2 | 2 | 0 | The new scratch test plus the touched regression tests covered the governance hardening thoroughly. |
| Rework | 1 | 1 | 0 | The buffer absorbed parser and gap-ledger normalization fixes without changing scope. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- The structured ledger helper let the validator and reviewer surfaces share one canonical evidence source instead of duplicating governance parsing logic.
- The new scratch integration test proved both the failing and passing no-gap paths, which made the Iteration 7 behavior easy to lock down.
- Existing start and resume routing tests continued to pass after the shared-governance changes, which kept the hardening additive instead of destabilizing.

## What Didn't Go Well

- The first parser implementation for decisions-ledger headings over-relied on `$Matches`, which broke on real ledger input and needed one rework pass.
- Gap-ledger parsing initially treated markdown separators as active concerns, which surfaced as a validator false positive on historical product artifacts.

## Improvement Actions

1. Owner: Implementer | Phase: next implementation | Type: implementation | Expected effect: extract shared ledger-entry parsing helpers further so future governance slices do not duplicate regex-heavy field extraction.
2. Owner: Reviewer | Phase: next planning | Type: process | Expected effect: define the preferred wording pattern for fixed-now versus deferred gap-ledger entries so future iterations stay consistent and validator-friendly.

## Calibration Suggestion

- Suggested capacity adjustment: keep current baseline at 20 story_points
- Rationale: task and phase variance both closed at zero, and the governance slice stayed within its planned rework reserve.

## Notes

- This artifact was scaffolded from plan.md, state.md, drift-log.md, and review.md for Squad's built-in Retrospective ceremony.
- Iteration 007 completes the no-gap governance hardening slice. Iteration 8 is now the next ready work.

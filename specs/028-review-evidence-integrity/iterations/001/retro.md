# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-05-21
**Review Boundary Ref**: accepted review on the current Feature 028 working tree
**Retro Boundary Ref**: current retrospective artifact on branch `028-review-evidence-integrity`

## Iteration Overview

Feature 028 Iteration 001 delivered the full pre-review evidence-integrity slice in
one bounded pass: the validator now blocks zero-diff declared-work gaps, reviewer
artifacts emit loud warnings instead of silent "below threshold" omissions,
`Test-FormMeaningParity` is available as the immutable Proposal 030 seed helper,
and reviewer evidence can be regenerated safely with `-Force` and
`-Confirm:$false`. The iteration also repaired the initial implementation blind
spots by switching declared-work detection to the real iteration task-table
contract and by replacing the placeholder Pester file with a standalone
scratch-repo regression lane.

**Estimation accuracy**: 18 SP planned = 18 SP delivered; zero variance across the
five grouped work packets recorded in the iteration plan.

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T004-T009 | 3 | 3 | 0 |
| T010-T016 | 4 | 4 | 0 |
| T017-T023 | 3 | 3 | 0 |
| T024-T031 | 3 | 3 | 0 |
| T032-T050 | 5 | 5 | 0 |

**Average variance**: 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | complete | complete | 0 | Clarify decisions Q1-Q6 resolved the key behavioral questions before implementation started. |
| Discovery/Spikes | complete | complete | 0 | The repair audit identified the real declared-work contract and the test-harness mismatch without reopening scope. |
| Implementation | 18 | 18 | 0 | Validator, helper, scaffolder, docs, and regression-lane work all landed in the same bounded slice. |
| Review | complete | complete | 0 | Review approved after the gate logic and integration lane were made truthful. |
| Retro | complete | complete | 0 | This artifact captures the lessons of the delivered slice without reopening implementation. |
| Iteration Closeout | complete | complete | 0 | Reviewer packet and `dashboard.md` are present on the current tree. |
| Rework | 0 | 0 | 0 | No accepted review finding reopened scope after the repaired implementation landed. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

1. **The repaired gate now measures the real artifact contract.** The implementation moved away from invented `state.md` counters and uses the iteration `plan.md` Tasks table first, with `state.md` task tables only as legacy fallback. That change made the validator and scaffolder line up with how real Specrew iterations are authored.

2. **The new integration lane proves the slice behavior end to end.** The standalone scratch-repo script exercises the zero-diff failure, empty-iteration no-false-positive, committed implementation no-false-positive, and late-commit rerun scenarios without relying on an ambient repo state.

3. **The AC8 check stayed evidence-based.** Running `validate-governance.ps1` for Feature 017 Iteration 001 on both clean `main` and the Feature 028 branch produced the same legacy failure mode, which confirmed the new rule is not the source of that old governance debt.

## What Didn't Go Well

1. **The first implementation pass overfit the draft plan instead of the repo’s actual artifact shape.** It assumed a completed-task counter lived in `state.md` and treated a Pester `Describe` file as an acceptable integration lane. Both assumptions were wrong and had to be repaired after audit.

2. **The feature artifacts lagged the real implementation state.** `tasks.md` and the generated iteration plan both preserved stale wording about `state.md` counters and Pester-based integration tests after the implementation had already moved to the correct task-table and standalone-script model.

## Improvement Actions

1. Owner: Planner / Implementer | Phase: next governance-heavy slice | Type: process | Expected effect: verify the real on-disk artifact contract before coding validator logic so draft-plan wording does not outrun the repository’s actual lifecycle shapes.
2. Owner: Reviewer / Test author | Phase: next integration-lane slice | Type: testing | Expected effect: prefer standalone scratch-repo scripts for governance integrations unless the repo already uses Pester as the authoritative execution harness for that lane.

## Calibration Suggestion

- Suggested capacity adjustment: keep the current baseline for governance-heavy single-iteration slices at ~18 SP when the work spans validator logic, reviewer scaffolding, docs, and end-to-end regression evidence.
- Rationale: The slice stayed within estimate once the work was grouped by true delivery packets rather than by every intermediate planning task.

## Notes

- This retrospective was seeded from the generated scaffold and then normalized to the delivered Feature 028 evidence.
- No deferred implementation work remains inside Iteration 001; the remaining lifecycle work is feature-closeout only.

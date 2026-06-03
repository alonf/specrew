# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-06-03

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 1 | 1 | 0 |
| T002 | 2 | 2 | 0 |
| T003 | 2 | 2 | 0 |
| T004 | 1 | 1 | 0 |
| T005 | 2 | 2 | 0 |
| T007 | 3 | 3 | 0 |
| T008 | 2 | 2 | 0 |
| T009 | 2 | 2 | 0 |
| T006 | 1 | 1 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | Scope confirmed; reproduction-first per defect. |
| Implementation | 10 | 10 | 0 | Planned tasks on estimate; significant UNPLANNED mid-flight work folded in without inflating task SP: the FR-024 enforcement-gap stick fix, the start/resume task-progress source-of-truth bug, the strict merge-detection fix, and the before-implement verdict reconciliation. |
| Review | 5 | 5 | 0 | On estimate; one review-signoff send-back rework loop to fix a pre-existing red required-CI test (`fcccfad3`). |
| Rework | 0 | ~1 | +1 | Unplanned: the send-back (pre-existing `non-specrew-session-bypass` stale assertion) + the premature review-signoff phase flip that FAILed the required-artifact check until review.md existed. |

## Drift Summary

- Total drift events: 1
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- **Reproduce-first caught real defects, not just confirmed expectations.** The FR-024 end-to-end enforcement test surfaced the silent re-anchor stick gap that the isolated unit tests could not (drift-log Event 1); the task-progress regression exposed the iteration-1-`tasks.md` downgrade; FR-011/FR-014 each FAILED pre-fix and passed after.
- **Strict, layered root-causing.** The merge-detection false positive (bare-number `--grep`), the task-progress source-of-truth bug (feature-root `tasks.md` is Iteration 1), and the FR-011 layer confusion were each diagnosed to the exact mechanism before fixing.
- **Honest state reconciliation.** The before-implement authorization was recorded as an explicit, non-backdated reconciliation; the task ledger was synced to `state.md`; T004 was closed as verify-clean with a guard rather than a fabricated fix.
- **Advisor consults sharpened the approach** at the two genuine forks (the start-flow stick fix; the FR-011 measured-the-wrong-layer correction).

## What Didn't Go Well

- **The FR-011 reproduce was initially measured at the wrong layer.** A file-layer grep for `specs//` is vacuous (the prompt holds the literal `<feature>` placeholder); the defect lives where the coordinator substitutes an empty feature. Cost investigation time before the advisor reframed it.
- **A pre-existing red required-CI test blocked review-signoff.** `non-specrew-session-bypass` grepped `specrew-start.ps1` for closeout phrases that had moved into the coordinator governance template — unrelated to this work but merge-blocking, forcing a send-back.
- **Premature lifecycle-state flip FAILed the validator.** Setting `Current Phase: review-signoff` before review.md existed tripped the required-artifact check (correctly).
- **Repeatable hazard:** reusing bare `T0NN` task IDs across iterations let Iteration 1's `tasks.md` contaminate Iteration 2's progress — a latent trap for any multi-iteration feature.

## Improvement Actions

1. Owner: Implementer | Phase: next iteration | Type: testing | Expected effect: for any "clears X / state sticks" behavior, add an end-to-end enforcement test (not just an isolated unit test) — the FR-024 stick gap proves isolated tests miss same-run regressions.
2. Owner: Planner/Spec Steward | Phase: next planning | Type: process | Expected effect: prefer iteration-prefixed task IDs (`I<n>-T0NN`) for multi-iteration features, or keep status strictly ledger-sourced (now enforced), to avoid cross-iteration `tasks.md` contamination.
3. Owner: Reviewer | Phase: pre-review | Type: process | Expected effect: run the required-CI suite (not just the iteration's own tests) before signaling review-signoff, so a pre-existing red test is caught before the gate, not at it.

## Calibration Suggestion

- Suggested capacity adjustment: keep the current 20 SP iteration baseline (no change).
- Rationale: planned-task variance was 0 (every task Actual = Estimate). The real signal is **unplanned mid-flight work** (enforcement-gap fix, task-progress bug, verdict reconciliation, pre-existing-test fix) absorbed without dropping scope — budget a small unplanned-discovery buffer rather than raising the cap.

## Notes

- This artifact was scaffolded from plan.md, state.md, drift-log.md, and review.md for Squad's built-in Retrospective ceremony.
- Replace all TBD placeholders with evidence from the completed iteration before marking the retro phase complete.
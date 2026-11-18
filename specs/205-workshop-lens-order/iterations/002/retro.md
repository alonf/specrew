# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-11-15

Written from the commit history, the drift log, the review record, the hand-over to 203 and the CI runs, not from
memory. The iteration ran from 2026-11-13 19:23 (before-implement approved, `22337b64`) to 2026-11-15 02:50 (review
sign-off approved, `9c9a132f`). It had 27 commits after before-implement, up to the records commit `38aebf0e`: 9 tasks
(20 SP), two codex rounds, 3 findings, 26 drift entries and 8 hand-overs to feature 203 (H-015 to H-022). The retro
scaffold refused to run (DRIFT-026), so this file was written without it. Times are local (UTC+2).

## Estimation Accuracy

Per-task effort was not time-tracked. The stand-ins are landing time and the review findings in each task's code.

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T018 (length and consumer test, red first) | 4 | landed 11-13 19:36 (`b29ba4e5`), 5 recorded numbers red first; **all 3 round 1 findings** were in its code: totals hid a swapped suffix, exempt questions were counted rather than identified, and a `lens:` consumer was not checked to receive the answer | under-built: every check was an aggregate, so a change that kept the totals passed |
| T019 (product-domain's six facts) | 2 | 11-13 19:37 (`60441624`); 0 findings in the lens text | on estimate |
| T020 (hand-forward lines) | 2 | 11-13 19:38 (`4d5a6b2c`); FR-024's source widened afterwards by the placement ruling (DRIFT-010) | on estimate |
| T021 (twelve placed questions) | 3 | 11-13 19:40 and 19:47 (`d8624469`, `34f69487`); the plan put four questions under a solution lens and the placement was ruled at implementation (DRIFT-007) | on estimate in code; planning defect |
| T022 (depth content) | 2.5 | with T021 (`34f69487`) | on estimate |
| T023 (workshop skill: one block) | 1.5 | 11-13 19:48 (`504ce94f`) | on estimate |
| T024 (Problem Context template) | 1 | 11-13 19:48 (`db619a30`); deployed copy left as is (DRIFT-008) | on estimate |
| T025 (copies, counts, CI step) | 2 | 11-13 19:57 (`0b3fc589`); 32 of 32 workshop tests | on estimate |
| T026 (recorded Light workshop run) | 2 | 11-14, human-paced, recorded `96dfc87b` 20:15; passes with its stated limit (replies relayed, each confirmed first, DRIFT-011) | on estimate in effort; a day of elapsed time |

**Average variance**: on estimate at landing. T018 to T025 landed in 21 minutes on 2026-11-13. Rework added about
2 SP over the planned 20 (DRIFT-018): three red test commits and three fix commits, 21:49 to 21:55 on 11-14. No lens,
skill or template changed in the fixes.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done before the iteration | — | — | The question table filed four problem questions under a solution lens (DRIFT-007). |
| Implementation | 18 SP | T018 to T025, 11-13 19:36 to 19:57 | on estimate | Each test landed red first. |
| Recorded workshop run | 2 SP | T026, 11-13 evening to 11-14 20:15 | on estimate | It ran through the reviewer session, with the maintainer confirming each reply. |
| Review | 0 (DRIFT-004) | re-pointing the verification plan (DRIFT-017), then two rounds, round 1 21:23 on `3ddcd185` and round 2 22:55 on `b15c5dd1` | +1 setup commit | Round 2's preflight took 582 s against 135 s alone, because 203's sweep ran at the same time. |
| Rework | 0 | 6 commits, about 2 SP | +2 SP | Each fix came after a test that failed first. |
| Review-signoff crossing | not planned (DRIFT-004) | 11-14 22:05 to 11-15 02:50: 3 commits (`fa65488d`, `9c9a132f`, `38aebf0e`), 1 allowed red push, 1 refused sync, 1 ruled CI rerun, 0 partial-coverage approvals | much smaller than iteration 001 | The gate found the change after round 2 records-only, so no override was needed (DRIFT-022). |

## Drift Summary

- **Total drift events**: 26 (DRIFT-024 to DRIFT-026 written at this retro). Specification drift: one, the FR-024 and FR-025 wording, matched to the placement
  ruling (DRIFT-010). None escaped to review: the three review findings were test defects, not drift.
- **Crew and plan errors (5)**:
  - DRIFT-007: the plan's placement of four questions.
  - DRIFT-017: the verification plan was not re-pointed at the start of the iteration.
  - DRIFT-018's miscount: "66 of 67" told to the reviewer, where the real figure was 68 of 69.
  - DRIFT-019: the scratch project was built without init's lint configuration.
  - DRIFT-022's record: `review.md` asserted a partial-coverage approval before the gate had decided.
- **External CI (5)**: DRIFT-005, DRIFT-009, DRIFT-012, DRIFT-020 and DRIFT-023. None was caused by 205's change.
  Each was reported first and rerun only by ruling.
- **Decisions and standing rules (8)**: DRIFT-004, DRIFT-010, DRIFT-011, DRIFT-013, DRIFT-018, DRIFT-021, DRIFT-024
  and DRIFT-025.
- **Engine findings and observations (the rest)**: they are handed over as H-015 to H-022, or placed in iteration 003
  or 004 (DRIFT-014, DRIFT-015, DRIFT-019). DRIFT-026 repeats iteration 001's DRIFT-024.

## What Went Well

- **Implementation landed red-first and on estimate.** T018 to T025 took 21 minutes, and the shipped lens files passed
  the stronger round 1 checks unchanged.
- **The recorded workshop run (T026) exercised the new behaviour end to end.** The run showed:
  - one recommendation list per lens, closed by one reply;
  - compliance asked at Light with no default;
  - answers handed forward between lenses.

  It also produced DRIFT-014, DRIFT-015 and DRIFT-019 for iterations 003 and 004.
- **The review-signoff crossing went from about 18 hours and 9 commits to under 5 hours and 3 commits.** There were no
  partial-coverage approvals (iteration 001 needed two) and no revert. Iteration 001's lesson 3 ("review.md first,
  then the sync") held.
- **Holding to the file-limit rule saved an approval.** H-022 was held rather than committed, and the sync then
  matched round 2 directly.
- **The home folder stayed clean.** Its hook files were hashed around every test run, preflight and sync, and never
  changed.

## What Didn't Go Well

- **Every round 1 finding was in the new test, again.** In iteration 001, 2 of 3 findings were in the parity test; here
  all 3 were in the length test. In both iterations the test could not see a change that kept what it measured: in
  001 an extra entry, in 002 a swap or a replacement. Iteration 001's lesson 1 covered the extra-entry form only.
- **Iteration 001's two reviewer-brief additions (action 5) did not reach the round scope files.** Neither scope file
  asks whether a test derives its expectation from what it checks. Round 1's first finding is in that class.
- **The verification plan was stale at the review stop** (DRIFT-017). It cost one ruling and one setup commit, and
  would have failed the round's preflight.
- **`review.md` asserted a coverage path before the gate decided** (DRIFT-022), and three of its lines needed
  correcting after the verdict.
- **CI was red on five pushes for reasons outside the change.** Each cost a report, a ruling and a rerun.

## Lessons Learned

1. **A completeness or budget test must fail on a change that keeps its totals.** Owner: crew, iteration 003. Every
   such test checks each item by key or identity, and has self-tests that swap two items, replace one and reword one.
   This widens iteration 001's lesson 1 (an extra entry) to the shapes round 1 found.
2. **The verification plan is re-pointed at before-implement, not at the review stop.** Owner: crew, iteration 003's
   first commit after before-implement: re-point the plan and add the iteration's new suites.
3. **At planning, each question's lens is checked against index.yml's `space` tag.** Owner: planner, iteration 003
   planning. This would have caught DRIFT-007 before T021.
4. **`review.md` states the gate's coverage decision only after the sync has made it.** Before the sync, the record
   says the gate decides. Owner: crew, iteration 003.
5. **A count given to the reviewer is measured, not recalled.** Owner: crew, now (the 66-of-67 miscount).
6. **A scratch project for a recorded run is built the way init builds one.** Owner: crew, now. The build script
   already writes init's lint configuration and `.gitignore` patterns (DRIFT-019).

## Reviewer-Instruction Triage

- **PROMOTE**: for any test that checks a catalog against a budget or a list, the brief asks whether a swap,
  replacement or rewording that keeps every total still passes (round 1, findings 1 and 2).
- **PROMOTE, carried over**: iteration 001's two additions, (a) does the test derive its expectation from the artifact
  under test, and (b) search code that computes the same thing. They did not reach iteration 002's scope files. They
  go into the scope-file template, not only into a retro.
- **DEFER**: "a reference to another component must be checked to arrive" (round 1, finding 3). One instance, now
  covered by the test's receipt check. Promote it if a second instance appears.
- **Signal for 203, not a brief change**: the engine demoted finding 1 from major to minor for "no concrete failure
  scenario", though the finding states one (the swap). Recorded in DRIFT-018.

## Signals for the Next Iteration

- **Iteration 003's scope**: the FR-030 lens refresh; FR-031; DRIFT-014's agenda grouping (about 2 SP). DRIFT-019's
  item 5 asks the code lens to require a version lookup with sources and a date.
- **Spec wording**: TG-003 still lists FR-031 under iteration 002.
- **The review-signoff and retro pushes will be red on Lint again** until the record order is fixed. By the
  maintainer's decision of 2026-11-14 22:39, given to feature 206, that ordering is a bug list item on feature 206
  and a candidate for 206's iteration 002. It is no longer only 203's; H-003 remains the pointer to the hand-over.
  Each such push needs its own answer, because no standing exception was decided (DRIFT-021, DRIFT-025).
- **The retro scaffold still refuses a wrapped review verdict** (DRIFT-026, iteration 001's DRIFT-024), so this
  retro was written by hand again.
- **Shared machine load**: 203's review lanes and 205's suites slow each other. The reviewer session coordinates when
  205 may run suites.
- **Uncommitted at this retro**: `.squad/active-features.yml`, which is never committed.

## Improvement Actions

| # | Action | Owner | When | Expected effect | Kind |
| - | ------ | ----- | ---- | --------------- | ---- |
| 1 | Completeness and budget tests check per item; self-tests swap, replace and reword | crew | iteration 003 | no round finding of the "totals unchanged" kind | practice |
| 2 | Re-point the verification plan in the first commit after before-implement | crew | iteration 003 | no stale preflight at the review stop | practice |
| 3 | Check each planned question's lens `space` tag at planning | planner | iteration 003 planning | no placement ruling during implementation | practice |
| 4 | `review.md` names the gate's coverage decision only after the sync | crew | iteration 003 | no post-verdict correction | practice |
| 5 | Put the three reviewer-brief additions into the round scope-file template | maintainer | at this retro's verdict | the additions reach every round, not only the retro | reviewer instruction |
| 6 | H-015 to H-022 | feature 203 | 203's planning | fewer external CI reruns and refused syncs | implementation |

## Calibration Suggestion

Keep the SP estimates for code and test tasks; they landed on estimate in both iterations. Restore a 2 SP rework
buffer. Iteration 002 planned none and went about 2 SP over, and iteration 001 used its 2 SP buffer. Leave the
review-signoff crossing unplanned while it stays this small (DRIFT-004). Plan it again at 2 SP if it again needs a
partial-coverage approval.

## Iteration 001 Actions, Checked

| # | Action | Result |
| - | ------ | ------ |
| 1 | Parity tests parse without the catalog; extra-entry self-test | kept for the extra-entry form; the swap and replace forms were missed (lesson 1 above) |
| 2 | Surface inventory includes computed orders | no computed order was in scope; a different planning miss happened (DRIFT-007) |
| 3 | `review.md` first, then any partial approval, then the sync | done; no partial approval was needed |
| 4 | Packet values, including the coverage line, from the pending-stop record | done in every packet |
| 5 | The two reviewer-brief additions | not done: absent from both round scope files |
| 6 | H-001 to H-012 | with feature 203 |

## Notes

- Commit counts were measured at `38aebf0e`, and drift counts at this retro's commit.

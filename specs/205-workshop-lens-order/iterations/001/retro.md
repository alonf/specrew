# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-11-12

Written from the commit history, the drift log, the review record, the hand-over to 203 and the CI run history, not from
memory. The iteration ran from 2026-11-10 (before-implement approved, `12837d26`) to 2026-11-12 (review sign-off
approved, `fd2834bf`): 21 commits after before-implement, up to the records commit `7c57168d`, 17 tasks (18 SP), two codex rounds, 3 findings, 25 drift
entries and 12 hand-overs to feature 203. The retro scaffold refused to run (DRIFT-024), so this file was written
without it. Times are local (UTC+2).

## Estimation Accuracy

Per-task effort was not time-tracked. Two measures stand in: the review findings in each task's code, and the lines
each task added against the lines its fixes added. Lines are counted from `git show --numstat` and split into product,
tests, deployed copies and records. T005 to T011 landed together (`9040b34c`), so their lines are counted together.

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 (parity test) | 4 | landed 11-10 03:30 (`dcf218ed`, with T002 and T003: 541 test lines); **2 of the 3 findings** were in its code (round 1: full lists were read with a pattern built from index.yml, so an extra lens was invisible; round 2: a selector exception ended the run before the mismatches were printed) | under-built: the test shared the catalog it checks, and one error path stopped the run |
| T002 (parity self-tests) | 1 | landed with T001; extended by both T001 fixes | on estimate |
| T003 (red-first run) | 0.5 | 72 mismatches recorded on the unchanged tree | on estimate |
| T017 (baseline of existing workshop tests) | 1 | landed 11-10 03:44 (`dbd186a0`) | on estimate |
| T004 (agenda-confirmation test) | 1.5 | landed 11-10 03:37 (`854ed59d`, 78 test lines); 0 findings | on estimate |
| T005 to T011 (order, tags, refusal, prose, copies) | 6.5 | landed 11-10 03:52 (`9040b34c`: 187 product, 225 deployed-copy lines); 0 findings in their files; the 18 copies' hashes were not refreshed (DRIFT-010, caught at the review record) | on estimate in code; T011's step was incomplete |
| T012 (parity green, SC-002 counts) | 0.5 | 11-10 03:56 (`d011cd0c`) | on estimate |
| T013 to T015 (regression, CI steps, proposal) | 2 | 11-10 04:04 (`8d870098`, 43 product lines) | on estimate |
| T016 (pre-push gate, push, CI) | 0.5 | pushed 11-10 04:05; all three workflows green on `03bc4c5b`, then on every push through `eec3745b` | on estimate |
| (no task) | — | round 1's second finding was in `scripts/internal/lens-applicability.ps1`, a computed order that no task named as a surface | omission at planning: FR-001's surface list missed computed orders |

**Average variance**: on estimate at landing; T001 to T016 landed in 35 minutes on 2026-11-10. Product lines: the tasks
added 232, the review fixes 56, or 0.24 times the task lines. Test lines: 626 and 193 (0.31). The code was the cheap
part of this iteration; the review-signoff crossing was not estimated and cost the most (below).

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done before the iteration | — | — | The scope surfaces listed files, not computed orders. |
| Implementation | 18 SP | T001 to T016 on 2026-11-10, 03:30 to 04:05 | on estimate | Each test landed red first. |
| Review | inside the implementation estimate | a failed preflight (DRIFT-008) and two rounds, 2026-11-11 00:12 to 03:29 | +1 preflight | The preflight ran feature 202's verification plan, and two of its suites rewrote the maintainer's home hook files. |
| Rework | 2 SP buffer | 3 fix commits, 56 product lines, by 11-11 10:48 | within the buffer | Every fix failing-test first. |
| Review-signoff crossing | not estimated | 2026-11-11 12:41 to 2026-11-12 13:24: 9 commits, one revert, 4 pushes of which 2 had red CI (`cf173030`, `b56aaeda`), 2 partial-coverage approvals, 13 drift entries (DRIFT-011 to DRIFT-023) | the largest phase of the iteration | Record order, the derived block, a machine restart and two hours of stuck CI. Most of it is engine behaviour handed to 203 (H-002 to H-004, H-007 to H-010). |

## Drift Summary

- **Total drift events**: 25. No specification drift. None escaped to review: the three review findings were code
  defects, not drift.
- **Crew errors (4)**: DRIFT-002 (design analysis pushed before the plan existed), DRIFT-011 (phase lines moved ahead
  of the sync), DRIFT-013's first reading (the crew reverted `review.md` in `e2748a53` on a preflight that does not
  check owed artifacts), DRIFT-022 (the coverage line left out of the review-signoff packet). DRIFT-010 is partly one:
  T011 did not refresh the copies' hashes.
- **External (3)**: DRIFT-005, DRIFT-015, DRIFT-016 (Pester fetch, a Windows timing test, runs queued for two hours;
  the three `8c7f3323` push runs are still queued).
- **Engine findings (18)**: the rest. Twelve hand-overs went to feature 203, H-001 to H-012. They cluster in two
  places: the record-order boundaries, review sign-off and retro (DRIFT-012, 013, 019 to 023, 025) and hooks that write state the human
  did not ask for (DRIFT-008, 009, 017).

## CI

- **Before the review record: green on every push.** 7 of 7 pushes from `12837d26` to `eec3745b`, all three workflows.
- **At the review-signoff crossing: red on 2 of 4 pushes** (`cf173030`, `b56aaeda`).
  - `cf173030`: Specrew CI Lint red on the derived block (43066362500); Cross-Platform red on a Windows timing test
    (43066363241, DRIFT-015).
  - `8c7f3323`: the push runs never started; Test and Cross-Platform were started by hand and passed. Specrew CI has no
    result for it.
  - `b56aaeda`: Lint red on the approved item only (43128568799). Feature 202's `a7e2b74c` took the same path.
  - `7c57168d`: the records push after the boundary commit; all three workflows green, every Specrew CI job run
    (Specrew CI 43209310670, Test 43209310370, Cross-Platform 43209310268).
- Both red causes are records in a state the lifecycle passes through (H-002, H-003), so every feature pays them at
  review-signoff until 203 fixes them.

## What Went Well

- **Implementation landed red-first and on estimate.** Every test failed before the change and passed after it; the
  parity test found 72 mismatches on the unchanged tree.
- **The review found three real defects, and each was fixed behind a test that failed first.** Rework was 0.24 times
  the task lines.
- **The home hook-file check caught a real leak.** The failed preflight (DRIFT-008) rewrote the maintainer's home hook
  files; the hashes caught it before anything else ran, and H-001 went to 203.
- **The crew stopped at every refusal it was told to stop at** and reported the exact text: the moved tree, the second
  derived-block item, the token refusal.
- **The timing census** turned five scattered CI failures into one class with a product defect and seven proposals
  (H-006).

## What Didn't Go Well

- **The review-signoff crossing took longer than all the code.** About 18 hours and 9 commits, against 35 minutes for
  T001 to T016.
- **The crew reverted the review record on a wrong reading** (DRIFT-013). The preflight passed without checking owed
  artifacts, and the crew read that as the sync's rule. The real sync then refused, and one approval round was spent
  undoing it.
- **The partial sign-off cost two approvals** (DRIFT-019), because it was given before `review.md` was written.
- **The review-signoff packet left out the coverage line** (DRIFT-022), on the one packet where coverage was the
  question.
- **T001's parity test shared the catalog it was checking.** That is a design error in a test whose whole job was to
  be independent of index.yml.
- **FR-001's surface list missed a computed order.** Planning listed files with lens lists; the selector computes one.

## Lessons Learned

1. **A parity test builds its expectation from the source of truth and parses each surface on its own.** A pattern
   built from the catalog cannot see an extra entry. Owner: crew, iteration 002: every new completeness or parity test
   parses its surfaces without reading the catalog first, and has a self-test that adds an extra entry.
2. **A computed order is an order surface.** Owner: planner, iteration 002 planning: the surface inventory searches
   code that sorts or selects lenses, not only files that list them.
3. **At review-signoff, write `review.md` before asking for a partial sign-off.** Then one approval binds to the tree
   the sync will see. Order: write and push `review.md` (the approved red Lint push), ask for partial coverage if the
   tree moved after the last round, run the sync, present the packet. Owner: crew, iterations 002 and 003.
4. **Decide about the engine from the real sync, not its preflight.** The preflight does not check owed artifacts.
   Owner: crew, now: when a preflight passes and the real step is refused, report the refusal; do not reason back from
   the preflight.
5. **Every packet reads the pending-stop record's coverage line.** Owner: crew, now.
6. **A deployed-copy change refreshes its hash record in the same commit** (DRIFT-010). Owner: crew, now; it is already
   a standing rule, and it was missed here.

## Reviewer-Instruction Triage

- **PROMOTE**: for a parity, consistency or completeness test, the brief asks the reviewer whether the test derives its
  expectation from the artifact under test (round 1's first finding).
- **PROMOTE**: for a "single definition" requirement, the brief asks the reviewer to search code that computes the
  same thing, not only text that lists it (round 1's second finding).
- **DEFER**: "an error path in a multi-report tool must not end the run" (round 2). One instance; FR-019 already
  requires every mismatch in one run, and the self-test now covers it. Promote if a second instance appears.

## Signals for the Next Iteration

- **Iteration 002 is problem-space completeness.** Its input is
  `specs/205-workshop-lens-order/iterations/001/problem-gap-list.md`, written by T006.
- **DRIFT-003 is still open**: the decision-point extractor does not see product-domain's numbered list. It matters if
  iteration 002 adds product-domain questions.
- **The review-signoff crossing will repeat its red Lint push** until 203 fixes H-003, and the derived-block item is a
  standing exception for 205 (B5F-049).
- **Review-runtime timing tests can fail on any push** (H-006). A failure on a commit that cannot cause it is recorded as
  external, and a repeat stops the work.
- **Uncommitted at this retro**: state.md's session-resume rewrite and the untracked `tasks-progress.yml` (DRIFT-017).
  They are settled at iteration closeout, as the maintainer rules.

## Improvement Actions

| # | Action | Owner | When | Expected effect | Kind |
| - | ------ | ----- | ---- | --------------- | ---- |
| 1 | Parity and completeness tests parse surfaces without the catalog; self-test with an extra entry | crew | iteration 002 | no test can share the blind spot of what it checks | practice |
| 2 | Surface inventory includes code that computes an order | planner | iteration 002 planning | no computed surface left untested | practice |
| 3 | At review-signoff: `review.md` first, then partial approval, then sync | crew | iterations 002 and 003 | one partial approval instead of two | practice |
| 4 | Read every packet's values, including the coverage line, from the pending-stop record | crew | now | the human sees coverage at every stop | practice |
| 5 | The two reviewer-brief additions above | maintainer | at this retro's verdict | the reviewer checks test independence and computed surfaces | reviewer instruction |
| 6 | H-001 to H-012 | feature 203 | 203's planning | review sign-off and retro stop costing a red push each, two approvals and a revert | implementation |

## Calibration Suggestion

Keep the SP estimates for code and test tasks: they landed on estimate. Add the review-signoff crossing as a planned
line item of 2 SP in iterations 002 and 003 until H-003 and H-007 are fixed, so its cost is visible in the plan
instead of appearing only in the drift log.

## Notes

- Counts were measured at `7c57168d`.
- Iteration 001 is the first iteration of feature 205, so there are no earlier actions to check.

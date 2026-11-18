# Retrospective: Iteration 003

**Schema**: v1
**Date**: 2026-11-16

This retro is written from the commit history, the drift log, the review record, the hand-over to 203 and the CI runs,
not from memory. Times are local (UTC+2).

- **Span**: from 2026-11-15 12:14 (Amendment A2, `9f454474`) to 2026-11-16 13:44 (review sign-off approved, `ec2638da`).
- **Size**: 8 tasks (7 SP of tasks, plus a 2 SP rework buffer), 29 commits, one codex round with no findings, 14 drift
  entries, and 4 hand-overs to feature 203 (H-023 to H-026).
- **Scaffold**: the retro scaffold refused to run (DRIFT-012), so this file was written without it.

## Estimation Accuracy

Per-task effort was not time-tracked. Landing time and review findings stand in.

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T027 (code-lens freshness test, red first) | 1.25 | 11-16 02:13 (`3b85cc06`); red with 1 self-test failing and 24 problems; 0 round findings | on estimate |
| T028 (agenda grouping test, red first) | 0.75 | 02:17 (`9043250d`); red with 13 problems; 0 round findings | on estimate |
| T029 (six per-stack rules refreshed) | 1.5 | 02:21 (`babf2cf8`); two vendor pages refused a plain fetch and were read with a browser user agent | on estimate |
| T030 (line function, conduct, A3 sentence) | 0.75 | 02:23 (`79667a2a`); T027 green | on estimate |
| T031 (grouped agenda, UTF-8 output) | 0.75 | 02:26 (`cd5b6ba8`); T028 green; the skill example tripped the parity sweep, fixed at 02:37 (`ebbe1b9b`) | +1 fix commit |
| T032 (proposal 220 status history) | 0.5 | 02:27 (`3230e1d5`) | on estimate |
| T033 (copies, hashes, CI steps) | 1 | 02:29 (`515a432b`); 34 of 34 workshop tests after the parity fix | on estimate |
| T034 (recorded render check) | 0.5 | 02:50 (`1b8f22d6`); a mutation probe proved the UTF-8 forcing is needed | on estimate |

**Average variance**: on estimate. T027 to T033 landed in 16 minutes, and T034 followed 21 minutes later. The rework
buffer was not used: the round found nothing. The one fix commit (`ebbe1b9b`) came before review.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Clarify and design | not sized | 11-15 12:14 to 17:14: Amendment A2, two design-analysis drafts, hardening rows | — | Option A was chosen with FR-032 unchanged. |
| Plan and tasks | not sized | 11-15 18:46 to 11-16 01:28 | long elapsed time | Amendment A3 (DRIFT-005) came in between the plan and the tasks approval; the wording was accepted at 20:57. |
| Implementation | 7 SP | 11-16 02:13 to 02:50 | on estimate | Each new test failed first. |
| Review | 0 | one round, preflight 308 s, total 687 s, on `a0c6a849` | 0 findings | 3 of 4 rounds remain in the campaign. |
| Rework | 2 SP buffer | 0 | −2 SP | The buffer was not used. |
| Review-signoff crossing | not planned | 11-16 12:24 to 13:44: 2 commits, 1 allowed red push, 0 refused syncs, 0 partial-coverage approvals | smaller than iteration 002 | The Gap Ledger needed one wording fix after the verdict (DRIFT-011). |

## Drift Summary

- **Total drift events**: 14 (DRIFT-012 to DRIFT-014 were written at this retro).
- **Specification drift**: one, Amendment A3 (DRIFT-005), routed through the spec and approved at the tasks boundary.
  None escaped to review.
- **External CI (3)**:
  - DRIFT-001: HookRenderDedupe I3a, on iteration 002's closeout push.
  - DRIFT-007: HookRenderDedupe I4b.
  - DRIFT-009: `co-review-service.Tests.ps1:129`.

  None was caused by 205's change. DRIFT-007 was rerun by ruling and DRIFT-009 under the standing exception.
- **Decisions and standing rules (6)**: DRIFT-005, DRIFT-006, DRIFT-008, DRIFT-010, DRIFT-013 and DRIFT-014.
- **Engine findings and carry-forward (the rest)**:
  - DRIFT-002, DRIFT-003, DRIFT-004 and DRIFT-011;
  - DRIFT-012: the retro scaffold, a recurrence of iteration 002's DRIFT-026.

## What Went Well

- **The first round found nothing.** Iterations 001 and 002 each had 3 round 1 findings, all in the new tests. This
  iteration's tests check each item by key, and their self-tests remove, swap and reword, which was iteration 002's
  lesson 1. The round read them and found no gap.
- **The verification plan was re-pointed in the first commits after before-implement** (T027, T028), which was
  iteration 002's lesson 2. The round's preflight passed on the first try.
- **The review-signoff crossing was the smallest so far**: 80 minutes and 2 commits. In iteration 002 it took under 5
  hours and 3 commits; in iteration 001, about 18 hours and 9. `review.md` said "the gate decides" until the sync had
  decided, which was iteration 002's lesson 4.
- **The render check caught a real defect class before review.** A Latin-1 console turned the coloured markers into
  mojibake. The UTF-8 forcing is proven by a probe that fails without it.
- **The home folder stayed clean.** Its hook files were hashed around every test run, preflight, round and sync, and
  never changed.

## What Didn't Go Well

- **The parity sweep failed after T031, and I missed it at the time.** The skill example named three lens ids in one
  list item. I read only the tail of the parity output, which showed the stale deployed copies, so the real failure
  surfaced at T033 (`ebbe1b9b`).
- **Governance refused the first Capacity line** (8.5 against a task sum of 6.5). The rule that the line equals the
  sum of the task efforts, with the buffer in the Phase Baseline, was not known at planning.
- **The deploy scripts restamped files outside 205**: 203's runtime JSON, five charters, three `.squad` files and
  `specrew_version`. Each was restored by exact path. The same cost recurs at every deploy.
- **CI was red on three records pushes for reasons outside the change.** Each cost a report, a rerun and a hand-over.
  HookRenderDedupe failed on two different cases within a day.
- **The governance check reads only a bullet's first line, and the retro scaffold refuses any worded verdict.** Each
  cost a rewrite (DRIFT-011, DRIFT-012).
- **Iteration 002's action 5, the reviewer-brief additions, is still not in the scope-file template.** This
  iteration's scope file does not ask whether a test derives its expectation from what it checks. The action is with
  proposal 140 (DRIFT-004).

## Lessons Learned

1. **Read a failing check's whole output before committing a task.** A tail can show one known failure and hide a new
   one. Owner: crew, now. Run parity after every task that touches a lens, skill or template, and search the output
   for each failing item, not the last lines.
2. **The Capacity line is the sum of the task efforts; the rework buffer lives in the Phase Baseline.** Owner: planner,
   iteration 004 planning.
3. **Per-item tests with mutation self-tests are what kept round 1 clean.** Owner: crew, iteration 004. Keep the
   form: each check by key or identity, with self-tests that remove, swap and reword. This repeats iteration 002's
   lesson 1, and this time it held; it is not a new lesson.
4. **A zero-finding Gap Ledger is one line ending "fixed-now".** Owner: crew, iteration 004. Write it in that form the
   first time.
5. **The deploy scripts' side restamps are a known cost.** Restoring them by exact path is the practice until a deploy
   option skips them. Owner: the maintainer, through feature 206's bug list. The reviewer session passes the
   description on as a candidate, because improvements go through the bug list or a proposal.

## Reviewer-Instruction Triage

- **No new candidates.** Round 1 found nothing, so it shows no gap in the reviewer brief.
- **Carried, still open**: iteration 001's two additions and iteration 002's swap-and-reword question, all for the
  scope-file template. They sit with proposal 140 (DRIFT-004), for the maintainer to prioritise. This iteration's
  scope file named six attack points by hand instead.

## Signals for the Next Iteration

- **Iteration 004's scope**: the two-pass split, the back-check and the amendments (DRIFT-015 and DRIFT-019 of
  iteration 002).
- **Review-record and retro pushes stay red on Lint** for the phase-line message, under the maintainer's standing
  allowance ("205: standing", 14:18 local, DRIFT-014). Each use is recorded with its run id. The allowance ends when
  feature 206's T034 fix reaches this branch.
- **The retro scaffold still refuses**, now any verdict worded beyond its first word (DRIFT-012).
- **The sign-off gate reads product Markdown as records** (DRIFT-013). In iteration 004, any lens, skill, template,
  conduct or deployed-copy change after a round gets a new round, whatever the gate says. This goes into iteration
  004's plan notes.
- **The code lens's two new conduct bullets are not yet exercised.** The next code-lens workshop is the live check
  of FR-030's A3 sentence.
- **The version facts were checked on 2026-11-16.** The line function marks them stale after 2027-02-14.
- **Uncommitted at this retro**: `.squad/active-features.yml`, which is never committed.

## Improvement Actions

| # | Action | Owner | When | Expected effect | Kind |
| - | ------ | ----- | ---- | --------------- | ---- |
| 1 | Run parity after each lens, skill or template task, and read every failing item | crew | iteration 004 | no failure found two tasks late | practice |
| 2 | Capacity line = sum of task efforts; buffer in the Phase Baseline | planner | iteration 004 planning | no governance refusal at plan | practice |
| 3 | Keep per-item checks with remove, swap and reword self-tests | crew | iteration 004 | round 1 stays clean | practice |
| 4 | Write a zero-finding Gap Ledger as one fixed-now line | crew | iteration 004 | no post-verdict rewrite | practice |
| 5 | Reviewer-brief additions into the scope-file template | maintainer, via proposal 140 | at proposal 140's prioritisation | the additions reach every round | reviewer instruction |
| 6 | H-023 (HookRenderDedupe) and H-026 (`co-review-service.Tests.ps1:129`) | feature 203 | planned in 203's iteration 002 as T016 and T015 | fewer external reruns | implementation |
| 7 | H-025 (the quality resolver) | feature 206 | B5F-085 on 203's findings; item 51 on 206's bug list, an iteration 003 candidate | correct quality profile without hand edits | implementation |
| 8 | H-024 (the plan scaffold's requirement scope) and the deploy restamps | maintainer, via 206's bug list | candidates, passed on by the reviewer session | each iteration's scope and each deploy need no hand repair | bug-list candidate |

## Calibration Suggestion

Keep the SP estimates for code and test tasks; they landed on estimate in all three iterations. Keep the 2 SP rework
buffer: iteration 001 used it, iteration 002 went 2 SP over without one, and this iteration did not need it. One clean
round does not yet show a trend. Leave the review-signoff crossing unplanned while it stays this small.

## Iteration 002 Actions, Checked

| # | Action | Result |
| - | ------ | ------ |
| 1 | Per-item checks; swap, replace and reword self-tests | done; round 1 found nothing in either new test |
| 2 | Re-point the verification plan after before-implement | done in T027 and T028's commits; the preflight passed first time |
| 3 | Check each planned item's lens `space` tag at planning | done in the design analysis; FR-032 reads `space` from index.yml |
| 4 | `review.md` names the gate's decision only after the sync | done; the record said "the gate decides" until the sync |
| 5 | Reviewer-brief additions into the scope-file template | not done; with proposal 140 (DRIFT-004) |
| 6 | H-015 to H-022 | with feature 203 |

## Notes

- Commit counts were measured at `ec2638da`, and drift counts at this retro's commit.

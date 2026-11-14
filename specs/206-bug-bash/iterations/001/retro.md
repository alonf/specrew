# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-11-14

Written from the commit history, the drift log, the review record, the bug list, the hand-over to 203 and the CI run
history, not from memory. The iteration ran from 2026-11-11 (before-implement approved, `47c0c026`) to 2026-11-14
(review sign-off approved, `53ecd9b1`). That is 122 commits after before-implement, up to `029dafa5` (37 test commits,
39 fix commits), 16 tasks (20 SP planned, 3 SP of review rework), four Codex rounds with 23 findings (12 fixed, 3 of round
1's found again and fixed with round 2's, 8 carried to iteration 002), 27 drift entries and 10 hand-overs to feature 203. The retro scaffold refused to run on review.md's verdict line
(DRIFT-206-I001-028), as it did for feature 205, so this file was written without it. Times are local (UTC+2).

## Estimation Accuracy

Per-task effort was not time-tracked. The measures used instead are when each task's "done" commit landed and what
review found in its code.

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 (no-console recovery refusal) | 1.5 | RED 5/7, GREEN 7/7 on 11-11; 0 review findings | on estimate |
| T002 (over-claim separator) | 0.5 | green on Windows 11-11; Unix evidence owed until the per-push Ubuntu step, done 11-13 13:37 (`aa13c5b5`); its fixture then needed two fixes (bug items 28 and 29, DRIFT-023) | over: the fixture, not the fix, cost the time |
| T003 (classifier strips managed blocks) | 1.5 | fix landed; a regression fixed at T015 (DRIFT-014); round 2 finding 1 and round 4 finding 3 in its code; remainder carried as SC-002 | under-built, and part-finished |
| T004 (203 hand-over record) | 0.5 | done 11-11; ten sections, closed at T018 | on estimate |
| T005 (closed-definition table) | 1.0 | done 11-11; 161 iterations, 36 changes, one ruling (198/010) | on estimate |
| T006 (one definition of closed) | 2.0 | done 11-11; round 1 finding 1, round 2 finding 2 and round 3 finding 2 in its closure-claim rule, and the negative-word list was replaced by affirmative forms (maintainer, 11-14) | under-built: three rounds to settle one rule |
| T007 (abandon 197/006, 198/010, 198/011; frozen list) | 1.0 | done 11-12 (`993e8e45`) | on estimate |
| T008 (frozen judged by nothing) | 1.5 | done 11-11; 0 findings | on estimate |
| T009 (`since`, closure stamp, abandoned by ruling) | 1.5 | 2.0 by ruling (DRIFT-008); round 1 finding 2, round 2 findings 3 and 5, round 3 findings 1 and 3 in its code | over: +0.5 by ruling, then the most review rework of any task |
| T010 (local nightly replay) | 0.5 | 11-12 04:11 (`f06eb83b`), no new finding | on estimate |
| T011 (review-verdict message) | 0.5 | done 11-12 (`9de20285`); 0 findings | on estimate |
| T012 (nightly notifier) | 2.5 | done 11-12 (`d4402368`); round 1's label note, round 2 finding 4, round 3 finding 4, round 4 findings 4 and 5 | under-built in the fingerprint |
| T013 (shared test census, lane guard) | 2.0 | done 11-12 (`257bc79c`); round 1 finding 5, round 2 finding 6, round 3 findings 5 and 6, round 4 findings 1 and 2 | under-built: the guard's workflow reader took four rounds |
| T014 (read the 35 held scripts) | 2.0 | done 11-12 (`015593cb`); 19 run safe, 10 home-writers held | on estimate |
| T015 (register the scripts) | 1.0 | done 11-13 (`55c3bb8d`); SC-001 stopped (four supervised runs, items 23 to 25), DRIFT-013 to DRIFT-020 | over: SC-001's runs were most of the iteration's second day |
| T018 (acceptance checks) | 0.5 | done 11-13 (`cb9e8eca`) | on estimate |

**Average variance**: the tasks landed close to the plan by commit time, 20 SP over 11-11 to 11-13. Review rework
added 3 SP (12 fixes at 0.25 each, DRIFT-021 and DRIFT-024). The review fixes added 159 product lines. All other test
and fix commits added 840 product lines and 2,680 test lines, so the fixes came to 0.19 times the task product lines.
Three tasks drew 14 of the 23 findings across all four rounds: T013's workflow reader (6), and T006's and T009's
closure and ruling rules (3 and 5).

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done before the iteration | — | — | Five design conditions; T009 grew by ruling. |
| Implementation | 20 SP | T001 to T018, 11-11 03:30 to 11-13 13:37 | on estimate by commit time; T015's SC-001 stop | Every fix behind a test that failed first. |
| Review | inside the implementation estimate | four rounds and one failed preflight, 11-13 14:57 to 11-14 17:42 | +2 rounds of rework | Round 1 cut by the 600 s deadline; round 3's first launch failed its preflight on my own fixture (DRIFT-023). |
| Rework | not budgeted | 12 fixes, 3 SP, 11-13 and 11-14 | +3 SP | The capacity file stays unchanged (maintainer). |
| Review-signoff crossing | not estimated | 11-14 19:34 to 21:40: 4 record commits, 2 refused syncs, 1 partial approval sent twice, 1 red Lint push | the H-003 pattern again | Scope files and tasks-progress.yml blocked the first sync; the review record moved the tree; the verdict-format rules surfaced only after the phase line moved. |

## Drift Summary

- **Total drift events**: 27, plus DRIFT-028 at this retro. No specification drift.
- **Crew errors (6)**: DRIFT-001 (a revert pushed alone), 004 (a deployed file without its hash), 005 (a feature id in
  deployed comments), 014 (T003's fix stopped `specrew start`), 023 (a fixture fix the preflight's layout broke) and
  027 (the review record's format).
- **Changes outside a task's owned files, each recorded at the time (8)**: DRIFT-003, 009, 012, 013, 015, 016, 018, 020.
- **Rulings and scope (9)**: DRIFT-006, 008, 010, 011, 017, 019, 021, 024, 026.
- **External or engine (3)**: DRIFT-002 (a home hook file changed by something outside this session), 007 (runs stuck
  queued), 022 (round approvals not reaching the round).
- **Review (1)**: DRIFT-025.

## CI

- **The tasks: green on most pushes.** 23 Specrew CI successes against 5 failures since 11-11. The failures were the
  revert pushed alone (DRIFT-001), the feature id in deployed comments (DRIFT-005), and a macOS journal failure on
  `103a5e3b` (item 27, HO-206-10).
- **Flaky suites seen four times each, across two branches.** `co-review-service.Tests.ps1:129` (item 13, HO-206-8)
  and `empty-result-retry.Tests.ps1:29` (item 3, HO-206-1). Each was rerun once, under the standing exception or the
  reviewer's ruling, and both are 203's to fix.
- **At review sign-off: Lint red on `b8d3b8f2`** on the approved item only (plan.md executing beside review.md). The
  Contract lane and Deterministic gate were skipped because they need Lint.

## What Went Well

- **Every fix was test-first, and the red count is in each test commit.** 37 test commits and 39 fix commits, with one
  bug per fix commit.
- **The home hook files never changed by anything this session ran.** They were hashed before and after every suite,
  lane, round and sync. The one change (DRIFT-002) came from outside and was caught.
- **The affirmative-forms ruling was dry-run before it was built.** 161 iterations were checked, 0 results changed, and
  the rebuild on a copy of the real index lost 0 stamps. It replaced a negative-word list that three rounds kept
  defeating.
- **The preflight-layout lanes (DRIFT-023) worked.** After round 3's failed preflight, every round launched with its
  lanes green in the preflight's own layout (571 s of 1800 s before round 4).
- **SC-001 was stopped, not forced.** When its runs wrote into this repository, the script was made to refuse, and
  the cause went to the bug list (items 23 to 25) instead of a workaround.

## What Didn't Go Well

- **A free-text rule took three rounds.** The closure-claim and ruling checks were built as "a claim word, unless a
  negative word is near". Each round found a phrasing the list missed. The maintainer's affirmative-forms ruling ended
  it, and it could have been the design from the start.
- **The census guard's workflow reader took four rounds** (comments, step names, `with:`/`env:`, block comments,
  block scalars, `;#`). It reads YAML and shell with line patterns, and each round found the next construct.
- **Round 1 spent an approval and delivered nothing usable.** Its preflight took 515 s of a 600 s budget. The timeout
  should have been sized from the lanes' measured time.
- **The review record's format failed only after the sign-off verdict.** The governance check judges review.md only
  once plan.md reaches `reviewing`, so the verdict and ledger format errors came after the approval. Fixing them
  needed a second instruction and a relayed decision.
- **T002's fixture copied the local review store** (item 29), and its first fix broke the preflight (DRIFT-023).
  "Copy the developer's working folder" is a recurring fixture defect: SC-001's fixture had it too (DRIFT-015).

## Lessons Learned

1. **A rule over free text accepts listed affirmative forms, never "anything but these negatives".** Owner: crew, now
   (already the rule for closure and ruling). Iteration 002 applies it to any new text check.
2. **A test that reads YAML or shell reads its structure, not its lines.** Owner: crew, iteration 002 (items 31 and 32).
   Use a parser where one exists, or a reader that tracks indentation, block scalars and comment tokens, with a
   fixture per construct.
3. **Size a round's timeout from the lanes' last measured time, with margin.** Owner: crew, now. Round 1's 600 s was a
   default, not a measurement.
4. **Before asking for review sign-off, validate review.md as if the plan were already at `reviewing`.** Owner: crew,
   iteration 002. Run the governance check with the phase line moved in a scratch copy, so format errors surface
   before the verdict, not after it.
5. **A fixture copies only what git does not ignore, and is tested in the preflight's layout.** Owner: crew, now (the
   rule since DRIFT-023). Iteration 002 applies it to `validator-hardening-iteration2.ps1` (item 29's remainder) and
   SC-001's script (item 24).

## Reviewer-Instruction Triage

- **PROMOTE**: for any text-matching rule, the brief asks the reviewer to try a phrasing that matches the pattern but
  denies or conditions it (rounds 1 to 3 found one each time).
- **PROMOTE**: for any test that reads workflow or script files, the brief asks the reviewer to try each YAML and shell
  construct that can hide or fake a line: comments, block scalars, keys of the same name at other levels, statement
  delimiters (rounds 2 to 4).
- **DEFER**: "a repository-level stop writes each message as a hash" (round 3 finding 4, round 4 finding 4). Items 30
  and 34 cover the remaining stops; promote if a new stop repeats it.

## Signals for the Next Iteration

- **Iteration 002's intake is the bug list's Iteration 002 Intake section.** SC-002 is first by name, then SC-001, T016,
  T017, DRIFT-010 and items 12, 15 to 30 and 31 to 38.
- **DRIFT-010 blocks feature 206's closeout.** Abandoned is closed only with a recorded ruling.
- **Item 37: a deferred task has no verdict value.** Until it is fixed, a part-finished task is written as `pass` with
  a note, as T003 is.
- **The two flaky suites (items 3 and 13) stay 203's.** The rerun exception covers only
  `co-review-service.Tests.ps1:129`.
- **The review-signoff crossing will repeat its red Lint push** until 203 fixes the phase-line order, and the
  derived-block item stays an approved exception.

## Improvement Actions

| # | Action | Owner | When | Expected effect | Kind |
| - | ------ | ----- | ---- | --------------- | ---- |
| 1 | Text rules accept listed affirmative forms only | crew | iteration 002 and on | no round spent on a missed negation | practice |
| 2 | Workflow and shell readers track structure; one fixture per construct | crew | iteration 002 (items 31, 32) | the census guard settles in one round | implementation |
| 3 | Round timeout from the lanes' measured time plus margin | crew | now | no round lost to its own preflight | practice |
| 4 | Validate review.md at `reviewing` in a scratch copy before the sign-off packet | crew | iteration 002 | format errors before the verdict, not after | practice |
| 5 | The two reviewer-brief additions above | maintainer | at this retro's verdict | the reviewer tries the next phrasing and the next construct first | reviewer instruction |
| 6 | A verdict value for a deferred task (item 37) | crew, or 203 if it owns the check | iteration 002 | an accepted review need not write `pass` on part-finished work | implementation |

## Calibration Suggestion

Keep the SP estimates for the code tasks: they landed close to plan by commit time. Add 0.25 SP per expected review
finding to tasks that build a rule over free text or a reader of YAML or shell. On this iteration's evidence that is
about 1 SP each for T006, T009 and T013. Plan the review-signoff crossing as a 1 SP line item until 203 fixes the
phase-line order.

## Notes

- Counts were measured at `029dafa5`.
- Iteration 001 is the first iteration of feature 206, so there are no earlier actions to check.

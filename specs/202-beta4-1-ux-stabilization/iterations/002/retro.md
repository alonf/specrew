# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-10-20

Written from the drift log, the review record, the ten round results under the review authority store,
`docs/beta4-findings.md` and the commit history, not from memory. The iteration ran from 2026-10-17 (before-implement
approved, `fe509311`) to 2026-10-20 (review sign-off approved, `d22539ce`): 53 commits, 9 tasks (17 SP), ten co-review
rounds, 35 real findings, 5 drift entries. Counts were measured at `d22539ce`.

## Estimation Accuracy

Per-task effort was again not time-tracked. Two measures are used instead: the review findings that sit in each task's
code, from the round results' locations and titles, and the product lines the task added against the lines its fixes
added (tests, records and the deployed runtime mirror excluded; the dispatcher's two byte-identical copies both count).

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T017 (message identity) | 4.5 | landed 2026-10-17 (`557c1866`, 291 lines); 17 findings, 16 in rounds 1 to 4 on it and its fixes; the round 1 to 4 fixes added 508 lines | the most under-estimated: its fix loop added 1.75 times the task's own lines |
| T016 (host binding) | 3.0 | landed 2026-10-17 (`b299c1b1`, 285 lines); 1 finding (R5-4, receipt dedupe); CI red from this commit on (DRIFT-004) | on estimate in findings; the CI regression went unseen for 37 commits |
| T022 (retire the receipt-outcomes journal) | 2.25 | landed 2026-10-18 (`1887045f`); 0 findings | on estimate |
| T018 (approval form) | 3.0 | landed 2026-10-18 (`067b5686`, 197 lines, and `9b4ef299`); 12 findings: 10 in rounds 5 to 8 (each a new input shape), 2 in round 9 (the reset's time) | under-estimated: every round from 5 to 8 found a new way to phrase an approval |
| T019 (reworded discussion question) | 0.5 | landed 2026-10-18 (`b29dad9a`); 2 findings (R5-5 dotted identifiers, R6-6 before/after) | slightly under |
| T020 (wide delegation) | 2.0 | landed 2026-10-18 (`60f85b40`, narrowed in `1a53a4b6`); 3 findings (R5-3, R6-4, R7-3) | under-estimated: each round found a reply the delegation rule misread |
| T021 (no question tool for workshop questions) | 1.0 | landed 2026-10-18 (`8ca51fc9`); 0 findings; one guard sentence lost and restored after sign-off (`cc6126ae`) | on estimate; its regression was caught by CI, not by a round |
| T023 (remove the draft-copy writer) | 0.25 | landed 2026-10-18 (`2888341e`, net 53 lines removed); 0 findings | on estimate |
| T024 (acceptance evidence, Copilot re-walk script) | 0.5 | landed 2026-10-18 (`355e27ed`); 0 findings; the re-walk itself has not run | on estimate as written; SC-011's after-value is null |

**Average variance**: at landing, roughly zero; all nine tasks landed on 2026-10-17 and 2026-10-18. After landing, the
variance is concentrated, as in iteration 001: T017 and T018, 7.5 of 17 SP (44%), hold 29 of the 35 findings (83%). The
five tasks that parse no human text (T016, T021, T022, T023, T024) hold 1.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done before the plan | scope ruling and DA-1 to DA-5 on 2026-10-17 | on estimate | 17 SP against the 15.25 SP accepted at the scope ruling, decided at the plan stop. |
| Implementation | 16.5 | T017 on 2026-10-17 to T023 on 2026-10-18 | on estimate at landing | One unplanned pull-in: B4F-137 (`e0f1eeda`), found by the B4F-127 interim check. |
| Review | two review points, a four-round allowance | ten rounds, two allowance resets | +6 rounds (+150%) against the allowance | Rounds 1 to 4 on T017 alone; rounds 9 and 10 on changes made after sign-off. |
| Rework | inside the round allowance | 12 fix commits, 859 product lines, against 1,159 task lines | 0.74 times the task lines | On T017 the fixes outgrew the task; on the other tasks they did not. |
| Acceptance | 0.5 | T024 written; the Copilot re-walk is the maintainer's and has not run | open | SC-011 is null until it runs. |

Iteration 001's calibration asked for rounds planned against rounds used, and fix lines against task lines. Both are
recorded above, the first time this has been done since the 199 instruction.

## Drift Summary

- **Total drift events**: 5, DRIFT-001 to DRIFT-005, all resolved.
- **By human decision**: DRIFT-001 (scope, at the plan), DRIFT-004 (`fix it now`), DRIFT-005 (`move it aside`).
- **Process failures among them**: DRIFT-004 (CI red and unwatched from T016 to the round-8 sign-off) and DRIFT-005
  (the review record written before a round that could still run).

## The 35 Findings, Graded by Consequence

The same grades as iteration 001's retro: critical means a false authorization, data loss, or a write outside the
project; major means recoverable, but it blocks or misleads; minor is everything else. Graded here from each finding's
stated failure scenario; the engine graded none of them this way (B4F-055).

| Round | Covered | Critical | Major | Minor | Total |
| --- | --- | --- | --- | --- | --- |
| 1 | T016, T017 | 3 | 3 | 0 | 6 |
| 2 | round-1 fixes | 1 | 3 | 0 | 4 |
| 3 | round-2 fixes | 0 | 3 | 0 | 3 |
| 4 | round-3 fixes | 1 | 2 | 0 | 3 |
| 5 | round-4 fixes, B4F-137, T018 to T022 | 3 | 1 | 1 | 5 |
| 6 | round-5 fixes, T023, T024 | 4 | 2 | 0 | 6 |
| 7 | round-6 fixes | 3 | 0 | 0 | 3 |
| 8 | round-7 fixes | 1 | 1 | 0 | 2 |
| 9 | the changes made after sign-off | 0 | 2 | 1 | 3 |
| 10 | round-9 fixes | 0 | 0 | 0 | 0 |
| **All** | | **16** | **17** | **2** | **35** |

- **Every critical finding is a false authorization.** None was data loss or a write outside the project.
- **The criticals did not taper until round 9.** Rounds 5 to 8 found 11, all in the approval form (T018) and the
  delegation rule (T020): a condition after the phrase, a quoted menu in Markdown, a qualified partial sign-off, a
  multiline reply on Codex and Copilot, "Use the default" read as a reviewer pick. Each was a new way to phrase a reply
  that the parser read as authority.
- **The engine demoted 30 of the 35, including all 16 critical.** Each demotion said "no concrete failure scenario", and
  each finding states one.
- Confidence notes: R9-1 and R9-2 are graded major because the live store writes `Z` times, which lose only the fraction;
  on a `+00:00` record either could keep a withdrawn approval spendable, which would make them critical. R5-4 (a skipped
  answer reported with another message's receipt) could read as data loss.

## The Rule for Ending Review Rounds

Set at the maintainer's review-signoff instruction. Iteration 001's retro asked whether its loop was too large or a loop
that adds defects; this iteration ran ten rounds, so the rule is set from what the ten rounds show.

1. **Grade at the checkpoint.** When a round ends, the crew grades every finding by consequence (the grades above) and
   says, for each fix, whether it adds state or a new path. Iteration 001's action 3 asked for this and it was not done;
   this rule needs it, because rule 2 is applied from it.
2. **Another round runs only for a reason.** It runs when the round just finished found a critical finding, or when one
   of its fixes adds state or a new path. Otherwise the fixes go in behind failing-first tests, and the review closes by
   the partial sign-off reply, naming those fixes.
3. **A cap, then slicing.** The cap is the campaign allowance plus one reset. At the cap, the review closes by partial
   sign-off with every open finding recorded. Going further means the maintainer slices the remaining work as its own
   change with its own rounds, as happened with the post-sign-off changes; it is not a further reset of the same loop.
4. **Fixes after the last round mean partial sign-off.** When fixes land after the last round, the decision brought is
   the partial sign-off reply, never a stop (B4F-126; the iteration 001 and 002 review closes).
5. **A clean, current round closes the review** on its own.

**What it would have changed here.** Rounds 1 to 8 would all have run: each found a critical except round 3, and round
3's fixes added new paths (a stable transcript identity, a not-saved report, a restore on timeout). Round 4 then found a
critical in them (R4-1, a withdrawal the legacy check could suppress). The cap (four rounds plus one reset) falls at
round 8, where the partial sign-off happened anyway. Round 10 would not have run: round 9 found no critical, and its
fixes added no state. Round 10 found nothing. **The rule saves one round here.** The rounds were not wasted: the cost
came from the class of code under review, which the rule does not change. Lesson 1 is what can change it.

## CI: Red for 37 Commits, and Nobody Looked

CI failed on every push from T016 (`46639843`) to the round-8 sign-off, through eight rounds (DRIFT-004). The eight local
lanes do not run those suites, and no step of the lifecycle reads CI. Two of the three failures were real regressions
(T021's guard sentence, a hook-health suite), and the third led to the stored-time defect (B4F-138). After the fix, one
Linux run failed once on a journal stress count (B4F-142), and passed on the next push. A lane result is not a CI result,
and only CI runs on Linux and macOS.

## What Went Well

- **The release gate is fixed in code**: B4F-127 (one message, one key, T017) and B4F-129 (a hook acts only for its own
  host, T016), each reviewed and behind failing-first tests.
- **The B4F-127 interim check earned its keep three times**: it caught a stale turn-end record (B4F-137), the 01:06Z
  approval that outlived a commit (B4F-140), and kept every round launch on a typed approval.
- **35 of 35 findings were real**, and each was checked against the code before it was fixed. Across feature 202, 67 of 67.
- **Rounds planned against rounds used, and fix lines against task lines, were measured** for the first time.
- **The simplification item landed with no findings**: T022 retired the receipt-outcomes journal, and T023 removed the
  draft copy.

## What Didn't Go Well

- **The approval form drew a new critical every round from 5 to 8.** A parser that reads authority from free text meets
  a new phrasing each time it is reviewed.
- **CI went unwatched for 37 commits** (DRIFT-004).
- **The review record was written before a round that could still run** (DRIFT-005), and that round's first launch was
  refused after 22 minutes.
- **The crew misinformed the maintainer three times at the review close.** It said Codex's file delivery caused round
  9's "found nothing" (the reviewer had marked its own coverage partial); it said the review-stop records blocked the
  packet (the leftover Squad test folder did, B4F-143); and it gave 01:39Z for a commit made at 09:00Z, caught before
  sending. Each was a decision or report built on an unverified reading.
- **The stored-time class was found one site at a time, five times** (B4F-138, round 9, B4F-141).

## Lessons Learned

1. **A parser that reads authority from free text yields one critical per new phrasing.** Rounds 5 to 8: 11 criticals,
   each a shape the parser had not met. Iteration 001's lesson 2 ("fix the class, not the instance") is repeated here
   nearly word for word, which is itself the finding: the class is the free-text reading, and the fixes were instances.
   Owner: maintainer, at the beta5 plan: decide whether approvals narrow to a closed form (the bare phrase as the whole
   message, everything else refused with the reason), which removes the class rather than its next instance.
2. **CI is a separate signal, and the lifecycle has to read it.** Owner: crew, now: CI status for the last push is
   checked at every round checkpoint and before every packet. Owner: planner: a task that touches a suite only CI runs
   says so in the plan, and the lane set covers it or names it as CI-only.
3. **Review rounds end by the rule above.** Owner: crew, from iteration 003: grade at each checkpoint and apply rules 2
   to 5. Owner: maintainer: the rule is set at this retro's verdict.
4. **The review record is written once, after the last round.** Owner: crew, now (DRIFT-005).
5. **A refusal is diagnosed from the paths it names, not from its count.** Owner: crew, now: before bringing a decision
   meant to clear a refusal, list exactly what the refusal counted. Owner: beta5: the preflight names its paths
   (B4F-143).
6. **An engine summary is relayed only after the stored result is read.** Owner: crew, now. Round 9's "found nothing"
   contradicted its own stored findings (B4F-139), and the crew then explained it wrongly a second time.
7. **A class found site by site needs a tree-wide check.** Owner: beta5 (the maintainer's ruling at review sign-off):
   the tree-wide time scan, with the review-engine items.

## Iteration 001's Actions, Checked

| Action (iteration 001) | Held? | Evidence |
| --- | --- | --- |
| 1. 15 SP or less; a round after each approval-touching task | partly | 17 SP, accepted at the plan stop; the two review points were placed as planned |
| 2. Store tests through the real path, five conditions | not audited | no round finding was traced to a path-around test; this retro did not audit the tests |
| 3. Classify each finding at the round checkpoint | no | consequence grading was done here, at the retro, not at the checkpoints |
| 4. A new store names writer, reader, clearing rule, scope | held | T022 removed a store; no task added one |
| 5. No commit between an approval and its step | held, by asking | the one commit after an unspent approval (`537352e3`) was made on the maintainer's `move it aside`, and the round then waited for their `use it` |
| 7. Derive the drift summary from its entries | no, third time | the count is still authored (`5 (DRIFT-001 to DRIFT-005)`) |
| 8. Ignore `.specrew/review/pause-decision/` in git | no | the files were modified and committed again (`61a17e87`), and their dirty state helped mislead the blocker diagnosis |

## Reviewer-Instruction Triage

- **PROMOTE**: for any change to an approval parser, the review brief lists the input shapes to try in one pass: a
  condition after the phrase, a quoted menu (plain and Markdown), a qualified partial sign-off, a multiline reply per
  host, a paired paste, and an injected or replayed prompt. Rounds 5 to 8 found these one per round.
- **PROMOTE**: the crew's checkpoint grades findings by consequence (rule 1 above), independently of the engine's label.
- **DEFER**: the engine's demotion of findings that state a failure scenario (B4F-055), and its partial-coverage report
  (B4F-139), to beta5 with the review-engine items, by the maintainer's ruling.
- **DROP**: nothing.

## Signals for the Next Iteration

- Beta4.1's release gate (B4F-127, B4F-129) is fixed in code and reviewed. The interim crew check stays until beta4.1
  ships, because B4F-140 shows a stored approval can still be older than the act that should authorize.
- SC-011 waits on the maintainer's Copilot re-walk (`copilot-rewalk.md`); iteration 002's acceptance is not complete
  without it.
- The CI step for the stored-time suite is committed on the local branch `ci-stored-time-step`, not pushed; it needs a
  login with workflow permission.
- Beta5 receives, by the maintainer's rulings: B4F-139, B4F-140, the tree-wide time scan (B4F-141), with B4F-055 and the
  review-engine items. B4F-142 and B4F-143 are open candidates.

## Improvement Actions

1. Owner: maintainer | Phase: beta5 plan | Type: design | Expected effect: approvals narrow to a closed form, and the
   approval-form class of critical findings stops recurring (lesson 1).
2. Owner: crew | Phase: now | Type: process | Expected effect: CI checked at every round checkpoint and before every
   packet; no red CI runs under a review again (lesson 2).
3. Owner: crew | Phase: iteration 003 on | Type: process | Expected effect: the round-ending rule applied from graded
   checkpoints; rounds used stay within the allowance plus one reset (lesson 3).
4. Owner: crew | Phase: now | Type: process | Expected effect: the review record is written after the last round, and
   refusals and engine summaries are verified before they reach the maintainer (lessons 4 to 6).
5. Owner: crew | Phase: next chore slot | Type: chore | Expected effect: the drift summary is derived from its entries,
   and `.specrew/review/pause-decision/` is ignored in git (iteration 001's actions 7 and 8, carried again).
6. Owner: maintainer | Phase: before beta4.1 ships | Type: acceptance | Expected effect: the Copilot re-walk fills
   SC-011, and a login with workflow permission pushes `ci-stored-time-step`.

## Calibration Suggestion

- **Capacity**: keep the 20 SP baseline. 17 SP was not the problem; the class of code was.
- **Price review by the code, not the SP.** Tasks that read authority from human text (T017, T018, T020 here) drew 32 of
  35 findings on 9.5 SP. Plan such a task with two rounds of its own, and plan the rest at one covering round.
- **Rounds**: planned two review points within a four-round allowance; used ten with two resets. With the new rule, the
  ceiling is the allowance plus one reset. Record planned against used again at the next retro.
- **Rework**: 0.74 times the task lines overall, 1.75 times on T017. Keep measuring both.

## Notes

- Finding attribution to tasks is from each finding's location and title; R4-3 (workshop repair lookup) is counted
  under T017's fixes, where it was introduced, and R5-4 (receipt dedupe) under T016.
- Line counts exclude `tests/`, `specs/`, `docs/`, `.specify/` and `.specrew/`; the dispatcher's two copies both count.
- The plan's task statuses for T018 to T024 still read "planned" at sign-off although each had landed; they are
  corrected to "done" with this retro.

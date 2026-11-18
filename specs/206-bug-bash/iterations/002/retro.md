# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-11-17

Written from the commit history, the drift log, the review record, the bug list and the CI run history, not from
memory. The iteration ran from 2026-11-15 (before-implement approved, `168864f5`) to 2026-11-17 (review sign-off
approved, `4fad6f5f`). Over that span it had:

- 146 commits after before-implement, up to `f9867637`: 42 test commits, 43 fix commits, 39 records commits;
- 21 tasks, 20 SP planned, and about 7.5 SP of rework by estimate;
- four review rounds with 35 findings, 19 fixed and 16 carried to the bug list;
- 22 drift entries, plus DRIFT-206-I002-023 at this retro.

The retro scaffold refused review.md's verdict line again (DRIFT-206-I002-023), as it did in iteration 001 and for
feature 205, so this file was written without it. Times are local (UTC+2) unless marked Z.

## Estimation Accuracy

Per-task effort was not time-tracked. The measures used instead are when each task's commits landed, and what review
found in its code. The finding counts cover rounds 2 to 4 and the findings each round carried to the bug list.

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T020 (start-written record) | 3.0 | 11-15 19:13 to 11-16 02:49, 10 commits; round 1 F1 and F5 | on estimate, with two round 1 fixes |
| T021 (SC-002's script green, registered) | 0.5 | 11-15 19:49 to 20:12; a pin outside its owned files (DRIFT-006) | on estimate |
| T022 (no session files starts) | 1.25 | 11-15 20:23 onward; 0 findings | on estimate |
| T023 (outside resume path refused) | 1.0 | 11-15 20:45 to 11-16 21:39, 14 commits; round 1 F3 and F4, round 2 F4 | over: three findings |
| T024 (SC-001's script green, registered) | 0.5 | 11-15 21:16 to 11-16 12:02; round 1 F2, F6 and F9; the Linux registration rework (DRIFT-014) | over: about 1 SP with T028's Linux rework |
| T025 (init's Squad probe in temp) | 1.0 | 11-15 21:02 to 11-16 02:33; round 1 F10 (a comment) | on estimate |
| T016 (delete `_ctl-spec.ps1`) | 0.25 | 11-16 03:06 to 03:39 | on estimate |
| T017 (stray `package.json`) | 1.5 | 11-16 03:07 to 12:02; 0 findings | on estimate |
| T026 (abandoned needs a ruling) | 1.0 | 11-16 11:37 to 21:04; round 2 F1 and F3, round 3 `a9d93413` and item 77, round 4 item 87 | under-built: five findings in a text rule |
| T032 (managed-block opener) | 0.75 | 11-16 03:09 to 03:39; 0 findings | on estimate |
| T031 (census guard reads structure) | 1.5 | 11-16 03:12 to 03:39; round 2 F2, round 3 `c79fd004` and items 78 to 80, round 4 item 89 | under-built: six findings in a YAML and shell reader |
| T030 (stops pass their messages) | 1.25 | 11-16 03:16 to 03:39; round 3 item 82 (a note) | on estimate |
| T027 (`workflow_dispatch:`) | 0.25 | 11-16 03:21 | on estimate |
| T028 (publish suite clears its key) | 0.75 | 11-16 04:13 to 14:42, 14 commits; moved to its own Windows job (DRIFT-015, DRIFT-018) | over: the Linux and Node 22 rework |
| T029 (`$Host` loop variable) | 0.25 | 11-16 03:22 | on estimate |
| T033 (`deferred` task verdict) | 1.0 | 11-16 03:41 to 04:00; round 2 F6, round 3 `f194` (major), `877e`, items 75 and 76, round 4 items 86 (major) and 88 | under-built: seven findings, two of them major |
| T034 (record before its verdict) | 1.0 | 11-16 03:24 to 21:39; round 2 F5 | on estimate; it kept this sign-off's Lint green |
| T035 (closeout dashboard redraw) | 1.25 | 11-16 03:47 to 04:00; round 2 F7 (item 63) | on estimate |
| T036 (Completed date, hardening rows) | 1.5 | 11-16 03:54 to 04:00; round 2 F8 and F9 (items 64, 65) | on estimate, with two carried findings |
| T037 (reviewer-brief promotions) | 0.25 | in every round's scope file | on estimate |
| T038 (review sign-off records) | 0.25 | 11-17; the record pushed before its verdict, CI green | on estimate; the crossing cost a partial sign-off (DRIFT-022) |

**Average variance**: the tasks landed by commit time on 11-15 and 11-16, inside the 20 SP. Review and CI rework added
about 7.5 SP by estimate:

- round 1's nine fixes, about 1.5;
- the Linux rework of the per-push suites, about 1.0;
- round 2's six fixes, about 3.0;
- the CI fixes on `7b54d49d`, about 0.5;
- round 3's four fixes with their records, about 1.5.

Three tasks drew 18 of the 35 findings: T033's deferred-row reader (7), T031's workflow reader (6) and T026's ruling
reader (5). All three read free text or YAML with patterns, the class iteration 001's lessons 1 and 2 named.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done before the iteration | — | — | Amendment A1 added FR-015 to FR-018 (items 37, 39, 41, 44); items 15, 16, 19, 20, 28 and 35 cut with Option B. |
| Implementation | 20 SP | T020 to T037, 11-15 19:13 to 11-16 14:42 | on estimate by commit time | Every fix behind a test that failed first. |
| Review | inside the estimate (T038's 0.25) | four rounds, 11-16 01:30 to 11-17 21:02 | +3 rounds of rework | Rounds 2 and 3 stopped after about five minutes each (item 62). |
| Rework | not budgeted | 19 review fixes and 2 CI reworks | about +7.5 SP | Each block decided by the maintainer before it started. |
| Review-signoff crossing | not estimated | 11-17 21:02 to 23:42: 1 records push, 1 refused sync, 1 partial sign-off, the verdict | CI green throughout | Iteration 001's red Lint push did not recur (T034). The refused sync is the gate gap (DRIFT-022). |

## The Review Campaign

Campaign `cmp-206-bug-bash-i002`, four rounds of four, code writer Claude.

| Round | Reviewer | Head | Reviewer time | What it read | Findings | Fixed |
| ----- | -------- | ---- | ------------- | ------------ | -------- | ----- |
| 1 | Claude | `7c006d67` | complete | the work up to `7c006d67` | 10 (7 minor, 3 notes) | 9 |
| 2 | Claude | `3ee41574` | about 265 s of 2400 s, partial | attack items 0 to 5; not the nine round 1 fixes, T030, T029, T017 or T016 | 9 | 6 |
| 3 | Claude | `ff6fe55e` | about 300 s of 2400 s, partial | Section 2 and part of 1b; not Section 1a (the round 1 fixes commit by commit) | 12 (1 major) | 4 |
| 4 | Codex | `33cffa14` | about 495 s (18:12:58Z to 18:21:13Z), complete | every section, the commit list checked against git | 4 (1 major) | 0; stopped |

- **The two partial rounds stopped early for the same reason.** The Claude reviewer host has no shell and no clock. It
  was given an absolute deadline it could not read and stopped to publish (item 62). In round 3 it also could not show
  a commit, so "commit by commit" could not be done on that host at all.
- **Round 4 on Codex covered all of it in about 495 s.** Its scope file gave each fix by file and function, plus the
  102-commit list. Its preflight took about 1113 s, more than twice the reviewer's time.
- **Preflight cost more than reviewing.** Rounds 2 to 4's preflights were 1014 s, 1480 s and 1113 s, against 265 s, 300
  s and 495 s of reviewing.
- **Of the 35 findings, 19 were fixed failing-test first and 16 went to the bug list**: items 63 to 65, 74 to 82 and
  86 to 89, with round 1's F8 noted.

## Drift Summary

- **Total drift events**: 22, plus DRIFT-023 at this retro. One specification correction (DRIFT-003, FR-015 and
  FR-016 by the design decision).
- **Crew errors (3)**:
  - DRIFT-008: a push red on a structural guard that no 206 lane runs;
  - DRIFT-009: a records push with the governance check failing;
  - DRIFT-014: SC-001 registered per push before its Linux evidence.
- **Changes outside a task's owned files, each recorded at the time (3)**: DRIFT-006, 007, 011.
- **Rulings and decisions (10)**: DRIFT-003, 005, 010, 015, 017, 018, 019, 020, 021, 022.
- **Tooling or engine (6)**:
  - DRIFT-001, 012 and 016: CI reruns under the rule;
  - DRIFT-002: the plan scaffold;
  - DRIFT-004: the design gate;
  - DRIFT-013: the local review store.

## CI

- **23 pushes; Test was green on all 22 that have concluded.**
- **Specrew CI** failed on five first attempts:
  - `686811a6`: a structural guard (DRIFT-008);
  - `3ca2f46a`: a governance failure (DRIFT-009);
  - `792e432d` and `9f8c270f`: the Linux per-push registrations and the publish suite (DRIFT-014, DRIFT-015);
  - `7b54d49d`: the new Windows job on Node 22 (DRIFT-018).
- **Cross-Platform Validation** failed twice: on `686811a6`, and on `7b54d49d` with its rerun (the Ubuntu PowerShell
  install; feature 203's fix cherry-picked as `00cef4d5`, item 72).
- **Reruns**: four, each under the rule or a ruling and recorded. DRIFT-001, DRIFT-012 and DRIFT-016 passed on
  the rerun; DRIFT-018's failed again and was fixed by the cherry-pick.
- **At review sign-off, every push was green**: `266bb3af`, `33cffa14`, the record `1d685ce2`, and the held records
  push followed at this retro.

## Engine Traps Met

Each is on the bug list. None was a defect in this iteration's code, and each cost the maintainer a typed decision or
a repeated one.

1. **An unspent approval after a partial round** (item 59, with 60). The engine treats a partial round as undelivered,
   so its approval stays spendable and swallows the next typed one. Round 3's approval was still open before round 4.
   The maintainer had to type a withdrawal (captured 17:46:15Z) before the fresh round approval (17:53:35Z). Nothing
   told the maintainer this; the crew found it in the files. After round 2, the same trap made the maintainer type
   the approval twice (DRIFT-019).
2. **A stop on findings that a records commit undoes** (item 43's sighting, feature 203's T022). The maintainer
   stopped on round 4 (sign-off allowed 19:02:30Z). Pushing the review record, as SC-009 now allows, moved the tree,
   and the review-signoff sync refused (19:09:04Z). The refusal advised a fresh round when none remained. A partial
   review sign-off carried it (DRIFT-022).
3. **A reviewer with a deadline and no clock** (item 62). Two of four rounds stopped at about five minutes of forty.
4. **The question-UI detector reading an agent's own output** (item 59's addition). Printing the approval record made
   the Stop hook record a "picker" observation (16:36:16Z). The crew now prints only date and state fields.
5. **The retro scaffold refuses an explained verdict line** (DRIFT-023). This is the third sighting: 205, 206/001 and
   206/002.

## What Went Well

- **Every fix was test-first, with the red count in the test commit.** There were 42 test commits and 43 fix commits,
  one bug per fix.
- **The home folder never changed because of anything this session ran.** It was hashed before and after every lane
  run, round, stop and sync. Codex wrote only in its own folder during round 4 (147 entries, all inside the round's
  window).
- **Iteration 001's lesson 4 held.** T034 lets a record precede its verdict, and the review record was pushed before
  the sign-off verdict with all three workflows green. Iteration 001's sign-off had a red Lint push.
- **Round 4's scope file worked.** Listing each fix by file and function, with the commit list, let one round cover
  what two rounds had not reached.
- **Each rework block was decided before it started**: "For 206, agree", "OK for both", "You can apply both" and "206
  round 3: fix four". No fix grew past what was approved.

## What Didn't Go Well

- **Iteration 001's lessons 1 and 2 did not stick.** "A rule over free text accepts listed affirmative forms" and "a
  reader of YAML or shell reads its structure" were both written down. Yet T033's deferred-row reader, T026's ruling
  reader and T031's census reader drew 18 findings across three rounds, two of them major. Each fix closed the
  construct found, and the next round found the next construct. Item 74's question (a structured line instead of
  word lists) is the real answer, and it is still open.
- **Two of four rounds were spent on a reviewer that could not finish.** The cause (item 62) was known after round 2.
  Round 3 ran on the same host anyway.
- **The Linux CI rework (DRIFT-014, 015, 018)**: SC-001 was registered per push before it had Linux evidence, and the
  publish suite had a second Linux cause. Both were caught only by CI.
- **Three crew-error drift entries.** Two were pushes red on a check not run before the push (DRIFT-008, DRIFT-009). The safe-push
  script closed that path from DRIFT-009 on.
- **The review-signoff crossing needed a partial sign-off** for a records-only push after a stop on findings. That is
  the ordinary path, and the engine treats it as an exception (item 43).

## Lessons Learned

1. **A text rule is a structured line, not a word list.**
   - Owner: the next bug bash (item 74, with items 75 to 77, 86 and 88).
   - Iteration 001's lesson 1 narrowed the lists but kept them, and the rounds kept finding the next phrasing.
   - The repeat is the finding: the next bug bash designs the structured line first.
2. **A reader of YAML or shell uses a parser, or refuses what it cannot read.**
   - Owner: the next bug bash (items 78 to 80 and 89).
   - Iteration 001's lesson 2 asked for a reader that tracks structure, and the fixes kept extending a line reader.
   - The safe side is to refuse folded blocks, continued `if:` lines and matrix `runs-on`, not to read them.
3. **Put a review round on a host that can run git and read a clock.**
   - Owner: crew, now.
   - Round 4 on Codex covered everything in about 495 s. Rounds 2 and 3 on the Claude host stopped at about five
     minutes each.
   - Until item 62 is fixed, a round whose scope needs commit history goes to Codex.
4. **Register a per-push suite only after it is green on every CI system.**
   - Owner: crew, now (the rule since DRIFT-014).
5. **After a stop on findings, plan the partial review sign-off as a step of the sign-off.**
   - Owner: crew, until 203's T022 lands.
   - Sync once, the human's typed line, sync again with no writes between. Say so in the stop packet, so it is not a
     surprise.

## Reviewer-Instruction Triage

- **PROMOTE**: a scope file lists each fix by file, function and commit, plus the full commit list. Round 4 used it
  to cover every section. Source: round 4 against rounds 2 and 3.
- **PROMOTE**: for a reader that removes comments or fences, the brief asks the reviewer to nest one inside the other
  and leave one unclosed. Rounds 3 and 4 found this (items 86 and 87).
- **DEFER**: "check the commit list against git". It only works on a host with a shell, so it waits on item 62.
- **KEEP** (iteration 001's two promotions, in every round's scope through T037): they produced the findings in the
  text rules and the census reader. The rules failed, not the brief.

## Signals for the Next Iteration

- **There is no iteration 003.** The reviewer session relayed the maintainer's plan: close 206 and 203, then open a
  new bug bash for the remaining known bugs. Next come the iteration closeout, then the feature closeout. The open
  list becomes the follow-up feature's seed, which the maintainer confirms at the feature-closeout packet.
- **The bug tally**, counted by part (item 6 has two), 90 parts over items 1 to 89:

| Status | Count | Items |
| ------ | ----- | ----- |
| Fixed in iteration 001 | 3 | 1, 4, 26 |
| Fixed in iteration 002 | 23 | 2, 5, 6a, 12, 17, 18, 21 to 25, 29 to 34, 37, 39, 41, 44, 51, 72 |
| With feature 203 | 13 | 3, 7, 8, 9, 13, 14, 27, 42, 58 to 62 |
| Closed without a fix | 1 | 81 |
| Open | 50 | the rest, with 83 to 89 added on 2026-11-17 |

- **The open majors, for the seed's first lines**:
  - 86: a decision id in an indented example counts as recorded;
  - 66: a session start rewrites a finished iteration to "not started";
  - 73: the tasks sync becomes impossible to pass after a session start;
  - 83: a governed agent edited its own engine.
- **The design question**: item 74.
- **Items that wait on 203's merge**: 40, 43 and 84 (feature 203's protected area); the 13 with 203 are its own.

## Improvement Actions

| # | Action | Owner | When | Expected effect | Kind |
| - | ------ | ----- | ---- | --------------- | ---- |
| 1 | Design item 74's structured line before fixing items 75 to 77, 86 and 88 | the follow-up bug bash | its plan | the text-rule class closes in one round | implementation |
| 2 | Census guard: refuse unread YAML constructs (items 78 to 80, 89) | the follow-up bug bash | its plan | no round spent on the next construct | implementation |
| 3 | Rounds that need commit history run on Codex until item 62 is fixed | crew | now | no partial round from a host that cannot finish | practice |
| 4 | Stop packets after findings name the partial sign-off step | crew | until 203's T022 | the crossing is planned, not a surprise | practice |
| 5 | The two scope-file promotions above | maintainer | at this retro's verdict | complete rounds on the first try | reviewer instruction |
| 6 | The retro scaffold accepts `accepted:` with an explanation, as the governance check does (DRIFT-023) | feature 203, or the follow-up bug bash | at triage | retros scaffold again | implementation |

## Calibration Suggestion

Keep the SP estimates for the code tasks: they landed inside 20 SP by commit time again. Two changes:

- **Price review findings into text and YAML rules.** Iteration 001 suggested 0.25 SP per expected finding on a text
  or YAML rule. This iteration bore it out: T033, T031 and T026 drew 18 findings, about 4.5 SP at that rate, close to
  the 4.5 SP of rounds 2 and 3's rework. Apply it at plan time, not after.
- **Price the review-signoff crossing at about 0.5 SP** until 203's T022 lands: the record, one refused sync, a partial
  sign-off and the verdict.

## Notes

- Counts were measured at `f9867637`.
- Iteration 001's six improvement actions:
  - actions 4, 5 and 6 were done (T034, T037, T033);
  - action 3 held for timeouts, but rounds 2 and 3 stopped on the missing clock, not on the timeout;
  - actions 1 and 2 were applied and did not close their class (lessons 1 and 2 above).

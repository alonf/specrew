# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-11-15

Written from the drift log (DRIFT-001 to DRIFT-091), the review record, the stored round results, the CI runs named in
the drift log, `docs/beta5-findings.md` and the commit history, not from memory. The iteration ran from 2026-10-31
(before-implement approved, `fca9067e`) to 2026-11-15 (review sign-off approved, `e9c1b20f`). Each item says whether it
is **measured** (with its source) or the crew's **judgment**.

Measured at `dc1a6301`: 354 commits after before-implement; 12 tasks planned at 28.5 points against a 20-point
baseline; 18 review rounds (13 on single tasks, 5 on the iteration); 91 drift entries. Product scripts changed by
7,636 lines added and 3,058 removed; tests by 11,683 added and 2,843 removed (`git diff --shortstat fca9067e`).

## Estimation Accuracy

Per-task time was not tracked; the plan's Actual column is empty. The stand-in is the scope the drift log records as
added, with the maintainer's ruling for each.

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 (host facts recorded in scratch folders) | 2.0 | done 2026-11-02 (research.md R1 to R4) | on estimate (judgment) |
| T002 (the live engine pin) | 2.0 | signed off on `52f37279` after 2 rounds, reopened for the hook-command-length defect (DRIFT-016), signed off again on `7abcd180` after rounds 3 and 4 (DRIFT-019); rounds 5 to 7 on its follow-ups (DRIFT-021 to DRIFT-023) | well over: 7 of the 13 single-task rounds (measured, DRIFT-010 to DRIFT-023) |
| T003 (one classifier for every typed turn) | 4.0 | built pure, wired by T004; touched T002's dispatcher (DRIFT-025) | on estimate (judgment) |
| T004 (one writer for every typed act) | 4.0 | rounds 8 to 13 and an allowance reset, signed off on `6210e2ab` (DRIFT-029 to DRIFT-035) | over: 6 rounds, 21 findings, all real (measured) |
| T005 (verdict pairing against the waiting crossing) | 1.5 | built on three commits (DRIFT-043, DRIFT-044) | on estimate (judgment) |
| T006 (the not-recorded report) | 2.0 | built on four commits (DRIFT-046) | on estimate (judgment) |
| T007 (the review budget snapshot) | 2.5 | built, then no review round could launch until fixed (DRIFT-051) | slightly over (judgment) |
| T008 (the review loop: grant, reservation, stops) | 5.0 | built in four steps (DRIFT-052), marked done with a red suite and reopened (DRIFT-055) | over (judgment) |
| T011 (the Stop check reads the reply's decision parts) | 1.5 | done under two maintainer rulings (plan row) | on estimate (judgment) |
| T012 (audit and correlation of records to turns) | 1.5 | about 2.25 (DRIFT-061) | +0.75, 50% over (measured) |
| T013 (test evidence: mint-path and phrase fixtures) | 1.5 | about 1.5 + 0.25 + 0.5 + 1.75 + 0.5 + 0.5 scope added (DRIFT-063 to DRIFT-065, DRIFT-067, DRIFT-069) | about +3.5, each part by the maintainer's ruling (measured) |
| T014 (pin advance and the Claude-only capture check) | 1.0 | pin advanced 2026-11-15 (DRIFT-082); capture check not done | open |

**Average variance** (measured where the log records points): T012 +50%, T013 more than doubled. Planned 28.5 points
against a 20-point baseline, so the plan itself was 43% over capacity before any variance.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | one day | specify to before-implement all approved on 2026-10-31 | on estimate | Measured: the verdict history. |
| Implementation | 28.5 points | 2026-11-01 to 2026-11-13 | over, see above | Measured: the plan rows and DRIFT-061 to DRIFT-069. |
| Single-task reviews | not priced | 13 rounds on T002 and T004 | not priced | Measured: DRIFT-010 to DRIFT-035. |
| Iteration review | 4 rounds (the maintainer's ruling, DRIFT-070) | 5 rounds, 2026-11-13 to 2026-11-15 | +1 round | Measured: round E was the fifth, by the maintainer's decision (DRIFT-076, DRIFT-079). |
| Review end | one sign-off | a stop, a refused sync, a pin advance, a partial sign-off and the sign-off | about one day | Measured: DRIFT-082, DRIFT-085. |

## Drift Summary

- **Total drift events**: 91 (DRIFT-001 to DRIFT-091). Measured. The drift log's own summary line still says 28; it
  was not kept up after DRIFT-028 (finding for the crew).
- **Review outcomes**: 18 (single-task rounds 1 to 13, iteration rounds A to E).
- **Entries that carry a maintainer ruling, decision or input**: 41 by their titles, each with its quote and time.
- **Crew errors and incidents**: real home hook files written by tests or sweeps four times (DRIFT-021, DRIFT-044,
  DRIFT-050, DRIFT-056); a worktree force-removed twice, erasing ignored state (DRIFT-049, DRIFT-066); a pin advanced
  on a chosen subset of suites (DRIFT-057); a task marked done with a red suite (DRIFT-055); CI unread for 8 days and
  40 pushes (DRIFT-053).
- **Specification drift**: 1 (DRIFT-026, FR-018's list of acts clarified).

## The Review

### Five iteration rounds

Measured, from the review record and DRIFT-070 to DRIFT-084. Reviewer Codex, launched from the pin `a56ac787`, one
focus file per round, each round started by the maintainer's own typed approval. Home hook files were 0 changed in
every round.

| Round | Run | Focus | Findings | Outcome |
| --- | --- | --- | --- | --- |
| A | `run-20261113-102531165-8671e9be` | authority and capture | 3 major (4 defects) | fixed, test first (DRIFT-070) |
| B | `run-20261113-172304585-393b6102` | the review engine | 4 major | fixed, test first (DRIFT-071) |
| C | `run-20261113-230313149-5c350d9c` | extension scripts, dispatcher, hosts | 3 major | fixed, test first (DRIFT-072) |
| D | `run-20261114-172156973-8e5f3fa1` | the whole tree with the tests | 3 major | fixed, test first (DRIFT-076) |
| E | `run-20261115-042146354-0a33bd36` | the four fixes since round D, and the records | 2 major | open, to iteration 002 (DRIFT-083, DRIFT-084) |

Rounds A to D: 13 major findings, 14 defects, each behind a test committed red first. Round E's two:

- `finding-cf1fe81e0398f883`: round D's fix for long transcripts is incomplete. A later message that reuses the
  approval's running prompt ID stops the search before the whole transcript is read, so a valid approval is refused.
- `finding-a537d3f72672e5f5`: round D's fix for the unsaved-turn report is incomplete. On the recovery path, a lost
  review-stop answer gets no report.

Both fail closed: they refuse an act, never allow one. Both go to iteration 002's first batch.

**Judgment**: every round found real defects in the authority code, and the count fell (4, 4, 3, 3, 2). Rounds D and E
each found an incomplete fix of the round before. A fix that makes one path refuse needs every sibling path checked
(lesson 3).

### The ordering deadlocks

Measured, each from a refusal the crew met.

- **The sync's state-truth gate** (DRIFT-082; B5F-050; feature 205's DRIFT-011). The review-signoff sync refuses
  unless plan.md shows the last authorized boundary's line, `executing`. The governance check refuses `executing` once
  review.md exists. No commit could hold the review record, pass the check and be synced. Way through: plan.md put
  back to `executing` in a records commit, under one red Lint run the maintainer allowed (DRIFT-082).
- **DRIFT-078**: a human-accepted stop never covers a records commit made after it. The review record had to be
  committed before a fifth round, and that round reviewed it (DRIFT-079).
- **The partial sign-off** (DRIFT-085). The sign-off gate listed all 15 majors of rounds A to E as still open, because
  no finding is ever marked resolved (B5F-071). The sign-off took two typed approvals: a partial sign-off, then the
  sign-off. The maintainer's requirement (DRIFT-091): the ordinary review end takes one approval.
- **The retro's own red Lint** (B5F-059). retro.md beside plan.md at `reviewing` fails the governance check, the same
  shape as B5F-050.

**Judgment**: four deadlocks with one cause. The engine's checks each hold one phase line true, and the lifecycle
passes through states where two checks need opposite lines. Each cost hours, and each was met first by a crew rather
than by a test.

### Two traces that were wrong at the last step

Measured, from the crew's messages to the reviewer session (quoted from the session record) and the drift log. The drift
log does not quote either claim; both were made in messages to the reviewer session on 2026-11-14.

1. **Path 2(a) in the round D readiness report** (16:19 local, 2026-11-14). It said ending the review by "stop the
   review here" on the unchanged tree, then the sign-off verdict, "**Works on the pin.** The stop runs entirely inside
   the pin ..." and "Your \"approved for review signoff\" works too." The reviewer session asked for it to be dry-run,
   since it "rests on code reading only". The dry run, reported at about 19:55 local the same day, showed the stop
   landing and the sign-off sync then refusing (DRIFT-078). The review records then had to move before a fifth round.
2. **Path (b) in the readiness note** (22:10 local, 2026-11-14): records committed and pushed first, a fifth round on
   that tree, the stop, the sync. The crew's words: "Unproven end to end (no round run), but the code says it lands".
   The trace followed the verdict capture and the sign-off evidence gate. The reviewer session accepted it after
   checking two of its code facts, and did not ask for the sync to be exercised with plan.md at `reviewing`. The real
   sync refused it on 2026-11-15 at the state-truth gate, which runs earlier (`sync-boundary-state.ps1:1822`; DRIFT-082).
   So the real run disproved this one, not a dry run. The dry runs came after and found the way through, which needed
   the pin advance first (DRIFT-086).

**Judgment**: both traces stopped one step short of the code that refused: the first at the stop, the second before the
sync's own gates. A dry run found the first fault before anything was spent; the second, left to code reading, cost a
refused sync after the stop and a red CI run. A trace reads the code a crew expects to run; a dry run runs the code that
does run.

### Round D's fix batch: four defects in its own test code

Measured (DRIFT-080, DRIFT-081):

1. A checkout snapshot compared as null on a clean checkout (found by the sweep).
2. A fixture line that made the sweep driver read a script suite as an empty Pester suite (found by the sweep).
3. The checkout check threw on a tracked dangling link (`.antigravitycli/...json`, B5F-077), listed only in the review
   target's layout (found by round E's preflight).
4. An absent `HOME` put back as an empty one, which changed what git ignores (found in the review target's layout,
   while proving the third).

The first launch of round E failed its preflight after 2,802 s and said only the lane's name (B5F-076).

**Judgment**: the test code written to prove fixes was the least reviewed code of the week. The rule adopted
(DRIFT-081): every lane runs green in the review target's layout, alone, before a round is asked for.

## What Went Well

- **Every finding was real, and each fix landed behind a test committed red first** (measured: DRIFT-070 to
  DRIFT-076; the review record).
- **The pin held**: the live hooks never ran half-built capture code. The maintainer asked for this at clarify. Its
  advance to `da78b600` changed 0 home hook files (measured: DRIFT-082).
- **Dry runs on scratch copies found every path problem before the real tree moved** (measured: DRIFT-076, DRIFT-078,
  DRIFT-082, DRIFT-086), with the home redirected and hashed.
- **The partial sign-off was captured with its transcript path on the advanced pin**, and its sender check read
  "human, accepted, typed by the human" (measured: DRIFT-085). On the old pin the same capture would have been
  discarded (DRIFT-072, DRIFT-086).
- **The maintainer's decisions were recorded with their words and times**, including those relayed by the reviewer
  session (measured: DRIFT-070 to DRIFT-091).
- **Home hook files: 0 changed across all five iteration rounds and the pin advance** (measured: DRIFT-070 to
  DRIFT-082).

## What Didn't Go Well

- **The ordering deadlocks** above: four, met by the crew, each costing a dry-run cycle or a red CI run (measured).
- **Lane and suite times crept toward their limits** (measured):
  - The t008 lane: 759 s on `064a2ff4`, then 838 s of 900 s on `da78b600`, 93% (DRIFT-087).
  - `message-identity`, `review-loop-stops` and `review-budget-loop`: 948, 977 and 889 s on `f6478946`; 1,189, 1,248
    and 1,135 s on `da78b600` (DRIFT-080, DRIFT-087).
  - The sweep limit was raised to 1,500 s for the rest of the iteration (DRIFT-077).
  - Suspect, not investigated: round D finding 1's whole-transcript read on a miss.
- **The hook cost**: about 19 s per turn, measured on a 53 MB transcript (DRIFT-073), paid on every turn by every
  crew. The field sighting of a waiting turn refused three times multiplies it (DRIFT-089, B5F-078).
- **Real home hook files were written four times** before the home was redirected in every run (DRIFT-021, DRIFT-044,
  DRIFT-050, DRIFT-056). **A worktree was force-removed twice** (DRIFT-049, DRIFT-066). The standing rule now forbids
  both.
- **CI was unread for 8 days and 40 pushes** (DRIFT-053). Feature 202 iteration 003's lesson 2 said the same; it did not
  hold as a habit and needed a rule.
- **Round E's two findings are carried open** (DRIFT-083, DRIFT-084).
- **A gate went unrun on a pushed commit**: the allowed red Lint on `c28b2af6` skipped the deterministic gate and the
  contract lane (B5F-074).
- **T014 is not done**: the capture check waits for the retro boundary (see Signals).

## Lessons Learned

1. **Run the boundary sync on a scratch copy before saying a path lands.** Judgment, from the two wrong traces. Owner:
   crew, now: every readiness report for a boundary includes a dry run of that boundary's own sync on a scratch copy
   with the real state (DRIFT-086, item 6).
2. **The lifecycle's phase checks need one owner.** Judgment, from the four deadlocks. Owner: maintainer, at iteration
   002's planning: B5F-050 and B5F-059 together, with DRIFT-078, DRIFT-091 and B5F-071 as one design input for the
   sign-off gate.
3. **A fix that makes one path refuse needs its sibling paths checked.** Judgment, from round E's two findings, each an
   incomplete round D fix; F2's commit message named the asymmetry and left it (DRIFT-084). Owner: crew, now: when a fix
   touches one reader or reporter, list its siblings in the commit and cover each, or record why not.
4. **Test code that proves a fix is code under review.** Judgment, from DRIFT-080 and DRIFT-081. Owner: crew, now: the
   adopted rule (every lane green in the review target's layout, alone, before a round).
5. **Time limits are measurements, not settings.** Judgment, from the creep. Owner: crew, iteration 002 first batch:
   the t008 lane and the three slow suites measured against the suspect, before any limit is raised.
6. **A habit that did not hold becomes a rule.** Measured: 202's CI lesson failed again here (DRIFT-053), and the
   standing rule (CI followed to its end after every push) is followed for every push the log records since (DRIFT-074,
   DRIFT-087). Owner: crew, now.

## Feature 202 Iteration 003's Actions, Checked

| Action | Held? | Evidence |
| --- | --- | --- |
| 1. The consequence grade at each round checkpoint | partly | round findings were reported to the reviewer session before each answer; the records give the engine's severity only |
| 2. Each CI job read at every checkpoint and before every packet | no, then yes | 8 days unread (DRIFT-053); then the standing rule, every push since |
| 3. B4F-158: the deterministic gate runs whether or not Lint passes | no | B5F-074 on `c28b2af6` |
| 4. The last approved stage checked before each next stage | yes | `start-context.json` read before each sync |
| 5. Review counts taken from the stored results | partly | the dry run said 16 majors; the stored listing said 15 (DRIFT-086) |

## Reviewer-Instruction Triage

- **PROMOTE**: when a fix adds a fallback or a report to one path, the brief asks the reviewer to check every path that
  reaches the same reader or writer. Round E found both its findings this way.
- **PROMOTE**: the focus file names the test code of the last fix batch as in scope (DRIFT-080, DRIFT-081).
- **DEFER**: the reviewer's own check of the review end's sync path, to the gate redesign (DRIFT-091).
- **DROP**: nothing.

## Signals for the Next Iteration

- **Iteration 002's first batch** (measured: the placements in DRIFT-078, DRIFT-083, DRIFT-084, DRIFT-087, DRIFT-091):
  - round E's two findings;
  - the hook cost (DRIFT-073);
  - DRIFT-078 with DRIFT-091 and B5F-071, as one design input;
  - the t008 lane.
- **T014's capture check** (the pin advance and a manual check FR-045 names: a verdict after a compaction, a quoted
  phrase, a pasted phrase). Its state:
  - The pin advanced before the sign-off, on the maintainer's decision at 13:27 on 2026-11-15 (DRIFT-082).
  - The verdict after a compaction was met live at 18:44: captured once, marker path.
  - The quoted and pasted phrases, the drop-finding line and the verdict typed more than 500 transcript lines after the
    packet are the live check at the retro boundary, on the maintainer's "Yes to all three" (20:57 local, 2026-11-15,
    DRIFT-092). The drop-finding line was typed at 20:58 and recorded nothing; the rest follow with this packet.
  - Two departures from T014's text, accepted by the maintainer in the same answer. The pin stays at `da78b600`, not
    the signed-off commit, a records-only difference. The live `stop the review here` check moves to iteration 002's
    first review stop, because there is no stop to answer before then.
  - A built rehearsal on scratch copies ran first and showed what each live line produces (DRIFT-092).
- **The project's hook launcher** was not redeployed. The redeploy is the maintainer's own decision (DRIFT-085).
- **Open findings to place**: B5F-071 to B5F-079; B5F-050 and B5F-059 are already proposed for iteration 002.

## Improvement Actions

1. Owner: crew | Phase: now | Type: process | Expected effect: each boundary readiness report includes a dry run of the
   boundary's own sync on a scratch copy with the real state (lesson 1).
2. Owner: maintainer | Phase: iteration 002 planning | Type: design | Expected effect: one owner for the phase checks;
   B5F-050, B5F-059, DRIFT-078, DRIFT-091 and B5F-071 designed together, so the ordinary review end takes one approval
   (lesson 2).
3. Owner: crew | Phase: now | Type: process | Expected effect: a fix to one reader or reporter lists and covers its
   sibling paths in the same batch (lesson 3).
4. Owner: crew | Phase: now | Type: process | Expected effect: every lane green in the review target's layout, alone,
   before a round is requested (lesson 4).
5. Owner: crew | Phase: iteration 002 first batch | Type: measurement | Expected effect: the t008 lane and the three
   slow suites timed against the whole-transcript-read suspect before any limit changes (lesson 5).
6. Owner: crew | Phase: now | Type: records | Expected effect: the drift log's summary line kept current with its
   entries.

## Calibration Suggestion

- **Capacity**: the plan took 28.5 points against a 20-point baseline, and scope rulings added about 4.25 more
  (measured: DRIFT-061 to DRIFT-069). Keep the 20-point baseline and plan to it.
- **Price review by the code**: the authority code took 18 rounds in all. Single-task reviews were not priced. Price
  each authority task at two rounds of its own (judgment).
- **Price the review end**: the end of this review took about a day of dry runs and decisions (DRIFT-082 to
  DRIFT-085). Until the gate redesign lands, plan half a day for it (judgment).

## Notes

- Counts of commits and lines are from `git log` and `git diff --shortstat` over `fca9067e..dc1a6301`. Product lines
  are `scripts/` and `extensions/` without Markdown; the `.specify` mirror is not counted.
- Round findings and counts are from the stored results and the review record, not from summaries.
- T014 is not complete; its live check and capture-check.md follow the retro verdict.

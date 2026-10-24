# Retrospective: Iteration 003

**Schema**: v1
**Date**: 2026-10-24

Written from the drift log, the review record, the four stored round results under the review authority store, the CI
run history, `docs/beta4-findings.md` and the commit history, not from memory. The iteration ran from 2026-10-21 (plan
approved, `f8c112f3`; before-implement approved, `e948a634`) to 2026-10-24 (review sign-off approved, `bef03c45`): 22
commits after before-implement, 8 tasks (5.75 SP), four co-review rounds, 7 real findings, 3 drift entries, and the
maintainer's Copilot re-walk. Counts were measured at `bef03c45`.

## Estimation Accuracy

Per-task effort was not time-tracked. As in iteration 002, two measures stand in: the review findings in each task's
code, from the stored results' titles and the fix commits, and the product lines the tasks added against the lines their
fixes added (tests, records and the deployed runtime copies excluded). T025 to T029 landed together in iteration 002
(`2fd7f2d6`), so their lines are counted together.

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T025 (payload probe and fixtures) | 1.0 | landed 2026-10-21 (`2fd7f2d6`, with T026 to T029); 2 findings, both minor (round 2: the capture time lost its ISO form; the fixtures carried the user's profile paths) | on estimate; the probe found the real payload shapes, and the re-walk added 8 more |
| T026 (Copilot's second payload shape) | 0.75 | 0 findings; held live: 0 hook rows under `claude` | on estimate |
| T027 (a reader for the unrecognized-payload record) | 0.25 | 0 findings; live: 0 records | on estimate |
| T028 (a sub-agent's task text is never an approval) | 0.5 | 1 finding (round 2: Copilot's `agentStop` for a sub-agent ran the end-of-turn path; T028 had guarded prompts only); held live, with B4F-155 left over | slightly under: it covered one event kind of two |
| T029 (product-domain questions in prose) | 0.5 | 0 findings; **failed live**: Copilot used `ask_user` anyway (B4F-131 seen again) | the review could not catch it: the rounds read the text, and the text was right |
| T031 (closeout listed as closed only on approval) | 0.75 | landed 2026-10-21 (`1cea2e51`, 16 lines); 0 findings; live at this iteration's closeout | on estimate |
| T032 (feature closeout clears nothing before approval) | 1.75 | landed 2026-10-21 (`29cf7760`, 230 lines); 2 findings (round 1: the consumer's capture loaded the newest installed module, not its own; round 2: that route had no test) | on estimate in size; its consumer path was untested until round 1 |
| T030 (acceptance and the re-walk) | 0.25 | done 2026-10-24; 0 findings; DRIFT-002 in its records | on estimate; the re-walk itself was the maintainer's two days |

The other 2 findings sit in code carried in: round 8's approval-form fixes from iteration 002 (`ac87d96c`), which the
maintainer added to this iteration's review at the plan stop. Round 3 found that the form gate failed open when the form
could not be read (`8aa15c19`); round 4 found that the fix records nothing and tells the human nothing (B4F-151).

**Average variance**: at landing, roughly zero; every task landed on 2026-10-21. Product lines: the tasks added 373, the
round fixes 97, or 0.26 times the task lines (iteration 002: 0.74). The approval-form code, outside the 5.75 SP, drew
the only two findings that the maintainer's grade of 2026-10-20 makes critical.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | one day | plan, tasks and before-implement all approved on 2026-10-21 | on estimate | B4F-146 joined at the tasks stop (T031, T032). |
| Implementation | 5.75 SP | T025 to T029 already in code; T031 and T032 on 2026-10-21 | on estimate | Each landed red first. |
| Review | one round, under a four-round allowance | four rounds, 2026-10-21 to 2026-10-22, no reset | +3 rounds against the plan, within the allowance | Rounds 3 and 4 were spent on the carried approval-form code. |
| Rework | inside the round allowance | 3 fix commits, 97 product lines | 0.26 times the task lines | Every fix landed behind a test that failed first. |
| Acceptance | the maintainer's re-walk | 2026-10-23 to 2026-10-24, passed SC-011 | on estimate | 8 real decisions, 1 corrective exchange, 0 extra stops. |
| Review-signoff stop | after the review | 2026-10-24, two days late | skipped, then held | DRIFT-003: the engine's sign-off was taken for the stage approval. |

## Drift Summary

- Total drift events: 3.
- DRIFT-001: the pre-review governance command still named iteration 002; re-pointed before the round. Fifth instance;
  its fix is beta5 work.
- DRIFT-002: the re-walk row was written into closed iteration 002; reverted by a new commit and moved here.
- DRIFT-003: the review-signoff stop was skipped, and the engine's sign-off was committed under its name; caught by the
  maintainer, then held.

## The Seven Findings, Graded by Consequence

The engine labelled 5 minor and 2 notes. Graded by consequence, with the maintainer's rule of 2026-10-20 (a finding that
misleads the human about an approval or a review result is critical):

| Round | Finding | Engine | Grade | Why |
| --- | --- | --- | --- | --- |
| 1 | A consumer's feature-closeout capture loads the newest installed module, not the one its extension came from | minor | major | A closeout in a consumer project could run code of another version |
| 2 | Copilot's `agentStop` for a sub-agent runs the end-of-turn path | minor | major | End-of-turn work ran mid-turn; whether it could record anything was not shown |
| 2 | The probe kept capture times as culture strings | minor | minor | Test data only |
| 2 | The resolver's default route had no test | note | minor | A test gap on round 1's fix |
| 2 | The fixtures carried the user's profile paths | note | minor | Committed test data named the maintainer's account |
| 3 | The approval-form gate failed open when the form could not be read | minor | **critical** | A condition typed below the partial sign-off line reached the writer that records authority |
| 4 | An unreadable approval form refuses silently, and the turn is still reserved | minor | **critical** | A correctly typed approval records nothing and the human is not told: the withheld "not recorded" notice the rule names |

Under the round-ending rule, round 3's critical justified round 4, and round 4's critical justified one more round (the
cap is the allowance plus one reset). The maintainer stopped the review instead, which is the maintainer's call. But no
record shows a consequence grade at either checkpoint, and the records call round 4's finding a "note" where the engine
said minor and the rule says critical. Iteration 002's action 3 asked for the grade at the checkpoint; this is the third
iteration in which it was done at the retro.

**A count correction.** The review record approved today says "6 findings and notes... 5 are fixed" and calls round 4's
finding "1 note". The stored results hold 7 findings: 6 fixed, and round 4's minor carried as B4F-151. The acceptance
evidence repeats "1 note". Both are left as approved; this retro is the correction, and Discussion prompt 1 asks whether
to append a dated correction line to them.

## CI: Red on Every Push of the Iteration

Specrew CI failed on all 16 pushes from iteration 002's closeout (`45f0d01c`) to `bef03c45`. Iteration 002's lesson 2
("CI is checked at every round checkpoint and before every packet") did not hold: nobody read the runs until this retro.

| Cause | Pushes | Kind |
| --- | --- | --- |
| Iteration 003's `state.md` not yet written, then DRIFT-001's closure missing its reason | 3 | records written later than the code |
| The deployed copies differ from the sources until the runtime refresh (release-model mirror check) | 6 | expected between review and refresh |
| Closed iteration 002 in scope: its closeout, then the re-walk row and its revert | 4 | DRIFT-002, and 002's own closeout |
| `plan.md` still `executing` with `review.md` present | 1 | the review record committed before its stop |
| The gap ledger lists items as open, not fixed-now or deferred | 1 | at `bef03c45`; classified at closeout, as in iteration 002 |
| A co-review lease test failed (`co-review-service.Tests.ps1`, the owner-handoff case) | 1 | **a test failure**, at `2ea34f92` |

Fifteen of the sixteen come from records or deployed copies in a state the lifecycle passes through. One is a test.
The deterministic gate, which runs the F-198 regression suite, ran on 7 pushes and failed on all 7: six times on the
mirror check, then on the lease test. Since `2ea34f92` the lint job has failed first, so the gate has not run. Run locally on Windows at `bef03c45` (2026-10-24), the suite passed 130 of 131. The lease test that failed in CI
passed. The one failure, `distribution-module-update.ps1`, stopped at `tar: Cannot connect to C:`, where the local
shell's `tar` reads the drive letter as a host name: this machine's setup, not checked further. Whether the lease test
fails again on Linux is not known until the gate runs in CI.

## What Went Well

- **SC-011 passed live** on Copilot 1.0.101, with Copilot still running Claude's hooks: 0 receipts, stop-block rows or
  hook rows under `claude`, and no receipt written twice. The beta4.1 gate items, B4F-127 and B4F-129, held.
- **Capturing real payloads worked.** T025's probe found Copilot's second payload shape, and the re-walk's capture hook
  found 8 more shapes, now fixtures that the binding suite replays.
- **Friction fell again**: 0 extra stops and 1 corrective exchange, from 9 and 5 in iteration 001 and 2 and 1 in the
  first re-walk.
- **7 of 7 findings were real**, and each fix landed behind a test that failed first. Rework fell from 0.74 to 0.26
  times the task lines.
- **The partial sign-off path worked the first time** at this review-signoff stop.

## What Didn't Go Well

- **CI was red for the whole iteration, again**, and not read until the retro. The deterministic gate's last result is
  a failed test.
- **The review-signoff stop was skipped** (DRIFT-003), and the engine's sign-off was committed under the stage's name.
- **A closed iteration was edited** (DRIFT-002), because a moved task's records still pointed at it.
- **Round 4's finding reached the records as a "note".** By the maintainer's rule it is critical, and the record
  miscounted the findings.
- **T029 failed live**, the third walk in a row: an instruction does not keep Copilot off `ask_user`.
- **The approval-form code drew a critical in each round that read it**, as in iteration 002.

## Lessons Learned

1. **The engine's label is not the grade.** Rounds 3 and 4 were labelled minor and are critical by the maintainer's
   rule; the records softened round 4's further, to "note". Owner: crew, now: every round checkpoint shows the crew's
   grade beside the engine's label, and what the round-ending rule says follows. Owner: maintainer, at this iteration's
   closeout: B4F-151's disposition, now that it is graded critical.
2. **A lesson held by habit did not hold.** Iteration 002's lesson 2 was a crew habit, and CI went unread again. Most of
   the red was records in states the lifecycle passes through, which teaches everyone to ignore red, and the lint
   failure hid the one test failure. Owner: crew, now: read each CI job, not the run's colour, and run the deterministic
   gate locally before a closeout. Owner: maintainer, at the beta5 plan: B4F-158, so that a record-order failure cannot
   hide a test failure.
3. **The engine's sign-off and the stage approval share a name, and the crew took one for the other.** Owner: crew, now:
   check the last approved stage in `.specrew/start-context.json` before starting the next one (DRIFT-003). Owner: beta5,
   with the review-engine items: rename one of the two.
4. **When tasks move between iterations, their records move too.** T030's owned paths and the walk script still named
   iteration 002 after it closed. Owner: planner, at any move: list the moved tasks' owned paths and re-point those in
   the closed iteration. Owner: crew, now: run the validator before committing any record outside the active iteration.
5. **Counts are taken from the stored results.** The review record's counts were written from memory and were wrong.
   Owner: crew, now.
6. **An instruction does not keep Copilot off a tool.** Three walks; the fix has to refuse the call. Owner: maintainer,
   at the beta5 plan: B4F-131 and B4F-153, outside the beta4.1 gate.

## Iteration 002's Actions, Checked

| Action (iteration 002) | Held? | Evidence |
| --- | --- | --- |
| 1. Approvals narrow to a closed form | not due | decided at the beta5 plan; rounds 3 and 4 found the class again |
| 2. CI checked at every round checkpoint and before every packet | **no** | 16 of 16 pushes red; read first at this retro |
| 3. The round-ending rule applied from graded checkpoints | partly | four rounds, within the allowance and without a reset; no record shows a grade at a checkpoint |
| 4. The review record written after the last round; refusals and summaries verified | partly | written after the last round, but only once the maintainer caught the skipped stop; its counts were wrong |
| 5. Drift summary derived; pause-decision ignored | partly | `.specrew/review/pause-decision/` is ignored (002 closeout); deriving the summary is beta5's |
| 6. The re-walk fills SC-011; `ci-stored-time-step` pushed | partly | SC-011 passed; the branch is still local |

## Reviewer-Instruction Triage

- **PROMOTE**: for a fix that makes a path refuse, the brief asks the reviewer to check that every refusing branch tells
  the human (round 4 found this in round 3's fix).
- **PROMOTE**: for any hook change keyed on a payload field, the brief asks the reviewer to try the sub-agent shape of
  every event kind, not only the prompt (round 2 found the sub-agent stop after T028 guarded prompts).
- **DEFER**: the engine's labels against consequence grades, to beta5 with B4F-055 and the review-engine items.
- **DROP**: nothing.

## Signals for the Next Iteration

- Iteration 003's closeout is next, and is T031's live test: `.specrew/closed-iterations.yml` must stay unchanged until
  the maintainer approves.
- The closeout needs the gap ledger classified as fixed-now or deferred, with a defer entry naming the approving human;
  CI requires it. The maintainer's instruction at review sign-off keeps the fixtures added after sign-off listed as
  open until then.
- Feature 202's closeout follows and is T032's live test. The beta4.1 gate held live.
- B4F-151 is graded critical by the maintainer's rule; its disposition is the maintainer's.
- `ci-stored-time-step` still needs a login with workflow permission.

## Improvement Actions

1. Owner: crew | Phase: now | Type: process | Expected effect: each round checkpoint shows the consequence grade beside
   the engine's label and what the round-ending rule says (lesson 1).
2. Owner: crew | Phase: now | Type: process | Expected effect: each CI job is read at every checkpoint and before every
   packet, and the deterministic gate runs locally before each closeout (lesson 2).
3. Owner: maintainer | Phase: beta5 plan | Type: design | Expected effect: B4F-158: the deterministic gate runs whether
   or not lint passes, and the validator in CI accepts the states the lifecycle passes through (lesson 2).
4. Owner: crew | Phase: now | Type: process | Expected effect: the last approved stage is checked before each next stage,
   and the validator runs before any commit outside the active iteration (lessons 3 and 4).
5. Owner: crew | Phase: now | Type: process | Expected effect: review counts are taken from the stored results (lesson
   5).
6. Owner: maintainer | Phase: iteration 003 closeout | Type: decision | Expected effect: B4F-151's disposition at its
   critical grade, and the gap ledger classified.

## Calibration Suggestion

- **Capacity**: keep the 20 SP baseline. 5.75 SP was small; the cost was the re-walk and the carried approval code.
- **Price review by the code**: iteration 002's suggestion held. The carried approval-form code took two rounds and drew
  a critical in each; the plan priced one round for everything. Plan approval code at two rounds of its own.
- **Rounds**: planned one, used four, within the allowance and without a reset.
- **Rework**: 0.26 times the task lines. Keep measuring.

## Notes

- Finding attribution is from each stored finding's title and the fix commits: round 2's two notes count under T032 and
  T025, and rounds 3 and 4 under the carried approval-form code.
- Line counts exclude `tests/`, `specs/`, `docs/`, `.specify/`, `.specrew/`, `.squad/`, `.claude/` and `.github/`.
- CI causes are from each failed run's log, read on 2026-10-24.

## Rulings Recorded at the Retro Verdict

The maintainer approved the retro on 2026-10-25 with one instruction, recorded here after the approval so the approved
text did not change under it: a dated correction line goes into the review record and the acceptance evidence (7
findings, 6 fixed). Both now carry it.

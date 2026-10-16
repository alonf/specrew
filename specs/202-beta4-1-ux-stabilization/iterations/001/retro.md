# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-10-16

Written from the drift log, the review record, the acceptance evidence, the three retro inputs, `docs/beta4-findings.md`
and the commit history, not from memory. The iteration ran from 2026-10-13 (specify, `3821a05c`) to 2026-10-16 (review
sign-off approved, `e1d3bbcd`). 113 commits from `24e5701a` to `1fa4439e`, 15 tasks, six co-review rounds, 32 real
findings, 35 drift entries. Counts were measured at `1fa4439e`.

## Estimation Accuracy

Per-task effort was not time-tracked. The `tasks-progress.yml` timestamps are batch stamps written at landing (T005 to
T013 share one stamp, T014 and T015 another), so they measure nothing. Three honest measures are used instead: when the
task landed, how many later commits named it (excluding the mechanical runtime-refresh commits), and how many review
findings sit in its code (from `retro-inputs/findings-classification.md`). The commit proxy undercounts badly here,
because the round-fix commits name the round, not the task. The findings column is the better rework measure.

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 (capture real host payloads) | 1.5 | landed 2026-10-13 (`9cbe8703`); 4 follow-on commits, all citing its measurements; 0 findings | on estimate; ran before the before-implement approval by the maintainer's decision (DRIFT-005) |
| T002 (standard turn record, host bindings) | 2.5 | landed 2026-10-13 (`7bb8028f`); 2 follow-on commits; 1 finding (R1-1, the new origin never reached its reader) | on estimate; owned-file list too narrow (DRIFT-010) |
| T003 (latch-free hook-output journal) | 3.0 | landed 2026-10-13 (`aa2ffb7b`); 3 follow-on commits; shares 21 findings with T004 (7 first-pass, 14 from fixes) | the most under-estimated pair: the fixes added more code than the tasks did (Phase Variance) |
| T004 (disclosures, recovery question) | 2.0 | landed 2026-10-14 (`0edfb321`); 1 follow-on commit; shares the 21 findings above | as T003 |
| T005 (cross-host and fault-injection suite) | 2.5 | landed 2026-10-14 (`fd1f5a0f`), reopened and closed the same day (`d8b74af7`); 5 follow-on commits; 0 findings | under-estimated: CI never ran it on this branch until DRIFT-018, and case (e) then exposed the lock starvation (DRIFT-023) |
| T006 (presented boundary memory) | 2.0 | landed 2026-10-14 (`0b62bf9b`, with round 2's fixes); 0 follow-on commits; 5 findings (R3-1, R3-2 shared with T007, R5-6, R6-3, R6-4) | under-estimated: reply and link parsing kept finding input shapes |
| T007 (substance-only Stop check) | 2.0 | landed 2026-10-14 (`8904b71f`); 1 follow-on commit (`dc5a4fb8`, DRIFT-030); 1 finding (R6-2) | within estimate at landing; its first live run repainted a reply (DRIFT-030) |
| T008 (orientation first) | 1.5 | landed 2026-10-14 (`aac6a3fa`); 1 follow-on commit (its regressions, DRIFT-018); 1 finding (R4-4) | within estimate at landing |
| T009 (one shared dials sentence) | 1.0 | landed 2026-10-14 (`a039f618`); 0 follow-on commits; 0 findings | on estimate |
| T010 (one feature resolver) | 2.0 | landed 2026-10-14 (`55e0dddc`); 0 follow-on commits; 1 finding (R4-1, `specrew start` not routed through it) | on estimate |
| T011 (new-feature cycle reset) | 2.0 | landed 2026-10-14; its code is in `f46c9fb1` under a bootstrap identity, `e0d8c33e` carries the label (DRIFT-022); 1 follow-on commit; 1 finding (R5-1) | on estimate; provenance damaged by a stray commit |
| T012 (resume from disk) | 1.0 | landed 2026-10-14 (`488468fe`); 3 follow-on commits; 1 finding (R4-2) | within estimate; one pinned suite stayed red for a day because it was in no lane (DRIFT-025) |
| T013 (gate refusal names its producer) | 0.5 | landed 2026-10-14 (`018c4d13`); 3 follow-on commits, records only; 0 findings | on estimate |
| T014 (draft intake on stdin) | 1.0 | landed 2026-10-15 (`b9cf8b71`); 5 follow-on commits; 0 findings | under-estimated: the instruction surfaces reached past the three skills (DRIFT-028) |
| T015 (acceptance evidence) | 1.0 | landed 2026-10-15 (`62b95304`); 4 follow-on commits; 0 findings | on estimate as written; the live walk it scripted has not run, so its after-values are null |

**Average variance**: at landing, roughly zero. All 15 tasks landed between 2026-10-13 and 2026-10-15 against the
25.5 SP envelope. After landing, the variance is concentrated, not spread: T003 and T004, 5.0 of 25.5 SP (20%), hold 21
of the 32 findings (66%). The other 20.5 SP hold 11.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done before the plan | 2026-10-13, specify to before-implement in about six hours; 26 commits | on estimate | Workshop, spec, clarify and the design co-design were complete at plan time. |
| Discovery/Spikes | 1.5 | T001 on 2026-10-13, plus the host-injected capture step (DRIFT-009) | on estimate | Ran early by the maintainer's tasks-stage instruction, ratified at before-implement. |
| Implementation | 23.0 | T002 on 2026-10-13 to T015 on 2026-10-15; 54 commits | on estimate at landing | Two unplanned pull-ins by the maintainer's decision: the lock budget (DRIFT-023) and the init scope guard (B4F-120/122, DRIFT-027). Neither was priced in SP. |
| Review | four rounds (the cadence ruling, DRIFT-018) | six rounds, one allowance reset, sign-off by partial sign-off on 2026-10-16 | +2 rounds (+50%) | Round 5's result could not carry a sign-off (B4F-126); round 6 ran by mechanics (see below). |
| Rework | from slack, no SP | 32 findings fixed in 9 commits; 33 commits after T015 landed | the dominant cost of the iteration | In the dispatcher and the workshop authority store, the round fixes added 554 lines against the 452 that T003 and T004 added. The rework on that area was larger than the work. |

The plan priced review as an allowance and rework as slack, following the 199 retro's ruling. The 199 retro also
instructed: "track review and rework effort separately, or the 1:1:1 floor is unverifiable and the next retro writes
this sentence again." This iteration did not track them separately, so this retro writes that sentence again. The
measures above (rounds planned against rounds used, fix lines against task lines) are what the record supports.

## Drift Summary

- **Total drift events**: 35 headed entries, DRIFT-001 to DRIFT-035, one entry per identifier, none skipped.
- **Resolved in their heading**: 33. Eight of those were resolved by human decision (DRIFT-003, 005, 007, 008, 009, 013,
  018 and 027). DRIFT-006 was resolved inside T011.
- **Observation**: 1 (DRIFT-002, the layered gate refusals). It was closed through T013's widened scope.
- **Open**: 1. DRIFT-034, critical: one typed approval recorded twice (B4F-127). It goes to iteration 002 as the first
  item, and it gates the release.
- **Spec drift**: 1 (DRIFT-001, FR-018's branch precedence, spec updated at design-analysis).
- **Class closure NONE**: 10 entries (001, 003, 004, 007, 011, 013, 022, 033, 034, 035). DRIFT-022's NONE was superseded
  when DRIFT-027 closed its class.
- **Stale counts in the record**: the drift log's own summary block said "26 events, 100% (26/26 resolved)" until this
  retro corrected it to 35 entries with one open. The review record's Notes say "DRIFT-001 to DRIFT-034", which was
  true when it was signed. DRIFT-031's heading says its fixes are unreviewed, but round 5
  reviewed them. DRIFT-032's heading calls round 5 "the last", and round 6 ran. This is the 199 retro's lesson 7
  ("authored counts drift; derived counts do not") recurring, because its improvement action 5 (derive the summary from
  the entries) has not landed yet.

## (a) The Findings Trend: Too Large, or a Loop That Adds Defects?

The six rounds found 8, 5, 4, 5, 6 and 4 real findings: 32 of 32 real. The engine demoted 23 of them (8, 4, 4, 0, 4,
3), and every demoted finding was real (B4F-055). Round 6 found nothing in round 5's fixes. A blame of every line that
round 6's fix (`0e6a8a01`) changed traces to T003, T006, T007 and round 3's fix, none to round 5's `5c56dbed`.

**Verdict: both explanations hold, and the dominant mechanism is the loop, in one specific form: instance-sized fixes
in one subsystem with a large state space. Size decided when the four-round allowance ran out. The loop decided how
many findings there were.**

### The evidence that the loop dominates

- **Findings follow state, not size.** The outage and recovery area (T003 and T004, 5.0 SP) holds 21 of 32 findings,
  22 with T002's wiring finding R1-1. The tasks that added no state (T007, T010, T012 and T014, 6.0 SP) drew 3 (R4-1,
  R4-2, R6-2). That is about 4 findings per SP against 0.5 per SP. If size drove the count, findings would track SP.
- **Fix-related findings did not decay.** Per round they were 0, 5, 2, 2, 5 and 2 (16 in all). First-pass findings did
  decay after round 1: 8, 0, 2, 3, 1 and 2. Fourteen of the 16 fix-related findings are in the outage and recovery area.
- **The chain is direct.** In every round from 1 to 4, a fix added a store, a field or a write path, and the next round
  found a defect in exactly that addition (`state-inventory.md`, section 4):
  - round 1's Unix lock led to R2-2 (a buffer removed while a writer held it) and to DRIFT-023 (the lock starved
    writers);
  - round 2's session binding on the recovery question led to R4-5 (a question no live session could answer);
  - round 3's same-turn disclosure led to R4-3 (the Stop-block path lacked it) and R5-5 (another session's outcome
    reported);
  - round 3's shape check led to R6-1 (it checked only one field);
  - round 4's re-ask and rollback led to R5-3 (a declined question stayed armed) and R5-4 (a question written during a
    withheld fire survived).
- **The rework outgrew the work.** The round fixes added 554 lines to the dispatcher and the workshop authority store,
  against 452 from T003 and T004 themselves.

One precision matters for the fix. Of the 16 fix-related findings, 7 were introduced or made worse by a fix, and 9 were
incomplete fixes: a fix repaired one reader or one path and left a sibling with the same defect. So the loop mostly did
not create defects from nothing. Each fix closed one instance of a class and either added the next state or left the
next sibling.

### The evidence for size

- Sixteen findings are in first-pass task code. Under the review cadence (DRIFT-018), new task code entered every round
  through round 4: round 3 covered T006 to T011, round 4 covered T012 to T014. Each round split its attention between new
  code and the previous round's fixes.
- Rounds 5 and 6 found 9 of their 10 findings in code older than the round's scope. Round 6 found two first-pass
  defects (R6-2, R6-4) in code that round 3 had already read. A reviewer that returns four to eight findings a round
  needs more rounds for a larger surface.
- 25.5 SP was planned against the 20 SP convention, an overcommit recorded at the plan approval.

### Why size is the secondary cause

Remove the 5.5 SP overcommit by taking the lowest-yield tasks out, and the outage area stays, with its 21 findings and
its loop: the count barely moves. Keep the size but stop the loop in that one area, and the remaining first-pass
findings after round 1 totalled 8 across five rounds, which four rounds could plausibly have absorbed. Size made the
allowance run out sooner. It did not produce the count.

### The way out the evidence shows

Round 5's fixes were written as class closures, not instance fixes: the recovery question became a decision with three
answers (yes, no, unclear); every outcome read was tied to this reply and this session; every write made before
delivery is taken back on a withheld fire. Round 6 found no defect in any of them. One round is weak evidence, but it is
the only round in six whose fixes drew no finding in the next round.

## (b) Why the Failing-First Tests Missed All 32

Every fix in 202 was written behind a test that failed first. None of those tests caught any of the 32 findings before
the reviewer did. `retro-inputs/findings-classification.md` gives each finding one class: the condition a test would
have had to build to show it.

| Class | What the test would have had to build | Findings |
| --- | --- | --- |
| A | an input shape or edge case the author did not picture | 9 |
| B | state shared across sessions or turns (persisted records, ordering, staleness, identity, concurrent writers) | 12 |
| C | a withheld or partial delivery (output withheld, a failed or partial write, a torn or incomplete record line) | 10 |
| D | other: a new value that never reached its real reader (R1-1) | 1 |

B and C together are 22 of 32. Thirty of the 32 sit in code written during 202. The other two (R4-1, R5-1) sit in
older code that a 202 task made reachable.

In 8 cases the record names why the existing test passed, and in every one the test went around the real path or
carried the same assumption as the code:

- R1-1: probe providers stood in for the real handover provider.
- R1-8: the non-Windows test was still pending.
- R2-1: the test supplied the turn origin itself.
- R2-2: the case never built the two-process interleaving.
- R2-5: the test bypassed the normalizer.
- R3-4: the test preseeded an already-degraded state, so the ordering was never exercised.
- R4-1: the test checked two of the three consumers.
- R4-2: the fixture contained the defect (it assumed iteration 1's task list for iteration 003).

The reason is structural. A failing-first test proves the fix for the case its author pictured. Each fix's test
pictured one turn, one session and one delivery that succeeded. The defects lived in the second session, the later
turn, the withheld fire and the torn line, which no test built unless someone thought to build it. The parsing findings
are the same shape on the input side: the tests used `file:///` links only, while the validator accepted Markdown links,
code fences, bullets, parentheses and case-differing paths.

## (c) The Runtime-Store Inventory

`retro-inputs/state-inventory.md` lists every store, journal, flag file and per-session record on the hook and
approval paths, at 202's starting tree (`24e5701a`) and at the end.

- **Stores**: 78 before 202, 90 after. 202 added 12 and removed none. It changed the shape or write path of 9 more.
- **Where the findings were**: 23 of 32 in stores 202 added, 7 in stores whose shape 202 changed, 2 in no store (text
  parsing and an artifact read).
- **One family holds most of it**: the hook-output journal and the seven stores 202 built around it to remove its
  latch (the outage buffer, the health journal, the lock files, the set-aside files, the receipt outcomes, the recovery
  request and the recovery receipts) hold 22 of 32 findings.
- **The recovery request alone** was involved in 9 findings. Its fields grew in rounds 2, 4 and 5.
- **Two of the new stores have no reader**: the draft copy (`turn-message.md`) and the recovery receipts
  (`reply-recording-recovery.jsonl`). One more is read only to copy a field into another store (`session-start.json`).
- **No growth control**: no journal on these paths is pruned or rotated except two. The per-turn records grow by one
  file per turn, and every file is scanned.

The candidates to merge or remove, ordered by the findings they were involved in:

| # | Candidate | Findings | What it needs |
| --- | --- | --- | --- |
| 1 | Remove the recovery question and its two stores; set the journal aside automatically, since both readers still read set-aside files and nothing is lost | 9 | a spec decision: FR-009 asks for the human's approval |
| 2 | Derive the degraded state from the outage buffer and drop the health journal; retire the legacy flag file's handling | 7 | a refactor across three readers in three files |
| 3 | Replace the shared receipt-outcome journal with a value passed within the hook fire, or a field on this turn's record | 7 | a refactor; its only use is a same-turn disclosure, and being project-wide is why it needed time, hash and session filters |
| 4 | Make the outage buffer the queue for contended appends and drop the lock files (B4F-123) | 2, plus DRIFT-023 | a new "contended" outcome; the maintainer ruled it out of 202 |
| 5 | Keep only the new fields of the presented boundary memory and derive the rest from the pending stage record; drop `session-start.json` | 6, though most were parsing findings a merge would not remove | a refactor |
| 6 | One per-session orientation record instead of four flag files keyed three ways | 1, plus 1 follow-on | a refactor |
| 7 | Delete the draft copy | 0 | nothing: it has no reader |

**Does the evidence support the maintainer's concern that each fix added state and each new state produced the next
round's findings?** Yes, for rounds 1 to 4, directly (the chain in section (a)). Two cautions keep the retro from
over-reading it. First, each round reviewed the 202 diff, so new code drew findings whether or not it was state; the
fairer comparison is inside 202, where the non-state tasks drew 3 findings. Second, the state-heavy files are also the
largest diffs, so size and state are partly one signal. Neither caution changes the reading: 202 removed one latch by
adding a family of stores, and each store brought a lifecycle (who owns a record, when it clears, which session it
belongs to, how a damaged line is read) that the tests did not model.

One constraint for iteration 002's choice: the spec puts "any redesign of the hook dispatcher or stores" out of scope
(beta5). Candidates 2, 3, 6 and 7 are local refactors; candidate 1 changes a requirement. The retro's recommendation is
candidate 3: it carries 7 findings, needs no requirement change, and removes a shared journal whose cross-session reads
were themselves a finding (R5-5). The choice is made at iteration 002's plan stop.

## (d) Live Friction Events, Counted in the Governing Principle's Terms

The spec's governing principle: "A stop message is justified only when the system needs a human decision to proceed AND
the human lacks the context for it." An extra stop is a stop with no such decision. A corrective exchange is a human
message spent repeating or repairing something the human already gave.

| Date | Event | Stage | Real decisions | Corrective exchanges | Extra stops | Where it lives |
| --- | --- | --- | --- | --- | --- | --- |
| 10-13 | A tasks approval typed after a context compaction was not recorded; the packet was shown again and the approval retyped (B4F-112, DRIFT-004) | tasks | 1 | 1 | 1 | approval intake, beta5 |
| 10-15 | A whole reply rendered again over two reworded headings (DRIFT-030) | implement | 0 | 0 | 1 | 202's own Stop check; fixed in 202 |
| 10-16 | An allowance-reset approval on its own line below a paste was refused by position without saying why; the reset then needed a second approval for the round; a script was offered as the way to approve (B4F-125) | review | 1 | 2 | 2 | approval intake, iteration 002 |
| 10-16 | A stop after round 5 was offered and refused: a crew commit had moved the round's snapshot (B4F-126, DRIFT-032) | review | 1 | 1 | 1 | review engine, beta5; triggered by the crew |
| 10-16 | A stop after round 6 was offered and refused: round 6's fixes postdate the round (B4F-126, DRIFT-033) | review | 1 | 1 | 1 | review engine, beta5; the crew should have checked first |
| 10-16 | The Stop review check asked seven times for a round approval while the approved stops ran, and once more after review sign-off was approved (B4F-121) | review | 0 | 0 | 8 | review engine, beta5 |
| 10-16 | The records committed after the engine's sign-off voided the partial sign-off; the maintainer gave it again (DRIFT-035) | review | 1 | 1 | 1 | crew error |
| 10-16 | A Git for Windows update emptied the Git folder for about 12 minutes; the hooks failed on the missing `bash.exe`, and the re-typed partial sign-off was never recorded (DRIFT-035) | review | 0 | 1 | 1 | environment; hooks have no fallback |
| 10-16 | A reworded discussion question repainted the sign-off packet (B4F-128) | review | 0 | 0 | 1 | 202's own Stop check, iteration 002 |
| 10-16 | One typed round approval was recorded twice, leaving an unspent approval for about ten and a half hours (B4F-127, DRIFT-034) | review | 0 | 0 | 0 | approval recording; critical, gates the release |

**At the review close (2026-10-16), the record shows 15 extra stops and 6 corrective exchanges.** The table counts 4
decisions there, and one of them repeated a decision already given (the second partial sign-off), so the maintainer made
3 distinct decisions: reset the allowance and run round 5, close the review by partial sign-off, approve the review
sign-off stage. That is more than four extra stops per decision.

Across the whole iteration, adding events that are on record but not in the table above (B4F-121's earlier blocks at
rounds 3 and 4, and the round-1 approval the maintainer had to re-send, B4F-117 in DRIFT-011), the count is at least 19
extra stops and 8 corrective exchanges. It is a floor: the 199 retro showed that friction rendered by the agent leaves no
journal line, and the B4F-116 notice ("nothing was recorded" over an approval that was recorded) misinformed the
maintainer five times without being counted as a stop.

**Against the beta4 baseline** (8 extra stops in one session at review, none about the code, the 2026-08-28 ruling),
202's own review close was worse: 15 extra stops in one day, none about the code. The causes are mostly outside what
Tier 1 changed. Of the 15, 10 came from the review engine (B4F-121 and B4F-126), 2 from approval intake (B4F-125), 1 from
202's own Stop check on a line kind its fixes had not reached (B4F-128), 1 from a crew error and 1 from the environment.
The crew triggered or failed to prevent 3 of the 15.

**This does not measure whether 202 worked.** The real measure is the live walk (`live-walk.md`): intake to the specify
approval on Claude, Codex and Copilot, counted against the same baseline. Its after-values are all still null. Until it
runs, nobody, including this retro, can say whether Tier 1 removed the friction it was built to remove. What 202's own
run shows is that the review stage, which Tier 1 did not touch, is now where most of the friction lives.

## Review Close: What the Record Must Say

- **"No round 6" was overridden by mechanics, not by decision.** The maintainer's round-5 rule (DRIFT-031) was that
  round 5 is the last and its fixes go to sign-off accepted in advance. A crew docs commit (`0d1b2514`) landed while
  round 5 ran and moved its snapshot, so its result could never carry a sign-off. A sixth round was the only way to get
  one. The rule assumed round 5's result would be signable, and nothing checked that assumption before the rule was set.
- **The demotion count is 23, not 24.** DRIFT-015 said round 2 demoted all 5; its fifth finding was reported minor and
  never demoted. B4F-055, `tasks.md` and `acceptance-evidence.md` carried the 24 forward. All four were corrected in
  place (DRIFT-033). An authored count, copied three times, drifted from its source.
- **The release gate.** Closing iteration 001 is not a release. Beta4.1 does not ship (no merge to main, no published
  module) until B4F-127 is fixed in iteration 002 (maintainer ruling at review sign-off, DRIFT-034). Authority integrity
  ranks first in the spec's quality priority, and B4F-127 is an approval the human never gave.
- **The iteration 002 proposal**, recorded in `plan.md` and decided at iteration 002's plan stop, not here:
  1. B4F-127 first: bind every approval not tied to one pending stage to one human message, and make the second
     recording path a no-op.
  2. B4F-125 (approval intake: typed lines below a paste, one decision one approval, no script offered as the approval),
     with B4F-128 (a reworded discussion question counts when its meaning matches).
  3. B4F-055 (demotion on form; a summary never says "nothing needs your attention" over real findings).
  4. One simplification item from the inventory in section (c).

  Size: 15 SP or less. Review rounds are placed after the tasks that touch approval handling.

## Boundary Commit Discipline

`boundary-commit-discipline-violations: 3`

Every stage has its commit (specify `3821a05c`, clarify `fdef4476`, plan `e370407e`, tasks `91a49b8f`, before-implement
`711cf640`, implement from `a738729f`, review sign-off `e1d3bbcd`), and the branch is even with its remote at
`1fa4439e`. The three violations are
commits at the wrong moment, not missing ones:

1. A sweep suite committed T011's uncommitted work under a bootstrap identity (`f46c9fb1`, DRIFT-022). Root cause: the
   sweep ran on a tree with uncommitted work, and the init path committed into the enclosing repository (B4F-120,
   fixed in 202 by DRIFT-027).
2. A docs commit landed while round 5 ran (`0d1b2514`) and made its result unsignable (B4F-126). Root cause: nothing
   warns at commit time that a round is running.
3. Records were committed between the engine's sign-off and the stage (`7f6d2e39`, `743240be`, `a5baf65f`), which
   voided the partial sign-off (DRIFT-035). Root cause: the crew read the engine's warning about writes between steps as
   ending at the engine's own sign-off.

At retro time the working tree carries two modified tracked runtime files under `.specrew/review/pause-decision/`. They
are runtime state, not work, but they are tracked in git, and a commit that carries them is one more way a commit can
move what a review is bound to (inventory, item 11).

## What Went Well

- Every finding was checked against the code. All 32 were real, each was traced and fixed behind a test that failed
  first, and CI was green on Windows, Linux and macOS at `bf94e30a`, the last code change before sign-off.
- The interim demotion rule (DRIFT-018) earned its place. The engine demoted 23 real findings, and five of the six round
  summaries said nothing needed the maintainer's attention (B4F-055). Without the rule, those findings would have gone out as minor follow-ups.
- Unblocking CI (DRIFT-018) found two T008 regressions that the crew's sweeps had missed, because the sweeps never
  reached `tests/bootstrap`.
- DRIFT-023 was handled by measurement, not argument: 50 runs per variant, three variants, then the maintainer's ruling
  built as one budget per hook fire and re-measured over 100,000 fires.
- Round 5's fixes closed classes, and round 6 found nothing in them (section (a)).
- The feature-scoped stage identity from round 5's fix held on its first live use, at the review sign-off approval
  (DRIFT-035).
- Lane headroom was kept by splitting lanes, never by raising timeouts (DRIFT-026, DRIFT-029).
- The record held. The maintainer found B4F-127 by reading a journal, and the same day it was reproduced in scratch with
  a root cause and a failing-test outline (`b4f-127-reproduction.md`).

## What Didn't Go Well

- One subsystem took two thirds of the findings, and its fixes added more code than the tasks that built it.
- The review allowance was four rounds, and the iteration needed six. The maintainer's "no round 6" rule did not survive
  contact with the engine.
- The review close cost 15 extra stops and 6 corrective exchanges for 3 decisions, worse than the beta4 baseline this
  feature exists to beat. The crew triggered or failed to prevent 3 of them.
- Tests went around the real path in 8 named cases, and in one the fixture carried the defect.
- 202 added 12 runtime stores and removed none. Two have no reader.
- Suites outside every lane went red unnoticed: `deployed-bootstrap-floor` from T012 for a day (DRIFT-025), and
  `codex-stop-gate-fail-open`, caught only by CI's gate (DRIFT-031).
- B4F-127, a critical defect, has been in the journals since 2026-08-30. No control raised it. A human reading a file
  did.
- Counts drifted again: 24 for 23, and a drift summary frozen at 26 (corrected at this retro).

## Lessons Learned

1. **A fix that adds state is new code with its own lifecycle, and needs the review that new code gets.** In rounds 1 to
   4, every added store, field or write path drew the next round's finding. Owner: Reviewer, from iteration 002: at each
   round, any fix that adds a store, field or write path is named in the round checkpoint, with its writer, reader,
   clearing rule and session scope.
2. **Fix the class, not the instance, in a large state space.** Nine of the 16 fix-related findings were siblings that a
   fix left behind. Round 5's class-shaped fixes were the only ones that drew nothing next round. Owner: Implementer:
   every fix names the class and lists the siblings it checked.
3. **A failing-first test proves the case its author pictured. It proves nothing about a path it goes around.** Owner:
   Implementer: tests drive the real path (no supplied origin, no preseeded state, no probe providers), and every test of
   a store builds the second session, the later turn, the withheld fire, the partial line and the concurrent writer.
4. **Derive before you store.** 202 removed one latch by adding seven stores around one journal, and those stores carried
   22 of 32 findings. Owner: Planner: a plan item that adds a runtime store says why the state cannot be derived from a
   store that already exists.
5. **Commits are events the review engine sees.** All three discipline violations were commits at the wrong moment.
   Owner: crew, now as rules (sweep only a committed tree, no commit while a round runs, records before the sign-off
   step); owner: maintainer, for whether B4F-126's commit-time warning moves out of beta5.
6. **A rule set before a round must be checked against what the engine can do.** "No round 6" assumed a signable round
   5. Owner: crew: before offering any stop or setting a closing rule, check that the result can carry a sign-off.
7. **Authored counts drift; derived counts do not.** Second retro in a row. Owner: crew, the 199 chore (derive the drift
   summary from its entries), now overdue.
8. **Friction must be attributed to the component that caused it.** Most of the review close's friction came from the
   review engine, which 202 did not change. A friction total without attribution would read as Tier 1 failing. Owner:
   maintainer, for the friction measure in the live walk and the beta5 review work.

## Signals for the Next Iteration

- Beta4.1 does not ship until B4F-127 is fixed. Until then the interim crew rule stands: before any round launch, pause
  choice or allowance reset, check that the stored approval came from the human's own typed message for that run.
- Iteration 002's order, size and review placement are proposed in `plan.md` and decided at its plan stop.
- B4F-127 is approval-recording code, the same family as the stores in section (c). Lessons 1 to 3 apply to it
  directly: its fix should remove a recording path, not add a store, and its test is already outlined (one typed
  approval, then N turns with no human message, gives exactly one recorded approval).
- The live walk has not run. Its after-values decide whether Tier 1 worked, and iteration 002's acceptance should not be
  read without them.
- The Git Bash outage is recorded as retro friction. The maintainer asked for no finding.
- The tracked runtime files under `.specrew/review/pause-decision/` are modified in the working tree now. Ignoring that
  folder removes one way a commit can carry runtime state.

## Improvement Actions

1. Owner: Planner | Phase: iteration 002 plan | Type: process | Expected effect: 15 SP or less; one review round after
   each task that touches approval handling; the simplification item chosen from section (c), with the spec's
   out-of-scope line on store redesign checked against it.
2. Owner: Implementer | Phase: iteration 002 implement | Type: test standard | Expected effect: every test of a store or
   a fix to one builds the five conditions from lesson 3 through the real path; the 8 path-around cases cannot recur in
   new tests.
3. Owner: Reviewer | Phase: every round checkpoint | Type: process | Expected effect: each finding is classified the way
   `findings-classification.md` did it (class, introducing commit, fix-related or not) at the checkpoint, so a loop is
   visible after one round, not at the retro.
4. Owner: Planner | Phase: plan template | Type: process | Expected effect: any plan item or fix that adds a runtime
   store names its writer, reader, clearing rule and session scope, and why the state cannot be derived; a store with no
   reader is refused at plan time.
5. Owner: crew | Phase: now | Type: process | Expected effect: no commit while a round runs; records before the engine's
   sign-off step; check that a result can carry a sign-off before offering a stop. The three violations above do not
   recur.
6. Owner: maintainer | Phase: iteration 001 closeout | Type: acceptance | Expected effect: the live walk runs on three
   hosts and fills the null after-values, so Tier 1 is judged on its own measure.
7. Owner: crew | Phase: next chore slot | Type: chore | Expected effect: the drift summary is derived from its entries
   (the 199 action, carried a second time).
8. Owner: crew | Phase: next chore slot | Type: chore | Expected effect: `.specrew/review/pause-decision/` is ignored in
   git, so runtime approval files cannot ride a commit.

## Calibration Suggestion

- **Capacity**: keep the 20 SP baseline. 25.5 SP did cost rounds, but section (a) shows it was not what produced the
  findings.
- **Review is the real calibration gap.** Four rounds were planned and six were used (+50%), with one allowance reset.
  For iteration 002, plan rounds directly: one after each approval-touching task, plus one covering round on the tree
  that ships. Record rounds planned against rounds used at the retro.
- **State-adding work needs its own measure.** In this iteration, the outage and recovery tasks drew about eight times
  the findings per SP of the tasks that added no state. A task that adds a store should carry its own review round before another
  task builds on it, whatever its SP.
- **Track review and rework separately.** The 199 instruction stands, unmet twice. The minimum is the rounds count, the
  fix commits per round, and the fix lines against the task lines in the files the fixes touched.

## Notes

- Authored directly from the artifacts named above at `1fa4439e`, by the brief's instruction; the scaffold script and
  the retro stage sync were not run.
- Follow-on commit counts exclude the landing commit and the runtime-refresh commits (`chore(self-host)`). Line counts
  for the dispatcher are one copy of its two byte-identical copies.
- The B4F-112 and B4F-117 rows are derived from DRIFT-004 and DRIFT-011, not from the acceptance-evidence friction
  table, which starts on 2026-10-15. B4F-121's block at round 3 comes from its finding entry, and its block at round 4
  from the acceptance-evidence table.
- The round result files under `.specrew/review/` were not re-read; per-round counts and the demotion correction come
  from `findings-classification.md`, which read them.

## Rulings Recorded at the Retro Verdict

The maintainer approved the retro on 2026-10-16. Their first approval was not recorded because it arrived as pasted
text, which is B4F-125 again. It came with three additions and one widened rule, recorded here after the approval so
the approved text did not change under it.

### 1. The 32 findings graded by consequence

Grades: critical means a false authorization, data loss, or a write outside the project; major means recoverable, but it
blocks or misleads; minor is everything else. Each finding is graded in `retro-inputs/consequence-grading.md`.

| Round | Critical | Major | Minor | Total |
| --- | --- | --- | --- | --- |
| 1 | 5 | 3 | 0 | 8 |
| 2 | 2 | 3 | 0 | 5 |
| 3 | 0 | 4 | 0 | 4 |
| 4 | 0 | 5 | 0 | 5 |
| 5 | 4 | 2 | 0 | 6 |
| 6 | 0 | 4 | 0 | 4 |
| **All** | **11** | **21** | **0** | **32** |

- **All six rounds went to defects that mattered**: 32 of 32 are critical or major. Under the strictest reading of
  three borderline findings (R2-5, R6-2 and R6-4 moved to minor), it is 29 of 32.
- **The critical findings are 8 false authorizations and 3 losses of journal records.** Seven of the 8 false
  authorizations are in the recovery-question machinery; the others are R1-1 (a workshop receipt) and R5-1 (the shared
  stage identity). No finding wrote outside the project.
- **The engine demoted all 11 critical findings.** 27 of the 32 reached the maintainer labelled minor, and only round
  4's five carried a label that matched their consequence. Round 5's "Nothing found that needs your attention" covered
  4 critical findings. This is the strongest evidence yet for B4F-055.
- Confidence notes: if "data loss" means the human's own work only, the 3 journal-loss findings are major and the
  count is 8 critical. R1-6 (the action ran before its approval was recorded) could read as critical.

### 2. The simplification item: candidates 1 and 3 side by side

Both go to iteration 002's plan stop, where the maintainer decides; this replaces the retro's single recommendation
in section (c).

| | Candidate 1: remove the recovery question | Candidate 3: replace the shared receipt-outcomes journal |
| --- | --- | --- |
| What changes | The system sets the journal aside itself, says so, and keeps everything; both readers already read set-aside files | The same-turn disclosure reads a value passed within the hook fire or a field on this turn's record |
| Findings it carried | 9, including 7 of the 8 false authorizations | 7, including R5-5 (another session's outcome) |
| Requirement change | FR-009 (the human approves recovery); the maintainer decides it at the plan stop | none |
| Governing principle | fits: a stop with no decision the human needs to make goes away | neutral: removes no stop |

**Candidate 7, deleting the draft copy that has no reader, is done in iteration 002 regardless.** It costs nothing.

### 3. B4F-121 in iteration 002

The review engine caused 10 of the 15 extra stops at the review close, and it is deferred to beta5. B4F-121 alone
produced 8: the Stop review check asking for a round while an approved step ran, and again after sign-off. The plan
input in `plan.md` estimates whether it fits within 15 SP. The plan stop decides.

### 4. Lesson 5, widened to a standing rule

**No commit between any human approval and the step that consumes it.** That covers a review round, a stop, a partial
sign-off, an allowance reset and a stage approval. All three discipline violations in this iteration broke this rule
in one form or another. It replaces the narrower "no commit while a round runs" and "records before the sign-off step".

### Friction at the retro stop

The pasted approval was not recorded, and the retro packet was then shown again in full because the reply had carried
the approval phrase: 1 corrective exchange, 1 extra stop (B4F-125).

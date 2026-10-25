# Retrospective: Iteration 002

**Schema**: v1
**Recorded**: 2026-08-31
**Iteration**: 002 (FR-024..FR-033, the beta3 tag batch)
**Capacity**: 19.0/20 story_points, 12 tasks

---

## The finding this iteration is about

**The reviewer graded one finding `blocking` and seven `major` across three rounds. The campaign's durable
record shows `blocking_count: 0` and `major_count: 0`.**

The blocking-graded finding was a deterministic wedge of every second iteration — measured, not argued:
a fresh iteration's plan mirror went `planning → complete` on its first sync and, being forward-only, could
never come back. The acceptance bar this whole feature was convened against names *a wedged gate* in its own
words.

**Reading the summary alone, that round was clean and the wedge shipped.**

The only thing that prevented it was a standing instruction from the maintainer to read raw findings instead
of the summary. That instruction worked, and **it does not scale past a maintainer who knows to give it.**
The instrument that gates the tag was, for this entire campaign, incapable of surfacing the one severity
that would have stopped it.

That is the whole beta4 UX argument in one sentence, and it belongs at the front of this document rather
than in its findings list. Ruling at the review-signoff verdict: B-3 stays beta4, and beta3's release notes
carry the limitation in writing — *severity summaries understate; read raw findings* — because a documented
workaround is what saved this campaign and testers deserve it in writing rather than by discovery.

---

## Estimation Accuracy — and the answer 001 could not give

Iteration 001's retro could not say where its effort went: per-task effort was never time-tracked and its
Actual column was the estimate copied across. **002 was instrumented so it could answer.** It can.

**The question**: was the 1:1:1 floor right — review and rework each roughly equal to implementation?

| measure | value | source |
|---|---|---|
| Implementation calendar | **1.8 hours** (19:48 → 21:38, twelve tasks in one session) | plan.md countable block |
| Rounds consumed | **3 of 4** | campaign store `rounds_used` |
| Rework commits after round 1 delivered | **15** (`fix(beta3):` subjects) | `git log --since=<round-1 ended_at>` |
| Record commits in the same window | **24** (`docs`/`chore`) | same |
| Calendar, round 1 delivered → signoff | **26.1 hours** (1.09 days) | result `ended_at` → signoff |

**The answer: the floor was not conservative. It was optimistic by an order of magnitude.**

Review and rework consumed **~14× the implementation calendar** (26.1h against 1.8h). The plan's *direct*
estimate was 5.5 SP against 19.0 — a ratio of 0.29. The 1:1:1 parity floor named beside it as a check would
have predicted 1×. Both were wrong in the same direction, and the floor — deliberately named as the
pessimistic check — was still 14× too optimistic.

**Iteration 001 measured "roughly eight times the implementation calendar." 002 measured fourteen.** Two
iterations, both instrumented differently, both landing far above the floor, and the second worse than the
first. **The floor is not a floor.** For work of this kind — governance machinery reviewed by an independent
host with findings that must be verified before disposition — implementation is the small part, and any
plan that treats review as a fraction of it will be wrong by a multiple rather than a margin.

> **CAVEAT, and it travels with the number** (maintainer, at the retro verdict): 8× and 14× were measured
> **on this codebase** — governance machinery, reviewed by an independent host, under adversarial
> discipline. **Carry the multiplier as THIS PROJECT'S measured range, re-measured per project, never
> inherited as a constant.** A downstream application project may sit nowhere near it.
>
> *"A multiplier applied unmeasured is an authored count wearing a derived count's clothes."* That is the
> DRIFT-199-I002-012 defect — the Actual column that was the estimate copied across — arriving one level
> up, in a ratio rather than a cell. The instrumentation that produced these numbers is the thing worth
> copying to another project; the numbers themselves are not.

**What the instruction bought**: the ability to say that sentence with numbers behind it. That is what 001
could not do, and it cost one plan note and three `git log` invocations. The instruction paid for itself.

### The tripwire fired twice and never produced its stop

The plan set three thresholds. Measured against them:

- **Rounds consumed > 2** — **TRIPPED** (3 used).
- **Rework commits > 6** — **TRIPPED** (15).
- **Calendar round-delivery → signoff > 3 days** — not tripped (1.09).

**Execution did not stop, and that was correct** — but not because the wire worked. The maintainer was
making explicit rulings at every one of those points (the convergence rule, the no-round-4 commitment, the
triage of each finding), so the thing the tripwire exists to force — *a visible stop where the human decides
whether to continue* — was already happening continuously by other means.

**The honest reading**: the tripwire was redundant here because the human never left the loop, and it would
have been redundant in exactly the situation it was designed for. Its value is for a session where the human
*has* left the loop, and this iteration cannot say whether it would work there. **Recorded as unproven
rather than as passed.**

---

## Drift Summary

**39 events** (DRIFT-199-I002-001 through -039). Of those, **five are positive-control evidence** — the
first iteration in this feature to record controls working as first-class events rather than only failures:

| # | control | what it caught |
|---|---|---|
| -019 | the timestamp guard | a defect the *repair* introduced, into the authority store |
| -035 | honest state + mint gate + withhold discipline, composing | a fabricated crossing, one keystroke away |
| -037 | T016's `pushed-head` split | 34 commits of verdict evidence existing on one disk |
| -039 | T024's capture disclosure | a pasted packet, correctly refused **and disclosed** |
| FR-014 | invoked-only spend | three rounds not charged for engine failures |

A drift log that holds only failures teaches the wrong lesson about which behaviours to repeat. This is the
counterweight, and it is honest: at the one moment a false authorization was one step away, three controls
composed correctly and the agent read state rather than the conversation.

---

## What Went Well

- **Field evidence changed conclusions three times.** T016 and T020 proved in HelloWinUIReactive; T018
  proved in ConsoleFractal *on the state that broke it*. In each case the field found something no fixture
  had: the greenfield deadlock, then the stranded-project variant that the first fix would have left behind.
- **Findings were read raw, not summarised** — the instruction that saved the campaign.
- **Wrong findings were withdrawn rather than defended**, in both directions and three times.
- **The review economics held.** Invoked-only spend refused to charge three engine failures. No round 4.
- **The commitment made in advance held under pressure.** No round 4 was committed *before* round 3's
  blocking finding existed, precisely so that moment would not be the one deciding it.

## What Didn't Go Well

- **Twelve tasks produced three regressions**, and fixing those exposed three more test defects, and fixing
  those produced one more defect in the fix itself. Decreasing — three, then one — but never zero.
- **Two of the ten items shipped nothing.** `confirm-workshop-lens.ps1` and `constrained-yaml.ps1` were
  absent from the FileList: fully tested, fully mirrored, parity-clean, and reaching no project at all.
- **A guard was built inert** — `Get-SpecrewHookEventCoverage` with zero production callers — hours after
  this same log named the inert-control family for the eleventh time.
- **A human authorization was discarded in silence**, and it took four attempts and a source read to find
  why.
- **The signoff sequence cost four typed approvals**, three of them consumed by the crew's own sequencing
  and record-writing rather than by anything the maintainer did.

---

## Lessons Learned

### 1. The instance-not-class pattern, four times

The fix is written against the instance that produced the evidence, and the evidence is always one instance.

- **W77's carry** solved the records-delta problem for the acceptance kind in front of it; the
  partial-signoff override reproduced it.
- **T018's first fix** unblocked new workshops and stranded every project that had already confirmed its
  agenda.
- **The line-ending ruling** was scoped to this checkout when the statement was about any consumer.
- **The operator workaround** was scoped to the failure that had been watched, needed a third clause nobody
  guessed, and then failed for a fourth reason.

Every one was correct about what it repaired. Every one left the mechanism intact, so the next instance
arrived wearing different clothes. **The countermeasure is not more care; it is asking, before writing the
fix, what else has the shape of the thing being fixed.**

### 2. Every guard protects less than its name claims

Headed by the sentence that subsumes the rest: **the fixture wrote the precondition the product denies.**
Mutation proving covers control-to-test wiring, not control-to-system. Mirror parity covers divergence, not
omission. The pause fail-soft covered argument binding, not write failure. Hook health covers registration,
not arrival. A green suite covers the states its fixtures can build.

**And the two blind spots are different**: mutation proving catches a test that reimplements its subject;
running against a state you did not author catches fixture blindness. **Neither catches the other**, and
this iteration was bitten by both.

### 3. Writing a rule down does not make you apply it

**Every rule this iteration produced was violated after it was written, by the person who wrote it.** The
guard-scope principle, then a guard that reimplemented its subject. The fail-soft trace rule, then a trace
applied to one swallow of two. The instance-not-class pattern, then a workaround scoped to the instance.

In each case what caught it was not the rule and not a review — **it was running the thing**: the engine's
own integrity check, a fresh project on the accused host, a mutation that produced zero failures, a real
cycle replay. **The only detector that has worked is running the subject.**

### 4. A finding that reaches a boundary becomes an instruction

Three wrong causes were produced this fortnight — two by the crew, one by the maintainer — and each was
about to be implemented by the other party before measurement caught it. That is a property of the authority
structure, not of either party's care: **the cost of a wrong cause is paid by whoever implements it, not
whoever formed it.** The countermeasure was cheap and available every time: before acting on a diagnosis
about a component, invoke the component.

### 5. A refusal must name the thing that actually failed

Six refusals this batch were true about what they *checked* and misleading about what went *wrong* — and one
success message had the same property. The standard's clause cannot only be "name one reachable action"; it
must also be "name the thing that actually failed", and the action must be reachable **from the state the
reader is in**. Three of those refusals had a perfectly reachable action attached to the wrong subject,
which is worse than vagueness.

### 6. Where two error directions have asymmetric recoverability, guard the irreversible side

Under-mirroring self-corrects at the next sync; over-mirroring is permanent. A wrong owner inverts a stop; an
unknown one only widens it. A definite ABSENT refuses work that exists; UNVERIFIABLE only declines to answer.
This states the principle more usefully than "fail open" does, because it also covers the cases where the
permissive direction is the irreversible one.

---

## Signals for the Next Iteration

- **The greenfield smoke path already exists as a prototype** (`tools/smoke/greenfield-cycle-replay.ps1`) —
  a closed iteration plus a fresh one through the real top-level sync entry. It cost ten minutes and found a
  defect on its first run that eleven mutation-proved suites and a purpose-written fixture had missed. The
  beta4 case for it is concrete rather than aspirational.
- **Review cost is not a fraction of implementation cost.** Plan the next iteration with review and rework
  as the dominant term, or plan them as unbounded and gate on rounds instead of effort.
- **Field exercise is the only evidence tier that has predicted field behaviour.** Every fix carrying only
  mutation proof in this iteration was later found wanting by a real project.

## Improvement Actions

**Rulings at the retro verdict, 2026-08-31:**

- **Estimation — stop pricing review in story points.** Two iterations of measurement say the number is
  fiction: 0.29 estimated against 14 actual. The replacement separates three kinds of number so each can be
  honest about what it is:
  - **Implementation → estimated in SP.** It is bounded work with a known shape, and 002's estimate held.
  - **Review → governed by the ROUND ALLOWANCE**, which is a real budget with real enforcement, rather
    than by an effort figure nothing can enforce.
  - **Review calendar → forecast from the measured multiplier range, stated as a forecast and not a gate.**
  *"Estimates for implementation, budgets for review, measurements for calendar — each number of the kind
  that can actually be honest."* This supersedes the 1:1:1 floor as a planning device; the floor survives
  only as the check that revealed it was wrong.
- **The tripwire — kept, recorded as unproven, redesign filed for beta4**, with the diagnosis that makes it
  a class rather than a miss: **the tripwire was an instruction in a plan note, not machinery**, which is
  precisely why its firing cannot be verified. *The instruction-layer family again, inside the governance
  instrument built to catch it.* And its real trigger was never magnitude - it was
  **grind-without-decision**. Every threshold excess this iteration was covered by an explicit ruling, so
  the correct redesign fires on an excess **no ruling has addressed**, which requires it to be machinery
  that can see rulings. Beta4, alongside the friction measurement.
- **DRIFT-199-I002-038 — priority rises to the TOP of beta4's arbitration list, and does not enter beta3.**
  The resolution is known, mechanical, and has now been performed three times without drama:
  **the ledger wins until the crossing is authorized.** That sentence IS the arbitration rule; beta4's work
  is encoding it so nobody has to know it.

1. **Beta4: B-3 as a record defect** — severity demotion is written into campaign state, not merely
   displayed. Beta3 ships the limitation documented.
2. **Beta4: extend W77's records-delta carry to every acceptance kind**, so an authorization is not
   invalidated by writing the records that authorization requires.
3. **Beta4: arbitration between the two `Status` readers** (DRIFT-038), rather than loosening either.
4. **Beta4: bound the rationale to its own paragraph** — the semantic half of the silent-drop defect.
5. **Beta4: the greenfield smoke path**, promoted from prototype into the release-gate lane.
6. **Beta4: every guard declares its scope**, and the half it does not cover is tested.
7. **Now: iteration 003's plan sync before the tag** — the field proof for the cycle-wedge fix, which is
   otherwise replay-proved only.

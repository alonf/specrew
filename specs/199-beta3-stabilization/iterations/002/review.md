# Review Record: Iteration 002

**Schema**: v1
**Reviewed**: 2026-08-31
**Overall Verdict**: accepted with named gaps
**Campaign**: `cmp-199-beta3-stabilization-i002`
**Rounds**: 3 of 4 used

## What This Sign-off Claims, and What It Does Not

Iteration 001's record had to withdraw an independence claim it had already made. This record states its
gaps first so nothing has to be withdrawn later.

**It claims**: three independent review rounds ran against this iteration's tree, by `codex`, independent
of the code writer (`claude`); their findings were read from the raw campaign results rather than the
summariser; every finding was verified against the code before disposition; and the fixes carry mutation
proof.

**It does not claim** — and each of these is expanded below:

1. **That the shipping tree is covered by a review round.** It is not. Round 3's findings were fixed
   *after* round 3, so the tree carries changes no round examined.
2. **That every fix has field evidence.** Three do; three do not, and one of those has never executed
   outside this repository.
3. **That the review record's own severity counts are trustworthy.** They are not, and the measurement of
   why is the most important thing in this document.

## The Instrument Defect That Gates Everything Else

**The reviewer graded one finding `blocking` and seven `major` across three rounds. The campaign's durable
record shows `blocking_count: 0` and `major_count: 0`.**

Round 3's `pending-pause.json` reads `blocking_count: 0, major_count: 0, minor_count: 4, demoted_count: 4`.
The demotion is not a rendering — it is written into the campaign's persistent state, so every consumer that
counts rather than reads inherits it.

The blocking-graded finding was `cycle-reset-mirror-wedge`: a deterministic wedge of every second iteration,
against an acceptance bar whose own words name *a wedged gate*. **Reading the summary alone, round 3 was
clean and the wedge shipped.** The only reason it did not is a standing instruction from the maintainer to
read raw findings instead of the summary — a workaround that worked and does not scale past a maintainer who
knows to give it.

Recorded as DRIFT-199-I002-016 (reclassifying B-3 from a summariser defect to a **record** defect) and
DRIFT-199-I002-030. This is the retro's lead item.

## Rounds

| round | run | verdict | reviewer grades | shown | disposition |
|---|---|---|---|---|---|
| 1 | `run-20260829-214056323-db3b4944` | findings | 3 × major | 3 × minor | 2 fixed, 1 pinned |
| 2 | `run-20260830-003634780-04d58169` | findings | 2 × major, 1 × minor | 3 × minor | 1 deferred, 2 fixed |
| 3 | `run-20260830-160011946-a3d8338c` | findings | 1 × **blocking**, 3 × major | 4 × minor | 2 fixed, 2 deferred |

An earlier attempt (`run-20260829-202021847-c98fb407`) failed pre-invocation and **consumed no round** —
FR-014's invoked-only spend, exercised for the first time unplanned. It held three times in total.

**No round 4.** The commitment was made in advance of round 3's findings, precisely so that moment would not
be the one deciding it.

## Findings and Dispositions

**Round 1** — `workshop-receipt-contract` (FR-027, writer/reader name mismatch) **fixed**;
`foreign-owner-still-stop-blocked` (FR-032, a flag set and never read) **fixed**;
`bare-marker-bypasses-identity` (FR-024) **pinned** with its closure condition, the expired justification
removed from the test, the source comment and the suite header.

**Round 2** — `pause-write-error-still-swallowed` **deferred to beta4** under the convergence rule, with the
crew's own admission intact: the guard survives that defect by one assertion, which is luck rather than
design. `global-marker-misassigns-owner` (FR-032/SC-019 **inverted** under concurrent sessions) **fixed**.
`numeric-approval-docs-stale` **fixed by deletion** in three places.

**Round 3** — `cycle-reset-mirror-wedge` **fixed** (the reviewed-state replay is capped at the boundary
being synced) and the checker capped with it, a second defect found only by an end-to-end replay.
`hook-event-guard-unwired` **fixed** by wiring the guard into `Resolve-SpecrewHookHealth` and rendering it.
`bare-marker-bypasses-identity` and `fresh-state-mirror-fields-missing` **accepted as follow-ups** — the
second verified *separate* from the cycle fix rather than assumed closed by it.

## Gap Ledger

1. **The shipping tree carries changes no round covered** — 9 source files and 6 commits beyond round 3's
   target `df2edd1f`. Every one is round 3's own output: finding 1's cap, the checker cap found inside it,
   and finding 2's wiring. A fourth round would review the response to the third and produce work needing a
   fifth. Accepted by explicit typed authorization, `human-authorized-partial-override`, with the
   maintainer's own rationale on record.

2. **T017 (FR-026, the constrained readers) has never executed outside this repository.** This is weaker
   than "mutation-proved only", which implies the code was present in the field and merely unobserved. Its
   shared reader `scripts/internal/constrained-yaml.ps1` was **absent from the FileList** and began shipping
   on 2026-08-30 (DRIFT-199-I002-024). Its two dependents loaded it with `if (Test-Path) { . $path }`, so
   downstream the FR-026 refusal wording was simply undefined.

3. **Finding 1 is replay-proved, not field-proved.** Mutation-proved at the gate and end-to-end through the
   real top-level sync path with a seeded store — which is where it caught the checker defect fixtures
   missed — but not yet observed in a genuine cycle. **003's plan sync is a gating step before the tag**, so
   the field proof arrives before shipping rather than after.

4. **Field evidence, by task**: T016 and T020 proved in HelloWinUIReactive; T018 proved in ConsoleFractal on
   the state that broke it, both paths. T017, finding 1 and finding 2 have no field exercise.

## Signature

Sign-off authorized against the tree at the time of the partial-override capture, on the maintainer's typed
`approved for partial review signoff` with a rationale recorded in
`.specrew/review/signoff-gate/override-authorizations/`. Gate decision: `allow`, reason
`human-authorized-partial-override`.

The full account of every finding, disposition and measurement is in
`specs/199-beta3-stabilization/iterations/002/drift-log.md` (36 events).

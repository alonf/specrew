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

Each entry is classified. Nothing here is closed by this sign-off; the deferred items are named so the tag decision is made against them rather than around them. All five deferrals are registered with their approving human in `.squad\decisions.md` under decision id `f199-i002-review-signoff-gap-ledger-deferrals`.

1. **DEFERRED — the shipping tree carries changes no round covered.** 9 source files and 6 commits beyond round 3's target `df2edd1f`, every one of them round 3's own output: finding 1's cap, the checker cap found inside it, and finding 2's wiring. A fourth round would review the response to the third and produce work needing a fifth; no round 4 was committed in advance of this finding existing. Accepted by explicit typed authorization, `human-authorized-partial-override`, with the maintainer's own rationale on record.

2. **DEFERRED — T017 (FR-026, the constrained readers) has never executed outside this repository.** Weaker than "mutation-proved only", which implies the code was present in the field and merely unobserved: its shared reader `scripts/internal/constrained-yaml.ps1` was absent from the FileList and began shipping on 2026-08-30 (DRIFT-199-I002-024), and its two dependents loaded it with `if (Test-Path) { . $path }`, so downstream the FR-026 refusal wording was simply undefined. Field evidence arrives with consumer use.

3. **DEFERRED to the pre-tag step — finding 1 (FR-030) is replay-proved, not field-proved.** Mutation-proved at the gate and end-to-end through the real top-level sync path with a seeded store, which is where it caught the checker defect the fixtures missed, but not yet observed in a genuine cycle. 003's plan sync is a gating step before the tag, so this one's field proof arrives before shipping rather than after.

4. **DEFERRED — three of six items have no field exercise.** T016 and T020 are proved in HelloWinUIReactive and T018 in ConsoleFractal on the state that broke it, both paths; T017, finding 1 and finding 2 are not. Named per task in the verdict table below.

5. **DEFERRED — the review record's severity counts cannot be trusted.** The reviewer graded one blocking and seven major across three rounds; the durable record shows zero of each. This is beta4's B-3, reclassified from a summariser defect to a record defect (DRIFT-199-I002-016), and it is the retro's lead item.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T014 | FR-024 | pass | Mint gate: no crossing until the from-stage's owed artifacts exist on disk. Fired live on 2026-08-31 as one of three controls refusing a fabricated crossing (DRIFT-199-I002-035). Suite `crossing-mint-gate`, mutation-proved. |
| T015 | FR-024 | pass, with a pinned gap | Withhold discipline and marker-identity binding. Round 1 found the bare-marker residual; the renderer work is carried, and case 4c now states what is true, why it is deferred, and what closes it, with the inverse assertion written out disabled. Round 3 re-reported it, correctly, as a known gap. |
| T016 | FR-025 | pass, field-proved | `pushed-head` split into delivery and durability. Proved in HelloWinUIReactive (no git remote: both origin-dependent checks stand down) and fired on this repository's own review-signoff boundary, catching 34 local-only commits (DRIFT-199-I002-037). |
| T017 | FR-026 | pass, no field exercise | Zero-construct detection and representation-naming in both constrained readers. Mutation-proved. **Its shared reader was absent from the FileList and began shipping 2026-08-30, so it has never executed outside this repository** (DRIFT-199-I002-024). |
| T018 | FR-027 | pass, field-proved | The governed lens checkpoint writer. Round 1 found a writer/reader name mismatch and a derived scope, both fixed at cause. A deadlock stopping every greenfield workshop at its first lens was found by starting a real project, not by any suite (DRIFT-199-I002-027), then a second defect stranded already-advanced projects and was found only by resuming a real deadlocked one. Both paths proved in ConsoleFractal. |
| T019 | FR-028 | pass | Acknowledgment line and the repair refusal through the contract; recognizers deliberately not widened. Suite `lens-acknowledgment`. |
| T020 | FR-029 | pass, field-proved | The not-yet-authored spec stub. Created in HelloWinUIReactive: sentinel present, zero placeholders, zero `FR-\d{3}`, and it names the two things the original walk did wrong. |
| T021 | FR-030 | pass, replay-proved | The crossing-mirror writer over every enumerated mirror. Round 3 graded a **blocking** regression here — the replay of a global authorization into a new iteration wedged every second cycle — fixed by capping the replay at the boundary being synced, and a second defect in the checker was found by an end-to-end replay through the real sync path. Not yet observed in a genuine cycle; 003's plan sync is a gating step before the tag. |
| T022 | FR-031 | pass | The closeout seal written last. Suite `delivery-durability-seal`. |
| T023 | FR-032 | pass | The pending crossing owed by the session that recorded it. Round 1 found the owner-scoped flag set and never consumed; round 2 found ownership **inverted** under concurrent sessions in a shared worktree — the maintainer's own configuration — and both are fixed with the ambiguity refused rather than guessed. |
| T024 | FR-010 | pass | Capture disclosure at prompt entry. |
| T025 | FR-033 | pass, and it found the method defects | The method sweep. Produced the mutation-proving limit rule, the guard-scope principle, the asymmetry rule and the seam rule — each of which this iteration then violated at least once, which is the retro's closing note. |

**Two tasks carry named gaps rather than clean passes** (T017's absence of any field execution, T021's
replay-only proof), and one carries a deliberate pinned residual (T015). Nothing here claims coverage the
gap ledger above denies.

## Signature

Sign-off authorized against the tree at the time of the partial-override capture, on the maintainer's typed
`approved for partial review signoff` with a rationale recorded in
`.specrew/review/signoff-gate/override-authorizations/`. Gate decision: `allow`, reason
`human-authorized-partial-override`.

The full account of every finding, disposition and measurement is in
`specs/199-beta3-stabilization/iterations/002/drift-log.md` (36 events).

# Iteration State: 011

**Schema**: v1
**Current Phase**: retro
**Iteration Status**: retro
**Closure Attempt (REVERSED)**: closed 2026-08-06T13:19:56Z on an approved verdict, then **un-closed the
same day** when the release gate (`validate-governance.ps1 -IncludeClosed`) rejected the closure as
`over-claim`: the status claimed closure while `review.md` and `quality/hardening-gate.md` did not exist.
The verdict was real; the artifacts were not. **The status was reversed rather than the evidence
backfilled under it**, so the record never shows closure preceding its evidence.
**Last Completed Task**: T090 (T092 ran to its cap and is terminal as `deferred`)
**Tasks Remaining**: (none — T091 and T093 deferred to beta3 by recorded decision)
**In Progress**: (none)
**Baseline Ref**: d7f27f6a
**Updated**: 2026-08-06T10:01:22.0165619Z

## Execution Summary

<!-- specrew:task-progress-summary:begin -->
- Execution is in progress.
- Task progress: 5 complete, 0 in-progress, 3 pending, 0 blocked.
- Latest completed task: T090
<!-- specrew:task-progress-summary:end -->

| Task | Status | Evidence |
| --- | --- | --- |
| T086 | done | FR-068 reproduction, both halves, RED-first |
| T087 | done | FR-066 fixtures RED-first; premise corrected on measurement |
| T088 | done | Unrecordable crossing is a branchable state; `success=false` |
| T089 | done | Provider speaks and names what is missing; T087 fully green |
| T090 | done | Both branches gated from one helper; T086 half 1 GREEN; contract authored |
| T091 | deferred | Composition half → beta3 hook-machinery cluster |
| T093 | deferred | Relief valve fired at T090's re-estimate → beta3 first row |
| T092 | deferred (ran to the cap; did NOT certify) | 3 of 3 rounds spent. R1: 4 findings. R2: validated findings 1/3/4, 1 blocking on the finding-2 fix. R3 (current digest): 1 blocking + 1 major. Finding-2 attempts reverted per the pre-committed ruling; gate green 90/90 |

## Delivery Position — FR-066 PARTIAL, FR-068 evidence half DELIVERED

| Requirement | State |
| --- | --- |
| FR-068 evidence half | **delivered** — tree-bound stage evidence, fail-closed unverifiable reasons, strict clarify matcher; validated by round 2, unchanged since |
| FR-066 arrival state | **delivered** — the unrecordable crossing is branchable and the surface names what is missing |
| FR-066 mint guard | **NOT delivered** — two attempts, both faulted (double-failure window; concurrent latch clear). Reverted. **The mint hole is OPEN and known.** |

**The current tree carries no independent certification**: all three rounds are spent and `86c5eb07`
has never been reviewed in this exact shape. Round 2's validation of findings 1/3/4 stands, and their
code is byte-unchanged since — that is the assurance the tag rests on. The green 90/90 gate is a
regression floor, not a certification.

**TAG BASIS RULED 2026-08-06 — named-limitation.** Beta2 gates on FR-068's evidence half plus FR-066's
arrival state; FR-066's mint guard ships as a named known defect carried to beta3. Iteration 011 **records**
at **~29.0/20 uncompressed with FR-066 partial** and is held open — see the closure trigger below. The beta3 carry list is consolidated in
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/011/drift-log.md

## Closure Trigger — why 011 is honestly OPEN

**The schema vocabulary blocks an honest closure, and the words were not bent to reach one.**

Closure requires `Overall Verdict: accepted`, which the schema permits only when **every** task verdict is
`pass`. T092's deliverable is *integrated verification and capped certification*. Verification passed
(90/90); **certification was attempted to the full 3-round cap and not achieved.** Marking T092 `pass`
would assert a result that does not exist, so `review.md` records `needs-rework` and the iteration is held
at `retro` — past its approved retrospective, but not closed.

**Closure trigger**: iteration 011 closes when **beta3 delivers FR-066's mint guard** from its design
spike — at which point FR-066 is whole and T092's certification claim can be re-made against a tree that
carries it.

**The beta2 tag proceeds with 011 honestly open.** The named-limitation basis never claimed 011's
certification, so nothing downstream depends on this closure. An open iteration with true artifacts beats
a closed one with false words.

### Superseded closure attempt (retained for the record)

**Closed 2026-08-06T13:19:56Z, then REVERSED the same day.** Closed on an explicit
`approved for iteration-closeout` (approve-with-instructions),
following `approved for retro` and the retro boundary packet. Closeout actions executed:

| Action | Result |
| --- | --- |
| Iteration registered closed | file:///C:/Dev/specrew-beta2-hardening/.specrew/closed-iterations.yml — `198-beta2-hardening / 011 / 2026-08-06T13:19:56Z`, written through `Add-SpecrewClosedIterationEntry` rather than hand-edited |
| Campaign disposition | `override-block` recorded on `run-f198-i011-fe88af18-certify` by the maintainer; **no round re-funded** |
| Disposition rationale (verbatim) | *"the named-limitation tag basis explicitly does not claim certification of the final tree; this disposition formally registers that already-made human decision."* |

The disposition **registers** a human decision already made in the tag-basis ruling; it does not create
one, and it does not assert certification the tree does not have.

A `tasks-progress.yml` is authored alongside this file rather than left to be auto-created later.
Iteration 010 had none, one was minted all-pending mid-life, and the summary writer overwrote a
corrected record with "not-started" for delivered work (DRIFT-198-I010-010). Authoring the tracker
at plan time removes the condition that defect needs — and it worked: the tracker carried the real
statuses, so the generated summary above recomputed to disk truth instead of overwriting it.

## Objective

Close the two authorization-integrity defects from the consumer manual test — FR-066 and FR-068 —
where a human can be led to authorize an increment that does not exist.

## Authorization

- **Phase 1 (specify + clarify)**: approved 2026-08-02. The spec carries the FR-019 scope
  amendment and FR-066/FR-067/FR-068, with SC-022..SC-025.
- **Phase 2 (plan → tasks → before-implement)**: approved 2026-08-03/06. Implementation authorized; T086–T090 delivered.

## Scope

FR-066 and FR-068 only, with criteria SC-023 and SC-025. FR-019 and FR-067 are deferred on the
measured estimate, not on preference — see `plan.md`.

## Capacity Position — ~29.0/20, OVER BY ~9.0, uncompressed

**Superseded 2026-08-06 (second time), and recorded at the number it actually is.** Certification
round 1 returned four validated findings — two blocking, two major, all defects in 011's own
corrections — and the rework is internal to this iteration's deliverables, so the zero-slack rule does
not route it.

| | Planned | Running total |
| --- | ---: | ---: |
| Iteration 011 as approved | 20.0 | 20.0 |
| Option 3 rework (findings 1–4 + RED-first fixtures) | +5.5 | 25.5 |
| Fixture collateral at measured size (option (a), 3 suites not 1) | +3.5 | **~29.0** |

**Capacity 20. Position: OVER by ~9.0.** The estimates are NOT compressed to make the cap appear to
hold — that is precisely what Iteration 009's ledger prices at ~70 SP against a cap of 20, and the
reason its trigger needed amending twice.

**Maintainer ruling 2026-08-06: beta2 still gates on 011.** The tag basis is authorization-integrity by
explicit ruling; this overrun is honest rework of the tag-gating machinery itself, and re-cutting the
tag to avoid finishing trust machinery was already rejected as option 4 — same logic, same answer.

### Superseded capacity note (retained for the record) — 20.0/20, exactly at cap

The iteration measured **21.5 SP against a capacity of 20**. T091 (3.0 SP, FR-068's composition
half) was deferred to beta3, bringing it to 18.5; **T093 (1.5 SP) was then added by maintainer
instruction on 2026-08-03** to fix the campaign-mode halt text, putting the iteration at **exactly
20.0/20 with zero external slack.** T092's internal correction allowance is intact.

**Superseded 2026-08-06**: T090 re-estimated 4.0 → 5.5 SP at its start gate and the pre-agreed relief valve fired, deferring T093 to beta3's first row. Its 1.5 SP covers T090's gap exactly, so the iteration total is unchanged at 20.0/20.

FR-068's composition clause no longer holds this iteration open: the maintainer's authorized specify
touch names the beta3 hook-machinery cluster inside SC-025 itself, so the requirement closes
honestly rather than hitting the DRIFT-198-I009-044 wall.

## Tasks Boundary — completed 2026-08-03

- **T086–T093 breakdown**: authored, with owners, effort, ownership globs, sequencing, and
  dependencies.
- **Bidirectional traceability**: **PASS** for Iteration 011 — 8/8 tasks map to an FR by record;
  FR-066, FR-068 and FR-018 all have covering tasks; SC-023 and SC-025's evidence clause are
  covered, and SC-025's composition clause is scoped-out by name rather than left uncovered.
- **`tasks.md` backfill (DRIFT-198-I010-007)**: Iterations 009, 010 and 011 sections landed in the
  same pass. Iteration 009's check is recorded **PARTIAL, not PASS** — it was planned against
  F-labels rather than FRs, so the FR-direction check cannot be computed, and claiming PASS would
  repeat the unverified-coverage error this feature has already made twice.

## Open Obligations Carried Into This Iteration

- **The full consumer-severe set measures ~52 SP** — three iterations, not the two the carried
  instruction assumed. FR-019 alone is ~19 plus certification; FR-067 ~14 plus certification. The
  beta2 tag's basis therefore needs a maintainer ruling: gate on authorization-integrity alone, or
  on the whole set and move the tag.
- **FR-019 has a blocking precondition to settle before it is scheduled**: the repo runs in
  campaign mode, where `specrew-review.ps1:803` rejects every remediation except `override-block`,
  so the two paths FR-019 changes are unreachable in the live mode today.
- **`tasks.md` backfill (DRIFT-198-I010-007)** — DISCHARGED at the tasks boundary: Iterations 009, 010 and 011 sections landed, with 009 recorded PARTIAL rather than PASS.

## Blockers

- **Last Escalated**: (none)

# Iteration Retrospective: 003

**Schema**: v1
**Feature**: 198-beta2-hardening
**Iteration**: 003
**Scope**: closure-scoped (retroactive)
**Authored**: 2026-07-27
**Authority**: maintainer instruction at the 2026-07-27 retroactive iteration-closeout

## Scope of this retro

Written at a retroactive closeout, thirteen days after Iteration 003 stopped
executing. It records the lessons that are visible from the durable record —
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/003/state.md
and
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/003/drift-log.md
— not reconstructed in-the-moment sentiment. Where a lesson was already acted
on, that is said plainly; a retro that claims foresight it did not have is
worth less than no retro.

## What went well

- **Co-review found real defects repeatedly, and they were fixed rather than
  argued with.** Containment escapes (symlink/junction, case-sensitivity,
  intermediate-directory links), false round accounting, an origin leak in the
  diff, and a tamper hole in verification all surfaced through review and were
  corrected with paired tests.
- **Overclaims were retracted in the record, not quietly edited out.** The
  "structurally unable to alter" phrasing was itself caught as a finding and is
  corrected in place, with the retraction left visible.
- **Evidence discipline hardened mid-iteration.** Review `90173dc6` found the
  green counts were prose with no digest-linked runtime evidence; the response
  was a recorder producing digest-bound runner-observed evidence rather than a
  tidier prose claim.
- **A simplification was chosen over more hardening.** After five review rounds
  on orchestrator-run verification, the maintainer chose to remove the
  mechanism rather than keep armouring it. Net code reduction.

## What was hard

- **T019 was too large to finish.** Seven pieces spanning identity, leasing,
  packet gating, evidence injection, stamping, and retention. Three pieces
  landed; the rest were superseded by an architecture that arrived in Iteration
  006. A task that needs a reconciliation table to explain its disposition was
  not one task.
- **Concurrent reviews raced.** A manual `--live` run and an autonomous
  navigator run fired ~30s apart on the same lineage — which was itself T019's
  scope, so the defect and its fix were circularly blocked.
- **Reviewer-host flakiness cost real cycles.** Codex empty-exit-0 had two
  distinct causes (self-triggered governance hooks, then file-primary delivery
  against a stdout-primary assumption); both were diagnosed properly rather
  than retried blindly, but they consumed the iteration.
- **The iteration was never closed.** Execution stopped, work moved to 007, and
  the open iteration sat there until a config change made it fail validation
  thirteen days later. Nothing was lost, but the ledger stopped matching
  reality — and the ledger is the product here.

## Lessons

1. **Stopping an iteration is not closing it.** The work moved forward
   correctly under an authorized reconciliation; the bookkeeping did not
   follow. An iteration left `executing` is a silent claim that it is still in
   flight.
2. **A capacity revert can retroactively invalidate an open historical
   iteration.** The grandfather rule protects closed iterations only, so
   leaving 003 open turned an unrelated config change into a CI failure. Close
   first, then revert.
3. **A task needing a per-piece disposition table was mis-sized at planning.**
   T019's reconciliation is well written, and it should not have been needed.
4. **Evidence must be digest-linked from the start.** The mid-iteration
   correction from prose counts to recorded runs should be the default posture,
   not a response to a finding.

## Estimation Accuracy

Planned capacity was `12/26` story points. The estimate held for the containment
and evidence work and failed for the one large task.

| Task | Planned SP | Actual SP | Read |
| --- | --- | --- | --- |
| T034a | 0.25 | 0.25 | On estimate. |
| T013 | 1.0 | 1.0 | On estimate, but absorbed four later review rounds of escape-hardening not counted here. |
| T014 | 1.0 | 1.0 | On estimate. |
| T015 | 0.5 | 2.5 | **5x over.** Five review rounds on orchestrator-run verification, ending in the maintainer's decision to remove the mechanism. |
| T016 | 1.0 | 4.0 | **4x over.** Reopened and the requirement amended mid-flight (FR-011/SC-003). |
| T017 | 1.5 | 2.0 | Modestly over; the denylist false-allow correction was unplanned. |
| T018 | 1.0 | 1.0 | On estimate after the framework-neutral amendment reshaped it. |
| T020 | 1.0 | 1.5 | Over; two-budget accounting was larger than the halt-UX framing suggested. |
| T019 | 1.5 | — | **Not completed.** Seven pieces; three landed. The single worst estimate of the iteration. |
| T030–T033, T034b | 3.25 | — | Not started; carried to Iteration 007 at the same 3.25 SP, where they were delivered. |

Pattern: the two tasks that blew up (T015, T016) did so because their
*requirement changed during execution*, not because the work was mis-sized
against a stable target. T019 is different — it was mis-sized at planning, and
no amount of execution discipline would have rescued a task that needed a
seven-row reconciliation table to explain itself.

## Drift Summary

Nine drift events were recorded during execution in
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/003/drift-log.md.
The dominant classes:

- **Containment escapes** (symlink/junction, lexical-only comparison, case
  sensitivity, intermediate directory links) — four separate rounds, each one
  level deeper than the last. The same convergence pattern later recurred in
  Iteration 009's path-identity work, which suggests the class was never fully
  generalized, only patched where reviewers reached.
- **Evidence honesty** — green counts standing on prose; suites claimed but not
  digest-recorded; a scaffolder artifact set polluting the reviewed increment.
- **Overclaim retraction** — "structurally unable to alter" and OS-sandbox
  language corrected everywhere after review caught it.
- **State-narrative destruction** (DRIFT-198-I003-009) — a sync helper replaced
  the whole Execution Summary on every task-progress write; fixed with a
  marker-bounded managed block.

No new drift is introduced by this closure. Two governance gaps surfaced *by*
the closure are recorded as DRIFT-198-I009-020 and DRIFT-198-I009-021 against
the current iteration rather than back-dated into 003.

## Improvement Actions

| Action | Owner | Status |
| --- | --- | --- |
| Close an iteration at the point execution stops, recording the residual as terminal `deferred` with its vehicle. | Crew process | Adopted at this closure. |
| Treat "this task needs a reconciliation document" as a planning smell and split it before the before-implement gate. | Planner | Open. |
| Check for open historical iterations before changing a governance config they are validated against. | Crew process | Adopted; this closure was the corrective instance. |
| Give the verdict record an explicit subject so a retroactive closeout is capturable authorization. | Specrew product backlog | Open — DRIFT-198-I009-020. |
| Let closure artifacts express "verified by a named successor iteration". | Specrew product backlog | Open — DRIFT-198-I009-021. |

## Process Notes

- This retro is written retroactively, thirteen days after execution stopped.
  It reads the durable record rather than reconstructing sentiment, and it says
  so at the top; a retro that implies in-the-moment reflection it did not have
  is worth less than none.
- The `## What Was Hard` section serves the conventional "what didn't go well"
  role for this iteration.
- Two governance-mechanism gaps found while performing this closure are recorded
  against the current iteration (DRIFT-198-I009-020, DRIFT-198-I009-021), not
  back-dated into 003. Iteration 003's own drift log is closed history.

## Signals for the next iteration

- Close each iteration at the point execution stops, even when the residual
  moves elsewhere; record the move as terminal `deferred` with its vehicle.
- Treat "this task needs a reconciliation document" as a planning smell.
- Before changing a governance config that historical artifacts are validated
  against, check which iterations are still open.

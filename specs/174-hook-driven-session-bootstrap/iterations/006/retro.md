# Retrospective: Iteration 006

**Schema**: v1
**Date**: 2026-06-10

Retroactive closure artifact (reconstructed 2026-06-11 from the iteration's plan.md closure note, drift-log,
and the iter-005 precedent — iteration 006 closed honestly-qualified on 2026-06-10 without a committed
retro.md).

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T035a | 1 | 1 | 0 |
| T035 | 4 | 4 | 0 |
| T036 | 3 | 3 | 0 |
| T037 | 2 | 2 | 0 |
| T038 | 4 | 4 | 0 |
| T039 | 1 | 1 | 0 |
| T040 | 2 | 2 | 0 |
| T041 | 2 | 2 | 0 |
| T042 | 1 | 1 | 0 |

**Average variance**: +/- 0 (20/20 SP at cap). **Honest caveat (carried from iter-5): 0 SP variance does NOT
mean clean** — the iteration's PARITY GOAL was disproven at review. Effort variance is blind to a
correctness-of-claims miss; read 0-variance as a velocity signal only.

## Drift Summary

- Total drift events: 2 (logged in drift-log.md). **D-010** (the specrew-start regression suite did not
  characterize the contract → T035a split + SP re-baseline 19→20, human pre-authorized at before-implement)
  RESOLVED in-iteration. **D-011** (hook ↔ `specrew start` read-and-follow PARITY disproven at review-signoff;
  T038's deployed floor proved file-existence, not the live read-and-follow experience — the build != live
  recurrence) DEFERRED to iteration 007. Resolution rate 50% (1/2) — honestly, because D-011's parity is
  iteration 007's deliverable, not a same-iteration fix.

## What Went Well

- **The lead-with-characterization instruction caught a real pledge before the extraction (D-010).** Forcing
  the "does the suite actually pin the contract?" check BEFORE moving `Get-StartPrompt` revealed the
  specrew-start suite did NOT characterize the contract content. T035a built the genuine net first, and the
  SP re-baseline (19→20) was honest rather than silently absorbed.
- **The kept deliverable is real and safe.** The `launch-contract.ps1` extraction (T035) is byte-identical,
  validator-green, and guarded by T035a — a clean, behavior-preserving refactor that iteration 007 builds on.
- **The carries landed.** evidence_locus (T040 — the review mechanism that refuses "delivered-live" on
  dev-tree-only evidence), the dormant-SessionEnd cleanup (T041), and the honesty-guarded docs (T042) all
  shipped, reducing iter-007's load.
- **The maintainer side-by-side caught the parity overclaim before it shipped as "done".** The send-back is a
  success of the review discipline, not a failure of it.

## What Didn't Go Well

- **HEADLINE — the build != live lesson recurred INSIDE the floor built to kill it (D-011).** Iteration 006
  existed to end the dev-tree-only "works" claim with a DEPLOYED live-wiring floor (T038). That floor ran
  green — but it asserted the contract file + the correct provider copy exist ON DISK, NOT that the agent
  reads `last-start-prompt.md` and follows it. A maintainer side-by-side disproved parity: the hook writes a
  THIN contract (skips coordinator-prompt-surgery) and the agent does not read-and-follow. The same
  `build != live` class as iter-5 D-009, one level up.
- **A green deployed test is still not a behavior test.** "Deployed layout" fixed the component-resolution
  blind spot from iter-5, but file-existence-on-disk is not the read-and-follow EXPERIENCE. The floor must
  assert the live behavior, not the artifact's presence.
- **The iteration could not honestly close as a parity success.** It delivered code (all tasks done) but not
  its goal. The honest close keeps T035 and defers parity — a partial, not a win.

## Improvement Actions

1. **Owner: Implementer | Phase: iter-7 test design | Type: methodology (the durable fix).** A live-wiring
   floor must assert the read-and-follow EXPERIENCE (the agent receives the full contract AND acts on it),
   not the presence of the contract file or the provider copy on disk. File-existence is plumbing; parity is
   behavior. Iteration 007 carries a REAL read-and-follow floor.
2. **Owner: Implementer | Phase: iter-7 | Type: process.** Bring the hook to parity by INCLUDING the
   coordinator-prompt-surgery step the launcher runs (the thin contract is the proximate cause); prove it
   against `specrew start`'s output, not a hand-rolled expectation.
3. **Owner: Reviewer | Phase: review-signoff | Type: review-mechanism (carried, now reinforced).** The
   evidence_locus mechanism (T040) must also distinguish `plumbing-present` from `behavior-observed` — a
   green deployed plumbing floor is NOT a behavior-delivered claim. The review refuses "drives / reaches the
   model" on plumbing-only evidence.
4. **Owner: Planner | Phase: iter-7 scope | Type: process.** The codex/copilot/cursor injection-reaches-model
   re-tests stay an explicit tracked slice (`f174-followup-multihost-injection-verification`), not a vague
   enumeration; iteration 007 first lands Claude read-and-follow parity, then the multi-host slice follows.

## Calibration Suggestion

- Keep the 18-20 SP band; iteration 006 ran 20/20 at 0 variance (sixth straight at 0 variance).
- **Honest caveat (reinforced from iter-5):** the 0-variance streak is a velocity signal, NOT a quality
  signal — it was blind to the parity disproof. Quality is carried by the read-and-follow floor (action 1),
  not the variance number.

## Signals For Next Step (iteration 007, NOT feature-closeout)

- **Iteration 007 charter:** deliver the deferred hook ↔ `specrew start` read-and-follow PARITY
  (FR-022/FR-023/FR-024) with a REAL read-and-follow floor — the hook writes the FULL contract (coordinator
  surgery included) and the agent demonstrably reads-and-follows it. F-174 stays OPEN until parity is proven.
- **Then:** the multi-host injection-reaches-model slice, then feature-closeout.

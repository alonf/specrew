# Retrospective: Iteration 008

**Schema**: v1
**Date**: 2026-06-11

Retroactive closure artifact (reconstructed 2026-06-11 from the iteration's plan.md + state.md closure
narrative and the iter-005/006 precedent — iteration 008 closed at the boundary commit `7fe04228` without a
committed retro.md).

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T048 | 3 | 3 | 0 |
| T049 | 5 | 5 | 0 |
| T050 | 6 | 6 | 0 |
| T051 | 3 | 3 | 0 |

**Average variance**: +/- 0 (17/20 SP). **Honest caveat (carried from iter-5/6): 0 SP variance does NOT mean
clean** — T050's effort was on-estimate, but it surfaced a hollow-handover finding deferred to iteration 009.
Variance measures estimate accuracy; it is blind to a correctness-in-practice gap.

## Drift Summary

- Total drift events: 3 (logged in drift-log.md). **D-012** (the rolling handover is HOLLOW in practice — the
  cross-host dogfood finding) DEFERRED to iteration 009. **D-013** (deployable-mirror skew — the handover
  never wrote at Stop in a deployed layout) and **D-014** (anchorless-workshop handover never surfaced) both
  RESOLVED in-iteration. Resolution rate 67% (2/3) — honestly, because D-012's architectural fix is
  iteration 009's deliverable, not a same-iteration fix.

## What Went Well

- **The multi-host dogfood earned its keep — again.** Validating across claude / codex / copilot exit-resume
  PROVED the re-anchor works AND surfaced the hollow-handover gap before it shipped silently. The live check,
  not the mechanical tests, found the real problem (the `build != live` discipline working).
- **Two real bugs found + fixed in-iteration (D-013, D-014).** The deployable-mirror skew (why the handover
  never wrote at Stop deployed) and the anchorless-workshop no-surface bug were both root-caused and fixed
  with regression guards (ProviderMirrorParity; the branch-feature resolver + its tests).
- **The handover-first resolution avoided a central-state write** (advisor-corrected from the prior
  early-anchor design) — a smaller, safer change that fixed the anchorless case without touching resume
  classification.
- **The three maintainer asks all shipped** (T048 docs, T049 intake-at-init, T051 continuity docs) on the
  green baseline, keeping the feature moving toward closeout.

## What Didn't Go Well

- **HEADLINE — the rolling handover was HOLLOW in practice despite passing its mechanical tests.** The
  machinery (write-at-Stop, material gate, the floor/body split) was green, but the BODY was empty in real
  sessions because authoring was agent-/gate-dependent and the Stop hook is transcript-blind. The most
  valuable moment — mid-implement, uncommitted — was the hollowest. The same `build != live` class as iter-3
  (D-002), iter-5 (D-009), and iter-6 (D-011): a green test is not a live-behavior guarantee.
- **The hollow handover was only caught by the manual cross-host dogfood**, not by any automated floor — the
  recurring lesson that runtime-behavior claims need a live check, not just a passing suite.
- **The iteration could not close as a clean win** — it delivered its tasks but its central artifact (the
  rolling handover) did not work in practice, so the close is honestly-qualified with the fix carried to
  iteration 009.

## Improvement Actions

1. **Owner: Implementer | Phase: iter-9 design | Type: architecture (the durable fix).** Make the Stop hook
   the PRIMARY delta-author: capture the git/fs session delta into the mechanical body sections on every
   material stop (never hollow, host-universal, no transcript or agent cooperation). This is iteration 009.
2. **Owner: Implementer | Phase: iter-9 test design | Type: methodology.** A handover floor must assert the
   BODY has REAL captured content (delta-derived), not just that a file was written — the iter-5/6 lesson
   applied to the handover body, not just its plumbing.
3. **Owner: Reviewer | Phase: review-signoff | Type: process.** A "surfaces / persists / restores" claim for
   the handover requires a manual or delta-asserting check that the BODY is non-hollow, not a file-presence
   floor. Fold into the evidence_locus / behavior-observed discipline (the iter-6 T040 carry).
4. **Owner: Implementer | Phase: iter-9 | Type: quality nit.** `Get-SpecrewSessionDelta` should
   exclude/deprioritize the Specrew-managed dirs so the user's real source is not pushed past the delta file
   cap (surfaced in the iter-9 dogfood).

## Calibration Suggestion

- Keep the 17-20 SP band; iteration 008 ran 17/20 at 0 variance.
- **Honest caveat (reinforced):** the 0-variance streak is a velocity signal, NOT a quality signal — it was
  blind to the hollow-handover finding. Quality is carried by the iteration-009 delta-author fix + a
  non-hollow body floor, not the variance number.

## Signals For Next Step (iteration 009, NOT feature-closeout)

- **Iteration 009 charter:** the Stop hook becomes the PRIMARY rolling-handover author — capture the git/fs
  delta into the mechanical sections every material stop (never hollow), accumulate across the boundary
  window, stamp the real host. F-174 stays OPEN until the handover is non-hollow in practice.
- **Then:** the on-host re-dogfood confirms the handover is rich in practice, then review-signoff + retro +
  feature-closeout.

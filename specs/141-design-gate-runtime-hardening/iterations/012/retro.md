# Retrospective: Iteration 012

**Schema**: v1
**Date**: 2026-06-06

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 (catalog-at-open) | 3 | ~4 | +1 (built then reverted — the empirical disposition) |
| T002 (open-question-first + pacing) | 2 | ~4 | +2 (pacing added round 1, then strengthened to mandatory cross-host round 2) |
| T003 (tests) | 2 | 2 | 0 |
| T004 (cross-host dogfood) | 1 | 1 | 0 |

The +3 is dogfood-driven iteration (the pacing refinements + the catalog revert), not estimation error — the dogfood found a refinement and a wrong hypothesis, which is its job.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | The mechanism was advisor-decided. |
| Implementation | 5 | ~8 | +3 | The catalog build+revert + the two pacing rounds (add, then strengthen). |
| Review | 3 | 3 | 0 | The dogfood (T004) cross-host + the tests. |

## Drift Summary

- 2 drift events, both **fixed-now**: (1) catalog-at-open built then empirically reverted by the cross-host dogfood (redundant on prose hosts, skims on Claude — a before-a-menu render); (2) Copilot deferred writing the workshop records until the SC-021 gate forced it (the deterministic floor caught it). See [drift-log.md](drift-log.md). No specification drift — the catalog revert is recorded in FR-041 (the governing model), not silent divergence.

## What Went Well

- **The convergence won — cross-host.** open-question-first + mandatory pacing hold on BOTH Claude and Copilot; the component map rendered in-band on Claude (the advisor's "real test"). Maintainer verdict: *"the best workshop"* on both hosts. The six-edit per-lens-render grind is done.
- **The dogfood reverted a wrong hypothesis cleanly.** Catalog-at-open looked good in intent but the cross-host run showed it helped no host. The advisor's *drop > host-conditional* avoided a fragile agent-self-detects-host branch.
- **The governing model crystallized** (the durable lesson): content whose next move is open discussion renders reliably on Claude; content that must render right before a structured menu skims (the `AskUserQuestion` tool-gravity) → a `PreToolUse` hook or accept-as-minor, never another instruction.

## What Didn't Go Well (the lessons)

- **The catalog-at-open was the wrong lever — and it took a CROSS-HOST dogfood to see it.** On Claude alone (round 1) it just skimmed (looked like the agenda-minor); only the Copilot run exposed the redundancy (nine lenses rendered twice). Lesson: **a cross-host dogfood reveals host-divergent harm that a single-host run hides.**
- **Conduct is host-variable, and an advisor inference is not data.** The advisor's "pacing is a no-op on Copilot" was drawn from the pre-pacing Copilot run; the maintainer's primary evidence (Copilot's per-lens wall — five subjects in one open question) overrode it → pacing is universal, not Claude-only. Lesson: weight the maintainer's primary evidence over an inference from an earlier run.
- **Copilot deferred writing the workshop records until the specify gate forced it** (Claude wrote them as it went). The SC-021 floor caught it (the deterministic gate did its job), so the outcome was correct — but write-as-you-go is the better conduct. Minor.

## Improvement Actions

1. Owner: Implementer | Phase: dogfood | Type: process | Expected effect: **a behavioral conduct change is CROSS-HOST-dogfooded before it is accepted** — a single-host run hides host-divergent harm (the catalog looked minor on Claude, was redundant on Copilot).
2. Owner: Spec Steward | Phase: implement | Type: process | Expected effect: **the governing model is the decision rule going forward** — classify any new confirm-point render as open-discussion (renders) vs before-a-menu (skims → hook or accept); do not re-attempt conduct on a before-a-menu render (the anti-edit-#9 rule).
3. Owner: maintainer | Phase: future | Type: optional | Expected effect: if reliable render-before-a-menu on Claude is ever wanted (the agenda, the design-analysis-stop map), it is a `PreToolUse` hook as one deliberate iteration — not another instruction.

## Calibration Suggestion

- The +3 actual is dogfood-driven refinement + a reverted hypothesis, not estimation error. No estimate-model change; the dogfood is doing its job.

## Notes

- Iteration 12 closes ACCEPTED on the cross-host behavioral acceptance (SC-028 + SC-027 met). The agenda skim is the maintainer-accepted minor (the governing-model edge). **Feature 141 (design-gate runtime hardening) is ready for feature-closeout.**

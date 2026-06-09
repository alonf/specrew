# Retrospective: Iteration 004

**Schema**: v1
**Date**: 2026-06-09

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T023 | 2 | 2 | 0 |
| T024 | 1 | 1 | 0 |
| T025 | 2 | 2 | 0 |
| T026 | 2 | 2 | 0 |
| T027 | 2 | 2 | 0 |
| T028 | 1 | 1 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done | done | 0 | Design pass co-settled with the human before planning. |
| Discovery/Spikes | 0 | 0 | 0 | Per-host Stop events research-confirmed (F-171 matrix). |
| Implementation | 10 | 10 | 0 | T023-T028; all exact. |
| Review | 2 | 2 | 0 | 145 review accepted first pass (one canonical-defer-entry fix at validate). |
| Rework | 1 | 0 | -1 | No send-back; the iter-3 retro floors pre-empted issues. |

## Drift Summary

- Total drift events: 0 (iteration 4 was a planned design pivot, co-settled up front - not a drift).

## What Went Well

- **The human's design insight turned a limitation into a better design.** Discovering only Claude has
  `SessionEnd` led to the universal Stop-event rolling handover - portable across all 4 hosts AND
  crash-safe (closes Proposal 130's own "no crash guarantee").
- **The iteration-3 retro actions were applied PROACTIVELY and worked.** The on-disk deployed-config
  floor (`DeployedHostConfig.Tests`) was written from the start - and here it guards a REMOVAL
  (SessionEnd absent on disk), the build != live trap in reverse. Validator EXIT 0 before every
  boundary (action 4) meant zero state-truth send-backs this iteration.
- **Clean pivot:** the provider row + deployer + manager-read all swapped to Stop with the SessionEnd
  model left dormant (honest deferral); 18 suites + deploy-integration green; live cross-host Stop
  smoke green on 4 hosts.

## What Didn't Go Well

- **The live-smoke harness hung** the first time because the dispatcher reads the hook event from
  STDIN when `-EventJson` is omitted - I forgot `-EventJson` (the iter-3 smoke had it). A test-harness
  gotcha, not a product bug; cost a stuck background task + a retry.
- **A design-record accuracy slip:** the phrase "SessionEndHandoverManager write-logic is REUSED by the
  Stop provider" was inaccurate (the provider sources HandoverStore + ClassificationEngine directly).
  The human caught it at review-signoff. Corrective captured in the cleanup follow-up.

## Improvement Actions

1. Owner: all roles | Phase: any dispatcher smoke | Type: process | Dispatcher live smokes MUST pass
   `-EventJson '<payload>'` - the dispatcher blocks on STDIN without it (hang). Document this as the
   smoke-invocation pattern so it is not rediscovered.
2. Owner: Planner/Implementer | Phase: design-record | Type: process | Do not write "X is reused by Y"
   in a design record unless Y actually sources X - verify the dependency before asserting reuse.
3. Owner: Implementer | Phase: cleanup slice | Type: cleanup | Execute
   `f174-followup-remove-dormant-sessionend-code` (delete the dormant SessionEnd code) AND correct the
   inaccurate "REUSED" phrase at the same time.

## Calibration Suggestion

- Keep the 10-18 SP band; iteration 4 was 10 SP at 0 variance (four iterations now at 0 variance).

## Signals For Next Step (feature-closeout)

- F-174 is functionally complete across iterations 1-4. Feature-closeout ships 1-4 together via
  push/PR/merge but **NO beta-publish** (directive `f174-closeout-no-beta-local-install`): the
  maintainer validates by installing the module from this local dev folder; the PSGallery publish is
  deferred until after that local validation.

## Notes

- Dogfood findings remain captured for the closeout ledger (`f174-dogfood-dev-tree-hook-validation`,
  `f174-dogfood-handoff-block-missing`).

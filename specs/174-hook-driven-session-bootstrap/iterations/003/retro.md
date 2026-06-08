# Retrospective: Iteration 003

**Schema**: v1
**Date**: 2026-06-09

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T021 | 3 | 3 | 0 |
| T022 | 3 | 3 | 0 |
| T016 | 2 | 2 | 0 |
| T017 | 2 | 2 | 0 |
| T014 | 2 | 2 | 0 |
| T015 | 2 | 2 | 0 |
| T018 | 2 | 2 | 0 |
| T019 | 1 | 1 | 0 |
| T020 | 1 | 1 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done | done | 0 | iter-003 plan + hardening-gate approved. |
| Discovery/Spikes | 0 | 0 | 0 | Live-wiring sequenced first surfaced the dispatch/deploy difficulties early, as intended. |
| Implementation | 18 | 18 | 0 | T021/T022 (live-wiring) + T014-T020; all exact. |
| Review | 2 | 3 | +1 | One send-back: D-002 "proven LIVE" overstated; the human caught it. |
| Rework | 2 | 1 | -1 | The rework was bounded (deploy-to-worktree + on-disk closure test + honest qualification). |

## Drift Summary

- Total drift events: 3
- Resolved in-iteration: 2 (D-003 dedupe-vs-sync; D-004 SessionEnd-not-live + overlay)
- Sequenced to a future iteration: 1 (D-005 handover-trigger pivot -> iteration 004)
- Escalated to human decision: 1 (the D-005 design pivot + the review-signoff send-back)

## What Went Well

- **Sequencing live-wiring first paid off exactly as the human directed.** Closing D-001/D-002 before
  the small tasks surfaced the hard problems early - the dedupe-vs-sync bug (D-003) and the
  SessionEnd dispatch/deploy questions - instead of at the end.
- **Real-fixture proofs:** cross-host SessionStart smoke (4 hosts), SessionEnd round-trip, no-`-A`
  scoped commit, exactly-once dedupe - all reproduced, not asserted on faith.
- **The host-capability research turned a limitation into a better design:** discovering only Claude
  has `SessionEnd` led the human to the Stop-event rolling handover (portable + crash-safe).

## What Didn't Go Well

- **The review overstated D-002 as "proven LIVE" while the deployed host config carried no SessionEnd.**
  The "build+test != live" check (iter-002 action) DID catch that the provider wasn't hook-registered -
  but the FIX (a scratch-project deployer test + a dispatcher-direct smoke) then itself BYPASSED the
  host->dispatcher link, and the review claimed "live" anyway. The human caught the second overclaim at
  review-signoff. Lesson: "build != live" as a mindset is necessary but not sufficient; it needs a
  STRUCTURAL floor (below).
- A second inflated number ("19 suites" vs 17) slipped into the same review - corrected; a review fixing
  an overclaim must self-check every count.

## Improvement Actions

1. Owner: Reviewer | Phase: review-signoff | Type: process (RECURRING PATTERN, not just this instance) |
   **A host-hook / host-config deliverable's live-wiring floor MUST include an on-disk deployed-config
   assertion** (the `DeployedHostConfig.Tests` pattern: read the actual deployed config on disk and
   assert the registration). Deployer-integration tests AND dispatcher-round-trip smokes can BOTH pass
   while the host->dispatcher link is dead, because neither reads the real deployed config. Feed this to
   the Proposal-145 reviewer-family and the workshop-hardening items batched at feature-closeout.
2. Owner: Reviewer | Phase: review-signoff | Type: process | A review that corrects an overclaim must
   re-verify EVERY quantitative claim in the same pass (the "19 suites" miss) - count from the artifact,
   not from memory.
3. Owner: Planner | Phase: iteration 004 | Type: design | Open iteration 004 with a design pass for the
   Stop-event rolling handover (Stop-only trigger, in-place file, material-change update policy) -
   decision `f174-i004-stop-event-rolling-handover`.

## Calibration Suggestion

- Suggested capacity adjustment: keep the 18-20 SP ceiling; iteration 003 was 18 SP at 0 variance.
- Rationale: three iterations now at 0 estimate variance; the IDesign decomposition keeps per-task
  effort highly predictable even for the live-wiring tasks.

## Signals For Next Iteration (004 - Stop-event rolling handover)

- Implement the universal Stop-event handover (replaces SessionEnd-only): refresh ONE in-place handover
  file on each per-host Stop, only on material change; portable + crash-safe. Carry over the iter-003
  SessionEnd provider logic + round-trip; change the trigger + file model. Apply the new live-wiring
  floor (improvement action 1) from the start: an on-disk deployed-config assertion for each host's
  Stop hook.

## Notes

- **Dogfood finding (standing, non-blocking):** the validator reports `handoff-block-missing` on every
  F-174 boundary commit - the hand-driven (non-Squad) lifecycle never emits SPECREW HANDOFF blocks.
  Captured for the feature-closeout dogfood ledger (`f174-dogfood-handoff-block-missing`).
- **Dogfood finding:** the dev-tree host-hook validation trap (`f174-dogfood-dev-tree-hook-validation`)
  - host-hook changes must be validated from the dev tree against the on-disk config, never via the
  installed beta's stale deployer.

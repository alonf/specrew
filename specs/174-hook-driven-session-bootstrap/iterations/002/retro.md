# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-06-08

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T008 | 2 | 2 | 0 |
| T009 | 2 | 2 | 0 |
| T010 | 1 | 1 | 0 |
| T011 | 2 | 2 | 0 |
| T012 | 2 | 2 | 0 |
| T013 | 2 | 2 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done | done | 0 | iter-002 plan + hardening-gate approved (after the closeout send-back fix). |
| Discovery/Spikes | 0 | 0 | 0 | Proposal 130 schema already specified; just read + composed. |
| Implementation | 11 | 11 | 0 | All exact; built on the iteration-001 IDesign seams. |
| Review | 2 | 1 | -1 | 145 review passed the validator on the FIRST full pass (iter-001 lessons applied). |
| Rework | 2 | 0 | -2 | No needs-work loops; PSScriptAnalyzer clean from the start. |

## Drift Summary

- Total drift events: 1
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 1 (D-002 SessionEnd hook registration)
- Escalated to human decision: 0

## What Went Well

- **The iteration-001 review lessons transferred.** PSScriptAnalyzer was clean from the start
  (no automatic-variable shadow, no em-dash/BOM, no ShouldProcess trap), and the 145 review
  **passed the validator on the first full pass** - the defer-entry-under-dated-heading and
  hardening-gate-enum gotchas were pre-empted, not rediscovered.
- **The locked Proposal-130 decision worked.** HandoverStore composed 130's schema exactly
  (schema v1 + 6 sections + index.yml + path + source-discrimination), with a code cross-reference;
  no "minimal contract" was invented.
- **Real-fixture proofs landed cleanly:** the opt-in scoped commit is proven to never `git add -A`
  (decoy-file test), and the launcher<->hook dedupe is proven live through the real provider.

## What Didn't Go Well

- **Second live-wiring deferral.** Like iteration-001's D-001 (downstream deploy), iteration 002
  built + tested SessionEndHandoverManager but did not register it to fire on a SessionEnd hook
  (the F-171 dispatcher does not dispatch SessionEnd) - **drift D-002**. A pattern is forming:
  components are built + unit-tested ahead of their hook registration, so "done" at the component
  level is not yet "live on a real session event."
- The closeout send-back (iteration-001 state-truth) interrupted the iteration-002 before-implement
  gate - a reminder that closeout finalization must be complete before the next iteration opens.

## Improvement Actions

1. Owner: Planner | Phase: iteration 003 planning | Type: process | Iteration 003 MUST close both
   live-wiring deferrals (D-001 downstream deploy + D-002 SessionEnd registration) - the live-fire
   wiring is where the user value actually lands; do not let a third deferral accumulate.
2. Owner: Reviewer | Phase: review-signoff | Type: process | Treat "component built + unit-tested"
   as NOT done until it is hook-registered and proven on a real (or dispatcher-smoke) event - make
   the live-wiring check an explicit review-signoff line item.
3. Owner: Planner | Phase: closeout | Type: process | Finalize iteration state-truth (state.md +
   plan.md status + `.pending` cleanup) atomically at iteration-closeout before opening the next
   iteration (the Proposal-142-class gap recorded in iteration 001).

## Calibration Suggestion

- Suggested capacity adjustment: keep the 12 SP/iteration baseline (iteration 002 was 11 SP, exact).
- Rationale: two iterations now with 0 estimate variance; the IDesign decomposition makes per-task
  effort highly predictable.

## Signals For Next Iteration (003 - the final one)

- Iteration 003 is the "make it live + multi-host" iteration: close D-001 (downstream extension-tree
  deploy) + D-002 (SessionEnd hook registration), add per-host normalization for
  Codex/Copilot/Cursor (FR-005) + per-host empirical verification, the HookJournalAccessor +
  per-path journal-assertion tests (SC-007), B1/B3 regression + the FR-012 negative test, and docs
  (FR-008). After 003 closes, only feature-closeout remains.

## Notes

- Real lessons recorded; no TBD placeholders remain.

# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-06-16
**Overall Verdict**: retro-ready, pending human verdict

## Estimation Accuracy

The task table records the human-approved expanded scope at 24/20 SP. That is the
minimum measured actual. The effective actual was higher because the iteration
absorbed an unplanned review/governance tail: the FR-007 split-guard stop,
Option A scope rebasing, T011 insertion, durability repair, review-packet
rebuild, and T010 issue-linkage tightening.

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 4 | 4 | 0 |
| T002 | 2 | 2 | 0 |
| T003 | 3 | 3 | 0 |
| T004 | 4 | 4 | 0 |
| T005 | 2 | 2 | 0 |
| T006 | 4 | 4 | 0 |
| T011 | 4 | 4 | 0 |
| T007 | 0.25 | 0.25 | 0 |
| T008 | 0.25 | 0.25 | 0 |
| T009 | 0.25 | 0.25 | 0 |
| T010 | 0.25 | 0.25 | 0 |
| Review/governance tail | 0 | ~6 | +6 |
| **Total** | **24** | **~30** | **~+6** |

**Average variance**: task rows held after the human-approved rebaseline, but the
iteration still cost roughly 30 SP effective effort because governance/review
repair was not represented as capacity.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 2 | ~3 | +1 | Scope summary, traceability, concurrency rationale, capacity, and design-analysis artifacts needed multiple reconciliation passes before tasks were self-consistent. |
| Discovery/Spikes | 1 | ~1.5 | +0.5 | Antigravity hook documentation, local `agy` availability, and event/output verification were cheap but still non-zero. |
| Implementation | 17 | ~19 | +2 | The accepted Option A host-model refactor made T011 explicit and migrated five hook-capable hosts through `RefocusHookBindings`. |
| Review | 3 | ~5 | +2 | Proposal 145 review, external-review send-back, real-host evidence, issue-linkage tightening, and reviewer artifact durability all landed here. |
| Rework | 1 | ~1.5 | +0.5 | T010 wording, lifecycle-state truth, and validation reruns were bounded but real. |

## Drift Summary

- Total drift events: 4.
- Resolved via human decision: 3 resolved events: DR-001 before-implement gate slip, DR-003 release-line drift, and DR-004 FR-007 split-guard scope expansion.
- Open non-blocking follow-up: DR-002 boundary-state and execution-state conflation.
- Deferred: 0 within F-183; DR-002 is explicitly outside F-183 capacity.

## What Went Well

- The cap/fallback/session-id runtime fixes landed with focused Pester coverage and corrected the exact stability failures that motivated the bundle.
- The delivery-cap test was moved off ambient developer state and into a synthetic shipped SessionStart fixture, which made the quality signal trustworthy.
- The FR-007 split guard eventually worked: the generalized host refactor was stopped, named, accepted as Option A, and re-baselined instead of silently becoming hidden scope.
- Antigravity support stayed bounded to verified `.agents/hooks.json` behavior, with real `PreInvocation` and `Stop` evidence recorded and no parity overclaim.
- The final review-signoff approval correctly tightened T010: #2446, #1627, and #1761 are linkage-pending at feature closeout, not falsely closed by the review packet.

## What Didn't Go Well

- The before-implement human stop was skipped once. T001 was good work, but the process defect was real and had to be logged as DR-001.
- The host-model refactor crossed the original T006 slice before the split decision was surfaced. The eventual Option A repair was correct, but the stop should have happened earlier.
- Lifecycle/runtime state was noisy: the committed iteration artifacts reached review-signoff, while `.specrew/start-context.json` lagged behind until the retro entry preflight re-recorded the human approval.
- Review durability had to be repaired after the first review pass; the quality-profile-foundation check, scope classification, and reviewer packet had to be made durable before approval.
- The actual cost was larger than the 24 SP rebaseline because review/governance repair was not given its own capacity line.

## Improvement Actions

1. Owner: Planner | Phase: planning | Type: capacity | When a split guard is triggered and accepted into scope, add both the new task and the review/governance repair tail to capacity instead of only adding implementation SP.
2. Owner: Implementer | Phase: implement | Type: process | Stop immediately at every human gate, even when the next engineering step is obvious; one human approval advances one boundary.
3. Owner: Reviewer | Phase: review | Type: evidence | Keep Proposal 145 review substantive against scope, traceability, and implementation behavior; do not reduce it to durability-only checks.
4. Owner: Implementer | Phase: release validation | Type: test | Before publishing `0.38.0-beta1`, verify the legacy/existing-config upgrade path, specifically `MigrateLegacyTopLevelEventMap`, so shipped host configs upgrade without clobbering user entries.
5. Owner: Reviewer | Phase: release validation | Type: evidence | Add a non-Antigravity SessionStart real-host run for SC-008 and make T009 evidence reproducible from the repo, or mark machine-local evidence explicitly.
6. Owner: Spec Steward | Phase: closeout | Type: linkage | Bind #2446, #1627, and #1761 at feature closeout to `b79b59d8` or to the final merge/squash commit.
7. Owner: Maintainer | Phase: follow-up | Type: governance | Keep DR-002 as a separate governance repair; do not hide it inside F-183 implementation capacity.
8. Owner: Maintainer | Phase: closeout | Type: hygiene | Resolve the unrelated line-ending churn outside F-183 before final closeout.

## Calibration Suggestion

- Suggested capacity adjustment: keep the nominal 20 SP cap, but treat stability/governance bundles with host verification as high-risk and reserve a visible 25-35% review/governance tail.
- Rationale: the accepted implementation scope was 24 SP, but effective actuals were about 30 SP once split-guard adjudication, real-host proof, review repair, and lifecycle-state reconciliation were counted.

## Signals for Closeout and Release

- T010 is pass with linkage pending at feature closeout, not a clean issue-closure pass.
- T008 is a release-target decision only; version-bearing release surfaces still need the `0.38.0-beta1` bump before publishing.
- T009 Antigravity evidence is valid for bounded behavior but remains machine-local unless reproduced or explicitly labelled that way.
- SC-008 still needs a non-Antigravity SessionStart real-host run before release validation claims multi-host coverage.

## Notes

- This artifact was scaffolded from `plan.md`, `state.md`, `drift-log.md`, and `review.md`; placeholders were replaced with iteration evidence.
- Retro stops here for human verdict. The next required verdict is `approved for retro` before iteration-closeout.

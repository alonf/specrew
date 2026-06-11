# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-06-12

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T201 | 2 | 2 | 0 |
| T202 | 1 | 1 | 0 |
| T203 | 1.5 | 1.5 | 0 |
| T204 | 1.5 | 1.5 | 0 |
| T205 | 2 | 2 | 0 |
| T206 | 1.5 | 1.5 | 0 |
| T207 | 0.5 | 0.5 | 0 |
| T208 | 1.5 | 1.5 | 0 |
| T209 | 1 | 1 | 0 |
| T210 | 1.5 | 1.5 | 0 |
| T211 | 1.5 | 1.5 | 0 |
| T212 | 1.5 | 1.5 | 0 |

**Average variance**: ~0 (on-target). SP actuals are qualitative (no per-task time-tracking). Consumed
17 / planned 17 / cap 20. The review-caught rework round (F1–F4) consumed the small review/rework
buffer, not new implementation SP.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Implementation | ~14 SP | ~14 SP | on-track | High reuse of the Iter-1 contract + generic fallback; the deployed-catalog location (carried Iter-1 watch-item) resolved without rework. |
| Review | ~2 SP | ~2 SP | +rework | The Proposal-145 structured review caught four findings (F1–F4); one was a CI-blocking lint + a false "markdownlint clean" claim. |
| Rework | small | small | on-track | F1–F4 fixed in one bounded round (a10ecf22); re-review verdict accepted; an over-claim in the accepted review (mechanical-checks) caught + fixed before closeout. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

(The four review-caught findings F1–F4 were review-phase quality/truthfulness items, not
specification drift; they are recorded in review.md and cross-referenced from drift-log.md.)

## What Went Well

- The runtime layer built cleanly on Iteration 1's `ProviderAdapter` contract + generic fallback; the
  architecture held with no re-design.
- The **forge-neutral-core invariant was test-enforced, not just intended**: the T015 grep test
  (the core invokes no `gh`/API) actively caught a wrong fix — it would have rejected the F1 "delegate
  to the github adapter" remedy, which is exactly why that remedy was discarded for the honest reword.
- **Honest phasing held end-to-end**: `apply_protection` denial-path, fail-open degradation, and the
  describe-only dogfood are all behaviourally proven (T211/T212), and the live GitHub apply + SC-014
  live posture-match are honestly labelled deferred to dogfood/beta rather than over-claimed.
- The carried Iter-1 watch-item (deployed-catalog location) was resolved this iteration so the deployed
  validator reads `work-kinds.yml`.

## What Didn't Go Well

- **The load-bearing miss: the iteration shipped two committed MD047 lint errors that fail the exact CI
  Lint command, while state.md/plan asserted "markdownlint clean" (F4).** One error was in this
  iteration's own drift-log. Root cause: the "clean" claim was carried from an earlier run instead of
  re-derived from the exact CI command at the moment of writing.
- **F1: stale-by-time comments.** Iteration 1's `provider-adapter.ps1` kept "lands in iteration 2"
  comments on its github contract-dispatch; Iteration 2 added the real github path in a parallel
  orchestrator but never reconciled the old comments — leaving stale-by-time text + a dual path.
- **The first-pass review proposed a wrong remedy for F1** ("delegate the contract op to github"),
  which would have broken the FR-014 forge-neutral-core invariant. It was caught only because the
  rework verified the fix against the T015 test — not because the review self-checked the remedy.
- **The accepted re-review initially over-claimed that mechanical-checks was "re-run after the
  rework"** when it had not been; the advisor caught it. A review about not over-claiming carried a
  small over-claim of its own.
- **Tooling friction:** `scaffold-reviewer-artifacts.ps1` generates lint-dirty placeholder supplements
  (MD009/MD032/MD047) and re-renders an unrelated Iter-1 artifact (`current-architecture.md`) — noisy
  when the substantive review lives in a single `review.md`.

## Improvement Actions

1. Owner: Reviewer | Phase: review prep | Type: reviewer-instruction (PROMOTE) | Any "markdownlint
   clean" / "lint clean" / gate-green claim recorded in state.md or review.md MUST be backed by a
   fresh run of the exact CI command in the same turn — never carried from an earlier run. (Prevents
   the F4 class.)
2. Owner: Reviewer | Phase: review authoring | Type: reviewer-instruction (PROMOTE) | When a review
   proposes a remedy, verify it against the invariants/tests it touches BEFORE recording it; a remedy
   that would break a known test (e.g. the FR-014 forge-neutral-core grep) is a finding against the
   review, not a fix. (Prevents the F1-delegate class.)
3. Owner: Reviewer | Phase: review evidence | Type: reviewer-instruction (PROMOTE) | Every "re-run
   after rework / replayed" claim in a review must correspond to a command actually executed in that
   turn; regenerate the artifact (e.g. mechanical-findings.json) so its timestamp proves the re-run.
4. Owner: Implementer | Phase: implement | Type: process | When an iteration adds a parallel path to an
   existing seam, reconcile the OLD path's comments/stubs in the same iteration so no "lands in
   iteration N" text survives past iteration N. (Prevents the F1 stale-by-time class.)
5. Owner: Implementer | Phase: tooling backlog | Type: implementation (DEFER) | File the
   `scaffold-reviewer-artifacts.ps1` lint-dirty-supplements + iter-1-artifact-re-render behaviour as a
   tooling-defect candidate (Proposal-037 / scaffolder backlog); not blocking, but it adds review noise.

## Calibration Suggestion

- Suggested capacity adjustment: keep the 20 SP iteration cap (Iter-2 consumed 17, under cap; on-target
  estimation).
- Rationale: zero estimation variance; the only extra effort was the bounded review/rework round, which
  fit the planned review + rework buffer. The feature total (~32+ SP across Iters 1–2, with Iter-3
  decouple remaining) is the signal to watch — re-confirm the Iter-3 scope (and the split-to-sibling
  escape hatch) at the next planning, since it may exceed the original ~16–24 SP rough estimate.

## Signals For Next Iteration (Iteration 3)

- Iteration 3 is the **forge-neutralization migration** (FR-019): decouple Specrew's
  downstream-*governing* surfaces from its own GitHub dev habits, driven by the Iter-1 coupling
  inventory → SC-008 (no over-claim sweep) + SC-013. If too large for one feature, exercise the
  split-to-sibling escape hatch (decided at planning).
- **T013b** (extension.yml version bump + deploy-time `.specify` coverage) remains carried to
  feature-closeout / release-deploy (drift-log D-001), where the version target is a release decision.
- Carried watch-item: add a contract test for the hand-rolled YAML reader as the schemas evolve.
- The three new reviewer-instruction candidates above (claims-need-fresh-evidence,
  verify-remedies-against-tests, re-run-claims-need-real-commands) are PROMOTE candidates for the
  durable review playbook (Proposal 145 / reviewer charter), pending the maintainer's triage.

## Notes

- Maintainer signed off the Iteration-2 review (accepted) and authorized retro + iteration-closeout,
  then stop.
- No push/PR/merge/tag/publish/release; no Iteration-3 work — stop after iteration-closeout per the
  maintainer's instruction.

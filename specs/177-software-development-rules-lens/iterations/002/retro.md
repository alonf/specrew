# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-06-10

## Estimation Accuracy

(Agent-driven session; "Actual" = scope completion, not wall-clock SP burndown. All nine tasks delivered
their scope; the variance this iteration was in the REVIEW phase, not implementation.)

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T010 | 3 | 3 | 0 |
| T011 | 0.5 | 0.5 | 0 |
| T012 | 2.5 | 2.5 | 0 |
| T013 | 1.5 | 1.5 | 0 |
| T014 | 1 | 1 | 0 |
| T015 | 1 | 1 | 0 |
| T016 | 1 | 1 | 0 |
| T017 | 1.5 | 1.5 | 0 |
| T018 | 1.5 | 1.5 | 0 |

**Average variance**: ~0 on implementation; the REVIEW phase ran over (two human send-backs) and the
implement phase absorbed one advisor-caught conduct correction + one dogfood-found defect.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | baseline | baseline | 0 | i2 plan inherited from i1-closeout; clean. |
| Discovery/Spikes | n/a | n/a | n/a | none. |
| Implementation | 13.5 SP | 13.5 SP | 0 | on scope; one advisor-caught conduct fix (writer-call -> hand-author) + one dogfood-found defect fix (single-element enforcement), both absorbed without scope change. |
| Review | light | OVER | + | the deployed-module dogfood (the gate) + two human send-backs (behavioral-SC honesty; .specify version parity). The real cost of the iteration. |
| Rework | 0 | review-only | + | no implementation rework; all rework was dogfood-found + review-artifact + release-parity reconciliation. |

## Drift Summary

- Total drift events: 2 -- D-002 (manifest capture writer-call -> hand-authored) RESOLVED/accepted; D-003
  (T017 behavioral SC-004/007/008) DEFERRED-WITH-GATE to the published beta (maintainer-approved, gates stable).
- Plus a review-signoff release-prep catch (the `.specify/.../extension.yml` mirror stale at 0.34.0) FIXED
  in a review-time follow-up (not formalized as a drift event; recorded in review.md Notes).
- Escalated: 0.

## What Went Well

- **The deployed-module dogfood did exactly its job**: on the FileList-only 0.35.0 staged module it caught a
  real defect that unit-green missed -- a single-element `enforcement: [review]` list projected to a JSON
  string, not an array (PowerShell unwraps a single-element array on function return). Root-caused, fixed
  (leading-comma idiom), and regression-tested. This is the strongest evidence yet that the deployed dogfood
  is the gate, not unit-green.
- **The advisor caught the load-bearing blind spot BEFORE the dogfood**: the original T012/T013 conduct told
  the agent to CALL a PowerShell writer the deployed agent cannot reach; switching to hand-author the manifest
  (the product-domain pattern) is what made the manifest path work on the deployed module at all.
- **The human review-signoff worked as designed -- twice**: it caught (1) the behavioral-SC over-claim
  (artifact inspection cannot establish "the agent was actually guided") and (2) the `.specify` extension.yml
  version-parity gap. Both were real; neither was caught by the validator's PASS. Evidence over form.
- **The i1 145-packet self-reference learning was applied**: the packet pins `reviewed_implementation_head`
  (da7a0129) so committing the packet does not stale its own metadata.

## What Didn't Go Well

- **The conduct blind spot (D-002) was mine, caught by the advisor, not by my own design**: I wrote the
  agent-calls-PS-writer conduct without testing reachability on the deployed layout. The deployed-module
  dogfood would have caught it, but later (and more expensively).
- **Unit-green missed the single-element-enforcement defect**: the unit round-trip only exercised a
  two-element list, so the single-element function-return unwrap slipped past -- exactly the gap the deployed
  dogfood exists to catch.
- **Two review-signoff send-backs**: the first review packet over-claimed the behavioral SCs as PASS (it
  needed to be deferred-with-gate); the release-prep `.specify` parity was incomplete (extension.yml mirror
  stale). Both were honest-accounting failures in the first packet.
- **The validator's review.md contract took several cycles to satisfy** (plan.md status vs review.md
  existence; Gap Ledger every-line-tokenized; Task Verdicts pass-only; deferred-gap requires a canonical
  `.squad/decisions.md` defer entry). Reading the validator source directly to fix all rules in one pass was
  faster than guess-and-revalidate (each validate run is ~8 min).

## Methodology learning

- **Deployed-module dogfood method (reusable)**: stage the FileList-only layout, resolve it by path
  (`SPECREW_MODULE_PATH`), discriminate with import-by-path module version (NOT `specrew version`, which reads
  the machine-global install), fresh `specrew init`, and validate the shipped bytes. It is the runtime gate.
- **Behavioral SCs cannot be self-graded**: SC-004/007/008 ("agent actually guided / human not walled /
  dependency stance honored") are behavioral; artifact inspection (and the author grading their own
  artifacts) is circular. The honest verdict is deferred-with-gate to the human-on-published-beta run; this
  project has under-surfacing precedent (testLenses8/11) proving correct conduct can still mis-behave.
- **Release-prep parity is a checklist, not a vibe**: T018 synced some `.specify` mirrors but missed
  extension.yml. A release-prep step should verify ALL version locations (ModuleVersion, config.yml, source
  extension.yml, `.specify` extension.yml) AND the full `.specify` mirror set in one explicit check.
- **The validator's review.md contract is strict and worth knowing up front**: Gap Ledger -> every non-empty
  line carries a `fixed-now`/`deferred` token (single-line bullets); a `deferred` gap requires a canonical
  `defer` entry (Type/Affected Iteration/Approving Human) in `.squad/decisions.md` + a review.md back-link;
  Task Verdicts -> exactly `pass`/`needs-work`/`blocked`.

## Improvement Actions

1. Owner: maintainer | Phase: next | Type: process | **Add a release-prep parity completeness check** to T018-class work: verify ALL version locations + the full `.specify` mirror set, not a subset (the review-signoff `.specify` extension.yml catch).
2. Owner: maintainer | Phase: next | Type: proposal | **Carry the i1 proposal candidates**: the 145-packet self-reference fields (partially applied here via the pinned reviewed_implementation_head), the scaffolder `-Force` ShouldProcess defect, the `Deploy-SpecrewSkill` extraction, and planned Proposal 178 (dependency-selection automation).
3. Owner: Implementer | Phase: review | Type: process | **Read the validator's review.md contract before authoring the packet** (Gap Ledger tokens, Task Verdict tokens, deferred-gap decisions.md entry) -- author to the contract once rather than iterate through ~8-min validate cycles.
4. Owner: Implementer | Phase: implement | Type: process | **Test single-element AND multi-element list cases** for any function returning a collection (the PowerShell single-element-array function-return unwrap; the leading-comma idiom guards it).

## Calibration Suggestion

- Suggested capacity adjustment: current baseline (20 SP) -> no change. i2 ran at 13.5 SP on scope.
- Rationale: implementation variance ~0; the iteration's real cost was the dogfood-found defect + review
  reconciliation -- process/tooling, not a sizing miss.

## Signals for Feature-Closeout

- **D-003 is the open gate**: the published `v0.35.0-beta.1` install-dogfood (human-on-host) MUST confirm
  SC-004 / SC-007 / SC-008 before promoting the 0.35.0 line to stable.
- Feature-closeout sequence (on approval): push the branch, open the PR, address bot review, merge, tag +
  publish `v0.35.0-beta.1`, then the human beta install-dogfood (the D-003 gate), then stable.
- Carry the proposal candidates (above) + author `pr-review-resolution.md` when the PR opens.

## Notes

- Scaffolded-equivalent from plan.md / state.md / drift-log.md / review.md; the boundary was advanced to
  retro through the formal `Invoke-SpecrewBoundaryStateSync` + consistent plan.md/state.md/dashboard updates
  (heeding the i1 retro send-back: do not leave the iteration state at the prior boundary).
- Review verdict: accepted for i2 delivery scope (SC-004/007/008 deferred-with-gate, D-003).

# Retro: Iteration 002 — research-gated host bindings, carries, docs, beta evidence

**Schema**: v1
**Date**: 2026-06-07
**Status**: complete

## What Went Well

- **Research-first ordering (the iteration-001 binding lesson) paid off concretely.** T013's live-doc matrix overturned a factually-obsolete spec premise (Copilot "no hook surface") BEFORE any binding code was written — D-002 reconciled the spec same-day, and T014 bound the verified subset per host instead of guessing.
- **Measurement-first carried forward and held.** Every binding decision cited the pwsh ~900ms spawn floor measured in iteration 001; UserPromptSubmit was confirmed as the cheap B3 home and bound on Codex without re-litigating latency.
- **Honest estimate revision in-flight.** T014 was revised 3.0→6.0 SP the moment the matrix proved three config formats and two casing conventions — recorded in plan.md with the arithmetic re-checked (12.5/20, within cap), not absorbed silently.
- **The feature dogfooded itself again at this gate.** The review-signoff boundary sync's channel-1 stdout delivered the retro-stage digest live — second production firing, clean.
- **Disprove-the-report review caught a real defect the suites missed.** Verifying the consumer-lane claim against the REAL e2e action log (not its exit code) exposed the greenfield-init anchor bug; it was fixed-now with an ordering guard and a re-proven 4-host e2e — exactly what review-signoff digest rule 9 exists to force.

## What Didn't Go Well

- **A T017 wiring defect shipped into the implement commit and was only caught at review.** The init hook-deployment block was anchored before the Squad-runtime step that provisions `.claude/`, so greenfield init silently skipped claude hooks. The unit/integration suites passed because they asserted content/parse/ordering on the SCRIPT, not the runtime greenfield deploy outcome — a form-vs-runtime gap on the producer's own consumer path.
- **The first review.md draft mis-summed the suite totals (336 vs actual 377).** A Shape-9 arithmetic-vs-form slip in my own claim ledger, caught by the advisor's read-back before the human saw it — but it should not have been written.
- **The consumer e2e lanes are non-hermetic for the new hook step.** PATH-based host detection with no home override means `update-command.ps1` and `bootstrap-to-iteration.ps1` deploy codex/copilot/cursor entries into the REAL user home. Benign (self-gating dispatcher), but tests writing outside their scratch dir is a defect.

## Lessons Learned

1. **A producer-script change needs a consumer-RUNTIME assertion, not just a content/parse assertion.** The anchor bug lived in the gap between "the wiring text is present and parses" and "the wiring produces the right deploy on a greenfield host." Owner: review discipline (already encoded as the iter-5 producer/consumer meta-rule; this is its second confirming instance). Next action: the e2e action-log grep for the deploy step is now part of the T017-class evidence, not the exit code.
2. **Run the arithmetic on your own evidence ledger before presenting it.** Shape 9 applies to review artifacts, not just capacity tables. Owner: me (review authoring). Next action: sum suite counts explicitly when writing the claim ledger.
3. **Hook-deploying tests must be hermetic.** Real-host side effects during integration runs are a latent footgun (today benign; tomorrow a destructive deploy script would not be). Owner: filed below as an improvement action.
4. **Honest non-binding is a feature, not a failure.** Antigravity shipped deferred-with-path because its primary contract was not fetchable — the matrix-gates-bindings rule did exactly its job. Worth keeping as the model for future host expansion.

## Drift Summary

- **Total drift events**: 1 (D-002, FR-013 Copilot clause obsoleted by live research) — resolved `spec-updated` same-day with citations in research-matrix.md. No unresolved drift at closeout. The greenfield-init anchor bug was an implementation defect caught at review (fixed-now in the gap ledger), not spec drift.

## Improvement Actions

1. **Thread `-UserHomeOverride` from the e2e lanes through `Invoke-RefocusHookDeployment` to `deploy-refocus-hooks.ps1`** so `update-command.ps1` / `bootstrap-to-iteration.ps1` stop writing the real user home (owner: Implementer; follow-up slice candidate — disclosed to the maintainer at the review gate).
2. **Producer-change reviews assert the consumer RUNTIME outcome** (e2e action-log evidence), not the lane exit code (owner: review discipline; confirmed meta-rule, no new artifact needed).
3. **Maintainer decision pending**: keep or remove the three user-home hook files (`~/.codex/hooks.json`, `~/.copilot/hooks/specrew-refocus.json`, `~/.cursor/hooks.json`) written by the test runs — they are identical to what a real `specrew init` would write on this machine.
4. **SC-008 beta runtime validation remains the release gate** (≥2 hook-bound hosts; Copilot B1 `source`-check rides as step 9) — carried to feature-closeout/beta, not this iteration.

## Estimation Accuracy

| Metric | Value |
| --- | --- |
| Planned / Actual | 12.5 / 12.5 SP (per-task Actuals = estimates across T013–T017) |
| Variance | 0 SP recorded against the REVISED plan (T014 3.0→6.0 was a mid-planning correction, not an overrun) |
| Honesty note | The one defect (init anchor) was fixed inside T017's 1.5 SP envelope at review — no scope was added or split. The real calibration signal: the 3.0→6.0 T014 revision shows the iteration-001 "measure before you estimate the host surface" lesson now fires at the right time. |

## Triage: Reviewer-Instruction Candidates

- **PROMOTE**: "For a change to a producer script, the review must assert the consumer's RUNTIME outcome (e2e action log / live artifact), not the consumer lane's exit code." (Second confirming instance; strongest form of the producer/consumer rule.)
- **DROP** (duplicate): "Re-run suites at review, do not quote implementation counts" — already shipped as review-signoff digest rule 9; this iteration's arithmetic slip was a summation error, not a quoting error.

## Signals for Next Iteration

- **Iteration 002 is the last implementation iteration** — feature scope (FR-001..020) is complete. Next is feature-closeout: PR, beta publish, SC-008 runtime validation on ≥2 hook-bound hosts under separate authorization.
- **Merge ordering** (from project state): land after crews 169/170; F-160 stale. Copilot B1 source-check is the open empirical question, resolved at the beta step.
- **Hermeticity follow-up** (improvement action 1) is the one carried code task; everything else is release mechanics.

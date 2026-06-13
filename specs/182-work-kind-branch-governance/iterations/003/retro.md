# Retrospective: Iteration 003

**Schema**: v1
**Date**: 2026-06-12

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T301 | 3 | 3 | 0 |
| T302 | 1 | 0.5 | -0.5 |
| T303 | 1.5 | 1.5 | 0 |
| T304 | 2.5 | 2.5 | 0 |
| T305 | 1.5 | 1.5 | 0 |
| T306 | 2.5 | 2.5 | 0 |
| T307 | 1 | 1 | 0 |
| T308 | 1 | 1 | 0 |

**Average variance**: -0.5 SP (slightly under). SP actuals are qualitative (no per-task time-tracking).
Planned consumed 14 / actual 13.5 / cap 20. The single under-variance is T302: it collapsed from
"regenerate the G4 artifact" to "verify" once the sweep confirmed G4 is the assembled runtime view of
G1–G3 (drift D-301), not a separate artifact. The in-review D-302 + D-304 completion fixes consumed the
small review/rework buffer, not new implementation SP.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Implementation | ~9.5 SP | ~9 SP | -0.5 | T301–T305; T302 collapsed (D-301). The genericize-with-labeled-example pattern (DP-1 b) carried cleanly across all three coordinator sources + lifecycle-discipline.md. |
| Review | ~3.5 SP | ~3.5 SP | +completion | T306–T308 + the Prop-145 review. The review's own SC-008 broad-verification caught D-304 (the shipped narrow sweep's blind spot); fixed in place + sweep widened within the buffer. |
| Rework | small | small | on-track | D-302 (.specify mirror sync) + D-304 (registry descriptors + widened sweep) + the Gap-Ledger single-line format fix — all bounded, fixed before closeout; no needs-rework verdict issued. |

## Drift Summary

- Total drift events: 4
- Resolved via spec/plan/mirror update (`spec-updated`): 2 (D-301 G4 assembled-view; D-302 mirror sync)
- Resolved via in-place neutralization (`implementation-reverted`): 2 (D-303 proposal-discipline.md; D-304 index docs + widened sweep)
- Deferred: 0
- Escalated to human decision: 0

(None is specification drift — spec ↔ implementation never diverged; all four are plan/inventory-vs-reality
reconciliations recorded in drift-log.md. D-303 + D-304 are also cross-referenced from review.md.)

## What Went Well

- **The Iteration-1 coupling inventory drove the slice cleanly.** The confirmed change surface (G1–G5)
  plus the planning-time sweep deltas (D1) mapped directly to tasks; the maintainer's DP-1 (b) and DP-2
  rulings resolved without re-design.
- **The genericize-with-labeled-example pattern preserved Specrew's own flow.** Every neutralized surface
  kept Specrew's own `gh` + PSGallery steps as an explicitly-labeled "Specrew's own example, NOT a
  downstream mandate" — so the decouple did not strip Specrew's usable closeout (T308 proves it).
- **The section-aware sweep design correctly separated two token classes**: generic forge mandates
  (`gh pr …`, section-level marker) from inherently-Specrew tokens (`Install-Module Specrew`, PSGallery —
  file-level marker, since a downstream project never installs "Specrew" as its own deliverable). That
  distinction is what let the sweep tolerate Specrew's own labeled examples without false-positives.
- **The forge-neutral default held in the runtime change (G5)**: the opt-in gate fails open to disabled,
  so a non-GitHub / un-opted project bakes in no reviewer — behaviour-proven (T305), not just intended.

## What Didn't Go Well

- **The load-bearing miss: the shipped SC-008 sweep had a gate-coverage directional blind spot (D-304).**
  The committed T306 sweep checked four mandate tokens and **missed the `PSGallery` registry-name class**,
  leaving a `PSGallery` descriptor in two downstream-governing methodology index docs (`README.md`,
  `review-instructions.md`). The iter-1 inventory had even inspected `review-instructions.md` and recorded
  it "already neutral" — missing the descriptor. It was caught **only** by the post-implementation
  broad-verification grep, not by the shipped sweep. Root cause: the sweep's token set was authored from
  the *known* couplings (gh pr + Install-Module Specrew), never from a registry-name *class* enumeration.
- **The `.specify` mirror handling was initially inconsistent (D-302).** `shared-governance.ps1`'s mirror
  was synced (forced by the SHA256 parity test) while `specrew-governance.md`'s equivalent mirror was left
  stale and *deferred* — leaving a committed mirror that still carried the exact `gh pr create` mandate the
  iteration removes. Caught by the advisor, not by my own pass.
- **A Gap-Ledger formatting bug FAILed the first review-state validation.** The Gap-Ledger bullets were
  authored with line-wrapping; `Test-NoGapClosurePolicy` is line-based, so the `: fixed-now` token landed
  on a continuation line the parser could not see. The earlier `validate-governance` PASS (run while
  status was still `executing`) had not exercised the accepted-verdict check — the classic "my green was on
  the wrong state" gap, surfaced by re-running after authoring the review.
- **Test-infra friction:** background `pwsh` tasks stalled on session events (one produced a misleading
  "7.5h hang" reading; another timed out `pr-review-integration` under 2×-concurrent contention). The
  `pr-review-integration` suite is genuinely slow (~180s isolated). Measurement noise, not a product
  defect, but it cost real time + a false alarm.

## Improvement Actions

1. Owner: Reviewer | Phase: review prep | Type: reviewer-instruction (PROMOTE) | A "no-over-claim" / coverage sweep must enumerate the token **class** (every name form of the forge/registry it guards), not just the already-known coupling tokens, AND the success criterion must be verified with a broad backstop grep — a green narrow self-test proves the test passes, not that the criterion holds. (Prevents the D-304 class.)
2. Owner: Implementer | Phase: implement | Type: process (PROMOTE) | When one tracked mirror in a parity-enforced set is synced, sync ALL equivalent tracked mirrors in the SAME commit — never sync one and defer an equivalent; a deferred mirror that contradicts the change is a committed lie. (Prevents the D-302 class.)
3. Owner: Reviewer | Phase: closeout authoring | Type: reviewer-instruction (PROMOTE) | Validator-parsed list entries (Gap Ledger especially) must be SINGLE physical lines; the closure-policy parser is line-based, so a wrapped bullet hides its classification token. Re-run validate-governance AFTER flipping to the review/closeout state, never trust an executing-state green for accepted-verdict checks. (Prevents the gap-ledger class.)
4. Owner: Implementer | Phase: tooling backlog | Type: implementation (DEFER) | File the background-`pwsh`-stall + the ~180s `pr-review-integration` runtime as test-infra candidates (Proposal-037 / test-harness backlog); not blocking, but they produce false hang/timeout readings under session-suspension + concurrency.

## Calibration Suggestion

- Suggested capacity adjustment: keep the 20 SP iteration cap (Iter-3 planned 14, actual 13.5, under cap;
  on-target with one small under-variance from the D-301 collapse).
- Rationale: estimation held to within -0.5 SP; the only extra effort was the bounded in-review D-302 +
  D-304 + format completion, which fit the planned review + rework buffer. The feature total across
  Iters 1–3 is now complete bar feature-closeout (T013b release-prep remains).

## Signals For Next (Feature-Closeout)

- Iteration 3 was the feature's **final implementation slice**. The remaining boundary is
  **feature-closeout** (release/deploy + the cross-iteration reconcile), NOT a new iteration.
- **T013b** (extension.yml version bump + deploy-time `.specify` coverage) remains carried to
  feature-closeout / release-deploy (drift-log D-001), where the version target is a release decision.
- **Closeout housekeeping (deferred, WARN-level — confirm at feature-closeout):** like Iteration 2,
  Iteration 3 closes WITHOUT a hand-rendered `dashboard.md` (the only hand-driven render paths re-spawn
  the lint-dirty reviewer supplements that were removed to keep the review clean), so it carries the same
  `missing-dashboard-auto-render-regression` WARN. Confirm at feature-closeout that this stays a
  non-blocking WARN (never hardens into a gate), or render both iter-2 + iter-3 dashboards via the proper
  boundary-sync path for parity with Iteration 1.
- **Carried watch-items:** the `Get-SpecrewAutomatedReviewOptIn` hand-YAML parser (brittle to
  non-standard indentation; fails open to disabled) — add a contract test as the governance schema
  evolves; the codified SC-008 sweep guards specific token classes, so the one-time broad-verification
  grep stays the backstop for any future forge-coupling class.
- The three new reviewer-instruction candidates above (class-enumeration + broad backstop;
  sync-all-equivalent-mirrors; single-line-validator-bullets + re-validate-on-the-right-state) are PROMOTE
  candidates for the durable review/closeout playbook (Proposal 145 / reviewer charter), pending the
  maintainer's triage.

## Notes

- Maintainer signed off the Iteration-3 review (accepted) and authorized retro + iteration-closeout, then
  stop before feature-closeout.
- D-303 (`proposal-discipline.md` generic PR/MR wording) is maintainer-ratified as inheritable methodology;
  D-304's honest record (the original narrow sweep was incomplete) is preserved in review.md + drift-log.md
  per the maintainer's instruction.
- No push/PR/merge/tag/publish/release; no Iteration 4 — stop after iteration-closeout per the maintainer's
  instruction.

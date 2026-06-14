# Retrospective: Iteration 004

**Schema**: v1
**Date**: 2026-06-13

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T401 | 3 | 3 | 0 |
| T402 | 2 | 2 | 0 |
| T403 | 3 | 3 | 0 |
| T404 | 1.5 | 1.5 | 0 |
| T405 | 2 | 2 | 0 |
| T406 | 2 | 2 | 0 |
| T407 | 1.5 | 1.5 | 0 |
| T408 | 2 | 2 | 0 |

**Average variance**: 0 SP. Planned 17 / actual 17 / cap 20 — within capacity. SP actuals are qualitative
(no per-task time-tracking). The per-task estimates held exactly; the extra effort that did materialize was
the **review send-back rework** (3 findings; F1/F2 blocking), which the plan's small rework buffer absorbed —
it produced no new task SP because it reworked T402/T403/T404's existing surfaces in place (commit
`61e6b258`), not new scope.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Implementation | ~13 SP | ~13 SP | 0 | T401–T407. The widened-sweep + neutralization (T401–T402) and the smaller forge-aware/routing/detector items (T405–T407) landed first-pass clean. |
| Review | ~4 SP | ~4 SP | +send-back | T408 + the Prop-145 review. The first review pass issued a **needs-rework** verdict (3 findings); the second pass accepted on the reworked tree. |
| Rework | small | small (3 findings) | on-track | F1 (deployed-shape resolution) + F2 (refocus session-start surface) + F3 (section-aware marker) — all bounded, fixed in `61e6b258`, absorbed by the planned buffer. |

## Drift Summary

- Total drift events: 1
- Resolved via in-place rework (`implementation-reverted`): 1 (D-401 — the review send-back: deployed-shape
  resolution + real intake surface + section-aware marker scope)
- Resolved via spec/plan update (`spec-updated`): 0
- Deferred: 0
- Escalated to human decision: 0

(D-401 is **not** specification drift — spec ↔ implementation never diverged; it is an implementation-quality
rework recorded in drift-log.md + cross-referenced from review.md. The iteration **reopen** itself is recorded
in closeout.md (superseded note) + dogfood-findings.md, not as drift.)

## What Went Well

- **The widened sweep is genuinely pattern-based, so it discharges the F-174 obligation without coupling.**
  T401 scans `.ps1` + deployed-agent surfaces by pattern, not by an enumerated file list — and a regression
  fixture proves it flags a synthetic `scripts/internal/launch-contract.ps1` mandate (2 hits). F-182 meets its
  binding obligation (catch F-174's future site at reconciliation) **without** editing F-174's worktree.
- **The labeled-example pattern from iter-3 carried cleanly to the runtime layer.** The two F-182-owned
  runtime/deployed surfaces (`specrew-start.ps1`, `squad.agent.md`) neutralized to the same "Specrew's own
  example, NOT a downstream mandate" form the iter-3 coordinator sources use — so the decouple did not strip
  Specrew's own usable closeout.
- **The scope guardrail held under temptation.** DF-006 (session-state clobber) and the `launch-contract.ps1`
  neutralization both sat one edit away, but stayed **out** of F-182 (routed to F-174) — `specrew-start.ps1`
  was touched current-tree-only and documents its F-174 supersession. No scope creep.
- **The review's own falsification caught the dev-vs-deployed-shape masking** before the accept was recorded
  — the send-back is the review doing its job, not a late surprise.

## What Didn't Go Well

- **The load-bearing miss: SC-016 was first proven against the DEV-REPO shape, not the DEPLOYED `.specify`
  shape (F1 + F2, both blocking).** The lifecycle templates lived at repo-root `templates/lifecycle/`, the
  resolver used the wrong roots, and the surface was wired into the **validator** — which runs too late to
  matter for DF-009 (intake/start). The first SC-016 green was real **on the dev repo** and **false on a real
  `specrew init`**. Root cause: I built + proved the success criterion against the convenient shape (the dev
  tree, the component that was easy to wire) instead of the shape + surface the SC actually targets (the
  deployed extension tree, the session-start path that fires before work begins). This is the iter-4 sibling
  of iter-3's "prove the criterion with a broad backstop, not a narrow self-test."
- **A file-level marker over-suppressed (F3, medium).** One labeled block's file-level marker whitewashed a
  **separate** unlabeled `gh pr` elsewhere in `squad.agent.md`. The marker granularity (file) was coarser than
  the thing it certified (one section), so it certified more than it had inspected — a quieter version of the
  same "the green covered less than it claimed" failure as F1/F2.
- **Same agent-knowledge confound recurred in the dogfood that opened this iteration.** The findings that
  drove iter-4 had to be read at the **artifact** level (the markdown-only sweep, the inert templates), because
  the behavior-level "the agent did the right thing" signal is confounded by an agent that already knows
  Specrew. The iteration was scoped from the confound-proof facts, correctly — but it is a standing reminder
  that behavior-level dogfood green is not evidence.

## Improvement Actions

1. Owner: Reviewer | Phase: review prep | Type: reviewer-instruction (PROMOTE) | A success criterion that targets a **deployed** artifact MUST be proven against the **deployed shape** (`.specify/extensions/...`), never the dev-repo layout — and a surfacing SC MUST be wired into (and asserted on) the **runtime path that actually fires when the SC's trigger occurs** (intake/session-start), not the most convenient component that happens to read the same data (a validator that runs too late). A green on the dev shape / the convenient surface is "my green was on the wrong shape." (Prevents the F1/F2 class.)
2. Owner: Implementer | Phase: implement | Type: process (PROMOTE) | A neutralization **marker's granularity must match what it certifies**: a per-section claim ("this GitHub orchestration is a labeled example") needs a per-section marker; a file-level marker may only certify a whole-file property. When a surface mixes labeled examples and separate live mandates, scope the sweep + the marker to the section. (Prevents the F3 class.)
3. Owner: Reviewer | Phase: dogfood intake | Type: reviewer-instruction (REAFFIRM) | When a dogfood is run by an agent that already knows Specrew, scope the resulting work from the **artifact-level + deterministic-validator** facts (the sweep, the inert template, the resolver shape) and **discount** the behavior-level "the agent did the right thing." (Reaffirms the agent-knowledge confound rule; drove iter-4 scoping correctly.)
4. Owner: Implementer | Phase: tooling backlog | Type: implementation (CARRY) | The pre-existing `refocus-digests.tests.ps1` red ("specify.md scopes specrew-gate-stop verdict routing by host") is a gate-stop digest gap (F-165/F-171/Proposal-188 territory), out of work-kind/forge scope — carry to the gate-stop digest work, do not blind-fix here.

## Calibration Suggestion

- Suggested capacity adjustment: keep the 20 SP iteration cap (iter-4 planned 17, actual 17, under cap;
  estimation held to 0 variance).
- Rationale: the per-task estimates were exact; the only extra effort was the bounded send-back rework, which
  fit the planned review + rework buffer. Across iterations 1–4 the feature is now complete bar
  feature-closeout.

## Signals For Next (Feature-Closeout)

- Iteration 4 was the **final dogfood-completion slice**. The remaining boundary is **feature-closeout**
  (the cross-iteration reconcile + release/deploy decision), NOT a new iteration. The iter-1–3 `closeout.md`
  carries a reopened/superseded note; a fresh feature-closeout supersedes it.
- **Carries to surface at feature-closeout (maintainer-ratified, NOT blockers):**
  - The pre-existing `refocus-digests.tests.ps1` red (gate-stop digest; out of work-kind/forge scope).
  - The optional FR-024 GitLab CI **template** (`.gitlab-ci.yml`) — the forge-aware lane + routing ship; the
    turnkey template is descoped.
  - The work-kind **validator** lifecycle field is kept as a **secondary** CI surface (the primary surface is
    the refocus session-start path, per F2).
- **Dashboard WARN (confirm-not-harden at feature-closeout, parity with iter-2/iter-3):** Iteration 4 closes
  WITHOUT a hand-rendered `dashboard.md`, so `validate-governance` carries the same
  `missing-dashboard-auto-render-regression` WARN for `182…004` (exit-code-independent). Confirm at
  feature-closeout that this stays a non-blocking WARN (never hardens into a gate), or render the iter-2/3/4
  dashboards via the proper boundary-sync path for parity with Iteration 1.
- **DF resolution-marking is feature-closeout reconciliation (NOT iteration work):** the dogfood findings
  this iteration fixed (DF-001, DF-004, DF-005, DF-008, DF-009) are NOT yet marked resolved in
  `dogfood-findings.md` — that cross-artifact reconciliation belongs at feature-closeout, behind the stop
  line. DF-006 + DF-010 stay F-174 handoffs (do not mark them F-182-resolved).
- **F-174 handoffs (recorded, NOT F-182 work):** DF-006 resume-preserves-state regression test;
  `launch-contract.ps1` neutralization (F-174 owns after rebasing onto F-182); DF-010 merge reconciliation
  (F-174 preserves F-182's neutralized coordinator sources + resolves the `specrew-start.ps1` conflict in
  favor of its deletion). F-182's obligation (the pattern-based widened sweep) is **already landed** and
  proven by the regression fixture.
- **Release/version (feature-closeout decision):** the FileList now ships the 4 lifecycle templates from the
  deployed extension tree (`Specrew.psd1` updated, ModuleVersion 0.36.0); the extension.yml version + the
  beta-before-stable publish are feature-closeout/release decisions, not iteration work.
- The two new reviewer-instruction candidates above (deployed-shape + right-surface proof;
  marker-granularity-matches-claim) are PROMOTE candidates for the durable review/closeout playbook
  (Proposal 145 / reviewer charter), pending the maintainer's triage.

## Notes

- Maintainer signed off the Iteration-4 review (accepted, after the send-back rework) and authorized retro +
  iteration-closeout, then stop before feature-closeout.
- The refocus-digests red and the FR-024 GitLab template are recorded as **explicit carries, not blockers**,
  per the maintainer's verdict.
- No push/PR/merge/tag/publish/release; no feature-closeout — stop after iteration-closeout per the
  maintainer's instruction.

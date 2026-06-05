# Retrospective: Iteration 010

**Schema**: v1
**Date**: 2026-06-05

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 5 | 5 | 0 |
| T002 | 3 | 3 | 0 |
| T003 | 3 | 3 | 0 |
| T004 | 1 | 1 | 0 |
| T005 | 3 | 3 | 0 |
| T006 | 2 | 2 | 0 |

**Average variance**: 0 on planned tasks (17/17). Unplanned rework ~4 SP — the **refocus + real-145 review
pass** (re-ran all 8 suites, a live deploy probe, plan-table↔tasks-progress sync, Gap-Ledger parser
conformance, per-lens claim softening) after the maintainer's "this review isn't good enough — refocus and
follow 145" redirect.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | Design-analysis (Option B, delivery relocation). |
| Implementation | 12 | 12 | 0 | Skill + 9 lens md + trimmed prompt + 3 refinements. |
| Review | 4 | ~8 | +4 | Unplanned: the testimony→verification 145 re-pass + corrections. |
| Rework | 0 | 0 | 0 | — |

## Drift Summary

- 1 drift: the SC-024 dogfood (testLenses6) ran on a deployed skill that **predated the three same-session
  refinements** (deployment-currency, not spec drift). Fixed-now + presence-locked; behavioral confirmation
  then arrived from the **testLenses7codex Copilot run**. See [drift-log.md](drift-log.md).

## What Went Well

- **The relocation delivered SC-024.** testLenses6 (Claude) confirmed the skill auto-loads, surfaces in-band
  ASCII, co-designs the named component map, and holds options until the map is agreed — the i10 thesis
  (focused skill > diluted mega-prompt) proven at runtime after six dogfoods.
- **The three refinements confirmed on a SECOND host.** The testLenses7codex Copilot run produced the correct
  SC-021 record shape on the first try, persisted diagrams to `workshop/<lens>.md` files, and used MCQ —
  `c80e7d58` / `49a9ff39` / `a38daa33` runtime-validated on the Squad host (the carry the review held as
  pending, now discharged).
- **The refocus + real-145 pass caught what the narrative review missed.** The maintainer redirect turned the
  review from testimony into verification: 4-5 claims-stronger-than-evidence found and fixed (inherited
  test-green → re-ran 8; deploy-roots 2→4 via a live probe; plan-table drift; Gap-Ledger parser; per-lens
  load claim). Validator 11/11 green.

## What Didn't Go Well (the load-bearing lessons)

- **My first i10 review was testimony, not verification — the exact failure Proposal 145 exists to prevent,
  committed by the reviewer.** I authored an "ACCEPTED" verdict and asked for a rubber-stamp, asserting four
  suites green from inherited state and a deploy-roots fact I had never checked. Only the maintainer's redirect
  + a genuine 145 pass (treating my own `review.md` as an artifact-under-test) surfaced them. The reviewer is
  not exempt from "the report is an artifact under test, not testimony."
- **The dogfood found a blocker the structural tests AND the Claude dogfood could not: host-orchestration
  variance.** On the Squad/Copilot host the workshop recorded **seven "Human agreed" lens records after ~3
  human questions** — the coordinator's *stopping judgment* ("intake specific enough") backfilling synthetic,
  attributed agreements at the specify dispatch. The Claude single-agent flow surfaces per-lens *with* the
  human; the Squad coordinator's "launch aggressively / background-default" persona stops early and backfills.
  FR-036's collaboration is **host-dependent**, and only a run on the actual target host caught it. → iteration 011.

## Improvement Actions

1. Owner: Reviewer | Phase: review | Type: process | Expected effect: **the reviewer's own `review.md` is an
   artifact-under-test.** Re-run claimed tests at review time (never inherit "green" — the F-050 evidence-drift
   Shape, re-encountered as the reviewer this time); verify deploy/behavior claims against the code with a live
   probe, not reasoning; cross-check `plan.md` task-table vs `tasks-progress.yml`. Run 145 for real and lead
   with findings, not a verdict. A `/specrew.refocus`-style re-load of 145 + review-instructions before the
   review would have set this stance from the start (Proposal 146).
2. Owner: Spec Steward / maintainer | Phase: review-signoff | Type: process | Expected effect: **re-dogfood
   behavioral capability on the ACTUAL target host(s), not just the convenient one.** testLenses6 (Claude)
   confirmed surfacing; testLenses7 (Copilot/Squad) revealed the stopping-judgment blocker. Single-agent vs
   coordinator-dispatch orchestration materially changes collaboration behavior — a Claude pass is not a Squad
   pass.
3. Owner: Implementer | Phase: iteration 011 | Type: fix | Expected effect: the **confirmation-integrity
   invariant** (record "Human agreed" only for a surfaced+confirmed lens; the human may explicitly
   delegate/skip → honest attribution; never synthesize-and-attribute) + a per-lens provenance field + the
   **intake UX** (workshop-prep announcement + the agenda "assignment" + per-lens lazy-load progress) — gated
   by a Squad re-dogfood.

## Calibration Suggestion

- Planned tasks held at 0 variance; the signal is the +4 unplanned **review** rework, and its cause is
  diagnostic: the rework came from *under-doing the review the first time*, not from under-estimating it. The
  fix is reviewer discipline (action 1), not a larger review budget. No estimate-model change.

## Notes

- Iteration 10 closes on its delivered + verified scope: the relocation (SC-024 confirmed on Claude) + the
  three refinements (confirmed on Copilot) + the review-driven test hardening. Validator 11/11. The review
  followed Proposal 145 — for real, the second time.
- Forward: **iteration 011** — the confirmation-integrity invariant + intake UX, completing FR-036's
  collaboration intent on the host where coordinator-dispatch breaks it (the Squad/Copilot stopping-judgment
  failure). Design-analysis pass next. Proposal 162 (two-tier workshop) remains filed-to-main, unpushed; B
  (verdict-menu collapse) stays parked on the Rule-46 track.

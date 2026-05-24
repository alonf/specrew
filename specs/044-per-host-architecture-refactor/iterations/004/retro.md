# Retrospective: Iteration 004

**Schema**: v1
**Date**: 2026-05-24

**Feature**: F-044 Per-Host Architecture Refactor

> **First LIVE-TRACKED iteration of F-044.** Unlike iter-001/002/003 (retroactive backfills), iter-004's plan.md was authored before any code change. Actuals were measured at task close, producing real variance data.

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 1.5 | 1.5 | 0 |
| T002 | 1 | 1 | 0 |
| T003 | 0.5 | 0.5 | 0 |

**Average variance**: +/- 0 (live-tracked; scope held; no rework)

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0.25 | 0.25 | 0 | plan.md written upfront with SP + Phase Baseline. |
| Discovery/Spikes | 0 | 0 | 0 | All 3 tasks had clear root cause from user feedback. |
| Implementation | 2.5 | 2.5 | 0 | T001 + T002 + T003 within estimates. |
| Review | 0.25 | 0.25 | 0 | Parse-check + smoke-test verified user's requested output empirically. |
| Rework | 0 | 0 | 0 | None. |

## Drift Summary

- Total drift events: 0 (see [drift-log.md](./drift-log.md))
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0 in-iteration; 3 out-of-scope items recorded in drift-log for traceability.

## What Went Well

- **Live tracking finally worked.** Plan-before-code produced real variance data (all zeros this time because scope was small + estimates were sound; future iterations will surface genuine variance).
- **Three tasks closed in expected sequence.** T001's helper extraction made T002 + T003 trivial — the BinaryAliases probe became a 4-line helper that consumers just call.
- **Empirical user-output match.** `specrew-host.ps1 -Subcommand list` produced the EXACT two-group output the user pasted in their request, on the first try. The user can copy the smoke-test output and verify.
- **Backwards-compat preserved.** Numbered-menu accepts both digit input AND kind-name input — users who memorized `claude` / `codex` etc. don't have to relearn.

## What Didn't Go Well

- **The "if-expression in -f format" PowerShell syntax tripped the smoke-test script.** Had to extract to a `$display = if (...) {} else {}` line before using in `-f`. Not a production issue (smoke test only), but a latent gotcha for anyone writing similar diagnostics.
- **No automated regression test added.** The smoke-test script lives in `.scratch/` (untracked). Promoting it to `tests/integration/` would prevent future regressions on the menu UX + host-list grouping. Queued for follow-up.
- **Version-number drift surfaced mid-iteration** (F-040 shipped as 0.26.0 instead of 0.40.0). Not iter-004's scope to fix but worth documenting as a separate methodology decision (option a: status quo bump to 0.27.0; option b: restore convention with jump to 0.44.0; option c: align going forward only). Captured for the user's decision before next PR-to-main.

## Improvement Actions

1. **Promote `.scratch/iter004-smoke.ps1` to `tests/integration/host-detection-ux.tests.ps1`** — Owner: Implementer | Phase: next small-fix slice | Type: testing | Expected effect: prevent regressions on menu UX + host-list grouping.
2. **Decide version-numbering policy** — Owner: User | Phase: pre-PR | Type: methodology | Expected effect: stop drift before next release; PSGallery users see a coherent version sequence.
3. **Document the if-expression-in-format-arg PowerShell gotcha** in `docs/how-to/add-a-new-host.md` Common Pitfalls section — Owner: next iteration | Type: docs | Expected effect: future contributors don't re-stub their toe.
4. **Live-tracking pattern formalization** — first iteration to do it; lock in for iter-005+.

## Calibration Suggestion

- Suggested capacity adjustment: keep 20 SP baseline. iter-004 used 3/20 (15%). Single-day small-UX-fix iterations should sit comfortably in the 2-5 SP range; capacity 20 leaves room for legitimately larger iterations (like iter-001's 18 SP architectural payoff).
- First real data point for variance — all zeros means estimates were sound OR scope was too small to surface variance. Next live-tracked iteration with ≥10 SP will be a better calibration signal.

## Notes

- This retro contains REAL variance data (all zeros, but real measurements at task close, not backfilled).
- iter-004 closes F-044 to the point where the user's next manual test round is the canonical review boundary for both the iter-003 fixes AND iter-004 UX changes.

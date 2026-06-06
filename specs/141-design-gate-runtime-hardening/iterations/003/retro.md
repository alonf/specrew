# Retrospective: Iteration 003

**Schema**: v1
**Date**: 2026-06-03

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 1 | 1 | 0 |
| T002 | 3 | 3 | 0 |
| T003 | 3 | 3 | 0 |
| T004 | 2 | 2 | 0 |
| T005 | 1 | 1 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | T001 reproduce + classify both defects before any fix. |
| Implementation | 6 | 6 | 0 | T002 (FR-012) on estimate. T003 (FR-013) reframed by prove-first to verify-clean + a guidance nudge — the 3 SP went into the prove-first investigation + the conservative nudge rather than the "establish a baseline commit" the plan anticipated. |
| Review | 3 | 3 | 0 | T004 tests + T005 docs/gap-ledger on estimate. |
| Rework | 0 | ~2 | +2 | Unplanned: the origin/main (0.31.0 + Feature 140) merge; the review-signoff send-back (state/plan/coverage reconciliation); the advisor-caught SC-009 reachability gap; the markdownlint-gate auto-fix corruption repair; the stale-install boundary-sync block. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 1 (the US6-AC1-vs-Feature-029 tension — resolved-by-clarification: C+nudge, no auto-commit)

## What Went Well

- **Prove-first prevented a wrong fix.** FR-013 looked like "establish a baseline commit," but the discriminator showed the baseline already resolves once a commit exists and the zero-commit omission is the *intentional, tested* Feature-029 fail-safe. Auto-committing would have contradicted `baseline-hygiene.tests.ps1:372-375`. The slice landed as verify-clean + a conservative guidance nudge — the maintainer's C+nudge call.
- **Signal-layer reproduction found a real FR-012 false positive.** Black-box intake `specrew start` looked clean (the multi-session guard no-ops without an active feature); probing `Get-SpecrewMultiDeveloperSignals` directly surfaced that a single-dev bootstrap's own writes tripped the multi-dev recommendation.
- **The advisor caught a form-without-enforcement gap.** The committed SC-009 sat after a locally-halting block in baseline-hygiene and was only assumed-green in CI; it was promoted to a committed, locally-green `design-gate-runtime-hardening-greenfield-baseline.tests.ps1` (watched pass).
- **Honest evidence + clean merge.** Removed an unverified "CI-reached" claim; classified `stash@{0}` as non-141 and parked it; merged a stable release (0.31.0 + Feature 140) with zero conflicts and re-verified 141 green post-merge.

## What Didn't Go Well

- **FR-012 did not reproduce in the obvious (intake) surface.** The multi-dev guard's feature-gating masked the false positive in black-box testing; it took a signal-layer probe to find. Cost investigation time.
- **SC-009 was initially unreachable where claimed.** Committed in a suite that halts locally + assumed green in CI — the exact runtime-vs-form anti-pattern; only the advisor's check forced a locally-verified home.
- **The markdownlint pre-boundary gate's `--fix` corrupted prose.** It turned `+`-at-(indented)-line-start continuations into `-` bullets in `coverage-evidence.md` + `quickstart.md` during boundary-sync, requiring repair + rephrasing.
- **The stale-install guard blocked boundary-sync.** The merge bumped `.specrew/config.yml` to 0.31.0 while the installed module was 0.30.0; recording the boundary required pointing `SPECREW_MODULE_PATH` at the dev tree.

## Improvement Actions

1. Owner: Implementer/Reviewer | Phase: next reproduction | Type: testing | Expected effect: when a defect's user-facing surface looks clean, probe the underlying signal/function layer before concluding verify-clean — black-box intake masked the FR-012 false positive.
2. Owner: Reviewer | Phase: pre-review | Type: testing | Expected effect: place each SC-NNN test in a suite that runs GREEN LOCALLY and watch it pass; never rest enforcement on an unverified "green in CI" assumption behind a locally-halting block.
3. Owner: Spec Steward/Planner | Phase: authoring | Type: process | Expected effect: avoid `+`/`*` at (indented) line-starts in lifecycle `.md` prose — the F-033 `--fix` gate mangles them into bullets. Candidate follow-up: make the gate refuse-rather-than-silently-mangle, or scope `--fix` to safe rules.
4. Owner: Implementer | Phase: post-release-merge | Type: ops | Expected effect: after merging a release that bumps the project version, set `SPECREW_MODULE_PATH` to the dev tree (or run `specrew update`) before boundary-sync so the stale-install guard does not block self-host lifecycle ops.

## Calibration Suggestion

- Suggested capacity adjustment: keep the 20 SP iteration baseline (no change); the 10 SP estimate held.
- Rationale: planned-task variance was 0. The real signal is **unplanned work** (the release merge, the send-back reconciliation, the SC-009 reachability fix, the markdownlint repair, the stale-install workaround) absorbed without dropping scope — budget an unplanned-discovery buffer rather than changing the cap. Notably T003's "fix" SP was consumed by prove-first investigation that correctly reframed the work to verify-clean + nudge.

## Notes

- Reproduction/classification + the prove-first discriminator are in drift-log.md; the C+nudge decision + the US6-AC1-vs-Feature-029 resolution are recorded there and in coverage-evidence.md.
- Follow-ups carried out of iteration 3: FR-012 self-host-only signals (not greenfield leaks); `recorded_at` coercion (deferred, untouched); `stash@{0}` disposition (ask Alon before dropping); the Feature-140 FileList `install.sh` sort (a 140/release manifest concern, reverted from this branch); the markdownlint `--fix` mangle-hazard (action 3).

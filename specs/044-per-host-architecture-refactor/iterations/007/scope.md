# Iteration 007 Scope

**Feature**: F-044 | **Iteration**: 007 — Linux Portability + Docs Sweep + PR Readiness (LIVE-TRACKED)

## Bug-by-bug closure

| Issue | Empirical source | Fix |
|---|---|---|
| **Windows-only `'C:\'` hardcoded path** | Antigravity WSL test (post-iter-006) — agent patched `.specify/.../scaffold-reviewer-artifacts.ps1` line 998 to handle Linux | T001 — canonicalized: `DirectorySeparatorChar`-driven root prefix + trim length; also fixed line 990 `-replace '/', '\'` |
| **Sibling: `'evaluation\report.md'` backslash literal** | T002 proactive grep audit (not Antigravity-surfaced — caught before next dogfood) | T002 — `'evaluation/report.md'` (forward slash, cross-platform Join-Path safe) |
| **README missing host-switching narrative** | User-flagged at end of WSL test: "Add to the readme one of the main advantages of Specrew - the ability to switch AI host tool and continue from the same spot" | T003 — new "Switch your AI host mid-feature" section near "Why Specrew" copy |
| **README stale version badge (0.25.0 → 0.27.0)** | iter-007 audit | T003 — bumped |
| **README duplicate F-043 entry in roadmap** | iter-007 audit | T003 — removed |
| **user-guide.md stale "v0.26.0, three host runtimes"** | iter-007 audit | T004 — bumped to v0.27.0 with Antigravity row in flag-translation + capability matrices |
| **9 MD032 markdownlint violations across iter-001..006 artifacts** | T005 lint sweep | T005 — `markdownlint --fix` (auto-fix) |
| **No Linux-portability regression assertions** | iter-007 design — prevent future regression | T006 — added Tests 8/9/10 to multi-host-lifecycle-smoke.tests.ps1 |
| **bootstrap-to-iteration test asserts stale Squad-branded text** | T007 CI test sweep surfaced — test predates F-044's Crew-neutral bootstrap output (Slice 9) | T007 — updated 2 assertions to match current "Add extra Crew members" / "Keep the Specrew-managed baseline charters intact" |
| **`.specrew/config.yml` + extension.yml version drift (0.26.0 vs psd1 0.27.0)** | T007 validator run surfaced Rule 15 warning | T007 — bumped 3 manifest files to 0.27.0 |
| **iter-005 pr-review-resolution.md missing (soft warning)** | T007 validator | T007 — pre-created stub placeholder |

## What iter-007 surfaced but is NOT in scope

- **baseline-hygiene + lifecycle-boundary-sync test failures** — confirmed pre-existing on origin/main; markdownlint gate halting `Invoke-SpecrewBoundaryStateSync` on auto-fixed `last-start-prompt.md`. Real bug class (the gate is correctly firing but the workflow doesn't re-commit the auto-fix), but pre-dates F-044. Candidate for separate small-fix iteration.
- **dashboard.md missing for 8 closed iterations** — pre-existing across F-031, F-043, F-044/001..006. Dashboard auto-render is open work (Proposal 046+048 bundle). Not iter-007 scope.
- **proposals/INDEX.md** entries for F-043 + F-044 + Proposal 108 — deferred to post-PR-merge chore per "proposals commit to main only" rule (already recorded in iter-005 drift-log).

## Methodology dogfood — fourth LIVE-TRACKED iteration

| Iteration | Pattern | SP planned | SP actual | Variance |
|---|---|---|---|---|
| iter-001 | Backfill | 18 | 18 | 0 (forced) |
| iter-002 | Backfill | 6 | 6 | 0 (forced) |
| iter-003 | Backfill | 4 | 4 | 0 (forced) |
| iter-004 | **LIVE** | 3 | 3 | 0 |
| iter-005 | **LIVE** | 8 | 8 (T007 deferred) | -0.5 |
| iter-006 | **LIVE** | 5.5 | 4 (T002 simpler than planned) | -1.5 |
| iter-007 | **LIVE** | 7 | 7 | 0 |

iter-007 hit exactly on plan: the work decomposed cleanly into the 7 tasks budgeted, no scope creep, no scope reduction. Calibration data point: when an iteration plan starts from a clear user-stated scope ("fix X, audit Y, add Z, verify W") the estimate accuracy is high. Calibration variance grows when the scope is "we'll see what we find".

## Cross-feature bundle disclosure

F-043 (Multi-Host Onboarding) and F-044 (Per-Host Architecture Refactor) ship as a bundled PR. iter-007 is the final iteration in F-044 before that bundled PR; F-043's iter-001 ships unchanged as part of the same PR. See [closeout-dashboard.md](../../closeout-dashboard.md) for the cross-feature dashboard.

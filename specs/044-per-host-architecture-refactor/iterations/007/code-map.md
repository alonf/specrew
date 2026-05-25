# Code Map: Iteration 007

**Feature**: F-044 | **Iteration**: 007 — Linux Portability + Docs Sweep + PR Readiness

## Production code touched

| File | Change | Why |
|---|---|---|
| `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1` | `Resolve-ModuleReference` lines 990 + 998: `DirectorySeparatorChar`-driven separator; `'C:\\'` → platform-aware root prefix; substring index 3 → platform-aware trim length | T001 — Linux portability (Antigravity's empirical WSL patch canonicalized) |
| `.specify/extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1` | Identical mirror of canonical fix | T001 — Specrew's self-dogfooded `.specify/` copy is git-tracked; keep both in sync |
| `evaluation/scorers/process-scorer.ps1` | Line 92: `'evaluation\report.md'` → `'evaluation/report.md'` | T002 — sibling Linux-portability bug found via proactive grep audit |
| `README.md` | New section "Switch your AI host mid-feature — without losing your place"; version badge 0.25.0 → 0.27.0; removed duplicate F-043 roadmap entry | T003 — user-requested headline differentiator |
| `docs/user-guide.md` | Multi-Host Launch section bumped v0.26.0 → v0.27.0; added Antigravity to flag-translation + capability matrices + launch-shape block; supported-host list updated to 4 hosts | T004 — version + host catalog parity |
| `tests/integration/multi-host-lifecycle-smoke.tests.ps1` | New Tests 8, 9, 10 (Linux-portability assertions + iter-007 parse-check) | T006 — regression coverage for iter-007 fixes |
| `tests/integration/bootstrap-to-iteration.ps1` | 2 assertion repairs: `'Add extra Squad members'` → `'Add extra Crew members'`; `'Keep the Specrew-managed baseline block intact'` → `'...baseline charters intact'` | T007 — align test with F-044's Crew-neutral bootstrap output (Slice 9) |
| `.specrew/config.yml` | `specrew_version: 0.26.0` → `0.27.0` | T007 — Rule 15 manifest parity |
| `extensions/specrew-speckit/extension.yml` | `version: "0.26.0"` → `"0.27.0"` | T007 — Rule 15 manifest parity |
| `.specify/extensions/specrew-speckit/extension.yml` | `version: "0.26.0"` → `"0.27.0"` | T007 — Rule 15 manifest parity |
| `specs/044-per-host-architecture-refactor/iterations/005/pr-review-resolution.md` | NEW placeholder stub | T007 — clear pr-review-integration soft warning before PR opens |
| Various iter-001..006 `*.md` files (9 files) | MD032 auto-fix (blank lines around lists) | T005 — markdownlint sweep |

## Iteration artifacts produced

- `iterations/007/plan.md` (live-tracked, written at iteration start)
- `iterations/007/state.md` (end-of-iteration summary)
- `iterations/007/scope.md` (bug-by-bug closure + deferred list)
- `iterations/007/drift-log.md` (2 in-flight drifts captured)
- `iterations/007/code-map.md` (this file)
- `iterations/007/review.md` (task verdicts + verification evidence)
- `iterations/007/retro.md` (variance + methodology lessons + carry-over)

## Test surface

| Test file | Assertions added | Total now |
|---|---|---|
| `tests/integration/multi-host-lifecycle-smoke.tests.ps1` | +3 (Tests 8, 9, 10) | 10 |
| `tests/integration/bootstrap-to-iteration.ps1` | 0 (assertion repair only) | unchanged |

## Tests run + verdicts

- 12/12 CI integration tests PASS
- 8/8 host-related integration tests PASS
- 7/7 validator iterations PASS
- 0 PSScriptAnalyzer Error-severity violations on 3 touched .ps1 files
- 0 markdownlint violations across 72 branch-changed .md files

# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-11
**Baseline Ref**: 58f5691
**Test-to-Code Ratio**: 5:1

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| `.specrew/quality/known-traps.md` | 1 | 0 | Iteration governance | Governance maintainer |
| `scripts/specrew-start.ps1` | 99 | 1 | T032-T036, T041 | Script maintainer |
| `specs/011-specrew-start-conditional-pause/iterations/001/drift-log.md` | 3 | 7 | Iteration governance | Governance maintainer |
| `specs/011-specrew-start-conditional-pause/iterations/001/plan.md` | 20 | 18 | T031, Review gate | Governance maintainer |
| `specs/011-specrew-start-conditional-pause/iterations/001/review.md` | 70 | 0 | Review gate | Reviewer |
| `specs/011-specrew-start-conditional-pause/iterations/001/state.md` | 48 | 27 | Iteration governance | Governance maintainer |
| `tests/integration/fixtures/specrew-start-detector/bootstrap/.gitkeep` | 2 | 0 | T030 | Test infrastructure maintainer |
| `tests/integration/fixtures/specrew-start-detector/with-changes/.gitkeep` | 2 | 0 | T030 | Test infrastructure maintainer |
| `tests/integration/specrew-start-auto-continue-preservation.ps1` | 136 | 0 | T039 | Test infrastructure maintainer |
| `tests/integration/specrew-start-baseline-tracking.ps1` | 135 | 0 | T040 | Test infrastructure maintainer |
| `tests/integration/specrew-start-change-detector.ps1` | 117 | 0 | T038 | Test infrastructure maintainer |

## Public-API Delta

### Added

- `Get-BaselineCommitHash` (`scripts/specrew-start.ps1`)
- `Test-SessionLoadedFilesChanged` (`scripts/specrew-start.ps1`)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none

# Code Map: Iteration 010

**Schema**: v1
**Reviewed**: 2026-05-07
**Baseline Ref**: e946390c0fbb404f39e29a20b9cd401730a688f1
**Test-to-Code Ratio**: 6:1

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .github/workflows/specrew-ci.yml | 28 | 2 | T-1001, T-1002, T-1003 | Planner |
| .github/workflows/specrew-confidence-lane.yml | 43 | 0 | T-1001, T-1002, T-1003 | Planner |
| evaluation/README.md | 2 | 2 | T-1001, T-1002, T-1003 | Planner |
| extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 | 29 | 3 | T-1001, T-1002, T-1003 | Planner |
| specs/001-specrew-product/iterations/010/drift-log.md | 21 | 0 | T-1001, T-1002, T-1003 | Planner |
| specs/001-specrew-product/iterations/010/plan.md | 94 | 0 | T-1001, T-1002, T-1003 | Planner |
| specs/001-specrew-product/iterations/010/retro.md | 58 | 0 | T-1001, T-1002, T-1003 | Planner |
| specs/001-specrew-product/iterations/010/review.md | 28 | 0 | T-1001, T-1002, T-1003 | Planner |
| specs/001-specrew-product/iterations/010/state.md | 25 | 0 | T-1001, T-1002, T-1003 | Planner |
| specs/001-specrew-product/plan.md | 3 | 3 | T-1001, T-1002, T-1003 | Planner |
| specs/001-specrew-product/spec.md | 3 | 3 | T-1002, T-1004 | Implementer |
| tests/README.md | 21 | 2 | T-1002, T-1004 | Implementer |
| tests/integration/lifecycle-trace-contract.ps1 | 101 | 0 | T-1002, T-1004 | Implementer |
| tests/integration/start-command.ps1 | 3 | 1 | T-1002, T-1004 | Implementer |
| tests/integration/validation-contract-lane.ps1 | 43 | 0 | T-1002, T-1004 | Implementer |
| tests/manual/copilot-squad-confidence-lane.ps1 | 165 | 0 | T-1002, T-1004 | Implementer |

## Public-API Delta

### Added

- Write-Pass (tests/integration/lifecycle-trace-contract.ps1)
- Write-Fail (tests/integration/lifecycle-trace-contract.ps1)
- Invoke-LaneScript (tests/integration/validation-contract-lane.ps1)
- Write-Pass (tests/manual/copilot-squad-confidence-lane.ps1)
- Write-Fail (tests/manual/copilot-squad-confidence-lane.ps1)
- Write-Info (tests/manual/copilot-squad-confidence-lane.ps1)
- Get-RelativePathSafe (tests/manual/copilot-squad-confidence-lane.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none

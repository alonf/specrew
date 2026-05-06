# Code Map: Iteration 009

**Schema**: v1
**Reviewed**: 2026-05-07
**Baseline Ref**: 8bcb28f961202086d89ea44726e2f2642d7792a4
**Test-to-Code Ratio**: 2:1

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| extensions/specrew-speckit/scripts/validate-governance.ps1 | 152 | 2 | T-902, T-903 | Planner |
| specs/001-specrew-product/contracts/iteration-artifacts.md | 19 | 1 | T-902, T-903 | Planner |
| specs/001-specrew-product/current-architecture.md | 1 | 1 | T-902, T-903 | Planner |
| specs/001-specrew-product/iterations/009/drift-log.md | 21 | 0 | T-902, T-903 | Planner |
| specs/001-specrew-product/iterations/009/plan.md | 96 | 0 | T-902, T-903 | Planner |
| specs/001-specrew-product/iterations/009/retro.md | 58 | 0 | T-902, T-903 | Planner |
| specs/001-specrew-product/iterations/009/review.md | 28 | 0 | T-902, T-903 | Planner |
| specs/001-specrew-product/iterations/009/state.md | 24 | 0 | T-902, T-903 | Planner |
| tests/integration/gap-governance.ps1 | 8 | 8 | T-901, T-902, T-903, T-904 | Reviewer |
| tests/integration/reviewer-closeout-governance.ps1 | 311 | 0 | T-901, T-902, T-903, T-904 | Reviewer |

## Public-API Delta

### Added

- Test-IsManifestPath (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-IsReviewerSourcePath (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-ReviewerCloseoutDiffArtifacts (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ReviewerCloseoutArtifacts (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-ReviewerCloseoutEnforcementMap (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Write-Pass (tests/integration/reviewer-closeout-governance.ps1)
- Write-Fail (tests/integration/reviewer-closeout-governance.ps1)
- loadMessage (tests/integration/reviewer-closeout-governance.ps1)
- loadAdminMessage (tests/integration/reviewer-closeout-governance.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- tests/integration/reviewer-closeout-governance.ps1 (311 changed lines)
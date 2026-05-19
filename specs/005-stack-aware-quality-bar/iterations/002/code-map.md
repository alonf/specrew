# Code Map: Iteration 002

**Schema**: v1
**Reviewed**: 2026-05-08
**Baseline Ref**: c87f204c39463eb765a819a7cc56b9416dd925b7
**Test-to-Code Ratio**: 0:1

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 | 332 | 2 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/current-architecture.md | 7 | 7 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/002/code-map.md | 63 | 0 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/002/coverage-evidence.md | 34 | 0 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/002/dependency-report.md | 24 | 0 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/002/plan.md | 47 | 25 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/002/quality/mechanical-findings.json | 11 | 0 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/002/quality/quality-evidence.md | 17 | 0 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/002/review-diagrams.md | 21 | 0 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/002/review.md | 28 | 0 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/002/reviewer-index.md | 56 | 0 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/002/state.md | 12 | 8 | T014 | Implementer |

## Public-API Delta

### Added

- Normalize-MarkdownCell (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-GateRowId (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-RepoRelativePath (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-DefaultRequirementRefsForGate (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Resolve-QualityEvidenceSource (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-DefaultQualityGateRows (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-ExistingQualityEvidenceState (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-QualityEvidenceContent (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-MechanicalFindingsScaffoldJson (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 (334 changed lines)

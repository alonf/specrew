# Code Map: Iteration 002

**Schema**: v1
**Reviewed**: 2026-05-08
**Baseline Ref**: c87f204c39463eb765a819a7cc56b9416dd925b7
**Test-to-Code Ratio**: 2:3

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .claude/settings.local.json | 10 | 1 | T014 | Implementer |
| .squad/agents/planner/history.md | 10 | 1 | T014 | Implementer |
| .squad/agents/reviewer/history.md | 2 | 0 | T014 | Implementer |
| .squad/skills/iteration-governance-readiness-review/SKILL.md | 1 | 0 | T014 | Implementer |
| extensions/specrew-speckit/README.md | 9 | 1 | T014 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1 | 222 | 2 | T014 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 | 332 | 2 | T014 | Implementer |
| extensions/specrew-speckit/scripts/validate-governance.ps1 | 268 | 0 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/002/plan.md | 47 | 25 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/002/state.md | 12 | 8 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/quickstart.md | 17 | 5 | T014 | Implementer |
| specs/005-stack-aware-quality-bar/tasks.md | 7 | 7 | T014 | Implementer |
| tests/integration/process-quality-report.ps1 | 69 | 0 | T012, T013, T014, T015, T016, T017 | Reviewer |
| tests/integration/process-quality-scorer.ps1 | 74 | 0 | T012, T013, T014, T015, T016, T017 | Reviewer |

## Public-API Delta

### Added

- Get-MarkdownMetadataValue (extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1)
- Normalize-MarkdownCell (extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1)
- Convert-ToRepoRelativePath (extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1)
- Get-DefaultRequirementRefsForGate (extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1)
- Resolve-QualityEvidenceSource (extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1)
- Get-DefaultQualityGateRows (extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1)
- Get-QualityEvidenceContent (extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1)
- Get-MechanicalFindingsScaffoldJson (extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1)
- Normalize-MarkdownCell (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-GateRowId (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-RepoRelativePath (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-DefaultRequirementRefsForGate (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Resolve-QualityEvidenceSource (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-DefaultQualityGateRows (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-ExistingQualityEvidenceState (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-QualityEvidenceContent (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-MechanicalFindingsScaffoldJson (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Normalize-MarkdownCell (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-MarkdownSectionTableAnyLevel (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-Phase1RequiredQualityGateRows (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-QualityEvidenceRowMap (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-MechanicalFindingsByGate (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-Phase1QualityEvidence (extensions/specrew-speckit/scripts/validate-governance.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 (334 changed lines)
- extensions/specrew-speckit/scripts/validate-governance.ps1 (268 changed lines)
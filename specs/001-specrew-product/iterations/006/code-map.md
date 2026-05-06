# Code Map: Iteration 006

**Schema**: v1
**Reviewed**: 2026-05-06
**Baseline Ref**: 9b5511f82b73cc9859abc618bb5a395e34663478
**Test-to-Code Ratio**: 1:2

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| extensions/specrew-speckit/README.md | 1 | 1 | T-601, T-602 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 | 460 | 7 | T-601, T-602 | Implementer |
| tests/integration/reviewer-artifacts.ps1 | 66 | 15 | T-602, T-603, T-604 | Implementer |

## Public-API Delta

### Added

- Convert-WildcardToRegex (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-ChangedCodeFiles (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-ModuleIdFromPath (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-ModuleLabel (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Resolve-ModuleReference (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-ModuleGraphEvidence (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-SecurityRoles (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-SecurityTriggerContext (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-SensitiveTouchpoints (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-VulnerabilityHighlights (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-DiagramEvidence (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- getOldValue (tests/integration/reviewer-artifacts.ps1)
- maskToken (tests/integration/reviewer-artifacts.ps1)
- getNewValue (tests/integration/reviewer-artifacts.ps1)

### Removed

- Get-OldValue (tests/integration/reviewer-artifacts.ps1)
- Get-NewValue (tests/integration/reviewer-artifacts.ps1)

## Module Hotspots

- Threshold: 250 changed lines per file
- extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 (467 changed lines)
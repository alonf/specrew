# Code Map: Iteration 007

**Schema**: v1
**Reviewed**: 2026-05-06
**Baseline Ref**: 598eb92b795676e3d8787ffc67a2623ce56e4db9
**Test-to-Code Ratio**: 2:4

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| extensions/specrew-speckit/scripts/manage-escalation-state.ps1 | 2 | 1 | T-701, T-704 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 | 60 | 6 | T-701, T-704 | Implementer |
| extensions/specrew-speckit/scripts/shared-governance.ps1 | 138 | 0 | T-701, T-704 | Implementer |
| extensions/specrew-speckit/scripts/validate-governance.ps1 | 127 | 3 | T-701, T-704 | Implementer |
| scripts/specrew-start.ps1 | 14 | 0 | T-702, T-703, T-704 | Reviewer |
| specs/001-specrew-product/current-architecture.md | 7 | 7 | T-702, T-703, T-704 | Reviewer |

## Public-API Delta

### Added

- Get-ActiveGapLedgerConcerns (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-RoutingFallbackCount (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-DecisionLedgerOptionalValue (extensions/specrew-speckit/scripts/shared-governance.ps1)
- New-DecisionsLedgerEntryId (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Add-StructuredDecisionsLedgerEntry (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-DecisionsLedgerEntries (extensions/specrew-speckit/scripts/shared-governance.ps1)
- New-DecisionsLedgerParsedEntry (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-ActiveGapLedgerLines (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-NoGapClosurePolicy (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-MarkdownSectionLines (extensions/specrew-speckit/scripts/validate-governance.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none
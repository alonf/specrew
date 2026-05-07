# Code Map: Iteration 011

**Schema**: v1
**Reviewed**: 2026-05-07
**Baseline Ref**: 0440f16f475a9ff4d06b0cb372111aa62069588e
**Test-to-Code Ratio**: 2:1

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .claude/settings.local.json | 11 | 1 | T-1102, T-1103 | Implementer |
| .specify/feature.json | 1 | 1 | T-1102, T-1103 | Implementer |
| .specrew/iteration-config.yml | 2 | 0 | T-1102, T-1103 | Implementer |
| .squad/decisions.md | 116 | 0 | T-1102, T-1103 | Implementer |
| extensions/specrew-speckit/scripts/validate-governance.ps1 | 50 | 4 | T-1102, T-1103 | Implementer |
| specs/001-specrew-product/plan.md | 4 | 2 | T-1102, T-1103 | Implementer |
| specs/001-specrew-product/spec.md | 4 | 2 | T-1101, T-1102 | Reviewer |
| tests/integration/reviewer-closeout-governance.ps1 | 152 | 10 | T-1101, T-1102 | Reviewer |

## Public-API Delta

### Added

- Get-IterationOrdinal (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-IterationMeetsCloseoutCutoff (extensions/specrew-speckit/scripts/validate-governance.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none
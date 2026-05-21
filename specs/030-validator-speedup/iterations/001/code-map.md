# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-21T23:42:44Z
**Baseline Ref**: edf4104
**Test-to-Code Ratio**: 1:4

> **Review Packet Note**
>
> Iteration 001 uses four semantic review slices across eleven changed files in the locked implementation range `edf4104...eeeb90e`.
> That grouping is intentional for review-boundary traceability and does not represent a form-vs-meaning gap.

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/extensions/specrew-speckit/scripts/shared-governance.ps1 | 103 | 38 | validator-auto-scope-core, governance-doc-sync, mirror-parity-audit | Implementer |
| .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 | 164 | 23 | validator-auto-scope-core, governance-doc-sync, mirror-parity-audit | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md | 1 | 0 | validator-auto-scope-core, governance-doc-sync, mirror-parity-audit | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md | 3 | 1 | validator-auto-scope-core, governance-doc-sync, mirror-parity-audit | Implementer |
| CHANGELOG.md | 1 | 0 | validator-auto-scope-core, governance-doc-sync, mirror-parity-audit | Implementer |
| extensions/specrew-speckit/scripts/shared-governance.ps1 | 103 | 38 | validator-auto-scope-core, governance-doc-sync, mirror-parity-audit | Implementer |
| extensions/specrew-speckit/scripts/validate-governance.ps1 | 164 | 23 | validator-auto-scope-core, governance-doc-sync, mirror-parity-audit | Implementer |
| extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md | 1 | 0 | validator-auto-scope-core, governance-doc-sync, mirror-parity-audit | Implementer |
| extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md | 3 | 1 | validator-auto-scope-core, governance-doc-sync, mirror-parity-audit | Implementer |
| specs/030-validator-speedup/tasks.md | 14 | 14 | validator-auto-scope-core, governance-doc-sync, mirror-parity-audit | Implementer |
| tests/integration/validate-governance-changed-only.tests.ps1 | 164 | 28 | governance-doc-sync, integration-regression-coverage, mirror-parity-audit | Implementer |

## Public-API Delta

### Added

- Resolve-SpecrewGitBaseRefCandidate (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewLocalScopeBaseRef (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-GitCurrentBranchName (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-ValidatorScopeReasonText (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-ValidatorScopeBanner (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Resolve-SpecrewGitBaseRefCandidate (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewLocalScopeBaseRef (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-GitCurrentBranchName (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-ValidatorScopeReasonText (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-ValidatorScopeBanner (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Assert-FirstLineMatch (tests/integration/validate-governance-changed-only.tests.ps1)
- Remove-OriginRemote (tests/integration/validate-governance-changed-only.tests.ps1)
- Remove-OriginHeadTrackingRef (tests/integration/validate-governance-changed-only.tests.ps1)
- Checkout-MainBranch (tests/integration/validate-governance-changed-only.tests.ps1)
- Checkout-DetachedHead (tests/integration/validate-governance-changed-only.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none
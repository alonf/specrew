# Code Map: Iteration 001

**Schema**: v1
**Reviewed**:
**Baseline Ref**: a135e11dd3ab7983d2f2fa8438303cbd279443ee
**Test-to-Code Ratio**: 8:8

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1 | 8 | 22 | I1-W002, I1-W003, I1-W004 | Implementer |
| .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1 | 12 | 6 | I1-W002, I1-W003, I1-W004 | Implementer |
| .squad/decisions.md | 132 | 0 | I1-W002, I1-W003, I1-W004 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1 | 8 | 22 | I1-W002, I1-W003, I1-W004 | Implementer |
| extensions/specrew-speckit/scripts/sync-boundary-state.ps1 | 12 | 6 | I1-W002, I1-W003, I1-W004 | Implementer |
| scripts/internal/coordinator-resume.ps1 | 42 | 0 | I1-W002, I1-W003, I1-W004 | Implementer |
| scripts/internal/sync-boundary-state.ps1 | 134 | 14 | I1-W002, I1-W003, I1-W004 | Implementer |
| scripts/specrew-review.ps1 | 29 | 0 | I1-W002, I1-W003, I1-W004 | Implementer |
| scripts/specrew-start.ps1 | 293 | 16 | I1-W002, I1-W003, I1-W004 | Implementer |
| specs/022-hotfix-schema-tests/iterations/001/drift-log.md | 4 | 4 | I1-W002, I1-W003, I1-W004 | Implementer |
| specs/022-hotfix-schema-tests/iterations/001/plan.md | 20 | 14 | I1-W002, I1-W003, I1-W004 | Implementer |
| specs/022-hotfix-schema-tests/iterations/001/quality/hardening-gate.md | 45 | 30 | I1-W002, I1-W003, I1-W004 | Implementer |
| specs/022-hotfix-schema-tests/iterations/001/retro.md | 75 | 0 | I1-W002, I1-W003, I1-W004 | Implementer |
| specs/022-hotfix-schema-tests/iterations/001/review.md | 71 | 0 | I1-W002, I1-W003, I1-W004 | Implementer |
| specs/022-hotfix-schema-tests/iterations/001/state.md | 22 | 13 | I1-W002, I1-W003, I1-W004 | Implementer |
| specs/022-hotfix-schema-tests/tasks.md | 16 | 16 | I1-W002, I1-W003, I1-W004 | Implementer |
| tests/README.md | 6 | 0 | I1-W005 | Reviewer |
| tests/integration/boundary-sync-atomicity.tests.ps1 | 12 | 10 | I1-W005 | Reviewer |
| tests/integration/closeout-identity-schema-parity.tests.ps1 | 108 | 0 | I1-W005 | Reviewer |
| tests/integration/lifecycle-boundary-sync.tests.ps1 | 138 | 0 | I1-W005 | Reviewer |
| tests/integration/review-command.ps1 | 6 | 2 | I1-W005 | Reviewer |
| tests/integration/stale-state-detection.tests.ps1 | 33 | 40 | I1-W005 | Reviewer |
| tests/integration/start-command.ps1 | 11 | 7 | I1-W005 | Reviewer |
| tests/integration/start-recovery-flow.tests.ps1 | 159 | 0 | I1-W005 | Reviewer |

## Public-API Delta

### Added

- Get-FeatureCloseoutIdentityBody (.specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1)
- Get-FeatureCloseoutIdentityBody (extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1)
- Get-CoordinatorRecoveryPromptBlock (scripts/internal/coordinator-resume.ps1)
- Get-SpecrewBoundaryOrder (scripts/internal/sync-boundary-state.ps1)
- Resolve-SpecrewBoundaryAuthCommitHash (scripts/internal/sync-boundary-state.ps1)
- Add-SpecrewBoundarySyncWarningLedgerEntry (scripts/internal/sync-boundary-state.ps1)
- Get-ReviewBoundarySyncWarning (scripts/specrew-review.ps1)
- Get-SpecrewLatestIterationDirectory (scripts/specrew-start.ps1)
- Get-SpecrewMetadataValueFromFile (scripts/specrew-start.ps1)
- Get-SpecrewLateBoundaryIssues (scripts/specrew-start.ps1)
- Read-SpecrewRecoveryChoice (scripts/specrew-start.ps1)
- New-SpecrewRecoverySession (scripts/specrew-start.ps1)
- Resolve-SpecrewRecoverySelection (scripts/specrew-start.ps1)
- Write-Pass (tests/integration/closeout-identity-schema-parity.tests.ps1)
- Write-Fail (tests/integration/closeout-identity-schema-parity.tests.ps1)
- Invoke-TestScript (tests/integration/closeout-identity-schema-parity.tests.ps1)
- New-MinimalProject (tests/integration/closeout-identity-schema-parity.tests.ps1)
- Write-Pass (tests/integration/lifecycle-boundary-sync.tests.ps1)
- Write-Fail (tests/integration/lifecycle-boundary-sync.tests.ps1)
- Invoke-TestScript (tests/integration/lifecycle-boundary-sync.tests.ps1)
- New-MinimalProject (tests/integration/lifecycle-boundary-sync.tests.ps1)
- Write-Pass (tests/integration/start-recovery-flow.tests.ps1)
- Write-Fail (tests/integration/start-recovery-flow.tests.ps1)
- Invoke-TestScript (tests/integration/start-recovery-flow.tests.ps1)
- Invoke-InteractiveStart (tests/integration/start-recovery-flow.tests.ps1)
- New-MinimalProject (tests/integration/start-recovery-flow.tests.ps1)
- New-StaleProject (tests/integration/start-recovery-flow.tests.ps1)

### Removed

- Set-FeatureCloseoutIdentityNow (.specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1)
- Set-FeatureCloseoutIdentityNow (extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1)

## Module Hotspots

- Threshold: 250 changed lines per file
- scripts/specrew-start.ps1 (309 changed lines)

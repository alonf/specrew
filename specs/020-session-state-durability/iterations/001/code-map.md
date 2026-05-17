# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-18T02:02:12+03:00
**Baseline Ref**: 0e90d1f
**Test-to-Code Ratio**: 3:6

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/extensions.yml | 28 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-clarify.md | 15 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-plan.md | 15 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-specify.md | 15 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-tasks.md | 19 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| .specify/extensions/specrew-speckit/extension.yml | 12 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1 | 6 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1 | 50 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/ceremonies/retro.md | 10 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/ceremonies/review-demo.md | 10 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| .squad/decisions.md | 6507 | 6277 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| .squad/decisions/inbox/2026-05-17-implementer-sync-boundary-state-head.txt | 1 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| .squad/identity/now.md | 3 | 3 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| Specrew.psd1 | 6 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-clarify.md | 15 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-plan.md | 15 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-specify.md | 15 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-tasks.md | 19 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| extensions/specrew-speckit/extension.yml | 12 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1 | 6 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| extensions/specrew-speckit/scripts/sync-boundary-state.ps1 | 50 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| extensions/specrew-speckit/squad-templates/ceremonies/retro.md | 10 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| extensions/specrew-speckit/squad-templates/ceremonies/review-demo.md | 10 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| scripts/internal/sync-boundary-state.ps1 | 563 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| scripts/specrew-start.ps1 | 381 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| specs/020-session-state-durability/contracts/sync-boundary-state-api.md | 37 | 250 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| specs/020-session-state-durability/iterations/001/DECISION-INBOX-DRAFT.md | 39 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| specs/020-session-state-durability/iterations/001/drift-log.md | 39 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| specs/020-session-state-durability/iterations/001/plan.md | 77 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| specs/020-session-state-durability/iterations/001/review.md | 62 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| specs/020-session-state-durability/iterations/001/state.md | 51 | 0 | I1-T001, I1-T002, I1-T003, I1-T004, I1-T006, I1-T007, I1-T008, I1-T009, I1-T010, I1-T012, I1-T013 | Implementer |
| tests/integration/boundary-sync-atomicity.tests.ps1 | 128 | 0 | I1-T005, I1-T011, I1-T014 | Reviewer |
| tests/integration/stale-state-detection.tests.ps1 | 154 | 0 | I1-T005, I1-T011, I1-T014 | Reviewer |
| tests/integration/version-checks.tests.ps1 | 87 | 0 | I1-T005, I1-T011, I1-T014 | Reviewer |

## Public-API Delta

### Added

- Get-SpecrewSessionStatePaths (scripts/internal/sync-boundary-state.ps1)
- ConvertTo-SpecrewFrontmatterValue (scripts/internal/sync-boundary-state.ps1)
- ConvertFrom-SpecrewFrontmatter (scripts/internal/sync-boundary-state.ps1)
- New-SpecrewMarkdownContent (scripts/internal/sync-boundary-state.ps1)
- Get-SpecrewSessionStateFromFrontmatter (scripts/internal/sync-boundary-state.ps1)
- Resolve-SpecrewFeatureRef (scripts/internal/sync-boundary-state.ps1)
- Resolve-SpecrewFeatureDirectory (scripts/internal/sync-boundary-state.ps1)
- Get-SpecrewFeatureNumber (scripts/internal/sync-boundary-state.ps1)
- New-SpecrewSessionState (scripts/internal/sync-boundary-state.ps1)
- Get-SpecrewPromptBody (scripts/internal/sync-boundary-state.ps1)
- Get-SpecrewIdentityBody (scripts/internal/sync-boundary-state.ps1)
- Update-SpecrewMarkdownStateFile (scripts/internal/sync-boundary-state.ps1)
- Write-FileAtomically (scripts/internal/sync-boundary-state.ps1)
- Update-SpecrewStartContext (scripts/internal/sync-boundary-state.ps1)
- Clear-SpecrewActiveFeature (scripts/internal/sync-boundary-state.ps1)
- Add-SpecrewBoundarySyncLedgerEntry (scripts/internal/sync-boundary-state.ps1)
- Get-LatestSpecrewBoundarySyncState (scripts/internal/sync-boundary-state.ps1)
- Invoke-SpecrewBoundaryStateSync (scripts/internal/sync-boundary-state.ps1)
- Get-SpecrewConfigValue (scripts/specrew-start.ps1)
- Get-InstalledSpecrewVersion (scripts/specrew-start.ps1)
- Get-SpecrewVersionMismatchWarning (scripts/specrew-start.ps1)
- Get-SpecrewPromptSessionState (scripts/specrew-start.ps1)
- Get-SpecrewIdentitySessionState (scripts/specrew-start.ps1)
- Get-SpecrewStartContextSessionState (scripts/specrew-start.ps1)
- Get-SpecrewSessionStateSnapshot (scripts/specrew-start.ps1)
- Test-SpecrewFeatureMergedToMain (scripts/specrew-start.ps1)
- Test-SpecrewFeatureBranchExists (scripts/specrew-start.ps1)
- Test-SpecrewAuthorizationRecord (scripts/specrew-start.ps1)
- Test-SpecrewSessionStateConsistency (scripts/specrew-start.ps1)
- Test-SpecrewStaleSessionState (scripts/specrew-start.ps1)
- Write-Pass (tests/integration/boundary-sync-atomicity.tests.ps1)
- Write-Fail (tests/integration/boundary-sync-atomicity.tests.ps1)
- Invoke-TestScript (tests/integration/boundary-sync-atomicity.tests.ps1)
- Write-Pass (tests/integration/stale-state-detection.tests.ps1)
- Write-Fail (tests/integration/stale-state-detection.tests.ps1)
- Invoke-TestScript (tests/integration/stale-state-detection.tests.ps1)
- New-TestProject (tests/integration/stale-state-detection.tests.ps1)
- Sync-PlanBoundary (tests/integration/stale-state-detection.tests.ps1)
- Write-Pass (tests/integration/version-checks.tests.ps1)
- Write-Fail (tests/integration/version-checks.tests.ps1)
- Invoke-TestScript (tests/integration/version-checks.tests.ps1)
- Set-SpecrewVersion (tests/integration/version-checks.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- .squad/decisions.md (12784 changed lines)
- scripts/internal/sync-boundary-state.ps1 (563 changed lines)
- scripts/specrew-start.ps1 (381 changed lines)
- specs/020-session-state-durability/contracts/sync-boundary-state-api.md (287 changed lines)
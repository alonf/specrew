# Code Map: Iteration 002

**Schema**: v1
**Reviewed**: 2026-05-18T01:05:21Z
**Baseline Ref**: d2cf2a38362e1707a1c6c583a7ef5f15b6563148
**Test-to-Code Ratio**: 3:8

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .squad/decisions.md | 267 | 0 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| .squad/identity/now.md | 34 | 13 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| scripts/internal/coordinator-resume.ps1 | 228 | 0 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| scripts/internal/task-progress.ps1 | 480 | 0 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| scripts/internal/version-check.ps1 | 271 | 0 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| scripts/internal/worktree-awareness.ps1 | 199 | 0 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| scripts/specrew-init.ps1 | 20 | 0 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| scripts/specrew-start.ps1 | 44 | 2 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| scripts/specrew-update.ps1 | 21 | 0 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| scripts/specrew-where.ps1 | 72 | 0 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| specs/020-session-state-durability/contracts/session-state-schema.yml | 35 | 6 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| specs/020-session-state-durability/contracts/welcome-back-prompt.md | 26 | 0 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| specs/020-session-state-durability/iterations/002/drift-log.md | 42 | 0 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| specs/020-session-state-durability/iterations/002/plan.md | 116 | 0 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| specs/020-session-state-durability/iterations/002/review.md | 78 | 0 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| specs/020-session-state-durability/iterations/002/state.md | 38 | 0 | I2-T001, I2-T002, I2-T003, I2-T005, I2-T006, I2-T007, I2-T009, I2-T010, I2-T011, I2-T013, I2-T014, I2-T015, I2-T016 | Implementer |
| tests/integration/cross-worktree-awareness.tests.ps1 | 115 | 0 | I2-T004, I2-T008, I2-T012, I2-T013, I2-T017 | Reviewer |
| tests/integration/psgallery-check.tests.ps1 | 105 | 0 | I2-T004, I2-T008, I2-T012, I2-T013, I2-T017 | Reviewer |
| tests/integration/task-progress-tracking.tests.ps1 | 127 | 0 | I2-T004, I2-T008, I2-T012, I2-T013, I2-T017 | Reviewer |

## Public-API Delta

### Added

- Get-ValidatorSummaryPath (scripts/internal/coordinator-resume.ps1)
- Get-ValidatorWarningSummary (scripts/internal/coordinator-resume.ps1)
- Resolve-ResumeIterationNumber (scripts/internal/coordinator-resume.ps1)
- Get-CoordinatorResumeSnapshot (scripts/internal/coordinator-resume.ps1)
- Get-CoordinatorResumePromptBlock (scripts/internal/coordinator-resume.ps1)
- Get-TaskProgressMarkdownContent (scripts/internal/task-progress.ps1)
- Get-TaskProgressMarkdownSectionTable (scripts/internal/task-progress.ps1)
- Get-SpecrewYamlScalarValue (scripts/internal/task-progress.ps1)
- ConvertTo-SpecrewYamlScalar (scripts/internal/task-progress.ps1)
- Resolve-TaskProgressFeatureRef (scripts/internal/task-progress.ps1)
- Get-IterationTaskProgressPath (scripts/internal/task-progress.ps1)
- Get-IterationPlanPath (scripts/internal/task-progress.ps1)
- Get-IterationTaskCatalog (scripts/internal/task-progress.ps1)
- New-TaskProgressEntry (scripts/internal/task-progress.ps1)
- Get-TaskProgressState (scripts/internal/task-progress.ps1)
- ConvertTo-TaskProgressContent (scripts/internal/task-progress.ps1)
- Sync-IterationTaskProgress (scripts/internal/task-progress.ps1)
- Set-TaskStatus (scripts/internal/task-progress.ps1)
- Set-TaskComplete (scripts/internal/task-progress.ps1)
- Set-TaskBlocked (scripts/internal/task-progress.ps1)
- Get-TaskProgressSummary (scripts/internal/task-progress.ps1)
- Get-SpecrewVersionConfigValue (scripts/internal/version-check.ps1)
- Get-SpecrewInstalledVersion (scripts/internal/version-check.ps1)
- ConvertTo-SpecrewSemanticVersion (scripts/internal/version-check.ps1)
- Get-SpecrewVersionCheckCachePath (scripts/internal/version-check.ps1)
- Test-SpecrewSkipUpdateCheck (scripts/internal/version-check.ps1)
- Get-SpecrewVersionCheckCacheState (scripts/internal/version-check.ps1)
- Set-SpecrewVersionCheckCacheState (scripts/internal/version-check.ps1)
- Test-SpecrewVersionCacheValid (scripts/internal/version-check.ps1)
- Invoke-SpecrewPSGalleryLatestVersionQuery (scripts/internal/version-check.ps1)
- Get-PSGalleryLatestVersion (scripts/internal/version-check.ps1)
- Get-PSGalleryUpdateWarning (scripts/internal/version-check.ps1)
- ConvertFrom-SpecrewFrontmatterBlock (scripts/internal/worktree-awareness.ps1)
- Get-WorktreeSessionState (scripts/internal/worktree-awareness.ps1)
- Get-WorktreeFeatureRef (scripts/internal/worktree-awareness.ps1)
- Get-WorktreeBoundarySummary (scripts/internal/worktree-awareness.ps1)
- Get-WorktreeFeatureNumber (scripts/internal/worktree-awareness.ps1)
- Get-WorktreeRecords (scripts/internal/worktree-awareness.ps1)
- Get-WorktreeState (scripts/internal/worktree-awareness.ps1)
- ConvertTo-SpecrewWorktreeLines (scripts/specrew-where.ps1)
- ConvertTo-SpecrewWorktreePayload (scripts/specrew-where.ps1)
- Write-Pass (tests/integration/cross-worktree-awareness.tests.ps1)
- Write-Fail (tests/integration/cross-worktree-awareness.tests.ps1)
- New-WorktreePrompt (tests/integration/cross-worktree-awareness.tests.ps1)
- Invoke-TestScript (tests/integration/cross-worktree-awareness.tests.ps1)
- Write-Pass (tests/integration/psgallery-check.tests.ps1)
- Write-Fail (tests/integration/psgallery-check.tests.ps1)
- Invoke-TestScript (tests/integration/psgallery-check.tests.ps1)
- Write-Pass (tests/integration/task-progress-tracking.tests.ps1)
- Write-Fail (tests/integration/task-progress-tracking.tests.ps1)
- Invoke-TestScript (tests/integration/task-progress-tracking.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- .squad/decisions.md (267 changed lines)
- scripts/internal/task-progress.ps1 (480 changed lines)
- scripts/internal/version-check.ps1 (271 changed lines)

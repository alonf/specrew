# Code Map: Iteration 001

**Schema**: v1
**Reviewed**:
**Baseline Ref**: 4ff6a949b5d39ebcbe64090fc3487e1073f68d74
**Test-to-Code Ratio**: 17:14

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .github/workflows/specrew-ci.yml | 4 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| .specify/extensions/specrew-speckit/extension.yml | 1 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| .specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1 | 9 | 3 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| .specify/extensions/specrew-speckit/scripts/scaffold-governance.ps1 | 12 | 4 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| .specify/extensions/specrew-speckit/scripts/shared-governance.ps1 | 83 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 | 197 | 9 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| .specify/templates/closeout-template.md | 24 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| .squad/agents/retro-facilitator/history.md | 17 | 1 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| .squad/agents/reviewer/history.md | 2 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| .squad/decisions.md | 85 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| docs/data-contracts.md | 47 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| extensions/specrew-speckit/extension.yml | 1 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1 | 9 | 3 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-governance.ps1 | 12 | 4 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| extensions/specrew-speckit/scripts/shared-governance.ps1 | 83 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| extensions/specrew-speckit/scripts/validate-governance.ps1 | 156 | 8 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| scripts/internal/coordinator-resume.ps1 | 18 | 8 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| scripts/internal/sync-boundary-state.ps1 | 35 | 12 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| scripts/internal/version-check.ps1 | 12 | 1 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| scripts/internal/worktree-awareness.ps1 | 13 | 3 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| scripts/specrew-start.ps1 | 27 | 6 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| scripts/specrew-update.ps1 | 1 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| specs/023-legacy-state-read-tolerance/checklists/state-reader-audit.md | 231 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| specs/023-legacy-state-read-tolerance/iterations/{1 => 001}/drift-log.md | 3 | 3 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| specs/023-legacy-state-read-tolerance/iterations/001/plan.md | 84 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| specs/023-legacy-state-read-tolerance/iterations/001/quality/hardening-gate.md | 35 | 187 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| specs/023-legacy-state-read-tolerance/iterations/001/quality/quality-evidence.md | 3 | 3 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| specs/023-legacy-state-read-tolerance/iterations/001/retro.md | 110 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| specs/023-legacy-state-read-tolerance/iterations/001/review.md | 128 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| specs/023-legacy-state-read-tolerance/iterations/001/state.md | 63 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| specs/023-legacy-state-read-tolerance/iterations/1/state.md | 0 | 33 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| specs/023-legacy-state-read-tolerance/tasks.md | 34 | 34 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| templates/specify/templates/closeout-template.md | 24 | 0 | T009-T014, T021-T024, T025-T027, T029, T031 | Implementer |
| tests/fixtures/legacy-versions/0.18.0/.specify/feature.json | 6 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/fixtures/legacy-versions/0.18.0/.specrew/config.yml | 3 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/fixtures/legacy-versions/0.18.0/.specrew/start-context.json | 8 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/fixtures/legacy-versions/0.19.0/.specify/feature.json | 5 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/fixtures/legacy-versions/0.19.0/.specrew/config.yml | 3 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/fixtures/legacy-versions/0.19.0/.specrew/start-context.json | 4 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/fixtures/legacy-versions/0.20.0/.specrew/config.yml | 4 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/fixtures/legacy-versions/0.21.0/tasks-progress.yml | 7 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/fixtures/legacy-versions/0.22.0/.specrew/last-validator-summary.json | 10 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/fixtures/legacy-versions/0.23.0/.specify/extensions/specrew-speckit/extension.yml | 8 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/fixtures/legacy-versions/0.23.0/.specify/feature.json | 7 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/fixtures/legacy-versions/0.23.0/.specrew/config.yml | 5 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/fixtures/legacy-versions/0.23.0/.specrew/last-validator-summary.json | 11 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/fixtures/legacy-versions/0.23.0/.specrew/start-context.json | 9 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/fixtures/legacy-versions/0.23.0/.squad/identity/now.md | 22 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/integration/Test-LegacyStateReaders.Tests.ps1 | 336 | 0 | T020, T028, T030, T034 | Human Steward |
| tests/unit/validate-governance.reader-tolerance.tests.ps1 | 120 | 0 | T020, T028, T030, T034 | Human Steward |

## Public-API Delta

### Added

- Get-SpecrewSupportedStateSchemas (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewStateSchemaVersion (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-IsUnsupportedSpecrewSchemaError (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewValidatorSummaryPath (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Write-SpecrewValidatorSummary (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Write-ValidatorSummaryAndExit (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-ExtensionManifestVersion (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ReaderTolerance (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-SpecrewSupportedStateSchemas (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewStateSchemaVersion (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-IsUnsupportedSpecrewSchemaError (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewValidatorSummaryPath (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Write-SpecrewValidatorSummary (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Write-ValidatorSummaryAndExit (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ReaderTolerance (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Write-Pass (tests/integration/Test-LegacyStateReaders.Tests.ps1)
- Write-Fail (tests/integration/Test-LegacyStateReaders.Tests.ps1)
- Assert-True (tests/integration/Test-LegacyStateReaders.Tests.ps1)
- Assert-Equal (tests/integration/Test-LegacyStateReaders.Tests.ps1)
- Assert-Null (tests/integration/Test-LegacyStateReaders.Tests.ps1)
- Assert-Match (tests/integration/Test-LegacyStateReaders.Tests.ps1)
- Assert-ThrowsLike (tests/integration/Test-LegacyStateReaders.Tests.ps1)
- Import-FunctionsFromFile (tests/integration/Test-LegacyStateReaders.Tests.ps1)
- New-TestWorkspace (tests/integration/Test-LegacyStateReaders.Tests.ps1)
- Invoke-WithDebugCapture (tests/integration/Test-LegacyStateReaders.Tests.ps1)
- New-TestWorkspace (tests/unit/validate-governance.reader-tolerance.tests.ps1)
- Get-WorktreeFeatureRef (tests/unit/validate-governance.reader-tolerance.tests.ps1)
- Invoke-ValidatorScript (tests/unit/validate-governance.reader-tolerance.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- tests/integration/Test-LegacyStateReaders.Tests.ps1 (336 changed lines)

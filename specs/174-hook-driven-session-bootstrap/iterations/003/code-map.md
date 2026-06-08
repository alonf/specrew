# Code Map: Iteration 003

**Schema**: v1
**Reviewed**: 2026-06-09
**Baseline Ref**: 3f36845e9d582b075e96c08d13bc181c4bc79932
**Test-to-Code Ratio**: 7:12

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
> 
> This iteration's task tracking declares **9 completed task(s)**, but the git diff against baseline `3f36845e9d582b075e96c08d13bc181c4bc79932` contains **27 file(s)**.
> 
> **Severity**: WARNING  
> **Implication**: Review evidence may be incomplete or misleading.
> 
> **Possible causes**:
> - Implementation work was not committed before scaffolding review artifacts
> - Task status markers in plan.md or review.md do not match actual progress
> - Baseline reference in state.md is stale or incorrect
> 
> **Remediation**: 
> 1. Verify implementation is committed: `git diff 3f36845e9d582b075e96c08d13bc181c4bc79932...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
> 
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/extensions/specrew-speckit/refocus-scopes.json | 8 | 0 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| Specrew.psd1 | 4 | 0 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| docs/getting-started.md | 10 | 0 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| extensions/specrew-speckit/refocus-scopes.json | 8 | 0 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1 | 82 | 0 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| extensions/specrew-speckit/scripts/specrew-handover-provider.ps1 | 83 | 0 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| scripts/internal/bootstrap/ClassificationEngine.ps1 | 38 | 0 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| scripts/internal/bootstrap/HookJournalAccessor.ps1 | 23 | 0 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| scripts/internal/bootstrap/HostEventAdapter.ps1 | 20 | 7 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| scripts/internal/bootstrap/LauncherIntegration.ps1 | 28 | 24 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| scripts/internal/bootstrap/SessionBootstrapManager.ps1 | 44 | 8 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| scripts/internal/bootstrap/SessionStateAccessor.ps1 | 19 | 0 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| scripts/internal/deploy-refocus-hooks.ps1 | 3 | 1 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| scripts/internal/refocus-deploy-integration.ps1 | 4 | 1 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| scripts/internal/specrew-bootstrap-provider.ps1 | 9 | 1 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| scripts/internal/specrew-handover-provider.ps1 | 83 | 0 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| specs/174-hook-driven-session-bootstrap/iterations/003/drift-log.md | 45 | 0 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| specs/174-hook-driven-session-bootstrap/iterations/003/plan.md | 101 | 0 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| specs/174-hook-driven-session-bootstrap/iterations/003/quality/hardening-gate.md | 30 | 0 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| specs/174-hook-driven-session-bootstrap/iterations/003/state.md | 33 | 0 | T021, T022, T016, T017, T014, T015, T018, T019, T020 | Implementer |
| tests/bootstrap/Concurrency.Tests.ps1 | 46 | 0 | T018, T019 | Implementer |
| tests/bootstrap/JournalAssertion.Tests.ps1 | 53 | 0 | T018, T019 | Implementer |
| tests/bootstrap/LauncherIntegration.Tests.ps1 | 11 | 16 | T018, T019 | Implementer |
| tests/bootstrap/PerHost.Tests.ps1 | 40 | 0 | T018, T019 | Implementer |
| tests/bootstrap/Regression.Tests.ps1 | 53 | 0 | T018, T019 | Implementer |
| tests/bootstrap/SessionBootstrapManager.Tests.ps1 | 1 | 0 | T018, T019 | Implementer |
| tests/integration/refocus-deploy.tests.ps1 | 2 | 0 | T018, T019 | Implementer |

## Public-API Delta

### Added

- Get-BootstrapProjectRoot (extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1)
- Format-BootstrapDirective (extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1)
- Get-HandoverProjectRoot (extensions/specrew-speckit/scripts/specrew-handover-provider.ps1)
- Get-HandoverProp (extensions/specrew-speckit/scripts/specrew-handover-provider.ps1)
- Test-SpecrewConcurrentSession (scripts/internal/bootstrap/ClassificationEngine.ps1)
- Get-SpecrewBootstrapJournal (scripts/internal/bootstrap/HookJournalAccessor.ps1)
- Get-SpecrewEventField (scripts/internal/bootstrap/HostEventAdapter.ps1)
- Get-SpecrewLauncherMarkerPath (scripts/internal/bootstrap/LauncherIntegration.ps1)
- Write-SpecrewLauncherBootstrapMarker (scripts/internal/bootstrap/LauncherIntegration.ps1)
- Get-SpecrewSessionMarker (scripts/internal/bootstrap/SessionStateAccessor.ps1)
- Get-HandoverProjectRoot (scripts/internal/specrew-handover-provider.ps1)
- Get-HandoverProp (scripts/internal/specrew-handover-provider.ps1)
- Assert-Equal (tests/bootstrap/Concurrency.Tests.ps1)
- Assert-True (tests/bootstrap/Concurrency.Tests.ps1)
- Assert-Equal (tests/bootstrap/JournalAssertion.Tests.ps1)
- Assert-True (tests/bootstrap/JournalAssertion.Tests.ps1)
- Assert-Equal (tests/bootstrap/PerHost.Tests.ps1)
- Assert-True (tests/bootstrap/PerHost.Tests.ps1)
- Assert-Equal (tests/bootstrap/Regression.Tests.ps1)
- Assert-True (tests/bootstrap/Regression.Tests.ps1)

### Removed

- Get-SpecrewLastStartRecordedAt (scripts/internal/bootstrap/LauncherIntegration.ps1)
- Write-LastStart (tests/bootstrap/LauncherIntegration.Tests.ps1)

## Module Hotspots

- Threshold: 250 changed lines per file
- none
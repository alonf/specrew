# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-08
**Baseline Ref**: 550e3c02c29330ada6d539c6b9c625fcb2097f22
**Test-to-Code Ratio**: 8:8

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **7 completed task(s)**, but the git diff against baseline `550e3c02c29330ada6d539c6b9c625fcb2097f22` contains **31 file(s)**.
>
> **Severity**: WARNING  
> **Implication**: Review evidence may be incomplete or misleading.
>
> **Possible causes**:
>
> - Implementation work was not committed before scaffolding review artifacts
> - Task status markers in plan.md or review.md do not match actual progress
> - Baseline reference in state.md is stale or incorrect
>
> **Remediation**:
>
> 1. Verify implementation is committed: `git diff 550e3c02c29330ada6d539c6b9c625fcb2097f22...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/extensions/specrew-speckit/refocus-scopes.json | 8 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| Specrew.psd1 | 8 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| extensions/specrew-speckit/refocus-scopes.json | 8 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| scripts/internal/bootstrap/ClassificationEngine.ps1 | 33 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| scripts/internal/bootstrap/DirectiveEngine.ps1 | 42 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| scripts/internal/bootstrap/HostEventAdapter.ps1 | 50 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| scripts/internal/bootstrap/ProjectMetadataAccessor.ps1 | 58 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| scripts/internal/bootstrap/SessionBootstrapManager.ps1 | 64 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| scripts/internal/bootstrap/SessionStateAccessor.ps1 | 90 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| scripts/internal/bootstrap/ValidationEngine.ps1 | 58 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| scripts/internal/specrew-bootstrap-provider.ps1 | 69 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| specs/174-hook-driven-session-bootstrap/contracts/174-hook-driven-session-bootstrap.md | 40 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| specs/174-hook-driven-session-bootstrap/data-model.md | 57 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| specs/174-hook-driven-session-bootstrap/gates/design-analysis-001.md | 38 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| specs/174-hook-driven-session-bootstrap/iterations/001/design-analysis.md | 275 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| specs/174-hook-driven-session-bootstrap/iterations/001/drift-log.md | 67 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| specs/174-hook-driven-session-bootstrap/iterations/001/plan.md | 104 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| specs/174-hook-driven-session-bootstrap/iterations/001/quality/hardening-gate.md | 32 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| specs/174-hook-driven-session-bootstrap/lens-applicability.json | 1 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| specs/174-hook-driven-session-bootstrap/plan.md | 114 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| specs/174-hook-driven-session-bootstrap/quickstart.md | 36 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| specs/174-hook-driven-session-bootstrap/review-diagrams.md | 49 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| specs/174-hook-driven-session-bootstrap/tasks.md | 84 | 0 | T001, T002, T003, T004, T005, T006, T007 | Implementer |
| tests/bootstrap/BootstrapProvider.Tests.ps1 | 29 | 0 | T001 | Implementer |
| tests/bootstrap/ClassificationEngine.Tests.ps1 | 34 | 0 | T001 | Implementer |
| tests/bootstrap/DirectiveEngine.Tests.ps1 | 35 | 0 | T001 | Implementer |
| tests/bootstrap/HostEventAdapter.Tests.ps1 | 36 | 0 | T001 | Implementer |
| tests/bootstrap/ProjectMetadataAccessor.Tests.ps1 | 30 | 0 | T001 | Implementer |
| tests/bootstrap/SessionBootstrapManager.Tests.ps1 | 60 | 0 | T001 | Implementer |
| tests/bootstrap/SessionStateAccessor.Tests.ps1 | 58 | 0 | T001 | Implementer |
| tests/bootstrap/ValidationEngine.Tests.ps1 | 68 | 0 | T001 | Implementer |

## Public-API Delta

### Added

- Resolve-SpecrewBootstrapMode (scripts/internal/bootstrap/ClassificationEngine.ps1)
- New-SpecrewBootstrapDirective (scripts/internal/bootstrap/DirectiveEngine.ps1)
- ConvertFrom-SpecrewHostHookEvent (scripts/internal/bootstrap/HostEventAdapter.ps1)
- Test-SpecrewFeatureLocal (scripts/internal/bootstrap/ProjectMetadataAccessor.ps1)
- Test-SpecrewBranchMergedToBase (scripts/internal/bootstrap/ProjectMetadataAccessor.ps1)
- Get-SpecrewFeatureResumable (scripts/internal/bootstrap/ProjectMetadataAccessor.ps1)
- Invoke-SpecrewSessionBootstrap (scripts/internal/bootstrap/SessionBootstrapManager.ps1)
- Get-SpecrewProp (scripts/internal/bootstrap/SessionStateAccessor.ps1)
- Get-SpecrewSessionAnchor (scripts/internal/bootstrap/SessionStateAccessor.ps1)
- Write-SpecrewSessionMarker (scripts/internal/bootstrap/SessionStateAccessor.ps1)
- Test-SpecrewAnchorPortable (scripts/internal/bootstrap/SessionStateAccessor.ps1)
- Test-SpecrewAnchorValidity (scripts/internal/bootstrap/ValidationEngine.ps1)
- Get-BootstrapProjectRoot (scripts/internal/specrew-bootstrap-provider.ps1)
- Format-BootstrapDirective (scripts/internal/specrew-bootstrap-provider.ps1)
- Assert-True (tests/bootstrap/BootstrapProvider.Tests.ps1)
- Assert-Equal (tests/bootstrap/ClassificationEngine.Tests.ps1)
- Assert-True (tests/bootstrap/ClassificationEngine.Tests.ps1)
- Assert-Equal (tests/bootstrap/DirectiveEngine.Tests.ps1)
- Assert-True (tests/bootstrap/DirectiveEngine.Tests.ps1)
- Assert-Equal (tests/bootstrap/HostEventAdapter.Tests.ps1)
- Assert-True (tests/bootstrap/HostEventAdapter.Tests.ps1)
- Assert-True (tests/bootstrap/ProjectMetadataAccessor.Tests.ps1)
- Assert-Equal (tests/bootstrap/SessionBootstrapManager.Tests.ps1)
- Assert-True (tests/bootstrap/SessionBootstrapManager.Tests.ps1)
- New-StateFile (tests/bootstrap/SessionBootstrapManager.Tests.ps1)
- Assert-Equal (tests/bootstrap/SessionStateAccessor.Tests.ps1)
- Assert-True (tests/bootstrap/SessionStateAccessor.Tests.ps1)
- Assert-Equal (tests/bootstrap/ValidationEngine.Tests.ps1)
- Assert-True (tests/bootstrap/ValidationEngine.Tests.ps1)
- New-StateFile (tests/bootstrap/ValidationEngine.Tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- specs/174-hook-driven-session-bootstrap/iterations/001/design-analysis.md (275 changed lines)

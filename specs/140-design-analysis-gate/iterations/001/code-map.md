# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-02
**Baseline Ref**: `ab299f7079173282e9330b600f20c42fd78a42c2`
**Implementation Commit**: `17f9e073`
**Boundary Sync Commit**: `726df48e`
**Test-to-Code Ratio**: focused PowerShell helper/integration coverage

## Files Touched

| Path | Purpose | Owning Tasks |
| --- | --- | --- |
| `scripts/internal/design-analysis-gate.ps1` | Reusable design-analysis applicability, artifact, option, recommendation, and Human Decision validator. | T002-T005, T007-T008 |
| `scripts/internal/sync-boundary-state.ps1` | Calls the design-analysis gate before `plan` boundary state mutation. | T006-T008, T012 |
| `scripts/specrew-start.ps1` | Adds generated lifecycle guidance for the substantive design-analysis stop and verdict shape. | T013 |
| `Specrew.psd1` | Adds the helper to the deployable FileList. | T002, T016 |
| `tests/unit/design-analysis-gate.tests.ps1` | Unit coverage for parsing, artifact validation, option validation, recommendation/Human Decision validation, and legacy compatibility. | T009-T010 |
| `tests/integration/design-analysis-boundary.tests.ps1` | Integration coverage for active plan-boundary block/pass and compatibility skip behavior. | T011 |
| `specs/140-design-analysis-gate/quickstart.md` | Final user validation flow and compatibility notes. | T015 |
| `specs/140-design-analysis-gate/contracts/design-analysis-gate.md` | Helper API, artifact contract, active applicability, and T014 deferral contract. | T015 |
| `specs/140-design-analysis-gate/iterations/001/quality/*` | Runtime evidence, hardening result, and zero-finding mechanical checks. | T016 |
| `.squad/active-features.yml`, `.squad/events/lifecycle-events.jsonl`, `.squad/identity/now.md` | Review-signoff boundary sync evidence. | Boundary sync |

## Public API Delta

### Added Helper Symbols

- `Get-SpecrewDesignAnalysisArtifactPath`
- `Test-SpecrewDesignAnalysisGateRequired`
- `Test-SpecrewDesignAnalysisArtifact`
- `Invoke-SpecrewDesignAnalysisPlanBoundaryGate`

Additional helper-private parsing functions are present in `scripts/internal/design-analysis-gate.ps1` to keep artifact parsing out of the sync script.

### Modified Existing Surface

- `Invoke-SpecrewBoundaryStateSync` now calls `Invoke-SpecrewDesignAnalysisPlanBoundaryGate` only when `-BoundaryType plan`.
- `scripts/specrew-start.ps1` generated prompt guidance now describes `clarify/before-plan -> design-analysis -> plan` for substantive features.

### Deferred Surface

- T014 command/workflow metadata changes were removed and remain deferred.

## Hotspots

| File | Review Note |
| --- | --- |
| `scripts/internal/design-analysis-gate.ps1` | Largest change; intentionally isolated helper with focused unit and integration coverage. |
| `scripts/internal/sync-boundary-state.ps1` | Small shared lifecycle edit; reviewed for call placement before state mutation. |

# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-02
**Baseline Ref**: 936f1c3789d3da6bfd7563f67c9b3de402b94dc2
**Test-to-Code Ratio**: 2:2

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **10 completed task(s)**, but the git diff against baseline `936f1c3789d3da6bfd7563f67c9b3de402b94dc2` contains **15 file(s)**.
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
> 1. Verify implementation is committed: `git diff 936f1c3789d3da6bfd7563f67c9b3de402b94dc2...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .squad/active-features.yml | 1 | 1 | T002, T003, T004, T005, T006, T007, T009, T011 | Implementer |
| .squad/events/lifecycle-events.jsonl | 1 | 0 | T002, T003, T004, T005, T006, T007, T009, T011 | Implementer |
| .squad/identity/now.md | 4 | 4 | T002, T003, T004, T005, T006, T007, T009, T011 | Implementer |
| Specrew.psd1 | 1 | 0 | T002, T003, T004, T005, T006, T007, T009, T011 | Implementer |
| extensions/specrew-speckit/templates/design-analysis.template.md | 124 | 0 | T002, T003, T004, T005, T006, T007, T009, T011 | Implementer |
| scripts/internal/design-analysis-gate.ps1 | 253 | 7 | T002, T003, T004, T005, T006, T007, T009, T011 | Implementer |
| scripts/specrew-start.ps1 | 1 | 1 | T002, T003, T004, T005, T006, T007, T009, T011 | Implementer |
| specs/141-design-gate-runtime-hardening/contracts/design-gate-runtime-hardening.md | 10 | 0 | T002, T003, T004, T005, T006, T007, T009, T011 | Implementer |
| specs/141-design-gate-runtime-hardening/contracts/mechanical-findings.schema.json | 77 | 0 | T002, T003, T004, T005, T006, T007, T009, T011 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/001/drift-log.md | 51 | 0 | T002, T003, T004, T005, T006, T007, T009, T011 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/001/plan.md | 100 | 0 | T002, T003, T004, T005, T006, T007, T009, T011 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/001/quality/hardening-gate.md | 35 | 0 | T002, T003, T004, T005, T006, T007, T009, T011 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/001/state.md | 40 | 0 | T002, T003, T004, T005, T006, T007, T009, T011 | Implementer |
| tests/integration/design-gate-runtime-hardening.tests.ps1 | 157 | 0 | T004, T009, T010, T011 | Implementer |
| tests/unit/design-gate-runtime-hardening.tests.ps1 | 204 | 0 | T004, T009, T010, T011 | Implementer |

## Public-API Delta

### Added

- Get-SpecrewDesignAnalysisMarkedOption (scripts/internal/design-analysis-gate.ps1)
- New-SpecrewDesignAnalysisGatePacket (scripts/internal/design-analysis-gate.ps1)
- Test-SpecrewDesignAnalysisGatePacket (scripts/internal/design-analysis-gate.ps1)
- Get-SpecrewDesignAnalysisGatePacketPath (scripts/internal/design-analysis-gate.ps1)
- Save-SpecrewDesignAnalysisGatePacket (scripts/internal/design-analysis-gate.ps1)
- Get-SpecrewDesignAnalysisSelectedOption (scripts/internal/design-analysis-gate.ps1)
- Get-SpecrewDesignAnalysisTemplatePath (scripts/internal/design-analysis-gate.ps1)
- New-SpecrewDesignAnalysisArtifact (scripts/internal/design-analysis-gate.ps1)
- Invoke-SpecrewDesignAnalysisPrePlanGate (scripts/internal/design-analysis-gate.ps1)
- Write-Pass (tests/integration/design-gate-runtime-hardening.tests.ps1)
- Write-Fail (tests/integration/design-gate-runtime-hardening.tests.ps1)
- Assert-True (tests/integration/design-gate-runtime-hardening.tests.ps1)
- Test-Throws (tests/integration/design-gate-runtime-hardening.tests.ps1)
- New-RuntimeHardeningFixture (tests/integration/design-gate-runtime-hardening.tests.ps1)
- Get-ValidArtifact (tests/integration/design-gate-runtime-hardening.tests.ps1)
- Write-Pass (tests/unit/design-gate-runtime-hardening.tests.ps1)
- Write-Fail (tests/unit/design-gate-runtime-hardening.tests.ps1)
- Assert-True (tests/unit/design-gate-runtime-hardening.tests.ps1)
- New-RuntimeHardeningFixture (tests/unit/design-gate-runtime-hardening.tests.ps1)
- Get-ToleranceFixtureArtifact (tests/unit/design-gate-runtime-hardening.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- scripts/internal/design-analysis-gate.ps1 (260 changed lines)

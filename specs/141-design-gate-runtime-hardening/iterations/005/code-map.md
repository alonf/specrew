# Code Map: Iteration 005

**Schema**: v1
**Reviewed**: 2026-06-03
**Baseline Ref**: 0e758032
**Test-to-Code Ratio**: 2:2

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **6 completed task(s)**, but the git diff against baseline `0e758032` contains **11 file(s)**.
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
> 1. Verify implementation is committed: `git diff 0e758032...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| extensions/specrew-speckit/templates/design-analysis.template.md | 13 | 3 | T001, T002, T003, T006 | Implementer |
| scripts/internal/design-analysis-gate.ps1 | 74 | 0 | T001, T002, T003, T006 | Implementer |
| scripts/internal/lens-applicability.ps1 | 63 | 3 | T001, T002, T003, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/005/design-analysis.md | 14 | 14 | T001, T002, T003, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/005/plan.md | 106 | 0 | T001, T002, T003, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/005/quality/hardening-gate.md | 36 | 0 | T001, T002, T003, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/005/state.md | 9 | 9 | T001, T002, T003, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/005/tasks-progress.yml | 41 | 0 | T001, T002, T003, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/quickstart.md | 32 | 1 | T001, T002, T003, T006 | Implementer |
| tests/unit/design-analysis-gate.tests.ps1 | 62 | 0 | T003, T005 | Implementer |
| tests/unit/lens-applicability-selector.tests.ps1 | 23 | 0 | T003, T005 | Implementer |

## Public-API Delta

### Added

- Test-SpecrewDesignAnalysisLensAddressedPlaceholder (scripts/internal/design-analysis-gate.ps1)
- Test-SpecrewDesignAnalysisLensCoverage (scripts/internal/design-analysis-gate.ps1)
- Get-SpecrewLensDecisionPoints (scripts/internal/lens-applicability.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none

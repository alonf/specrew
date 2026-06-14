# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-11
**Baseline Ref**: 016b7e39a58f03ec3499088100c42080ee60032e
**Test-to-Code Ratio**: 2:3

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **15 completed task(s)**, but the git diff against baseline `016b7e39a58f03ec3499088100c42080ee60032e` contains **21 file(s)**.
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
> 1. Verify implementation is committed: `git diff 016b7e39a58f03ec3499088100c42080ee60032e...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

**Reviewer note (warning triaged — heuristic false-positive)**: the 21-file / 16-task gap is
expected and the implementation IS committed. Two tasks legitimately produce multiple files
(T008 = 3 capture templates; T009 = adapter + a shared reader), and 4 of the 21 are iteration
**process** artifacts in the diff (`plan.md`, `state.md`, `tasks.md`, `drift-log.md`) rather than
task outputs. So ~17 source/output files map to 16 tasks. No uncommitted work; baseline =
`016b7e39` (the pre-implementation merge). Verdict unaffected.

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| Specrew.psd1 | 12 | 1 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| docs/methodology/work-kinds.md | 74 | 0 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| extensions/specrew-speckit/knowledge/design-lenses/devops-operations.md | 65 | 0 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| extensions/specrew-speckit/knowledge/repository-governance.schema.json | 95 | 0 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| extensions/specrew-speckit/knowledge/work-kinds.schema.json | 66 | 0 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| extensions/specrew-speckit/knowledge/work-kinds.yml | 101 | 0 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| extensions/specrew-speckit/scripts/provider-adapter.ps1 | 155 | 0 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| extensions/specrew-speckit/scripts/provider-generic.ps1 | 45 | 0 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| extensions/specrew-speckit/scripts/work-kind-common.ps1 | 154 | 0 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| specs/182-work-kind-branch-governance/iterations/001/drift-log.md | 25 | 4 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| specs/182-work-kind-branch-governance/iterations/001/forge-coupling-inventory.md | 48 | 0 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| specs/182-work-kind-branch-governance/iterations/001/plan.md | 18 | 17 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| specs/182-work-kind-branch-governance/iterations/001/state.md | 19 | 5 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| specs/182-work-kind-branch-governance/tasks.md | 4 | 3 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| templates/lifecycle/devops-lifecycle.md | 37 | 0 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| templates/lifecycle/docs-only-lifecycle.md | 31 | 0 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| templates/work-kind/release-validation-record.md | 27 | 0 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| templates/work-kind/repository-governance.yml | 45 | 0 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| templates/work-kind/work-kind.yml | 9 | 0 | T001, T002, T003, T008, T009, T010, T012, T013, T013b, T014, T015 | Implementer |
| tests/unit/provider-adapter.tests.ps1 | 63 | 0 | T004, T011, T013, T013b, T014, T015 | Spec Steward |
| tests/unit/work-kind-catalog.tests.ps1 | 75 | 0 | T004, T011, T013, T013b, T014, T015 | Spec Steward |

## Public-API Delta

### Added

- New-SpecrewProviderAdapter (extensions/specrew-speckit/scripts/provider-adapter.ps1)
- Get-SpecrewPrContext (extensions/specrew-speckit/scripts/provider-adapter.ps1)
- Invoke-SpecrewDetectCapability (extensions/specrew-speckit/scripts/provider-adapter.ps1)
- Invoke-SpecrewDescribeProtection (extensions/specrew-speckit/scripts/provider-adapter.ps1)
- Invoke-SpecrewApplyProtection (extensions/specrew-speckit/scripts/provider-adapter.ps1)
- Get-SpecrewGenericCapability (extensions/specrew-speckit/scripts/provider-generic.ps1)
- ConvertFrom-SpecrewWorkKindScalar (extensions/specrew-speckit/scripts/work-kind-common.ps1)
- ConvertFrom-SpecrewWorkKindCatalog (extensions/specrew-speckit/scripts/work-kind-common.ps1)
- ConvertFrom-SpecrewWorkKindDeclaration (extensions/specrew-speckit/scripts/work-kind-common.ps1)
- Test-SpecrewWorkKindGlob (extensions/specrew-speckit/scripts/work-kind-common.ps1)
- Test-SpecrewWorkKindAllowlisted (extensions/specrew-speckit/scripts/work-kind-common.ps1)
- Write-Pass (tests/unit/provider-adapter.tests.ps1)
- Write-Fail (tests/unit/provider-adapter.tests.ps1)
- Assert-True (tests/unit/provider-adapter.tests.ps1)
- Write-Pass (tests/unit/work-kind-catalog.tests.ps1)
- Write-Fail (tests/unit/work-kind-catalog.tests.ps1)
- Assert-True (tests/unit/work-kind-catalog.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none

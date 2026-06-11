# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-10
**Baseline Ref**: 7f4f2ae7482df0a8c0259c515c103c36c23d4e35
**Test-to-Code Ratio**: 2:1

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **9 completed task(s)**, but the git diff against baseline `7f4f2ae7482df0a8c0259c515c103c36c23d4e35` contains **21 file(s)**.
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
> 1. Verify implementation is committed: `git diff 7f4f2ae7482df0a8c0259c515c103c36c23d4e35...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| extensions/specrew-speckit/knowledge/design-lenses/code-implementation.md | 155 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| extensions/specrew-speckit/knowledge/design-lenses/code-rules.yml | 442 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| extensions/specrew-speckit/knowledge/design-lenses/implementation-rules.schema.json | 90 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| extensions/specrew-speckit/knowledge/design-lenses/index.yml | 6 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| scripts/internal/code-implementation-lens.ps1 | 396 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| specs/177-software-development-rules-lens/contracts/implementation-rules.schema.json | 14 | 14 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| specs/177-software-development-rules-lens/current-architecture.md | 15 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| specs/177-software-development-rules-lens/iterations/001/code-map.md | 89 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| specs/177-software-development-rules-lens/iterations/001/coverage-evidence.md | 59 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| specs/177-software-development-rules-lens/iterations/001/dashboard.md | 38 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| specs/177-software-development-rules-lens/iterations/001/dependency-report.md | 48 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| specs/177-software-development-rules-lens/iterations/001/drift-log.md | 23 | 4 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| specs/177-software-development-rules-lens/iterations/001/plan.md | 10 | 10 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| specs/177-software-development-rules-lens/iterations/001/quality/mechanical-findings.json | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| specs/177-software-development-rules-lens/iterations/001/review-diagrams.md | 54 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| specs/177-software-development-rules-lens/iterations/001/review-report.yml | 94 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| specs/177-software-development-rules-lens/iterations/001/review.md | 103 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| specs/177-software-development-rules-lens/iterations/001/reviewer-index.md | 55 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| specs/177-software-development-rules-lens/iterations/001/state.md | 11 | 6 | T001, T002, T003, T004, T005, T006, T007, T008, T009 | Implementer |
| tests/unit/code-implementation-lens.tests.ps1 | 152 | 0 | T007, T008, T009 | Implementer |
| tests/unit/lens-conduct-delivery.tests.ps1 | 2 | 2 | T007, T008, T009 | Implementer |

## Public-API Delta

### Added

- Get-SpecrewCodeManifestPath (scripts/internal/code-implementation-lens.ps1)
- Get-SpecrewCodeRecordPath (scripts/internal/code-implementation-lens.ps1)
- Get-SpecrewCodeRuleEscape (scripts/internal/code-implementation-lens.ps1)
- Get-SpecrewCodeRuleUnescape (scripts/internal/code-implementation-lens.ps1)
- Get-SpecrewCodeMember (scripts/internal/code-implementation-lens.ps1)
- ConvertTo-SpecrewCodeScalar (scripts/internal/code-implementation-lens.ps1)
- ConvertTo-SpecrewImplementationRulesYaml (scripts/internal/code-implementation-lens.ps1)
- ConvertFrom-SpecrewCodeScalar (scripts/internal/code-implementation-lens.ps1)
- ConvertFrom-SpecrewCodeInlineList (scripts/internal/code-implementation-lens.ps1)
- ConvertFrom-SpecrewImplementationRulesYaml (scripts/internal/code-implementation-lens.ps1)
- Format-SpecrewCodeImplementationMarkdown (scripts/internal/code-implementation-lens.ps1)
- New-SpecrewImplementationRulesManifest (scripts/internal/code-implementation-lens.ps1)
- Get-SpecrewCodeRuleIds (scripts/internal/code-implementation-lens.ps1)
- Merge-SpecrewCodeRuleCatalog (scripts/internal/code-implementation-lens.ps1)
- Test-SpecrewImplementationRulesManifest (scripts/internal/code-implementation-lens.ps1)
- Write-Pass (tests/unit/code-implementation-lens.tests.ps1)
- Write-Fail (tests/unit/code-implementation-lens.tests.ps1)
- Assert-True (tests/unit/code-implementation-lens.tests.ps1)
- New-TempManifestDir (tests/unit/code-implementation-lens.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- extensions/specrew-speckit/knowledge/design-lenses/code-rules.yml (442 changed lines)
- scripts/internal/code-implementation-lens.ps1 (396 changed lines)

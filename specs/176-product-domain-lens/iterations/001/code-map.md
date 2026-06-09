# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-10
**Baseline Ref**: 9a7ef7a30f24688ca3e8061e7c3ab5918c83f76f
**Test-to-Code Ratio**: 3:2

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
> 
> This iteration's task tracking declares **15 completed task(s)**, but the git diff against baseline `9a7ef7a30f24688ca3e8061e7c3ab5918c83f76f` contains **30 file(s)**.
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
> 1. Verify implementation is committed: `git diff 9a7ef7a30f24688ca3e8061e7c3ab5918c83f76f...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
> 
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .agents/skills/specrew-design-workshop/SKILL.md | 270 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| .claude/skills/specrew-design-workshop/SKILL.md | 270 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| .cursor/rules/specrew-design-workshop/SKILL.md | 270 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| .github/skills/specrew-design-workshop/SKILL.md | 270 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/skills/design-workshop.md | 36 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| extensions/specrew-speckit/knowledge/design-lenses/diagram-vocabulary.json | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| extensions/specrew-speckit/knowledge/design-lenses/index.yml | 6 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| extensions/specrew-speckit/knowledge/design-lenses/product-domain.md | 178 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/design-workshop.md | 36 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| scripts/internal/design-analysis-gate.ps1 | 72 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| scripts/internal/product-domain-lens.ps1 | 397 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/contracts/mechanical-findings.schema.json | 77 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/contracts/product-domain.md | 59 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/contracts/product-domain.schema.json | 103 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/data-model.md | 76 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/gates/design-analysis-001.md | 32 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/iterations/001/design-analysis.md | 309 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/iterations/001/drift-log.md | 61 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/iterations/001/lens-applicability.json | 32 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/iterations/001/plan.md | 105 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/iterations/001/quality/hardening-gate.md | 35 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/iterations/001/quality/mechanical-findings.json | 11 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/iterations/001/state.md | 33 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/plan.md | 215 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/quickstart.md | 47 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/review-diagrams.md | 84 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| specs/176-product-domain-lens/spec.md | 26 | 5 | T006, T007, T008, T009, T010, T011, T013, T014, T015 | Implementer |
| specs/176-product-domain-lens/tasks.md | 109 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T012, T013, T014 | Implementer |
| tests/integration/product-domain-multihost.tests.ps1 | 54 | 0 | T006, T007, T008, T009, T010, T011, T013, T014, T015 | Implementer |
| tests/unit/product-domain-lens.tests.ps1 | 135 | 0 | T006, T007, T008, T009, T010, T011, T013, T014, T015 | Implementer |

## Public-API Delta

### Added

- Get-SpecrewProductDomainCatalogDir (scripts/internal/design-analysis-gate.ps1)
- Test-SpecrewProductDomainGate (scripts/internal/design-analysis-gate.ps1)
- Get-SpecrewProductDomainDepth (scripts/internal/product-domain-lens.ps1)
- Get-SpecrewProductDomainEscape (scripts/internal/product-domain-lens.ps1)
- Get-SpecrewProductDomainUnescape (scripts/internal/product-domain-lens.ps1)
- ConvertTo-SpecrewProductDomainYaml (scripts/internal/product-domain-lens.ps1)
- ConvertFrom-SpecrewProductDomainScalar (scripts/internal/product-domain-lens.ps1)
- ConvertFrom-SpecrewProductDomainYaml (scripts/internal/product-domain-lens.ps1)
- Get-SpecrewProductDomainRecordPath (scripts/internal/product-domain-lens.ps1)
- Format-SpecrewProductDomainMarkdown (scripts/internal/product-domain-lens.ps1)
- New-SpecrewProductDomainRecord (scripts/internal/product-domain-lens.ps1)
- Get-SpecrewProductDomainSchemaPath (scripts/internal/product-domain-lens.ps1)
- Test-SpecrewProductDomainRecord (scripts/internal/product-domain-lens.ps1)
- Test-SpecrewProductDomainResearchBlock (scripts/internal/product-domain-lens.ps1)
- Format-SpecrewProductDomainSummary (scripts/internal/product-domain-lens.ps1)
- Risk (specs/176-product-domain-lens/iterations/001/design-analysis.md)
- Write-Pass (tests/integration/product-domain-multihost.tests.ps1)
- Write-Fail (tests/integration/product-domain-multihost.tests.ps1)
- Assert-True (tests/integration/product-domain-multihost.tests.ps1)
- Write-Pass (tests/unit/product-domain-lens.tests.ps1)
- Write-Fail (tests/unit/product-domain-lens.tests.ps1)
- Assert-True (tests/unit/product-domain-lens.tests.ps1)
- New-TempFeature (tests/unit/product-domain-lens.tests.ps1)
- New-ValidRecord (tests/unit/product-domain-lens.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- .agents/skills/specrew-design-workshop/SKILL.md (270 changed lines)
- .claude/skills/specrew-design-workshop/SKILL.md (270 changed lines)
- .cursor/rules/specrew-design-workshop/SKILL.md (270 changed lines)
- .github/skills/specrew-design-workshop/SKILL.md (270 changed lines)
- scripts/internal/product-domain-lens.ps1 (397 changed lines)
- specs/176-product-domain-lens/iterations/001/design-analysis.md (309 changed lines)
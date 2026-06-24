# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-24
**Baseline Ref**: 7266978a3b6e0cf620d104ba3c6734451667f959
**Test-to-Code Ratio**: 7:5

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **6 completed task(s)**, but the git diff against baseline `7266978a3b6e0cf620d104ba3c6734451667f959` contains **37 file(s)**.
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
> 1. Verify implementation is committed: `git diff 7266978a3b6e0cf620d104ba3c6734451667f959...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .github/workflows/cross-platform-validation.yml | 22 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| .github/workflows/publish-module.yml | 8 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| .github/workflows/specrew-ci.yml | 16 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| Specrew.psd1 | 1 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| hosts/_contract.md | 9 | 1 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| hosts/_registry.ps1 | 24 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| scripts/internal/coordinator-prompt-surgery.ps1 | 3 | 3 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| scripts/internal/host-flag-translation.ps1 | 1 | 1 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| scripts/internal/test-publish-harness.ps1 | 45 | 1 | T001, T004, T005, T006 | Planner, Reviewer |
| scripts/internal/update-host-package-filelist.ps1 | 190 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| scripts/specrew-start.ps1 | 4 | 4 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/contracts/devin-cli-host.md | 161 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/contracts/mechanical-findings.schema.json | 77 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/data-model.md | 171 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/gates/design-analysis-001.md | 32 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/iterations/001/design-analysis.md | 418 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/iterations/001/drift-log.md | 56 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/iterations/001/lens-applicability.json | 24 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/iterations/001/plan.md | 129 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/iterations/001/quality/hardening-gate.md | 97 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/iterations/001/quality/mechanical-findings.json | 11 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/iterations/001/quality/quality-evidence.md | 91 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/iterations/001/quality/trap-reapplication.md | 23 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/iterations/001/research/devin-stop-payload-spike.md | 93 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/iterations/001/state.md | 50 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/plan.md | 365 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/quickstart.md | 80 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/review-diagrams.md | 95 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/spec.md | 4 | 2 | T001, T004, T005, T006 | Planner, Reviewer |
| specs/200-devin-cli-host/tasks.md | 157 | 0 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/workshop/product-domain.md | 16 | 12 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| specs/200-devin-cli-host/workshop/product-domain.yml | 8 | 12 | T001, T002, T003, T004, T005 | Planner, Reviewer |
| tests/integration/host-coupling-firewall.tests.ps1 | 122 | 9 | T001, T004, T005, T006 | Planner, Reviewer |
| tests/integration/host-package-filelist.tests.ps1 | 154 | 0 | T001, T004, T005, T006 | Planner, Reviewer |
| tests/integration/host-registry.tests.ps1 | 86 | 0 | T001, T004, T005, T006 | Planner, Reviewer |
| tests/integration/multi-host-launch-path.tests.ps1 | 9 | 5 | T001, T004, T005, T006 | Planner, Reviewer |
| tests/integration/publish-module-harness.tests.ps1 | 68 | 2 | T001, T004, T005, T006 | Planner, Reviewer |

## Public-API Delta

### Added

- Test-SpecrewRegisteredHostKind (hosts/_registry.ps1)
- Get-SpecrewOrdinalSortedStrings (scripts/internal/update-host-package-filelist.ps1)
- Get-SpecrewHostPackageFileListEntries (scripts/internal/update-host-package-filelist.ps1)
- Update-SpecrewHostPackageFileList (scripts/internal/update-host-package-filelist.ps1)
- Find-SpecrewHostAdditionPurityViolation (tests/integration/host-coupling-firewall.tests.ps1)
- Write-Pass (tests/integration/host-package-filelist.tests.ps1)
- Write-Fail (tests/integration/host-package-filelist.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- specs/200-devin-cli-host/iterations/001/design-analysis.md (418 changed lines)
- specs/200-devin-cli-host/plan.md (365 changed lines)

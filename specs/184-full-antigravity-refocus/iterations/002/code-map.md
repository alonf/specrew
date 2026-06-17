# Code Map: Iteration 002

**Schema**: v1
**Reviewed**: 2026-06-18
**Baseline Ref**: abf18b99
**Test-to-Code Ratio**: 5:8

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
> 
> This iteration's task tracking declares **5 completed task(s)**, but the git diff against baseline `abf18b99` contains **38 file(s)**.
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
> 1. Verify implementation is committed: `git diff abf18b99...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
> 
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1 | 16 | 2 | T001, T002, T003, T004 | Planner, Reviewer |
| .squad/active-features.yml | 1 | 1 | T001, T002, T003, T004 | Planner, Reviewer |
| .squad/decisions.md | 99 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| .squad/events/lifecycle-events.jsonl | 3 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| .squad/identity/now.md | 5 | 5 | T001, T002, T003, T004 | Planner, Reviewer |
| Specrew.psd1 | 3 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| docs/getting-started.md | 1 | 1 | T001, T002, T003, T004 | Planner, Reviewer |
| extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1 | 16 | 2 | T001, T002, T003, T004 | Planner, Reviewer |
| scripts/internal/instruction-deploy.ps1 | 103 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| scripts/internal/instruction-file-merge.ps1 | 116 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| scripts/internal/specrew-bootstrap-provider.ps1 | 16 | 2 | T001, T002, T003, T004 | Planner, Reviewer |
| scripts/specrew-init.ps1 | 19 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| scripts/specrew-start.ps1 | 11 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| scripts/specrew-update.ps1 | 8 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/checklists/requirements-iteration-002.md | 42 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/implementation-rules.yml | 5 | 5 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/discovery-host-landscape.md | 86 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/drift-log.md | 78 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/lens-applicability.json | 108 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/plan.md | 121 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/quality/hardening-gate.md | 48 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/real-host-evidence.md | 43 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/state.md | 140 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/workshop/architecture-core.md | 47 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/workshop/code-implementation.md | 49 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/workshop/component-design.md | 48 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/workshop/devops-operations.md | 56 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/workshop/integration-api.md | 70 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/workshop/product-domain.md | 45 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/workshop/product-domain.yml | 36 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/iterations/002/workshop/requirements-nfr.md | 66 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/spec.md | 151 | 1 | T001, T005, T006 | Planner, Reviewer |
| specs/184-full-antigravity-refocus/tasks.md | 57 | 51 | T001, T002, T003, T004 | Planner, Reviewer |
| templates/coordinator-instructions.md | 5 | 0 | T001, T002, T003, T004 | Planner, Reviewer |
| tests/bootstrap/CoordinatorFrontLoad.Tests.ps1 | 52 | 0 | T001, T005, T006 | Planner, Reviewer |
| tests/integration/host-coupling-firewall.tests.ps1 | 18 | 1 | T001, T005, T006 | Planner, Reviewer |
| tests/integration/instruction-deploy.tests.ps1 | 98 | 0 | T001, T005, T006 | Planner, Reviewer |
| tests/unit/instruction-file-merge.tests.ps1 | 85 | 0 | T001, T005, T006 | Planner, Reviewer |

## Public-API Delta

### Added

- Deploy-SpecrewCoordinatorInstructions (scripts/internal/instruction-deploy.ps1)
- Invoke-SpecrewInstructionDeployment (scripts/internal/instruction-deploy.ps1)
- Get-SpecrewInstructionBeginMarker (scripts/internal/instruction-file-merge.ps1)
- Get-SpecrewInstructionEndMarker (scripts/internal/instruction-file-merge.ps1)
- Get-SpecrewCoordinatorFragmentPath (scripts/internal/instruction-file-merge.ps1)
- Get-SpecrewCoordinatorFragment (scripts/internal/instruction-file-merge.ps1)
- Merge-SpecrewManagedInstructionSection (scripts/internal/instruction-file-merge.ps1)
- Set-SpecrewInstructionFileSection (scripts/internal/instruction-file-merge.ps1)
- Assert-True (tests/bootstrap/CoordinatorFrontLoad.Tests.ps1)
- Write-Pass (tests/integration/instruction-deploy.tests.ps1)
- Write-Fail (tests/integration/instruction-deploy.tests.ps1)
- Write-NoBom (tests/integration/instruction-deploy.tests.ps1)
- Write-Pass (tests/unit/instruction-file-merge.tests.ps1)
- Write-Fail (tests/unit/instruction-file-merge.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none
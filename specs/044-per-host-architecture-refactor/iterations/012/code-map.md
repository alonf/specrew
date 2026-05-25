# Code Map: Iteration 012

**Schema**: v1
**Reviewed**: 2026-05-25
**Baseline Ref**: 0b1c1810
**Test-to-Code Ratio**: 0:0

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **5 completed task(s)**, but the git diff against baseline `0b1c1810` contains **7 file(s)**.
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
> 1. Verify implementation is committed: `git diff 0b1c1810...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| proposals/104-multi-host-onboarding-and-selection-flow.md | 5 | 1 | T001, T002, T003, T004, T005 | Implementer |
| proposals/108-specrew-init-refactor-and-crew-runtime-abstraction.md | 5 | 1 | T001, T002, T003, T004, T005 | Implementer |
| proposals/109-open-feature-awareness-and-multi-feature-switching.md | 226 | 0 | T001, T002, T003, T004, T005 | Implementer |
| proposals/110-quality-tier-routing-runtime-verification-bundle.md | 189 | 0 | T001, T002, T003, T004, T005 | Implementer |
| proposals/110-specrew-update-experience.md | 362 | 0 | T001, T002, T003, T004, T005 | Implementer |
| proposals/111-git-hook-markdownlint-enforcement.md | 164 | 0 | T001, T002, T003, T004, T005 | Implementer |
| proposals/INDEX.md | 7 | 3 | T001, T002, T003, T004, T005 | Implementer |

## Public-API Delta

### Added

- none

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- proposals/110-specrew-update-experience.md (362 changed lines)

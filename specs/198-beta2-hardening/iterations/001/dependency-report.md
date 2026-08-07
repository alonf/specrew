# Dependency Report: Iteration 001

**Schema**: v1
**Reviewed**: 2026-07-10
**Baseline Ref**: 62ff9d6473405ecc8433d6609b6d50c3be5459af

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **6 completed task(s)**, but the git diff against baseline `62ff9d6473405ecc8433d6609b6d50c3be5459af` contains **84 file(s)**.
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
> 1. Verify implementation is committed: `git diff 62ff9d6473405ecc8433d6609b6d50c3be5459af...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

**Warning answered (reviewed 2026-07-10)**: same explanation as coverage-evidence.md - the diff spans the iteration's full lifecycle layer (specs artifacts, mirrored annotations, review records), not just product code; all committed.

---

## Dependency Delta

| Ecosystem | Package | Prior Version | New Version | Change Type | License | Owning Task |
| --------- | ------- | ------------- | ----------- | ----------- | ------- | ----------- |
| toolchain (uv tool) | specify-cli (spec-kit) | 0.8.4 | 0.12.9 | version bump (single tested pin, I2) | MIT | T001/T002 |
| toolchain (npm -g) | @bradygaster/squad-cli | 0.9.1 | 0.11.0 | version bump (single tested pin, I2) | MIT | T003 |

## New-to-Project

- none

## Vulnerability Scan

- status: unscanned
- reason: No manifest files changed in this iteration.

## Transitive Surface

- none | No manifest changes were detected.

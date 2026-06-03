# Code Map: Iteration 003

**Schema**: v1
**Reviewed**: 2026-06-03
**Baseline Ref**: 99360a566f6861b9c2968b43276b508f558fc0ee
**Test-to-Code Ratio**: 3:0

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **5 completed task(s)**, but the git diff against baseline `99360a566f6861b9c2968b43276b508f558fc0ee` contains **19 file(s)**.
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
> 1. Verify implementation is committed: `git diff 99360a566f6861b9c2968b43276b508f558fc0ee...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .github/workflows/cross-platform-validation.yml | 23 | 4 | T018, T019 | Implementer |
| README.md | 18 | 5 | T018, T019 | Implementer |
| docs/getting-started.md | 14 | 2 | T018, T019 | Implementer |
| docs/troubleshooting.md | 47 | 0 | T018, T019 | Implementer |
| docs/user-guide.md | 5 | 3 | T018, T019 | Implementer |
| install.sh | 87 | 22 | T018, T019 | Implementer |
| specs/140-unix-native-install/iterations/003/drift-log.md | 45 | 0 | T018, T019 | Implementer |
| specs/140-unix-native-install/iterations/003/plan.md | 157 | 0 | T018, T019 | Implementer |
| specs/140-unix-native-install/iterations/003/quality/hardening-gate.md | 56 | 0 | T018, T019 | Implementer |
| specs/140-unix-native-install/iterations/003/quality/macos-manual-proof.md | 91 | 0 | T018, T019 | Implementer |
| specs/140-unix-native-install/iterations/003/quality/mechanical-findings.json | 11 | 0 | T018, T019 | Implementer |
| specs/140-unix-native-install/iterations/003/quality/quality-evidence.md | 17 | 0 | T018, T019 | Implementer |
| specs/140-unix-native-install/iterations/003/quality/release-gate.md | 65 | 0 | T018, T019 | Implementer |
| specs/140-unix-native-install/iterations/003/quality/trap-reapplication.md | 15 | 0 | T018, T019 | Implementer |
| specs/140-unix-native-install/iterations/003/state.md | 36 | 0 | T018, T019 | Implementer |
| specs/140-unix-native-install/tasks.md | 40 | 29 | T018, T019 | Implementer |
| tests/integration/install-sh-detect.sh | 36 | 21 | T020, T021, T023, T024 | Reviewer |
| tests/integration/install-sh-prerelease.sh | 43 | 0 | T020, T021, T023, T024 | Reviewer |
| tests/unit/wrapper-docs-parity.tests.ps1 | 71 | 0 | T020, T021, T023, T024 | Reviewer |

## Public-API Delta

### Added

- Write-Pass (tests/unit/wrapper-docs-parity.tests.ps1)
- Write-Fail (tests/unit/wrapper-docs-parity.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none

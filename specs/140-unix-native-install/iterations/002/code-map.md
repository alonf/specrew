# Code Map: Iteration 002

**Schema**: v1
**Reviewed**: 2026-06-02
**Baseline Ref**: be008f3b358869c4dec5c7994004e4d7af0d0ab0
**Test-to-Code Ratio**: 8:0

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **8 completed task(s)**, but the git diff against baseline `be008f3b358869c4dec5c7994004e4d7af0d0ab0` contains **22 file(s)**.
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
> 1. Verify implementation is committed: `git diff be008f3b358869c4dec5c7994004e4d7af0d0ab0...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .gitattributes | 4 | 1 | T010, T011, T012, T013, T014 | Implementer |
| .github/workflows/cross-platform-validation.yml | 97 | 0 | T010, T011, T012, T013, T014 | Implementer |
| Specrew.psd1 | 1 | 0 | T010, T011, T012, T013, T014 | Implementer |
| install.sh | 240 | 0 | T010, T011, T012, T013, T014 | Implementer |
| specs/140-unix-native-install/iterations/002/drift-log.md | 22 | 0 | T010, T011, T012, T013, T014 | Implementer |
| specs/140-unix-native-install/iterations/002/plan.md | 9 | 9 | T010, T011, T012, T013, T014 | Implementer |
| specs/140-unix-native-install/iterations/002/quality/lenses/robustness-baseline.md | 34 | 0 | T010, T011, T012, T013, T014 | Implementer |
| specs/140-unix-native-install/iterations/002/quality/lenses/security-baseline.md | 60 | 0 | T010, T011, T012, T013, T014 | Implementer |
| specs/140-unix-native-install/iterations/002/quality/lenses/test-integrity.md | 38 | 0 | T012, T015, T016, T017 | Implementer |
| specs/140-unix-native-install/iterations/002/review-145.md | 93 | 0 | T010, T011, T012, T013, T014 | Implementer |
| specs/140-unix-native-install/iterations/002/review.md | 37 | 0 | T010, T011, T012, T013, T014 | Implementer |
| specs/140-unix-native-install/iterations/002/state.md | 36 | 0 | T010, T011, T012, T013, T014 | Implementer |
| specs/140-unix-native-install/plan.md | 2 | 1 | T010, T011, T012, T013, T014 | Implementer |
| specs/140-unix-native-install/research.md | 12 | 2 | T010, T011, T012, T013, T014 | Implementer |
| specs/140-unix-native-install/spec.md | 7 | 3 | T012, T015, T016, T017 | Implementer |
| specs/140-unix-native-install/tasks.md | 6 | 3 | T010, T011, T012, T013, T014 | Implementer |
| tests/fixtures/install-sh/os-release/arch | 3 | 0 | T012, T015, T016, T017 | Implementer |
| tests/fixtures/install-sh/os-release/debian-12 | 4 | 0 | T012, T015, T016, T017 | Implementer |
| tests/fixtures/install-sh/os-release/ubuntu-2204 | 4 | 0 | T012, T015, T016, T017 | Implementer |
| tests/fixtures/install-sh/os-release/ubuntu-noversion | 2 | 0 | T012, T015, T016, T017 | Implementer |
| tests/integration/install-sh-detect.sh | 53 | 0 | T012, T015, T016, T017 | Implementer |
| tests/integration/wrapper-runtime.sh | 75 | 0 | T012, T015, T016, T017 | Implementer |

## Public-API Delta

### Added

- none

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none

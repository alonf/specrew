# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-03
**Baseline Ref**: ee8ef1fcbe9334790bdd142780f548721e9cc2ec
**Test-to-Code Ratio**: 2:4

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **18 completed task(s)**, but the git diff against baseline `ee8ef1fcbe9334790bdd142780f548721e9cc2ec` contains **13 file(s)**.
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
> 1. Verify implementation is committed: `git diff ee8ef1fcbe9334790bdd142780f548721e9cc2ec...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

**Reviewer note**: the gap is EXPECTED for this investigation feature. Several of
the 18 tasks are evidence/disposition/gate/review tasks that do not each create a
unique file, and the conditional fix tasks share the resolver/deploy files plus
their `.specify` mirrors. All implementation is committed (the repro-first commit
precedes the fix commit); the baseline-to-HEAD diff is complete and accurate.

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 | 17 | 0 | T001, T003, T004, T006, T007, T010, T012 | Implementer |
| .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1 | 5 | 5 | T001, T003, T004, T006, T007, T010, T012 | Implementer |
| extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 | 17 | 0 | T001, T003, T004, T006, T007, T010, T012 | Implementer |
| extensions/specrew-speckit/scripts/sync-boundary-state.ps1 | 5 | 5 | T001, T003, T004, T006, T007, T010, T012 | Implementer |
| specs/160-unix-resolver-sidecar-hardening/contracts/mechanical-findings.schema.json | 77 | 0 | T001, T003, T004, T006, T007, T010, T012 | Implementer |
| specs/160-unix-resolver-sidecar-hardening/iterations/001/drift-log.md | 45 | 0 | T001, T003, T004, T006, T007, T010, T012 | Implementer |
| specs/160-unix-resolver-sidecar-hardening/iterations/001/investigation-evidence.md | 137 | 0 | T001, T003, T004, T006, T007, T010, T012 | Implementer |
| specs/160-unix-resolver-sidecar-hardening/iterations/001/plan.md | 116 | 0 | T001, T003, T004, T006, T007, T010, T012 | Implementer |
| specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/hardening-gate.md | 51 | 0 | T001, T003, T004, T006, T007, T010, T012 | Implementer |
| specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/trap-reapplication.md | 15 | 0 | T001, T003, T004, T006, T007, T010, T012 | Implementer |
| specs/160-unix-resolver-sidecar-hardening/iterations/001/state.md | 33 | 0 | T001, T003, T004, T006, T007, T010, T012 | Implementer |
| tests/integration/managed-runtime-sidecar.tests.ps1 | 149 | 0 | T005, T008, T009, T011, T013, T015, T016, T018 | Reviewer |
| tests/integration/unix-resolver-path-semantics.tests.ps1 | 113 | 0 | T005, T008, T009, T011, T013, T015, T016, T018 | Reviewer |

## Public-API Delta

### Added

- Write-Pass (tests/integration/managed-runtime-sidecar.tests.ps1)
- Write-Info (tests/integration/managed-runtime-sidecar.tests.ps1)
- Assert-True (tests/integration/managed-runtime-sidecar.tests.ps1)
- New-SkillDir (tests/integration/managed-runtime-sidecar.tests.ps1)
- Write-Pass (tests/integration/unix-resolver-path-semantics.tests.ps1)
- Write-Info (tests/integration/unix-resolver-path-semantics.tests.ps1)
- Assert-True (tests/integration/unix-resolver-path-semantics.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none

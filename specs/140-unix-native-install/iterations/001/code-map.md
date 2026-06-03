# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-02
**Baseline Ref**: 393257292e3719467ca2ed75f165cd9eb2d9d89b
**Test-to-Code Ratio**: 4:3

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **0 completed task(s)**, but the git diff against baseline `393257292e3719467ca2ed75f165cd9eb2d9d89b` contains **27 file(s)**.
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
> 1. Verify implementation is committed: `git diff 393257292e3719467ca2ed75f165cd9eb2d9d89b...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .gitattributes | 3 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| Specrew.psd1 | 10 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| bin/specrew | 25 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| bin/specrew-init | 25 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| bin/specrew-review | 25 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| bin/specrew-start | 25 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| bin/specrew-team | 25 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| bin/specrew-update | 25 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| bin/specrew-version | 25 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| bin/specrew-where | 25 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| scripts/internal/generate-shell-wrappers.ps1 | 157 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| scripts/specrew-install-shell-wrappers.ps1 | 252 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| scripts/specrew.ps1 | 15 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| specs/140-unix-native-install/contracts/mechanical-findings.schema.json | 77 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| specs/140-unix-native-install/contracts/unix-native-install.md | 1 | 1 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| specs/140-unix-native-install/data-model.md | 1 | 1 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| specs/140-unix-native-install/iterations/001/drift-log.md | 50 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| specs/140-unix-native-install/iterations/001/plan.md | 104 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| specs/140-unix-native-install/iterations/001/quality/hardening-gate.md | 43 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| specs/140-unix-native-install/iterations/001/quality/mechanical-findings.json | 11 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| specs/140-unix-native-install/iterations/001/quality/quality-evidence.md | 17 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| specs/140-unix-native-install/iterations/001/quality/trap-reapplication.md | 15 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| specs/140-unix-native-install/iterations/001/state.md | 36 | 0 | T001, T002, T003, T004, T005, T007, T008 | Implementer |
| tests/unit/install-shell-wrappers.tests.ps1 | 98 | 0 | T005, T006, T008, T009 | Implementer |
| tests/unit/shell-wrapper-generator.tests.ps1 | 93 | 0 | T005, T006, T008, T009 | Implementer |
| tests/unit/wrapper-filelist-parity.tests.ps1 | 50 | 0 | T005, T006, T008, T009 | Implementer |
| tests/unit/wrapper-registry-parity.tests.ps1 | 40 | 0 | T005, T006, T008, T009 | Implementer |

## Public-API Delta

### Added

- Get-CommandRegistry (scripts/internal/generate-shell-wrappers.ps1)
- New-WrapperContent (scripts/internal/generate-shell-wrappers.ps1)
- ConvertFrom-UnixStyleInstallerArgs (scripts/specrew-install-shell-wrappers.ps1)
- Resolve-SpecrewBinDir (scripts/specrew-install-shell-wrappers.ps1)
- Test-DirOnPath (scripts/specrew-install-shell-wrappers.ps1)
- Get-WrapperInstallPlan (scripts/specrew-install-shell-wrappers.ps1)
- Test-IsUnixPlatform (scripts/specrew-install-shell-wrappers.ps1)
- Get-ExistingTargetKind (scripts/specrew-install-shell-wrappers.ps1)
- Invoke-SpecrewInstallShellWrappers (scripts/specrew-install-shell-wrappers.ps1)
- Show-InstallShellWrappersUsage (scripts/specrew-install-shell-wrappers.ps1)
- Write-Pass (tests/unit/install-shell-wrappers.tests.ps1)
- Write-Fail (tests/unit/install-shell-wrappers.tests.ps1)
- Write-Pass (tests/unit/shell-wrapper-generator.tests.ps1)
- Write-Fail (tests/unit/shell-wrapper-generator.tests.ps1)
- Invoke-Generator (tests/unit/shell-wrapper-generator.tests.ps1)
- Write-Pass (tests/unit/wrapper-filelist-parity.tests.ps1)
- Write-Fail (tests/unit/wrapper-filelist-parity.tests.ps1)
- Write-Pass (tests/unit/wrapper-registry-parity.tests.ps1)
- Write-Fail (tests/unit/wrapper-registry-parity.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- scripts/specrew-install-shell-wrappers.ps1 (252 changed lines)

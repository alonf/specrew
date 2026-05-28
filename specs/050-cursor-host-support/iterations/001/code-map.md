# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-29
**Baseline Ref**: b1b1ca0afff2c988cc4b94de0f96cd3a7d0b255c
**Test-to-Code Ratio**: 3:9

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
> 
> This iteration's task tracking declares **10 completed task(s)**, but the git diff against baseline `b1b1ca0afff2c988cc4b94de0f96cd3a7d0b255c` contains **21 file(s)**.
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
> 1. Verify implementation is committed: `git diff b1b1ca0afff2c988cc4b94de0f96cd3a7d0b255c...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
> 
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| Specrew.psd1 | 3 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| hosts/_registry.ps1 | 3 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| hosts/cursor/coordinator-rules.psd1 | 35 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| hosts/cursor/handlers.ps1 | 230 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| hosts/cursor/host.psd1 | 28 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| scripts/init/post-bootstrap-output.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| scripts/internal/coordinator-prompt-surgery.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| scripts/internal/detect-hosts.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| scripts/internal/host-flag-translation.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| scripts/internal/host-history.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| scripts/specrew-start.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/contracts/mechanical-findings.schema.json | 77 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/drift-log.md | 64 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/plan.md | 97 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/quality/hardening-gate.md | 42 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/quality/mechanical-findings.json | 11 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/state.md | 38 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| tests/integration/host-cursor.tests.ps1 | 108 | 0 | T002, T003, T004, T005, T006, T010 | Implementer |
| tests/integration/host-registry.tests.ps1 | 23 | 20 | T002, T003, T004, T005, T006, T010 | Implementer |
| tests/integration/multi-host-launch-path.tests.ps1 | 2 | 2 | T002, T003, T004, T005, T006, T010 | Implementer |

## Public-API Delta

### Added

- New-CursorLaunchInvocation (hosts/cursor/handlers.ps1)
- ConvertTo-CursorFlag (hosts/cursor/handlers.ps1)
- Test-CursorRuntimeInstalled (hosts/cursor/handlers.ps1)
- Get-CursorSignals (hosts/cursor/handlers.ps1)
- ConvertTo-CursorAgentDescription (hosts/cursor/handlers.ps1)
- Install-CursorCrewRuntime (hosts/cursor/handlers.ps1)
- Write-Pass (tests/integration/host-cursor.tests.ps1)
- Write-Fail (tests/integration/host-cursor.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none
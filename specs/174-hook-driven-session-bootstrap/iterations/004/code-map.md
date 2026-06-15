# Code Map: Iteration 004

**Schema**: v1
**Reviewed**: 2026-06-09
**Baseline Ref**: 4cd5183263778eb1dd5245de586e0ec2702da38f
**Test-to-Code Ratio**: 6:6

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **6 completed task(s)**, but the git diff against baseline `4cd5183263778eb1dd5245de586e0ec2702da38f` contains **21 file(s)**.
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
> 1. Verify implementation is committed: `git diff 4cd5183263778eb1dd5245de586e0ec2702da38f...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .claude/settings.local.json | 2 | 2 | T023, T024, T025, T026, T027, T028 | Implementer |
| .gitignore | 2 | 0 | T023, T024, T025, T026, T027, T028 | Implementer |
| .specify/extensions/specrew-speckit/refocus-scopes.json | 1 | 1 | T023, T024, T025, T026, T027, T028 | Implementer |
| docs/getting-started.md | 4 | 2 | T023, T024, T025, T026, T027, T028 | Implementer |
| extensions/specrew-speckit/refocus-scopes.json | 1 | 1 | T023, T024, T025, T026, T027, T028 | Implementer |
| extensions/specrew-speckit/scripts/specrew-handover-provider.ps1 | 38 | 17 | T023, T024, T025, T026, T027, T028 | Implementer |
| scripts/internal/bootstrap/ClassificationEngine.ps1 | 21 | 0 | T023, T024, T025, T026, T027, T028 | Implementer |
| scripts/internal/bootstrap/HandoverStore.ps1 | 70 | 0 | T023, T024, T025, T026, T027, T028 | Implementer |
| scripts/internal/bootstrap/SessionBootstrapManager.ps1 | 1 | 1 | T023, T024, T025, T026, T027, T028 | Implementer |
| scripts/internal/deploy-refocus-hooks.ps1 | 10 | 9 | T023, T024, T025, T026, T027, T028 | Implementer |
| scripts/internal/specrew-handover-provider.ps1 | 38 | 17 | T023, T024, T025, T026, T027, T028 | Implementer |
| specs/174-hook-driven-session-bootstrap/iterations/004/drift-log.md | 45 | 0 | T023, T024, T025, T026, T027, T028 | Implementer |
| specs/174-hook-driven-session-bootstrap/iterations/004/plan.md | 86 | 0 | T023, T024, T025, T026, T027, T028 | Implementer |
| specs/174-hook-driven-session-bootstrap/iterations/004/quality/hardening-gate.md | 29 | 0 | T023, T024, T025, T026, T027, T028 | Implementer |
| specs/174-hook-driven-session-bootstrap/iterations/004/state.md | 33 | 0 | T023, T024, T025, T026, T027, T028 | Implementer |
| specs/174-hook-driven-session-bootstrap/spec.md | 41 | 32 | T023, T027 | Implementer |
| tests/bootstrap/DeployedHostConfig.Tests.ps1 | 11 | 10 | T023, T027 | Implementer |
| tests/bootstrap/JournalAssertion.Tests.ps1 | 1 | 1 | T023, T027 | Implementer |
| tests/bootstrap/Regression.Tests.ps1 | 2 | 1 | T023, T027 | Implementer |
| tests/bootstrap/RollingHandover.Tests.ps1 | 67 | 0 | T023, T027 | Implementer |
| tests/integration/refocus-deploy.tests.ps1 | 8 | 7 | T023, T027 | Implementer |

## Public-API Delta

### Added

- Test-SpecrewHandoverMaterialChange (scripts/internal/bootstrap/ClassificationEngine.ps1)
- Get-SpecrewRollingHandoverPath (scripts/internal/bootstrap/HandoverStore.ps1)
- Write-SpecrewRollingHandover (scripts/internal/bootstrap/HandoverStore.ps1)
- Get-SpecrewRollingHandover (scripts/internal/bootstrap/HandoverStore.ps1)
- Assert-Equal (tests/bootstrap/RollingHandover.Tests.ps1)
- Assert-True (tests/bootstrap/RollingHandover.Tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none

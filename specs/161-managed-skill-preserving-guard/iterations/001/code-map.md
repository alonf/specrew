# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-06
**Baseline Ref**: 6185acb2827f8061db8a10e66a2aa234738c4020
**Test-to-Code Ratio**: 2:2

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **9 completed task(s)**, but the git diff against baseline `6185acb2827f8061db8a10e66a2aa234738c4020` contains **19 file(s)**.
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
> 1. Verify implementation is committed: `git diff 6185acb2827f8061db8a10e66a2aa234738c4020...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 | 19 | 1 | T003, T004, T006, T007, T008 | Implementer |
| .specrew/last-validator-summary.json | 4 | 4 | T003, T004, T006, T007, T008 | Implementer |
| .squad/active-features.yml | 1 | 1 | T003, T004, T006, T007, T008 | Implementer |
| .squad/decisions.md | 20 | 0 | T003, T004, T006, T007, T008 | Implementer |
| .squad/events/lifecycle-events.jsonl | 1 | 0 | T003, T004, T006, T007, T008 | Implementer |
| .squad/identity/now.md | 5 | 5 | T003, T004, T006, T007, T008 | Implementer |
| extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 | 19 | 1 | T003, T004, T006, T007, T008 | Implementer |
| specs/161-managed-skill-preserving-guard/contracts/mechanical-findings.schema.json | 77 | 0 | T003, T004, T006, T007, T008 | Implementer |
| specs/161-managed-skill-preserving-guard/iterations/001/drift-log.md | 45 | 0 | T003, T004, T006, T007, T008 | Implementer |
| specs/161-managed-skill-preserving-guard/iterations/001/evidence.md | 128 | 0 | T003, T004, T006, T007, T008 | Implementer |
| specs/161-managed-skill-preserving-guard/iterations/001/plan.md | 101 | 0 | T003, T004, T006, T007, T008 | Implementer |
| specs/161-managed-skill-preserving-guard/iterations/001/quality/hardening-gate.md | 52 | 0 | T003, T004, T006, T007, T008 | Implementer |
| specs/161-managed-skill-preserving-guard/iterations/001/quality/lenses/robustness-baseline.md | 20 | 0 | T003, T004, T006, T007, T008 | Implementer |
| specs/161-managed-skill-preserving-guard/iterations/001/quality/lenses/security-baseline.md | 21 | 0 | T003, T004, T006, T007, T008 | Implementer |
| specs/161-managed-skill-preserving-guard/iterations/001/quality/lenses/test-integrity.md | 21 | 0 | T003, T005, T009 | Implementer |
| specs/161-managed-skill-preserving-guard/iterations/001/quality/mechanical-findings.json | 11 | 0 | T003, T004, T006, T007, T008 | Implementer |
| specs/161-managed-skill-preserving-guard/iterations/001/quality/quality-evidence.md | 56 | 0 | T003, T004, T006, T007, T008 | Implementer |
| specs/161-managed-skill-preserving-guard/iterations/001/state.md | 44 | 0 | T003, T004, T006, T007, T008 | Implementer |
| tests/integration/managed-skill-stuck-preserving.tests.ps1 | 298 | 0 | T003, T005, T009 | Implementer |

## Public-API Delta

### Added

- Write-Pass (tests/integration/managed-skill-stuck-preserving.tests.ps1)
- Write-Info (tests/integration/managed-skill-stuck-preserving.tests.ps1)
- Write-Probe (tests/integration/managed-skill-stuck-preserving.tests.ps1)
- Assert-True (tests/integration/managed-skill-stuck-preserving.tests.ps1)
- Get-CanonicalSkillContent (tests/integration/managed-skill-stuck-preserving.tests.ps1)
- Get-MarkerContent (tests/integration/managed-skill-stuck-preserving.tests.ps1)
- New-LegacySkillDir (tests/integration/managed-skill-stuck-preserving.tests.ps1)
- Get-LegacyAction (tests/integration/managed-skill-stuck-preserving.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- tests/integration/managed-skill-stuck-preserving.tests.ps1 (298 changed lines)

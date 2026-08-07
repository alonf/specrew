# Code Map: Iteration 011

**Schema**: v1
**Reviewed**: 2026-08-06
**Baseline Ref**: d7f27f6a
**Test-to-Code Ratio**: 8:5

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **0 completed task(s)**, but the git diff against baseline `d7f27f6a` contains **24 file(s)**.
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
> 1. Verify implementation is committed: `git diff d7f27f6a...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/extensions/specrew-speckit/scripts/shared-governance.ps1 | 308 | 0 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| .specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 | 41 | 2 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| .specrew/closed-iterations.yml | 3 | 0 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| .squad/decisions.md | 86 | 0 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| extensions/specrew-speckit/scripts/shared-governance.ps1 | 308 | 0 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 | 41 | 2 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| scripts/internal/sync-boundary-state.ps1 | 52 | 2 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| specs/198-beta2-hardening/beta2-release-claim.md | 77 | 7 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| specs/198-beta2-hardening/boundary-evidence-contract.md | 95 | 0 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| specs/198-beta2-hardening/iterations/010/drift-log.md | 38 | 0 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| specs/198-beta2-hardening/iterations/011/drift-log.md | 1080 | 0 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| specs/198-beta2-hardening/iterations/011/plan.md | 461 | 0 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| specs/198-beta2-hardening/iterations/011/retro.md | 252 | 0 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| specs/198-beta2-hardening/iterations/011/state.md | 144 | 0 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| specs/198-beta2-hardening/iterations/011/tasks-progress.yml | 53 | 0 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| specs/198-beta2-hardening/spec.md | 60 | 5 | T092 | Reviewer |
| specs/198-beta2-hardening/tasks.md | 107 | 0 | T086, T087, T088, T089, T090, T091, T093 | Implementer |
| tests/f198-regression-suite.ps1 | 8 | 0 | T092 | Reviewer |
| tests/integration/conformance-detection.tests.ps1 | 104 | 0 | T092 | Reviewer |
| tests/integration/conformance-stop-intent-wiring.tests.ps1 | 49 | 0 | T092 | Reviewer |
| tests/integration/fr066-first-boundary-arrival.tests.ps1 | 214 | 0 | T092 | Reviewer |
| tests/integration/fr068-verdict-demand-reproduction.tests.ps1 | 346 | 0 | T092 | Reviewer |
| tests/integration/pending-verdict-stop-artifact.tests.ps1 | 20 | 1 | T092 | Reviewer |
| tests/integration/pending-verdict-surface.tests.ps1 | 67 | 4 | T092 | Reviewer |

## Public-API Delta

### Added

- Get-SpecrewBoundaryStageEvidenceContract (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewBoundaryStageEvidence (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Set-SpecrewStageEvidenceGate (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewBoundaryStageEvidenceContract (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewBoundaryStageEvidence (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Set-SpecrewStageEvidenceGate (extensions/specrew-speckit/scripts/shared-governance.ps1)
- New-BoundaryStageEvidence (tests/integration/conformance-detection.tests.ps1)
- Set-FixtureBoundCrossing (tests/integration/conformance-detection.tests.ps1)
- Set-FixtureBoundCrossing (tests/integration/conformance-stop-intent-wiring.tests.ps1)
- Write-Pass (tests/integration/fr066-first-boundary-arrival.tests.ps1)
- Write-Red (tests/integration/fr066-first-boundary-arrival.tests.ps1)
- Write-Measured (tests/integration/fr066-first-boundary-arrival.tests.ps1)
- Write-Inconclusive (tests/integration/fr066-first-boundary-arrival.tests.ps1)
- New-UnbootstrappedProject (tests/integration/fr066-first-boundary-arrival.tests.ps1)
- New-FixtureTranscript (tests/integration/fr066-first-boundary-arrival.tests.ps1)
- Write-Pass (tests/integration/fr068-verdict-demand-reproduction.tests.ps1)
- Write-Red (tests/integration/fr068-verdict-demand-reproduction.tests.ps1)
- Write-Measured (tests/integration/fr068-verdict-demand-reproduction.tests.ps1)
- Fail (tests/integration/fr068-verdict-demand-reproduction.tests.ps1)
- New-EvidencelessBoundaryFixture (tests/integration/fr068-verdict-demand-reproduction.tests.ps1)
- New-FixtureTranscript (tests/integration/fr068-verdict-demand-reproduction.tests.ps1)
- Invoke-DispatcherContradiction (tests/integration/fr068-verdict-demand-reproduction.tests.ps1)
- Test-ClarifyShape (tests/integration/fr068-verdict-demand-reproduction.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- .specify/extensions/specrew-speckit/scripts/shared-governance.ps1 (308 changed lines)
- extensions/specrew-speckit/scripts/shared-governance.ps1 (308 changed lines)
- specs/198-beta2-hardening/iterations/011/drift-log.md (1080 changed lines)
- specs/198-beta2-hardening/iterations/011/plan.md (461 changed lines)
- specs/198-beta2-hardening/iterations/011/retro.md (252 changed lines)
- tests/integration/fr068-verdict-demand-reproduction.tests.ps1 (346 changed lines)

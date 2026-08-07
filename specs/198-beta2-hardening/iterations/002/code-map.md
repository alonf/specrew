# Code Map: Iteration 002

**Schema**: v1
**Reviewed**: 2026-07-11
**Baseline Ref**: 1fdd7c6d60943c28ae90c43aba286044d5619642
**Test-to-Code Ratio**: 5:14

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **7 completed task(s)**, but the git diff against baseline `1fdd7c6d60943c28ae90c43aba286044d5619642` contains **36 file(s)**.
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
> 1. Verify implementation is committed: `git diff 1fdd7c6d60943c28ae90c43aba286044d5619642...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/extensions/specrew-speckit/scripts/shared-governance.ps1 | 147 | 3 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 | 11 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| .specrew/review/inline/20260710T213312228-de8951f5/findings-result.json | 27 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| .specrew/review/inline/20260710T213312228-de8951f5/redacted-evidence.json | 11 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| .specrew/review/inline/20260710T213312228-de8951f5/review-thread.json | 25 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| .specrew/review/inline/20260710T220201403-7634fabc/findings-result.json | 27 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| .specrew/review/inline/20260710T220201403-7634fabc/redacted-evidence.json | 11 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| .specrew/review/inline/20260710T220201403-7634fabc/review-thread.json | 35 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| .specrew/review/inline/20260710T233356014-d6dd10af/findings-result.json | 25 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| .specrew/review/inline/20260710T233356014-d6dd10af/redacted-evidence.json | 11 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| .specrew/review/inline/20260710T233356014-d6dd10af/review-thread.json | 25 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| extensions/specrew-speckit/scripts/shared-governance.ps1 | 147 | 3 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| extensions/specrew-speckit/scripts/validate-governance.ps1 | 11 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| scripts/internal/bootstrap/HandoverStore.ps1 | 4 | 1 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| scripts/internal/continuous-co-review/_load.ps1 | 1 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1 | 49 | 10 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1 | 28 | 2 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| scripts/internal/continuous-co-review/reviewer-host-catalog.ps1 | 20 | 4 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| scripts/internal/continuous-co-review/tracker-honesty-check.ps1 | 165 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1 | 16 | 7 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| scripts/internal/lint-self-leak.ps1 | 9 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| scripts/internal/sync-boundary-state.ps1 | 8 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| scripts/specrew-review.ps1 | 17 | 8 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| specs/198-beta2-hardening/gates/design-analysis-002.md | 32 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| specs/198-beta2-hardening/iterations/002/design-analysis.md | 325 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| specs/198-beta2-hardening/iterations/002/drift-log.md | 45 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| specs/198-beta2-hardening/iterations/002/lens-applicability.json | 24 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| specs/198-beta2-hardening/iterations/002/plan.md | 94 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| specs/198-beta2-hardening/iterations/002/quality/hardening-gate.md | 41 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| specs/198-beta2-hardening/iterations/002/state.md | 35 | 0 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| specs/198-beta2-hardening/spec.md | 26 | 3 | T010 | Implementer |
| specs/198-beta2-hardening/tasks.md | 8 | 7 | T007, T008, T009, T010, T011, T012, T019a | Implementer |
| tests/unit/boundary-ratchet.tests.ps1 | 147 | 0 | T010 | Implementer |
| tests/unit/budget-resolution.tests.ps1 | 70 | 0 | T010 | Implementer |
| tests/unit/self-leak-lint.tests.ps1 | 4 | 0 | T010 | Implementer |
| tests/unit/tracker-honesty-check.tests.ps1 | 120 | 0 | T010 | Implementer |

## Public-API Delta

### Added

- Get-SpecrewUnreconciledBoundary (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Invoke-SpecrewBoundaryRatchetGate (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewUnreconciledBoundary (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Invoke-SpecrewBoundaryRatchetGate (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-ContinuousCoReviewHostDefaultTimeoutSeconds (scripts/internal/continuous-co-review/reviewer-host-catalog.ps1)
- Get-ContinuousCoReviewTrackerOnlyDelta (scripts/internal/continuous-co-review/tracker-honesty-check.ps1)
- Get-ContinuousCoReviewTreeFileContent (scripts/internal/continuous-co-review/tracker-honesty-check.ps1)
- Get-ContinuousCoReviewStateClaims (scripts/internal/continuous-co-review/tracker-honesty-check.ps1)
- Get-ContinuousCoReviewAcceptedReviewRecord (scripts/internal/continuous-co-review/tracker-honesty-check.ps1)
- Test-ContinuousCoReviewTrackerReconcileHonest (scripts/internal/continuous-co-review/tracker-honesty-check.ps1)
- Write-Pass (tests/unit/boundary-ratchet.tests.ps1)
- Write-Fail (tests/unit/boundary-ratchet.tests.ps1)
- New-RatchetFixture (tests/unit/boundary-ratchet.tests.ps1)
- New-HistoryEntry (tests/unit/boundary-ratchet.tests.ps1)
- Write-Pass (tests/unit/budget-resolution.tests.ps1)
- Write-Fail (tests/unit/budget-resolution.tests.ps1)
- Write-Pass (tests/unit/tracker-honesty-check.tests.ps1)
- Write-Fail (tests/unit/tracker-honesty-check.tests.ps1)
- Save-Tree (tests/unit/tracker-honesty-check.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- specs/198-beta2-hardening/iterations/002/design-analysis.md (325 changed lines)

# Code Map: Iteration 002

**Schema**: v1
**Reviewed**: 2026-06-03
**Baseline Ref**: 464e0d3e97cf031525447690447fe81d8e98b7d4
**Test-to-Code Ratio**: 9:5

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **9 completed task(s)**, but the git diff against baseline `464e0d3e97cf031525447690447fe81d8e98b7d4` contains **27 file(s)**.
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
> 1. Verify implementation is committed: `git diff 464e0d3e97cf031525447690447fe81d8e98b7d4...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .squad/active-features.yml | 1 | 1 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| .squad/events/lifecycle-events.jsonl | 3 | 0 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| .squad/identity/now.md | 5 | 5 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| Specrew.psd1 | 1 | 0 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| scripts/internal/coordinator-prompt-surgery.ps1 | 12 | 1 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| scripts/internal/session-recovery.ps1 | 680 | 0 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| scripts/internal/sync-boundary-state.ps1 | 6 | 2 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| scripts/internal/task-progress.ps1 | 38 | 20 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| scripts/specrew-start.ps1 | 32 | 474 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/contracts/design-gate-runtime-hardening.md | 18 | 4 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/001/plan.md | 2 | 2 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/001/quality/hardening-gate.md | 8 | 4 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/002/drift-log.md | 59 | 0 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/002/plan.md | 88 | 0 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/002/quality/hardening-gate.md | 35 | 0 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/002/state.md | 79 | 0 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/iterations/002/tasks-progress.yml | 59 | 0 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/quickstart.md | 30 | 12 | T002, T003, T004, T005, T007, T008, T006 | Implementer |
| specs/141-design-gate-runtime-hardening/spec.md | 16 | 0 | T005, T009, T006 | Implementer |
| tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1 | 1 | 1 | T005, T009, T006 | Implementer |
| tests/integration/multi-host-launch-path.tests.ps1 | 28 | 0 | T005, T009, T006 | Implementer |
| tests/integration/non-specrew-session-bypass.tests.ps1 | 6 | 2 | T005, T009, T006 | Implementer |
| tests/integration/stale-state-detection.tests.ps1 | 1 | 1 | T005, T009, T006 | Implementer |
| tests/integration/start-recovery-flow.tests.ps1 | 110 | 1 | T005, T009, T006 | Implementer |
| tests/integration/task-progress-tracking.tests.ps1 | 129 | 0 | T005, T009, T006 | Implementer |
| tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1 | 249 | 0 | T005, T009, T006 | Implementer |
| tests/unit/design-gate-runtime-hardening.tests.ps1 | 19 | 0 | T005, T009, T006 | Implementer |

## Public-API Delta

### Added

- Get-SpecrewConfigValue (scripts/internal/session-recovery.ps1)
- Get-SpecrewPromptSessionState (scripts/internal/session-recovery.ps1)
- Get-SpecrewIdentitySessionState (scripts/internal/session-recovery.ps1)
- Get-SpecrewStartContextSessionState (scripts/internal/session-recovery.ps1)
- Get-SpecrewSessionStateSnapshot (scripts/internal/session-recovery.ps1)
- Test-SpecrewFeatureMergedToMain (scripts/internal/session-recovery.ps1)
- Test-SpecrewFeatureBranchExists (scripts/internal/session-recovery.ps1)
- Test-SpecrewAuthorizationRecord (scripts/internal/session-recovery.ps1)
- Test-SpecrewSessionStateConsistency (scripts/internal/session-recovery.ps1)
- Get-SpecrewLatestIterationDirectory (scripts/internal/session-recovery.ps1)
- Get-SpecrewMetadataValueFromFile (scripts/internal/session-recovery.ps1)
- Get-SpecrewLateBoundaryIssues (scripts/internal/session-recovery.ps1)
- Test-SpecrewStaleSessionState (scripts/internal/session-recovery.ps1)
- Read-SpecrewRecoveryChoice (scripts/internal/session-recovery.ps1)
- New-SpecrewRecoverySession (scripts/internal/session-recovery.ps1)
- Resolve-SpecrewRecoverySelection (scripts/internal/session-recovery.ps1)
- Clear-SpecrewStaleSessionReference (scripts/internal/session-recovery.ps1)
- Invoke-SpecrewStaleSessionCleanupDecision (scripts/internal/session-recovery.ps1)
- Write-Pass (tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1)
- Write-Fail (tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1)
- Assert-True (tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1)
- Assert-Equal (tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1)
- New-TempRoot (tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1)
- Write-StartContext (tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1)
- Write-ActiveSessions (tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1)
- Invoke-FixtureGit (tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1)

### Removed

- Get-SpecrewConfigValue (scripts/specrew-start.ps1)
- Get-SpecrewPromptSessionState (scripts/specrew-start.ps1)
- Get-SpecrewIdentitySessionState (scripts/specrew-start.ps1)
- Get-SpecrewStartContextSessionState (scripts/specrew-start.ps1)
- Get-SpecrewSessionStateSnapshot (scripts/specrew-start.ps1)
- Test-SpecrewFeatureMergedToMain (scripts/specrew-start.ps1)
- Test-SpecrewFeatureBranchExists (scripts/specrew-start.ps1)
- Test-SpecrewAuthorizationRecord (scripts/specrew-start.ps1)
- Test-SpecrewSessionStateConsistency (scripts/specrew-start.ps1)
- Get-SpecrewLatestIterationDirectory (scripts/specrew-start.ps1)
- Get-SpecrewMetadataValueFromFile (scripts/specrew-start.ps1)
- Get-SpecrewLateBoundaryIssues (scripts/specrew-start.ps1)
- Test-SpecrewStaleSessionState (scripts/specrew-start.ps1)
- Read-SpecrewRecoveryChoice (scripts/specrew-start.ps1)
- New-SpecrewRecoverySession (scripts/specrew-start.ps1)
- Resolve-SpecrewRecoverySelection (scripts/specrew-start.ps1)

## Module Hotspots

- Threshold: 250 changed lines per file
- scripts/internal/session-recovery.ps1 (680 changed lines)
- scripts/specrew-start.ps1 (506 changed lines)

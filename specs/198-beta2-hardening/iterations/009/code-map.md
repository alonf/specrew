# Code Map: Iteration 009 — Review Candidate Fidelity

**Schema**: v1
**Reviewed**:
**Baseline Ref**: afb3eda731d35ae922e92d9acf200f80e32e9580
**Test-to-Code Ratio**: 25:29

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **7 completed task(s)**, but the git diff against baseline `afb3eda731d35ae922e92d9acf200f80e32e9580` contains **84 file(s)**.
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
> 1. Verify implementation is committed: `git diff afb3eda731d35ae922e92d9acf200f80e32e9580...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .github/workflows/cross-platform-validation.yml | 24 | 1 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| .gitignore | 2 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| .specify/extensions/specrew-speckit/scripts/Test-CopilotInstructionsChangeType.ps1 | 1 | 1 | T076, T077, T079 | Implementer |
| .specify/extensions/specrew-speckit/scripts/conformance-turn-delta.ps1 | 21 | 3 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| .specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 | 90 | 1 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| .specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 | 1 | 1 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| .specify/extensions/specrew-speckit/scripts/test-consumer-assumptions.ps1 | 13 | 1 | T076, T077, T079 | Implementer |
| .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 | 11 | 1 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| .specrew/closed-iterations.yml | 3 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| .specrew/iteration-config.yml | 3 | 3 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| .specrew/reviewer-hosts.json | 5 | 5 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| Specrew.psd1 | 2 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| extensions/specrew-speckit/scripts/Test-CopilotInstructionsChangeType.ps1 | 1 | 1 | T076, T077, T079 | Implementer |
| extensions/specrew-speckit/scripts/conformance-turn-delta.ps1 | 21 | 3 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 | 197 | 1 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 | 1 | 1 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| extensions/specrew-speckit/scripts/test-consumer-assumptions.ps1 | 13 | 1 | T076, T077, T079 | Implementer |
| extensions/specrew-speckit/scripts/validate-governance.ps1 | 11 | 1 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/_load.ps1 | 4 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/hook-health-receipt.ps1 | 1 | 1 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/path-identity.ps1 | 196 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/review-authority-core.ps1 | 33 | 4 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/review-authority-store.ps1 | 7 | 1 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1 | 59 | 18 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/review-design-context.ps1 | 17 | 3 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/review-harness-contract.ps1 | 1 | 1 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/review-run-reconciler.ps1 | 33 | 9 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/review-target-port.ps1 | 185 | 15 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/reviewed-state-digest.ps1 | 128 | 52 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/reviewer-candidate-prompt.md | 7 | 5 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/verification-plan-contract.ps1 | 21 | 10 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/verification-plan-runner.ps1 | 13 | 4 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/verification-plan-supplier.ps1 | 2 | 2 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/continuous-co-review/worktree-reviewer.ps1 | 73 | 4 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/file-classification.ps1 | 11 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/review-engine-resolution.ps1 | 222 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/specrew-hook-dispatcher.ps1 | 1 | 1 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/internal/task-progress.ps1 | 26 | 2 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| scripts/specrew-review.ps1 | 104 | 24 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/beta2-release-claim.md | 134 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/003/plan.md | 8 | 8 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/003/quality/hardening-gate.md | 40 | 9 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/003/retro.md | 149 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/003/review.md | 136 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/003/state.md | 42 | 8 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/003/tasks-progress.yml | 13 | 13 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/008/state.md | 4 | 4 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/008/tasks-progress.yml | 1 | 1 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/drift-log.md | 1263 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/evidence/article-amplifier-frozen-replay.Tests.ps1 | 70 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/evidence/independent-review-0e0048b0-recert-result.json | 1 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/evidence/independent-review-178a3772-result.json | 1 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/evidence/independent-review-29e9f6fa-result.json | 55 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/evidence/independent-review-2c6d7cb8-sweep-result.json | 1 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/evidence/independent-review-3d74f123-final-result.json | 1 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/evidence/independent-review-5117c807-result.json | 1 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/evidence/independent-review-aab37c3b-2-result.json | 1 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/evidence/independent-review-d2b786e6-result.json | 1 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/evidence/independent-review-f738f5cf-certify-result.json | 1 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/plan.md | 205 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/quality/hardening-gate.md | 43 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/state.md | 255 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| specs/198-beta2-hardening/iterations/009/tasks-progress.yml | 53 | 0 | T072, T073, T074, T075, T076, T077, T078 | Implementer |
| tests/continuous-co-review/integration/co-review-deploy-completeness.Tests.ps1 | 73 | 0 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/integration/review-cross-platform-fault-matrix.Tests.ps1 | 3 | 0 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/unit/path-identity-mutation-gate.Tests.ps1 | 160 | 0 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/unit/path-identity-volume-differential.Tests.ps1 | 185 | 0 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/unit/path-identity.Tests.ps1 | 358 | 0 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/unit/review-authority-core.Tests.ps1 | 30 | 5 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/unit/review-campaign-orchestrator.Tests.ps1 | 36 | 0 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/unit/review-codex-copilot-harness.Tests.ps1 | 6 | 0 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/unit/review-harness-contract.Tests.ps1 | 6 | 4 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/unit/review-posix-runtime.Tests.ps1 | 4 | 1 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/unit/review-public-campaign-command.Tests.ps1 | 27 | 2 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/unit/review-target-port.Tests.ps1 | 156 | 0 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/unit/reviewed-state-digest.Tests.ps1 | 87 | 9 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/unit/reviewer-host-grant-write-scope.Tests.ps1 | 141 | 0 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/unit/worktree-containment.Tests.ps1 | 8 | 2 | T076, T077, T079 | Implementer |
| tests/continuous-co-review/unit/worktree-reviewer-machinery-paths.Tests.ps1 | 101 | 0 | T076, T077, T079 | Implementer |
| tests/f198-regression-suite.ps1 | 285 | 49 | T076, T077, T079 | Implementer |
| tests/unit/feature-051-file-classification.tests.ps1 | 13 | 1 | T076, T077, T079 | Implementer |
| tests/unit/regression-harness-isolation.tests.ps1 | 21 | 0 | T076, T077, T079 | Implementer |
| tests/unit/review-engine-resolution.tests.ps1 | 133 | 0 | T076, T077, T079 | Implementer |
| tests/unit/task-progress-managed-summary.tests.ps1 | 37 | 0 | T076, T077, T079 | Implementer |

## Public-API Delta

### Added

- Assert-ManagedTargetContained (.specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1)
- Assert-ManagedMutationAllowed (.specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1)
- Assert-ManagedTargetContained (extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1)
- Assert-ManagedMutationAllowed (extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1)
- Remove-RetiredManagedRuntimeFiles (extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1)
- Get-ContinuousCoReviewCaseFlippedName (scripts/internal/continuous-co-review/path-identity.ps1)
- Get-ContinuousCoReviewOrdinalUniquePath (scripts/internal/continuous-co-review/path-identity.ps1)
- Get-ContinuousCoReviewCaseVerdictFromListing (scripts/internal/continuous-co-review/path-identity.ps1)
- Get-ContinuousCoReviewPathCaseSensitive (scripts/internal/continuous-co-review/path-identity.ps1)
- Get-ContinuousCoReviewPathComparison (scripts/internal/continuous-co-review/path-identity.ps1)
- Get-ContinuousCoReviewPathComparer (scripts/internal/continuous-co-review/path-identity.ps1)
- ConvertTo-ContinuousCoReviewLiteralPathspec (scripts/internal/continuous-co-review/path-identity.ps1)
- Get-GitReviewTargetTreeEntries (scripts/internal/continuous-co-review/review-target-port.ps1)
- Test-GitReviewTargetSymlinkContained (scripts/internal/continuous-co-review/review-target-port.ps1)
- Assert-GitReviewTargetTreeSymlinksContained (scripts/internal/continuous-co-review/review-target-port.ps1)
- Remove-ContinuousCoReviewGitIgnoredPath (scripts/internal/continuous-co-review/worktree-reviewer.ps1)
- Test-SpecrewReviewRuntimePathUnderRoot (scripts/internal/review-engine-resolution.ps1)
- Assert-SpecrewReviewRuntimePathContained (scripts/internal/review-engine-resolution.ps1)
- Get-SpecrewReviewRuntimeManagedTextSha256 (scripts/internal/review-engine-resolution.ps1)
- ConvertTo-SpecrewReviewRuntimeManagedFileManifest (scripts/internal/review-engine-resolution.ps1)
- Get-SpecrewReviewRuntimeManagedFileManifest (scripts/internal/review-engine-resolution.ps1)
- Get-SpecrewReviewRuntimeBundleSha256 (scripts/internal/review-engine-resolution.ps1)
- Resolve-SpecrewReviewEngineRoot (scripts/internal/review-engine-resolution.ps1)
- Set-ReviewerHostRowField (scripts/specrew-review.ps1)
- exists (specs/198-beta2-hardening/beta2-release-claim.md)
- New-MutantPrimitive (tests/continuous-co-review/unit/path-identity-mutation-gate.Tests.ps1)
- Get-ContinuousCoReviewPathCaseSensitive (tests/continuous-co-review/unit/path-identity-mutation-gate.Tests.ps1)
- Invoke-HarnessAgainstPrimitive (tests/continuous-co-review/unit/path-identity-mutation-gate.Tests.ps1)
- New-VolumeOracleFixtureRoot (tests/continuous-co-review/unit/path-identity-volume-differential.Tests.ps1)
- Get-ObservedEntryName (tests/continuous-co-review/unit/path-identity-volume-differential.Tests.ps1)
- New-DirectoryIfVolumeAllows (tests/continuous-co-review/unit/path-identity-volume-differential.Tests.ps1)
- New-GrantFixtureProject (tests/continuous-co-review/unit/reviewer-host-grant-write-scope.Tests.ps1)
- Get-GrantCatalog (tests/continuous-co-review/unit/reviewer-host-grant-write-scope.Tests.ps1)
- Invoke-GrantRecording (tests/continuous-co-review/unit/reviewer-host-grant-write-scope.Tests.ps1)
- Start-F198RegisteredSuite (tests/f198-regression-suite.ps1)
- Complete-F198RegisteredSuite (tests/f198-regression-suite.ps1)
- Write-F198SuiteResult (tests/f198-regression-suite.ps1)
- Assert-True (tests/unit/review-engine-resolution.tests.ps1)
- New-RuntimeFixture (tests/unit/review-engine-resolution.tests.ps1)

### Removed

- Get-ContinuousCoReviewPathComparison (scripts/internal/continuous-co-review/verification-plan-contract.ps1)

## Module Hotspots

- Threshold: 250 changed lines per file
- specs/198-beta2-hardening/iterations/009/drift-log.md (1263 changed lines)
- specs/198-beta2-hardening/iterations/009/state.md (255 changed lines)
- tests/continuous-co-review/unit/path-identity.Tests.ps1 (358 changed lines)
- tests/f198-regression-suite.ps1 (334 changed lines)

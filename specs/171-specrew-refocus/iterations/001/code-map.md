# Code Map: Iteration 001 — engine, channels, dispatcher, breaker, Claude binding

**Schema**: v1
**Reviewed**: 2026-06-07
**Baseline Ref**: ffb03e73ebf764d56d1a3ac4c8c708eb5e11dead
**Test-to-Code Ratio**: 7:11

> **Review Evidence Warning disposition** _(reviewed, explained)_: the 12-tasks-vs-63-files scaffold flag decomposes as ~30 lifecycle/spec/workshop artifacts + ~33 implementation files, every one committed and traceable to a T0NN boundary commit (full decomposition in coverage-evidence.md).

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .agents/skills/specrew-refocus/.specrew-managed | 4 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .agents/skills/specrew-refocus/SKILL.md | 48 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .claude/skills/specrew-refocus/.specrew-managed | 4 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .claude/skills/specrew-refocus/SKILL.md | 48 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .github/skills/specrew-refocus/.specrew-managed | 4 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .github/skills/specrew-refocus/SKILL.md | 48 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/refocus-scopes.json | 50 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/refocus/before-implement.md | 20 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/refocus/clarify.md | 20 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/refocus/feature-closeout.md | 21 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/refocus/general.md | 30 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/refocus/implement.md | 22 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/refocus/iteration-closeout.md | 21 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/refocus/plan.md | 21 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/refocus/retro.md | 21 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/refocus/review-signoff.md | 26 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/refocus/specify.md | 22 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/refocus/tasks.md | 20 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1 | 130 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/scripts/refocus.ps1 | 494 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 | 538 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1 | 42 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md | 7 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| .squad/decisions.md | 24 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| Specrew.psd1 | 19 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/refocus-scopes.json | 50 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/refocus/before-implement.md | 20 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/refocus/clarify.md | 20 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/refocus/feature-closeout.md | 21 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/refocus/general.md | 30 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/refocus/implement.md | 22 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/refocus/iteration-closeout.md | 21 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/refocus/plan.md | 21 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/refocus/retro.md | 21 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/refocus/review-signoff.md | 26 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/refocus/specify.md | 22 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/refocus/tasks.md | 20 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1 | 130 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/scripts/refocus.ps1 | 494 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 | 538 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/scripts/sync-boundary-state.ps1 | 42 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md | 6 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/refocus.md | 48 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| hosts/claude/host.psd1 | 15 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| scripts/internal/deploy-refocus-hooks.ps1 | 130 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| scripts/internal/refocus.ps1 | 494 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| scripts/internal/specrew-hook-dispatcher.ps1 | 538 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| specs/171-specrew-refocus/contracts/mechanical-findings.schema.json | 77 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| specs/171-specrew-refocus/contracts/specrew-refocus.md | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| specs/171-specrew-refocus/data-model.md | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| specs/171-specrew-refocus/iterations/001/drift-log.md | 51 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| specs/171-specrew-refocus/iterations/001/plan.md | 109 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| specs/171-specrew-refocus/iterations/001/quality/hardening-gate.md | 29 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| specs/171-specrew-refocus/iterations/001/state.md | 35 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| specs/171-specrew-refocus/plan.md | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| specs/171-specrew-refocus/spec.md | 1 | 1 | T001, T004, T006 | Implementer |
| specs/171-specrew-refocus/tasks.md | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012 | Implementer |
| tests/integration/refocus-catalog.tests.ps1 | 126 | 0 | T001, T004, T006 | Implementer |
| tests/integration/refocus-channels.tests.ps1 | 127 | 0 | T001, T004, T006 | Implementer |
| tests/integration/refocus-deploy.tests.ps1 | 117 | 0 | T001, T004, T006 | Implementer |
| tests/integration/refocus-digests.tests.ps1 | 133 | 0 | T001, T004, T006 | Implementer |
| tests/integration/refocus-dispatcher.tests.ps1 | 338 | 0 | T001, T004, T006 | Implementer |
| tests/integration/refocus-engine.tests.ps1 | 224 | 0 | T001, T004, T006 | Implementer |

## Public-API Delta

### Added

- Get-SpecrewHookCommand (.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Test-IsSpecrewHook (.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Remove-SpecrewEntries (.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Write-RefocusWarn (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusProjectRoot (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Test-RefocusConfinedPath (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusCatalog (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusDigestRoot (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Read-RefocusDigest (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusStartContext (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusCurrentBoundary (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusBoundarySuccessor (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusTokenEstimate (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusRuntimeStateFiles (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Format-RefocusPayload (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusFallbackPointerSet (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Invoke-RefocusScopePayload (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Invoke-RefocusRoleScope (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Invoke-RefocusCompactInstructions (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Invoke-RefocusStatus (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Invoke-RefocusResetBreaker (.specify/extensions/specrew-speckit/scripts/refocus.ps1)
- Write-DispatcherWarn (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-DispatcherProjectRoot (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-SanitizedSessionId (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-DispatcherCatalog (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Resolve-ProviderCommandPath (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Invoke-ProviderProcess (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-SessionStatePath (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Read-SessionState (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Save-SessionState (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- New-SessionState (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-BoundaryCursor (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-ChannelOneFingerprint (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Test-B3ShouldInject (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Add-JournalEntry (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-BannerFacts (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Remove-StaleSessionState (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Test-BreakerSuppressed (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Test-BreakerShouldTrip (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Set-BreakerTripped (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-RefocusProviderArgs (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Write-InjectionOutput (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-SpecrewHookCommand (extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Test-IsSpecrewHook (extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Remove-SpecrewEntries (extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Write-RefocusWarn (extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusProjectRoot (extensions/specrew-speckit/scripts/refocus.ps1)
- Test-RefocusConfinedPath (extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusCatalog (extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusDigestRoot (extensions/specrew-speckit/scripts/refocus.ps1)
- Read-RefocusDigest (extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusStartContext (extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusCurrentBoundary (extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusBoundarySuccessor (extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusTokenEstimate (extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusRuntimeStateFiles (extensions/specrew-speckit/scripts/refocus.ps1)
- Format-RefocusPayload (extensions/specrew-speckit/scripts/refocus.ps1)
- Get-RefocusFallbackPointerSet (extensions/specrew-speckit/scripts/refocus.ps1)
- Invoke-RefocusScopePayload (extensions/specrew-speckit/scripts/refocus.ps1)
- Invoke-RefocusRoleScope (extensions/specrew-speckit/scripts/refocus.ps1)
- Invoke-RefocusCompactInstructions (extensions/specrew-speckit/scripts/refocus.ps1)
- Invoke-RefocusStatus (extensions/specrew-speckit/scripts/refocus.ps1)
- Invoke-RefocusResetBreaker (extensions/specrew-speckit/scripts/refocus.ps1)
- Write-DispatcherWarn (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-DispatcherProjectRoot (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-SanitizedSessionId (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-DispatcherCatalog (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Resolve-ProviderCommandPath (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Invoke-ProviderProcess (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-SessionStatePath (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Read-SessionState (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Save-SessionState (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- New-SessionState (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-BoundaryCursor (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-ChannelOneFingerprint (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Test-B3ShouldInject (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Add-JournalEntry (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-BannerFacts (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Remove-StaleSessionState (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Test-BreakerSuppressed (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Test-BreakerShouldTrip (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Set-BreakerTripped (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-RefocusProviderArgs (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Write-InjectionOutput (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Get-SpecrewHookCommand (scripts/internal/deploy-refocus-hooks.ps1)
- Test-IsSpecrewHook (scripts/internal/deploy-refocus-hooks.ps1)
- Remove-SpecrewEntries (scripts/internal/deploy-refocus-hooks.ps1)
- Write-RefocusWarn (scripts/internal/refocus.ps1)
- Get-RefocusProjectRoot (scripts/internal/refocus.ps1)
- Test-RefocusConfinedPath (scripts/internal/refocus.ps1)
- Get-RefocusCatalog (scripts/internal/refocus.ps1)
- Get-RefocusDigestRoot (scripts/internal/refocus.ps1)
- Read-RefocusDigest (scripts/internal/refocus.ps1)
- Get-RefocusStartContext (scripts/internal/refocus.ps1)
- Get-RefocusCurrentBoundary (scripts/internal/refocus.ps1)
- Get-RefocusBoundarySuccessor (scripts/internal/refocus.ps1)
- Get-RefocusTokenEstimate (scripts/internal/refocus.ps1)
- Get-RefocusRuntimeStateFiles (scripts/internal/refocus.ps1)
- Format-RefocusPayload (scripts/internal/refocus.ps1)
- Get-RefocusFallbackPointerSet (scripts/internal/refocus.ps1)
- Invoke-RefocusScopePayload (scripts/internal/refocus.ps1)
- Invoke-RefocusRoleScope (scripts/internal/refocus.ps1)
- Invoke-RefocusCompactInstructions (scripts/internal/refocus.ps1)
- Invoke-RefocusStatus (scripts/internal/refocus.ps1)
- Invoke-RefocusResetBreaker (scripts/internal/refocus.ps1)
- Write-DispatcherWarn (scripts/internal/specrew-hook-dispatcher.ps1)
- Get-DispatcherProjectRoot (scripts/internal/specrew-hook-dispatcher.ps1)
- Get-SanitizedSessionId (scripts/internal/specrew-hook-dispatcher.ps1)
- Get-DispatcherCatalog (scripts/internal/specrew-hook-dispatcher.ps1)
- Resolve-ProviderCommandPath (scripts/internal/specrew-hook-dispatcher.ps1)
- Invoke-ProviderProcess (scripts/internal/specrew-hook-dispatcher.ps1)
- Get-SessionStatePath (scripts/internal/specrew-hook-dispatcher.ps1)
- Read-SessionState (scripts/internal/specrew-hook-dispatcher.ps1)
- Save-SessionState (scripts/internal/specrew-hook-dispatcher.ps1)
- New-SessionState (scripts/internal/specrew-hook-dispatcher.ps1)
- Get-BoundaryCursor (scripts/internal/specrew-hook-dispatcher.ps1)
- Get-ChannelOneFingerprint (scripts/internal/specrew-hook-dispatcher.ps1)
- Test-B3ShouldInject (scripts/internal/specrew-hook-dispatcher.ps1)
- Add-JournalEntry (scripts/internal/specrew-hook-dispatcher.ps1)
- Get-BannerFacts (scripts/internal/specrew-hook-dispatcher.ps1)
- Remove-StaleSessionState (scripts/internal/specrew-hook-dispatcher.ps1)
- Test-BreakerSuppressed (scripts/internal/specrew-hook-dispatcher.ps1)
- Test-BreakerShouldTrip (scripts/internal/specrew-hook-dispatcher.ps1)
- Set-BreakerTripped (scripts/internal/specrew-hook-dispatcher.ps1)
- Get-RefocusProviderArgs (scripts/internal/specrew-hook-dispatcher.ps1)
- Write-InjectionOutput (scripts/internal/specrew-hook-dispatcher.ps1)
- Write-Pass (tests/integration/refocus-catalog.tests.ps1)
- Write-Fail (tests/integration/refocus-catalog.tests.ps1)
- Assert-True (tests/integration/refocus-catalog.tests.ps1)
- Write-Pass (tests/integration/refocus-channels.tests.ps1)
- Write-Fail (tests/integration/refocus-channels.tests.ps1)
- Assert-True (tests/integration/refocus-channels.tests.ps1)
- New-ScratchProject (tests/integration/refocus-channels.tests.ps1)
- Invoke-Wrapper (tests/integration/refocus-channels.tests.ps1)
- Write-Pass (tests/integration/refocus-deploy.tests.ps1)
- Write-Fail (tests/integration/refocus-deploy.tests.ps1)
- Assert-True (tests/integration/refocus-deploy.tests.ps1)
- New-ScratchProject (tests/integration/refocus-deploy.tests.ps1)
- Invoke-Deploy (tests/integration/refocus-deploy.tests.ps1)
- Write-Pass (tests/integration/refocus-digests.tests.ps1)
- Write-Fail (tests/integration/refocus-digests.tests.ps1)
- Write-DriftWarn (tests/integration/refocus-digests.tests.ps1)
- Assert-True (tests/integration/refocus-digests.tests.ps1)
- Get-TokenEstimate (tests/integration/refocus-digests.tests.ps1)
- Read-DigestParts (tests/integration/refocus-digests.tests.ps1)
- Write-Pass (tests/integration/refocus-dispatcher.tests.ps1)
- Write-Fail (tests/integration/refocus-dispatcher.tests.ps1)
- Assert-True (tests/integration/refocus-dispatcher.tests.ps1)
- New-ScratchProject (tests/integration/refocus-dispatcher.tests.ps1)
- Invoke-Dispatcher (tests/integration/refocus-dispatcher.tests.ps1)
- Set-Cursor (tests/integration/refocus-dispatcher.tests.ps1)
- New-SeedState (tests/integration/refocus-dispatcher.tests.ps1)
- New-JournalSeed (tests/integration/refocus-dispatcher.tests.ps1)
- Write-Pass (tests/integration/refocus-engine.tests.ps1)
- Write-Fail (tests/integration/refocus-engine.tests.ps1)
- Assert-True (tests/integration/refocus-engine.tests.ps1)
- Invoke-Engine (tests/integration/refocus-engine.tests.ps1)
- New-ScratchProject (tests/integration/refocus-engine.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- .specify/extensions/specrew-speckit/scripts/refocus.ps1 (494 changed lines)
- .specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 (538 changed lines)
- extensions/specrew-speckit/scripts/refocus.ps1 (494 changed lines)
- extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 (538 changed lines)
- scripts/internal/refocus.ps1 (494 changed lines)
- scripts/internal/specrew-hook-dispatcher.ps1 (538 changed lines)
- tests/integration/refocus-dispatcher.tests.ps1 (338 changed lines)

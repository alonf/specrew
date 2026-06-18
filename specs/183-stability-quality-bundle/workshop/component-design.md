# Component Design Lens Record: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Date**: 2026-06-15
**Depth**: Medium
**Confirmation**: human-confirmed (lens-question scope)

## Component Map

```text
Feature 183 components

SessionStart Delivery Path
  HookDispatcherPolicy
      -> computes cap-aware fragment priority/drop behavior
  BootstrapProviderFallback
      -> emits the minimal fail-loud fallback directive on provider failure
  DirectiveDeliveryCapFixture
      -> builds synthetic SessionStart inputs for hermetic cap assertions

Session Identity and Journal State
  SessionIdResolver
      -> extracts/sanitizes host session IDs and chooses per-launch fallback token
  HookJournalState
      -> owns dedupe/breaker/journal key behavior tied to session identity
  HookLauncherDeploymentCheck
      -> flags when user-level hook launcher redeploy may be required

Closeout Sync and Classification
  CloseoutDirtyClassifier
      -> classifies `.specify` dirty surfaces coherently
  CloseoutRemoteMessage
      -> chooses commit-vs-push wording based on upstream existence
  CloseoutDashboardRefresh
      -> regenerates dashboard on auto-detect closeout paths

Mechanical Test Hygiene
  CloseoutIdentityFixture
      -> isolates scratch git context from the real worktree
  LifecycleSyncCommandAssertion
      -> points ValidateSet checks at the module-internal sync copy

Release and Mirror Discipline
  MirrorParityCheckpoint
      -> keeps source and deployed extension copies aligned
  ReleaseValidationThread
      -> records next beta target, real-host validation, and stable promotion gate

Antigravity Hook Support
  AntigravityHookManifest
      -> adds verified hook capability metadata to the Antigravity host manifest
  AntigravityHookConfigAdapter
      -> deploys Specrew hook entries into project-scoped .agents/hooks.json using Antigravity's supported hooks.json shape
  AntigravityEventAdapter
      -> maps verified Antigravity events to Specrew SessionStart/Stop-style behavior
  AntigravityHookDocsCleanup
      -> removes stale Antigravity-no-hooks wording once support ships
```

## Accepted Components

- **HookDispatcherPolicy** — computes cap-aware fragment priority/drop behavior.
- **BootstrapProviderFallback** — emits the minimal fail-loud fallback directive
  on provider failure.
- **DirectiveDeliveryCapFixture** — builds synthetic SessionStart inputs for
  hermetic cap assertions.
- **SessionIdResolver** — extracts/sanitizes host session IDs and chooses a
  per-launch fallback token.
- **HookJournalState** — owns dedupe/breaker/journal key behavior tied to
  session identity.
- **HookLauncherDeploymentCheck** — flags when user-level hook launcher redeploy
  may be required.
- **CloseoutDirtyClassifier** — classifies `.specify` dirty surfaces coherently.
- **CloseoutRemoteMessage** — chooses commit-vs-push wording based on upstream
  existence.
- **CloseoutDashboardRefresh** — regenerates dashboard on auto-detect closeout
  paths.
- **CloseoutIdentityFixture** — isolates scratch git context from the real
  worktree.
- **LifecycleSyncCommandAssertion** — points ValidateSet checks at the
  module-internal sync copy.
- **MirrorParityCheckpoint** — keeps source and deployed extension copies aligned.
- **ReleaseValidationThread** — records next beta target, real-host validation,
  and stable promotion gate.
- **AntigravityHookManifest** — adds verified hook capability metadata to the
  Antigravity host manifest.
- **AntigravityHookConfigAdapter** — deploys Specrew hook entries into
  project-scoped `.agents/hooks.json` using Antigravity's supported `hooks.json`
  shape while preserving user hooks.
- **AntigravityEventAdapter** — maps verified Antigravity events to Specrew
  startup/refocus/handover behavior without claiming unsupported parity.
- **AntigravityHookDocsCleanup** — removes stale Antigravity-no-hooks wording
  from user-facing docs once support ships.

## Dependency Direction

```text
Tests / Evidence
  -> public command/script entry points where possible
  -> focused helper seams only when production entry points would be too broad

Runtime paths
  HookDispatcherPolicy
    -> no dependency on fallback text details
  BootstrapProviderFallback
    -> uses centralized fallback text only
  SessionIdResolver
    -> used by HookJournalState / dedupe / breaker paths
  CloseoutDirtyClassifier
    -> used by sync-boundary-state closeout flow
  CloseoutDashboardRefresh
    -> invoked by closeout auto-detect path
  AntigravityHookConfigAdapter
    -> uses verified Antigravity hook config schema
  AntigravityEventAdapter
    -> maps only verified Antigravity events to Specrew dispatcher events

Mirror discipline
  source files are authoritative
  .specify/extensions mirror follows source
```

Dependency rules:

- Keep cap policy separate from fallback text.
- Keep session ID extraction separate from journal writing.
- Keep closeout classification separate from closeout dashboard rendering.
- Keep tests hermetic and avoid assertions against ambient repo state.
- Mirror source to `.specify` after touched extension/runtime files change.
- Keep Antigravity hook capability separate from generic supported-host status;
  support is governed by verified hook bindings, not by host availability alone.

## Test Strategy

```text
HookDispatcherPolicy
  - Pester test: over-cap join preserves bootstrap and drops/shrinks lower-priority refocus.
  - Evidence: measured composite under host cap.

BootstrapProviderFallback
  - Pester test: provider exception emits minimal fallback directive on stdout and exits 0.
  - Evidence: fallback text remains under cap and names recovery commands.

DirectiveDeliveryCapFixture
  - Pester test: synthetic startup SessionStart event measures shipped composite, not ambient refocus.

SessionIdResolver / HookJournalState
  - Pester tests: missing/blank/malformed session IDs get a per-launch fallback token, not global unknown.
  - Evidence: status/journal/dedupe keys no longer collapse under `unknown`.

CloseoutDirtyClassifier / CloseoutRemoteMessage / CloseoutDashboardRefresh
  - Pester tests for `.specify` companion files, no-upstream message, and auto-detect dashboard regeneration.
  - Evidence: closeout sync output/dashboard reflects the path taken.

CloseoutIdentityFixture / LifecycleSyncCommandAssertion
  - Pester tests stop depending on real worktree dirtiness and inspect the module-internal sync script.

AntigravityHookManifest / AntigravityHookConfigAdapter / AntigravityEventAdapter
  - Pester tests prove Antigravity becomes hook-capable only with verified RefocusHookBindings.
  - Deployment tests prove Antigravity hooks are provisioned in the expected hooks.json location/shape and preserve user entries.
  - Contract tests prove mapped Antigravity events invoke Specrew dispatcher/provider behavior and docs no longer use stale Antigravity-no-hooks wording.
```

Real-host evidence is still required for the SessionStart delivery path before
stable promotion.

## Mirror and Release Ownership

Mirror means source-to-deployed extension parity inside this project:

- Source/package side:
  `file:///C:/Dev/183-stability-quality-bundle/extensions/specrew-speckit/`
- Deployed project side:
  `file:///C:/Dev/183-stability-quality-bundle/.specify/extensions/specrew-speckit/`

This is distinct from host deployment/fanout of hooks or skills into AI host
locations. For this feature, mirror parity means touched Specrew extension
scripts/templates stay aligned between source and `.specify`.

For each touched runtime/extension file:

```text
source change
  -> immediate mirror update into .specify/extensions/specrew-speckit
  -> parity check before boundary/review
```

For release:

```text
implementation/review complete
  -> check current published/tagged beta state
  -> choose next 0.37.0-beta<N>
  -> real-host validation
  -> stable promotion only after validation PASS
```

# Implementation Plan: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Design-analysis verdict**: `approved for plan with Option B`
**Branch**: `183-stability-quality-bundle`
**Date**: 2026-06-16

## Summary

Deliver the eight clarified FRs as one human-approved 24/20 SP stability
iteration. The implementation keeps the original bug-bash fixes as vertical
slices over the existing Specrew PowerShell/Pester/runtime surfaces, and DR-004
Option A accepts the generalized hook-capable host model refactor into this
feature rather than splitting it out.

The plan consumes Option B from
file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/design-analysis.md.
It does not create a new parser package, dependency, or release mechanism. It
does create the accepted `RefocusHookBindings` host-manifest model for hook
deploy/status behavior, with no parity claim beyond verified events.

## Technical Context

- **Runtime**: PowerShell 7+ scripts/module code, JSON/YAML config, markdown
  governance artifacts, and Pester/integration-style test scripts.
- **Primary source paths**: file:///C:/Dev/183-stability-quality-bundle/extensions/specrew-speckit/
  and file:///C:/Dev/183-stability-quality-bundle/scripts/.
- **Deployed mirror path**: file:///C:/Dev/183-stability-quality-bundle/.specify/extensions/specrew-speckit/.
- **Host registry path**: file:///C:/Dev/183-stability-quality-bundle/hosts/.
- **Test paths**: file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/,
  file:///C:/Dev/183-stability-quality-bundle/tests/integration/, and
  file:///C:/Dev/183-stability-quality-bundle/tests/unit/.
- **Dependency policy**: use existing project tools; no new runtime dependency.
- **Release rule**: do not hard-code a beta suffix. At release time, inspect
  local tags, origin tags, and published package/release state, then select the
  next valid `0.37.0-beta<N>`.

## Quality Planning

The quality-profile resolver currently detects a repository-level React signal,
but this feature's scoped surfaces are PowerShell governance/runtime code,
host-registry metadata, JSON/YAML config, markdown docs, and Pester tests. The
plan therefore overrides the inferred preset to the feature workshop's resolved
stack: `powershell-json-yaml-pester`.

### Required Quality Gates

| Gate | Evidence |
| --- | --- |
| SessionStart cap/fallback tests | Deterministic Pester tests for FR-001 and FR-002. |
| Session-key state tests | Missing/blank/malformed host session IDs no longer write/report under global `unknown`. |
| Directive cap hermeticity | `tests/bootstrap/DirectiveDeliveryCap.Tests.ps1` uses synthetic SessionStart input. |
| Closeout sync tests | Dirty `.specify`, no-upstream wording, and auto-detect dashboard regeneration fixtures. |
| #1761 local red cleanup | Scratch git isolation and module-internal sync-script assertion tests. |
| Antigravity hook tests | Config merge/remove/opt-out tests plus verified-event contract tests. |
| Host hook model tests | Manifest-driven deploy/status tests for hook-capable hosts and schema failure paths. |
| Mirror parity | Touched source and `.specify` mirror files are byte-aligned. |
| Real-host validation | SessionStart/fallback reaches at least one real hook-capable host; Antigravity real-host validation before stable if FR-007 ships. |

### Hardening Focus

- Hook inputs are untrusted host payloads; sanitize session IDs and config data.
- Provider failures fail open with governed fallback text on stdout and exit 0.
- Antigravity hook config writes must preserve user entries and abort safely on
  unsafe parse/merge.
- Tests that create dirty git state must use scratch repos and never operate on
  the real worktree.
- Docs and status must label partial Antigravity support honestly.

## Architecture

Option B originally used modular vertical slices. DR-004 Option A amends that
plan by accepting a small host-model abstraction for hook deploy/status binding
data, while keeping enforcement and parity claims tied to verified behavior.

| Component | Responsibility | Primary Evidence |
| --- | --- | --- |
| HookDispatcherPolicy | Preserve bootstrap when combined SessionStart output is over cap. | FR-001 / SC-001 tests |
| BootstrapProviderFallback | Emit minimal governed fallback if provider execution fails. | FR-002 / SC-002 tests |
| DirectiveDeliveryCapFixture | Build synthetic shipped SessionStart input for cap tests. | FR-004 / SC-004 |
| SessionIdResolver | Sanitize host session ID or generate per-launch fallback token. | FR-003 / SC-003 |
| HookJournalState | Key dedupe/breaker/journal state by resolved session token. | FR-003 / SC-003 |
| CloseoutDirtyClassifier | Classify `.specify` dirty surfaces coherently. | FR-005 / SC-005 |
| CloseoutRemoteMessage | Render push wording only when upstream exists. | FR-005 / SC-005 |
| CloseoutDashboardRefresh | Regenerate dashboard on closeout auto-detect. | FR-005 / SC-005 |
| CloseoutIdentityFixture | Isolate dirty-state tests in scratch git repos. | FR-006 / SC-006 |
| LifecycleSyncCommandAssertion | Assert against module-internal sync script copy. | FR-006 / SC-006 |
| AntigravityHookManifest | Add hook-capable metadata only for verified Antigravity bindings. | FR-007 / SC-009 |
| AntigravityHookConfigAdapter | Merge Specrew entries into project `.agents/hooks.json` without clobbering user hooks. | FR-007 / SC-009 |
| AntigravityEventAdapter | Map only verified Antigravity events/output semantics to Specrew behavior. | FR-007 / TG-004 |
| AntigravityHookDocsCleanup | Remove stale no-hooks wording and document fallback. | FR-007 / LIR-008 |
| RefocusHookBindingContract | Define manifest fields for hook settings path, command mode, config shape, registrations, ownership, and project-root signals. | FR-008 / TG-006 |
| ManifestDrivenHookDeployer | Render, merge, remove, and preserve hook entries using `RefocusHookBindings` instead of host-name branches. | FR-008 / SC-010 |
| ManifestDrivenHookHealth | Report installed/missing/stale/opted-out hook status from host manifest data. | FR-008 / SC-010 |
| MirrorParityCheckpoint | Keep touched source and deployed mirror aligned. | SC-007 / TG-003 |
| ReleaseValidationThread | Record beta choice and real-host validation before stable. | SC-007 / SC-008 |

## FR-to-Test Mapping

| Requirement | Planned Test / Evidence |
| --- | --- |
| FR-001 | Add/adjust dispatcher tests proving bootstrap survives over-cap output and refocus is dropped/shrunk first. |
| FR-002 | Provider-failure fixture proves stdout fallback is non-empty, under cap, exit 0, and names recovery commands. |
| FR-003 | Session resolver/journal tests prove missing/blank/malformed IDs use a per-launch token, not global `unknown`. |
| FR-004 | Rewrite `DirectiveDeliveryCap.Tests.ps1` to use a synthetic shipped SessionStart composite. |
| FR-005 | Closeout sync fixtures cover `.specify` dirty companion files, no-upstream wording, and dashboard refresh. |
| FR-006 | #1761 tests run against scratch git/module-internal files for the intended reasons. |
| FR-007 | Refocus deploy/hooks command tests cover Antigravity hook capability, `.agents/hooks.json` merge/remove/opt-out, verified events, docs cleanup, and fallback status. |
| FR-008 | Manifest-driven hook deploy/status tests prove hook binding data comes from `hosts/<kind>/host.psd1` and existing hook-capable hosts keep their behavior. |
| TG-003 | Mirror parity check for every touched extension/runtime file. |
| TG-004 | Antigravity parity evidence names verified events/output behavior and labels unsupported events degraded/deferred. |
| TG-005 | Closeout links fixes to issues #2446, #1627, and #1761. |
| TG-006 | Host-model evidence maps manifest schema, deploy behavior, status behavior, and mirror copies for touched hook-capable hosts. |

## Capacity Plan

The default iteration capacity remains 20 story_points. DR-004 Option A accepts
the expanded host-model refactor into F-183 and re-baselines this iteration to
24/20 story_points as an explicit human-approved over-cap exception.

| Slice | Requirements | Effort |
| --- | --- | ---: |
| SessionStart cap policy and provider fallback | FR-001, FR-002, SC-001, SC-002 | 4.0 |
| Delivery-cap hermetic fixture | FR-004, SC-004 | 2.0 |
| Session ID resolver and journal state | FR-003, SC-003 | 3.0 |
| Closeout classification, upstream wording, dashboard refresh | FR-005, SC-005 | 4.0 |
| #1761 mechanical test hygiene | FR-006, SC-006 | 2.0 |
| Antigravity hook binding, config merge, docs cleanup, verified-event tests | FR-007, SC-009, TG-004 | 4.0 |
| Manifest-driven hook-capable host model | FR-008, SC-010, TG-006 | 4.0 |
| Mirror/release readiness evidence and integration pass | SC-007, SC-008, TG-003, TG-005 | 1.0 |
| **Total** |  | **24.0** |

## Phase Baseline

| Phase | Effort |
| --- | ---: |
| Planning and artifact authoring | 2.0 |
| Discovery/spikes | 1.0 |
| Implementation | 17.0 |
| Review and deterministic validation | 3.0 |
| Expected rework | 1.0 |
| **Total** | **24.0** |

## Split Guard

FR-007 remains in scope under Option B. DR-004 Option A accepts one expansion
that crossed the original split guard: the generalized `RefocusHookBindings`
host-manifest model needed to keep hook binding data in host packages rather
than shared core branches. That expansion is now explicit FR-008 scope.

Further FR-007 or FR-008 growth still requires a fresh human split/defer
decision. The accepted expansion is limited to:

- project-scoped `.agents/hooks.json` merge/remove/opt-out support;
- verified event mapping only;
- docs/status cleanup for stale no-hooks wording;
- fallback guidance through `specrew start --host antigravity`;
- real-host validation before stable;
- manifest fields for hook settings path, opt-out marker, dispatcher path,
  config shape, command mode, registrations, ownership/version metadata, and
  project-root signals;
- deploy/status behavior that consumes those manifest fields for touched
  hook-capable hosts.

Any full parity work for unverified SessionStart/Stop behavior, generalized host
capability matrices beyond hook deployment/status, payload optimization, or
broader Stop-hook handover belongs to a new human-approved feature or later
iteration.

## Plan Outputs

- Data model: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/data-model.md
- Quickstart: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/quickstart.md
- Contract: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/contracts/stability-quality-bundle.md
- Review diagrams: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/review-diagrams.md
- Iteration plan: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/plan.md

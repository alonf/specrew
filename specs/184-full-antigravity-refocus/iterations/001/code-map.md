# Code Map: F-184 Iteration 001

## Scope

Implementation range: `593fcc4e..2e75d114`.

This map links the F-184 requirements to the changed implementation and test
surfaces reviewed at signoff.

## Runtime And Adapter Surfaces

| Surface | Change | Requirements |
| --- | --- | --- |
| `scripts/internal/bootstrap/HostEventAdapter.ps1` | Antigravity `conversationId` normalization into the existing session identity model; host-name validation is pattern-based rather than a shared-core enum. | FR-001, FR-002 |
| `scripts/internal/bootstrap/SessionStateAccessor.ps1` | Existing per-session refocus state model reused for Antigravity anchors and marker identity. | FR-002, FR-004 |
| `scripts/internal/bootstrap/ClassificationEngine.ps1` | Same-session marker classification distinguishes Antigravity's own marker from competing sessions. | FR-004 |
| `scripts/internal/bootstrap/SessionBootstrapManager.ps1` | Antigravity bootstrap uses the real conversation id for dedupe/state and suppresses own-marker advisory; host parameters no longer hardcode the five-host enum. | FR-001, FR-002, FR-004, FR-005 |
| `scripts/internal/specrew-hook-dispatcher.ps1` | Hook routing/output policy is manifest-driven via `DispatcherRuntime`: Antigravity `PreInvocation` routes B2/B3 through existing refocus machinery and emits `injectSteps`; `PostToolUse` remains non-injection without a shared-core Antigravity branch. | FR-003, FR-006, FR-010 |
| `scripts/internal/deploy-refocus-hooks.ps1` | Antigravity hook deployment preserves user hooks, installs `PreInvocation`/`Stop`, bakes deterministic encoded host runtime binding into hook commands, and carries `-ModulePath` when `SPECREW_MODULE_PATH` is valid. | FR-005, FR-007, FR-009, FR-010 |
| `extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1` | Mirrored deployed extension copy of the deployer. | FR-005, FR-007 |
| `.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1` | Project-local deployed copy kept byte-identical to source. | FR-005, FR-007 |

## Host Metadata And Docs

| Surface | Change | Requirements |
| --- | --- | --- |
| `hosts/*/host.psd1` | Hook-capable manifests declare `RefocusHookBindings.DispatcherRuntime` so bootstrap events, B3 events, output shape, decision-only events, and pointer/inline mode are host metadata rather than shared-core conditionals. | FR-003, FR-005, FR-010 |
| `hosts/antigravity/handlers.ps1` | Launch binary resolution uses `hosts/antigravity/host.psd1` `Binary` instead of duplicating `agy` in the handler. | FR-005, FR-010 |
| `README.md` and `docs/**` | Antigravity appears at host-level documentation depth with `agy`, hook install/remove/status, permission, sandbox, recovery, and evidence-gated status guidance. | FR-008, FR-009, TG-006 |
| `specs/184-full-antigravity-refocus/iterations/001/*.md` | Discovery, validation, real-host evidence, review, and state artifacts record traceability and release honesty. | TG-001 through TG-006 |

## Test Surfaces

| Surface | Evidence |
| --- | --- |
| `tests/bootstrap/HostEventAdapter.Tests.ps1` | Proves Antigravity `conversationId` normalization and no `unknown` fallback when a real id exists. |
| `tests/bootstrap/SessionStateAccessor.Tests.ps1` | Proves marker and state accessor behavior. |
| `tests/bootstrap/ClassificationEngine.Tests.ps1` | Proves same-session marker is not concurrent and different fresh marker remains concurrent. |
| `tests/bootstrap/SessionBootstrapManager.Tests.ps1` | Proves Antigravity dedupe key, marker storage, and own-marker suppression. |
| `tests/bootstrap/Regression.Tests.ps1` | Proves Antigravity `PreInvocation` is the B2/B3 carrier and B1 remains unsupported. |
| `tests/integration/refocus-dispatcher.tests.ps1` | Proves B3 `injectSteps`, dedupe, no `PostToolUse` injection, fail-open diagnostics, and no prompt leakage. |
| `tests/integration/refocus-deploy.tests.ps1` | Proves hook preservation, manifest behavior, encoded launcher shape, deterministic host runtime binding, opt-out, and T008 `-ModulePath` dogfood fix. |
| `tests/integration/specrew-hooks-command.tests.ps1` | Proves hook install/status/remove command behavior for Antigravity and stale legacy refresh. |
| `tests/integration/host-coupling-firewall.tests.ps1` | Blocks shared-core `agy` lookup and Antigravity routing literals; verifies host runtime policy stays manifest-driven. |
| `tests/integration/host-registry.tests.ps1` | Requires every hook-capable host manifest to declare dispatcher runtime policy. |
| `tests/integration/host-detection-ux.tests.ps1` | Proves Antigravity launch binary resolution follows the manifest `Binary` field. |
| `tests/integration/filelist-completeness.tests.ps1` | Proves deployable source roots and `Specrew.psd1` FileList stay bidirectionally aligned. |

## Design Trace

| Design Decision | Implementation Disposition |
| --- | --- |
| Reuse existing refocus machinery. | Satisfied. B3 uses existing dispatcher/state/dedupe/breaker paths; no parallel Antigravity-only refocus system was introduced. |
| Keep Antigravity bounded to host adapter/manifest/state/helper changes. | Satisfied after sendback repair. Runtime changes are in existing bootstrap/dispatcher/deployer surfaces; host-specific hook behavior is manifest data. |
| Map B3 to `PreInvocation`, not `PostToolUse`. | Satisfied. Manifest runtime policy maps Antigravity B3 to `PreInvocation`; automated tests prove `PreInvocation` emits `injectSteps` and `PostToolUse` does not. |
| Preserve F-183 bootstrap and Stop handover. | Satisfied. Real-host evidence and regression tests prove `PreInvocation` and `Stop` still fire. |
| Avoid full parity claims before proof. | Satisfied. Evidence is labeled machine-local and release/stable gates remain explicit. |

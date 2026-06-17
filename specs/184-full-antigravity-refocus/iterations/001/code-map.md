# Code Map: F-184 Iteration 001

## Scope

Implementation range: `593fcc4e..2e75d114`.

This map links the F-184 requirements to the changed implementation and test
surfaces reviewed at signoff.

## Runtime And Adapter Surfaces

| Surface | Change | Requirements |
| --- | --- | --- |
| `scripts/internal/bootstrap/HostEventAdapter.ps1` | Antigravity `conversationId` normalization into the existing session identity model. | FR-001, FR-002 |
| `scripts/internal/bootstrap/SessionStateAccessor.ps1` | Existing per-session refocus state model reused for Antigravity anchors and marker identity. | FR-002, FR-004 |
| `scripts/internal/bootstrap/ClassificationEngine.ps1` | Same-session marker classification distinguishes Antigravity's own marker from competing sessions. | FR-004 |
| `scripts/internal/bootstrap/SessionBootstrapManager.ps1` | Antigravity bootstrap uses the real conversation id for dedupe/state and suppresses own-marker advisory. | FR-001, FR-002, FR-004, FR-005 |
| `scripts/internal/specrew-hook-dispatcher.ps1` | Antigravity `PreInvocation` routes B2/B3 through existing refocus machinery and emits `injectSteps`; `PostToolUse` remains non-injection. | FR-003, FR-006, FR-010 |
| `scripts/internal/deploy-refocus-hooks.ps1` | Antigravity hook deployment preserves user hooks, installs `PreInvocation`/`Stop`, and now bakes `-ModulePath` into launcher commands when `SPECREW_MODULE_PATH` is valid. | FR-005, FR-007, FR-009 |
| `extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1` | Mirrored deployed extension copy of the deployer. | FR-005, FR-007 |
| `.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1` | Project-local deployed copy kept byte-identical to source. | FR-005, FR-007 |

## Host Metadata And Docs

| Surface | Change | Requirements |
| --- | --- | --- |
| `hosts/antigravity/host.json` | Manifest declares Antigravity B2+B3 support through `PreInvocation` and `Stop`, without B1 compaction support. | FR-003, FR-005, FR-010 |
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
| `tests/integration/refocus-deploy.tests.ps1` | Proves hook preservation, manifest behavior, encoded launcher shape, opt-out, and T008 `-ModulePath` dogfood fix. |
| `tests/integration/specrew-hooks-command.tests.ps1` | Proves hook install/status/remove command behavior for Antigravity and stale legacy refresh. |
| `tests/integration/filelist-completeness.tests.ps1` | Proves deployable source roots and `Specrew.psd1` FileList stay bidirectionally aligned. |

## Design Trace

| Design Decision | Implementation Disposition |
| --- | --- |
| Reuse existing refocus machinery. | Satisfied. B3 uses existing dispatcher/state/dedupe/breaker paths; no parallel Antigravity-only refocus system was introduced. |
| Keep Antigravity bounded to host adapter/manifest/state/helper changes. | Satisfied. Runtime changes are in existing bootstrap/dispatcher/deployer surfaces; non-Antigravity host contracts remain unchanged. |
| Map B3 to `PreInvocation`, not `PostToolUse`. | Satisfied. Automated tests prove `PreInvocation` emits `injectSteps`; `PostToolUse` does not. |
| Preserve F-183 bootstrap and Stop handover. | Satisfied. Real-host evidence and regression tests prove `PreInvocation` and `Stop` still fire. |
| Avoid full parity claims before proof. | Satisfied. Evidence is labeled machine-local and release/stable gates remain explicit. |

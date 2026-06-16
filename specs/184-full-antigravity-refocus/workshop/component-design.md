# Component Design Lens

## Decision

Reuse the existing Specrew refocus component design. F-184 mostly uses current
components and may add one small helper if needed to keep the Antigravity
self-marker concurrency exception out of the dispatcher.

## Component Map

```text
Antigravity hooks
  PreInvocation / Stop
          |
          v
+-------------------------+
| SpecrewHookDispatcher   |
+-----------+-------------+
            |
    +-------+-------------------------------+
    |                                       |
    v                                       v
+----------------------+        +--------------------------+
| HostEventAdapter     |        | HandoverProvider/Store   |
| Antigravity mapping  |        | Stop handover            |
+----------+-----------+        +--------------------------+
           |
           v
+----------------------+        +--------------------------+
| SessionStateAccessor |<------>| ClassificationEngine     |
| per-session anchor   |        | boundary cursor          |
+----------+-----------+        +------------+-------------+
           |                                 |
           +---------------+-----------------+
                           v
                 +---------------------+
                 | Test-B3ShouldInject |
                 | boundary-cross only |
                 +----------+----------+
                            |
                            v
                 +---------------------+
                 | RefocusProvider     |
                 | inject discipline   |
                 +---------------------+
```

## Responsibilities

### Managers

- `SpecrewHookDispatcher` - routes host hook events and owns the
  bootstrap/refocus/handover decision path.
- `RefocusHookDeploymentManager` - deploys `RefocusHookBindings` from host
  manifests into host config without clobbering user hooks.
- `SessionBootstrapManager` - builds governed startup/bootstrap directives.
- `HandoverProvider` / `HandoverStore` - writes durable Stop/handover state
  through the existing save path.

### Engines

- `HostEventAdapter` with Antigravity mapping - normalizes `PreInvocation` and
  `Stop` payload shape into the dispatcher's expected event model.
- `ClassificationEngine` - reads lifecycle/boundary truth and exposes the
  boundary cursor B3 watches.
- `Test-B3ShouldInject` - decides whether refocus should inject based on
  boundary cursor change, dedupe, and breaker state.
- `ConcurrencyMarkerClassifier` - small helper if needed; distinguishes
  Antigravity's own session marker from a real competing session.
- `DirectiveEngine` / `RefocusProvider` - composes the actual
  refocus/bootstrap payload.

### Resource Accessors

- `SessionStateAccessor` - owns per-session refocus state/anchor read/write.
- `ProjectMetadataAccessor` - resolves project/worktree/start-context metadata.
- `HostManifestAccessor` - reads host manifests and `RefocusHookBindings`.
- `HostConfigAccessor` - reads/writes `.agents/hooks.json` while preserving user
  entries.
- `RuntimeStateStore` - stores `.specrew/runtime/refocus-state-*.json` and
  marker files.

## Key Flow

```text
agy turn -> PreInvocation -> Dispatcher -> Antigravity event mapping
-> SessionStateAccessor + ClassificationEngine -> Test-B3ShouldInject
-> RefocusProvider -> inject only on real boundary crossing
```

## Binding Constraints

- Do not create a parallel Antigravity-only refocus subsystem.
- Keep Antigravity variance inside the host adapter, config accessor, or a
  small marker-classification helper.
- Keep B3 decision behavior in the existing `Test-B3ShouldInject` path.
- Preserve existing Stop handover and bootstrap components.

## Confirmation

Human accepted the component map as mostly existing design with maybe one new
small helper.

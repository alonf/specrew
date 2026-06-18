# Review Diagrams: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Phase**: pre-implementation planning artifact for reviewer

## Component Diagram

```mermaid
flowchart LR
  Host[Host Hook Event] --> Dispatcher[Hook Dispatcher]
  Dispatcher --> Cap[HookDispatcherPolicy]
  Dispatcher --> Fallback[BootstrapProviderFallback]
  Dispatcher --> Session[SessionIdResolver]
  Session --> Journal[HookJournalState]
  Cap --> Output[Governed Host Output]
  Fallback --> Output

  Closeout[Closeout Sync] --> Dirty[CloseoutDirtyClassifier]
  Closeout --> Remote[CloseoutRemoteMessage]
  Closeout --> Dashboard[CloseoutDashboardRefresh]

  Hooks[specrew hooks] --> AGManifest[AntigravityHookManifest]
  AGManifest --> AGConfig[AntigravityHookConfigAdapter]
  AGConfig --> AGEvents[AntigravityEventAdapter]

  Source[Source Extension Files] --> Mirror[.specify Mirror]
  Tests[Deterministic Tests] --> Evidence[Review Evidence]
  Mirror --> Evidence
  Output --> Evidence
  Dashboard --> Evidence
  AGEvents --> Evidence
```

## Sequence: SessionStart Degraded But Governed

```mermaid
sequenceDiagram
  participant Host
  participant Dispatcher
  participant CapPolicy
  participant Provider
  participant SessionResolver
  participant Journal

  Host->>Dispatcher: SessionStart event
  Dispatcher->>SessionResolver: resolve session key
  SessionResolver-->>Dispatcher: host id or per-launch fallback token
  Dispatcher->>Provider: build bootstrap/refocus fragments
  alt provider succeeds
    Provider-->>Dispatcher: fragments
    Dispatcher->>CapPolicy: compose under cap
    CapPolicy-->>Dispatcher: bootstrap preserved, refocus trimmed if needed
  else provider fails
    Provider-->>Dispatcher: exception
    Dispatcher-->>Dispatcher: build governed fallback
  end
  Dispatcher->>Journal: record state/diagnostic by session key
  Dispatcher-->>Host: governed bootstrap or degraded fallback, exit 0
```

## Sequence: Antigravity Hook Install

```mermaid
sequenceDiagram
  participant User
  participant HooksCLI as specrew hooks
  participant Registry as Host Registry
  participant Adapter as AntigravityHookConfigAdapter
  participant Config as .agents/hooks.json
  participant Status as hooks status/docs

  User->>HooksCLI: install --host antigravity
  HooksCLI->>Registry: resolve verified RefocusHookBindings
  Registry-->>HooksCLI: Antigravity hook-capable metadata
  HooksCLI->>Adapter: merge Specrew-owned hook entries
  Adapter->>Config: parse existing project config
  alt config safe
    Adapter->>Config: preserve user entries and write Specrew entries
    Adapter-->>Status: installed/verified subset
  else config unsafe
    Adapter-->>Status: fail open, report unsupported shape
  end
  Status-->>User: use specrew start --host antigravity for fallback if needed
```

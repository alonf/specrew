# Review Diagrams: Hook-Driven Session Bootstrap

**Feature**: 174-hook-driven-session-bootstrap
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram

```mermaid
flowchart TB
  Dispatcher["F-171 HookDispatcher (reused)"]
  Dispatcher --> BM[SessionBootstrapManager]
  Dispatcher --> HM[SessionEndHandoverManager]
  BM --> CE["ClassificationEngine (pure)"]
  BM --> DE["DirectiveEngine (pure)"]
  BM --> VE[ValidationEngine]
  VE --> HS[HandoverStore]
  VE --> PMA[ProjectMetadataAccessor]
  VE --> SSA[SessionStateAccessor]
  BM --> HJA[HookJournalAccessor]
  HM --> HS
  HEA[HostEventAdapter] --> Dispatcher
  LI[LauncherIntegration] --> Dispatcher
  DE --> Agent["agent renders prose + menu"]
```

## Sequence: full bootstrap that clears a stale anchor

```mermaid
sequenceDiagram
  participant User
  participant Dispatcher as F-171 Dispatcher (B2)
  participant Mgr as SessionBootstrapManager
  participant VE as ValidationEngine
  participant CE as ClassificationEngine
  participant DE as DirectiveEngine
  participant J as HookJournalAccessor
  participant Agent
  User->>Dispatcher: direct host launch
  Dispatcher->>Mgr: SessionStart B2 event
  Mgr->>VE: validate handover + anchor vs project
  VE-->>Mgr: handover invalid; anchor merged/absolute -> cleared
  Mgr->>CE: classify(no valid resume)
  CE-->>Mgr: mode = full (reason: cleared stale anchor)
  Mgr->>DE: build directive(full, findings)
  DE-->>Mgr: directive{render_first, findings}
  Mgr->>J: record{mode:full, anchor_cleared:merged}
  Mgr-->>Agent: inject directive
  Agent-->>User: prose orientation + "Cleared a stale anchor" + Resume/New/Pick
```

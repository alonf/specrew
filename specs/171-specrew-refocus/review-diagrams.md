# Review Diagrams: Specrew Refocus

**Feature**: 171-specrew-refocus
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram

```mermaid
flowchart TB
  subgraph Adapters["Trigger adapters (volatile, per-host)"]
    Skill["/specrew-refocus skill"]
    Dispatcher["SpecrewHookDispatcher"]
    Advisory["CoordinatorAdvisory"]
  end
  subgraph Hooks["Host events (research-gated per host)"]
    Claude["Claude: SessionStart / PostToolUse"]
    AG["Antigravity*"]
    Cur["Cursor*"]
    Cod["Codex notify*"]
  end
  Provider["RefocusProvider (registry row 1)"]
  State["RuntimeSessionState\n(dedupe + breaker + journal)"]
  Engine["RefocusEngine (stable, pure)"]
  Catalog["refocus-scopes.yml\n(scopes/triggers/budgets/registry)"]
  Digests["refocus digests\n(general + 10 stages)"]
  Wrapper["WrapperEmission\n(boundary-sync stdout, ALL hosts)"]

  Claude --> Dispatcher
  AG --> Dispatcher
  Cur --> Dispatcher
  Cod --> Dispatcher
  Dispatcher --> Provider
  Provider --> Engine
  Dispatcher --- State
  Skill --> Engine
  Wrapper --> Engine
  Engine --> Catalog
  Engine --> Digests
```

## Sequence: B1 post-compaction (Claude)

```mermaid
sequenceDiagram
  participant Host as Claude Code
  participant D as Dispatcher
  participant P as RefocusProvider
  participant E as Engine
  participant S as SessionState
  Host->>D: SessionStart {source: compact, session_id}
  D->>D: env kill-switch? .specrew present? sanitize id
  D->>S: read breaker + fingerprints
  D->>P: normalized event
  P->>E: --trigger b1
  E->>E: catalog -> general + current stage + role
  E-->>P: banner + payload
  P-->>D: fragment
  D->>S: journal {b1, hook, injected} + fingerprint
  D-->>Host: additionalContext (payload)
```

## Sequence: B3 dedupe across channels

```mermaid
sequenceDiagram
  participant Crew as Crew (any host)
  participant W as boundary-sync wrapper
  participant E as Engine
  participant S as SessionState
  participant D as Dispatcher (hook hosts)
  Crew->>W: advance boundary
  W->>E: --boundary <next>
  E-->>W: payload
  W->>S: fingerprint injection
  W-->>Crew: stdout: sync result + payload (in context)
  Note over D: next hook event
  D->>S: state-diff: cursor moved? fingerprinted?
  S-->>D: fingerprint present
  D->>S: journal {b3, hook, deduped}
  D-->>D: silent (no double payload)
```

## Failure mode: breaker trip

```mermaid
flowchart LR
  Fire["trigger fires"] --> Check{"breaker state?"}
  Check -- ok --> Count{"runaway? token cap?\nstate readable?"}
  Count -- healthy --> Inject["inject + journal"]
  Count -- violation --> Trip["trip (per-trigger or global)\nONE WARN: reason + re-enable paths\njournal: breaker-suppressed"]
  Check -- tripped --> Silent["silent for session\n(slash + channel 1 unaffected)"]
```

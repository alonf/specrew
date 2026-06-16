# Review Diagrams: Full Antigravity Refocus

## Runtime Flow

```text
agy PreInvocation
  |
  v
Antigravity adapter
  conversationId -> sanitized session id
  event          -> Specrew dispatcher event
  |
  v
SessionStateAccessor
  refocus-state-<session>.json
  |
  v
ClassificationEngine + B3 decision
  |
  +-- boundary crossed -> injectSteps once
  |
  +-- no boundary      -> no injection
```

## Stop Flow

```text
agy Stop
  |
  v
Specrew dispatcher
  |
  v
handover provider
  |
  v
.specrew/handover/session-handover.md
```

## Concurrency Marker Flow

```text
session-marker.json
  |
  v
ConcurrencyMarkerClassifier
  |
  +-- marker owned by current Antigravity conversation -> no advisory
  |
  +-- marker owned by another session                  -> advisory
  |
  +-- stale or malformed                               -> existing stale/fail-open path
```

## Documentation Status Flow

```text
docs depth parity
  |
  v
status label remains evidence-gated
  |
  +-- no full evidence -> pending validation / machine-local / beta candidate
  |
  +-- beta evidence    -> beta
  |
  +-- stable gate pass -> stable / verified
```

# Review Diagrams: Iteration 002 — Iteration 2a: Collision Detection & Feature Claims

**Schema**: v1
**Diagram Format**: mermaid

## Structure Diagram

```mermaid
flowchart LR
  Start[scripts/specrew-start.ps1] --> Sessions[scripts/internal/session-management.ps1]
  Start --> Claims[scripts/internal/feature-claims.ps1]
  Sync[scripts/internal/sync-boundary-state.ps1] --> Claims
  Sync --> Sessions
  Sessions --> ActiveSessions[.specrew/active-sessions.yml]
  Claims --> ActiveFeatures[.squad/active-features.yml]
  Sessions --> Atomic[scripts/internal/atomic-write.ps1]
  Claims --> Atomic
  Sessions --> Yaml[scripts/internal/yaml-list.ps1]
  Claims --> Yaml
```

## Flow Diagram

```mermaid
sequenceDiagram
  participant Dev as Developer
  participant Start as specrew start
  participant Sessions as session-management.ps1
  participant Claims as feature-claims.ps1
  participant Sync as sync-boundary-state.ps1

  Dev->>Start: start/resume feature
  Start->>Sessions: Clear-StaleSessionLocks
  Start->>Sessions: Test-SessionCollision
  Start->>Claims: Test-FeatureClaimConflict
  alt claim conflict declined
    Start-->>Dev: exit without recording session lock
  else no conflict or continue
    Start->>Sessions: Register-SessionLock
    Start-->>Dev: launch/resume handoff
  end
  Dev->>Sync: cross lifecycle boundary
  Sync->>Claims: Add or Update feature claim
  alt feature-closeout and merged to main
    Sync->>Claims: Remove-FeatureClaim
    Sync->>Sessions: Remove-SessionLock
  end
```

## Local View Hints

- [scripts/specrew-start.ps1](../../../scripts/specrew-start.ps1)
- [scripts/internal/sync-boundary-state.ps1](../../../scripts/internal/sync-boundary-state.ps1)
- [scripts/internal/session-management.ps1](../../../scripts/internal/session-management.ps1)
- [scripts/internal/feature-claims.ps1](../../../scripts/internal/feature-claims.ps1)

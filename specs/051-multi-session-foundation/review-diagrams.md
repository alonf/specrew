# Review Diagrams: Multi-Session Foundation

**Feature**: 051-multi-session-foundation
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram

```mermaid
flowchart TB
  CLI["specrew CLI<br/>(config / start / update / where)"]
  Config[".specrew/config.yml<br/>session_mode"]
  FileClass["file-classification.ps1<br/>(FR-004..006)"]
  Gitignore[".gitignore<br/>per-session patterns"]
  Sessions[".specrew/active-sessions.yml<br/>SessionLockEntry"]
  Claims[".squad/active-features.yml<br/>FeatureClaimEntry"]
  Signals["Get-MultiDevSignals<br/>(computed, not persisted)"]
  IdentityShared[".squad/identity/now.md<br/>(tracked: focus_area, body)"]
  IdentityState[".squad/identity/session-state.yml<br/>(gitignored: session_state_*)"]
  Log[".specrew/session-start.log<br/>(JSON Lines)"]

  CLI --> Config
  CLI --> FileClass
  FileClass --> Gitignore
  FileClass --> IdentityState
  CLI --> Sessions
  CLI --> Claims
  CLI --> Signals
  Signals -. recommend when single .-> CLI
  CLI --> IdentityShared
  CLI --> IdentityState
  CLI --> Log
  Config -. gates .-> Sessions
  Config -. gates .-> Claims
```

## Sequence: concurrent-session collision detection (US3 → FR-008/010/011)

```mermaid
sequenceDiagram
  participant DevB as Developer B
  participant Start as specrew start
  participant Locks as active-sessions.yml
  DevB->>Start: specrew start (feature 051)
  Start->>Locks: read entries (atomic)
  Start->>Start: Clear-StaleSessionLocks (>24h) [FR-011]
  Start->>Locks: Test-SessionCollision(051)
  alt active entry exists for 051
    Locks-->>Start: SessionLockEntry (user@machine, start_time)
    Start-->>DevB: ⚠ collision warning (<2s) [FR-010, SC-002]
  else no active entry
    Start->>Locks: Register-SessionLock(051) [FR-008]
    Start-->>DevB: session started
  end
```

## Sequence: feature claim warning (US4 → FR-013/014/015)

```mermaid
sequenceDiagram
  participant DevB as Developer B
  participant Start as specrew start
  participant Claims as active-features.yml
  DevB->>Start: cross specify boundary (051)
  Start->>Claims: read claims
  alt 051 already claimed by another
    Claims-->>Start: FeatureClaimEntry(claimed_by)
    Start-->>DevB: "Feature 051 claimed by ... Continue anyway?" [FR-015]
    DevB->>Start: y / n
    alt continue (y)
      Start->>Claims: Add-FeatureClaim (both recorded)
    else decline (n)
      Start-->>DevB: exit, no session created
    end
  else unclaimed
    Start->>Claims: Add-FeatureClaim(051) [FR-013]
  end
  Note over Start,Claims: each later boundary → Update-FeatureClaim last_refresh_time [FR-014, SC-008]
```

## Sequence: brand-new worktree detection (US9/US10 → FR-039/040/041)

```mermaid
sequenceDiagram
  participant Dev as Developer
  participant Start as specrew start
  participant State as session-state.yml (inherited)
  participant FS as worktree evidence
  Dev->>Start: specrew start --feature 051-new
  Start->>State: read inherited session_state_*
  Start->>FS: Test-BrandNewWorktree() [FR-039]
  Note right of FS: empty active-sessions.yml<br/>+ no boundary commits on branch<br/>+ no iteration dirs for inherited path
  alt brand-new (all signals true)
    Start->>Start: log decision [FR-042]
    Start-->>Dev: SKIP A/B/C → specify flow [FR-040]
  else genuine inconsistency
    Note right of FS: inherited feature_path ≠ branch<br/>AND iteration dirs exist
    Start->>Start: log decision [FR-042]
    Start-->>Dev: SHOW A/B/C recovery [FR-041]
  end
```

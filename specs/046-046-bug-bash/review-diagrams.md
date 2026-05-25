# Review Diagrams: F-046 Bug-Bash Bundle

**Feature**: `046-046-bug-bash`  
**Phase**: pre-implementation (planning artifact for reviewer)

## Component Diagram

```mermaid
flowchart TD
    SyncCmd[sync-boundary-state.ps1] -->|atomic sync| StartContext[start-context.json]
    SyncCmd -->|append verdict| VerdictHistory[(Verdict History)]
    Scaffolder[scaffold-reviewer-artifacts.ps1] -->|scaffold| targetFile[review.md]
    targetFile -->|checks verdict| ProtectionCheck{Test-SpecrewFileHasPopulatedVerdict}
    ProtectionCheck -->|if accepted| PendingFile[review.md.pending]
    ProtectionCheck -->|if empty/needs-rework| Overwrite[overwrite review.md]
```

## Sequence: Atomic Boundary Sync and Protected Scaffolding

```mermaid
sequenceDiagram
    participant User
    participant Wrapper as sync-boundary-state.ps1
    participant Helper as Invoke-SpecrewBoundaryStateSync
    participant Context as start-context.json

    User->>Wrapper: run with BoundaryType (e.g. implement)
    Wrapper->>Wrapper: translate implement -> review-signoff
    Wrapper->>Helper: Invoke-SpecrewBoundaryStateSync(review-signoff)
    Helper->>Helper: Add-SpecrewBoundaryAuthorization
    Helper->>Context: update last_authorized_boundary & verdict_history
    Helper->>Context: update session_state.boundary_type
    Helper-->>User: returns success
```

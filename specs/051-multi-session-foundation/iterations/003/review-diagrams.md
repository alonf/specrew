# Review Diagrams: Iteration 003 — Iteration 2b: Conflict Reduction & Multi-Developer Auto-Detection

**Schema**: v1
**Diagram Format**: mermaid

## Component Diagram

```mermaid
flowchart LR
  Legacy[".squad/decisions.md"] --> Split["scripts/decisions-split.ps1"]
  Split --> IterationLedger[".squad/decisions/iteration-NNN/decisions.md"]
  Sync["sync-boundary-state.ps1"] --> Jsonl[".squad/events/lifecycle-events.jsonl"]
  Sync --> Sorter["scripts/psd1-sort.ps1"]
  Sorter --> Manifest["Specrew.psd1 FileList"]
  Start["specrew-start.ps1"] --> Signals["scripts/auto-detection.ps1"]
  Where["specrew-where.ps1"] --> Dashboard["dashboard-renderer.ps1"]
  Dashboard --> Signals
  Sync --> Signals
  Signals --> Git["local git metadata"]
  Signals --> Sessions[".specrew/active-sessions.yml"]
  Signals --> StateFiles["local shared-state mtimes"]
```

## Sequence: Boundary Sync Conflict-Reduction Path

```mermaid
sequenceDiagram
  participant Crew as Lifecycle Sync
  participant Sync as sync-boundary-state.ps1
  participant Decisions as decisions-split.ps1
  participant Events as append-only-logs.ps1
  participant Manifest as psd1-sort.ps1
  participant Signals as auto-detection.ps1
  Crew->>Sync: sync boundary(feature, iteration, auth commit)
  Sync->>Events: Add-SpecrewLifecycleEvent(boundary-sync)
  Events-->>Sync: JSONL line appended
  Sync->>Decisions: Split when session_mode == multi
  Decisions-->>Sync: per-iteration ledgers refreshed
  Sync->>Manifest: Sort-SpecrewManifestFileList()
  Manifest-->>Sync: manifest converged
  Sync->>Signals: Get-SpecrewMultiDeveloperSignals()
  Signals-->>Crew: coarse activity note when signals exist
```

## Sequence: Welcome Recommendation

```mermaid
sequenceDiagram
  participant User
  participant Start as specrew-start.ps1
  participant Locks as session-management.ps1
  participant Signals as auto-detection.ps1
  User->>Start: specrew start
  Start->>Locks: register or refresh local session lock
  Start->>Signals: Get-SpecrewMultiDeveloperRecommendation()
  alt signals exist and session_mode is single
    Signals-->>Start: recommendation text with coarse counts
    Start-->>User: consider specrew config set session_mode multi
  else no signal or already multi
    Signals-->>Start: null
    Start-->>User: no redundant recommendation
  end
```

## Omissions

- True two-clone merge choreography is not diagrammed; the implemented control is deterministic file-surface reduction plus append-only event logging.

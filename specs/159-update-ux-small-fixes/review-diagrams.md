# Review Diagrams: Specrew Update Downgrade Guard and Compatibility Message Cleanup

**Feature**: 159-update-ux-small-fixes  
**Phase**: pre-implementation (planning artifact for reviewer)

## Component Diagram

```mermaid
flowchart LR
  CLI[specrew update CLI] --> Args[Argument Parser]
  Args --> Scope[Update Invocation]
  Scope --> Versions[Version Resolver]
  Versions --> Guard[Downgrade Guard]
  Guard -->|older running module| Refusal[Fail Closed Message]
  Guard -->|equal or newer| Existing[Existing Update Flow]
  Existing --> Deploy[Deploy Extension and Runtime Assets]
  Existing --> Config[Update Config]
  UX[Active Version/Governance UX] --> Cleanup[0.24.0 Active-Message Cleanup]
```

## Sequence: Stale Module Refusal

```mermaid
sequenceDiagram
  participant User
  participant CLI as specrew update
  participant Config as Project config
  participant Guard as Downgrade guard
  participant Assets as Protected assets

  User->>CLI: run mutating update
  CLI->>Config: read specrew_version
  CLI->>Guard: compare running version to project baseline
  Guard-->>CLI: running module is older
  CLI-->>User: non-zero refusal with remediation
  CLI-xAssets: no deployment, install, template refresh, or config write
```

## Sequence: Equal/Newer Pass-Through

```mermaid
sequenceDiagram
  participant User
  participant CLI as specrew update
  participant Guard as Downgrade guard
  participant Flow as Existing update flow
  participant Config as Project config

  User->>CLI: run mutating update
  CLI->>Guard: compare running version to project baseline
  Guard-->>CLI: equal or newer allowed
  CLI->>Flow: continue existing update behavior
  Flow->>Config: write refreshed versions after successful update
  CLI-->>User: existing update summary
```

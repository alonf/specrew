# Review Diagrams: Unix Resolver Sidecar Hardening Investigations

**Feature**: `160-unix-resolver-sidecar-hardening`
**Phase**: pre-implementation planning artifact for reviewer

## Component Diagram

```mermaid
flowchart LR
  Spec[Investigation Spec] --> Plan[Plan and Tasks]
  Plan --> ResolverProbe[Resolver Path Probe]
  Plan --> SidecarFixture[Managed Sidecar Fixture]
  ResolverProbe --> ResolverFinding[Resolver Finding]
  SidecarFixture --> SidecarFinding[Sidecar Finding]
  ResolverFinding --> ConditionalResolverFix[Conditional Resolver Fix]
  SidecarFinding --> ConditionalMarkerFix[Conditional Marker Fix]
  ConditionalResolverFix --> ReviewEvidence[Review Evidence]
  ConditionalMarkerFix --> ReviewEvidence
  ResolverFinding --> ReviewEvidence
  SidecarFinding --> ReviewEvidence
```

## Sequence: Resolver Path Investigation

```mermaid
sequenceDiagram
  participant Dev as Developer
  participant Test as Resolver path test
  participant Resolver as Specrew resolver code
  participant Evidence as Investigation evidence
  Dev->>Test: run path semantics fixture
  Test->>Resolver: exercise current path construction
  Resolver-->>Test: actual target or fallback behavior
  Test->>Evidence: record confirmed or not-confirmed disposition
  alt failure confirmed
    Test->>Resolver: apply separator-safe fix in implementation
    Test->>Evidence: record Windows and Unix regression pass
  else not confirmed
    Test->>Evidence: record no-fix disposition
  end
```

## Sequence: Managed Refresh Sidecar Investigation

```mermaid
sequenceDiagram
  participant Dev as Developer
  participant Fixture as Scratch deploy fixture
  participant Canonical as Canonical charters
  participant Runtime as Host or Squad deploy logic
  participant Evidence as Investigation evidence
  Dev->>Fixture: create scratch project
  Fixture->>Canonical: seed managed and user-edited cases
  Fixture->>Runtime: run direct deploy refresh
  Runtime-->>Fixture: actions and preserve notices
  Fixture->>Evidence: record marker creation and recognition result
  alt marker bug confirmed
    Fixture->>Runtime: verify focused marker fix
    Fixture->>Evidence: record managed refresh and unmanaged preserve pass
  else behavior correct
    Fixture->>Evidence: record not-confirmed no-fix disposition
  end
```

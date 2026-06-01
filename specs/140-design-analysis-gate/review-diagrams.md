# Review Diagrams: Minimal Design Alternatives / Architecture Intake Gate

**Feature**: 140-design-analysis-gate  
**Phase**: pre-implementation (planning artifact for reviewer)

## Component Diagram

```mermaid
flowchart LR
  Spec[spec.md Clarifications] --> Prompt[Lifecycle Guidance]
  Prompt --> Gate[Design Analysis Gate]
  Gate --> Artifact[iterations/001/design-analysis.md]
  Artifact --> Validator[Artifact Validation Helper]
  Validator --> Sync[Plan Boundary Sync]
  Sync --> Plan[plan.md]
  Artifact --> Plan
  Human[Human Verdict] --> Artifact
```

## Sequence: Active Substantive Feature

```mermaid
sequenceDiagram
  participant Human
  participant Coordinator
  participant Artifact as design-analysis.md
  participant Checker as DesignAnalysis Validator
  participant Sync as Boundary Sync
  participant Plan as plan.md

  Coordinator->>Artifact: create alternatives and recommendation
  Coordinator-->>Human: request approved for plan with Option X
  Human-->>Coordinator: approved for plan with Option B
  Coordinator->>Artifact: record chosen option, reason/modifications, commit hash
  Coordinator->>Sync: request plan boundary advance
  Sync->>Checker: validate artifact and decision
  Checker-->>Sync: valid
  Sync-->>Plan: allow planning to proceed
```

## Sequence: Missing Human Decision Blocks Plan

```mermaid
sequenceDiagram
  participant Coordinator
  participant Artifact as design-analysis.md
  participant Checker as DesignAnalysis Validator
  participant Sync as Boundary Sync

  Coordinator->>Artifact: writes alternatives and recommendation
  Coordinator->>Sync: request plan boundary advance
  Sync->>Checker: validate Human Decision
  Checker-->>Sync: missing chosen option or commit hash
  Sync-->>Coordinator: block with actionable message
```

## Sequence: Compatibility for Existing In-Flight Feature

```mermaid
sequenceDiagram
  participant Sync as Boundary Sync
  participant Context as Lifecycle Context
  participant Checker as Applicability Rule

  Sync->>Context: inspect feature and iteration state
  Context-->>Checker: existing or in-flight before feature rollout
  Checker-->>Sync: legacy-compatible, do not hard-fail solely for missing artifact
  Sync-->>Sync: continue existing compatibility path
```

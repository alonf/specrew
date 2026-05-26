# Review Diagrams: Iteration 001

**Schema**: v1
**Diagram Format**: mermaid
**Reviewed**: 2026-05-26

## Component Diagram

```mermaid
flowchart LR
  Session["Specrew session handoff state"] --> Validator["validate-governance.ps1"]
  Evidence[".specrew/handoff-evidence.json"] --> Validator
  Validator --> Warns["WARN-only trust-hardening findings"]
  Tasks["tasks.md checkboxes"] --> Progress["tasks-progress.yml"]
  Templates["Coordinator and reviewer templates"] --> Handoff["Public handoff prose"]
  Scaffolder["scaffold-reviewer-artifacts.ps1"] --> Diagrams["review-diagrams.md Mermaid output"]
  Extension["extensions/specrew-speckit/scripts"] <--> Mirror[".specify/extensions/specrew-speckit/scripts"]
```

## Sequence: Missing Handoff Detection

```mermaid
sequenceDiagram
  participant Host as Host session
  participant Evidence as Handoff evidence
  participant Validator as Governance validator
  participant Reviewer as Reviewer packet
  Host->>Evidence: records boundary/session metadata
  Validator->>Evidence: checks for required handoff block
  alt missing or dropped after compaction
    Validator-->>Reviewer: emits WARN trust-hardening finding
  else handoff present
    Validator-->>Reviewer: records no handoff gap
  end
```

## Sequence: Task Progress Regeneration

```mermaid
sequenceDiagram
  participant Start as specrew-start.ps1
  participant Tasks as tasks.md
  participant State as state.md
  participant Progress as tasks-progress.yml
  Start->>Tasks: read checkbox completion
  Start->>State: read last completed task
  Start->>Progress: write derived task status
  Progress-->>Start: preserve done status for completed tasks
```

# Review Diagrams: Boundary Authorization Prompt Truth + Human Re-entry Packet

**Feature**: 139-boundary-authorization-prompt-truth
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram

```mermaid
flowchart LR
  Config[.specrew/config.yml] --> Resolver[Boundary Policy Resolver]
  Resolver --> Context[start-context.json boundary_enforcement.policy_classes]
  Resolver --> Prompt[Generated last-start-prompt.md]
  Prompt --> Coordinator[Host Coordinator]
  Context --> Coordinator
  Coordinator --> Packet[Six-section Human Re-entry Packet]
  Packet --> Human[Human Verdict]
  Human --> Evidence[Verdict Evidence]
  Evidence --> Sync[Boundary Sync]
```

## Sequence: clarify-to-plan stop

```mermaid
sequenceDiagram
  participant Human
  participant Start as specrew start
  participant Config as .specrew/config.yml
  participant Context as start-context.json
  participant Prompt as last-start-prompt.md
  participant Agent as Coordinator Agent
  participant Spec as spec.md

  Human->>Start: requests feature
  Start->>Config: read boundary policy classes
  Config-->>Start: human-judgment-required boundaries
  Start->>Context: write boundary_enforcement.policy_classes
  Start->>Prompt: render policy-derived lifecycle guidance
  Agent->>Spec: specify and clarify
  Agent->>Agent: reaches clarify -> plan
  Agent-->>Human: emit six-section re-entry packet
  Human-->>Agent: approve, send back, or discuss
```

## Sequence: beta2-bad prompt regression

```mermaid
sequenceDiagram
  participant Test
  participant Fixture as Bad Prompt Fixture
  participant Checker as Prompt Regression Check

  Test->>Fixture: load prompt containing beta2-bad phrases
  Fixture-->>Checker: only gate that HARD-BLOCKS / continue automatically through plan/tasks
  Checker-->>Test: fail as non-compliant
```

## Sequence: status-approved contradiction check

```mermaid
sequenceDiagram
  participant Validator
  participant Spec as Feature Artifact
  participant Decisions as Verdict Evidence

  Validator->>Spec: read status
  Spec-->>Validator: Status: Approved
  Validator->>Decisions: search matching human verdict
  Decisions-->>Validator: no matching approval
  Validator-->>Validator: flag contradiction
```

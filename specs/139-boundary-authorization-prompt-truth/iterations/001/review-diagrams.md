# Review Diagrams: Iteration 001

**Schema**: v1
**Diagram Format**: mermaid
**Reviewed**: 2026-06-01

## Component Diagram

```mermaid
flowchart LR
  Config[".specrew/config.yml"] --> Start["scripts/specrew-start.ps1"]
  Shared["shared-governance.ps1"] --> Start
  Start --> Prompt["last-start-prompt.md"]
  Start --> Context["start-context.json with policy_classes"]
  Prompt --> HumanPacket["Six-section human re-entry packet"]
  Context --> Validator["validate-governance.ps1"]
  HandoffValidator["handoff-governance-validator.ps1"] --> Fixtures["negative handoff fixtures"]
  Tests["Feature 139 unit + integration tests"] --> Start
  Tests --> Shared
  Tests --> Validator
  Tests --> HandoffValidator
```

## Sequence: Fresh Start Stop Contract

```mermaid
sequenceDiagram
  participant Human
  participant Start as specrew start
  participant Config as .specrew/config.yml
  participant Prompt as Generated Prompt
  participant Context as start-context.json
  participant Agent as Coordinator

  Human->>Start: start feature request
  Start->>Config: resolve boundary policy classes
  Start->>Context: write boundary_enforcement.policy_classes
  Start->>Prompt: write policy-derived lifecycle instructions
  Agent->>Prompt: follow generated lifecycle contract
  Agent-->>Human: stop at clarify -> plan with six-section packet
  Human-->>Agent: approve as-is / approve with instructions / send back / discuss prompt #N
```

## Sequence: Status Approved Validator Check

```mermaid
sequenceDiagram
  participant Validator as validate-governance.ps1
  participant Spec as spec.md
  participant State as start-context.json
  participant Decisions as .squad/decisions.md

  Validator->>Spec: read active feature status
  alt Status is Approved
    Validator->>State: check verdict_history
    Validator->>Decisions: check human verdict evidence
    alt no matching evidence
      Validator-->>Validator: fail governance validation
    else matching evidence exists
      Validator-->>Validator: pass contradiction check
    end
  else status is not Approved
    Validator-->>Validator: skip narrow contradiction check
  end
```

## Local View Hints

- [review.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/iterations/001/review.md)
- [code-map.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/iterations/001/code-map.md)
- [coverage-evidence.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/iterations/001/coverage-evidence.md)

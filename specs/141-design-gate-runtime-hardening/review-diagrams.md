# Review Diagrams: Design Gate Runtime Hardening

**Feature**: 141-design-gate-runtime-hardening  
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram (Iteration 1 design-gate runtime path)

```mermaid
flowchart TB
  Tpl[design-analysis.template.md<br/>versioned template] --> Scaffold[scaffold path]
  Scaffold --> DA[iterations/NNN/design-analysis.md]
  subgraph Helper[design-analysis-gate.ps1 - extended from F140]
    Core[validation core - F140]
    PrePlan[pre-plan validator]
    Renderer[typed packet renderer]
    PacketVal[packet validator]
  end
  DA --> Core
  Core --> PrePlan
  Renderer --> PacketVal
  PacketVal --> Gates[(specs/feature/gates/<br/>durable 155-lite packet)]
  Lenses[(quality/lenses/*)] -.read-only.-> DA
  StartPrompt[specrew-start.ps1<br/>coordinator guidance] -->|enforce: no plan.md<br/>before valid| PrePlan
  PrePlan -->|valid?| Decision{artifact + human<br/>decision valid}
  Decision -->|no| Block[block plan.md authoring]
  Decision -->|yes| Plan[plan.md + selected option]
```

## Sequence: design-analysis gate before plan (canonical flow)

```mermaid
sequenceDiagram
  participant Human
  participant Coord as Coordinator
  participant Scaffold
  participant Validator as Pre-plan validator
  participant Packet as Packet renderer/validator
  Coord->>Scaffold: reach design-analysis stop
  Scaffold-->>Coord: design-analysis.md (from template)
  Coord->>Coord: author options + Crew recommendation
  Coord->>Validator: check before authoring plan.md
  Validator-->>Coord: invalid (no human decision) -> blocked
  Coord->>Packet: render typed gate packet
  Packet-->>Coord: rendered + validated packet (+ durable gates/ copy)
  Coord->>Human: present packet (approved for plan with Option X?)
  Human-->>Coord: approve Option X
  Coord->>Validator: re-check (artifact + decision valid)
  Validator-->>Coord: valid, selectedOption = Option X
  Coord->>Coord: author plan.md with selected option
```

## Sequence: smoke-bundle defects (later iterations)

```mermaid
sequenceDiagram
  participant Gen as start-prompt generator
  participant Pkt as start/handoff packet
  participant Proj as greenfield/downstream project
  Gen->>Pkt: render artifact paths
  Note over Pkt: iter 2 - every path has non-empty feature segment (no specs//)
  Gen->>Pkt: render host-conditional wording
  Note over Pkt: iter 2 - selected host only (no Copilot text on Claude)
  Proj->>Gen: run lifecycle command
  Note over Proj: iter 3 - only actionable warnings; baseline commit resolves to real hash
```

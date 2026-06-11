# Review Diagrams: Code & Implementation Lens

**Feature**: 177-software-development-rules-lens
**Phase**: pre-implementation (planning artifact for the reviewer)

## Component diagram

```mermaid
flowchart TB
  subgraph Catalog["Catalog (ships with Specrew, static)"]
    CR[code-rules.yml<br/>49 rules + per-stack, stable ids]
    LM[code-implementation.md lens md]
    SC[implementation-rules.schema.json]
    REG[index.yml / applicability-map.json / lensIds]
  end
  OV[code-rules.local.yml<br/>project overlay - guideline + custom]
  subgraph DesignTime
    WS[specrew-design-workshop<br/>code lens turn]
    MAN[implementation-rules.yml<br/>selections + decisions + dependency_policy]
    REC[workshop/code-implementation.md]
  end
  subgraph ImplementTime
    SK[specrew-code-rules skill<br/>static, multi-host reader]
    AG[coding agent]
  end
  PLAN[plan.md implement constraints]
  CR --> WS
  OV -. merge .-> WS
  LM --> WS
  WS --> MAN
  WS --> REC
  CR --> SK
  OV -. merge .-> SK
  MAN --> SK
  SK --> AG
  MAN --> PLAN
  MAN -. forward-compat .-> P156[(156 workshop-decisions.yml)]
```

## Sequence: design-time capture (guideline-first)

```mermaid
sequenceDiagram
  participant Human
  participant Workshop as specrew-design-workshop
  participant Catalog as code-rules.yml
  participant Manifest as implementation-rules.yml
  Workshop->>Human: source of code-rules truth? (guideline? paste/point/no)
  alt has guideline
    Human-->>Workshop: pasted guideline
    Workshop->>Catalog: map guideline -> rules (auto-check, flag conflicts)
    Workshop->>Human: confirm mapping + new custom items
  else none
    Human-->>Workshop: no
  end
  Workshop->>Human: resolve stack + grouped pre-checked checklist + decision-prompts + dependency selection
  Human-->>Workshop: set/unset + decisions + custom rules + dependency_policy
  Workshop->>Manifest: write reference-by-ID manifest (+ context_scope, dependency_policy)
  Workshop->>Human: lens recorded (lens-applicability.json)
```

## Sequence: implement-time guidance

```mermaid
sequenceDiagram
  participant Agent as coding agent
  participant Skill as specrew-code-rules
  participant Manifest as implementation-rules.yml
  participant Catalog as code-rules.yml
  Agent->>Skill: starting task (e.g., write a service)
  Skill->>Manifest: resolve active feature + read manifest
  alt manifest present
    Skill->>Catalog: resolve rule text by id (baseline + overlay)
    Skill-->>Agent: task-scoped rules + decisions + dependency stance
  else no manifest
    Skill->>Catalog: baseline-default rules only
    Skill-->>Agent: baseline guidance (baseline mode)
  end
  Agent->>Agent: write code honoring the surfaced rules
```

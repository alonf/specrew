# Review Diagrams: Beta3 Stabilization

**Feature**: 199-beta3-stabilization
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram

```mermaid
flowchart TB
  subgraph Navigators [Consumer rendering]
    NAV[co-review navigators\ndecision surface + stop blocks + gloss helper]
    BAN[bootstrap-provider + prompt-surgery\nfull prerelease version]
  end
  subgraph Orchestrators
    ORC[review-campaign-orchestrator\npause terminal + stop-here landing]
    INIT[specrew-init + plan materializer\nstarter verification plan]
  end
  subgraph Core [Authority core - pure decisions]
    CORE[review-authority-core\nper-campaign budget 4, invoked-only spend]
    CLS[signoff-evidence-gate classifier\nconsult -> suppress -> records-only -> quiet]
  end
  subgraph Store [Immutable facts]
    STORE[review-authority-store\nreparse tags + pending-pause fact]
    GATE[(signoff-gate latest.json\nunchanged writer)]
  end
  NAV --> ORC --> CORE --> STORE
  CLS --> GATE
  CLS --> STORE
  CAP[ConversationCaptureAccessor + hooks deploy\nphrase-first capture, wiring reconcile] -.side rail.-> NAV
  CAT[reviewer-host-catalog codex 900s\n+ verdict-goal reviewer prompt] -.side rail.-> ORC
```

## Sequence: the pause (every round)

```mermaid
sequenceDiagram
  participant H as Human
  participant O as Orchestrator
  participant C as Core
  participant S as Store
  participant N as Navigator
  participant G as Stop governor
  O->>C: round ingested; compute pause verdict
  C-->>O: verdict (findings, cost, budget, recommendation)
  O->>S: write PendingPauseFact (atomic)
  O->>N: render decision surface
  N-->>H: findings + cost + 3 numbered options
  Note over O: engine exits - nothing spends
  G->>S: read pending pause
  S-->>G: present -> QUIET (no block)
  H->>S: numbered reply -> PauseDecisionFact
```

## Sequence: stop-here landing (the wedge killer)

```mermaid
sequenceDiagram
  participant H as Human
  participant O as Orchestrator
  participant V as Frozen-tree verification
  participant C as Core
  participant S as Store
  participant CL as Classifier
  participant N as Navigator
  H->>O: choice 2 (stop here)
  O->>V: run bounded verification on the frozen tree
  V-->>O: pass
  O->>C: validate identity-bound residual acceptance
  C->>S: write acceptance facts
  O->>CL: gate sync
  CL->>S: consult signoff-gate decision
  S-->>CL: allow
  N-->>H: "review signed off; N minor findings saved as follow-ups"
```

## Iteration 002: the crossing family

```mermaid
flowchart TB
  subgraph Capture [Capture and mint]
    CAP[verdict capture
marker identity verified]
    GATE{mint gate
from-stage artifacts on disk?}
    WR[Add-SpecrewBoundaryAuthorization]
  end
  subgraph Mirrors [Mirrors of last_authorized_boundary]
    M1[state.md Current Phase]
    M2[state.md Iteration Status]
    M3[plan.md Status]
  end
  subgraph Sync [Boundary sync]
    RM[re-mirror from store]
    TG{truth gate
every mirror == store?}
    PF[gate-preflight
pushed-head at closeouts
verdict-commit-durable everywhere]
    SEAL[seal LAST at closeout]
  end
  subgraph Stop [Stop hook]
    OWN{owner == this session?}
    PKT[packet with options + marker@identity]
    INFO[one informational line]
    UNK[owner unknown: demand + named gap]
  end
  CAP --> GATE
  GATE -- absent --> WH[withhold: name what is owed]
  GATE -- present --> WR --> M1 & M2 & M3
  WR --> STORE[(authority store
pending_crossing.owner, .marker)]
  RM --> TG -- agrees --> PF --> SEAL
  TG -- ahead --> REF[refusal names the mirror]
  STORE --> OWN
  OWN -- yes --> PKT
  OWN -- no --> INFO
  OWN -- unknown --> UNK
```

## Sequence: a lens close (FR-027, FR-028)

```mermaid
sequenceDiagram
  participant H as human
  participant A as agent
  participant R as receipt minter (prompt-submit)
  participant W as confirm-workshop-lens
  participant V as lens validator
  participant L as lens-applicability.json
  H->>A: "yes" (lens still open)
  A-->>H: Recorded: "yes". This lens stays open until you type "move on" (or "skip")
  H->>R: move on
  R->>R: mint phase-lens receipt
  A->>W: confirm-workshop-lens -Lens <lens>
  W->>V: validate the lens record (where a validator exists)
  V-->>W: errors / none
  W-->>A: refusal keeps the lens open, names the record's own lines
  W->>L: moved_on=true, confirmation fields
  W->>A: handover refreshed; next lens
```

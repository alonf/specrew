# Review Diagrams: 0.40.0-beta2 Hardening Bundle

**Feature**: 198-beta2-hardening
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram (feature-wide, per the agreed map)

```mermaid
flowchart TB
  subgraph Lanes[CI lanes and templates]
    SLL[SelfLeakLintLane]
    PFT[PromptFixtureTest]
    MGT[MethodologyGateTemplate]
    WKT[WorkKindTemplate]
  end
  subgraph Deploy[Deploy and heal surface]
    TSI[TemplateSurfaceInstaller]
    IB[InitBootstrap]
    UH[UpdateHealer]
  end
  subgraph Runtime[Reviewer runtime]
    WM[WorktreeMaterializer]
    RBB[ReviewerBundleBuilder]
    SPB[SlimPromptBuilder]
    CD[ContainmentDetector]
    RTR[RecordedTestRunner]
    CN[CheckpointNavigator]
    RCG[RoundCeilingGovernor]
    BR[BudgetResolver]
    LDI[LiveDoorIdentity]
  end
  subgraph Core[Governance core]
    BSR[BoundarySyncRatchet] --> BAC[BoundaryAuthorizationCheck]
    GV[GovernanceValidator] --> BAC
    DI[DigestIdentity] --> THC[TrackerHonestyCheck]
    RMR[ReleaseModelResolver]
  end
  subgraph Data[Data seams]
    DL[SelfLeakDenyList]
    MPL[MachineryPathList]
    RHC[ReviewerHostCatalog]
    RG[RepositoryGovernance]
    TP[ToolchainPins]
  end
  Lanes --> Core
  Deploy --> Core
  Runtime --> Core
  Core --> Data
  SLL --> DL
  WM --> MPL
  DI --> MPL
  BR --> RHC
  RMR --> RG
  IB --> TP
```

## Sequence: the deny-list single-truth loop (iteration 001 canonical flow)

```mermaid
sequenceDiagram
  participant Author
  participant CI as SelfLeakLintLane (repo CI)
  participant List as SelfLeakDenyList (shipped JSON)
  participant Consumer as Consumer (update heal + gateway advisory, iter 004)
  Author->>CI: push template edit
  CI->>List: load entries (schema_version checked)
  CI->>CI: derive scan surface FROM deploy manifest source
  alt unannotated self-fact
    CI-->>Author: RED - file, term, class, escape syntax, rule doc
    Author->>Author: fix or annotate specrew-self-ok: reason
  else clean or annotated
    CI-->>Author: green (annotated hits listed with reasons)
  end
  Author->>Consumer: release ships the SAME list
  Consumer->>List: advisory scan + heal read identical entries
```

## Sequence: boundary ratchet on a non-stopping host (iteration 002 canonical flow)

```mermaid
sequenceDiagram
  participant Agent as Agent (no Stop hook)
  participant Sync as sync-boundary-state
  participant Auth as Test-SpecrewBoundaryAuthorization
  participant Human
  Agent->>Sync: cross boundary N (mechanical record, F-174)
  Sync->>Auth: delta(position, last_authorized)
  Auth-->>Sync: delta = 1 (pending verdict)
  Agent->>Sync: attempt boundary N+1 without approval
  Sync->>Auth: delta(position, last_authorized)
  Auth-->>Sync: delta > 1 (unreconciled skip)
  Sync-->>Agent: REFUSE - names skipped boundary + both doors
  Human->>Sync: retro-approve OR decline
  alt retro-approved
    Sync->>Sync: cursor advances (recorded as retroactive)
  else declined
    Human->>Sync: explicit confirm
    Sync->>Sync: revert to recorded AuthCommitHash
  end
```

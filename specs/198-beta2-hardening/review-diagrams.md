# Review Diagrams: 0.40.0-beta2 Hardening Bundle

**Feature**: 198-beta2-hardening
**Phase**: Iteration 008 planning (Beta2 finish line)

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

## Component: controlled external review replacement (iterations 006/007)

```mermaid
flowchart LR
  Human[Human allowance] --> CLI[specrew review]
  CLI --> Cutover[Authority mode: legacy / disabled / campaign]
  Cutover --> Campaign[ReviewCampaignCoordinator]
  Campaign --> Repos[Immutable campaign/run/claim repositories]
  Campaign --> Target[External Git ReviewTargetPort]
  Campaign --> Harness[HarnessPort]
  Campaign --> Runtime[RuntimePort]
  Harness --> Claude[Claude]
  Harness --> Codex[Codex]
  Harness --> Copilot[Copilot]
  Harness --> Cursor[Cursor]
  Harness --> Antigravity[Antigravity]
  Runtime --> Job[Windows Job Object]
  Runtime --> Cgroup[Linux cgroup]
  Runtime --> PGroup[macOS process group]
  Harness --> Candidate[Run-owned candidate.json]
  Candidate --> Ingress[Strict ResultIngestor]
  Runtime --> Ingress
  Target --> Ingress
  Ingress --> Result[Immutable controller result.json + report.md]
  Result --> Signoff[Exact-digest signoff gate]
  Result --> Retro[Retro evidence projection]
```

The reviewer never writes the origin repository or terminal authority. The repository is the sole code-mutation
authority; campaign repositories are the sole review-state mutation authority.

## Sequence: one paid run, timeout, and visible rerun

```mermaid
sequenceDiagram
  participant Human
  participant CLI as Campaign CLI
  participant Store as Immutable Store
  participant Target as Git Target
  participant Harness
  participant Runtime as OS Runtime
  participant Ingress
  Human->>CLI: authorize exactly one slot
  CLI->>Store: reserve run ID / claim generation
  CLI->>Target: freeze external target + exact digest
  CLI->>Harness: no-spend preflight
  CLI->>Runtime: launch one invocation
  CLI->>Store: spend slot at invocation start
  Runtime->>Harness: supervise descendant tree
  alt completes
    Harness->>Ingress: raw candidate JSON file
    Runtime->>Ingress: completed + death/streams verified
  else timeout
    Runtime->>Runtime: kill descendants and close streams
    Runtime->>Ingress: timed-out + termination verified
    Harness->>Ingress: optional valid partial candidate
  end
  Ingress->>Store: publish one terminal result
  Store-->>Human: result, digest/currentness, findings, timing
  opt human authorizes rerun
    Human->>CLI: new slot + new run ID
  end
```

## Sequence: workshop intermediate Stop

```mermaid
sequenceDiagram
  participant Workshop
  participant State as Durable workshop state
  participant Stop as Stop provider
  participant Human
  Workshop->>State: record active feature/iteration/lens + pending question
  Workshop-->>Human: render lens content and explicit question
  Stop->>State: verify exact active scope and pending question
  alt lifecycle boundary pending
    Stop-->>Human: full boundary packet
  else valid workshop intermediate
    Stop-->>Human: no duplicate generic five-section packet
  else fabricated/abandoned/interrupted state
    Stop-->>Human: ordinary non-boundary context packet
  end
```

## Component: verification-plan supplier and production injection (iteration 008)

```mermaid
flowchart LR
  Explicit[Explicit project config] --> Selector[Ordered Plan Supplier]
  Metadata[Named project-owned metadata detector] --> Selector
  Profile[Explicit quality profile] --> Selector
  Provider[Active provider-gated catalog row] --> Selector
  Catalog[Small versioned selection catalog] --> Selector
  Selector -->|selected| Plan[.specrew/verification-plan.json]
  Selector -->|no trusted source| NotConfigured[verification-not-configured]
  Plan --> Validator[Existing FR-048 validator]
  Validator --> Runner[Existing T018 ordered runner]
  Target[Frozen external Git target + digest] --> Runner
  Runner --> Evidence[Per-command recorded evidence]
  Evidence --> Join[Exact digest + command_id join]
  Plan --> Join
  Join --> Campaign[Review campaign evidence injection]
  Campaign --> Reviewer[Authorized reviewer invocation]
  NotConfigured --> Setup[Actionable setup instruction; zero provider spend]
```

The selector supplies commands but never executes them. The existing FR-048/T018 path owns validation,
execution, and evidence. Review reads the frozen target, does not mutate the origin, and refuses provider spend
when selection is absent or invalid.

## Sequence: finish-line release and published-beta proof

```mermaid
sequenceDiagram
  participant Project as Downstream fixture
  participant Supplier
  participant Runner as T018 Runner
  participant Campaign
  participant CI as Three-OS CI
  participant Human
  participant Release as Tag workflow
  participant Consumer as Fresh consumer
  Project->>Supplier: explicit config / named metadata / profile / provider
  Supplier->>Runner: canonical selected plan
  Runner->>Runner: execute in order; record every attempt
  Runner->>Campaign: exact-digest + command-id evidence
  Campaign->>Campaign: inject matching bounded evidence
  Campaign->>CI: deterministic suite and governance proof
  CI-->>Human: pre-release gates and independent review result
  Human->>Release: separately authorize v0.40.0-beta2
  Release-->>Consumer: published beta bits
  Consumer-->>Human: SC-014 friction-class PASS/FAIL evidence
  Note over Human,Consumer: Stable promotion remains separate
```

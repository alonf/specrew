# Review Diagrams: Iteration 007

**Schema**: v1
**Diagram Format**: mermaid

## Production Review Authority

```mermaid
graph TD
  Human[Human slot grant] --> Campaign[ReviewCampaign]
  Campaign --> Facts[Immutable grant reservation spend run facts]
  Campaign --> Target[External exact Git target]
  Campaign --> Harness[One of five file-primary harnesses]
  Campaign --> Runtime[Job Object cgroup or process group]
  Harness --> Candidate[Run-owned raw JSON candidate]
  Runtime --> Controller[Controller waits for verified termination]
  Target --> Controller
  Candidate --> Ingress[Strict identity and schema ingress]
  Controller --> Ingress
  Ingress --> Result[Immutable result.json]
  Result --> Report[Derived report.md]
```

## T061 Correction and Signoff Sequence

```mermaid
sequenceDiagram
  participant H as Human
  participant C as Controller
  participant A as Claude
  participant R as Repository
  loop Attempts 1 through 12
    H->>C: Fresh authorization reference
    C->>C: Deterministic and no-spend preflight
    alt Pre-provider failure
      C-->>H: Preserve failure with zero spend
    else Provider invoked
      C->>A: Exactly one contained invocation
      A-->>C: Raw candidate JSON
      C-->>H: Publish result and stop on findings
      H->>R: Authorize bounded correction
      R->>R: Test commit CI exact preflight
    end
  end
  H->>C: Standing progress grant for attempt 13
  C->>A: Exactly one contained invocation
  A-->>C: Complete zero-finding pass at 58869dfe
  C-->>R: Allow one six-file evidence finalization child
  R-->>C: Finalization commit F
  C->>C: CreateNew binding fact run + digest + F
  C-->>H: Reviewed at 58869dfe finalized as F
```

## Bounded Finalization Envelope

```mermaid
graph LR
  X[Reviewed commit X] --> F[Direct child F]
  F --> Allow[Only six review evidence files]
  F --> Deny[Scripts tests specs contracts denied]
  Clean[Clean run bound to digest of X] --> Fact[CreateNew authority fact]
  X --> Fact
  F --> Fact
  Fact --> Gate[Boundary-finalized signoff packet]
```

## Support and Deferral Boundary

```mermaid
graph LR
  Beta2[Beta2 Iteration 007] --> CodeReview[Code-review campaign]
  CodeReview --> Five[Five real harnesses]
  CodeReview --> Three[Three production OS runtimes]
  CodeReview --> Truth[Digest-scoped support truth]
  Beta3[Beta3] --> Generic[Generic gate and artifact target adapters]
  Open[Open Beta2 slice] --> Supplier[FR-048 FR-049 SC-015 command-plan supplier]
  Supplier --> Block[Blocks feature closeout]
```

The diagrams intentionally separate reviewer execution from code mutation: only the repository may mutate product code, only the campaign controller may publish review authority, and the finalization child cannot carry implementation changes.

# Review Diagrams: Iteration 008

**Schema**: v1
**Diagram Format**: mermaid

## Verification and Review Authority

```mermaid
graph TD
  Human[Human one-slot grant] --> Campaign[Review campaign controller]
  Campaign --> Plan[Governed verification plan]
  Plan --> Copy[Disposable exact-digest verification copy]
  Copy --> Evidence[External controller evidence]
  Evidence --> Protect[OS-protect untouched reviewer target]
  Protect --> Harness[Claude file-primary harness]
  Campaign --> Runtime[Windows Job Object]
  Harness --> Candidate[External raw JSON candidate]
  Runtime --> Controller[Verify termination and target identity]
  Candidate --> Ingress[Strict schema and identity ingress]
  Controller --> Ingress
  Ingress --> Result[Immutable result.json]
  Result --> Report[Derived report.md]
```

## T066 Correction Sequence

```mermaid
sequenceDiagram
  participant H as Human
  participant C as Controller
  participant R as Repository
  participant A as Claude
  loop Attempts 01 through 09
    H->>C: Fresh authorization
    alt Pre-provider failure
      C-->>H: Zero-spend result
    else Provider invoked
      C->>A: Exactly one invocation
      C-->>H: Findings or containment failure
      H->>R: Bounded correction
    end
  end
  C-->>H: Third integrity recurrence; non-convergence stop
  H->>R: T071 diagnostic and containment replan
  H->>C: Attempt 10 grant
  C->>A: One invocation at 659bec28
  A-->>C: Clean pass
  C-->>R: Provider-free finalization probe refuses classifier mismatch
  R->>R: Add precise local-settings classifier and paired tests
  H->>C: Attempt 11 grant
  C->>A: One invocation at 9a6b8854
  A-->>C: Complete zero-finding pass
  C-->>H: Prepare review-signoff boundary
```

## Bounded Finalization Envelope

```mermaid
graph LR
  X[Reviewed commit 9a6b8854] --> F[Single direct-child finalization F]
  F --> Allow[Exactly six evidence files]
  F --> Deny[Every other path denied]
  Clean[Clean run 11 at digest eb9643d5] --> Fact[CreateNew authority fact]
  X --> Fact
  F --> Fact
  Fact --> Gate[Reviewed at X finalized as F]
```

## Release Boundary

```mermaid
graph LR
  Signoff[T066 clean review-signoff] --> ReleaseGate[T029 separate release authority]
  ReleaseGate --> Beta[Publish v0.40.0-beta2]
  Beta --> Dogfood[T067 fresh-consumer validate-not-promote]
  Dogfood --> Closeout[Beta2 closeout decision]
  Proposal[Proposal 209] --> Separate[Separately scheduled slice]
```

The diagrams separate repository mutation, controller evidence publication, paid reviewer execution, and release authority. Clean review cannot publish the beta; publication cannot imply stable promotion.

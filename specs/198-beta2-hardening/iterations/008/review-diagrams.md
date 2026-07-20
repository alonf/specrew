# Review Diagrams: Iteration 008

**Schema**: v1
**Diagram Format**: mermaid

## Verification and Review Authority

```mermaid
graph TD
  Human[Human one-slot grant] --> Campaign[Review campaign controller]
  Campaign --> Plan[Resolved governed verification plan]
  Plan --> Copy[Disposable exact-digest verification copy]
  Copy --> Evidence[External controller-owned evidence]
  Evidence --> Protect[OS-protect untouched reviewer target]
  Protect --> Harness[Claude file-primary harness]
  Campaign --> Runtime[Windows Job Object]
  Harness --> Candidate[External run-owned raw JSON candidate]
  Runtime --> Controller[Controller verifies termination and target identity]
  Candidate --> Ingress[Strict schema and identity ingress]
  Controller --> Ingress
  Ingress --> Result[Immutable result.json]
  Result --> Report[Derived report.md]
```

## T066 Attempt and Correction Sequence

```mermaid
sequenceDiagram
  participant H as Human
  participant C as Controller
  participant R as Repository
  participant A as Claude
  H->>C: Attempts 01 and 02 grants
  C->>A: One invocation each
  A-->>C: Findings plus red verification evidence
  C-->>H: Stop; no hidden retry
  H->>R: Authorize corrections
  H->>C: Attempts 03 and 04 grants
  C-->>H: Preflight failure; zero provider spend
  loop Attempts 05 through 09
    H->>C: Fresh progress grant
    C->>A: Exactly one invocation
    C-->>H: Publish findings or containment failure
    H->>R: Authorize bounded correction
  end
  C-->>H: Third integrity recurrence; non-convergence stop
  H->>R: Authorize T071 diagnostic and containment replan
  R->>R: Disposable verification plus external evidence plus read-only target
  R->>R: 73-suite registry and three-OS CI pass
  H->>C: Exact attempt 10 grant
  C->>A: One contained invocation at 659bec28
  A-->>C: Complete zero-finding pass
  C-->>H: Prepare review-signoff boundary
```

## Bounded Finalization Envelope

```mermaid
graph LR
  X[Reviewed commit 659bec28] --> F[Single direct-child finalization commit F]
  F --> Allow[Exactly six review-evidence files]
  F --> Deny[All other paths denied]
  Clean[Clean run 10 bound to digest 45255b42] --> Fact[CreateNew authority fact]
  X --> Fact
  F --> Fact
  Fact --> Gate[Reviewed at X finalized as F]
```

## Release Boundary

```mermaid
graph LR
  Signoff[T066 clean review-signoff] --> ReleaseGate[T029 separate human release authority]
  ReleaseGate --> Beta[Publish v0.40.0-beta2]
  Beta --> Dogfood[T067 fresh-consumer validate-not-promote]
  Dogfood --> Closeout[Beta2 closeout decision]
  Proposal[Proposal 209] --> Separate[Separately scheduled slice]
```

The diagrams separate repository mutation, controller evidence publication, paid reviewer execution, and release authority. Clean review cannot publish the beta; publication cannot imply stable promotion.

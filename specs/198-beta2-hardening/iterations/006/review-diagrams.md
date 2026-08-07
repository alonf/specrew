# Review Diagrams: Iteration 006

**Schema**: v1
**Diagram Format**: mermaid

## Authority Structure

```mermaid
graph TD
  Human[Human grant] --> Campaign[ReviewCampaign policy]
  Campaign --> Store[Immutable JSON facts]
  Campaign --> Target[External Git target port]
  Campaign --> Harness[Claude file-primary harness]
  Campaign --> Runtime[OS containment runtime]
  Harness --> Candidate[Run-owned candidate JSON]
  Candidate --> Ingress[Strict result ingress]
  Target --> Ingress
  Runtime --> Ingress
  Ingress --> Result[Immutable controller result.json]
  Result --> Report[Derived report.md]
```

## One-Invocation Review Flow

```mermaid
sequenceDiagram
  participant H as Human
  participant C as Controller
  participant T as Git target
  participant R as Job Object runtime
  participant A as Claude
  participant I as Strict ingress
  H->>C: Add one immutable grant
  C->>T: Freeze exact external snapshot + digest
  C->>C: Preflight contract/store/harness/runtime
  C->>C: Reserve, claim, then record spend
  C->>R: Start one contained invocation
  R->>A: Prompt with exact candidate path
  A->>I: Write raw JSON directly to candidate file
  R-->>C: Exit, containment, termination evidence
  T-->>C: Origin integrity + currentness
  C->>I: Validate identity, schema, applicability
  I-->>C: Publish one immutable terminal result
```

## Trust and Deferral Boundary

- The repository remains the sole code-mutation authority; the reviewer sees a disposable copy.
- Campaign/run repositories are the sole review-state mutation authority.
- Iteration 006 proves the shared foundation and one Claude file-primary slice only.
- The other harness adapters, production Linux/macOS/Windows runtime matrix, live smokes, and progress-to-retro projection remain Iteration 007.

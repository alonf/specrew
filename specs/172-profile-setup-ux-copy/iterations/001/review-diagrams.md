# Review Diagrams: Iteration 001

**Schema**: v1
**Diagram Format**: mermaid

## Structure Diagram

```mermaid
flowchart TD
  A[Proposal 170] --> B[Profile setup metadata]
  B --> C[user-profile.ps1 first-run prompt]
  B --> D[Normalize setup input]
  C --> E[User profile dials]
  D --> E
  F[Integration tests] --> B
  F --> D
```

## Flow Diagram

```mermaid
sequenceDiagram
  participant User
  participant Prompt as First-run setup
  participant Parser as Normalize-CrewInteractionProfileSetupInput
  participant Profile as profile dials
  User->>Prompt: Press Enter or choose 1-10/auto
  Prompt->>Parser: Raw input
  Parser-->>Prompt: auto or canonical number
  Prompt->>Profile: Store by stable persona ID
```

## Omissions

- Deployment diagram omitted: no deployment, host binding, or package surface
  changed.
- Data migration diagram omitted: persisted profile schema was preserved.

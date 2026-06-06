# Review Diagrams: Iteration 001

**Schema**: v1
**Diagram Format**: mermaid

## Structure Diagram

```mermaid
flowchart LR
  Proposal167[Proposal 167] --> Spec168[Feature 168 Spec]
  Spec168 --> Docs[Proposal Discipline Docs]
  Spec168 --> Validator[Governance Validator]
  Spec168 --> ReviewGuidance[Review Instructions]
  Spec168 --> Index[Proposals Index]
  Fixtures[Synthetic Fixtures] --> Tests[Focused Replay Tests]
  Validator --> Tests
  Docs --> Tests
  ReviewGuidance --> Tests
  Index --> Tests
  Tests --> Evidence[Review Evidence]
  Evidence --> HumanReview[Review Signoff]
```

## Flow Diagram

```mermaid
sequenceDiagram
  participant Maintainer
  participant Proposal as Shipped Proposal
  participant Validator
  participant Reviewer
  Maintainer->>Proposal: add post-ship amendment or allowed correction
  Validator->>Proposal: inspect changed proposal sections
  Validator-->>Maintainer: soft warning for unsafe body edit or malformed amendment
  Reviewer->>Proposal: verify amendment id, delta, preserve list, tests required
  Reviewer-->>Maintainer: accept only delta-based implementation evidence
```

## Review Notes

- Diagrams show the Feature 168 governance flow only.
- Runtime product behavior is not part of this slice.

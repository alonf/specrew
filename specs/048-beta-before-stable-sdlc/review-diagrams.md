# Review Diagrams: Beta-Before-Stable SDLC Discipline

**Feature**: `048-beta-before-stable-sdlc`  
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram

```mermaid
flowchart LR
  Closeout[Feature Closeout] --> Handoff[Coordinator Handoff Template]
  Handoff --> Agent[Agent SDLC Actions]
  Handoff --> Human[Human Approval and PASS/FAIL]
  Agent --> BetaTag[Beta Tag and Publish Verify]
  Human --> Verdict{PASS?}
  Verdict -- FAIL --> FixLoop[Fix and Next Beta]
  FixLoop --> BetaTag
  Verdict -- PASS --> Stable[Stable Tag and Publish Verify]
  Stable --> Audit[Release Audit Capture]
  Audit --> File[docs/releases/<feature-ref>.md]
```

## Sequence: PASS promotion flow

```mermaid
sequenceDiagram
  participant Agent
  participant GitHub
  participant PSGallery
  participant Human
  participant Audit
  Agent->>GitHub: push branch and open PR
  Agent->>GitHub: self-review, monitor automated review, merge
  Agent->>GitHub: tag vX.Y.Z-beta.1
  GitHub->>PSGallery: publish prerelease
  Agent->>PSGallery: verify prerelease package
  Agent->>Human: pause for clean-shell PASS/FAIL verdict
  Human-->>Agent: PASS with evidence
  Agent->>GitHub: tag vX.Y.Z stable
  GitHub->>PSGallery: publish stable
  Agent->>PSGallery: verify stable package
  Agent->>Audit: capture release audit record
  Audit-->>GitHub: commit direct-main or trailing one-file PR
```

## Sequence: FAIL beta loop

```mermaid
sequenceDiagram
  participant Agent
  participant PSGallery
  participant Human
  Agent->>PSGallery: verify vX.Y.Z-beta.1 publication
  Agent->>Human: request prerelease validation verdict
  Human-->>Agent: FAIL with evidence
  Agent->>Agent: fix on main after approval
  Agent->>PSGallery: publish and verify vX.Y.Z-beta.2
  Agent->>Human: request PASS/FAIL again
  Human-->>Agent: PASS with evidence
  Agent->>PSGallery: publish and verify stable
```

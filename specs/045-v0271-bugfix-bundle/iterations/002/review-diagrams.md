# Review Diagrams: Iteration 002

**Schema**: v1
**Reviewed**: 2026-05-25
**Diagram Format**: mermaid
**Overall Verdict**: accepted

## Structure Diagram

```mermaid
flowchart LR
  Tests[Brownfield regression tests] --> Primary[extensions brownfield-merge.ps1]
  Tests --> Mirror[.specify brownfield-merge.ps1]
  Primary --> Report[Merge Report]
  Mirror --> Report
  Report --> Init[specrew init]
  Docs[Operator docs] --> Maintainer[Maintainer]
  Quickstart[Feature quickstart] --> Reviewer[Reviewer]
  Evidence[Quality evidence] --> Reviewer
```

## Flow Diagram

```mermaid
sequenceDiagram
  participant Test as Regression Test
  participant Merge as brownfield-merge.ps1
  participant Project as Fixture Project
  participant Reviewer
  Test->>Project: create self-hosting fixture
  Test->>Merge: request PassThru report
  Merge->>Project: inspect extensions/specrew-speckit and .squad/agents
  Merge-->>Test: no role conflicts, canonical roles preserved
  Test->>Project: create non-self-hosting fixture
  Test->>Merge: request PassThru report
  Merge-->>Test: baseline role conflicts reported
  Reviewer->>Test: replay suite during review
  Test-->>Reviewer: pass, exit code 0
```

## Omissions

- No dependency graph is shown because no package dependencies changed.
- No browser or service topology is shown because this patch changes CLI/governance behavior and documentation only.

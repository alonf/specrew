# Review Diagrams: F-047 Trust-Hardening Bug-Bash Bundle

**Feature**: `047-bug-bash-trust-hardening`
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram

```mermaid
flowchart TD
  subgraph Validator[validate-governance.ps1]
    HB[handoff-block check]
    DD[dashboard-missing diagnosis]
    WL[wrong-location check]
    MM[mermaid-absence check]
    IR[internal-reference regex]
  end
  Shared[shared-governance.ps1\nTest-SpecrewHandoffBlockPresent] --> HB
  Shared --> DD
  Scaffold[scaffold-reviewer-artifacts.ps1\nMermaid skeleton] --> MM
  Audit[installed-instructions/ audit] --> IR
  Start[specrew-start.ps1] --> Catalog[Get-SpecrewSkillCatalogState\ncontent-based]
  Start --> Progress[tasks-progress.yml\nreconcile from tasks.md]
  Templates[per-host coordinator templates\nclose-out SDLC handoff]
  Validator -->|WARN findings| Report[governance report]
```

## Sequence: handoff-block detection at a boundary commit (Item 1 + Item 2)

```mermaid
sequenceDiagram
  participant Op as Operator/Agent
  participant V as validate-governance.ps1
  participant H as Test-SpecrewHandoffBlockPresent
  participant R as Governance report
  Op->>V: validate iteration (boundary commit)
  V->>H: handoff block present? (commit window + session metadata)
  H-->>V: false (no block; compaction_marker=true)
  V->>R: emit WARN (post-compaction handoff-drop, sub-trigger 3c)
  R-->>Op: WARN finding (not FAIL)
```

## Sequence: resume reconciliation (Item 7)

```mermaid
sequenceDiagram
  participant Op as Operator
  participant S as specrew-start.ps1
  participant T as tasks.md ([x])
  participant St as state.md
  participant P as tasks-progress.yml
  Op->>S: specrew start (resume complete feature)
  S->>T: read [x] checkboxes (authoritative)
  S->>St: read Last Completed Task
  S->>P: write derived per-task status (done)
  S-->>Op: welcome-back snapshot reflects truth (no "Start T001")
```

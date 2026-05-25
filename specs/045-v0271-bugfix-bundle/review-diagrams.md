# Review Diagrams: Specrew v0.27.1 Bug-Fix Bundle

**Feature**: `045-v0271-bugfix-bundle`
**Phase**: pre-implementation planning artifact, repaired during iteration 002 review

## Component Diagram

```mermaid
flowchart LR
  Maintainer[Maintainer CLI] --> Router[scripts/specrew.ps1]
  Router --> Version[scripts/specrew-version.ps1]
  Router --> Start[scripts/specrew-start.ps1]
  Router --> Init[scripts/specrew-init.ps1]
  Init --> Brownfield[extensions/specrew-speckit/scripts/brownfield-merge.ps1]
  Brownfield --> Mirror[.specify/extensions/specrew-speckit/scripts/brownfield-merge.ps1]
  Init --> SkillCatalog[skill-catalog state helpers]
  Start --> SkillCatalog
  Docs[docs/getting-started.md and docs/user-guide.md] --> Maintainer
  Tests[tests/integration regression suites] --> Router
  Tests --> Brownfield
```

## Sequence: Self-Hosting Brownfield Classification

```mermaid
sequenceDiagram
  participant Maintainer
  participant Init as specrew init
  participant Merge as brownfield-merge.ps1
  participant Repo as Project Files
  Maintainer->>Init: run init in existing project
  Init->>Merge: request brownfield report
  Merge->>Repo: inspect extensions/specrew-speckit/
  Merge->>Repo: inspect .squad/agents/
  alt self-hosting signal present
    Merge-->>Init: canonical baseline roles, no role conflict
    Init-->>Maintainer: continue with preserved project source
  else no self-hosting signal
    Merge-->>Init: baseline role conflicts
    Init-->>Maintainer: block until conflicts are resolved
  end
```

## Sequence: Operator Update Decision

```mermaid
sequenceDiagram
  participant Maintainer
  participant Guide as Operator Docs
  participant Module as PowerShell Module
  participant Project as Specrew Project
  Maintainer->>Guide: check update path
  Guide-->>Maintainer: use Update-Module first
  Maintainer->>Module: update and verify specrew --version
  Maintainer->>Guide: check redeploy trigger
  alt release/runtime gap requires redeploy
    Maintainer->>Project: run specrew init
  else no redeploy trigger
    Maintainer-->>Project: continue normal specrew start flow
  end
```

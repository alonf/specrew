# Review Diagrams: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram

```mermaid
flowchart TB
  subgraph Data["Catalog & Contracts (data)"]
    Catalog[WorkKindCatalog\nwork-kinds.yml]
    Schema[CatalogSchema]
    Decl[WorkKindDeclaration\n.specrew/work-kind.yml]
    Gov[RepositoryGovernance\n.specrew/repository-governance.yml]
  end
  subgraph Surfaces["Methodology Surfaces"]
    Lens[DevOpsLensContent]
    Docs[DocsOnlyLifecycle]
    DevOps[DevOpsLifecycle]
    Inv[CloseoutVsReleaseInvariant]
  end
  subgraph Validators["Validators (forge-neutral)"]
    V[WorkKindValidator]
    CFC[ChangedFileClassifier]
    CEC[CloseoutEvidenceChecker]
  end
  subgraph Seam["Provider Seam"]
    Contract[ProviderAdapterContract]
    GH[GitHubAdapter]
    Gen[GenericFallbackAdapter]
    Cap[CapabilityDetector]
    Syn[AdapterSynthesisConduct]
  end
  CI[CIWorkflowTemplate] --> V
  V --> CFC
  V --> CEC
  V --> Catalog
  CFC --> Catalog
  V -.uses, with git-diff fallback.-> Contract
  Contract --> GH
  Contract --> Gen
  Cap --> Contract
  Lens --> Gov
  Lens --> Cap
  Lens --> Syn
  Surfaces --> Catalog
  Cap --> Gov
```

## Sequence: declare → validate (the canonical PR flow)

```mermaid
sequenceDiagram
  participant Dev as Developer
  participant CI as CIWorkflowTemplate
  participant V as WorkKindValidator
  participant A as ProviderAdapter (or git-diff fallback)
  participant Cat as WorkKindCatalog
  Dev->>Dev: write .specrew/work-kind.yml (work_kind)
  Dev->>CI: open PR
  CI->>V: run(ProjectPath, BaseRef)
  V->>A: read_pr_context()  (changed files, target branch)
  A-->>V: changed_files / fallback: git diff base..head
  V->>Cat: load kind → allowed_scope + required_evidence
  V->>V: one kind? scope match? closeout evidence? open boundary?
  V-->>CI: advisory|blocking verdict naming the exact gap
  CI-->>Dev: render result (advisory by default)
```

## Sequence: detect → report (honest capability)

```mermaid
sequenceDiagram
  participant Lens as DevOpsLensContent
  participant Cap as CapabilityDetector
  participant A as ProviderAdapter
  Lens->>Cap: detect(ProjectPath)
  Cap->>A: detect_capability(ctx)
  alt GitHub adapter present
    A-->>Cap: { mechanism: branch-protection|rulesets, constraints }
  else no/unknown adapter
    A-->>Cap: { mechanism: ci-only|manual }
  end
  Cap-->>Lens: honest mechanism + constraints (never over-promise)
  Lens->>Lens: describe-only by default; apply_protection needs human approval
```

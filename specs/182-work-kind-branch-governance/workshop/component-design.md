# Component-Design Workshop Record: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Depth**: medium
**Confirmation**: human-confirmed (lens-question)

## Component map (approved)

```text
                    ┌─────────────────────────── WIRING ───────────────────────────┐
                    │ CIWorkflowTemplate (GH Actions v1)   ForgeNeutralizationMigration (Iter 3) │
                    └───────────────┬───────────────────────────────┬───────────────┘
                                    │ invokes                       │ decouples
             ┌──────────────────────▼──────────┐          ┌─────────▼────────────────────────┐
             │      VALIDATORS (forge-neutral)  │          │     METHODOLOGY SURFACES          │
             │ WorkKindValidator                │          │ DevOpsLensContent                 │
             │  ├ ChangedFileClassifier         │          │ DocsOnlyLifecycle                 │
             │  └ CloseoutEvidenceChecker       │          │ DevOpsLifecycle                   │
             └───────┬──────────────┬───────────┘          │ CloseoutVsReleaseInvariant        │
                     │ reads        │ uses (with fallback) │ WorkKindTaxonomyDoc               │
                     │              ▼                       └────────┬──────────────────────────┘
                     │     ┌─────────────────────────┐               │ describe/synthesize
                     │     │     PROVIDER SEAM        │◀──────────────┘
                     │     │ ProviderAdapterContract  │
                     │     │  ├ GitHubAdapter         │
                     │     │  ├ GenericFallbackAdapter │
                     │     │  ├ CapabilityDetector     │
                     │     │  └ AdapterSynthesisConduct│
                     │     └───────────┬──────────────┘
                     ▼                 ▼
             ┌───────────────────────────────────────────────────┐
             │            CATALOG & CONTRACTS (data)              │ ◀── everything depends inward
             │ WorkKindCatalog · CatalogSchema ·                  │
             │ WorkKindDeclaration · RepositoryGovernance         │
             └───────────────────────────────────────────────────┘
```

## Components (named, with responsibility + tentative iteration)

**Catalog & Contracts (data)** — Iter 1:

- `WorkKindCatalog` (`work-kinds.yml`) — 4 kinds × lifecycle weight + required-evidence + allowed changed-file scope.
- `CatalogSchema` (`work-kinds.schema.json`) — validates the catalog and the declaration.
- `WorkKindDeclaration` (`.specrew/work-kind.yml` template) — per-work-item declared kind + metadata.
- `RepositoryGovernance` (`.specrew/repository-governance.yml` template) — `branch_model` + `review_gate` + `multi_repo`.

**Methodology Surfaces** — Iter 1:

- `DevOpsLensContent` — governance questions + `branch_model` + `review_gate` + adapter-synthesis conduct.
- `DocsOnlyLifecycle` — lightweight docs-only lifecycle surface/template.
- `DevOpsLifecycle` — devops work-kind surface/template (risk/rollback + dry-run/CI evidence).
- `CloseoutVsReleaseInvariant` — invariant doc + `release-validation-record` template.
- `WorkKindTaxonomyDoc` — human-readable companion to the catalog.

**Validators (forge-neutral runtime)** — Iter 2:

- `WorkKindValidator` — orchestrates PR checks; advisory/blocking verdict naming the exact gap (SC-005).
- `ChangedFileClassifier` — maps changed files to a kind's allowed scope (allow-list for global/generated).
- `CloseoutEvidenceChecker` — verifies the kind's required closeout evidence / no open boundary.

**Provider Seam** — contract+reference+fallback Iter 1; detection Iter 2:

- `ProviderAdapterContract` — the interface (Iter 1).
- `GitHubAdapter` — v1 reference adapter, `gh`/API (Iter 1 stub → Iter 2 detection).
- `GenericFallbackAdapter` — always-present; `ci-only`/`manual` + git-diff `read_pr_context` (Iter 1).
- `CapabilityDetector` — honest mechanism report (Iter 2).
- `AdapterSynthesisConduct` — documented on-the-fly synthesis, read-only by default (Iter 1 doc; exercised Iter 2).

**Wiring**:

- `CIWorkflowTemplate` — GitHub Actions workflow invoking the validator (Iter 2).
- `ForgeNeutralizationMigration` — cross-cutting decouple of downstream-governing surfaces (Iter 3).

## Key flows

- **declare → validate**: developer writes `.specrew/work-kind.yml` → `CIWorkflowTemplate`
  runs `WorkKindValidator` → `ChangedFileClassifier` + `CloseoutEvidenceChecker` read
  `WorkKindCatalog` + (`read_pr_context` | git-diff) → advisory/blocking verdict naming the gap.
- **detect → report**: `CapabilityDetector` → `ProviderAdapter.detect_capability` (GitHub |
  generic) → honest mechanism → `DevOpsLensContent` surfaces it.

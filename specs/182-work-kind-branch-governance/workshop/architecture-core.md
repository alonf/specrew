# Architecture-Core Workshop Record: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Depth**: full
**Confirmation**: human-confirmed (lens-question)

## Macro architecture (design-time → declaration → enforcement)

```text
          DESIGN-TIME (per feature/project)        DECLARATION (per work item)        ENFORCEMENT (per PR / on main)
       ┌──────────────────────────────────┐    ┌───────────────────────────┐    ┌─────────────────────────────────┐
       │  DevOps & Operations lens         │    │  .specrew/work-kind.yml   │    │  Branch protection (REAL push-   │
       │   → repository_governance capture │    │   work_kind: <one of 4>   │    │   block layer; forge-enforced)   │
       │   → multi_repo capture            │───▶│   + optional metadata     │───▶│  ───────────────────────────────│
       └──────────────────────────────────┘    └───────────────────────────┘    │  CI work-kind validator (semantic│
                          │                                  ▲                   │   layer): declaration present? 1  │
                          │ reads                            │ classified by     │   kind? changed-files match kind? │
                          ▼                                  │                   │   required closeout evidence?     │
       ┌──────────────────────────────────┐                 │                   │   → advisory (warn) | blocking    │
       │  WORK-KIND CATALOG (data)         │─────────────────┘                   └─────────────────────────────────┘
       │  work-kinds.yml:                  │  4 kinds → lifecycle weight                      │ uses
       │   software-feature | bug-bash |   │  + required-evidence set                         ▼
       │   docs-only | devops             │  + allowed changed-file scope     ┌─────────────────────────────────┐
       └──────────────────────────────────┘                                  │  ProviderAdapter (thin seam)     │
                          │ referenced by                                    │   github (v1 reference)          │
                          ▼                                                   │   generic/unknown (v1 fallback   │
       ┌──────────────────────────────────┐                                  │     → ci-only | manual, honest)  │
       │  LIFECYCLE SURFACES (methodology) │                                  │   <forge> (synthesized on the fly│
       │   docs-only lifecycle template    │                                  │     when downstream dev names it;│
       │   devops lifecycle template       │                                  │     read-only by default)        │
       │   closeout-vs-release-validation  │                                  └─────────────────────────────────┘
       │   invariant doc                   │
       └──────────────────────────────────┘     LIFECYCLE TRUTH (the invariant):
                                                  feature-closeout  ──(pre-merge, in feature PR)
                                                  release-validation-record ──(post-merge, on main, SEPARATE)
                                                  post-merge finding ──▶ NEW docs-only/devops/bug-bash work item (never reopen)
```

## Decisions

- **DP-A1 — Decomposition**: data-driven **catalog** (`work-kinds.yml`) + **thin
  validators** (PowerShell) + **methodology surfaces** (lens md + lifecycle templates);
  layered/modular. Reuses the producer→declaration→enforcement spine proven in Feature
  177 (catalog→manifest→consumer).
- **DP-A2 — Taxonomy as data, not prose**: the 4 kinds + lifecycle weight +
  required-evidence + allowed changed-file scope live in the catalog, referenced by the
  lens, the templates, and the validator so docs and enforcement cannot drift.
- **DP-A3 — Closeout vs release-validation**: `feature-closeout` is the last in-feature
  boundary (pre-merge); a **separate `release-validation-record`** captures post-merge
  beta/CI/docs learning on main; a post-merge finding **routes to a new work item**,
  never reopens the merged feature, and merged closeout artifacts are not retroactively
  rewritten.
- **DP-A4 — Provider-neutral core + pluggable `ProviderAdapter`** (refined with the
  maintainer): the methodology, the `.specrew/work-kind.yml` declaration, and the CORE
  validator never import a forge assumption. v1 ships a **GitHub reference adapter** + a
  **generic/unknown fallback** (`ci-only`/`manual`). Other forges (GitLab, Azure DevOps,
  Bitbucket, Gitea) are **synthesized on the fly** from the adapter contract + the GitHub
  reference when a downstream developer states their forge, captured at the downstream
  project (e.g. `.specrew/providers/<forge>.ps1`) with provenance — no GitLab/Azure code
  ships in Specrew. **Safety guardrails**: (1) synthesized/unverified adapters are
  **read-only by default** — `detect_capability` + `describe_protection` only;
  `apply_protection` (mutates repo security) stays **human-approved**; (2) a **bounded
  audit** decouples existing downstream-facing branch/PR/release-governance GitHub
  references (the closeout `gh pr create`/merge-commit steps + PR-review-integration)
  behind the seam, while Specrew's OWN dev infra stays GitHub (Specrew is a GitHub
  project). Out-of-surface coupling is recorded as a tight follow-up, not silently
  dropped.
- **DP-A5 — Phased enforcement is architectural**: the validator runs **advisory (warn)
  OR blocking**, config-controlled, **defaulting to advisory** — honesty baked into
  structure, not only docs (no over-claim).
- **DP-A6 — Hardest-to-reverse**: the **declaration contract** (`.specrew/work-kind.yml`
  shape) + the **catalog schema** are isolated as versioned data + a documented contract;
  templates/messages/detector stay cheap to change.

## Out of scope (this feature / iteration)

- Full ruleset-enforcement automation (phased/deferred where partial).
- Non-GitHub adapters shipped in Specrew (synthesized on the fly instead).
- Proposals 174 / 178.

## Agreed flow

`developer declares work_kind in .specrew/work-kind.yml` → `CI validator reads catalog +
changed files + closeout evidence` → `advisory/blocking verdict` ‖ `branch protection
blocks direct pushes` → `feature-closeout before merge; post-merge finding opens a NEW
work item + a release-validation-record`.

# Design Analysis — Iteration 001: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Date**: 2026-06-11
**Status**: awaiting Human Decision (`approved for plan with Option <X>`)

## Problem framing

Specrew treats feature delivery, release validation, docs changes, and DevOps changes as
one lifecycle shape, so post-merge findings reopen merged features (unsafe on a protected
release branch) and trivial changes carry full-feature ceremony. Feature 182 introduces
first-class **work kinds**, a **DevOps-lens branch-governance** decision area, the
**feature-closeout-vs-release-validation** invariant, and — per the design workshop — a
**provider-neutral core + pluggable `ProviderAdapter`**, a configurable **`branch_model`**,
a **`review_gate`**, and a **forge-neutralization** of all downstream-governing surfaces.

The design workshop (product-domain + 7 technical lenses + code-implementation, recorded
under `workshop/` and `lens-applicability.json`) already co-designed the architecture,
component map, and flows. This analysis compares **implementation-strategy** alternatives
and carries the workshop's co-design forward for the Human Decision.

## Decision points (resolved in the workshop; see lens records)

- **Decomposition** → data-driven catalog + thin validators + methodology surfaces
  (architecture-core DP-A1/A2).
- **Forge coupling** → provider-neutral core + pluggable `ProviderAdapter`; GitHub reference
  + generic fallback + on-the-fly read-only synthesis (DP-A4, integration-api DP-I1/I2).
- **Lifecycle truth** → feature-closeout pre-merge; separate release-validation-record;
  post-merge finding → new work item (DP-A3).
- **Enforcement posture** → advisory by default, phased to blocking; honest capability
  reporting (DP-A5, requirements-nfr).
- **Branch model / review gate** → user-configurable `branch_model` + `review_gate`
  (devops-operations).

## Alternatives

### Option A — Simplest (methodology-only first)

Ship the work-kind taxonomy + lifecycle surfaces + DevOps-lens governance + the
`ProviderAdapter` *contract* only — all advisory/documentation. Defer the CI validator,
capability detection, synthesis, and the forge-neutralization migration to follow-up
features.

- **Design principle**: minimize blast radius; ship + prove the methodology before any
  runtime.
- **Pros**: fastest, lowest-risk, immediately usable; nothing to over-claim.
- **Cons**: no automated enforcement yet; does **not** deliver the full proposal the
  maintainer approved; the runtime value (US4/US5) slips entirely.

### Option B — Reasonable *(Crew recommendation)*

The 3-iteration plan as co-designed:

- **Iter 1** — methodology + adapter contract/fallback + audit/inventory + brownfield content.
- **Iter 2** — runtime validator + capability detection + on-the-fly synthesis + dogfood.
- **Iter 3** — forge-neutralization decouple migration.

- **Design principle**: defense-in-depth delivered incrementally; each iteration ships a
  coherent, independently-testable layer; honest phased enforcement (advisory → blocking as
  proven).
- **Pros**: delivers the full approved scope; each iteration is independently valuable;
  matches the workshop decomposition exactly; honors every maintainer decision (synthesize-
  not-pre-build, advisory-default, no change to Specrew's own GitHub usage).
- **Cons**: the largest commitment (~16–24 SP, 3 iterations); the Iter-3 migration carries
  the most uncertainty (mitigated by the Iter-1 inventory + the escape hatch to split).

### Option C — By-the-book (maximal upfront)

Everything in Option B **plus**: ship a second forge adapter (e.g. GitLab) in v1 instead of
relying on synthesis; make the CI validator **blocking** on Specrew's own repo from the
start; build full ruleset-enforcement automation.

- **Design principle**: maximal upfront completeness + enforcement.
- **Pros**: strongest enforcement; two proven adapters.
- **Cons**: **contradicts confirmed maintainer decisions** (no pre-built adapters —
  synthesize on the fly; advisory-default honesty; phased enforcement); largest/slowest/
  highest-risk; over-built relative to the validated need.

## Crew recommendation

**Option B.** It delivers exactly the approved scope, honors every decision locked in the
workshop (provider-neutral, synthesize-don't-pre-build, advisory-default honesty, no change
to Specrew's own GitHub usage), and reuses the co-designed decomposition. Option A
under-delivers the approved proposal; Option C contradicts confirmed decisions and
over-builds. The Iter-3 risk is bounded by making the precise coupling inventory an Iter-1
deliverable and keeping the split-to-sibling escape hatch.

## Co-Design Record

*(Component-to-responsibility map + agreed flows + agreed UI layout, co-designed and
human-confirmed in the design workshop — component-design lens "Approve the map" and ui-ux
lens "Confirm". Reaffirmed at this design-analysis stop.)*

**Decomposition method**: data-driven catalog + thin validators + methodology surfaces
(layered/modular).

**Component-to-responsibility map** (grouped by layer; every component named):

```text
                    ┌─────────────────────────── WIRING ───────────────────────────┐
                    │ CIWorkflowTemplate (GH Actions v1)   ForgeNeutralizationMigration (Iter 3) │
                    └───────────────┬───────────────────────────────┬───────────────┘
             ┌──────────────────────▼──────────┐          ┌─────────▼────────────────────────┐
             │      VALIDATORS (forge-neutral)  │          │     METHODOLOGY SURFACES          │
             │ WorkKindValidator                │          │ DevOpsLensContent                 │
             │  ├ ChangedFileClassifier         │          │ DocsOnlyLifecycle                 │
             │  └ CloseoutEvidenceChecker       │          │ DevOpsLifecycle                   │
             └───────┬──────────────┬───────────┘          │ CloseoutVsReleaseInvariant        │
                     │ reads        │ uses (with fallback) │ WorkKindTaxonomyDoc               │
                     │     ┌─────────▼───────────────┐      └────────┬──────────────────────────┘
                     │     │     PROVIDER SEAM        │◀─────────────┘ describe/synthesize
                     │     │ ProviderAdapterContract  │
                     │     │  ├ GitHubAdapter         │
                     │     │  ├ GenericFallbackAdapter │
                     │     │  ├ CapabilityDetector     │
                     │     │  └ AdapterSynthesisConduct│
                     ▼     └───────────┬──────────────┘
             ┌───────────────────────────────────────────────────┐
             │            CATALOG & CONTRACTS (data)              │ ◀── everything depends inward
             │ WorkKindCatalog · CatalogSchema ·                  │
             │ WorkKindDeclaration · RepositoryGovernance         │
             └───────────────────────────────────────────────────┘
```

Responsibilities (one line each):
- **WorkKindCatalog** — 4 kinds × lifecycle weight + required-evidence + allowed scope.
- **CatalogSchema** — validates catalog + declaration. **WorkKindDeclaration** — declared kind + metadata. **RepositoryGovernance** — `branch_model` + `review_gate` + `multi_repo` capture.
- **DevOpsLensContent** — governance questions + branch_model + review_gate + synthesis conduct. **DocsOnlyLifecycle** / **DevOpsLifecycle** — lightweight lifecycle surfaces. **CloseoutVsReleaseInvariant** — the invariant doc + release-validation-record template. **WorkKindTaxonomyDoc** — human-readable catalog companion.
- **WorkKindValidator** — orchestrates PR checks → advisory/blocking verdict naming the gap. **ChangedFileClassifier** — changed files → allowed scope (allow-list for global/generated). **CloseoutEvidenceChecker** — required closeout evidence / no open boundary.
- **ProviderAdapterContract** — the forge seam. **GitHubAdapter** — reference. **GenericFallbackAdapter** — ci-only/manual + git-diff. **CapabilityDetector** — honest mechanism. **AdapterSynthesisConduct** — on-the-fly, read-only by default.
- **CIWorkflowTemplate** — GH Actions wrapper invoking the validator. **ForgeNeutralizationMigration** — Iter-3 decouple.

**Agreed flow 1 — declare → validate**: `developer writes .specrew/work-kind.yml` →
`CIWorkflowTemplate runs WorkKindValidator` → `ChangedFileClassifier + CloseoutEvidenceChecker
read WorkKindCatalog + (read_pr_context | git-diff)` → `advisory/blocking verdict naming the gap`.

**Agreed flow 2 — detect → report**: `CapabilityDetector → ProviderAdapter.detect_capability
(GitHub | generic) → honest mechanism → DevOpsLensContent surfaces it`.

**Agreed UI layout (ui-ux)** — the text/CLI surface the human approved: validator output
names the exact gap + allowed scope + fix and carries the advisory/blocking label; the
capability report is honest + describe-only by default; the brownfield prompt offers
adapt-or-change. (Full render in `workshop/ui-ux.md`.)

**Human-agreed marker**: the component map + responsibilities + both flows + the UI layout
were rendered in-band and **confirmed by the maintainer** during the design workshop
(component-design "Approve the map"; ui-ux "Confirm"). Reaffirmation is part of the
`approved for plan with Option <X>` verdict at this stop.

## Human Decision

- **Chosen option**: **Option B — Reasonable** (the co-designed 3-iteration plan).
- **Reason / modifications**: Accepted the Crew recommendation as-is; no modifications. Delivers
  the full approved scope, honors every workshop decision (provider-neutral, synthesize-don't-
  pre-build, advisory-default honesty, no change to Specrew's own GitHub usage), with the
  Iter-3 decouple bounded by the Iter-1 inventory + the split-to-sibling escape hatch.
- **Verdict**: `approved for plan with Option B`
- **Authorizing human**: Alon Fliess
- **Date**: 2026-06-11
- **Commit (containing this decision)**: this commit (the design-analysis Human Decision commit).

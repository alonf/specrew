# Quickstart: Product & Problem Domain Lens

**Feature**: 176-product-domain-lens
**Last verified**: 2026-06-09 (planning artifact — describes how the built feature is exercised)

## Run it

Once implemented, the lens runs automatically as the first workshop phase at feature intake. To
exercise it directly:

```pwsh
# Unit + integration tests are standalone PowerShell scripts (see tests/README.md), run directly:
pwsh -NoProfile -File tests/unit/product-domain-lens.tests.ps1
pwsh -NoProfile -File tests/integration/product-domain-multihost.tests.ps1

# Build + persist + validate a record by hand
. ./scripts/internal/product-domain-lens.ps1
$record = [ordered]@{
  schema_version = '1.0'; depth = 'light'; depth_reason = 'tiny utility'; context_scope = 'feature_standalone'
  areas = [ordered]@{ users_stakeholders = '...'; pain_job = '...'; mvp = '...'; out_of_scope = '...'; constraints = '...' }
  statements = @(); skipped = @(); follow_up_research = @()
  confirmation = 'human-confirmed'; confirmation_scope = 'lens-question'
}
New-SpecrewProductDomainRecord -FeatureDir specs/999-demo -Record $record
Test-SpecrewProductDomainRecord -Path specs/999-demo/workshop/product-domain.yml
```

## Try the canonical scenario

1. Start a feature intake (`specrew start` / the workshop). **Expected**: the product-domain phase
   runs FIRST, before any technical-lens applicability question.
2. The Crew selects a depth (Light/Standard/Deep) by risk and novelty and states why. **Expected**:
   for a small internal tool it picks Light and records the reason.
3. The Crew reframes a solution-first request ("build X") into the problem and asks the product
   questions. **Expected**: users/stakeholders, pain/job, MVP, out-of-scope, and constraints are
   captured, each material statement evidence-tagged.
4. The records are written. **Expected**: both `specs/<feature>/workshop/product-domain.yml` and
   `product-domain.md` exist; `spec.md` carries a product-domain summary.
5. The specify boundary syncs. **Expected**: the gate passes only with a genuine
   `confirmation: human-confirmed` / `lens-question` record.

## Verify the edge cases

- **Batch approval is rejected (FR-009/SC-005)**: a record whose `confirmation_scope` is a
  batch/agenda approval fails the specify gate.
- **Conditional research-needed block (FR-011/SC-006)**: a `research-needed` statement marked
  `load_bearing: true` blocks the plan boundary; a non-load-bearing one advances with the gap
  recorded.
- **Graceful degradation**: with the lens catalog or a skill copy absent, the phase surfaces a WARN
  and never silently skips the grounding.
- **Schema forward-compat (SC-008)**: `product-domain.yml` validates against
  `contracts/product-domain.schema.json`, including the optional `product_id` / `product_context_ref`
  and `context_scope` hooks (so Proposal 156/162 wiring connects later).

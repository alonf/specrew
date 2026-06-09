# Workshop diagram: component-design (build decomposition)

**Feature**: 176-product-domain-lens
**Lens**: component-design (+ devops-operations deploy topology folded in)
**Captured**: 2026-06-09 (intake workshop, human-confirmed)

This is the keeper diagram rendered in-band during the intake workshop and approved
by the maintainer as the spec's build decomposition.

## Component map

```text
  [product-domain.md]  <- the lens knowledge (shared catalog)
        | read by
        v
  [specrew-design-workshop skill]  <- runs product-domain FIRST, adaptive depth, no-batch-confirm
        | writes
        v
  workshop/product-domain.{yml, md}  <- per-feature records (structured + human-readable)
        | validated by
        v
  [specify-gate floor]  <- requires record + SC-026 provenance; rejects batch approval (FR-009)
        | covered by
        v
  [tests]  <- depth / dual-artifact / evidence-tags / FR-009 / gate / host-parity
```

## Named components (grouped by build area)

Catalog knowledge:

- `product-domain.md` — new lens file (8 decision areas, Light/Standard/Deep depth model,
  evidence-tag vocabulary, no-batch-confirmation conduct, solution-first → problem reframing).
- Catalog registration — `index.yml` entry + a `diagram-vocabulary.json` entry (context
  diagram), marked as the always-applicable first-stage lens, distinct from the
  question-gated `applicability-map.json`.

Per-feature artifacts:

- `product-domain.yml` — structured record (depth, per-area answers, assumptions, evidence
  tags, skipped areas, follow-up research), forward-compatible with Proposal 156's
  consumer shape.
- `product-domain.md` — human-readable feature record, under `specs/<feature>/workshop/`.
- Record writer/validator functions (PowerShell) — scaffold the record, format the readable
  doc, validate required fields + evidence tags + confirmation provenance.

Workshop conduct:

- `specrew-design-workshop` skill updated to run `product-domain` first and enforce
  no-batch-confirmation, re-deployed to the 4 host copies through the managed-skill deploy
  path.

Enforcement:

- Specify-gate floor — extends the existing specify-boundary gate to require the
  product-domain record with SC-026 `confirmation` / `confirmation_scope` provenance and
  reject batch approval (FR-009); conditional `research-needed` → plan block (FR-011).

Tests:

- depth selection (light/standard/deep), dual-artifact persistence, evidence-tagging,
  FR-009 agenda-approval non-equivalence, the gate floor, and multi-host skill parity.

## Deploy topology (devops-operations)

```text
  one shared catalog file        four managed host skill copies
  -----------------------        ------------------------------------
  design-lenses/product-domain.md   .claude/skills/specrew-design-workshop/
            |                        .cursor/rules/specrew-design-workshop/
            | conduct change         .github/skills/specrew-design-workshop/
            | propagates via         .agents/skills/specrew-design-workshop/
            v  managed-skill deploy      (each carries a .specrew-managed marker)
       [host-parity test]  <- fails on drift between the copies
```

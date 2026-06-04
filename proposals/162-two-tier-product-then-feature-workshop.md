---
proposal: 162
title: Two-Tier Design Workshop — Product/App-Level Once, Then Short Per-Feature
status: candidate
phase: phase-2
estimated-sp: 15-25
discussion: surfaced 2026-06-05 during the Feature 141 iteration-8 visual dogfood (testLenses4, a document-translation SaaS). The maintainer observed that every feature re-runs the full multi-lens design workshop from scratch, with no memory of the product's macro architecture, design method, or service landscape — so the architecture conversation restarts each feature and the cross-feature structure is never established once. Maintainer: "Maybe at the beginning we need to do the workshop for the entire app, then for each spec (feature) we need to conduct a short one." Genuinely new STRUCTURE, explicitly NOT folded into Feature 141 Amendment A6 (which makes a single feature's design-analysis collaborative). A6 is the per-feature depth; 162 is the cross-feature spine that per-feature sessions inherit.
---

# Two-Tier Design Workshop — Product/App-Level Once, Then Short Per-Feature

## Why

Specrew's design-lens workshop (Feature 141, Amendment A4) and the collaborative design-analysis
(Amendment A6) operate PER FEATURE. Each feature independently infers applicable lenses, discusses
architecture, co-decides a design method, and names services. For the FIRST feature of a product that
is right. For the SECOND and later features it is both wasteful and incoherent: the product already HAS
a macro architecture, a chosen design method (e.g. IDesign microservices on Azure), a service landscape,
and cross-cutting decisions (identity, telemetry, data lifecycle, hosting, residency). Re-deriving those
per feature either repeats the same long conversation, or silently drifts — feature 2 quietly assumes a
different decomposition than feature 1, with nowhere that records the product-level truth once.

The iteration-8 dogfood made this concrete: the document-translation product's architecture (8 services,
IDesign, Container Apps, Entra External ID, content-free telemetry) is a PRODUCT fact, not a per-feature
one — yet today there is nowhere to establish it once and have later features inherit it. The
architecture-summit analogy the maintainer drew for A4 has two levels in real practice: a product summit
that sets the macro shape once, then short per-feature design sessions that refine within it.

## What

A two-tier workshop model:

- **Tier 1 — Product/App-level workshop (once, re-openable).** Run at product inception (or the first
  feature) and re-openable on demand. Establishes and records the PRODUCT-level design truth: the macro
  architecture, the chosen design method / decomposition style (consuming A6/FR-035), the service and
  component landscape, the cross-cutting decisions (identity, telemetry, data lifecycle, hosting,
  residency), and the binding product constraints. Persisted as a product-level artifact (for example
  `.specrew/product-design.md` plus a structured sibling) that is shared project truth, version-controlled.
- **Tier 2 — Per-feature workshop (short, inherits Tier 1).** Each feature's lens workshop and
  design-analysis INHERIT the product-level decisions as given context, and discuss only what is NEW or
  DIFFERENT for this feature — which existing services it touches, which new component it adds, where it
  diverges from the product defaults (with an explicit, recorded reason). The per-feature session is short
  because the macro shape is already settled; it focuses on the feature's deltas.

Inheritance and drift: a per-feature design that contradicts a Tier-1 decision MUST surface it explicitly
(a recorded divergence with a reason), not silently — the same anti-omission discipline as FR-026 / SC-025.

## Scope / Non-goals

- NOT a replacement for A4 (per-lens workshop) or A6 (collaborative design-analysis) — it is the tier
  ABOVE them. A6 is per-feature depth; 162 is the cross-feature spine that per-feature sessions inherit.
- NOT the deferred Proposal 156 deep lens automation (project-local overrides, lens-file schema validation,
  broad cross-phase automation).
- Behavioral plus a deterministic floor, consistent with A4/A5/A6: the Tier-1 artifact's PRESENCE and the
  per-feature INHERITANCE / divergence record are gate-checkable; the QUALITY of the product workshop is
  validated by a runtime dogfood, not the gate.

## Acceptance criteria

- AC1: a product-level workshop produces a persisted, shared product-design artifact (macro architecture,
  design method, service landscape, cross-cutting decisions) — run once, re-openable.
- AC2: a second feature's design session demonstrably inherits the Tier-1 decisions as context and is
  shorter, discussing only the feature's deltas (verified by a runtime dogfood — the cross-feature value
  is behavioral).
- AC3: a per-feature design that diverges from a Tier-1 decision records the divergence with a reason; a
  silent contradiction is blocked or flagged (deterministic floor).
- AC4: degrades gracefully — a project with no product-design artifact falls back to today's per-feature
  workshop (no hard dependency).

## Effort + phasing

- ~15-25 SP, one feature (likely two iterations: the Tier-1 artifact + product-workshop conduct; then the
  Tier-2 inheritance + the divergence floor). Phase 2 (methodology), after Feature 141 closes.
- Sequence after Feature 141: A6 must ship first — the per-feature collaborative design is the unit 162
  composes into a two-tier model.

## Relationships

- Builds ON Feature 141 Amendments A4 (per-lens workshop), A5 (workshop visuals), and A6 (collaborative
  design-analysis).
- Composes WITH the lens catalog + applicability engine (Feature 141 FR-009 / FR-025 / FR-026).
- Related to the roadmap-spine / product-context direction (Proposal 057) — the product-design artifact is
  a natural companion to a product-level roadmap.

# Design Analysis: Product & Problem Domain Lens (first workshop lens)

**Feature**: 176-product-domain-lens
**Iteration**: 001
**Date**: 2026-06-09
**Phase**: pre-plan design-analysis (human verdict "approved for plan with Option X" required before plan.md)

## Problem framing

The spec (file:///C:/Dev/Specrew-product-domain-lens/specs/176-product-domain-lens/spec.md)
fixes the behavior: a required first lens `product-domain` runs before technical-lens
applicability selection, captures product/problem context at adaptive depth, tags
evidence, persists two records, and is enforced at the specify gate. The intake workshop
co-designed and human-confirmed the component map
(file:///C:/Dev/Specrew-product-domain-lens/specs/176-product-domain-lens/workshop/component-design.md)
and the two forks (extend the gate; conditional `research-needed` blocking).

What the spec deliberately left for design-analysis: the **mechanical slot-in** of the
lens into the existing catalog/selector, the **structured-record schema**, and — surfaced
at before-plan — a **quality-bar/stack correction**. This analysis resolves those.

## Decision Point 1 (primary) — where `product-domain` slots into the lens model

The existing selector (file:///C:/Dev/Specrew-product-domain-lens/scripts/internal/lens-applicability.ps1)
is a deterministic function of `applicability-map.json` (`always_on` foundational lenses +
yes/no question-gated specialized lenses). `product-domain` is always-applicable, runs
*before* that questionnaire, and carries machinery the selector has no concept of: a
Light/Standard/Deep depth model, an evidence-tag vocabulary, and its own artifacts. The
verdict picks one option.

### Option 1 (Simplest) — add `product-domain` to `always_on`

Register it as another `always_on` row in
file:///C:/Dev/Specrew-product-domain-lens/extensions/specrew-speckit/knowledge/design-lenses/applicability-map.json.

- **Trade-off**: cheapest registration, but semantically wrong. `always_on` lenses are
  selected *by* the questionnaire (the selector returns nothing until answers exist) and
  run *alongside* the technical lenses — that violates FR-001's "run before applicability
  selection." The depth model, evidence tags, and run-first ordering have nowhere to live.
  Forces the lens's distinct behavior through a mechanism built for yes/no gating.

### Option 2 (Reasonable) — a new first-stage workshop phase ahead of the selector — RECOMMENDED

Introduce a "product-domain phase" the workshop runs *first*: load `product-domain.md`,
facilitate the depth-adaptive capture, write the two records, enforce at the gate — and
only then run the existing applicability questionnaire + technical lenses, untouched. The
deterministic selector stays pure; `product-domain` is registered in `index.yml` as a
first-stage lens (a `default_phase` such as `intake-product-domain`) but is NOT a row in
`applicability-map.json`.

- **Trade-off**: introduces one new "first-stage" concept, but it matches FR-001 exactly,
  keeps the LLM/network-free selector pure (Feature 141's decoupling intent), and gives the
  depth model + evidence tags + artifacts a natural home. Touches the workshop skill and a
  thin first-stage runner; the selector is unchanged.

### Option 3 (By the book) — a generalized pre-technical lens-stage framework

Build a first-class "pre-technical stage" registry that can host `product-domain` today and
future pre-technical lenses (e.g. Proposal 164 risk-assessment, Proposal 175 supplemental
packs) as data rows, with ordering + a stage contract.

- **Trade-off**: most future-proof, but premature generalization for a single lens now —
  more surface, more tests, more deploy risk, and the abstraction would be guessed from one
  example. Right-sizing belongs here (design-analysis), and one lens does not justify the
  framework. The Option 2 first-stage phase can be generalized later when a second
  pre-technical lens actually lands, at lower total cost than speculating now.

**Crew recommendation: Option 2** (per the maintainer's clarify→plan instruction: bring both,
default to the first-stage phase, do not lock before this verdict). It is the smallest change
that honors FR-001 and keeps the selector pure, without the Option 3 over-build.

## Decision Point 2 (supporting) — the structured `product-domain.yml` schema

Resolved within the recommendation (no separate verdict). The record carries:

- `schema_version` (additive evolution; mismatch → fail-open WARN, matching the catalog
  convention).
- `depth` (`light | standard | deep`) + `depth_reason`.
- `areas` — per decision-area answers (users/stakeholders, pain/job + workaround, existing
  system/context, constraints, outcomes, MVP/non-goals/vision, alternatives — competitive
  only at standard/deep per FR-003).
- `statements[]` — each material statement with an `evidence` tag
  (`known | assumed | unknown | research-needed`) and, for `research-needed`, a
  `load_bearing` boolean driving FR-011's conditional plan-block.
- `skipped[]` — skipped areas + reasons; `follow_up_research[]`.
- `confirmation` / `confirmation_scope` — the SC-026 provenance the gate checks (FR-010).
- **`product_id` / `product_context_ref`** — a stable OPTIONAL reference field for future
  Proposal 162 product-level inheritance (maintainer instruction at the clarify→plan
  verdict). Present in the shape and schema-validated (SC-008); **no inheritance behavior is
  built now** — it is a forward-compatible hook only.

The human-readable `product-domain.md` is a rendered view of the same record.

## Decision Point 3 (supporting) — quality-bar / stack correction

`resolve-quality-profile.ps1` auto-inferred `quality-profile.react-spa-public.v1` (browser-UI
and concurrency-correctness) from the repo root `package.json`/react dependency. This feature's
real stack is PowerShell governance tooling — lens markdown, PowerShell functions, JSON/YAML
artifacts, and skill conduct; there is no browser UI and no concurrency. Recorded as drift
D-003 in file:///C:/Dev/Specrew-product-domain-lens/specs/176-product-domain-lens/iterations/001/drift-log.md.

Per the stack-aware-tool-selection rule, per-project stack selection needs the maintainer's
approval. **Proposed correction (needs your sign-off):** the quality bar for `plan.md` is the
PowerShell profile — Pester unit tests, PSScriptAnalyzer lint, and the existing Specrew
mechanical-checks (`dead-field` / `anti-pattern` / `test-integrity`) + governance validator —
not the react-spa bundle. Concurrency-correctness is `not-applicable` here.

## Co-Design Record

**Decomposition method (agreed at intake)**: governance/methodology decomposition by build
area (catalog knowledge → workshop conduct → per-feature artifacts → enforcement → tests), per
the human-confirmed component map.

**Component-to-responsibility map** (human-confirmed at intake; carried here unchanged):

- `product-domain.md` (catalog lens file) — the decision areas, depth model, evidence
  vocabulary, and no-batch-confirmation conduct.
- Catalog registration (`index.yml` first-stage entry + `diagram-vocabulary.json`) — makes the
  lens discoverable as the first-stage lens (Option 2).
- `specrew-design-workshop` skill — runs the product-domain phase first; deployed to the
  host-managed skill surfaces of all five supported hosts.
- Record writer/validator (PowerShell) — scaffolds `product-domain.{yml,md}`, validates fields,
  evidence tags, and provenance.
- Specify-gate floor — requires the record + SC-026 provenance; rejects batch approval (FR-009).
- Tests — depth selection, dual-artifact, evidence-tags, FR-009 non-equivalence, gate floor,
  host-parity, and the SC-008 schema conformance.

**Agreed key flow** (the slot-in under Option 2):

```text
feature intake
  -> [product-domain phase]  (load lens md -> depth-adaptive capture -> evidence tags
  ->                           -> write product-domain.{yml,md} -> specify-gate floor)
  -> applicability questionnaire (unchanged deterministic selector)
  -> technical lenses (architecture, data, ui-ux, ... unchanged)
  -> specify boundary
```

**Human-agreed marker**: PENDING this design-analysis verdict. On "approved for plan with
Option X" I set the agreement and `co_design: true` on the iteration record, then render +
persist the typed design-gate packet and call the pre-plan gate before authoring plan.md.

## Crew recommendation (summary)

- **DP1**: Option 2 — new first-stage workshop phase ahead of the selector.
- **DP2**: the schema above, including the optional `product_id` / `product_context_ref`
  forward-compat hook (shape only).
- **DP3**: correct the quality bar to the PowerShell profile (needs your sign-off).

## Human Decision

- **Chosen option**: *pending verdict* (expected: "approved for plan with Option 2").
- **Reason / modifications**: *to be recorded from the verdict*.
- **Stack correction approved?**: *pending* (DP3).
- **Authorizing commit**: *to be recorded — the commit that contains this verdict, not the
  design-analysis draft commit*.
- **Verdict**: *pending*.

---
proposal: 156
title: Design Analysis Lens Knowledge Catalog
status: candidate
phase: phase-2
estimated-sp: 11-19
discussion: surfaced 2026-06-02 after manual smoke of Feature 140 design-analysis gate; maintainer requested extending the experience to databases/storage, UI/UX, DevOps/IaC/CI/CD/secrets/RBAC, and other architecture areas using the architecture book/course corpus as reusable knowledge files.
---

# Design Analysis Lens Knowledge Catalog

## Why

Feature 140 proves the value of a human-felt design-analysis stage: it changes
the lifecycle from "jump to plan" to "surface the architectural decision first."
The next problem is coverage. Databases, UI/UX, DevOps, security, observability,
and API integration each have distinct question sets. If those questions remain
prompt-only, the Crew will ask them inconsistently and future areas will require
code changes.
If the resulting answers remain prose-only, later development and review agents
cannot reliably tell which component names, data structures, contracts, UI
choices, security boundaries, platform assumptions, or code rules are binding.

Specrew needs a repo-local knowledge folder where design lenses are explicit,
reviewable, and extensible. The source should be the project's own architecture
methodology: Alon Fliess' architecture book markdown and Software Architecture
course material, paraphrased into operational questions and plan obligations.

## What

Add a data-driven design-lens catalog under:

```text
extensions/specrew-speckit/knowledge/design-lenses/
```

The initial catalog contains:

- architecture core
- requirements and NFRs
- data and storage
- UI/UX
- DevOps and operations
- integration and APIs
- security and compliance
- observability and resilience
- component design

Each lens defines applicability signals, design decision points, a question
bank, alternative dimensions, plan obligations, validation signals, and source
notes. The catalog also includes `index.yml`, `lens-schema.md`, and
`lens-template.md` so new areas can be added without changing runtime code.

The runtime integration SHALL also emit a canonical workshop decision manifest,
`workshop-decisions.yml` (or a schema-equivalent file if the final feature names
it differently). This is the producer-side contract that later plan,
implementation, variance, and review stages consume. It does not replace the
human-readable workshop notes; it gives every selected or skipped workshop
decision a stable ID, provenance, applicability status, human-confirmation
state, expected evidence, and reconciliation path.

Example shape:

```yaml
decisions:
  - id: component.session-bootstrap-manager
    lens: component-design
    source: workshop/component-design.md
    kind: component-responsibility
    applies: true
    confirmation: human-confirmed
    decision: "SessionBootstrapManager orchestrates bootstrap only."
    expected_evidence: [implementation, unit-tests, integration-test]
  - id: data.bootstrap-directive.required-reads
    lens: data-storage
    source: data-model.md
    kind: data-field
    applies: true
    confirmation: human-confirmed
    decision: "required_reads carries mandatory directive artifacts."
    expected_evidence: [contract, unit-tests]
  - id: code-rule.object-invariants
    lens: code-implementation
    source: workshop/code-implementation.md
    kind: code-rule
    applies: true
    confirmation: baseline-default
    decision: "Objects keep member values inside invariant ranges."
    enforcement: [review, unit-tests]
  - id: platform.cloud-azure.reference-architecture
    lens: domain-platform-analysis
    source: workshop/domain-platform-analysis.md
    kind: supplemental-pack-decision
    applies: false
    applicability_reason: "Feature is local-only and has no cloud deployment."
```

### Functional requirements

- **FR-001**: Specrew SHALL ship a repo-local design-lens knowledge catalog.
- **FR-002**: Each lens SHALL include applicability signals so the Crew can
  activate only relevant areas.
- **FR-003**: Each lens SHALL include a question bank that affects design,
  planning, tests, release validation, or explicit deferral.
- **FR-004**: Each lens SHALL include alternative dimensions for simplest,
  reasonable, and by-the-book design-analysis options.
- **FR-005**: Each lens SHALL include plan obligations and validation signals
  so design-analysis output can flow into plan/review evidence.
- **FR-006**: The catalog SHALL include a schema/template for adding future
  areas.
- **FR-007**: Source notes SHALL cite book/course anchors at a high level and
  SHALL NOT copy long private or copyrighted source passages.
- **FR-008**: Future runtime integration SHOULD load the catalog as data during
  design-analysis instead of hard-coding the lens questions in prompts.
- **FR-009**: Runtime integration SHOULD allow project-local overrides or
  additions after the shipped catalog is copied or referenced.
- **FR-010**: Runtime integration SHALL emit a schema-validated
  `workshop-decisions.yml` manifest containing every selected, delegated,
  skipped, or applicability-filtered workshop decision with a stable decision
  ID.
- **FR-011**: Each decision record SHALL include lens ID, source artifact,
  decision kind, applies/skipped state, human confirmation provenance, expected
  evidence, and the artifact or gate that must reconcile accepted changes.
- **FR-012**: Lens additions such as Proposal 163 `code-implementation` and
  Proposal 175 `domain-platform-analysis` SHALL feed decisions into the same
  manifest rather than creating isolated verification universes.
- **FR-013**: Applicability or lens-agenda approval SHALL NOT count as approval
  for all workshop questions. The manifest SHALL distinguish
  `human-confirmed`, `human-delegated`, `human-skipped`, `baseline-default`,
  and `applicability-filtered` decisions.

### Out of scope

- Implementing runtime selection of lenses in this proposal record.
- Changing the in-flight Feature 140 implementation scope.
- Forcing every feature to answer every lens.
- Treating applicability selection, lens-agenda approval, or pack activation as
  blanket approval for all questions under that lens.
- Publishing the private book/course source text.
- Replacing Proposal 137; this proposal is a knowledge-data companion.

## Effort

- **Iteration 1 (~3-5 SP)**: Catalog structure, initial lens files, index,
  schema, template, and proposal/index update.
- **Iteration 2 (~5-9 SP)**: Runtime loader and design-analysis integration:
  select applicable lenses, render focused questions, support project-local
  additions, and validate catalog shape.
- **Iteration 3 (~3-5 SP)**: Workshop decision manifest producer:
  schema-validate `workshop-decisions.yml`, assign stable decision IDs, carry
  human-confirmation provenance, and expose expected review evidence for
  Proposal 145.
- **Total**: ~11-19 SP.

## Phase placement

Phase 2. This extends Proposal 137 / Feature 140 while the design-analysis
surface is still fresh, but it is intentionally separable from the current
feature so the active branches do not absorb uncontrolled scope.

## Open questions

1. Should the runtime load shipped lenses directly from the extension path, or
   copy them into `.specrew/knowledge/design-lenses/` for project-local editing?
2. Should project-local lenses be additive only, or can they override shipped
   lens IDs?
3. Should lens applicability be driven only by Crew judgment, or should
   specify/clarify answers activate lenses mechanically?

## Risks

- **Too many questions**: a broad catalog can become a long interview.
  Mitigation: applicability signals and profile-aware depth should select only
  relevant lenses.
- **Prompt-only regression**: if runtime integration pastes the entire catalog
  into prompts, behavior stays inconsistent. Mitigation: load lenses as data,
  render focused prompts, and preserve plan obligations.
- **Source leakage**: book/course material is private working source. Mitigation:
  paraphrase and record source anchors only.

## Cross-references

- Related proposals: 063, 137, 141, 145, 163, 174, 175, 197.
- Source artifacts:
  `extensions/specrew-speckit/knowledge/design-lenses/`.
- Composability with: Proposal 137 design-analysis gate, Proposal 063
  substantive intake, Proposal 141 persona/lens separation, Proposal 145
  workshop-decision conformance, Proposal 163 code-implementation rules,
  Proposal 174 boundary variance, Proposal 175 supplemental packs, and
  Proposal 197 continuous co-review (which consumes these workshop decisions as
  the rubric for its inline reviewer).

## Implementation status (2026-06-03; amended 2026-06-08)

This proposal is being delivered in slices, not all at once:

- **Shipped (read-only catalog):** the lens knowledge catalog —
  `extensions/specrew-speckit/knowledge/design-lenses/` (`index.yml`, schema, template, and the
  initial lenses: architecture-core, requirements-nfr, data-storage, ui-ux, devops-operations,
  integration-api, security-compliance, observability-resilience, component-design) — is on `main`
  and usable as read-only input. Feature 141 Iteration 1 dogfooded it (a lightweight "Applicable
  Lenses" reference).
- **In progress (Feature 141, Iteration 4 — Amendment A1):** **questionnaire-driven applicability
  selection.** A small fixed applicability questionnaire ("UI? auth/secrets/PII? persistent data?
  external API? deploy/release? perf/resilience?") is recorded as a `lens-applicability.json`
  artifact, and a **deterministic** selector maps answers to lenses (foundational lenses always-on;
  specialized lenses gated by their answer) via a **decoupled sibling map file** (the catalog
  `index.yml` stays pure). Tracked as Feature 141 FR-009/FR-010/FR-025 + SC-006/SC-015; the selector
  is a pure function (no network/LLM), unit-testable. Maintainer decision 2026-06-03: Option B /
  decoupled.
- **Future (still deferred — this proposal's remaining scope):** project-local lens overrides,
  lens-schema validation enforcement, broad cross-phase lens automation, a standalone `specrew lens`
  command, a schema-validated answer/selection artifact, canonical `workshop-decisions.yml`
  producer support, stable decision ID generation, and auto-generated per-lens rationale.
  These are intentionally NOT in Feature 141 (FR-010 keeps them deferred); they remain the open
  scope of this proposal for a later feature.

## Status history

- 2026-06-02: candidate proposal created with initial knowledge catalog seeded
  from the architecture book markdown and Software Architecture course material.
- 2026-06-03: catalog confirmed shipped on `main` (read-only); the questionnaire-driven
  applicability-selection slice was un-deferred into Feature 141 Iteration 4 (Amendment A1,
  decoupled Option B). Truly-deep automation remains this proposal's deferred scope. See the
  Implementation status section above.
- 2026-06-08: amended the runtime integration contract to require a
  schema-validated `workshop-decisions.yml` producer manifest with stable
  decision IDs, human-confirmation provenance, expected evidence, and one shared
  decision stream for base lenses, Proposal 163 code rules, and Proposal 175
  supplemental packs. This is the source artifact Proposal 145 verifies through
  `workshop-decision-conformance.yml`.

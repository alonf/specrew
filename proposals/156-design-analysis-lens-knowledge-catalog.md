---
proposal: 156
title: Design Analysis Lens Knowledge Catalog
status: candidate
phase: phase-2
estimated-sp: 8-14
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

### Out of scope

- Implementing runtime selection of lenses in this proposal record.
- Changing the in-flight Feature 140 implementation scope.
- Forcing every feature to answer every lens.
- Publishing the private book/course source text.
- Replacing Proposal 137; this proposal is a knowledge-data companion.

## Effort

- **Iteration 1 (~3-5 SP)**: Catalog structure, initial lens files, index,
  schema, template, and proposal/index update.
- **Iteration 2 (~5-9 SP)**: Runtime loader and design-analysis integration:
  select applicable lenses, render focused questions, support project-local
  additions, and validate catalog shape.
- **Total**: ~8-14 SP.

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

- Related proposals: 063, 137, 141.
- Source artifacts:
  `extensions/specrew-speckit/knowledge/design-lenses/`.
- Composability with: Proposal 137 design-analysis gate, Proposal 063
  substantive intake, Proposal 141 persona/lens separation.

## Status history

- 2026-06-02: candidate proposal created with initial knowledge catalog seeded
  from the architecture book markdown and Software Architecture course material.

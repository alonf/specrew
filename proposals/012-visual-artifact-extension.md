---
proposal: 012
title: Visual Artifact Extension
status: candidate
phase: phase-1
estimated-sp: 15
discussion: tbd
---

# Visual Artifact Extension

## Why

Specrew's lifecycle artifacts are all markdown text. The interaction model (Feature 016) ships three pillars — stop frequency, content density, click-through navigation — but doesn't yet address the **visual layer**. Architecture diagrams, data-flow diagrams, sequence diagrams, task DAGs — these are absent from Specrew artifacts.

For complex features, text descriptions of architecture and flow are insufficient. The user understands faster with a picture. The Reviewer evaluates faster with a picture. Onboarding readers understand faster with a picture.

This proposal adds the visual layer: Mermaid/PlantUML diagrams embedded in spec/plan/iteration artifacts, rendered click-through when the user opens the file in a Mermaid-aware Markdown viewer.

## What

**Pillar 4 of the interaction model** (complementing Feature 016's three pillars):

1. **Diagram-language support**: `spec.md`, `plan.md`, per-iteration artifacts support inline ```mermaid``` and ```plantuml``` code blocks
2. **Diagram templates** per artifact type:
   - Spec: high-level architecture diagram + data-flow diagram
   - Plan: task DAG + ownership-boundary diagram
   - Iteration: sequence diagram of cross-boundary interactions
3. **Reviewer skill extension**: Reviewer checks that diagrams exist and align with text content
4. **Validator soft-warning rule**: `missing-architecture-diagram` for features that introduce architectural surfaces but lack a diagram

Composability: when Methodology Site (Proposal 013) ships, diagrams in artifacts auto-render in the public site. Visual artifacts compose with click-through navigation: file:/// URLs to artifacts with diagrams provide both substantive content AND visual structure.

## Effort

- **Iteration 1 (~10 SP)**: Diagram-language support + diagram templates + Reviewer skill update
- **Iteration 2 (~5 SP)**: Soft-warning validator rule + integration tests + Methodology Site embed support
- **Total**: ~15 SP

## Phase placement

Phase 1 — completes the interaction model trilogy (Substantive Interaction Model + Architecture Intent Checkpoint + Visual Artifact Extension).

## Open questions

1. Mermaid only, or also PlantUML?
2. Required diagrams per artifact type (mandatory) or recommended (advisory)?
3. Diagram review responsibility — does the Reviewer evaluate diagram CORRECTNESS or just EXISTENCE?
4. Auto-generation from spec text — out of scope?
5. Methodology Site rendering — server-side or client-side?

## Risks

- **Diagram drift**: diagrams not updated when text changes. Mitigation: soft-warning rule for "spec FR added but diagram unchanged."
- **Diagram authoring overhead**: another artifact to maintain per feature. Mitigation: templates + diagram-required-only-for-architectural-features filter.
- **Tooling diversity**: Mermaid + PlantUML have different rendering surfaces. Mitigation: start with Mermaid only (broader Markdown-viewer support); add PlantUML later if demand.

## Cross-references

- Composes with: Proposal 007 (Substantive Interaction Model) — Pillar 4 completion
- Composes with: Proposal 011 (Architecture Intent Checkpoint) — visual representation of intent
- Composes with: Proposal 013 (Methodology Site) — diagrams embed in public site
- Targets: F-017 in eventual on-disk numbering

## Status history

- 2026-05-13: candidate captured during ClipBoard6 dogfooding (observation #3)
- Status → draft pending detailed source spec

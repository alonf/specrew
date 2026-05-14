---
proposal: 011
title: Architecture Intent Checkpoint
status: draft
phase: phase-1
estimated-sp: 10
discussion: tbd
---

# Architecture Intent Checkpoint

## Why

The current `/speckit.plan` step transitions from spec to implementation plan but doesn't explicitly capture the architectural intent — the "shape" of the solution. This means:

- Architectural decisions are inferred from task table structure rather than declared
- The Reviewer can't evaluate architectural fit because the architectural intent isn't an explicit surface
- Future iterations can drift from the original architectural intent without surfacing the divergence

Adding a checkpoint inside `/speckit.plan` that explicitly captures architectural intent gives Specrew an 8th boundary inside the planning phase, complementary to Feature 016's boundary discipline.

## What

A new sub-phase within `/speckit.plan`:
1. Spec ingestion (existing)
2. **Architecture Intent Checkpoint** (new) — explicit prose statement of:
   - Primary architectural pattern (monolith / microservice / serverless / etc.)
   - Coupling/cohesion strategy
   - Data flow shape
   - Key boundaries (process, deployment, trust)
   - Notable trade-offs accepted
3. Task decomposition (existing)
4. Quality scaffold (existing)

The checkpoint is captured in a new `architecture-intent.md` artifact under `specs/<feature>/` (NOT per-iteration; architectural intent is feature-level).

The Reviewer's evaluation at review boundary checks implementation conforms to declared architectural intent — divergence requires explicit reconciliation.

Composes with Feature 016's boundary discipline: the checkpoint is a boundary commit on its own, between planning-scaffold and tasks-generation.

Composes with Proposal 008 (NFR Governance) Tier-3 hosting-model question: the architectural intent statement should reference the hosting-model answer.

## Effort

- **Iteration 1 (~10 SP)**: Coordinator-prompt update + `architecture-intent.md` template + Reviewer skill for intent-conformance check + integration tests
- **Total**: ~10 SP

On-disk spec already exists at `specs/006-human-architecture-checkpoint/spec.md` (Draft status); this proposal documents the public roadmap entry.

## Phase placement

Phase 1 — complements Feature 016's boundary discipline. Cheap to ship once Feature 016's infrastructure exists.

## Open questions

1. Is `architecture-intent.md` mandatory or opt-in? (Recommended: opt-in via flag, becomes default in Phase 2)
2. Intent template — free-form or structured headings?
3. Conformance check granularity — strict (every divergence flagged) or directional (only major divergences)?
4. Multi-iteration evolution: can architectural intent evolve across iterations of the same feature?
5. Cross-feature reuse — can multiple features share an architectural-intent document?

## Risks

- **Premature architecture commitment**: forcing architectural choices at planning may overcommit before discovery. Mitigation: intent statement explicitly captures "what we're committing to" vs "what's still open."
- **Reviewer overhead**: another conformance check at review boundary. Mitigation: the check is intent-level (directional), not detail-level (every line).
- **Documentation burden**: another artifact per feature. Mitigation: template-driven; senior architects can complete in 10-15 minutes.

## Cross-references

- Existing on-disk spec: `specs/006-human-architecture-checkpoint/spec.md`
- Composes with: Proposal 007 (Substantive Interaction Model) — 8th boundary inside `/speckit.plan`
- Composes with: Proposal 008 (NFR Governance) — Tier-3 hosting-model answer feeds intent statement
- Composes with: Proposal 014 (Red Team Agent) — Red Team challenges declared architectural intent

## Status history

- 2026-05-09: candidate captured during early Specrew planning
- 2026-05-13: status → draft; on-disk spec exists at `specs/006-human-architecture-checkpoint/`
- Queued: status → active after Feature 016 ships

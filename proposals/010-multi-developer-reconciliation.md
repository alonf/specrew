---
proposal: 010
title: Multi-Developer Reconciliation
status: draft
phase: phase-5
estimated-sp: 75
discussion: tbd
---

# Multi-Developer Reconciliation

## Why

Specrew today is designed for a single developer working on one feature at a time. When multiple developers want to work on different features concurrently:

- Each developer's feature touches shared surfaces (`validate-governance.ps1`, coordinator prompts, `.squad/decisions.md`)
- No mechanism exists to detect semantic conflicts at PR time (only raw git conflicts)
- No coordination point for when two features have overlapping FRs or require the same boundary discipline updates
- The boundary-claim-without-commit pattern would compound dangerously if developers worked from "the new baseline" that wasn't yet committed

The methodology promises spec-governed AI coding; without multi-developer reconciliation, that promise breaks at the moment teams scale.

## What

Four major components:

**1. FR-provenance tables**: every functional requirement in every shipped feature gets tagged with its originating feature + iteration. When a new feature claims FR-NNN that conflicts with an existing FR, the validator surfaces the conflict at PR time, not at merge time.

**2. PR-time conflict classifier**: validator pass that runs at PR boundary, identifying:
- Hard conflicts: same FR claimed by two features
- Soft conflicts: overlapping behavior across features
- Touched-shared-surfaces: which files are co-modified

Produces a structured conflict report that Squad's Spec Steward consumes.

**3. Spec Steward as Blocking Mediator**: when conflicts are detected, the Spec Steward agent becomes a blocking participant in PR review. Cannot merge until conflicts are explicitly resolved (acknowledged, reconciled, or one feature deferred).

**4. Reconciliation-iteration pattern**: when two features have genuine conflicts that require design changes, a new "reconciliation iteration" is opened on a designated branch. The reconciliation iteration's purpose is to merge the two feature designs into a coherent specification, then both features re-anchor against the reconciled spec.

## Effort

- **Iteration 1 (~25 SP)**: FR-provenance tagging + tooling to populate provenance from spec.md FRs + validator extension for tag enforcement
- **Iteration 2 (~25 SP)**: PR-time conflict classifier + structured conflict report format + validator integration
- **Iteration 3 (~25 SP)**: Spec Steward blocking-mediator behavior + reconciliation-iteration scaffolding + integration tests
- **Total**: ~75 SP

## Phase placement

Phase 5 — after MVP (Phase 4 exit). Multi-developer support is a major scope expansion; needs the foundational quality work shipped first.

## Open questions

1. How are FR numbers assigned across concurrent features? Centralized allocation or per-feature with reconciliation at merge?
2. Conflict classification rules — what counts as "overlapping behavior"?
3. Reconciliation-iteration ownership: which developer's branch hosts it? Or a shared reconciliation branch?
4. Block vs warn for soft conflicts?
5. Authentication: how do we know developer X authored vs developer Y?
6. PR-template integration: does the conflict report attach to the PR or to a separate artifact?
7. Validator performance: full-history scan per PR — what's the budget?
8. Backward compatibility: how do existing single-developer projects opt into this?

## Risks

- **Performance impact**: per-PR full-history scan may be slow for mature projects. Mitigation: incremental scanning over commits since last reconciliation.
- **Reconciliation iteration overhead**: forcing two features to merge designs may slow both. Mitigation: only triggered for hard conflicts; soft conflicts can be acknowledged in PR comments.
- **Provenance drift**: FRs can be renumbered or restructured over time. Mitigation: provenance is append-only; renumbering creates a new provenance link, not a replacement.
- **Two-developer assumption**: validator may not scale to 5+ concurrent features. Mitigation: design for N-way reconciliation; surface multi-way conflicts as multi-party negotiations.

## Cross-references

- Composes with: Proposal 015 (Expertise-Aware Adaptive Interaction) — Capability 3 multi-developer decision routing depends on this
- Foundation for: any future scenario where multiple developers contribute concurrently

## Status history

- 2026-05-11: candidate captured during scaling discussion
- 2026-05-12: status → draft; source spec written

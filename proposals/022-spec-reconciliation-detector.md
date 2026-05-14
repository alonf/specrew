---
proposal: 022
title: Spec-Reconciliation Detector
status: candidate
phase: phase-2
estimated-sp: 10
discussion: tbd
---

# Spec-Reconciliation Detector

## Why

When an iteration's implementation discovers something not anticipated in the parent feature spec — a new requirement, a deferred concern resurfacing, a clarification needed — the discovery should reconcile back to `spec.md`. Without enforcement, divergence accumulates: the iteration ships against an implicit spec, the explicit spec drifts from reality.

The pattern was visible during Feature 016 Iter 1, where multiple FR-008 / FR-009 reconciliations happened during implementation but the original spec wasn't always updated to reflect what was learned.

## What

A new validator rule that compares iteration artifacts (state.md, drift-log.md, review.md, retro.md) against the parent `spec.md` for divergence signals:
- New FR-NNN references in iteration artifacts that aren't in spec.md → fail
- Drift-log entries declaring "this differs from spec.md X" → require spec.md reconciliation entry
- Retro lessons that imply spec.md inadequacy → surface for reconciliation review

When divergence detected, emit soft-warning (not hard-fail) with specific reconciliation guidance: "drift-log.md mentions FR-NNN-A which doesn't appear in spec.md; either add to spec.md as discovered, or update drift-log.md to remove."

## Effort

~10 SP, 1 iteration.

## Phase placement

Phase 2 — graduation candidate, pair with Proposal 021 (Bypass Detector). Both formalize prompt-only invariants as validator-enforced rules.

## Open questions

1. Detection granularity — token-level FR-NNN matching, or semantic divergence detection?
2. Soft-warning vs hard-fail at rollout?
3. Reconciliation requirement — every drift requires spec.md update, or only "this is permanent" drifts?
4. Multi-iteration drift accumulation — if Iter 1 drifted and Iter 2 drifts in same direction, is that an aggregate signal?

## Risks

- **Over-flagging legitimate clarifications**: clarify-time refinements aren't drifts. Mitigation: clarify-completed-at marker; reconciliation requirement only after clarify closes.
- **Reconciliation overhead**: forcing spec.md updates for every drift slows iteration. Mitigation: soft-warning level; drift can be acknowledged in drift-log.md without spec update for transient observations.

## Cross-references

- Composes with: Proposal 021 (Bypass Detector) — paired graduation candidates
- Justified by: Feature 016 reconciliation patterns

## Status history

- 2026-05-12: candidate captured following validator-hardening retro
- 2026-05-13: queued for Phase 2 alongside bypass detector

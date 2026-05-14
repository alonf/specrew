---
proposal: 027
title: Iteration 011 Cleanup (F-001 Pre-Canonical-Schema Refinement)
status: candidate
phase: phase-2
estimated-sp: 7
discussion: tbd
---

# Iteration 011 Cleanup

## Why

Feature 001 (specrew product) has iteration 011 that uses a pre-canonical schema, predating Specrew's current canonical state.md / plan.md format. The iteration is closed but its artifacts aren't aligned with current schema conventions. This creates inconsistency in the project history.

Cleanup options surfaced during F-014 closeout discussion:
1. Schema-migrate the iteration artifacts to canonical format (preserves history with consistency)
2. Annotate the iteration as grandfathered (preserves history, accepts inconsistency)
3. Skip — historical artifacts can stay in their original format

The recommended approach is grandfathering with explicit annotation: a small refinement that adds `schema-version: pre-canonical-v0` to iteration-011's artifacts, plus a validator rule that exempts pre-canonical iterations from current-schema checks.

## What

Small focused feature:
- Add `schema-version` field to state.md / plan.md / drift-log.md frontmatter
- Validator rule: pre-canonical iterations exempt from canonical-schema enforcement
- Iteration 011's artifacts get the `schema-version: pre-canonical-v0` annotation
- README / docs note explaining the grandfathering convention

## Effort

~5-10 SP, single iteration.

## Phase placement

Phase 2 — small cleanup work; not load-bearing. Slot after graduation candidates.

## Open questions

1. Grandfathering vs migration — keep grandfathering, or eventually migrate?
2. Schema version naming — `pre-canonical-v0`, `legacy`, or other?
3. Annotation requirement — opt-in per-iteration or automatic for pre-N iterations?
4. Cross-feature grandfathering — does this set precedent for other future schema changes?

## Risks

- **Grandfathering precedent**: setting a "we'll grandfather past iterations" pattern could discourage future migrations. Mitigation: explicit "this is a one-off; future schema changes should migrate, not grandfather."

## Cross-references

- Composes with: validator's schema enforcement rules

## Status history

- 2026-05-13: candidate captured during F-014 closeout (deferred small feature)

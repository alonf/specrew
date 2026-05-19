---
proposal: 003
title: Squad Descriptive References
status: shipped
phase: phase-1
estimated-sp: 9
shipped-as: feature-012
discussion: tbd
---

# Squad Descriptive References

## Why

User-facing Specrew output frequently referenced opaque numeric identifiers — `FR-013`, `T007`, decision IDs — without descriptive context. Users had to manually look up what each ID meant by opening linked artifacts. Particularly painful in boundary handoffs where multiple identifiers compound.

The previous Feature 007 (user-facing progress handoff) introduced soft validation for plain-language responses, but didn't enforce that numeric IDs in user-facing surfaces carry descriptive labels alongside.

## What

Extended Specrew's soft-validator surface with a `numeric-ID-undescribed` rule that fires when user-facing handoff messages reference identifiers without nearby descriptive context. Examples that pass:

- `FR-013 (validator-hardening)` ✓
- `T007 — public-readiness drift validation` ✓

Examples that fail:

- Bare `FR-013` without surrounding context ✗
- Bare `T007` in a sentence ✗

The rule is soft-warning, not hard-fail — it prompts authors to add context rather than blocking output.

Composes with Feature 007's plain-language response format.

See `specs/012-descriptive-id-handoffs/spec.md` for full detail.

## Effort

~9 SP across 1 iteration.

## Phase placement

Phase 1 — user-facing clarity. Substantially reduces the cognitive cost of reading Specrew's handoff messages.

## Cross-references

- Specification: `specs/012-descriptive-id-handoffs/spec.md`
- Composes with: Feature 007 user-facing progress handoff format
- Cross-referenced by: Feature 016 substantive-handoff Pillar 2 expectations

## Status history

- 2026-05-11: candidate captured following user observation about opaque IDs
- 2026-05-11: status → draft
- 2026-05-12: status → active → shipped

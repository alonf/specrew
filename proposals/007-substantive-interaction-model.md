---
proposal: 007
title: Substantive Interaction Model
status: shipped
phase: phase-1
estimated-sp: 22
shipped-as: feature-016
discussion: tbd
---

# Substantive Interaction Model

## Why

Specrew's value comes from the interaction model between the human developer and the lifecycle. Three pillars are required at every boundary for that model to deliver value: stop frequency (boundary discipline), stop substance (essence-in-console), and click-through navigation (file:/// links).

External dogfooding on a fresh project surfaced three related observations that together described a broken interaction model:

- The user had to manually open `.md` files to understand state because boundary handoffs were procedurally complete but substantively thin
- File references in boundary handoffs used bare paths instead of `file:///` URLs, breaking click-through navigation
- Lifecycle boundaries were bundled into auto-continue cycles, replacing the dogfooding pattern of 7 discrete authorizations per iteration with 2-3

This proposal codifies all three pillars as enforced rules in the coordinator prompt + validator, so the interaction model holds without depending on the user's pasting habit.

## What

Three-pillar enforcement across the coordinator prompt + `validate-governance.ps1`:

**Pillar 1 — Boundary Discipline**: Squad must stop at each of the 7 iteration boundaries and request explicit human authorization. The `bundled-boundary-advance` hard-validator rule detects multiple boundary commits without intervening recorded human authorization.

**Pillar 2 — Essence in Console**: Boundary handoffs must contain substantive content in each of three sections ("What I just did", "Why I stopped", "What I need from you"). Soft-validator rules fire when sections lack specific identifiers, fail to name the specific boundary, or omit actionable verdict requests.

**Pillar 3 — Click-Through Navigation**: All artifact references in boundary handoffs must use `file:///` URL format. Hard-validator rule blocks bare paths in handoffs; soft-warning for in-flight narration. Explicit exemption list for shell commands, code blocks, JSON/YAML, regex patterns.

24 functional requirements organized by pillar, plus cross-cutting requirements for corpus row additions, integration tests, README updates, and historical cross-references.

See `specs/016-substantive-interaction-model/spec.md` for full detail.

## Effort

- **Iteration 1 (~13 SP planned, ~25+ SP actual)**: Coordinator prompt updates + 2 hard-validator rules + 4 soft-validator rules + canonical authorization-recording shape. Multiple repair cycles surfaced design defects (regex substring-match, pending-vs-post-commit Commit Reference, hash-treadmill on amend) that were resolved within the iteration.
- **Iteration 2 (~17 SP)**: Integration tests + corpus rows + README/template updates + carryover work (FR-008 pending → post-commit Commit Reference synchronization, UTC seconds-precision authoring, stale-reference scan mandate)
- **Total**: ~22 SP planned, ~40+ SP actual with repair cycles

## Phase placement

Phase 1 — the foundation of the interaction model. Subsequent features (Architecture Intent Checkpoint, Visual Artifact Extension) compose with this.

## Notable outcomes

This iteration was the first to demonstrate Specrew's adversarial self-testing capability:

- The validator rules introduced in Iteration 1 fired on the iteration's own commits, surfacing multiple design defects
- Each defect was resolved through repair cycles within the iteration
- Six corpus-row candidates surfaced; three estimation-discipline learnings captured
- A Reviewer Regression Event was triggered and recovered via human verifier

The repair cost was substantial (~30+ SP of additional work) but every defect was caught by the system itself, not by escaping to production. The methodology demonstrated its own value at meta level.

## Corpus-row candidates surfaced

- `validator-catch-22-pre-commit-vs-post-commit` (validation-discipline)
- `boundary-regex-substring-match` (validation-discipline) — resolved in Iter 2
- `fr-008-pending-commit-reference-vs-validator-hash-match` (validation-discipline) — resolved in Iter 2
- `nfr-budget-calibrated-against-pre-refactor-baseline` (estimation-discipline)
- `self-referential-feature-sp-surcharge` (estimation-discipline)
- `decisions-ledger-parser-fractional-second-timestamp-incompatibility` (validation-discipline) — resolved in Iter 2
- `repair-cycles-cascade-from-bookkeeping-misalignment` (process-discipline)

## Cross-references

- Specifications: `specs/016-substantive-interaction-model/spec.md` (canonical), `specs/016-substantive-interaction-model/iterations/001/`, `specs/016-substantive-interaction-model/iterations/002/`
- Composes with: Proposal 011 (Architecture Intent Checkpoint), Proposal 012 (Visual Artifact Extension)
- Foundation for: Proposal 014 (Red Team Agent) — Red Team would have caught the FR-006↔FR-009 design conflict at clarify time
- Validates: 6 new validator rules in `extensions/specrew-speckit/scripts/validate-governance.ps1`

## Status history

- 2026-05-13: candidate captured following external dogfooding observations
- 2026-05-14: status → draft; source spec finalized
- 2026-05-14: status → active; Feature 016 entered Specrew lifecycle
- 2026-05-15: Iteration 1 closed
- 2026-05-15: Iteration 2 in flight; status → shipped on feature-closeout

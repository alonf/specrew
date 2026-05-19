---
proposal: 015
title: Expertise-Aware Adaptive Interaction
status: candidate
phase: phase-2
estimated-sp: 25
discussion: tbd
---

# Expertise-Aware Adaptive Interaction

## Why

Specrew treats all users identically — same gates, same communication style, same hand-holding. This is correct for a methodology-first approach but leaves value on the table:

- Senior users find verbose questioning patronizing
- Novice users benefit from explicit prompts experts find redundant
- In team contexts, decision-routing is implicit ("whoever's at the keyboard answers")

A per-user expertise model drives adaptive interaction across the lifecycle: thresholds, gates, and decision-routing all adapt to declared and inferred expertise.

## What

A per-user expertise model in `.specrew/user-profile.yml` with three dimensions:

1. **General seniority** (years / band)
2. **Per-technology familiarity** (per stack family — senior backend dev may be React novice)
3. **Per-solution-domain expertise** (distributed systems / embedded / data engineering / etc.)

Hybrid assessment: explicit Q&A at bootstrap (3-5 questions) + contextual inference over time + explicit re-calibration via `specrew profile update`.

Three capabilities unlocked:

1. **Adaptive substantive-content thresholds**: Feature 016's ≥3-identifiers / ≥50-words rules relax for experts (per dimension), stay strict for novices
2. **Adaptive gate strictness**: redundant checks for experts (e.g., "have you considered idempotency?" auto-resolved for distributed-systems experts) but safety-critical gates (security, spec-fidelity, lifecycle discipline) NEVER relax
3. **Multi-developer decision routing** (depends on Multi-Developer Reconciliation): "this decision is in @alice's expertise area; want to wait for her input?" — composes with team-tracking infrastructure

## Effort

Two sizings:

- **Lean (~20-25 SP)**: single-user only (Capabilities 1+2)
- **Full (~35-45 SP)**: single-user + multi-user routing (all three Capabilities)

Recommended split: lean version in Phase 2 + full version after Multi-Developer Reconciliation (Phase 5).

## Phase placement

Phase 2 (lean) — adaptive thresholds and gate strictness ship independently of multi-developer infrastructure. Phase 5-adjacent (full) — routing capability composes with Multi-Developer Reconciliation.

## Open questions

1. Bootstrap questionnaire size — 5 max?
2. Continuous numeric expertise vs discrete bands?
3. When does inference override declared expertise?
4. Which gates NEVER relax (safety-critical enumeration)?
5. Per-user vs per-project profile?
6. Storage location — `.specrew/user-profile.yml`?
7. Public-flip implications for external contributors?
8. Strict-mode override mechanism?

## Risks

- **Calibration risk**: incorrect expertise assessment → incorrect gate relaxation → safety hole. Mitigation: never relax safety-critical gates; require explicit user confirmation per relaxation.
- **Sycophancy drift**: dynamically adjusting to "what user expects" can drift from quality bar. Mitigation: relaxed gates produce advisory notes that compound; if they accumulate, surface.
- **Privacy / ethics**: tracking user behavior to infer expertise needs careful handling. Mitigation: explicit consent at bootstrap; signals captured locally; no external transmission without authorization.

## Cross-references

- Composes with: Proposal 010 (Multi-Developer Reconciliation) — Capability 3 depends on team-tracking
- Composes with: Proposal 007 (Substantive Interaction Model) — Capability 1 adapts F-016 thresholds
- Composes with: Proposal 008 (NFR Governance) — Tier-3 questions adapt to expertise
- Composes with: Proposal 014 (Red Team Agent) — Red Team flags expertise-mismatch decisions

## Status history

- 2026-05-15: candidate captured during Feature 016 Iter 2 in-flight discussion

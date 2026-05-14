---
proposal: 008
title: Non-Functional Requirement Governance
status: draft
phase: phase-2
estimated-sp: 28
discussion: tbd
---

# Non-Functional Requirement Governance

## Why

Specrew today governs the **lifecycle** of work — spec authority, traceability, drift, ceremonies, approvals. It does not govern the **quality attributes** of the system being built. The Specrew constitution has 27 principles; none mention cohesion, coupling, observability, error handling, security baseline, or any other NFR / cross-cutting concern.

Specrew plays the architect's role for projects that may have no architect. If Specrew does not surface NFRs, no one will. But Specrew also runs on diverse stacks and domains and must not dictate architecture.

The resolution is the pattern Specrew already adopted (2026-05-13) for schema validation: **category-level mandate + stack-aware catalog + human approval at clarify time + validator enforcement of the category, not the specific tool**. That pattern has one entry today (schema validation at untrusted boundaries). This proposal extends it to the full NFR surface.

The pattern: surface → default → accept override.

## What

A three-tier NFR governance model baked into Specrew's lifecycle:

**Tier 1 — Universal baselines** (Reviewer-enforced regardless of stack). Six categories:
- `schema-validation-at-boundaries` (seed entry, already adopted 2026-05-13)
- `structured-logging`
- `no-silent-failure-error-handling`
- `secrets-externalized`
- `cohesion-coupling-discipline`
- `automated-build-and-test-gates`

**Tier 2 — Conditional baselines** (surfaced at clarify time based on spec characteristics). Six categories:
- `distributed-tracing-opentelemetry` (triggers: ≥2 services, async messaging, service mesh)
- `authn-authz-baseline` (triggers: user/principal/session/auth/token mentions)
- `pii-handling` (triggers: email/name/phone/address/payment in data model)
- `health-readiness-endpoints` (triggers: long-running service description)
- `retry-idempotency-compensation` (triggers: cross-boundary mutating operations)
- `deployment-readiness` (triggers: production-bound spec characteristics)

**Tier 3 — Architect's must-ask questions** (required clarify-time questionnaire; `unspecified` is a valid answer). Six categories:
- `hosting-model` (enum from cheat-sheet)
- `scalability-target`
- `availability-target`
- `performance-budget`
- `cost-ceiling`
- `release-strategy`

A canonical NFR catalog at `.specify/extensions/specrew-speckit/quality/nfr-catalog.yml` defines categories, tiers, trigger conditions, stack-aware example tools. A per-project NFR record at `.specrew/quality/non-functional-requirements.yml` captures user answers and acknowledgments. The Reviewer skill family (`nfr-baseline-review` + per-category skills) checks Tier 1 baselines during review.

Multi-stack support: stacks declared as a list; common Tier-1 principles apply across stacks, stack-specific tooling examples per stack.

Unified clarify-time decision ledger: all clarify-time NFR decisions flow to `.squad/decisions.md` (canonical) with `.specrew/quality/non-functional-requirements.yml` as a projection view. Future governance aspects plug into the same ledger.

Post-feature self-application: after this feature ships, Specrew's own constitution gets refreshed with Tier-1 baselines as a closeout dogfooding step.

## Effort

- **Iteration 1 (~13 SP)**: Catalog YAML + schema + Tier-1 baseline skill (including `automated-build-and-test-gates`) + constitution seeding + validator soft-warning
- **Iteration 2 (~15-16 SP)**: Tier-2 trigger detection + Tier-3 questionnaire + clarify-step integration + unified ledger integration + multi-stack catalog handling + Specrew self-application closeout
- **Total**: ~28-29 SP

## Phase placement

Phase 2 — after the queued quality-lift trilogy (source-spec fidelity contract, spec-scenario integration test mandate, boundary validation tier). NFR Governance absorbs/retires Boundary Validation Tier (~15 SP saved by merging).

## Open questions

1. Bootstrap questionnaire size: 5 max at `specrew-init` (general seniority + 2 per-technology + 2 per-domain)?
2. Expertise bands continuous (years) vs discrete (novice/competent/expert)?
3. When does inference override declared expertise? Recommended: never silently — surface discrepancies.
4. Which gates NEVER relax regardless of expertise? Safety-critical enumeration required.
5. Per-user vs per-project profile?
6. Storage location: `.specrew/user-profile.yml`?
7. Public-flip implications for external contributors?
8. Override mechanism for forced "strict mode"?
9. Capability-3 routing trust (timeout / escalation when assigned expert unavailable)?

## Risks

- **Stack-aware tool selection complexity**: each (category, stack) pair requires curated tooling examples. Mitigation: start with 6 primary stacks (dotnet, node, python, java, go, rust); extend as needed.
- **Trigger regex false positives/negatives**: Tier-2 patterns are mechanical. Mitigation: soft-warning level absorbs imperfect detection; user can decline triggered categories with reason.
- **Constitution edit-log overhead**: every override creates an audit row. Mitigation: keep edit log lightweight; lean on git history for full audit trail.
- **Multi-stack catalog complexity**: common vs stack-specific separation adds catalog dimensions. Mitigation: catalog explicitly separates common principles from stack-specific examples.

## Cross-references

- Composes with: Proposal 008 (Source-Spec Fidelity Contract), Proposal 020 (Spec-Scenario Integration Tests), Proposal 014 (Red Team Agent)
- Replaces: queued Boundary Validation Tier (absorbed)
- Stack-aware pattern: `feedback_stack_aware_tool_selection.md`-equivalent guidance
- Reference: Alon Fliess, "Architecting Scalable Solutions" (2025), chapters 2/5/6

## Status history

- 2026-05-14: candidate captured following review of book chapters 2/5/6 and reflection on Specrew's NFR gap
- 2026-05-14: status → draft; source spec drafted with three-tier model
- 2026-05-14: refinement — multi-stack promoted from deferred to V1; Specrew self-application added as closeout step; unified clarify-time decision ledger introduced
- 2026-05-14: refinement — DevOps family added across all three tiers; skill-authoring worked examples added for `cohesion-coupling-discipline` and `automated-build-and-test-gates`

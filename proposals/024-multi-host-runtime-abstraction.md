---
proposal: 024
title: Multi-Host Runtime Abstraction (Serial — Scenario A)
status: candidate
phase: phase-4-or-5
estimated-sp: 65
discussion: tbd
---

# Multi-Host Runtime Abstraction (Serial)

## Why

Specrew today runs on GitHub Copilot CLI as the primary host. Squad is the orchestration runtime that drives the lifecycle. The methodology itself is theoretically host-neutral — the governance, lifecycle boundaries, validator rules don't depend on which AI host executes them.

But the implementation is currently coupled to Copilot CLI's agent definitions and Squad's specific orchestration patterns. This coupling has two real costs:

1. **Throttling vulnerability**: continuous Specrew development on a single host (Copilot) can trigger that host's rate limits, blocking work
2. **Team-adoption blocker**: real development teams have heterogeneous AI tool preferences — some devs use Copilot, others Claude Code, others Codex, others local models. Standardizing a team on ONE AI host is unrealistic. Without host heterogeneity, team adoption is structurally limited.

This proposal abstracts the host-runtime layer so Specrew becomes a methodology that **any** AI host can implement, AND each developer on a team can use their preferred host while Specrew's governance + multi-developer reconciliation handle coordination.

## What

A host-neutral governance layer above multiple AI runtimes:

1. **Canonical state** at `.specrew/*` — host-neutral truth surface (decisions, config, governance, validator rules)
2. **Provider projection** — each AI host (Copilot, Claude Code, Codex, CAO, etc.) projects the canonical state into its own format
3. **Per-host adapter layer** — host-specific files (`.github/agents/`, `.claude/agents/`, etc.) are generated from canonical state, not hand-edited
4. **Pragmatic first non-Squad provider**: CAO (Claude's agent orchestrator) as proof-of-concept — demonstrates the abstraction works

## Effort

- **Core (M0-M2)**: ~65 SP
- **Full (M0-M5 with all major hosts)**: ~125 SP

Phased delivery:
- M0: canonical state + Copilot projection (existing as baseline)
- M1: CAO projection (first non-Squad provider)
- M2: validator + governance host-neutrality
- M3-M5: additional providers (Codex, custom)

## Phase placement

**Phase 4 OR early Phase 5 — prerequisite for genuine team adoption.**

Previous framing was Phase 6 "conditional on non-Copilot demand." Re-framing 2026-05-15: real dev teams have heterogeneous AI tool preferences. Team adoption (Phase 5's stated goal in the consolidated plan) requires Multi-Host Runtime as a prerequisite, NOT a conditional follow-up. The "non-Copilot demand" trigger fires the moment Specrew has team users.

Sequencing implication: Multi-Host Serial ships BEFORE Multi-Developer Reconciliation, because the canonical-state abstraction in `.specrew/*` is the foundation that Multi-Developer Reconciliation builds on.

## Scenario A vs Scenario B

This proposal covers **Scenario A** specifically: serial, switchable single-active host. One host runs at a time; switch hosts when needed (e.g., when Copilot throttles, switch to Claude Code). Canonical state in `.specrew/*` enables seamless resume on the new host.

**Scenario B** (concurrent multi-host — one developer driving 3 hosts on 3 features simultaneously) is a separate, more ambitious capability that combines Multi-Host + Multi-Developer Reconciliation + concurrent-orchestration UI. ~150-200 SP combined effort. Deferred to a separate future feature ("Concurrent Multi-Host Orchestration"). Captured for future analysis; NOT in scope for this proposal.

For team adoption, Scenario A is sufficient. Each developer uses their preferred host; coordination happens at PR boundary via Multi-Developer Reconciliation.

## Open questions

1. Canonical state schema — how host-neutral can it be?
2. Provider projection — code-generated or schema-driven?
3. Per-host capability differences — how to handle (e.g., Codex doesn't have skills)?
4. Adapter testing — how to validate projections across hosts?
5. Demand signal — what triggers the M0-M2 build?

## Risks

- **Premature abstraction**: building for hosts no one uses. Mitigation: defer until non-Copilot demand exists.
- **Lowest-common-denominator design**: forcing all hosts into a uniform shape loses host-specific power. Mitigation: canonical state is INTENT; host-specific features can extend per-host.
- **Maintenance burden**: every host adapter must keep up with methodology evolution. Mitigation: schema-driven projections minimize per-host code.

## Cross-references

- Composes with: Proposal 010 (Multi-Developer Reconciliation) — this proposal is now framed as a Phase 5 prerequisite; team-adoption scenario depends on both
- Composes with: Proposal 026 (Refactor Track) — R5 coordinator-prompt modularization composes with this work
- Future complement: Concurrent Multi-Host Orchestration (Scenario B) — not yet a proposal; queued for analysis after Scenario A ships

## Status history

- 2026-05-12: candidate captured during host-coupling discussion
- 2026-05-13: Phase 6 placement (conditional on non-Copilot demand)
- 2026-05-15: re-framing after empirical Copilot-throttling experience + team-adoption analysis. Phase placement promoted from Phase 6 conditional to Phase 4-or-5 prerequisite. Scenario A (serial) vs Scenario B (concurrent) distinction made explicit; Scenario B split to separate future-feature candidate. Further analysis pending before spec drafting.

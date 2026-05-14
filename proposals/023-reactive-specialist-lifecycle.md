---
proposal: 023
title: Reactive Specialist Lifecycle Management
status: candidate
phase: phase-2
estimated-sp: 22
discussion: tbd
---

# Reactive Specialist Lifecycle Management

## Why

Feature 004 was originally drafted as proactive Junior/Senior pairing — adding a paired specialist agent at planning time. ClipBoard6 dogfooding on 2026-05-13 revealed an alternative pattern working in practice: REACTIVE specialist pairing, where a specialist agent is added mid-iteration when the primary agent gets locked out (e.g., Implementer hit a problem; Tank was added dynamically to assist).

The reactive pattern fits dogfooded reality better than the proactive pattern. This proposal reframes Feature 004 from proactive to reactive.

## What

A formalized reactive specialist lifecycle:

1. **Lockout detection**: when primary agent (Implementer / Reviewer / etc.) accumulates N failures or stuck states, the lockout state activates
2. **Specialist routing**: based on the failure pattern, a specialist agent type is selected (Tank for resilience issues, Worf for security issues, etc.)
3. **Dynamic team expansion**: the specialist joins the team mid-iteration via `.squad/team.md` update + routing
4. **Specialist handoff**: primary agent's state is captured; specialist takes over with full context
5. **Reactive return**: when the issue resolves, primary agent resumes; specialist's contribution recorded in iteration artifacts

Composes with existing reviewer-regression-event escalation pattern, extending it to a broader specialist-routing surface.

## Effort

~20-25 SP across 2 iterations.

- **Iteration 1**: Lockout detection + specialist routing logic + team-expansion mechanism
- **Iteration 2**: Specialist agent definitions (Tank for resilience, Worf for security, others as needed) + integration tests

## Phase placement

Phase 2 — slot 2.3 (after graduation candidates, before iteration-011 cleanup).

## Open questions

1. Lockout threshold — N failures? Stuck-state heuristic?
2. Specialist taxonomy — which specialist types ship initially?
3. Specialist permanence — once added, do specialists stay on the team for the iteration or rotate out?
4. Routing logic — pattern-matched (failure type → specialist) or LLM-decided?
5. Handoff format — what state does the primary pass to the specialist?

## Risks

- **Specialist proliferation**: too many specialist types becomes hard to maintain. Mitigation: start with 2-3 specialist types; expand as patterns emerge.
- **Lockout false positives**: legitimate slow progress flagged as lockout. Mitigation: thresholds tunable; user can override.
- **Coordination overhead**: dynamic team expansion adds coordinator-prompt complexity. Mitigation: routing decisions logged in decisions.md for audit.

## Cross-references

- Reframes: original Feature 004 spec (proactive pairing) → reactive pairing
- Composes with: Proposal 015 (Expertise-Aware Adaptive Interaction) — Capability 3 routing
- Justified by: ClipBoard6 dogfooding observation

## Status history

- 2026-05-13: candidate captured following ClipBoard6 dogfooding evidence
- 2026-05-13: Option A reframing confirmed by user (proactive → reactive)

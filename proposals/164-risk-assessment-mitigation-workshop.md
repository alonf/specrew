---
proposal: 164
title: Risk Assessment & Mitigation in the Design Workshop (per-lens capture + consolidated register) — RESEARCH-NEEDED
status: candidate
phase: phase-2
estimated-sp: 6-10 (research-dependent; see Research Needed)
priority-tier: 2
discussion: surfaced 2026-06-05 by the maintainer during the testLenses8/11 cross-host workshop dogfooding, alongside Proposal 163. Risk + mitigation is already touched in two disconnected places (per-lens, and the before-implement hardening gate) but is not a single holistic, prioritized thread. Whether it is per-lens, consolidated-after-all, or hybrid — and how it hands off to the hardening gate — is research-needed before spec conversion.
---

# Risk Assessment & Mitigation in the Design Workshop

## Why

Risk is not absent from Specrew today — it is **touched in two disconnected places**, with no holistic,
prioritized thread between them:

- **Per-lens, implicitly:** security-compliance surfaces threats / attack surface, requirements-nfr surfaces
  quality risks, observability-resilience surfaces failure modes, and the design-analysis options each carry a
  *reversibility cost* + trade-offs.
- **At before-implement, explicitly:** the **hardening gate** is already a risk register — its 5 canonical
  concerns (security-surface, error-handling, retry/idempotency, test-integrity, operational-resilience) pair a
  risk category with expected **controls** (mitigations).

What is missing is a **design-time, prioritized risk-and-mitigation pass**: collect the risks surfaced across
the lenses, add the cross-cutting risks no single lens owns, rank them, and decide mitigate / accept / defer
with an owner — before they reach the hardening gate.

## What (provisional — pending research): a hybrid

The proven pattern is **both**, not either:

- **Capture per-lens, in context** — a risk is most visible where it arises (the integration lens sees the
  cloud-timeout risk; data sees the buffer-leak risk). Capturing only at the end loses half of them.
- **Consolidate + prioritize after all lenses** — one pass that collects the per-lens risks, adds **cross-cutting
  risks** no single lens owns, ranks them (likelihood × impact), and records mitigate / accept / defer + owner:
  a real risk register that **seeds the hardening gate** rather than competing with it.

Pure per-lens misses the cross-cutting risks and the prioritization; pure after-all loses the in-context
capture. Hybrid keeps both.

## The central question: per-lens vs. after-all vs. hybrid — and the hardening-gate handoff

This decides the shape and is **not settled here**:

- The capture/consolidate split above (hybrid recommended, but validate).
- **How the design-time risk register relates to the before-implement hardening gate** — which is *already* a
  risk-concern register with controls. The design register must **precede and feed** the gate (one continuous
  risk thread), not duplicate it one phase later. Getting this boundary right is the crux.

## Research Needed (before spec conversion) — maintainer-flagged

**The scope and placement are deliberately not decided here.** Convert to a spec only after:

1. **Per-lens vs. after-all vs. hybrid** — validate the hybrid (capture in-context + consolidate/prioritize),
   and decide whether the consolidated pass is a workshop **step**, a dedicated **risk lens**, or a cross-cutting
   pass at the design-analysis stop.
2. **The design-register → hardening-gate handoff** — how the design-time register maps onto / seeds the 5
   hardening concerns + controls without duplication; whether they become one artifact across phases.
3. **The register schema** — likelihood / impact / category / mitigation / accept-defer / owner — and how much
   is deterministic-floor-able vs. behavioral (the SC-021/SC-025 precedent: presence-floor + dogfood).
4. **Interaction with the per-lens conduct** and the design-analysis options' existing reversibility/trade-off
   capture (reuse, don't reinvent).
5. **Avoiding risk-theater** — a register no one acts on is worse than none; the research must tie each recorded
   risk to a downstream consequence (a hardening control, a test, a deferral decision).

## Composition map

- **The hardening gate (Feature 141)** — the before-implement 5-concern register is the downstream counterpart;
  164 designs the design-time register that feeds it.
- [[145-structured-multi-phase-reviewer]] — the reviewer verifies mitigations landed; the register gives it the
  risk list to check against.
- [[163-code-implementation-lens]] — sibling new-dimension proposal from the same dogfooding; both are
  research-gated workshop additions filed behind Feature 141.
- The security-compliance / requirements-nfr / observability-resilience lenses — the per-lens risk sources.
- The design-analysis options' reversibility / trade-off capture — the existing risk-ish surface to reuse.

## Sizing

~6-10 SP, research-dependent: per-lens risk capture (small, mostly conduct in the existing lenses) + the
consolidated register step/lens + the hardening-gate handoff. An "enforced" register (a deterministic
presence-floor + the gate handoff) is the upper end; a record-only design register is the lower.

## Open questions

- Per-lens vs. after-all vs. hybrid (the central one).
- A workshop step, a dedicated risk lens, or a cross-cutting pass at design-analysis?
- One risk artifact spanning design → hardening, or two with a defined handoff?
- Prioritization method (likelihood × impact qualitative bands vs. a score).
- Does it gate a boundary, or stay advisory until the hardening gate?

## Risks

- **Duplicating the hardening gate** — the boundary must be designed, not improvised, or 164 just re-does the
  before-implement concern register one phase earlier.
- **Risk-theater** — a register that records risks but drives no mitigation/test/deferral; each risk must tie to
  a downstream consequence.
- **Overlap with the security / nfr / observability lenses** — needs a clear "those lenses *surface* risks; this
  *consolidates + prioritizes + mitigates* them" split.

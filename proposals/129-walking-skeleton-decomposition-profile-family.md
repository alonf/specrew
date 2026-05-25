---
proposal: 129
title: Walking-Skeleton + Decomposition Profile Family (walking-skeleton-vertical-slices / layered-bottom-up / microservices-first / data-model-first / idesign-method)
status: candidate
phase: phase-2
estimated-sp: 20-35 (bundled 3-5 profiles) — could ship walking-skeleton-vertical-slices + layered-bottom-up first (~10-16 SP) and the rest as follow-ups
priority-tier: 3
discussion: companion to Proposal 128 (clarify-phase question); ships the actual profile contents under Proposal 052 mechanism; surfaced 2026-05-26 PlanningPoC dogfooding
---

# Walking-Skeleton + Decomposition Profile Family

## Why

Proposal 128 adds the clarify-phase question "How do you prefer to decompose this work across iterations?" That question is useless without **profile contents** behind each option — the actual Planner-charter directives, Implementer-charter directives, iteration templates, and validator rules that shape behavior when a strategy is selected.

This proposal ships the profile family under [[proposal-052]]'s (Specrew Profile System) extensibility mechanism. Each profile is a focused bundle of charter directives + templates + validator rules that activate when its strategy is selected.

Without this proposal, Proposal 128's question fires but options 1-4 have no behavior — only option 5 ("Spec-driven default") works (the current default).

## What

Profile family — 5 profiles in the initial catalog. Bundle 2 initially (walking-skeleton + layered-bottom-up); ship the others as follow-up slices when there's appetite.

### Profile 1: `walking-skeleton-vertical-slices` (~5-8 SP — SHIP FIRST)

**Bundle contents**:

- **Planner-charter directive injection**: *"Favor vertical slices over horizontal layers. iter-001 MUST include at least one task touching each declared architectural layer (UI, API, BL, persistence, infrastructure) on the thinnest end-to-end happy-path. iter-002+ implements one feature at a time as full vertical slices."*
- **Implementer-charter directive injection**: *"When ordering tasks within an iteration, prefer thinnest-end-to-end-path before depth. Do not finish all backend layers before starting the UI."*
- **Reviewer-charter directive injection**: *"At iter-001 review, verify the iteration spans all declared architectural layers. Reject iter-001 if it skips any declared layer (e.g., backend-only iter-001 in a project that declared UI)."*
- **iter-001 plan template**: scaffolds with explicit per-layer task slots (UI: TBD, API: TBD, BL: TBD, persistence: TBD, infrastructure: TBD); planner fills with concrete tasks during plan boundary
- **Validator rule** (soft WARN): `iter-001 lacks task touching declared layer X` when the project has activated this profile and an architectural layer has no associated task
- **Documentation**: `docs/profiles/walking-skeleton-vertical-slices.md` explaining the pattern, citing Cockburn Crystal + Bogard + Pragmatic Programmer

### Profile 2: `layered-bottom-up` (~3-5 SP — SHIP SECOND)

The explicit version of today's default. Useful for ML / data-platform / infrastructure projects where bottom-up genuinely makes sense.

**Bundle contents**:

- **Planner-charter directive injection**: *"Order iterations by architectural layer: foundation/repositories iter-001, engines/managers iter-002, API iter-003, UI iter-004. Each iteration ships its layer fully before next layer begins."*
- **Iteration template**: explicit layer-per-iteration scaffolding
- **Validator rule** (soft INFO, not WARN): `iter-N is implementing layer X; previous layer Y status: Z` — surfaces layer progression for reviewer visibility
- **Documentation**: `docs/profiles/layered-bottom-up.md`

### Profile 3: `microservices-first` (~5-8 SP — FOLLOW-UP SLICE)

Independent deployable units; per-service vertical slices; service registry / discovery / contracts as foundation work.

**Bundle contents**:

- Planner-charter directive: *"Decompose by service boundary first. iter-001 ships the service registry + contracts; iter-002+ implements one service per iteration as a full vertical slice."*
- Service-contract scaffolding
- Validator rule checking that each iteration's tasks fall within one service boundary

### Profile 4: `data-model-first` (~3-5 SP — FOLLOW-UP SLICE)

Schema and migrations first, then layers up.

**Bundle contents**:

- Planner-charter directive: *"iter-001 = data model + migrations + repository contracts. iter-002+ implements features that use the model."*
- DB-migration discipline templates
- Validator rule checking that iter-001 has migration tasks

### Profile 5: `idesign-method` (~5-8 SP — FOLLOW-UP SLICE, requires research)

Lowy IDesign / "The Method" — volatility-based decomposition + architecture-first discipline.

**Bundle contents**:

- Planner-charter directive citing volatility decomposition principles
- Pre-spec architecture phase template
- Volatility-map scaffolding

This profile requires more research before drafting (Lowy's method is complex and may not map cleanly to Specrew's lifecycle). Mark as candidate-deferred until comparative-research phase from Proposal 128's memory is done.

## How

Bundled 2-profile initial shipment + 3-profile follow-ups.

### Initial bundle (~10-16 SP)

| Step | File | Effort |
|---|---|---|
| `walking-skeleton-vertical-slices` profile contents | `extensions/specrew-speckit/profiles/walking-skeleton-vertical-slices/` (charter directives + templates + validator rules) | 5-8 SP |
| `layered-bottom-up` profile contents | `extensions/specrew-speckit/profiles/layered-bottom-up/` | 3-5 SP |
| Profile mechanism integration with Proposal 052 | depends on 052 shipping | 2-3 SP |
| Documentation | `docs/profiles/walking-skeleton-vertical-slices.md`, `docs/profiles/layered-bottom-up.md` | 1-2 SP |
| Integration tests | `tests/integration/walking-skeleton-profile.tests.ps1` (new) | 1-2 SP |

### Follow-up slices (~10-19 SP total)

- `microservices-first` profile: ~5-8 SP
- `data-model-first` profile: ~3-5 SP
- `idesign-method` profile: ~5-8 SP (after research)

## Acceptance criteria

- **AC1**: After Proposal 052 ships, activating `walking-skeleton-vertical-slices` profile via `specrew config` injects the Planner / Implementer / Reviewer charter directives
- **AC2**: A project with this profile activated produces iter-001 plans where at least one task touches each declared architectural layer
- **AC3**: Validator emits WARN if iter-001 skips a declared layer when this profile is active
- **AC4**: Activating `layered-bottom-up` profile produces explicit layer-per-iteration plans
- **AC5**: Switching profiles mid-feature triggers a deliberate warning + audit-trail entry (don't silently change behavior)
- **AC6**: Documentation accurately describes when to choose each profile + the trade-offs (citations to Cockburn / Bogard / Hunt-Thomas / Lowy)
- **AC7**: Profile activation is recorded in `.specrew/config.yml` + audit-trail entry in `.squad/decisions.md`

## Out of scope

- **The clarify-phase question** — Proposal 128 owns that
- **Forcing profile change on existing iterations** — profile applies forward; existing iterations grandfathered
- **Profile composition** (e.g., walking-skeleton + DDD) — DDD/CQRS/Clean-Architecture are orthogonal; this proposal only ships decomposition profiles, not architectural-style profiles. Composition with architecture-style profiles is a separate follow-up
- **AI-detected automatic profile selection** — explicit user choice via Proposal 128's question; no inference

## Composition

- **Proposal 052 (Specrew Profile System)** — direct dependency; profile mechanism is 052's
- **Proposal 128 (Decomposition-Strategy Clarify Question)** — companion; 128 asks, 129 ships
- **Proposal 063 (Substantive Intake Questioning)** — composes via 128 question
- **Proposal 047 (Project Governance Profile)** — adjacent profile-system work
- **Proposal 096 (Proposal-Driven-Design Profile)** — sibling profile pattern; same architectural family

## Risks

- **Profile mechanism dependency on Proposal 052** — if 052 doesn't ship soon, fallback is installed-template/charter-directive override (less elegant but works). Mitigation: ship walking-skeleton profile via charter override first; migrate to 052 profile mechanism when 052 lands
- **Over-prescription of walking-skeleton pattern** — some projects don't benefit (pure data-pipeline / infrastructure). Mitigation: profile is opt-in; layered-bottom-up is the explicit alternative
- **Charter-directive injection conflicts** — multiple active profiles might inject conflicting directives. Mitigation: profile compatibility matrix + activation-time conflict detection
- **Validator rule false positives** — declared-layer enumeration may be ambiguous. Mitigation: WARN-only initially; promote to FAIL after observed practice
- **idesign-method profile requires research** — Lowy's method is complex. Mitigation: explicitly mark as candidate-deferred; ship the four simpler profiles first

## Empirical motivation

2026-05-26 PlanningPoC dogfooding observed AI agents defaulting to bottom-up layered work even when the architect (Alon) prefers Walking Skeleton + Vertical Slices. Memory `[[decomposition-strategy-and-walking-skeleton-profile-2026-05-26]]` captured the gap analysis + industry-context survey (Cockburn / Bogard / Hunt-Thomas / Lowy / SAFe Architectural Runway / Lean) + sequencing decision.

PlanningPoC iter-001 specifically demonstrated the default: 23 tasks across persistence/engines/manager/architecture-tests, with frontend appearing only as React/Vite "runway" scaffolding — no vertical slice through to a working UI surface.

## Cross-references

- file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md
- file:///C:/Dev/Specrew/proposals/128-decomposition-strategy-clarify-question.md (companion)
- file:///C:/Dev/Specrew/proposals/063-substantive-intake-questioning.md
- file:///C:/Dev/Specrew/proposals/047-project-governance-profile.md
- file:///C:/Dev/Specrew/proposals/096-proposal-driven-design-profile.md
- Memory: [[decomposition-strategy-and-walking-skeleton-profile-2026-05-26]]
- Cockburn Crystal Methodology (Walking Skeleton)
- Jimmy Bogard "Vertical Slice Architecture" series
- Hunt + Thomas, *The Pragmatic Programmer* (Tracer Bullet Development)
- Juval Lowy, *Righting Software* (IDesign Method)

## Status history

- 2026-05-26: candidate proposal drafted as part of memory→proposal sweep. Scoped initial bundle (walking-skeleton + layered-bottom-up) as 10-16 SP; 3 follow-up profiles as separate slices when appetite arrives. Companion to Proposal 128's clarify-phase question.

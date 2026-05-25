---
proposal: 128
title: Decomposition-Strategy Clarify-Phase Question (Walking Skeleton vs Layered Bottom-Up vs Microservices First etc.)
status: candidate
phase: phase-2
estimated-sp: 3-5
priority-tier: 3
discussion: surfaced 2026-05-26 during PlanningPoC iter-001 review; AI agents default to bottom-up layered work; architect-preference for Walking Skeleton + Vertical Slices not asked anywhere; composes with Proposal 063 Substantive Intake Questioning
---

# Decomposition-Strategy Clarify-Phase Question

## Why

Specrew's clarify-phase substantive intake (Proposal 063) covers 12 categories: problem, users, security, scale, hosting, framework, architecture, NFRs, budget, MVP, stack, research. **It does not currently ask about decomposition strategy.**

The result, observed during 2026-05-26 PlanningPoC iter-001 dogfooding: AI agents (across Squad/Specrew + Claude + Antigravity + Copilot — all hosts) **default to bottom-up layered work**. Foundation → engine → API → UI. PlanningPoC iter-001 produced 23 tasks across persistence/engines/manager/architecture-tests, with the frontend appearing only as React/Vite "runway" scaffolding — no vertical slice through to a working UI surface.

Causes of the default:

- AI training-data bias (textbook examples are layered)
- Spec-Kit's `/speckit.tasks` ordering by dependency (safest = leaf-first)
- No explicit Specrew directive to prefer vertical slices over horizontal layers

The contrast is the architect-style **Walking Skeleton + Tracer Bullets** pattern (well-known industry naming — Cockburn Crystal / Bogard Vertical Slice / Hunt-Thomas Pragmatic Programmer):

1. Foundation sprints first — solution skeleton, technology choices, DevOps, crosscutting concerns
2. Then ONE feature implemented as a complete vertical slice — UI, API Gateway, BL, DB — to validate architecture end-to-end
3. Then feature-by-feature E2E — each iteration ships UI + back + DB + tests + deployment for one feature

Empirical value: integration surprises surface in sprint 1 instead of sprint 5; demoable from week 2; "we have backend done but no UI" antipattern is structurally prevented.

Architects with strong decomposition preferences have no sanctioned Specrew hook to inject those preferences. Every iteration requires manual override of the AI default.

## What

Add one category-level question to Proposal 063's clarify-phase intake (12 → 13 categories):

**Category: Decomposition Strategy** — "How do you prefer to decompose this work across iterations?"

| Option | Description | Profile activated (per Proposal 052 + 129) |
|---|---|---|
| 1. Walking Skeleton | Thin end-to-end through all layers first, then feature-by-feature E2E | `walking-skeleton-vertical-slices` |
| 2. Layered bottom-up | Foundation/engines/repositories first, then API/manager, then UI | `layered-bottom-up` |
| 3. Microservices/services-first | Independent deployable units; per-service vertical slices | `microservices-first` |
| 4. Data-model-first | Schema + migrations first, then layers up | `data-model-first` |
| 5. Spec-driven default | Whatever the AI naturally produces (current default behavior) | (no profile activation) |
| 6. Other (describe) | Free-text alternative; routes to Architect persona for follow-up | (per-project ad-hoc) |

The answer drives active profile selection. Default is option 5 ("Spec-driven default") so light projects don't get burdened. Substantive projects (Mode B/C per Proposal 063's adaptive depth) get the question; trivial projects (Mode A) skip it.

This composes with [[proposal-063]]'s adaptive-questioning architecture and [[proposal-052]]'s profile system + [[proposal-129]]'s actual profile contents.

## How

| Step | File | Effort |
|---|---|---|
| Add Decomposition Strategy category to Proposal 063's intake catalog | Proposal 063 source spec at `file:///C:/Dev/SpecrewDraft/substantive-intake-questioning.md` | 1 SP |
| Update intake-routing logic to fire Decomposition question in Mode B + C | (depends on 063 implementation; this proposal contributes the question definition) | 1 SP |
| Default-answer recommendation logic — if option 5 selected, no profile activated; if 1-4, activate corresponding profile via Proposal 052 mechanism | (depends on 052 implementation) | 1 SP |
| Documentation | docs/user-guide.md substantive-intake section | 0.5 SP |
| Tests covering Mode A skip + Mode B/C fire + per-option profile activation | tests/integration/decomposition-strategy-intake.tests.ps1 (new) | 1 SP |

Total ~3-5 SP. Phase 2 small follow-up to Proposal 063.

## Acceptance criteria

- **AC1**: Substantive intake (Proposal 063) in Mode B/C asks the Decomposition Strategy question after the architecture / NFR categories
- **AC2**: Mode A (trivial projects) skips the question
- **AC3**: Selecting option 1 ("Walking Skeleton") activates the `walking-skeleton-vertical-slices` profile from Proposal 129 (if available)
- **AC4**: Selecting option 5 ("Spec-driven default") activates no profile — current default behavior preserved
- **AC5**: The answer is recorded in `.specrew/intake-decisions.yml` (or equivalent per Proposal 063) for audit trail
- **AC6**: "Other (describe)" routes to Architect persona for follow-up question; answer stored as free-text profile note

## Out of scope

- **Profile content** — that's Proposal 129's scope; this proposal contributes only the question + activation routing
- **Forcing decomposition strategy on existing iterations** — applies at intake; existing iterations grandfathered
- **Cross-iteration strategy change** — if user wants to switch strategies mid-feature, that's an explicit user direction (not auto-handled by this question)
- **Validator enforcement of activated profile** — Proposal 129's validator rules handle that; this proposal handles question + activation

## Composition

- **Proposal 063 (Substantive Intake Questioning)** — direct dependency; this proposal extends 063's catalog
- **Proposal 052 (Specrew Profile System)** — direct dependency; activation routes through 052's mechanism
- **Proposal 129 (Walking Skeleton + Decomposition Profile Family)** — companion proposal; 128 asks the question, 129 ships the profile contents
- **Proposal 047 (Project Governance Profile)** — adjacent; both add init/clarify-time configurable behavior
- **Memory `[[feedback-stack-aware-tool-selection]]`** — analogous pattern (category-level question + per-project answer drives selection)

## Risks

- **Question burden in Mode B** — adding more questions may make intake feel heavy. Mitigation: question only fires in Mode B/C; defaults make most projects skip
- **Default selection bias** — if option 5 is default, architects who'd benefit from explicit choice may not notice the question. Mitigation: documentation + first-run education
- **Profile dependency** — until Proposal 129 ships profile contents, options 1-4 have no behavior. Mitigation: ship 128 + at least one profile from 129 together; document the rest as "coming soon"
- **Dependence on 063 implementation timing** — if 063 doesn't ship soon, this proposal stalls. Mitigation: fallback path is one-line coordinator-prompt addition (less elegant but works without 063)

## Empirical motivation

2026-05-26 PlanningPoC dogfooding observation. Alon's natural architect workflow (Walking Skeleton + Tracer Bullets) didn't surface anywhere in the clarify phase; iter-001 defaulted to 23-task layered bottom-up without checking preference. Memory captured at `[[decomposition-strategy-and-walking-skeleton-profile-2026-05-26]]` with industry-context survey of Cockburn Crystal / Bogard Vertical Slice / Hunt-Thomas Tracer Bullet / Outside-In TDD / MVP-first patterns.

## Cross-references

- file:///C:/Dev/Specrew/proposals/063-substantive-intake-questioning.md
- file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md
- file:///C:/Dev/Specrew/proposals/047-project-governance-profile.md
- file:///C:/Dev/Specrew/proposals/129-walking-skeleton-decomposition-profile-family.md (companion)
- Memory: [[decomposition-strategy-and-walking-skeleton-profile-2026-05-26]]

## Status history

- 2026-05-26: candidate proposal drafted as part of memory→proposal sweep. Scope kept tight (~3-5 SP) as a question-catalog addition to Proposal 063. Profile contents pushed to companion proposal 129.

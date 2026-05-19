---
proposal: 026
title: Refactor Track Features (R1-R5)
status: candidate
phase: phase-3
estimated-sp: 110
discussion: tbd
---

# Refactor Track Features (R1-R5)

## Why

Specrew's core scripts have accumulated mass:

- `specrew-start.ps1`: 2,605 lines
- `specrew-init.ps1`: 1,784 lines
- `validate-governance.ps1`: 2,867 lines
- 0 Pester tests

Every new feature touches these monoliths. The maintainability cliff is approaching. Plus the coordinator-prompt is growing past 1,000 lines as features add new rules.

This proposal queues five refactor features (R1-R5) that modularize the monoliths into testable components.

## What

Five interconnected refactor features:

**R1 — `specrew-start.ps1` modularization (~60 SP)**: split into Specrew.Core / Specrew.Config / Specrew.Routing / Specrew.Artifacts modules. Introduces Pester test framework.

**R2 — `validate-governance.ps1` modularization (~20 SP)**: per-rule modules under `lib/Specrew.Validator.*.psm1`. Each rule becomes independently testable.

**R4 — Trust-boundary documentation (~6 SP)**: explicit document of trust boundaries in the script surface (which scripts run with what permissions; what they trust about input).

**R5 — Coordinator-prompt modularization (~15-20 SP, NEW 2026-05-13)**: separate prompt files per concern (boundary discipline, content density, file URLs, architecture intent, etc.). Coordinator prompt INCLUDES them via template injection at install/build time.

**Artifact mergeability work (~10 SP, separated from Multi-Developer Reconciliation)**: per-branch / per-feature / deterministic-order patterns for files that cause merge collisions (e.g., `feature.json`, `identity/now.md`).

R3 was folded into Feature 015 (product-spec status reconciliation) and is retired from the refactor track.

## Effort

~110 SP across the five features. Each is independently scheduable; some can ship in parallel after the first.

## Phase placement

Phase 3 — system-optimization phase. Composes with parallelization strategy (Phase B): refactor makes single-team work faster; eventually enables parallel teams.

## Open questions

1. Refactor sequence — R1 first (biggest, blocks others)?
2. Test framework adoption — Pester everywhere, or per-script?
3. Backward compatibility — old script APIs must continue working during transition?
4. Coordinator-prompt modularization template — install-time injection or runtime composition?

## Risks

- **Refactor regression**: monolith → modules can introduce subtle behavior changes. Mitigation: Pester tests first; refactor under test coverage.
- **Scope creep**: refactor "while we're at it" tendencies. Mitigation: each R-feature has bounded scope; no rewrites.
- **Coordinator-prompt fragmentation**: modular prompts may lose coherence. Mitigation: template includes ensure final prompt assembly is deterministic.

## Cross-references

- Composes with: parallelization strategy (Phase B optimization)
- Composes with: Proposal 010 (Multi-Developer Reconciliation) — artifact mergeability is a prerequisite

## Status history

- 2026-05-12: candidates captured (R1-R4)
- 2026-05-13: R5 (coordinator-prompt modularization) added; R3 retired (folded into F-015)

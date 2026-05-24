# Iteration 001 State

**Feature**: F-044 Per-Host Architecture Refactor
**Iteration**: 001 — Phases A-D + Proposal 108 Slices 1-9 (architectural payoff)
**Status**: closed-with-known-issues (review-gate identified 22 findings → iter-002 cleanup slice)
**Started**: 2026-05-23
**Closed**: 2026-05-24
**Branch**: `multi-host-integration-refactor` (bundled with F-043 PR)

## Scope

iter-001 ships:
- Per-host package registry (Phase A) + 4 host manifests
- Per-host handler implementations (Phase B) — 4 contract functions × 4 hosts = 16 functions
- Registry-driven shims replacing 3 host-coupled scripts (Phase C)
- Manifest-driven launch path + Antigravity addition (Phase C.2)
- Declarative coordinator-prompt surgery rules engine (Phase C.3)
- Phase D ship-blocker fixes + truthful-metrics doc pass
- `scripts/specrew-init.ps1` split into 9 focused files (Proposal 108 Slices 1-8)
- 5th contract function `Install-<Kind>CrewRuntime` + canonical `.specrew/team/` source-of-truth + per-host translation on every `specrew start` (Slice 9)

Covers FRs FR-001 through FR-012 of the spec (FR-013 test file shipped in iter-002 to keep iter-001 scope architectural).

## Boundary state

- specify: completed (retroactive — see [`../../spec.md`](../../spec.md))
- clarify: skipped (work shipped before spec; user authorized in-conversation)
- plan: completed (retroactive — see [`../../plan.md`](../../plan.md))
- tasks: covered by phase breakdown in `../../plan.md` § "iter-001 phase breakdown"
- implement: completed (24 commits, see [`code-map.md`](./code-map.md))
- review-signoff: completed-with-conditions — see [`review.md`](./review.md) for the 22 findings + sign-off as "approved for iter-002 follow-up"
- retro: completed — see [`retro.md`](./retro.md)
- iteration-closeout: completed (this file)
- feature-closeout: pending iter-002 + bundled PR merge to main

## Methodology disclosure

The work in this iteration shipped BEFORE the spec was written. Spec and iteration artifacts are retroactive backfill. The review-gate methodology IS being honored — iter-001 closes with the 22 findings recorded honestly + iter-002 addresses them. That's the textbook two-iteration pattern; the unusual aspect is that it was reconstructed post-hoc rather than driven live.

## Cross-feature note

This iteration was developed on the `multi-host-integration-refactor` branch alongside F-043 (Multi-Host Onboarding). Several F-044 commits sit BEFORE F-043 commits (Phase A-C provide the registry F-043 depends on); several sit AFTER (Phase D + Slice 1-9 build the host-package contract that consumes F-043's host-history). The bundled PR description explains the co-evolution; readers can navigate F-043's iteration artifacts independently.

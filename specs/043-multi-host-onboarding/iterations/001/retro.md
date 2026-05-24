# Iteration 001 Retro

**Feature**: F-043 | **Iteration**: 001 | **Date**: 2026-05-24

## What went well

- **Scope discipline at implementation time**: When parallel F-044 work surfaced higher-priority architectural concerns, the team explicitly cut FR-008/009/011 rather than letting scope creep. The remaining 9 FRs shipped cleanly within their original effort estimate.
- **Substrate reuse**: F-043 builds entirely on top of F-044's registry-driven host abstraction. The host-history schema's `hosts:` map is populated by iterating `Get-RegisteredHostKinds` — no hardcoded enums, no special-cases. Adding a new host kind extends F-043's state automatically.
- **F-040 review-gap closure**: F-040's review noted that `Resolve-SpecrewHostFromHistory` was defined but never called. F-043's wiring closed Gap 1 explicitly. Demonstrates the review-feedback-loop methodology working — gaps caught at one feature's review become acceptance criteria for the next.

## What went poorly

- **Methodology violations**: This iteration ran almost entirely without the per-feature SDLC discipline. Spec was auto-drafted overnight by Squad without user clarify input (per the standing Proposal 063 Substantive Intake Questioning concern — F-025/F-029 work, not yet shipped). Implementation commits landed on a shared integration branch instead of a per-feature branch from main. Iteration artifacts (this directory) were backfilled retroactively at closeout. The user explicitly flagged this in conversation: "we work really hard and not so by Specrew methodology since I want available and I let you run. It is time to fix that."
- **A-1 ship-blocker shipped**: The `-NoLaunch` carve-out gap (commit `755c87f1`) broke 3 pre-existing integration tests. Caught only by F-044 iter-001's deep-review-agent A — would have been caught immediately by a per-feature review-boundary on a clean F-043 branch.
- **Spec drift on serialization format**: `.yml` → `.json` was a reasonable engineering call but happened without a spec-amendment loop. The drift is benign (schema fields conform) but illustrates the pattern where implementer judgment overrides spec text without going back through clarify.
- **Test gap**: T010 (`tests/integration/multi-host-onboarding.tests.ps1`) was never written. F-043 behavior is currently regression-covered transitively by F-040's suite + the `specrew-start-*` tests, but F-043 lacks first-class test assertions for its own FRs.

## Lessons + queued action items

1. **PR-at-feature-close discipline is non-negotiable for non-trivial features**. F-043 should have been its own branch from main, its own PR with focused review. The cross-feature bundle with F-044 here is justified by genuine architectural co-evolution, but in normal cases the discipline must hold. Reinforces the standing Proposal 067 (Small-Fix Slice Type) for the rare cases where bundling is appropriate.
2. **Substantive Intake Questioning (Proposal 063 / F-025 / F-029) is the structural fix** for the auto-drafted-overnight spec gap. The spec defaults Squad chose for F-043 (e.g., "ship `.yml`") were reasonable but the user never reviewed them at clarify. Proposal 063 fires intake questions BEFORE the auto-progression.
3. **F-040 Gap 1 → F-043 closure pattern** should be formalized — review gaps from one feature should be promoted to acceptance criteria of the next feature touching the same surface. Captured as candidate proposal for future drafting.
4. **Follow-up slice for FR-008/009/011** (Category A coordinator-content migration) queued. Recommended after F-044 closes and before the next user-facing host work.
5. **T010 test backfill** queued as a small-fix slice.

## Honest framing for the reader

This iteration shipped its core value (host-selection chain + persistence + `specrew host` CLI) but the lifecycle discipline lapsed in ways that the methodology is designed to prevent. The retroactive backfill of this directory makes the work navigable for future readers, but the lapse itself is the most important data point — see [`../../proposals/063-substantive-intake-questioning.md`](../../../../proposals/063-substantive-intake-questioning.md) for the structural fix in progress.

# Iteration 004 Drift Log

**Feature**: F-044 | **Iteration**: 004 — Host UX Improvements (LIVE-TRACKED)

## No drift events

iter-004 was LIVE-TRACKED with plan.md authored before implementation. Estimates held; no scope expansion; no rework loops; no spec amendments. T001 + T002 + T003 closed within their planned SP estimates.

## Surfaced-but-not-iter-004 (recorded for traceability)

- **Cross-environment binary detection (e.g., WSL agy from Windows)**: surfaced by user's note "Antigravity on WSL"; explicitly out-of-scope per [`scope.md`](./scope.md). Could become a future proposal if multi-shell coordination needs surface.
- **PSGallery publication lag (user is running 0.24.1; main is 0.26.0)**: surfaced during iter-004 conversation; not a methodology bug; tracked by Proposal 060 (Prerelease Channel + Module Hygiene) deferred item.
- **Version-number drift from feature-aligned convention (F-040 → 0.26.0 instead of 0.40.0)**: surfaced during iter-004 conversation; queued as separate methodology decision (see [`retro.md`](./retro.md) § Lessons + Versioning).

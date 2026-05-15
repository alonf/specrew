# Implementer decision: Feature 018 review repair

- **Date**: 2026-05-15
- **Feature**: 018 — Velocity Dashboard Visual Richness + PoC-Parity Restoration
- **Boundary**: review-verdict-signoff
- **Decision**: Preserve Recent Shipped per-iteration granularity by rendering a combined feature-and-iteration label (`F-017 · iter-001`) on live dashboard rows.

## Rationale

1. Feature-only Recent Shipped labels regressed once Feature 017 and later features accumulated multiple closed
   iterations, causing `specrew where` to emit duplicate row labels.
2. A combined feature-and-iteration label keeps Feature 017 granularity visible without widening the repair into
   roadmap, projection, or retro surfaces.
3. The same label needs to flow through both rich and monochrome render paths so validator-backed snapshots and
   operator reruns stay consistent.


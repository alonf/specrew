# Spec Steward Decision Inbox — Feature 029 Review Repair

- **Date**: 2026-05-21
- **Feature**: 029-baseline-hygiene
- **Decision**: Treat commit-backed evidence as a hard review-boundary prerequisite. Implementation commits and upstream push must complete before review-boundary; PR opening belongs at review-boundary; merge belongs after review sign-off.
- **Rationale**: The rejected artifact revision claimed passing evidence while the actual F-029 surface work was still uncommitted. Reordering T010 into T010a/T010b keeps spec, plan, and execution discipline aligned with the review-evidence integrity gate.
- **Operational Impact**: Future review-boundary repairs should update the iteration task ordering before re-presenting evidence, then rerun scoped governance and feature-local tests against the committed branch head.

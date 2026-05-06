# Iteration Plan: 006

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 9/20 story_points
**Started**: 2026-05-06
**Completed**:

## Summary

Iteration 006 delivers the advanced reviewer surfaces scheduled after reviewer-core: FR-048, FR-053, and FR-054. The slice extends persisted closeout generation with a conditional `security-surface.md`, Mermaid-first `review-diagrams.md`, and a separate mutable `current-architecture.md` companion artifact outside the immutable iteration snapshot.

The implementation keeps reviewer-core as the canonical foundation. Security and diagram artifacts are derived from the same persisted review packet, and the mutable current-view surface is explicitly separated from closed-iteration artifacts so later iterations do not rewrite historical reviewer evidence.

---

## Scope

### In Scope

- Conditional `security-surface.md` generation from plan/team context
- Mermaid-first `review-diagrams.md` generation with omission recording when evidence is insufficient
- Mutable feature-level `current-architecture.md` companion surface
- Reviewer index wiring for advanced reviewer surfaces
- Regression coverage for the new reviewer artifacts

### Out of Scope

- No-gap closure and defer evidence hardening (Iteration 7)
- Delegated runtime evidence and reviewer gap-repair loop (Iteration 7)

---

## Requirements Traceability

| Spec Ref | Requirement | Planned Deliverables | Owner |
|----------|-------------|----------------------|-------|
| FR-048 | Conditional security surface | `security-surface.md`, trigger detection from team/plan context, vulnerability highlight carry-forward | Implementer |
| FR-053 | Reviewer diagrams | `review-diagrams.md`, Mermaid rendering, omission recording, local-view hints | Implementer |
| FR-054 | Immutable snapshots + current view | feature-level `current-architecture.md`, reviewer index distinction between snapshot and mutable view | Reviewer + Implementer |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-601 | Generate conditional security surface from closeout evidence | FR-048 | US-2 | 3 | Implementer | done | copilot-agent | 3 | pass |
| T-602 | Generate Mermaid-first reviewer diagrams with omission tracking | FR-053 | US-2 | 3 | Implementer | done | copilot-agent | 3 | pass |
| T-603 | Separate immutable iteration packet from mutable current architecture view | FR-054 | US-2 | 2 | Reviewer | done | copilot-agent | 2 | pass |
| T-604 | Harden reviewer-advanced regression coverage | FR-048, FR-053, FR-054 | US-2 | 1 | Reviewer | done | copilot-agent | 1 | pass |

**Planned Total**: 9 story_points

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Advanced reviewer surfaces stay fixed for this slice. |
| Time Limit (hours) | n/a | Not used for this scope-bounded iteration. |
| Overcommit Threshold | 1.0 | No overcommit expected at planned capacity 9/20. |
| Defer Strategy | manual | Governance hardening remains deferred to Iteration 7. |
| Calibration Enabled | true | Retro should confirm this slice stayed within the expected reviewer-surface budget. |

---

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Advanced reviewer artifact contract mapping |
| Implementation | 5 | Security surface, diagrams, and current architecture plumbing |
| Review | 2 | Contract-focused reviewer artifact validation |
| Rework | 1 | Buffer for artifact-shape fixes |

---

## Acceptance Checkpoints

1. `security-surface.md` is generated when security is in scope by plan or team context and omitted with an explicit reviewer-index reason otherwise.
2. `review-diagrams.md` records Mermaid structure/flow diagrams when thresholds are met and records omissions instead of inventing diagrams when evidence is insufficient.
3. `current-architecture.md` lives outside `iterations\NNN\` and is clearly labeled as the mutable companion to immutable reviewer snapshots.
4. Reviewer index artifact links clearly distinguish snapshot artifacts from the mutable current-view surface.

## Notes

- Iteration 006 builds directly on Iteration 005 reviewer-core rather than introducing a separate reviewer pipeline.
- The contract test for reviewer artifacts now exercises security trigger detection, Mermaid diagram generation, and current-view wiring in one scratch repo.

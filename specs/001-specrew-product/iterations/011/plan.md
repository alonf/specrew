# Iteration Plan: 011

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 4/20 story_points
**Started**: 2026-05-07
**Completed**:

## Summary

Iteration 011 is a forward-only corrective governance slice. It carries the reviewer-closeout cutoff repair, the explicit-target legacy-iteration regression fix, and the remaining FR-054 defer evidence without reopening Iteration 009 or rewriting Iteration 010.

The purpose of this slice is process integrity as much as technical correctness: the validator/config/test fixes are kept, but the history boundary is restored by treating them as new work with their own iteration artifacts. It also serves as the forward attribution point for the follow-on reviewer-governance hot-fix that was discovered immediately after Iteration 010 closed.

---

## Scope

### In Scope

- Re-home the reviewer-closeout cutoff repair into a new forward iteration
- Ensure explicit-target validation preserves historical iterations that predate reviewer-closeout enforcement
- Keep the remaining FR-054 immutability-guardrail gap recorded canonically without mutating closed iteration artifacts

### Out of Scope

- The automated FR-054 immutable-snapshot guardrail itself
- `specrew start` wrapper and same-window launch repairs
- Downstream repo hygiene work (`FR-055`)

---

## Requirements Traceability

| Spec Ref | Requirement | Planned Deliverables | Owner |
|----------|-------------|----------------------|-------|
| FR-046, FR-049, FR-052, FR-053 | Reviewer closeout enforcement honors the forward-only cutoff in both default and explicit-target validation | `validate-governance.ps1`, `.specrew\iteration-config.yml` | Reviewer |
| FR-046, FR-049, FR-052, FR-053 | Legacy explicitly targeted iterations before the cutoff remain valid | `tests\integration\reviewer-closeout-governance.ps1` regression coverage | Implementer |
| FR-054, FR-044, FR-045 | Closed iteration snapshots stay immutable while the remaining automation gap stays visible and deferred | `.squad\decisions.md` plus Iteration 011 planning evidence | Planner |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-1101 | Re-home reviewer closeout cutoff enforcement into a forward corrective slice | FR-046, FR-049, FR-052, FR-053 | US-2 | 2 | Reviewer | done | copilot-agent | 2 | pass |
| T-1102 | Add explicit-target legacy-iteration regression coverage for the closeout cutoff | FR-046, FR-049, FR-052, FR-053 | US-2 | 1 | Implementer | done | copilot-agent | 1 | pass |
| T-1103 | Record the remaining FR-054 guardrail gap without mutating closed iterations | FR-054, FR-044, FR-045 | US-2 | 1 | Planner | done | copilot-agent | 1 | pass |

**Planned Total**: 4 story_points

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Keep the corrective slice fixed to forward-only closeout enforcement repair. |
| Time Limit (hours) | n/a | Not used for this scope-bounded iteration. |
| Overcommit Threshold | 1.0 | No overcommit expected at planned capacity 4/20. |
| Defer Strategy | manual | Keep the immutable-snapshot guardrail as an explicit follow-up rather than widening this slice. |
| Calibration Enabled | true | Retro should confirm whether corrective governance slices stay small and isolated. |

---

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Restore the snapshot boundary and open a new corrective slice instead of rewriting Iteration 009 |
| Implementation | 2 | Isolate the cutoff/config/test/defer-evidence edits under Iteration 011 |
| Review | 1 | Reviewer-closeout regression and repo governance validation proved the isolated slice |
| Rework | 0 | Isolation held after Iteration 009 was restored, so no extra repair loop was needed |

---

## Acceptance Checkpoints

1. Iteration 009 remains byte-for-byte at its committed snapshot while the cutoff repair is tracked only under Iteration 011.
2. Explicit-target validation of pre-cutoff legacy iterations passes without retroactively requiring reviewer closeout packets.
3. The remaining FR-054 guardrail gap is deferred canonically without back-editing closed iteration artifacts.

## Notes

- Iteration 012 was temporarily set aside while this slice was validated and closed so the reviewer packet reflects only the forward governance correction.
- This slice intentionally owns the shared roadmap renumbering because the forward-only correction changes the delivery order for FR-055 and FR-056.

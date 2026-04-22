# Iteration Plan: 002 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: TBD
**Started**: TBD
**Completed**: TBD

## Summary

Iteration 2 scope includes FR-007 (configurable effort model), FR-015 (process-quality scorer), FR-017 (capacity planning with overcommit detection), FR-019 (programmatic task resume), FR-020 (brownfield bootstrap), and **FR-021 (cross-agent review routing)**.

This stub captures the planned scope pending detailed planning in the Iteration 2 planning ceremony. Full task breakdown, effort estimation, and traceability matrix will be populated once planning begins.

---

## Planned Functional Requirements

| Requirement | Description | Effort (est) |
| ----------- | ----------- | ------------ |
| FR-007 | Configurable effort measurement (effort unit + capacity model) | TBD |
| FR-015 | Process-quality scorer (ceremony adherence, drift detection rate, traceability coverage) | TBD |
| FR-017 | Capacity planning with overcommit detection and task deferral suggestion | TBD |
| FR-019 | Programmatic task resume: automated pickup from last completed task after failure/interruption | TBD |
| FR-020 | Brownfield bootstrap: merge into existing Spec Kit/Squad config without overwriting | TBD |
| **FR-021** | **Cross-agent review routing: Reviewer and Spec Steward preferentially route to a non-Implementer delegated agent** | TBD |

## Planned Spikes / Validation

| Spike | Description | Blocks | Effort (est) |
| ----- | ----------- | ------ | ------------ |
| **V-R7-2** | Validate that Squad's SDK supports per-role selection of a Copilot Agent HQ agent via `preferred_agent` in `role-assignments.yml`. Determine whether Squad can invoke a specific Agent HQ selectable agent per task, or whether a Specrew-side routing wrapper is required. If Squad cannot route per role, capture the gap as a blocker on FR-021 and decide between (a) waiting on a Squad upstream change or (b) building a Specrew-owned routing shim. | FR-021 | TBD (0.5–1 pt expected) |

**Total Capacity**: TBD (planned for post-MVP stabilization and enhanced iteration engine features)

---

## Notes

- Iteration 2 planning will refine scope, task breakdown, and effort estimates based on Iteration 1 retrospective findings and calibration data.
- FR-021 implementation depends on (a) FR-022 (agent detection + config) being complete and validated in Iteration 1 and (b) V-R7-2 confirming Squad can route per role or that a Specrew-side shim is viable.
- Brownfield bootstrap (FR-020) may require careful attention to edge cases and user prompting for conflicting role names.

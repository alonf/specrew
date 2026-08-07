# Iteration Plan: 005

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: abandoned
**Capacity**: 5/26 story_points
**Started**: 2026-07-14
**Completed**:

## Objective

Record the completed host-support and hook-health hardening slice, and preserve the
architectural reassessment that replaced the non-converging mutable review lease. This
is a post-hoc lifecycle disposition, not authorization to resume Iteration 005. The
replacement campaign/run architecture was planned and delivered in Iterations 006–008.

## Scope Summary

| Requirement | Iteration 005 outcome | Disposition |
| --- | --- | --- |
| FR-050 | Truthful host/surface support tiers and presentation | delivered |
| FR-051 | Codex Stop-contract characterization and fail-open guard | delivered |
| FR-052 | Copilot CLI hook-contract characterization | delivered |
| FR-053 | Sanitized hook-health receipts, classifier, and doctor/status integration | delivered |
| FR-054 | Codex plugin packaging regression | deferred to issue #3084 / Beta3 |
| FR-057–FR-065, SC-017–SC-021 | Replacement campaign/run architecture established by the Iteration 005 design reassessment | carried into Iterations 006–008 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status |
| --- | --- | --- | --- | ---: | --- | --- | --- |
| T035 | Host-support model and truthful tiers | FR-050 | Support truth | 0.50 | Implementer | `scripts/internal/continuous-co-review/**`, `docs/**` | done |
| T036 | Codex Stop-contract conformance and adapter safeguards | FR-051 | Host contract | 1.25 | Implementer | `hosts/codex/**`, `scripts/internal/continuous-co-review/**`, `tests/**` | done |
| T037 | Copilot CLI contract verification | FR-052 | Host contract | 1.00 | Implementer | `hosts/copilot/**`, `scripts/internal/continuous-co-review/**`, `tests/**` | done |
| T038 | Hook-health receipts and doctor/status presentation | FR-053 | Health evidence | 0.75 | Implementer | `scripts/internal/continuous-co-review/**`, `tests/**` | done |
| T039 | Receipt integration, support-tier reconciliation, and documentation | FR-050, FR-051, FR-053 | Integration | 1.00 | Implementer | `scripts/internal/**`, `docs/**`, `tests/**` | done |
| T040 | Codex plugin packaging regression | FR-054 | Packaging | 0.50 | Implementer | `tests/**` | deferred |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Repository-configured unit. |
| Capacity per Iteration | 26 | Capacity in force for the feature. |
| Iteration Bounding | scope | The delivered hardening slice and architecture reassessment are the historical boundary. |
| Time Limit (hours) | n/a | Scope-bounded iteration. |
| Overcommit Threshold | 1.0 | No overcommit was authorized. |
| Defer Strategy | manual | T040 was explicitly deferred to #3084. |
| Calibration Enabled | true | Later retrospectives record the non-converging review cost. |

## Concurrency Rationale

The historical work executed serially under one Implementer. No same-specialty
parallel ownership is reconstructed or implied by this archival plan.

## Traceability and Disposition

- T035–T039 are reconstructed from [state.md](state.md), the committed feature task
  ledger, and their digest-bound evidence. Their `done` status records delivered work;
  it does not retroactively claim a completed Iteration 005 review/signoff cycle.
- T040 remains deferred to issue #3084 / Beta3 and is not a Beta2 release blocker.
- The final authorized Iteration 005 review rounds did not converge. The maintainer
  stopped the implementation and authorized an eight-lens reassessment in
  [design-analysis.md](design-analysis.md). The mutable lease design is superseded.
- Iteration 006 owns the immutable authority foundation, Iteration 007 owns production
  harness/runtime completion, and Iteration 008 owns the Beta2 release tail.
- Status is `abandoned` because Iteration 005 intentionally pivoted before its own
  review, retro, and closeout. No task in this file authorizes further mutation.

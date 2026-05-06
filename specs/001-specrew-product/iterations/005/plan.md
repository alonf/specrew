# Iteration Plan: 005

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 17/20 story_points
**Started**: 2026-05-06
**Completed**:

## Summary

Iteration 005 delivers the reviewer-core closeout surfaces for the Specrew product itself. The slice covers FR-046, FR-047, FR-049, FR-050, FR-051, and FR-052 by generating persisted reviewer artifacts at iteration close, replaying those artifacts through `specrew review`, and hardening the regression suite so the reviewer packet follows the product contract rather than placeholder content.

This batch was reopened once during dogfooding after the initial closeout produced files that existed but did not satisfy the FR-level artifact shape. The final scope keeps the same requirement slice, but adds explicit contract hardening so the generated packet is substantive rather than ceremonial.

---

## Scope

### In Scope

- Reviewer closeout code map generation with baseline-aware file and symbol deltas
- Dependency delta and vulnerability-scan reporting for closeout review
- Coverage evidence generation with explicit `not_executed` handling
- Interactive reviewer summary and non-interactive digest emission
- Persisted reviewer index plus `specrew review` replay/open flows
- Regression coverage for reviewer artifacts and replay

### Out of Scope

- Conditional `security-surface.md` generation (Iteration 6)
- Reviewer diagrams and immutable snapshot/current-view split (Iteration 6)
- No-gap governance and defer evidence hardening (Iteration 7)

---

## Requirements Traceability

| Spec Ref | Requirement | Planned Deliverables | Owner |
|----------|-------------|----------------------|-------|
| FR-046 | Reviewer code map | `code-map.md`, baseline capture, hotspot/test-to-code heuristics | Implementer |
| FR-047 | Dependency report | `dependency-report.md`, manifest diffing, vulnerability-scan posture | Implementer |
| FR-049 | Coverage evidence | `coverage-evidence.md`, test execution capture, requirement mapping | Reviewer + Implementer |
| FR-050 | Interactive reviewer summary | closeout summary block emitted from persisted artifacts | Implementer |
| FR-051 | Machine-parseable reviewer digest | stable digest line for CI/quiet output and replay | Implementer |
| FR-052 | Reviewer index + replay | `reviewer-index.md`, `specrew review`, local-open hints | Reviewer + Implementer |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-501 | Generate baseline-aware reviewer code map | FR-046 | US-2 | 4 | Implementer | done | copilot-agent | 4 | pass |
| T-502 | Generate dependency delta and vulnerability scan report | FR-047 | US-2 | 3 | Implementer | done | copilot-agent | 3 | pass |
| T-503 | Generate coverage evidence with explicit not_executed handling | FR-049 | US-2 | 2 | Reviewer | done | copilot-agent | 2 | pass |
| T-504 | Emit interactive summary and stable non-interactive digest | FR-050, FR-051 | US-2 | 3 | Implementer | done | copilot-agent | 3 | pass |
| T-505 | Persist reviewer index and replay through `specrew review` | FR-052 | US-2 | 3 | Implementer | done | copilot-agent | 3 | pass |
| T-506 | Harden reviewer-core regression coverage | FR-046, FR-047, FR-049, FR-050, FR-051, FR-052 | US-2 | 2 | Reviewer | done | copilot-agent | 2 | pass |

**Planned Total**: 17 story_points

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Reviewer-core requirements stay fixed for this slice. |
| Time Limit (hours) | n/a | Not used for this scope-bounded iteration. |
| Overcommit Threshold | 1.0 | No overcommit expected at planned capacity 17/20. |
| Defer Strategy | manual | Advanced reviewer surfaces remain explicitly deferred. |
| Calibration Enabled | true | Retro should feed later reviewer slices. |

---

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 2 | Reviewer-core slice definition and contract mapping |
| Implementation | 10 | Artifact generation, replay, and closeout wiring |
| Review | 3 | Dogfood review, contract audit, and replay validation |
| Rework | 2 | Hardening after dogfood contract failures |

---

## Acceptance Checkpoints

1. Closeout must generate `code-map.md`, `dependency-report.md`, `coverage-evidence.md`, and `reviewer-index.md` with the required sections and stable metadata.
2. Interactive closeout must emit the Reviewer Summary block; quiet/non-interactive closeout must emit only the stable `SPECREW_REVIEW schema=v1 ...` digest.
3. `specrew review` must replay the persisted packet without re-running iteration logic and must support `--quiet`, `--json`, and `--open`.
4. Reviewer-core regression coverage must reject placeholder output and enforce the contract tokens (`not_executed`, `unscanned`, stable digest shape).

## Notes

- This iteration is the first dogfood closeout for the reviewer visibility subsystem itself.
- The batch was reopened after an initial review found that placeholder reviewer artifacts and weak tests had started ratifying spec violations.
- The final closeout must be self-hosting: the reviewer packet generated for this iteration must be acceptable on its own merits.

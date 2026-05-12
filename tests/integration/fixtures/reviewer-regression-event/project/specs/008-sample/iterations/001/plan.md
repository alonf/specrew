# Iteration Plan: 001

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: executing  
**Capacity**: 5/20 story_points  
**Started**: 2026-05-09  
**Completed**: (not yet started)

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T001 | Stronger-class escalation fixture | FR-002 | US1 | 2 | Reviewer | in-progress | reviewer-fixture | | |
| T002 | Same-class fallback fixture | FR-003 | US1 | 2 | Reviewer | planned | reviewer-fixture | | |
| T003 | Maximum-strength hold fixture | FR-004 | US1 | 1 | Reviewer | planned | reviewer-fixture | | |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Fixture mirrors the repository default effort unit. |
| Capacity per Iteration | 20 | Fixture keeps the default Specrew capacity. |
| Iteration Bounding | scope | Fixture keeps the scope-bounded default. |
| Time Limit (hours) | n/a | Not used for this fixture. |
| Overcommit Threshold | 1.0 | No overcommit is expected in the fixture. |
| Defer Strategy | manual | Fixture uses the default manual defer strategy. |
| Calibration Enabled | true | Included for contract completeness. |

## Notes

- This fixture iteration exists to exercise stronger-class escalation, same-class fallback, and maximum-strength hold routing for reviewer-regression events.

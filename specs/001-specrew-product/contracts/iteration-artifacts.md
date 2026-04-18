# Contract: Iteration Artifact Formats

**Date**: 2026-04-17
**Spec**: [spec.md](../spec.md)
**Requirements**: FR-005, FR-006, FR-008, FR-009, FR-010, FR-018, FR-019

## Iteration Plan (`iterations/NNN/plan.md`)

```markdown
# Iteration Plan: NNN

**Schema**: v1
**Spec**: [spec.md](../../spec.md)
**Status**: planning | executing | reviewing | retro | complete | abandoned
**Capacity**: {used}/{total} {effort_unit}
**Started**: YYYY-MM-DD
**Completed**: YYYY-MM-DD (or blank)

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-001 | ... | FR-003 | US-2 | 3 | Implementer | done | copilot-agent-1 | 4 | pass |
| T-002 | ... | FR-008 | US-3 | 5 | Implementer | planned | | | |

## Notes

- Free-form planning notes
```

## Task State (`iterations/NNN/state.md`)

```markdown
# Iteration State: NNN

**Schema**: v1
**Last Completed Task**: T-001
**Tasks Remaining**: T-002, T-003
**In Progress**: (none)
**Updated**: YYYY-MM-DDTHH:MM:SS
```

## Drift Log (`iterations/NNN/drift-log.md`)

```markdown
# Drift Log: Iteration NNN

**Schema**: v1

## Events

- **DR-001**: Detected YYYY-MM-DD during T-001
  - **Requirement**: FR-003
  - **Deviation**: Agent stored user preferences in memory instead of spec-mandated config file
  - **Resolution**: implementation-reverted
  - **Detail**: Task T-001 marked needs-rework. Agent instructed to use config file per FR-003.

- **DR-002**: ...
```

## Review (`iterations/NNN/review.md`)

```markdown
# Review: Iteration NNN

**Schema**: v1
**Reviewed**: YYYY-MM-DD
**Overall Verdict**: accepted | needs-rework | blocked

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T-001 | FR-003 | pass | Output matches requirement |
| T-002 | FR-008 | needs-work | Drift detection not triggered on mock input |
```

## Retrospective (`iterations/NNN/retro.md`)

```markdown
# Retrospective: Iteration NNN

**Schema**: v1
**Date**: YYYY-MM-DD

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T-001 | 3 | 4 | +1 |
| T-002 | 5 | 3 | -2 |

**Average variance**: +/- X.X

## Drift Summary

- Total drift events: N
- Resolved via spec update: N
- Resolved via revert: N
- Deferred: N

## What Went Well

- ...

## What Didn't Go Well

- ...

## Improvement Actions

1. ...
2. ...

## Calibration Suggestion

- Suggested capacity adjustment: {current} → {suggested}
- Rationale: ...
```

## Evaluation Report (`evaluation/report.md`)

```markdown
# Evaluation Report

**Schema**: v1
**Evaluated**: YYYY-MM-DD
**Reference Spec**: {path}
**Iterations Completed**: N

## Overall: PASS | FAIL

## Process Quality

| Criterion | Score | Details |
| --------- | ----- | ------- |
| Ceremony adherence | N/N phases | ... |
| Drift detection rate | X% | N detected / M introduced |
| Traceability coverage | X% | N tasks linked / M total |
| Estimation accuracy | ±X.X avg | ... |

## Outcome Quality

| Criterion | Score | Details |
| --------- | ----- | ------- |
| Requirement coverage | X% | N covered / M total |
| Acceptance pass rate | X% | N passed / M scenarios |
| Artifact consistency | OK/WARN | plan ↔ tasks ↔ output |

## Per-Iteration Breakdown

### Iteration 1
- ... (same structure as process/outcome above)

### Iteration 2
- ...
```

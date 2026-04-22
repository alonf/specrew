# Contract: Iteration Artifact Formats

**Date**: 2026-04-17 (Updated 2026-04-18: State machine made normative)
**Spec**: [spec.md](../spec.md)
**Requirements**: FR-005, FR-006, FR-008, FR-009, FR-010, FR-018, FR-019

## Iteration State Machine (Normative)

This contract enforces a strict phase state machine that MUST be followed for every iteration. This is not guidance — it is an operating rule that blocks invalid phase transitions.

```
┌─────────┐     approve      ┌───────────┐    all tasks    ┌────────────┐    review      ┌──────────┐    retro      ┌──────────┐
│Planning │──────plan────────>│ Executing │───────complete──>│ Reviewing  │────verdicts───>│  Retro   │───produced───>│ Complete │
└─────────┘                   └───────────┘                  └────────────┘                 └──────────┘                └──────────┘
      ▲                              ▲                              ▲                            ▲
      │                              │                              │                            │
      └──────────────────────────────┴────────────────────────────┬─────────────────────────────┘
                                   (needs-rework task re-enters executing)

ANY STATE ──────────────────────────────► ABANDONED (with recorded reason)
```

### Phase Rules

| Phase | Entry Condition | Exit Condition | Blocking Artifacts | Produced Artifacts |
|-------|-----------------|----------------|--------------------|-------------------|
| **Planning** | Iteration initialized | User approves plan | spec.md (must have requirements) | plan.md with all tasks defined |
| **Executing** | Plan approved | All tasks complete/abandoned/deferred | plan.md (approved), state.md (initial) | state.md (updated per task), drift-log.md |
| **Reviewing** | Execution complete | Review verdicts recorded | All completed tasks, drift-log.md | review.md with per-task verdicts |
| **Retro** | Review complete (overall verdict recorded) | `retro.md` complete | review.md (complete), all phase artifacts | retro.md with estimation, drift summary, actions |
| **Complete** | `retro.md` complete and Alon sign-off recorded | (terminal state) | All four phase artifacts plus recorded final sign-off | (none — marks iteration closed) |

### Artifact Validation Gates

- **Before executing**: `plan.md` MUST exist and be approved. Each task MUST map to a spec requirement (FR/TG). No null requirement references.
- **Before reviewing**: All tasks MUST be in a terminal state (done, needs-rework, deferred, or blocked). `drift-log.md` MUST be created (may be empty if zero drift events).
- **Before retro**: `review.md` MUST exist with per-task verdicts. Overall iteration verdict (accepted/needs-rework/blocked) MUST be recorded.
- **Before completing**: `retro.md` MUST exist with all mandatory fields (estimation accuracy, drift summary, process notes, improvement actions), and Alon MUST record final sign-off. If `retro.md` exists but sign-off is still pending, iteration status remains `retro`.

### Abandoned Iteration Rule

If an iteration is abandoned at any phase:
1. All incomplete tasks are recorded and become available for the next iteration
2. `iterations/NNN/state.md` is marked abandoned with explicit reason
3. Retro ceremony is NOT required (retro phase is skipped)
4. Next iteration can only begin after Alon (Chief Architect) approves the abandonment reason

---

## Iteration Plan (`iterations/NNN/plan.md`)

```markdown
# Iteration Plan: NNN

**Schema**: v1
**Spec**: [spec.md](../../spec.md)
**Status**: planning | executing | reviewing | retro | complete | abandoned
**Capacity**: {used}/{total} {effort_unit}
**Started**: YYYY-MM-DD
**Completed**: YYYY-MM-DD (only after Alon final sign-off; otherwise blank)

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-001 | ... | FR-003 | US-2 | 3 | Implementer | done | copilot-agent-1 | 4 | pass |
| T-002 | ... | FR-008 | US-3 | 5 | Implementer | planned | | | |

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 2 | Task decomposition, traceability, approval |
| Discovery/Spikes | 1 | Pre-planning risk reduction work |
| Implementation | 7 | Delivery tasks and wiring |
| Review | 1 | Review/demo gate and verdict capture |
| Rework | 1 | Expected needs-work buffer |

## Notes

- Free-form planning notes
```

Planning artifacts MUST include both task-level estimates and a phase-level baseline so retrospective analysis can compare where variance occurred.

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

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 2 | 3 | +1 | Extra clarification cycle |
| Discovery/Spikes | 1 | 1 | 0 | |
| Implementation | 7 | 6 | -1 | Reused existing helper |
| Review | 1 | 2 | +1 | Rework surfaced late |
| Rework | 1 | 0 | -1 | No needs-work loop |

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

Retrospectives MUST capture both task-level and phase-level variance. At minimum, phase variance covers planning, discovery/spikes, implementation, review, and rework.

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

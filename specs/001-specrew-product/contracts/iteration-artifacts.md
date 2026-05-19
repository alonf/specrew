# Contract: Iteration Artifact Formats

**Date**: 2026-04-17 (Updated 2026-04-18: State machine made normative; Updated 2026-05-05: Repair escalation state made normative)
**Spec**: [spec.md](../spec.md)
**Requirements**: FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-017, FR-018, FR-019, FR-027, FR-038, FR-039, FR-040, FR-041, FR-046, FR-047, FR-049, FR-052, FR-053

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

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T-001 | ... | FR-003 | US-2 | 3 | Implementer | — | done | copilot-agent-1 | 4 | pass |
| T-002 | ... | FR-008 | US-3 | 5 | Junior Frontend Developer | client/src/dashboard/** | planned | | | |
| T-003 | ... | FR-040 | US-3 | 5 | Senior Frontend Developer | client/src/exports/** | planned | | | |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds the configured threshold. |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Technology and scope signals: frontend-oriented signals dominate the scoped requirements.
- Task dependency graph: explicit ownership boundaries are only recorded once the task table is populated.
- Workstream separability: same-specialty expansion is only justified when the plan shows independent slices that can move in parallel safely.
- Shared-surface conflict risk: if tasks still overlap on a shared high-conflict surface, keep the work serial until ownership boundaries are explicit.
- Recommendation: if a Junior/Senior same-specialty pair is proposed, either record `Owner File Globs` (or an equivalent serialized ownership-boundary field) for the parallel tasks or state clearly that the work remains serial.

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

Planning artifacts MUST include:

1. task-level estimates
2. an effort-model snapshot copied from `.specrew/iteration-config.yml`
3. a phase-level baseline so retrospective analysis can compare where variance occurred
4. a `## Concurrency Rationale` section before any Junior/Senior same-specialty expansion is planned
5. explicit `Owner File Globs` (or an equivalent ownership-boundary field) for tasks that are allowed to run in parallel inside the same specialty; otherwise the rationale MUST keep the work serial

## Reviewer Closeout Packet (`iterations/NNN/*.md`)

When an iteration touches code or tests relative to `state.md` `Baseline Ref`, reviewer closeout MUST exist before the iteration can close in `retro` or `complete`.

Required artifacts for code-touching iterations:

1. `code-map.md`
2. `coverage-evidence.md`
3. `reviewer-index.md`
4. `review-diagrams.md` (may contain explicit omissions instead of invented diagrams)

Conditional reviewer artifacts:

1. `dependency-report.md` MUST exist when dependency manifests changed relative to `Baseline Ref`.
2. `current-architecture.md` is a mutable spec-level current view and lives outside the iteration directory when generated.

These artifacts are produced by `scaffold-reviewer-artifacts.ps1`. Closing a code-touching iteration without the required reviewer packet is a governance failure even if `review.md` and `retro.md` already exist.

## Task State (`iterations/NNN/state.md`)

```markdown
# Iteration State: NNN

**Schema**: v1
**Last Completed Task**: T-001
**Tasks Remaining**: T-002, T-003
**In Progress**: (none)
**Updated**: YYYY-MM-DDTHH:MM:SS

<!-- >>> specrew-managed escalation-state >>> -->
## Repair Escalation

- **Status**: inactive | active
- **Artifact**: tasks.md | plan.md | review.md | (none)
- **Gate**: after-tasks | before-implement | review | (none)
- **Failure Count**: 0..N
- **Current Tier**: efficiency | balanced | deep
- **Current Owner**: Planner | Reviewer | Spec Steward | (none)
- **Locked Out Agents**: Agent A, Agent B | (none)
- **Last Escalated**: YYYY-MM-DDTHH:MM:SSZ | (none)
- **Resolved At**: YYYY-MM-DDTHH:MM:SSZ | (none)
- **Notes**: free-form summary | (none)
<!-- <<< specrew-managed escalation-state <<< -->
```

`state.md` now has two normative responsibilities:

1. persist resumable task-execution metadata
2. persist the active repair-escalation cycle for any artifact that is currently failing governance gates

When `Status` is `active`, resume tooling MUST prioritize the escalation cycle before suggesting normal task execution. Activation and resolution of that block MUST also synchronize `.squad/config.json` so the temporary model override for the current repair owner matches `Current Tier` in real time. When the gate passes, the escalation block MUST be reset to `inactive`, clear the temporary owner override, and restore the default `efficiency` tier for future work.

### Reviewer Regression State (Spec 008 Extension)

When spec 008 (Reviewer Escalation Symmetry) is active, `state.md` gains an additional managed block:

```markdown
<!-- >>> specrew-managed reviewer-regression-state >>> -->
## Reviewer Regression State

- **Status**: inactive | active | held | resolved
- **Feature**: specs/008-reviewer-escalation-symmetry | (none)
- **Active Event IDs**: RRE-001, RRE-002 | (none)
- **Prior Reviewer Class**: copilot | claude | (none)
- **Current Reviewer Class**: codex | claude | (none)
- **Current Reviewer Owner**: Reviewer | Human Reviewer | (none)
- **Lockout Chain Length**: 0..N
- **Lockout Cap**: 2
- **Cap Active**: true | false
- **Locked Out Agents**: Agent A, Agent B | (none)
- **Carry Forward From Iteration**: 003 | (none)
- **Last Event**: 2026-05-09T12:34:56Z | (none)
- **Notes**: free-form routing summary | (none)
<!-- <<< specrew-managed reviewer-regression-state <<< -->
```

This block is a runtime mirror, not the source of truth. The ledger at `.specrew/reviewer-regression-log.md` remains authoritative. The block must never replace or mutate the existing `escalation-state` managed block. Both blocks operate independently:

- `escalation-state` governs implementer-side repair escalation (spec 001 FR-027)
- `reviewer-regression-state` governs reviewer-side escalation and lockout-cap handling (spec 008 FR-001 through FR-015)

Runtime sync must keep both blocks synchronized with `.squad/config.json` so routing decisions reflect both implementer and reviewer escalation state.

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

For the Iteration 2 process-only slice of FR-015, the report MAY populate only the process section plus a deferred placeholder in `## Outcome Quality`. At minimum, the process section must truthfully report artifact adherence and phase adherence from the current scorer output.

# Specrew: Retrospective

**Type**: Ceremony  
**Schema**: v1  
**Status**: Active governance template

## Purpose

Close an iteration by capturing what happened, how accurate the plan was, where drift appeared, and what must change before the next planning ceremony.

## Trigger

- Review/demo is complete and `review.md` records an overall verdict
- `plan.md`, `state.md`, `drift-log.md`, and `review.md` all exist
- Runs as a distinct ceremony; it does not wait on human sign-off to begin

## Participants

| Role | Responsibility |
| ---- | -------------- |
| Retro Facilitator | Leads the ceremony and writes `retro.md` |
| Planner | Supplies estimate deltas and calibration notes |
| Spec Steward | Summarizes drift patterns and governance misses |
| Implementer | Explains execution blockers, surprises, and rework |
| Chief Architect | Reviews improvement actions and approves policy changes |

## Required Inputs

| Input | Why it matters |
| ----- | -------------- |
| `iterations/NNN/plan.md` | Baseline scope, estimates, owners, and final task states |
| `iterations/NNN/state.md` | Confirms execution ended in a resumable, terminal state |
| `iterations/NNN/drift-log.md` | Source of truth for drift count and resolution type |
| `iterations/NNN/review.md` | Review verdicts, rework calls, and release readiness |

## Ceremony Method

### 1. Preflight gate

Do not start synthesis until these checks pass:

1. `review.md` has an overall verdict
2. every task in `plan.md` has a final task status
3. `drift-log.md` exists, even when it records zero drift
4. any abandoned or deferred work is explicit

### 2. Estimation accuracy

Record both task-level and phase-level variance:

- **task level**: estimated vs. actual for each task
- **phase level**: planning, discovery/spikes, implementation, review, rework
- call out systemic bias, not just arithmetic deltas

### 3. Drift summary

Summarize:

- total drift events
- gold-plating vs. omission vs. direct violation
- resolution path used
- whether any drift escaped to review instead of being caught during execution

### 4. Process adherence

Capture what helped or hurt governance:

- Were pre-planning spikes run before planning?
- Did the planning gate stop orphan tasks and stale references?
- Was state persisted after each task?
- Did review and retro happen in the right order?

### 5. Improvement actions

Record only concrete follow-ups:

1. owner
2. next iteration or phase
3. expected effect
4. whether the action is a policy, template, or implementation change

## Output Contract

Produce `iterations/NNN/retro.md` with at least:

- `## Estimation Accuracy`
- `## Drift Summary`
- `## What Went Well`
- `## What Didn't Go Well`
- `## Improvement Actions`

Include calibration guidance when variance suggests a capacity or sequencing change.

## Exit Condition

The retro phase is complete when `retro.md` is written and improvement actions are explicit enough to feed the next planning ceremony.

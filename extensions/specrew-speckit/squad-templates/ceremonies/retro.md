# Specrew: Retrospective Guidance

**Type**: Built-in ceremony guidance
**Schema**: v1  
**Status**: Source guidance for Squad's built-in retrospective

## Purpose

Augment Squad's built-in retrospective so it captures Specrew's governance requirements: what happened, how accurate the plan was, where drift appeared, and what must change before the next planning ceremony.

## Trigger

- Review/demo is complete and `review.md` records an overall verdict
- `plan.md`, `state.md`, `drift-log.md`, and `review.md` all exist
- Runs inside Squad's built-in Retrospective ceremony; Specrew does not append a separate retrospective definition to `.squad/ceremonies.md`

## Participants

| Role | Responsibility |
| ---- | -------------- |
| Retro Facilitator | Leads the ceremony and writes `retro.md` |
| Planner | Supplies estimate deltas and calibration notes |
| Spec Steward | Summarizes drift patterns and governance misses |
| Implementer | Explains execution blockers, surprises, and rework |
| Project Owner (optional) | Reviews improvement actions and approves policy changes when a non-baseline approver is needed |

## Required Inputs

| Input | Why it matters |
| ----- | -------------- |
| `iterations/NNN/plan.md` | Baseline scope, estimates, owners, and final task states |
| `iterations/NNN/state.md` | Confirms execution ended in a resumable, terminal state |
| `iterations/NNN/drift-log.md` | Source of truth for drift count and resolution type |
| `iterations/NNN/review.md` | Review verdicts, rework calls, and release readiness |

## Guidance Method

Use this checklist inside Squad's built-in retrospective flow.

### 0. Artifact scaffold

Start by creating a contract-aligned retro artifact in the downstream project:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-retro-artifact.ps1 -IterationDirectory .\specs\NNN-feature\iterations\NNN
```

This scaffold seeds `retro.md` from the current `plan.md`, `state.md`, `drift-log.md`, and `review.md` so the ceremony can focus on evidence and decisions instead of formatting.

When the retrospective is complete and the iteration is ready to close, persist the `iteration-closeout` boundary:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1 `
  -ProjectPath . `
  -BoundaryType iteration-closeout `
  -FeatureRef NNN-feature `
  -IterationNumber NNN
```

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
- `## Phase Variance`
- `## Drift Summary`
- `## What Went Well`
- `## What Didn't Go Well`
- `## Improvement Actions`

Include calibration guidance when variance suggests a capacity or sequencing change.

## Exit Condition

The retro phase is complete when `retro.md` is written and improvement actions are explicit enough to feed the next planning ceremony.

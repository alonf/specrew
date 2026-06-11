---
name: "specrew-iteration-resume"
description: "Resume an interrupted iteration by analyzing state.md plus plan.md's task table and suggesting the next safe execution step or escalation."
domain: "lifecycle-recovery"
confidence: "high"
source: "Specrew governance pillar — iteration resume / recovery helper"
---

# specrew-iteration-resume

**Type**: Recovery Skill  
**Schema**: v1  
**Status**: Active recovery method

## Purpose

Resumes interrupted iterations by analyzing `state.md` plus the authoritative task table in `plan.md`, then suggests the next execution step or active repair escalation.

## When to Use

- **When an iteration is interrupted** (agent crash, user stops work, blocker encountered)
- **When resuming work after a break**
- **When transferring iteration ownership** (handoff between agents/humans)

## Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| iteration_directory | path | Yes | Path to `specs/<feature>/iterations/NNN/` containing `state.md` and `plan.md` |
| resume_mode | enum: continue, replan, abort | Yes | How to resume the iteration |

## Process

1. Parse `state.md` to extract:
    - Last completed task
    - In-progress tasks (started but not done)
    - Remaining tasks (not yet started)
    - Active repair escalation state, if one is recorded
2. Parse `plan.md` to read the authoritative task table and current task statuses.
3. Reconcile stale or partial `state.md` metadata against the task table:
   - Repair missing `Tasks Remaining`, `In Progress`, and `Updated` metadata when possible
   - Treat `planned` tasks as remaining work and `in-progress` / `needs-rework` tasks as active work
   - Surface blockers when `state.md` references unknown tasks or plan-blocked tasks
4. Determine resumption strategy based on `resume_mode`:
    - **continue**: Resume the current repair escalation first; after activating or resolving escalation, sync `.squad/config.json` with `sync-squad-model-overrides.ps1`, otherwise resume the current in-progress task or suggest the next incomplete task
    - **replan**: Suggest re-planning remaining tasks
    - **abort**: Mark iteration as abandoned, list salvageable tasks
5. Generate resume report
6. Write the report back into `state.md` when the iteration is resumable or intentionally being re-planned/aborted

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| status | enum: ready, blocked, needs-replan | Resumption readiness |
| last_completed_task | string? | ID of last successfully completed task |
| in_progress_tasks[] | array | Tasks that were started but not finished |
| remaining_tasks[] | array | Tasks not yet started |
| next_suggested_task | string? | Task ID to execute next (null if blocked) |
| next_recovery_action | string? | Escalation step to resume before normal task work |
| repair_escalation | object | Persisted escalation state from `state.md` |
| blockers[] | array | Issues preventing resumption |
| blockers[].type | enum: dependency, role, resource | Type of blocker |
| blockers[].description | string | What is blocking progress |
| salvageable_tasks[] | array? | Tasks that can be moved to next iteration (if abort mode) |

## Side Effects

- Updates `state.md` with repaired execution metadata, resume timestamp, escalation summary, suggested next task, and resume report
- No file writes if status is "blocked"

## Error Handling

- If `state.md` is not found under `iteration_directory`: infer state from `plan.md` (all tasks assumed "planned")
- If `plan.md` is not found under `iteration_directory`: return error (cannot resume without plan)
- If `state.md` references unknown tasks or blocked work: report blockers and preserve the existing file

## Example Usage

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\resume-iteration.ps1 `
  -IterationDirectory .\specs\001-feature\iterations\000 `
  -ResumeMode continue
```

Expected Output (READY):
  status: "ready"
  last_completed_task: "T-003"
  in_progress_tasks: []
  remaining_tasks: ["T-004", "T-005", "T-006"]
  next_suggested_task: "T-004"
  blockers: []
  salvageable_tasks: null

Expected Output (BLOCKED):
  status: "blocked"
  last_completed_task: "T-003"
  in_progress_tasks: ["T-004"]
  remaining_tasks: ["T-005", "T-006"]
  next_suggested_task: null
  blockers:
    - type: "dependency"
      description: "T-004 is blocked waiting for external API access"
    - type: "role"
      description: "Reviewer role is unassigned; cannot proceed to review phase"
  salvageable_tasks: null

Expected Output (ABORT):
  status: "needs-replan"
  last_completed_task: "T-002"
  in_progress_tasks: []
  remaining_tasks: ["T-003", "T-004", "T-005"]
  next_suggested_task: null
  blockers:
    - type: "resource"
      description: "Critical blocker: upstream dependency no longer available"
  salvageable_tasks: ["T-005", "T-006"]

```

---

**Implementation Status**: Implemented for FR-019 / Iteration 2.

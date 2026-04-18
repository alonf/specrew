# specrew-iteration-resume

**Type**: Recovery Skill  
**Schema**: v1  
**Status**: Stub (Iteration 0 - implementation deferred to Iteration 1)

## Purpose

Resumes interrupted iterations by analyzing `state.md` and determining which tasks remain incomplete. Suggests next task to execute.

## When to Use

- **When an iteration is interrupted** (agent crash, user stops work, blocker encountered)
- **When resuming work after a break**
- **When transferring iteration ownership** (handoff between agents/humans)

## Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| state_path | path | Yes | Path to `iterations/NNN/state.md` |
| plan_path | path | Yes | Path to `iterations/NNN/plan.md` |
| resume_mode | enum: continue, replan, abort | Yes | How to resume the iteration |

## Process

<!-- Implementation deferred to Iteration 1 -->

1. Parse `state.md` to extract:
   - Last completed task
   - In-progress tasks (started but not done)
   - Blocked tasks (cannot proceed)
   - Remaining tasks (not yet started)
2. Parse `plan.md` to get task dependencies (if specified)
3. Determine resumption strategy based on `resume_mode`:
   - **continue**: Find next task respecting dependencies
   - **replan**: Suggest re-planning remaining tasks
   - **abort**: Mark iteration as abandoned, list salvageable tasks
4. Check for blockers:
   - Are any blocked tasks dependencies for remaining tasks?
   - Are all required roles still assigned?
5. Generate resume report

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| status | enum: ready, blocked, needs-replan | Resumption readiness |
| last_completed_task | string? | ID of last successfully completed task |
| in_progress_tasks[] | array | Tasks that were started but not finished |
| remaining_tasks[] | array | Tasks not yet started |
| next_suggested_task | string? | Task ID to execute next (null if blocked) |
| blockers[] | array | Issues preventing resumption |
| blockers[].type | enum: dependency, role, resource | Type of blocker |
| blockers[].description | string | What is blocking progress |
| salvageable_tasks[] | array? | Tasks that can be moved to next iteration (if abort mode) |

## Side Effects

- Updates `state.md` with resume timestamp and resume report
- No file writes if status is "blocked"

## Error Handling

- If state_path not found: Infer state from plan.md (all tasks assumed "planned")
- If plan_path not found: Return error (cannot resume without plan)
- If state.md has conflicting data: Report conflict, suggest manual reconciliation

## Example Usage

```
Invoke skill: specrew-iteration-resume
Inputs:
  state_path: "specs/001-feature/iterations/000/state.md"
  plan_path: "specs/001-feature/iterations/000/plan.md"
  resume_mode: "continue"

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

**Implementation Status**: STUB - Prompt skeleton only. Full logic to be implemented in Iteration 1 (FR-009).

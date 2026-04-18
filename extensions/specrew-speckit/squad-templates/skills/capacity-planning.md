# specrew-capacity-planning

**Type**: Planning Skill  
**Schema**: v1  
**Status**: Active planning method

## Purpose

Analyze in-scope requirements, produce a taskable effort model, and make overcommit visible before the plan is approved.

## When to Use

- During the Planning ceremony
- When re-planning after needs-rework or abandonment
- For deferral and what-if sequencing decisions

## Inputs

| Input | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| spec_requirements | array | Yes | List of requirements to plan for this iteration |
| iteration_config | object | Yes | Config from `.specrew/iteration-config.yml` |
| iteration_config.capacity_per_iteration | number | Yes | Max effort units for this iteration |
| iteration_config.effort_unit | string | Yes | Unit of effort measurement |
| iteration_config.overcommit_threshold | float | Yes | Ratio for overcommit warning |
| role_assignments | array | Yes | Available roles from `.specrew/role-assignments.yml` |
| historical_velocity | number? | No | Average effort per iteration for calibration |

## Process

1. Break each requirement into executable work and enabling work
2. Estimate effort per task and by phase:
   - planning
   - discovery/spikes
   - implementation
   - review
   - expected rework
3. Assign tasks to role owners, not individual nicknames
4. Calculate total effort and compare it to configured capacity
5. If over capacity:
   - rank deferral candidates
   - identify the requirement impact of each deferral
   - surface whether approval is needed
6. Return a plan-ready task list plus a capacity narrative

## Outputs

| Output | Type | Description |
| ------ | ---- | ----------- |
| tasks[] | array | Decomposed task list |
| tasks[].id | string | Task identifier |
| tasks[].title | string | Task description |
| tasks[].requirement_ref | string | Requirement this task implements |
| tasks[].effort | number | Estimated effort in the configured unit |
| tasks[].owner | string | Assigned role name |
| total_effort | number | Sum of all task efforts |
| capacity_status | enum: ok, warn, error | Capacity check result |
| capacity_message | string? | Warning or error message if not ok |
| suggested_deferrals[] | array? | Tasks to defer if overcommitted |
| phase_baseline[] | array | Planned effort by phase for retro comparison |

## Side Effects

None. This skill informs `plan.md`; it does not approve the plan.

## Error Handling

- If `iteration_config` is missing: use defaults (`capacity=20`, `unit=story_points`)
- If `role_assignments` are missing: assign tasks to `unassigned`
- If the requirements array is empty: return an empty plan and `capacity_status: ok`

## Review Standard

The output is only good enough for planning when it makes deferral choices and phase-level variance explicit.

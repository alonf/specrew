# specrew-traceability-check

**Type**: Analysis Skill  
**Schema**: v1  
**Status**: Active planning/review method

## Purpose

Validate that the plan is safe to execute by proving every task traces to authority and every in-scope requirement has coverage.

## When to Use

- During Planning before approval
- During Review when scope or requirement coverage is questioned
- On demand when a task looks orphaned or a requirement looks uncovered

## Inputs

| Input | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| iteration_plan_path | path | Yes | Path to `iterations/NNN/plan.md` |
| spec_path | path | Yes | Path to the authoritative spec file |
| requirement_scope | array? | No | Optional filter for specific requirements |

## Process

1. Parse the plan task table and collect task IDs, requirement refs, story refs, owners, and statuses
2. Parse the spec and identify the in-scope requirements
3. Build both:
   - requirement -> tasks
   - task -> requirement
4. Fail the check on:
   - orphan tasks
   - stale or invalid requirement references
   - uncovered in-scope requirements
   - tasks missing owner, effort, or story metadata
5. Return concrete fixes, not just a percentage

## Outputs

| Output | Type | Description |
| ------ | ---- | ----------- |
| verdict | enum: PASS, FAIL | Traceability check result |
| coverage_ratio | float | Percentage of requirements with tasks |
| orphan_tasks[] | array | Tasks with missing or invalid requirement refs |
| uncovered_requirements[] | array | Requirements with no tasks |
| partial_requirements[] | array | Requirements partially implemented |
| fix_actions[] | array | Plan edits required before execution can begin |

## Side Effects

None. This is a pre-execution gate.

## Error Handling

- If `iteration_plan_path` is missing: return FAIL with `plan file missing`
- If `spec_path` is missing: return FAIL with `spec file missing`
- If plan or spec parsing fails: return FAIL with the parsing problem

## Review Standard

The result must be strong enough to block planning if the plan is not contract-safe.

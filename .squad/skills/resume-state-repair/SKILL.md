---
name: "resume-state-repair"
description: "Repair stale execution metadata by reconciling state.md against the authoritative task table before resuming work"
domain: "powershell"
confidence: "high"
source: "earned"
tools:
  - name: "view"
    description: "Read state.md, plan.md, and the resume helper together"
    when: "When you need to compare persisted state fields against live task statuses"
  - name: "rg"
    description: "Find resume metadata labels, task-table parsing, and stale-state references quickly"
    when: "When auditing where resume logic trusts state too much"
  - name: "powershell"
    description: "Reproduce the stale-state scenario and verify the repaired resume flow"
    when: "When proving an interrupted iteration no longer skips planned work"
---

## Context

Use this when a resume or recovery helper reads both `state.md` and `plan.md`, and stale execution metadata could cause the workflow to skip incomplete tasks after an interruption.

## Patterns

- Treat the task table in `plan.md` as the authority for which tasks are still `planned`, `in-progress`, `needs-rework`, `blocked`, or `done`.
- Let `state.md` carry only the volatile execution details that may be newer than the plan table, especially active in-progress tasks.
- Rebuild `Tasks Remaining` from authoritative `planned` tasks instead of trusting a stale comma-separated list.
- Preserve or infer `In Progress` from `state.md` first, then fall back to task-table statuses when state metadata is missing.
- Rewrite repaired metadata before appending or refreshing any managed resume report so the artifact itself becomes the recovery output.

## Examples

- `state.md` says `Tasks Remaining: T-003`, but `plan.md` still shows `T-002` and `T-003` as planned. Repair `Tasks Remaining`, set `T-002` in progress on continue, and keep `T-003` queued.
- `state.md` is missing `In Progress` and `Updated`. Reconstruct them from the task table and write the repaired fields during resume.

## Anti-Patterns

- Trusting a stale `Tasks Remaining` list over the live task table.
- Leaving repaired resume results only in JSON output while `state.md` stays stale.
- Using task-table order alone as the execution order when the iteration can complete tasks out of order.

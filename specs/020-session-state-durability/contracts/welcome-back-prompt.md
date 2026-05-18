# Welcome-Back Prompt Contract

**Feature**: `020-session-state-durability`  
**Schema**: v1  
**Iteration**: 002

## Required Fields

When `specrew start` resumes a verified-current or re-anchored session, the generated prompt must include:

1. Active feature name
2. Feature path
3. Active worktree path
4. Current boundary and current task (if any)
5. Last completed task with timestamp (when available)
6. Last completed boundary commit hash and recorded-at timestamp
7. Task progress counts plus task-level detail for complete / in-progress / pending / blocked items
8. Validator warning summary from the latest recorded validator output, when available
9. Suggested next actions that are substantive (resume current task, start next task, review warnings, etc.)

## Rendering Rules

- The welcome-back block appears near the top of `.specrew/last-start-prompt.md` under the heading `## Welcome Back Snapshot`.
- If no validator summary is recorded, render `Validator state: no recorded warnings`.
- If no task is in progress, suggested next actions should point to the first pending task.
- If a task is blocked, the block must preserve the blocked reason in the task detail list.

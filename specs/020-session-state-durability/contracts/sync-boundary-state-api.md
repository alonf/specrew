# Sync Boundary State API

**Script**: `extensions/specrew-speckit/scripts/sync-boundary-state.ps1`  
**Schema**: v1  
**Iteration**: 001

## Purpose

Synchronize boundary-state metadata across `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/identity/now.md`, and `.squad/decisions.md` whenever a lifecycle boundary completes.

## Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| `-ProjectPath` | no | Specrew project root. Defaults to `.`. |
| `-BoundaryType` | yes | One of `specify`, `clarify`, `plan`, `tasks`, `review-signoff`, `iteration-closeout`, `feature-closeout`. |
| `-FeatureRef` | conditional | Feature directory slug such as `020-session-state-durability`. Optional at feature-closeout when `.specify/feature.json` still points at the active feature. |
| `-IterationNumber` | no | Three-digit iteration identifier when the boundary belongs to one iteration. |
| `-TaskId` | no | Stable task identifier when the boundary is task-adjacent. |
| `-AuthCommitHash` | no | Commit hash of the governing authorization or boundary commit to persist for stale-state validation. |
| `-PassThru` | no | Return the result object instead of console output. |

## Behavior Contract

1. Use write-temp-then-rename semantics for every file write.
2. Update files sequentially; cross-file atomicity is best-effort.
3. Persist flat `session_state_*` frontmatter fields in Markdown artifacts and a `session_state` object in `start-context.json`.
4. Append a `Boundary sync:` entry to `.squad/decisions.md` with boundary, feature, iteration, task, auth commit, and recorded-at values.
5. On `feature-closeout`, clear `.specify/feature.json` `feature_directory` after the state files are synchronized.

## Success Result

`-PassThru` returns an object with:

- `success`
- `boundary_type`
- `feature_ref`
- `iteration_number`
- `task_id`
- `recorded_at`
- `prompt_path`
- `context_path`
- `identity_path`
- `decisions_path`

## Failure Behavior

- If any file write fails, the script throws.
- Files written before the failure remain durable; the next `specrew start` run must detect the mismatch and stop with a stale-state prompt.

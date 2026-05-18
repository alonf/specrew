# Drift Log: Iteration 002

**Schema**: v1

## Summary

**Total drift events**: 2
**Resolution rate**: 100% (2/2 resolved)
**Specification drift**: None detected

## Events

### 2026-05-24 — Repair Attempt 1/3

- **Hypothesis**: The stale-state regression is not a fixture bug or Iteration 001 artifact lookup bug; `Get-TaskProgressSummary` is treating an advisory resume snapshot as fatal when the synced iteration has no `plan.md`.
- **Change made**: Updated `scripts\internal\task-progress.ps1` so summary generation falls back to any existing `tasks-progress.yml` state and returns an empty summary when the iteration plan is absent, instead of throwing during `specrew start`.
- **Test result**: PASS — `tests\integration\stale-state-detection.tests.ps1`, `tests\integration\task-progress-tracking.tests.ps1`, `tests\integration\cross-worktree-awareness.tests.ps1`, `tests\integration\boundary-sync-atomicity.tests.ps1`, and `tests\integration\version-checks.tests.ps1`.

### 2026-05-24 — PSGallery Repair Attempt 1/3

- **Hypothesis**: `specrew init` reaches the PSGallery warning path, but `Get-SpecrewInstalledVersion` looks for `Specrew.psd1` under `scripts\` instead of the repo root, so the helper cannot determine the bundled current version and suppresses the warning/cache write.
- **Change made**: Updated `scripts\internal\version-check.ps1` so the manifest fallback resolves the module manifest from the repository root (`..\..\Specrew.psd1`) before comparing against the PSGallery latest-version result.
- **Test result**: PASS — `tests\integration\psgallery-check.tests.ps1`, `tests\integration\boundary-sync-atomicity.tests.ps1`, `tests\integration\stale-state-detection.tests.ps1`, `tests\integration\task-progress-tracking.tests.ps1`, `tests\integration\cross-worktree-awareness.tests.ps1`, `tests\integration\version-checks.tests.ps1`, and `extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath . -IterationPath .\specs\020-session-state-durability\iterations\002`.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:
- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

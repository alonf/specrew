# Review: Iteration 012

**Schema**: v1
**Reviewed**: 2026-05-07
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T-1201 | FR-024 | pass | `scripts\specrew.ps1` now injects `--project-path <cwd>` when `specrew start` is invoked without an explicit project path, so downstream artifacts are written into the caller repo instead of the Specrew source repo. |
| T-1202 | FR-024 | pass | `scripts\specrew-start.ps1` now launches Windows same-window Copilot sessions through a child `pwsh` process, preserving the interactive session instead of returning immediately after bootstrap. |
| T-1203 | FR-024 | pass | `tests\integration\start-command.ps1` now covers both the default project-path behavior and the Windows same-window launch path. |

## Main Achievements

- `specrew start` now resolves its project context from the downstream caller repo by default instead of depending on the wrapper script location.
- Windows same-window handoff no longer drops out after the initial Copilot bootstrap step.
- The start-command regressions now capture both defects so later launch-flow work cannot reintroduce them silently.

## Gap Ledger

No known gaps remain.

## Remaining Notes

- This slice is intentionally limited to `specrew start` wrapper and launch behavior hardening.
- The product roadmap now resumes with the downstream repo-hygiene contract after this corrective separation work.

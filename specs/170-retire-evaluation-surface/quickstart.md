# Quickstart: Retire Top-Level Evaluation Surface

**Feature**: 170-retire-evaluation-surface
**Last verified**: 2026-06-06

## Run it

```powershell
# from the repo root
pwsh -File tests/integration/process-quality-scorer.ps1
pwsh -File tests/integration/process-quality-report.ps1
```

## Try the canonical scenario

1. Confirm the old surface is gone: `git ls-files evaluation/` — expect no output.
2. Run `pwsh -File tests/integration/process-quality-scorer.ps1` — expect a
   stream of `PASS:` lines and exit code 0 (the test builds a scratch project
   under `.scratch/process-quality-scorer/` and scores it via the moved scorer).
3. Run `pwsh -File tests/integration/process-quality-report.ps1` — expect
   `PASS:` lines, exit code 0, and the generated report at
   `.scratch/process-quality-report/project/test-results/process-quality-report.md`
   (untracked scratch space, not a repository artifact).

## Verify the edge cases

- **Missing scratch directory**: delete `.scratch/` entirely and re-run either
  test — both rebuild their scratch trees and pass.
- **Linux-safe path form**: run the smoke suite
  (`pwsh -Command "Invoke-Pester tests/integration/multi-host-lifecycle-smoke.tests.ps1"`)
  — it parses `tests/support/process-quality-scorer.ps1` and asserts the
  forward-slash path form.
- **Non-root invocation**: `pwsh -File tests/integration/project-path-resolution-regression.ps1`
  — path resolution to the moved scorer must not regress.

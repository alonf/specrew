# Quickstart: 203 beta5 stabilization

1. Run the iteration 001 suites: `Invoke-Pester tests/unit/typed-act-classifier.Tests.ps1, tests/unit/typed-act-writer.Tests.ps1, tests/unit/review-budget-loop.Tests.ps1`.
2. Check the live engine pin: the hook launcher's `-ModulePath` points at
   `%USERPROFILE%\.specrew\live-engine\203-beta5-stabilization`, and `git -C <pin> log -1` shows the last signed-off
   commit.
3. Review budget: the plan's `## Review budget` block is snapshotted at `approved for before-implement`; a spent
   budget stops with `approved for allowance reset` and `stop the review here`.
4. Claude capture check (FR-045): after the deployment point, type a verdict after a compaction, then a quoted
   and a pasted approval phrase; record the three results in `iterations/001/capture-check.md`.

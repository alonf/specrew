# Coverage Evidence: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-11
**Overall Verdict**: accepted

## Test Strategy

- Implementation briefing: (unavailable)
- Review-time strategy: use `reviewer.test_commands` when configured; otherwise record `not_executed` explicitly and keep the signal visible in closeout output.

## Tests Run

| Command | Result | Pass Count | Fail Count | Duration | Exit Code | Notes |
| ------- | ------ | ---------- | ---------- | -------- | --------- | ----- |
| `pwsh -NoProfile -File .\tests\integration\specrew-start-change-detector.ps1` | pass | 2 | 0 | 00:00:05.116 | 0 | PASS: detector returns no session-loaded changes for routine resumes and updates the baseline after a committed prompt-surface change. |
| `pwsh -NoProfile -File .\tests\integration\specrew-start-baseline-tracking.ps1` | pass | 3 | 0 | 00:00:04.702 | 0 | PASS: `baseline_commit_hash` is written to YAML frontmatter, survives round-trip serialization, and remains a valid 40-character SHA. |
| `pwsh -NoProfile -File .\tests\integration\specrew-start-auto-continue-preservation.ps1` | pass | 3 | 0 | 00:00:06.153 | 0 | PASS: routine resumes preserve the auto-continue directive across repeated runs and ignore uncommitted working-tree noise. |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Tool: PowerShell integration scripts

## Coverage-to-Requirements

| Requirement | Test Files / Commands |
| ----------- | --------------------- |
| FR-001 | `tests\integration\specrew-start-change-detector.ps1`, `tests\integration\specrew-start-auto-continue-preservation.ps1` |
| FR-002 | `tests\integration\specrew-start-baseline-tracking.ps1`, `tests\integration\specrew-start-change-detector.ps1` |
| FR-004 | `tests\integration\specrew-start-auto-continue-preservation.ps1` |
| FR-006 | Review inspection of `scripts\specrew-start.ps1` parameter surface at commit `fb926fe` plus the three regression scripts above |
| FR-007 | Review inspection of preserved error-message callsites in `scripts\specrew-start.ps1` plus `tests\integration\specrew-start-auto-continue-preservation.ps1` |
| FR-010 | `pwsh -NoProfile -File .\tests\integration\specrew-start-change-detector.ps1`, `pwsh -NoProfile -File .\tests\integration\specrew-start-baseline-tracking.ps1`, `pwsh -NoProfile -File .\tests\integration\specrew-start-auto-continue-preservation.ps1` |

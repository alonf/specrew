# Coverage Evidence: Iteration 002

**Schema**: v1
**Reviewed**: 2026-06-03
**Overall Verdict**: accepted

> **Note (form-vs-meaning):** the diff from baseline `464e0d3e` spans 27 files for 9 tasks. Expected
> for this multi-slice iteration (the Slice-1 session-recovery extraction + FR-024/FR-011/FR-014 +
> tests + iteration artifacts), all committed. See review.md evidence-integrity dimension.

## Test Strategy

- Reproduce-first per defect: FR-011, FR-014, the task-progress source-of-truth bug, and the
  stale-detection regressions each FAILED on pre-fix code and pass after; T004 is a verify-clean
  guard (passes on current code, locking the clean exit).
- The commands below are the **actual targeted feature-141 suites** exercised for this iteration
  (re-run 2026-06-03), not the reviewer's generic default quality-framework commands.

## Tests Run

| Command | Result | Pass Count | Fail Count | Duration | Exit Code | Notes |
| ------- | ------ | ---------- | ---------- | -------- | --------- | ----- |
| `pwsh -File tests/integration/multi-host-launch-path.tests.ps1` | pass | 24 | 0 | 7.2s | 0 | FR-011 Test 9b (greenfield browse-line guard) + FR-014 Test 18b (host-neutral approval-mode + delegation wording). |
| `pwsh -File tests/integration/start-recovery-flow.tests.ps1` | pass | 6 | 0 | 72.2s | 0 | FR-024 end-to-end enforcement (stale missing-path -> choice A -> confirm -> cleanup sticks). |
| `pwsh -File tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1` | pass | 15 | 0 | 5.9s | 0 | FR-024 detection/guard/cleanup/enforcement + Group 7 strict merge-detection; 0 transcript-noise lines. |
| `pwsh -File tests/unit/design-gate-runtime-hardening.tests.ps1` | pass | 17 | 0 | 1.4s | 0 | Includes the T004 verify-clean guard (gate harness exits clean; quality/prereq paths resolve). |
| `pwsh -File tests/integration/task-progress-tracking.tests.ps1` | pass | 7 | 0 | 24.8s | 0 | Start/resume task-progress source-of-truth regression (iteration-1 tasks.md must not downgrade iteration-2). |
| `pwsh -File tests/integration/stale-state-detection.tests.ps1` | pass | 5 | 0 | 90.4s | 0 | FR-024 stale-state recovery guidance (slug-bearing merge detection). |
| `pwsh -File tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1` | pass | 6 | 0 | 43.4s | 0 | Feature-closeout merged-claim removal via the strict merge detection (sync-boundary copy). |
| `pwsh -File tests/integration/non-specrew-session-bypass.tests.ps1` | pass | 6 | 0 | 13.4s | 0 | Promotion/preserve task-progress contracts + the repaired closeout-phrase assertion (`fcccfad3`). |

**Totals**: 86 pass, 0 fail across 8 targeted suites (re-run 2026-06-03). Governance validator: iteration 002 PASS.

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression + end-to-end runtime verification
- Tool: PowerShell test suites (no coverage instrumentation; behavior verified by assertion + real `specrew start` runs)

## Coverage-to-Requirements

| Requirement | Targeted Suites |
| ----------- | --------------- |
| FR-011 (no empty `specs//` paths) / SC-007 | tests/integration/multi-host-launch-path.tests.ps1 (Test 9b) |
| FR-014 (host-accurate wording) / SC-010 | tests/integration/multi-host-launch-path.tests.ps1 (Test 18b) |
| FR-024 (stale cross-worktree recovery) | tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1; tests/integration/start-recovery-flow.tests.ps1 (e2e); tests/integration/stale-state-detection.tests.ps1; tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1 |
| FR-015 (T004 gate-harness clean exit) | tests/unit/design-gate-runtime-hardening.tests.ps1 |
| Start/resume task-progress (source-of-truth) | tests/integration/task-progress-tracking.tests.ps1 |
| Required-CI regression (closeout-phrase assertion) | tests/integration/non-specrew-session-bypass.tests.ps1 |

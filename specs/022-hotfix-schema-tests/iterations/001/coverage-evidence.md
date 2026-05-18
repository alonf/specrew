# Coverage Evidence: Iteration 001

**Schema**: v1
**Reviewed**: 
**Overall Verdict**: accepted

## Test Strategy

- Implementation briefing: (unavailable)
- Review-time strategy: use `reviewer.test_commands` when configured; otherwise record `not_executed` explicitly and keep the signal visible in closeout output.

## Tests Run

| Command | Result | Pass Count | Fail Count | Duration | Exit Code | Notes |
| ------- | ------ | ---------- | ---------- | -------- | --------- | ----- |
| & '.\\tests\\integration\\quality-profile-foundation.ps1' | pass | 1 | 0 | 00:00:03.4827839 | 0 | PASS: Quality profile foundation scaffold and Phase 1/Phase 2 planning contracts expose versioned quality assets, bounded hardening metadata, preserve local overrides, and define recognized-stack/custom-composition expectations |
| & '.\\tests\\integration\\mechanical-findings-contract.ps1' | pass | 1 | 0 | 00:00:00.9036066 | 0 | PASS: Mechanical findings contract fixtures keep the Phase 1 rule set schema-compliant and make demoted rules remain visible with disposition references |
| & '.\\tests\\integration\\quality-evidence-governance.ps1' | pass | 1 | 0 | 00:00:12.7669527 | 0 | PASS: Quality evidence governance regressions passed. |
| & '.\\tests\\integration\\process-quality-scorer.ps1' | pass | 1 | 0 | 00:00:01.6386720 | 0 | PASS: Process scorer returns structured artifact and phase adherence results |
| & '.\\tests\\integration\\process-quality-report.ps1' | pass | 1 | 0 | 00:00:01.7850557 | 0 | PASS: Process scorer writes a Markdown report with process and deferred outcome sections |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Tool: unknown

## Coverage-to-Requirements

| Requirement | Test Files / Commands |
| ----------- | --------------------- |
| FR-005 | tests/README.md, tests/integration/boundary-sync-atomicity.tests.ps1, tests/integration/closeout-identity-schema-parity.tests.ps1, tests/integration/lifecycle-boundary-sync.tests.ps1, tests/integration/review-command.ps1, tests/integration/stale-state-detection.tests.ps1, tests/integration/start-command.ps1, tests/integration/start-recovery-flow.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-014 | tests/README.md, tests/integration/boundary-sync-atomicity.tests.ps1, tests/integration/closeout-identity-schema-parity.tests.ps1, tests/integration/lifecycle-boundary-sync.tests.ps1, tests/integration/review-command.ps1, tests/integration/stale-state-detection.tests.ps1, tests/integration/start-command.ps1, tests/integration/start-recovery-flow.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-010 | tests/README.md, tests/integration/boundary-sync-atomicity.tests.ps1, tests/integration/closeout-identity-schema-parity.tests.ps1, tests/integration/lifecycle-boundary-sync.tests.ps1, tests/integration/review-command.ps1, tests/integration/stale-state-detection.tests.ps1, tests/integration/start-command.ps1, tests/integration/start-recovery-flow.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-004 | tests/README.md, tests/integration/boundary-sync-atomicity.tests.ps1, tests/integration/closeout-identity-schema-parity.tests.ps1, tests/integration/lifecycle-boundary-sync.tests.ps1, tests/integration/review-command.ps1, tests/integration/stale-state-detection.tests.ps1, tests/integration/start-command.ps1, tests/integration/start-recovery-flow.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-009 | tests/README.md, tests/integration/boundary-sync-atomicity.tests.ps1, tests/integration/closeout-identity-schema-parity.tests.ps1, tests/integration/lifecycle-boundary-sync.tests.ps1, tests/integration/review-command.ps1, tests/integration/stale-state-detection.tests.ps1, tests/integration/start-command.ps1, tests/integration/start-recovery-flow.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-015 | tests/README.md, tests/integration/boundary-sync-atomicity.tests.ps1, tests/integration/closeout-identity-schema-parity.tests.ps1, tests/integration/lifecycle-boundary-sync.tests.ps1, tests/integration/review-command.ps1, tests/integration/stale-state-detection.tests.ps1, tests/integration/start-command.ps1, tests/integration/start-recovery-flow.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
# Coverage Evidence: Iteration 003

**Schema**: v1
**Reviewed**: 2026-06-09
**Overall Verdict**: accepted

Reviewer note: deliverable-test evidence (commands + exit codes + reproduced smokes) is in
[review-report.yml](./review-report.yml) claim_ledger. Iteration-003 added suites: Concurrency (10),
JournalAssertion (9), Regression (11), PerHost (12); the 18-file bootstrap suite + the F-171
refocus-deploy integration are green; PSScriptAnalyzer clean on all F-174 files. Live smokes:
cross-host SessionStart (4 hosts), SessionEnd->SessionStart round-trip, dispatcher SessionEnd
dispatch, Claude SessionEnd hook registration. The auto-populated framework rows below are the
scaffolder default, not the iteration-003 deliverable evidence.

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **9 completed task(s)**, but the git diff against baseline `3f36845e9d582b075e96c08d13bc181c4bc79932` contains **27 file(s)**.
>
> **Severity**: WARNING  
> **Implication**: Review evidence may be incomplete or misleading.
>
> **Possible causes**:
>
> - Implementation work was not committed before scaffolding review artifacts
> - Task status markers in plan.md or review.md do not match actual progress
> - Baseline reference in state.md is stale or incorrect
>
> **Remediation**:
>
> 1. Verify implementation is committed: `git diff 3f36845e9d582b075e96c08d13bc181c4bc79932...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Test Strategy

- Implementation briefing: (unavailable)
- Review-time strategy: use `reviewer.test_commands` when configured; otherwise record `not_executed` explicitly and keep the signal visible in closeout output.

## Tests Run

| Command | Result | Pass Count | Fail Count | Duration | Exit Code | Notes |
| ------- | ------ | ---------- | ---------- | -------- | --------- | ----- |
| & '.\\tests\\integration\\quality-profile-foundation.ps1' | pass | 1 | 0 | 00:00:03.6132287 | 0 | PASS: Quality profile foundation scaffold and Phase 1/Phase 2 planning contracts expose versioned quality assets, bounded hardening metadata, preserve local overrides, and define recognized-stack/custom-composition expectations |
| & '.\\tests\\integration\\mechanical-findings-contract.ps1' | pass | 1 | 0 | 00:00:01.1176165 | 0 | PASS: Mechanical findings contract fixtures keep the Phase 1 rule set schema-compliant and make demoted rules remain visible with disposition references |
| & '.\\tests\\integration\\quality-evidence-governance.ps1' | pass | 1 | 0 | 00:00:32.2886379 | 0 | PASS: Quality evidence governance regressions passed. |
| & '.\\tests\\integration\\process-quality-scorer.ps1' | pass | 1 | 0 | 00:00:02.1762694 | 0 | PASS: Process scorer returns structured artifact and phase adherence results |
| & '.\\tests\\integration\\process-quality-report.ps1' | pass | 1 | 0 | 00:00:02.0875922 | 0 | PASS: Process scorer writes a Markdown report with process and deferred outcome sections |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Tool: unknown

## Coverage-to-Requirements

| Requirement | Test Files / Commands |
| ----------- | --------------------- |
| FR-001 | tests/bootstrap/Concurrency.Tests.ps1, tests/bootstrap/JournalAssertion.Tests.ps1, tests/bootstrap/LauncherIntegration.Tests.ps1, tests/bootstrap/PerHost.Tests.ps1, tests/bootstrap/Regression.Tests.ps1, tests/bootstrap/SessionBootstrapManager.Tests.ps1, tests/integration/refocus-deploy.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-005 | tests/bootstrap/Concurrency.Tests.ps1, tests/bootstrap/JournalAssertion.Tests.ps1, tests/bootstrap/LauncherIntegration.Tests.ps1, tests/bootstrap/PerHost.Tests.ps1, tests/bootstrap/Regression.Tests.ps1, tests/bootstrap/SessionBootstrapManager.Tests.ps1, tests/integration/refocus-deploy.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-009 | tests/bootstrap/Concurrency.Tests.ps1, tests/bootstrap/JournalAssertion.Tests.ps1, tests/bootstrap/LauncherIntegration.Tests.ps1, tests/bootstrap/PerHost.Tests.ps1, tests/bootstrap/Regression.Tests.ps1, tests/bootstrap/SessionBootstrapManager.Tests.ps1, tests/integration/refocus-deploy.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-018 | tests/bootstrap/Concurrency.Tests.ps1, tests/bootstrap/JournalAssertion.Tests.ps1, tests/bootstrap/LauncherIntegration.Tests.ps1, tests/bootstrap/PerHost.Tests.ps1, tests/bootstrap/Regression.Tests.ps1, tests/bootstrap/SessionBootstrapManager.Tests.ps1, tests/integration/refocus-deploy.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-019 | tests/bootstrap/Concurrency.Tests.ps1, tests/bootstrap/JournalAssertion.Tests.ps1, tests/bootstrap/LauncherIntegration.Tests.ps1, tests/bootstrap/PerHost.Tests.ps1, tests/bootstrap/Regression.Tests.ps1, tests/bootstrap/SessionBootstrapManager.Tests.ps1, tests/integration/refocus-deploy.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-011 | tests/bootstrap/Concurrency.Tests.ps1, tests/bootstrap/JournalAssertion.Tests.ps1, tests/bootstrap/LauncherIntegration.Tests.ps1, tests/bootstrap/PerHost.Tests.ps1, tests/bootstrap/Regression.Tests.ps1, tests/bootstrap/SessionBootstrapManager.Tests.ps1, tests/integration/refocus-deploy.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-012 | tests/bootstrap/Concurrency.Tests.ps1, tests/bootstrap/JournalAssertion.Tests.ps1, tests/bootstrap/LauncherIntegration.Tests.ps1, tests/bootstrap/PerHost.Tests.ps1, tests/bootstrap/Regression.Tests.ps1, tests/bootstrap/SessionBootstrapManager.Tests.ps1, tests/integration/refocus-deploy.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-008 | tests/bootstrap/Concurrency.Tests.ps1, tests/bootstrap/JournalAssertion.Tests.ps1, tests/bootstrap/LauncherIntegration.Tests.ps1, tests/bootstrap/PerHost.Tests.ps1, tests/bootstrap/Regression.Tests.ps1, tests/bootstrap/SessionBootstrapManager.Tests.ps1, tests/integration/refocus-deploy.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |

# Coverage Evidence: Iteration 004

**Schema**: v1
**Reviewed**: 2026-06-09
**Overall Verdict**: accepted

Reviewer note: deliverable-test evidence (commands + exit codes + reproduced smokes) is in
[review-report.yml](./review-report.yml) claim_ledger. Iteration-004 added/updated suites:
RollingHandover (rolling round-trip + material-change + crash-safety + Stop-provider skip),
DeployedHostConfig (on-disk floor: Stop present / SessionEnd absent), plus Regression /
JournalAssertion / refocus-deploy swapped to the Stop model. 18 bootstrap suites + the F-171
deploy integration green; PSScriptAnalyzer clean. Live cross-host Stop dispatcher smoke green on
all four hosts. The auto-populated framework rows below are the scaffolder default.

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **6 completed task(s)**, but the git diff against baseline `4cd5183263778eb1dd5245de586e0ec2702da38f` contains **21 file(s)**.
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
> 1. Verify implementation is committed: `git diff 4cd5183263778eb1dd5245de586e0ec2702da38f...HEAD --stat`
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
| & '.\\tests\\integration\\quality-profile-foundation.ps1' | pass | 1 | 0 | 00:00:03.4431675 | 0 | PASS: Quality profile foundation scaffold and Phase 1/Phase 2 planning contracts expose versioned quality assets, bounded hardening metadata, preserve local overrides, and define recognized-stack/custom-composition expectations |
| & '.\\tests\\integration\\mechanical-findings-contract.ps1' | pass | 1 | 0 | 00:00:01.1052732 | 0 | PASS: Mechanical findings contract fixtures keep the Phase 1 rule set schema-compliant and make demoted rules remain visible with disposition references |
| & '.\\tests\\integration\\quality-evidence-governance.ps1' | pass | 1 | 0 | 00:00:32.0948779 | 0 | PASS: Quality evidence governance regressions passed. |
| & '.\\tests\\integration\\process-quality-scorer.ps1' | pass | 1 | 0 | 00:00:02.2466943 | 0 | PASS: Process scorer returns structured artifact and phase adherence results |
| & '.\\tests\\integration\\process-quality-report.ps1' | pass | 1 | 0 | 00:00:02.0933078 | 0 | PASS: Process scorer writes a Markdown report with process and deferred outcome sections |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Tool: unknown

## Coverage-to-Requirements

| Requirement | Test Files / Commands |
| ----------- | --------------------- |
| FR-009 | specs/174-hook-driven-session-bootstrap/spec.md, tests/bootstrap/DeployedHostConfig.Tests.ps1, tests/bootstrap/JournalAssertion.Tests.ps1, tests/bootstrap/Regression.Tests.ps1, tests/bootstrap/RollingHandover.Tests.ps1, tests/integration/refocus-deploy.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-005 | specs/174-hook-driven-session-bootstrap/spec.md, tests/bootstrap/DeployedHostConfig.Tests.ps1, tests/bootstrap/JournalAssertion.Tests.ps1, tests/bootstrap/Regression.Tests.ps1, tests/bootstrap/RollingHandover.Tests.ps1, tests/integration/refocus-deploy.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-008 | specs/174-hook-driven-session-bootstrap/spec.md, tests/bootstrap/DeployedHostConfig.Tests.ps1, tests/bootstrap/JournalAssertion.Tests.ps1, tests/bootstrap/Regression.Tests.ps1, tests/bootstrap/RollingHandover.Tests.ps1, tests/integration/refocus-deploy.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |

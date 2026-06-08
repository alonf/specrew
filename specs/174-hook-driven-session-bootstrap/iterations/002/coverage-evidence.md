# Coverage Evidence: Iteration 002

**Schema**: v1
**Reviewed**: 2026-06-08
**Overall Verdict**: accepted

Reviewer note: the deliverable-test evidence (commands + exit codes) is recorded in
[review-report.yml](./review-report.yml) claim_ledger. Iteration-002 suites: HandoverStore (15),
HandoverValidation (6), SessionEndHandover (10), LauncherIntegration (5); the full bootstrap suite
(12 files) is green; PSScriptAnalyzer clean. The auto-populated framework rows below are the
scaffolder default, not the iteration-002 deliverable evidence.

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **6 completed task(s)**, but the git diff against baseline `64bc0cb7702b8d36bce187d743cf4d0f015dbea5` contains **20 file(s)**.
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
> 1. Verify implementation is committed: `git diff 64bc0cb7702b8d36bce187d743cf4d0f015dbea5...HEAD --stat`
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
| & '.\\tests\\integration\\quality-profile-foundation.ps1' | pass | 1 | 0 | 00:00:04.8738286 | 0 | PASS: Quality profile foundation scaffold and Phase 1/Phase 2 planning contracts expose versioned quality assets, bounded hardening metadata, preserve local overrides, and define recognized-stack/custom-composition expectations |
| & '.\\tests\\integration\\mechanical-findings-contract.ps1' | pass | 1 | 0 | 00:00:02.8053293 | 0 | PASS: Mechanical findings contract fixtures keep the Phase 1 rule set schema-compliant and make demoted rules remain visible with disposition references |
| & '.\\tests\\integration\\quality-evidence-governance.ps1' | pass | 1 | 0 | 00:00:33.6825915 | 0 | PASS: Quality evidence governance regressions passed. |
| & '.\\tests\\integration\\process-quality-scorer.ps1' | pass | 1 | 0 | 00:00:02.2828962 | 0 | PASS: Process scorer returns structured artifact and phase adherence results |
| & '.\\tests\\integration\\process-quality-report.ps1' | pass | 1 | 0 | 00:00:02.0445524 | 0 | PASS: Process scorer writes a Markdown report with process and deferred outcome sections |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Tool: unknown

## Coverage-to-Requirements

| Requirement | Test Files / Commands |
| ----------- | --------------------- |
| FR-009 | specs/174-hook-driven-session-bootstrap/spec.md, tests/bootstrap/HandoverStore.Tests.ps1, tests/bootstrap/HandoverValidation.Tests.ps1, tests/bootstrap/LauncherIntegration.Tests.ps1, tests/bootstrap/SessionEndHandover.Tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-010 | specs/174-hook-driven-session-bootstrap/spec.md, tests/bootstrap/HandoverStore.Tests.ps1, tests/bootstrap/HandoverValidation.Tests.ps1, tests/bootstrap/LauncherIntegration.Tests.ps1, tests/bootstrap/SessionEndHandover.Tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-017 | specs/174-hook-driven-session-bootstrap/spec.md, tests/bootstrap/HandoverStore.Tests.ps1, tests/bootstrap/HandoverValidation.Tests.ps1, tests/bootstrap/LauncherIntegration.Tests.ps1, tests/bootstrap/SessionEndHandover.Tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-021 | specs/174-hook-driven-session-bootstrap/spec.md, tests/bootstrap/HandoverStore.Tests.ps1, tests/bootstrap/HandoverValidation.Tests.ps1, tests/bootstrap/LauncherIntegration.Tests.ps1, tests/bootstrap/SessionEndHandover.Tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-006 | specs/174-hook-driven-session-bootstrap/spec.md, tests/bootstrap/HandoverStore.Tests.ps1, tests/bootstrap/HandoverValidation.Tests.ps1, tests/bootstrap/LauncherIntegration.Tests.ps1, tests/bootstrap/SessionEndHandover.Tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-007 | specs/174-hook-driven-session-bootstrap/spec.md, tests/bootstrap/HandoverStore.Tests.ps1, tests/bootstrap/HandoverValidation.Tests.ps1, tests/bootstrap/LauncherIntegration.Tests.ps1, tests/bootstrap/SessionEndHandover.Tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |

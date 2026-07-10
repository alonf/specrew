# Coverage Evidence: Iteration 001

**Schema**: v1
**Reviewed**: 2026-07-10
**Overall Verdict**: accepted

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **6 completed task(s)**, but the git diff against baseline `62ff9d6473405ecc8433d6609b6d50c3be5459af` contains **84 file(s)**.
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
> 1. Verify implementation is committed: `git diff 62ff9d6473405ecc8433d6609b6d50c3be5459af...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Test Strategy

- Implementation briefing: toolchain pins moved with probe-first evidence (T001-T003); self-leak firewall landed blocking with paired fixtures (T004-T006). Every honesty invariant carries a paired test (NFR-007).
- Review-time strategy: use `reviewer.test_commands` when configured; otherwise record `not_executed` explicitly and keep the signal visible in closeout output.

## Tests Run

| Command | Result | Pass Count | Fail Count | Duration | Exit Code | Notes |
| ------- | ------ | ---------- | ---------- | -------- | --------- | ----- |
| & '.\\tests\\integration\\quality-profile-foundation.ps1' | pass | 1 | 0 | 00:00:01.5878923 | 0 | PASS: Quality profile foundation scaffold and Phase 1/Phase 2 planning contracts expose versioned quality assets, bounded hardening metadata, preserve local overrides, and define recognized-stack/custom-composition expectations |
| & '.\\tests\\integration\\mechanical-findings-contract.ps1' | pass | 1 | 0 | 00:00:00.4332616 | 0 | PASS: Mechanical findings contract fixtures keep the Phase 1 rule set schema-compliant and make demoted rules remain visible with disposition references |
| & '.\\tests\\integration\\quality-evidence-governance.ps1' | pass | 1 | 0 | 00:00:12.8685789 | 0 | PASS: Quality evidence governance regressions passed. |
| & '.\\tests\\integration\\process-quality-scorer.ps1' | pass | 1 | 0 | 00:00:00.9332674 | 0 | PASS: Process scorer returns structured artifact and phase adherence results |
| & '.\\tests\\integration\\process-quality-report.ps1' | pass | 1 | 0 | 00:00:00.8257661 | 0 | PASS: Process scorer writes a Markdown report with process and deferred outcome sections |
| pwsh -File tests/unit/self-leak-lint.tests.ps1 | pass | 18 | 0 | ~00:01:30 | 0 | Paired per-class red/green + annotation semantics + exit-2 loud + surface enumeration + real-repo born-clean guard |
| pwsh -File tests/integration/version-info-states.tests.ps1 | pass | 1 | 0 | ~00:00:20 | 0 | Single-tested-pin window lock (Test 8 updated per I2) |
| pwsh -File tests/integration/bootstrap-asset-blocker-recovery.ps1 | pass | 1 | 0 | ~00:00:40 | 0 | Repair path asserts v0.12.9; shims at pinned versions |
| pwsh -File tests/integration/squad-duplicate-rows.tests.ps1 | pass | 1 | 0 | ~00:02:00 | 0 | REAL specrew init on pinned toolchain (specify 0.12.9 --integration + squad 0.11.0) - the live no-extensions fixture |
| pwsh -File tests/integration/deployed-bootstrap-floor.tests.ps1 | pass | 1 | 0 | ~00:01:00 | 0 | Deployed-surface round-trip green |
| pwsh -File tests/integration/command-surface-deploy.tests.ps1 | pass | 1 | 0 | ~00:00:30 | 0 | Per-host command-surface deploy green |
| pwsh -File scripts/internal/lint-self-leak.ps1 -ProjectRoot . | pass | 198 | 0 | ~00:00:10 | 0 | Deploy surface GREEN: 198 shipped files, 25 annotated hits with recorded reasons |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Tool: unknown

## Coverage-to-Requirements

| Requirement | Test Files / Commands |
| ----------- | --------------------- |
| FR-033 | tests/unit/self-leak-lint.tests.ps1 (Tests 2-9: per-class red, surface==FileList, born-clean guard); .github/workflows/specrew-ci.yml self-leak-lint job |
| FR-034 | tests/unit/self-leak-lint.tests.ps1 (Test 7: red output names escape + docs/methodology/self-leak-firewall.md) |
| FR-037 | tests/unit/self-leak-lint.tests.ps1 (Tests 1, 3, 4: shape/classes/compile, annotation semantics per file kind, missing-reason red) |
| FR-038 | iterations/001/quality/toolchain-probe-evidence.md (probe transcript); tests/integration/squad-duplicate-rows.tests.ps1 (real init on 0.12.9); version-info-states; bootstrap-asset-blocker-recovery; deployed-bootstrap-floor; command-surface-deploy |
| FR-039 | squad 0.11.0 scratch probe (evidence file); tests/integration/squad-duplicate-rows.tests.ps1; version-info-states |

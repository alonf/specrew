# Coverage Evidence: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-24
**Overall Verdict**: accepted

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **6 completed task(s)**, but the git diff against baseline `7266978a3b6e0cf620d104ba3c6734451667f959` contains **37 file(s)**.
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
> 1. Verify implementation is committed: `git diff 7266978a3b6e0cf620d104ba3c6734451667f959...HEAD --stat`
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
| & '.\\tests\\integration\\quality-profile-foundation.ps1' | pass | 1 | 0 | 00:00:03.5641632 | 0 | PASS: Quality profile foundation scaffold and Phase 1/Phase 2 planning contracts expose versioned quality assets, bounded hardening metadata, preserve local overrides, and define recognized-stack/custom-composition expectations |
| & '.\\tests\\integration\\mechanical-findings-contract.ps1' | pass | 1 | 0 | 00:00:01.0388535 | 0 | PASS: Mechanical findings contract fixtures keep the Phase 1 rule set schema-compliant and make demoted rules remain visible with disposition references |
| & '.\\tests\\integration\\quality-evidence-governance.ps1' | pass | 1 | 0 | 00:00:31.8111102 | 0 | PASS: Quality evidence governance regressions passed. |
| & '.\\tests\\integration\\process-quality-scorer.ps1' | pass | 1 | 0 | 00:00:02.1233833 | 0 | PASS: Process scorer returns structured artifact and phase adherence results |
| & '.\\tests\\integration\\process-quality-report.ps1' | pass | 1 | 0 | 00:00:01.9744416 | 0 | PASS: Process scorer writes a Markdown report with process and deferred outcome sections |
| pwsh -File ./tests/integration/host-registry.tests.ps1 | pass | 24 | 0 | n/a | 0 | Slice A: registry discovers host packages; unknown-host and case-variant inputs rejected at the validation seam (FR-001/SC-002). |
| pwsh -File ./tests/integration/host-package-filelist.tests.ps1 | pass | 8 | 0 | n/a | 0 | Slice A: generate/check FileList parity, missing-file failure, Windows/Unix path determinism (FR-002/SC-004). |
| pwsh -File ./tests/integration/host-coupling-firewall.tests.ps1 | pass | 8 | 0 | n/a | 0 | Slice A: clean-tree pass, planted-literal fails through production scanner, allow-list bounded 11->8 (FR-003/FR-004/SC-003). |
| pwsh -File ./tests/integration/multi-host-launch-path.tests.ps1 | pass | 25 | 0 | n/a | 0 | Slice A: registry-driven launch paths across registered hosts (FR-001). |
| pwsh -File ./tests/integration/publish-module-harness.tests.ps1 | pass | 11 | 0 | n/a | 0 | Slice A: FileList-faithful prepublish harness includes every generated host-package file (FR-019/SC-010). |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Tool: unknown

## Coverage-to-Requirements

| Requirement | Test Files / Commands |
| ----------- | --------------------- |
| FR-011 | scripts/internal/test-publish-harness.ps1, specs/200-devin-cli-host/spec.md, tests/integration/host-coupling-firewall.tests.ps1, tests/integration/host-package-filelist.tests.ps1, tests/integration/host-registry.tests.ps1, tests/integration/multi-host-launch-path.tests.ps1, tests/integration/publish-module-harness.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-012 | scripts/internal/test-publish-harness.ps1, specs/200-devin-cli-host/spec.md, tests/integration/host-coupling-firewall.tests.ps1, tests/integration/host-package-filelist.tests.ps1, tests/integration/host-registry.tests.ps1, tests/integration/multi-host-launch-path.tests.ps1, tests/integration/publish-module-harness.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-001 | scripts/internal/test-publish-harness.ps1, specs/200-devin-cli-host/spec.md, tests/integration/host-coupling-firewall.tests.ps1, tests/integration/host-package-filelist.tests.ps1, tests/integration/host-registry.tests.ps1, tests/integration/multi-host-launch-path.tests.ps1, tests/integration/publish-module-harness.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-002 | scripts/internal/test-publish-harness.ps1, specs/200-devin-cli-host/spec.md, tests/integration/host-coupling-firewall.tests.ps1, tests/integration/host-package-filelist.tests.ps1, tests/integration/host-registry.tests.ps1, tests/integration/multi-host-launch-path.tests.ps1, tests/integration/publish-module-harness.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-003 | scripts/internal/test-publish-harness.ps1, specs/200-devin-cli-host/spec.md, tests/integration/host-coupling-firewall.tests.ps1, tests/integration/host-package-filelist.tests.ps1, tests/integration/host-registry.tests.ps1, tests/integration/multi-host-launch-path.tests.ps1, tests/integration/publish-module-harness.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-004 | scripts/internal/test-publish-harness.ps1, specs/200-devin-cli-host/spec.md, tests/integration/host-coupling-firewall.tests.ps1, tests/integration/host-package-filelist.tests.ps1, tests/integration/host-registry.tests.ps1, tests/integration/multi-host-launch-path.tests.ps1, tests/integration/publish-module-harness.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-019 | scripts/internal/test-publish-harness.ps1, specs/200-devin-cli-host/spec.md, tests/integration/host-coupling-firewall.tests.ps1, tests/integration/host-package-filelist.tests.ps1, tests/integration/host-registry.tests.ps1, tests/integration/multi-host-launch-path.tests.ps1, tests/integration/publish-module-harness.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |

# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-07-10
**Baseline Ref**: 62ff9d6473405ecc8433d6609b6d50c3be5459af
**Test-to-Code Ratio**: 3:14

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

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .github/agents/squad.agent.md | 2 | 2 | T001, T002, T003, T004, T005, T006 | Implementer |
| .github/workflows/specrew-ci.yml | 17 | 2 | T001, T002, T003, T004, T005, T006 | Implementer |
| .github/workflows/specrew-confidence-lane.yml | 2 | 2 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/data/self-leak-deny-list.json | 88 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/extension.yml | 1 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/knowledge/design-lenses/README.md | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/prompts/coordinator-decision-guidance.md | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/prompts/coordinator-response.md | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/refocus/feature-closeout.md | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/refocus/general.md | 0 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/refocus/review-signoff.md | 0 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1 | 3 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1 | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 | 5 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1 | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/skills/specrew-update/SKILL.md | 3 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specify/extensions/specrew-speckit/templates/lifecycle/software-feature-lifecycle.md | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specrew/review/inline/20260709T224852258-bd274a8d/findings-result.json | 46 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specrew/review/inline/20260709T224852258-bd274a8d/redacted-evidence.json | 11 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specrew/review/inline/20260709T224852258-bd274a8d/review-thread.json | 46 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specrew/review/inline/20260709T231707847-e8c50739/findings-result.json | 27 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specrew/review/inline/20260709T231707847-e8c50739/redacted-evidence.json | 11 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specrew/review/inline/20260709T231707847-e8c50739/review-thread.json | 25 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specrew/review/inline/20260709T231951205-9ed8b672/findings-result.json | 25 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specrew/review/inline/20260709T231951205-9ed8b672/redacted-evidence.json | 11 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specrew/review/inline/20260709T231951205-9ed8b672/review-thread.json | 25 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specrew/review/inline/20260709T232909754-a51accbc/findings-result.json | 25 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specrew/review/inline/20260709T232909754-a51accbc/redacted-evidence.json | 11 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .specrew/review/inline/20260709T232909754-a51accbc/review-thread.json | 25 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .squad/active-features.yml | 5 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .squad/decisions.md | 45 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .squad/events/lifecycle-events.jsonl | 5 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| .squad/identity/now.md | 7 | 7 | T001, T002, T003, T004, T005, T006 | Implementer |
| Specrew.psd1 | 1 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| docs/methodology/self-leak-firewall.md | 85 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/data/self-leak-deny-list.json | 88 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/extension.yml | 1 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/knowledge/design-lenses/README.md | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/prompts/coordinator-decision-guidance.md | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/prompts/coordinator-response.md | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/refocus/feature-closeout.md | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/refocus/general.md | 0 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/refocus/review-signoff.md | 0 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1 | 3 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1 | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 | 5 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/scripts/sync-boundary-state.ps1 | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/scripts/validate-governance.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/specrew-update/SKILL.md | 3 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| extensions/specrew-speckit/templates/lifecycle/software-feature-lifecycle.md | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| scripts/init/preflight.ps1 | 2 | 2 | T001, T002, T003, T004, T005, T006 | Implementer |
| scripts/internal/lint-self-leak.ps1 | 197 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| scripts/internal/supported-versions.yml | 6 | 6 | T001, T002, T003, T004, T005, T006 | Implementer |
| scripts/specrew-init.ps1 | 21 | 20 | T001, T002, T003, T004, T005, T006 | Implementer |
| scripts/specrew-update.ps1 | 3 | 3 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/contracts/198-beta2-hardening.md | 90 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/contracts/mechanical-findings.schema.json | 77 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/data-model.md | 139 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/gates/design-analysis-001.md | 32 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/iterations/001/design-analysis.md | 307 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/iterations/001/drift-log.md | 73 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/iterations/001/lens-applicability.json | 24 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/iterations/001/plan.md | 87 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/iterations/001/quality/hardening-gate.md | 40 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/iterations/001/quality/toolchain-probe-evidence.md | 104 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/iterations/001/state.md | 41 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/plan.md | 254 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/quickstart.md | 38 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/review-diagrams.md | 100 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| specs/198-beta2-hardening/tasks.md | 95 | 0 | T001, T002, T003, T004, T005, T006 | Implementer |
| templates/github/workflows/specrew-ci.yml | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| templates/github/workflows/specrew-project-sync.yml | 2 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| templates/squad/agents/laforge/history.md | 1 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| templates/squad/agents/picard/history.md | 1 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| templates/squad/agents/retro-facilitator/history.md | 1 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| templates/squad/agents/spec-steward/history.md | 1 | 1 | T001, T002, T003, T004, T005, T006 | Implementer |
| templates/squad/agents/worf/history.md | 2 | 2 | T001, T002, T003, T004, T005, T006 | Implementer |
| templates/squad/identity/now.md | 16 | 53 | T001, T002, T003, T004, T005, T006 | Implementer |
| tests/integration/bootstrap-asset-blocker-recovery.ps1 | 7 | 7 | T004 | Implementer |
| tests/integration/version-info-states.tests.ps1 | 15 | 11 | T004 | Implementer |
| tests/unit/self-leak-lint.tests.ps1 | 171 | 0 | T004 | Implementer |

## Public-API Delta

### Added

- Read-SelfLeakDenyList (scripts/internal/lint-self-leak.ps1)
- Get-SelfLeakScanSurface (scripts/internal/lint-self-leak.ps1)
- Test-SelfLeakAnnotated (scripts/internal/lint-self-leak.ps1)
- Write-Pass (tests/unit/self-leak-lint.tests.ps1)
- Write-Fail (tests/unit/self-leak-lint.tests.ps1)
- Invoke-Lint (tests/unit/self-leak-lint.tests.ps1)
- New-Fixture (tests/unit/self-leak-lint.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- specs/198-beta2-hardening/iterations/001/design-analysis.md (307 changed lines)
- specs/198-beta2-hardening/plan.md (254 changed lines)

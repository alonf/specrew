# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-31
**Baseline Ref**: add50d87c08cfe4fb14dcdfe074f0b599eaa7713
**Test-to-Code Ratio**: 6:0

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **18 completed task(s)**, but the git diff against baseline `add50d87c08cfe4fb14dcdfe074f0b599eaa7713` contains **34 file(s)**.
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
> 1. Verify implementation is committed: `git diff add50d87c08cfe4fb14dcdfe074f0b599eaa7713...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .github/agents/speckit.analyze.agent.md | 14 | 0 | T001, T006, T010, T016, T017 | Planner |
| .github/agents/speckit.checklist.agent.md | 14 | 0 | T001, T006, T010, T016, T017 | Planner |
| .github/agents/speckit.plan.agent.md | 13 | 0 | T001, T006, T010, T016, T017 | Planner |
| .github/agents/speckit.tasks.agent.md | 13 | 0 | T001, T006, T010, T016, T017 | Planner |
| .github/agents/speckit.taskstoissues.agent.md | 14 | 0 | T001, T006, T010, T016, T017 | Planner |
| .github/prompts/speckit.analyze.prompt.md | 9 | 0 | T001, T006, T010, T016, T017 | Planner |
| .github/prompts/speckit.checklist.prompt.md | 9 | 0 | T001, T006, T010, T016, T017 | Planner |
| .github/prompts/speckit.taskstoissues.prompt.md | 7 | 0 | T001, T006, T010, T016, T017 | Planner |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md | 8 | 0 | T001, T006, T010, T016, T017 | Planner |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md | 11 | 0 | T001, T006, T010, T016, T017 | Planner |
| .specify/extensions/specrew-speckit/extension.yml | 19 | 0 | T001, T006, T010, T016, T017 | Planner |
| .squad/decisions.md | 9 | 0 | T001, T006, T010, T016, T017 | Planner |
| .squad/identity/now.md | 4 | 4 | T001, T006, T010, T016, T017 | Planner |
| README.md | 10 | 0 | T001, T006, T010, T016, T017 | Planner |
| docs/user-guide.md | 10 | 0 | T001, T006, T010, T016, T017 | Planner |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md | 8 | 0 | T001, T006, T010, T016, T017 | Planner |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md | 11 | 0 | T001, T006, T010, T016, T017 | Planner |
| extensions/specrew-speckit/extension.yml | 19 | 0 | T001, T006, T010, T016, T017 | Planner |
| specs/054-activate-spec-surfaces/contracts/mechanical-findings.schema.json | 77 | 0 | T001, T006, T010, T016, T017 | Planner |
| specs/054-activate-spec-surfaces/iterations/001/drift-log.md | 73 | 0 | T001, T006, T010, T016, T017 | Planner |
| specs/054-activate-spec-surfaces/iterations/001/plan.md | 19 | 19 | T001, T006, T010, T016, T017 | Planner |
| specs/054-activate-spec-surfaces/iterations/001/quality/hardening-gate.md | 50 | 0 | T001, T006, T010, T016, T017 | Planner |
| specs/054-activate-spec-surfaces/iterations/001/quality/mechanical-findings.json | 11 | 0 | T001, T006, T010, T016, T017 | Planner |
| specs/054-activate-spec-surfaces/iterations/001/quality/quality-evidence.md | 57 | 0 | T001, T006, T010, T016, T017 | Planner |
| specs/054-activate-spec-surfaces/iterations/001/quality/trap-reapplication.md | 15 | 0 | T001, T006, T010, T016, T017 | Planner |
| specs/054-activate-spec-surfaces/iterations/001/state.md | 35 | 0 | T001, T006, T010, T016, T017 | Planner |
| specs/054-activate-spec-surfaces/iterations/001/tasks-progress.yml | 113 | 0 | T001, T006, T010, T016, T017 | Planner |
| specs/054-activate-spec-surfaces/tasks.md | 19 | 19 | T001, T006, T010, T016, T017 | Planner |
| tests/integration/discovery-surface-contract.ps1 | 86 | 0 | T003, T004, T005, T009, T013, T018 | Reviewer |
| tests/integration/lifecycle-boundary-sync.tests.ps1 | 65 | 0 | T003, T004, T005, T009, T013, T018 | Reviewer |
| tests/integration/slash-command-coexistence.tests.ps1 | 17 | 0 | T003, T004, T005, T009, T013, T018 | Reviewer |
| tests/integration/slash-command-discovery.tests.ps1 | 29 | 0 | T003, T004, T005, T009, T013, T018 | Reviewer |
| tests/integration/slash-command-routing.tests.ps1 | 17 | 0 | T003, T004, T005, T009, T013, T018 | Reviewer |
| tests/integration/validation-contract-lane.ps1 | 1 | 0 | T003, T004, T005, T009, T013, T018 | Reviewer |

## Public-API Delta

### Added

- Write-Pass (tests/integration/discovery-surface-contract.ps1)
- Write-Fail (tests/integration/discovery-surface-contract.ps1)
- Assert-True (tests/integration/discovery-surface-contract.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none

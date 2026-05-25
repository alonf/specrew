# Code Map: Iteration 009

**Schema**: v1
**Reviewed**: 2026-05-25
**Baseline Ref**: 7773aa12
**Test-to-Code Ratio**: 1:1

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **4 completed task(s)**, but the git diff against baseline `7773aa12` contains **43 file(s)**.
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
> 1. Verify implementation is committed: `git diff 7773aa12...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/extensions/specrew-speckit/squad-templates/agents/implementer/charter.md | 3 | 1 | T001, T002, T003, T004 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/agents/planner/charter.md | 3 | 1 | T001, T002, T003, T004 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/agents/retro-facilitator/charter.md | 3 | 1 | T001, T002, T003, T004 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md | 3 | 1 | T001, T002, T003, T004 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/agents/spec-steward/charter.md | 3 | 1 | T001, T002, T003, T004 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md | 3 | 2 | T001, T002, T003, T004 | Implementer |
| docs/getting-started.md | 8 | 3 | T001, T002, T003, T004 | Implementer |
| docs/user-guide.md | 8 | 5 | T001, T002, T003, T004 | Implementer |
| extensions/specrew-speckit/squad-templates/agents/implementer/charter.md | 3 | 1 | T001, T002, T003, T004 | Implementer |
| extensions/specrew-speckit/squad-templates/agents/planner/charter.md | 3 | 1 | T001, T002, T003, T004 | Implementer |
| extensions/specrew-speckit/squad-templates/agents/retro-facilitator/charter.md | 3 | 1 | T001, T002, T003, T004 | Implementer |
| extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md | 3 | 1 | T001, T002, T003, T004 | Implementer |
| extensions/specrew-speckit/squad-templates/agents/spec-steward/charter.md | 3 | 1 | T001, T002, T003, T004 | Implementer |
| extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md | 3 | 2 | T001, T002, T003, T004 | Implementer |
| hosts/_registry.ps1 | 19 | 4 | T001, T002, T003, T004 | Implementer |
| hosts/antigravity/host.psd1 | 1 | 0 | T001, T002, T003, T004 | Implementer |
| hosts/claude/host.psd1 | 1 | 0 | T001, T002, T003, T004 | Implementer |
| hosts/codex/host.psd1 | 1 | 0 | T001, T002, T003, T004 | Implementer |
| hosts/copilot/host.psd1 | 1 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/closeout-dashboard.md | 4 | 4 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/current-architecture.md | 15 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/009/code-map.md | 40 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/009/drift-log.md | 12 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/009/plan.md | 76 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/009/pr-review-resolution.md | 20 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/009/retro.md | 79 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/009/review.md | 44 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/009/scope.md | 35 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/009/state.md | 48 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/011/code-map.md | 51 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/011/coverage-evidence.md | 58 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/011/dashboard.md | 38 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/011/dependency-report.md | 48 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/011/drift-log.md | 13 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/011/plan.md | 80 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/011/pr-review-resolution.md | 20 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/011/retro.md | 76 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/011/review-diagrams.md | 45 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/011/review.md | 46 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/011/reviewer-index.md | 53 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/011/scope.md | 35 | 0 | T001, T002, T003, T004 | Implementer |
| specs/044-per-host-architecture-refactor/iterations/011/state.md | 50 | 0 | T001, T002, T003, T004 | Implementer |
| tests/integration/host-registry.tests.ps1 | 15 | 2 | T001 | Implementer |

## Public-API Delta

### Added

- none

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none

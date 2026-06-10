# Code Map: Iteration 002

**Schema**: v1
**Reviewed**: 2026-06-10
**Baseline Ref**: 96ded099a4e29db56c8e26de441af9da13896db4
**Test-to-Code Ratio**: 2:1

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **9 completed task(s)**, but the git diff against baseline `96ded099a4e29db56c8e26de441af9da13896db4` contains **26 file(s)**.
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
> 1. Verify implementation is committed: `git diff 96ded099a4e29db56c8e26de441af9da13896db4...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._
>
> **Reviewed + JUSTIFIED as benign (see review.md Notes)**: all 26 files are committed (96ded099..da7a0129); one task legitimately touches many files (the conduct turn updates the template + 4 deployed host copies + 4 `.specify` mirrors; release-prep touches the FileList + version triple + CHANGELOG). No uncommitted or unexplained source change; do NOT re-run with `-Force` (known ShouldProcess defect).

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .agents/skills/specrew-design-workshop/SKILL.md | 41 | 1 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| .claude/skills/specrew-design-workshop/SKILL.md | 41 | 1 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| .cursor/rules/specrew-design-workshop/SKILL.md | 41 | 1 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| .github/skills/specrew-design-workshop/SKILL.md | 41 | 1 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/agents/implementer/charter.md | 9 | 0 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/agents/planner/charter.md | 1 | 0 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/skills/code-rules.md | 93 | 0 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/skills/design-workshop.md | 41 | 1 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| .specrew/config.yml | 1 | 1 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| CHANGELOG.md | 7 | 3 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| Specrew.psd1 | 6 | 1 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| extensions/specrew-speckit/extension.yml | 1 | 1 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| extensions/specrew-speckit/knowledge/design-lenses/code-implementation.md | 32 | 0 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| extensions/specrew-speckit/squad-templates/agents/implementer/charter.md | 9 | 0 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| extensions/specrew-speckit/squad-templates/agents/planner/charter.md | 1 | 0 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/code-rules.md | 93 | 0 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/design-workshop.md | 41 | 1 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| scripts/internal/code-implementation-lens.ps1 | 8 | 3 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| specs/177-software-development-rules-lens/iterations/002/dogfood-report.md | 105 | 0 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| specs/177-software-development-rules-lens/iterations/002/drift-log.md | 72 | 0 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| specs/177-software-development-rules-lens/iterations/002/plan.md | 98 | 0 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| specs/177-software-development-rules-lens/iterations/002/quality/hardening-gate.md | 36 | 0 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| specs/177-software-development-rules-lens/iterations/002/quality/mechanical-findings.json | 11 | 0 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| specs/177-software-development-rules-lens/iterations/002/state.md | 58 | 0 | T010, T011, T012, T013, T014, T015, T016, T018 | Implementer |
| tests/integration/code-rules-skill-multihost.tests.ps1 | 79 | 0 | T015, T016, T017 | Implementer |
| tests/unit/code-implementation-lens.tests.ps1 | 20 | 0 | T015, T016, T017 | Implementer |

## Public-API Delta

### Added

- Write-Pass (tests/integration/code-rules-skill-multihost.tests.ps1)
- Write-Fail (tests/integration/code-rules-skill-multihost.tests.ps1)
- Assert-True (tests/integration/code-rules-skill-multihost.tests.ps1)
- Assert-Match (tests/integration/code-rules-skill-multihost.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none

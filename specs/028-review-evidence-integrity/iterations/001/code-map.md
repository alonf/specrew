# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 
**Baseline Ref**: aa654510f22bce82e23f21baa1ced85abc97a3b8
**Test-to-Code Ratio**: 1:3

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
> 
> This iteration's task tracking declares **5 completed task(s)**, but the git diff against baseline `aa654510f22bce82e23f21baa1ced85abc97a3b8` contains **14 file(s)**.
> 
> **Severity**: WARNING  
> **Implication**: Review evidence may be incomplete or misleading.
> 
> **Possible causes**:
> - Implementation work was not committed before scaffolding review artifacts
> - Task status markers in plan.md or review.md do not match actual progress
> - Baseline reference in state.md is stale or incorrect
> 
> **Remediation**: 
> 1. Verify implementation is committed: `git diff aa654510f22bce82e23f21baa1ced85abc97a3b8...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
> 
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/feature.json | 1 | 2 | T004-T009, T010-T016, T017-T023, T024-T031 | Implementer |
| .specrew/last-start-prompt.md | 128 | 14 | T004-T009, T010-T016, T017-T023, T024-T031 | Implementer |
| .specrew/last-validator-summary.json | 3 | 3 | T004-T009, T010-T016, T017-T023, T024-T031 | Implementer |
| .specrew/start-context.json | 9 | 15 | T004-T009, T010-T016, T017-T023, T024-T031 | Implementer |
| .squad/agents/scribe/history.md | 28 | 0 | T004-T009, T010-T016, T017-T023, T024-T031 | Implementer |
| .squad/decisions.md | 193 | 0 | T004-T009, T010-T016, T017-T023, T024-T031 | Implementer |
| CHANGELOG.md | 2 | 0 | T004-T009, T010-T016, T017-T023, T024-T031 | Implementer |
| docs/user-guide.md | 24 | 0 | T004-T009, T010-T016, T017-T023, T024-T031 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 | 71 | 2 | T004-T009, T010-T016, T017-T023, T024-T031 | Implementer |
| extensions/specrew-speckit/scripts/shared-governance.ps1 | 92 | 0 | T004-T009, T010-T016, T017-T023, T024-T031 | Implementer |
| extensions/specrew-speckit/scripts/validate-governance.ps1 | 157 | 0 | T004-T009, T010-T016, T017-T023, T024-T031 | Implementer |
| proposals/073-review-evidence-integrity.md | 7 | 6 | T004-T009, T010-T016, T017-T023, T024-T031 | Implementer |
| proposals/INDEX.md | 3 | 3 | T004-T009, T010-T016, T017-T023, T024-T031 | Implementer |
| tests/README.md | 1 | 0 | T004-T009, T010-T016, T017-T023, T032-T050 | Implementer |

## Public-API Delta

### Added

- Test-FormMeaningParity (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-DeclaredCompletedTaskCount (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-PreReviewCommitGate (extensions/specrew-speckit/scripts/validate-governance.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none
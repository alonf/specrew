# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-06
**Baseline Ref**: 52602eded0aa17d28b768ae86073d212a9c56b05
**Test-to-Code Ratio**: 1:0

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **7 completed task(s)**, but the git diff against baseline `52602eded0aa17d28b768ae86073d212a9c56b05` contains **13 file(s)**.
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
> 1. Verify implementation is committed: `git diff 52602eded0aa17d28b768ae86073d212a9c56b05...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specrew/last-validator-summary.json | 12 | 0 | T001, T002, T003, T004, T005, T007 | Implementer |
| .squad/active-features.yml | 1 | 1 | T001, T002, T003, T004, T005, T007 | Implementer |
| .squad/decisions.md | 27 | 0 | T001, T002, T003, T004, T005, T007 | Implementer |
| .squad/events/lifecycle-events.jsonl | 3 | 0 | T001, T002, T003, T004, T005, T007 | Implementer |
| .squad/identity/now.md | 5 | 5 | T001, T002, T003, T004, T005, T007 | Implementer |
| specs/170-retire-evaluation-surface/contracts/mechanical-findings.schema.json | 77 | 0 | T001, T002, T003, T004, T005, T007 | Implementer |
| specs/170-retire-evaluation-surface/iterations/001/drift-log.md | 55 | 0 | T001, T002, T003, T004, T005, T007 | Implementer |
| specs/170-retire-evaluation-surface/iterations/001/plan.md | 92 | 0 | T001, T002, T003, T004, T005, T007 | Implementer |
| specs/170-retire-evaluation-surface/iterations/001/quality/hardening-gate.md | 32 | 0 | T001, T002, T003, T004, T005, T007 | Implementer |
| specs/170-retire-evaluation-surface/iterations/001/quality/mechanical-findings.json | 11 | 0 | T001, T002, T003, T004, T005, T007 | Implementer |
| specs/170-retire-evaluation-surface/iterations/001/quality/quality-evidence.md | 47 | 0 | T001, T002, T003, T004, T005, T007 | Implementer |
| specs/170-retire-evaluation-surface/iterations/001/state.md | 45 | 0 | T001, T002, T003, T004, T005, T007 | Implementer |
| specs/170-retire-evaluation-surface/spec.md | 1 | 1 | T001, T002, T003 | Implementer |

## Public-API Delta

### Added

- none

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none

## Form-vs-Meaning Gap — Explained (reviewer disposition: not a defect)

The warning above is expected for this iteration and is dispositioned as
explained: this was a verification-first iteration whose product implementation
PRE-DATES the task baseline (adoption snapshot 3b6a3e0d, committed at feature
creation). The 7 tasks were read-only verification runs; the 13 files in the
baseline..HEAD diff are lifecycle/evidence artifacts (iteration plan, state,
drift log, quality evidence, spec SC-004 reconciliation, governance ledger),
not untracked implementation. The implementation diff itself was reviewed
against the pre-adoption baseline b31345f4 (see review.md Phases 2/5/6).

## Code Surface (implementation delta, pre-adoption baseline b31345f4)

| Surface | Files | Nature |
| --- | --- | --- |
| Deleted public surface | evaluation/README.md, evaluation/report.md | stale artifacts removed |
| Moved test support | evaluation/scorers/process-scorer.ps1 -> tests/support/process-quality-scorer.ps1 | 99% rename; 1-line functional delta (default report path) |
| Test callers | tests/integration/{process-quality-scorer,process-quality-report,project-path-resolution-regression}.ps1 + multi-host-lifecycle-smoke.tests.ps1 | pure path-reference updates |
| Docs/instructions | docs/user-guide.md, docs/release-notes-v0.27.0.md, .github/copilot-instructions.md, .specrew/quality/known-traps.md | reference truthfulness edits |
| Validator mirrors | extensions/.../handoff-governance-validator.ps1 + .specify mirror | identical 1-line reference updates (diff-identical verified) |
| Squad surfaces | .squad/skills/process-quality-scoring/SKILL.md, templates/squad/agents/worf/history.md | path-reference updates |

**Hotspots**: none — no file exceeds a 1-line functional change outside pure renames/reference updates.

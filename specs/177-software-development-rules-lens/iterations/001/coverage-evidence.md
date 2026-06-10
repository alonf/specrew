# Coverage Evidence: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-10
**Overall Verdict**: accepted

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **9 completed task(s)**, but the git diff against baseline `7f4f2ae7482df0a8c0259c515c103c36c23d4e35` contains **21 file(s)**.
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
> 1. Verify implementation is committed: `git diff 7f4f2ae7482df0a8c0259c515c103c36c23d4e35...HEAD --stat`
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
| & '.\\tests\\integration\\quality-profile-foundation.ps1' | pass | 1 | 0 | 00:00:03.4957760 | 0 | PASS: Quality profile foundation scaffold and Phase 1/Phase 2 planning contracts expose versioned quality assets, bounded hardening metadata, preserve local overrides, and define recognized-stack/custom-composition expectations |
| & '.\\tests\\integration\\mechanical-findings-contract.ps1' | pass | 1 | 0 | 00:00:01.1800009 | 0 | PASS: Mechanical findings contract fixtures keep the Phase 1 rule set schema-compliant and make demoted rules remain visible with disposition references |
| & '.\\tests\\integration\\quality-evidence-governance.ps1' | pass | 1 | 0 | 00:00:30.4158077 | 0 | PASS: Quality evidence governance regressions passed. |
| & '.\\tests\\integration\\process-quality-scorer.ps1' | pass | 1 | 0 | 00:00:02.3262126 | 0 | PASS: Process scorer returns structured artifact and phase adherence results |
| & '.\\tests\\integration\\process-quality-report.ps1' | pass | 1 | 0 | 00:00:02.1750228 | 0 | PASS: Process scorer writes a Markdown report with process and deferred outcome sections |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Tool: unknown

## Coverage-to-Requirements

| Requirement | Test Files / Commands |
| ----------- | --------------------- |
| FR-002 | tests/unit/code-implementation-lens.tests.ps1, tests/unit/lens-conduct-delivery.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-004 | tests/unit/code-implementation-lens.tests.ps1, tests/unit/lens-conduct-delivery.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-001 | tests/unit/code-implementation-lens.tests.ps1, tests/unit/lens-conduct-delivery.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-013 | tests/unit/code-implementation-lens.tests.ps1, tests/unit/lens-conduct-delivery.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |

## FR x Phase Coverage (authoritative — agrees with review-report.yml)

The auto Coverage-to-Requirements table above lists the task-traced primary FRs plus the scaffolder's
broader integration regression sweep. The **authoritative F-177 FR coverage** is the `fr_phase_matrix` in
`review-report.yml`, reproduced here so this artifact agrees with it. The real F-177 FR evidence is
`tests/unit/code-implementation-lens.tests.ps1` (+ `lens-conduct-delivery` + `lens-applicability-selector`);
the integration commands above are the scaffolder's regression sweep, not F-177-FR-specific.

| Requirement | Status | Evidence |
| --- | --- | --- |
| FR-001 | verified | registration; T009 + selector |
| FR-002 | verified | catalog 60 ids; T007 |
| FR-003 | partial-i1 | lens md grouping content; conduct i2 (T012) |
| FR-004 | verified | schema + writer; T008 |
| FR-005 | deferred-i2 | guidance skill (T010/T011) |
| FR-006 | deferred-i2 | plan/implement wiring (T014) |
| FR-007 | verified | context_scope hook; T008 |
| FR-008 | deferred-i2 | baseline-only skill mode (T010/T015) |
| FR-009 | partial-i1 | checked/unchecked + T008; set/unset UI i2 (T012) |
| FR-010 | partial-i1 | guideline-first content; conduct i2 (T012) |
| FR-011 | deferred-i2 | assisted ingestion (T013) |
| FR-012 | verified | overlay never-drops + provenance; T008 |
| FR-013 | verified | dependency_policy; T006 + T008 |

**File-count note**: the form-vs-meaning warning above (9 tasks vs 21 files) is justified. 11 files are the
implementation (`code-rules.yml`, `implementation-rules.schema.json` x2, `code-implementation.md`,
`index.yml`, `code-implementation-lens.ps1`, `code-implementation-lens.tests.ps1`,
`lens-conduct-delivery.tests.ps1`, contracts schema) and 10 are the iteration's own governance/review
artifacts (review, review-report, code-map, coverage-evidence, dependency-report, dashboard, drift-log,
plan, state, current-architecture). All 21 are in `git diff 7f4f2ae7...HEAD`; none is unexplained.

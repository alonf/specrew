# Tasks: Retire Top-Level Evaluation Surface

**Feature**: 170-retire-evaluation-surface
**Plan**: `specs/170-retire-evaluation-surface/plan.md`
**Created**: 2026-06-06
**Capacity**: 2/20 story_points

## Overview

Single verification-first iteration. The implementation pre-exists as adoption
snapshot `3b6a3e0d`; each task either proves an FR empirically or records the
evidence the adoption skipped. Any gap a task finds is fixed inside that task
and re-verified before the task closes.

## Iteration 001: Verification, Gap-Fixing, and Evidence

### Phase 1: Structural Verification

| Task | Description | Traces | Effort (SP) | Owner |
| --- | --- | --- | --- | --- |
| T001 | Assert no tracked `evaluation/` path remains (`git ls-files evaluation/` empty) and the scorer exists at `tests/support/process-quality-scorer.ps1` with no other tracked copy. | FR-001, FR-002, SC-001 | 0.25 | Implementer |

### Phase 2: Empirical Test Runs

| Task | Description | Traces | Effort (SP) | Owner |
| --- | --- | --- | --- | --- |
| T002 | Run `tests/integration/process-quality-scorer.ps1`; require exit 0; capture run log. | FR-003, SC-002 | 0.25 | Implementer |
| T003 | Run `tests/integration/process-quality-report.ps1`; require exit 0; assert the generated report lands under untracked scratch `test-results/` space. | FR-004, SC-002 | 0.25 | Implementer |
| T004 | Run the multi-host lifecycle smoke suite (scorer-parse + forward-slash assertions) and `tests/integration/project-path-resolution-regression.ps1`; require pass. | FR-005, SC-003 | 0.25 | Implementer |

### Phase 3: Reference Truthfulness and History

| Task | Description | Traces | Effort (SP) | Owner |
| --- | --- | --- | --- | --- |
| T005 | Repo-wide `evaluation/` reference scan over active surfaces; classify every hit as retirement-wording or frozen-fixture; zero unexplained hits. | FR-006, SC-004 | 0.25 | Implementer |
| T006 | Verify audit trail (Proposal 169 on main `262325d3` + INDEX entry) and history immutability (`git diff main` empty for historical fixtures/specs paths). | FR-007, FR-008, SC-005 | 0.25 | Spec Steward |

### Phase 4: Evidence Consolidation

| Task | Description | Traces | Effort (SP) | Owner |
| --- | --- | --- | --- | --- |
| T007 | Run mechanical checks; consolidate all run logs/scan outputs into `iterations/001/quality/quality-evidence.md`; fix any gap surfaced by T001-T006 and re-run the affected check. | FR-001..FR-008 (evidence layer) | 0.5 | Implementer |

## Dependency Graph

- T001 -> T002, T003, T004 (structure must hold before runs are meaningful)
- T002, T003, T004, T005, T006 -> T007 (consolidation last)
- T005 and T006 are independent of T002-T004.

## Parallel Opportunities

T002/T003/T004 may run back-to-back in one session; T005/T006 may interleave.
No same-specialty parallel execution is warranted at this size.

## Quality Gates and Acceptance Criteria

### Before Implementation

- Iteration plan + hardening gate with `Overall Verdict: ready`.
- Human authorization for the tasks -> before-implement crossing.

### Implementation Complete

- T001-T007 done; every FR has recorded empirical evidence (exit codes, scan
  output, diff results) in `quality-evidence.md` — file presence is NOT
  acceptance (runtime-deliverable rule).

### Review Complete

- Reviewer artifacts present (code touched); SC-004 scan re-checked at review;
  drift log reconciled; no unexplained `evaluation/` reference anywhere active.

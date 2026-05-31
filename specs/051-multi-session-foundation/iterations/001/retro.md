# Retrospective: Iteration 001 — Session Mode Configuration & File Classification

**Schema**: v1
**Date**: 2026-05-31

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 0.5 | 0.5 | 0 |
| T002 | 0.5 | 0.5 | 0 |
| T003 | 0.5 | 0.5 | 0 |
| T004 | 1 | 1 | 0 |
| T005 | 0.5 | 0.5 | 0 |
| T006 | 0.5 | 0.5 | 0 |
| T007 | 0.5 | 0.5 | 0 |
| T008 | 0.5 | 0.5 | 0 |
| T009 | 1 | 1 | 0 |
| T010 | 1 | 1 | 0 |
| T011 | 0.5 | 0.5 | 0 |
| T012 | 0.5 | 0.5 | 0 |
| T013 | 0.5 | 0.5 | 0 |
| T014 | 0.5 | 0.5 | 0 |
| T015 | 0.5 | 0.5 | 0 |
| T016 | 0.5 | 0.5 | 0 |
| T017 | 0.5 | 0.5 | 0 |
| T018 | 0.5 | 0.5 | 0 |
| T019 | 0.5 | 0.5 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | ~done | high | + | Large pre-implement remediation: re-verification surfaced 2 blockers (missing artifacts, capacity overcommit) → authored 5 plan artifacts + 5-iteration restructure. Cost paid once; unblocked all downstream iterations. |
| Discovery/Spikes | 0 | 0 | 0 | No spikes; mechanisms pre-decided in research.md (R1-R7). |
| Implementation | ~8 SP | 8 SP | 0 | On estimate. Reused existing helpers (Set-YamlScalarValue pattern, dispatch idiom); no blockers. |
| Review | ~2 SP | 2 SP | 0 | Thorough structured review; one residue caught (quickstart D-002 path) + fixed. |
| Rework | ~1 SP | ~0 | - | No needs-work loops; D-002 resolved pre-code at a natural pause. |

## Drift Summary

- Total drift events: 2
- Resolved via spec update: 1 (D-001 capacity overcommit → honest re-estimate + Iter-2 split)
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 1 (D-002 plan-vs-codebase path convention → codebase idiom)

## What Went Well

- **Reviewer-verification re-check before any code** caught two real before-implement blockers that the tasks-boundary approval had passed: missing pre-implement artifacts, and a capacity summary that was form-correct but arithmetically false (62 stated vs 139 actual). Applying Props 145/140/142 to *planning* artifacts paid off.
- **TDD fail-first, against real surfaces:** both suites written red-first; T008 drives the real governance scaffold writer, T015 runs against a real temp git repo — no stubs (Shape-6 discipline).
- **Shape-9 arithmetic vigilance:** review.md states the explicit per-task SP sum (11.0) inline rather than trusting the summary.
- **Honest caveat disclosure:** the T011/T013 init-wiring coverage-edge was surfaced in coverage-evidence + review, not papered over.
- **Producer/consumer + coverage discipline:** coverage-evidence records the iteration-added test files as executed (closes the F-049 iter-5 / F-050 iter-2 coverage-drift trap).
- **FileList-omission guard:** every new `.ps1` registered in `Specrew.psd1` as created (the v0.27.3 / v0.28.0-beta.1 crash class).
- **Drift surfaced at natural pauses, not auto-corrected:** D-002 (path convention) raised for a human decision rather than silently following invented paths.

## What Didn't Go Well

- **Capacity overcommit reached the tasks boundary undetected (D-001):** the after-tasks gate checks FR↔task coverage but NOT `stated iteration total == summed per-task effort`, so a 2.2× envelope breach (62 vs 139 SP) was invisible until a manual sum at before-implement.
- **Plan invented script paths (D-002):** `config-management.ps1` / `specrew-cli.ps1` / `file-classification.ps1` didn't match the codebase idiom (`specrew.ps1` dispatch + `specrew-<cmd>.ps1` + `scripts/internal/`), forcing a path-reconciliation before implementation.
- **Recurring working-tree drift at every boundary:** auto-deploy churn on `.claude/agents/*.md` + `.squad/*` must be classified/parked at each boundary commit — a friction tax that repeats across iters 1/2a/2b/3 until iter-4 ships.

## Improvement Actions

1. Owner: methodology | Phase: next planning | Type: process+validator | Standardize the Shape-9 arithmetic-vigilance pattern (explicit per-task SP sum in review.md) AND pursue a capacity-truth validator rule (FAIL when a stated iteration total ≠ summed `[effort]`, or any iteration sum > 20 SP cap). Composes with the structured-reviewer proposal (145) + capacity-planning skill. Captured in memory `project-capacity-summary-truth-gap-2026-05-31`.
2. Owner: Implementer | Phase: small-fix slice | Type: implementation | Add an init-flow integration test asserting `.gitignore` + git-index state after a real `specrew init`, closing the disclosed T011/T013 coverage-edge.
3. Owner: Planner | Phase: roadmap | Type: sequencing | The per-boundary auto-deploy friction empirically validates iter-4 (items 9+10: identity split + brand-new worktree detection) priority. Open question for iter-2a planning: would moving iter-4 earlier reduce the friction tax paid across 2a/2b/3? Record the decision.
4. Owner: methodology | Phase: cross-Crew | Type: process | F-051 used working-tree *classification* (state.md table) where F-054 used *parking*; both honestly address Shape 5 when classification is genuine, but a single convention would improve parallel-Crew consistency. Don't action mid-feature; decide at a consolidation pass.

## Calibration Suggestion

- Suggested capacity adjustment: keep the honest re-estimate rubric (F-054-anchored ~0.5 SP/task baseline + justified code premium); 0 variance this iteration validates it.
- Rationale: every task landed exactly on its re-estimated effort (avg variance 0); the inflated original markup (1.43 SP/task) was the anomaly, now corrected. Standardize the rubric for iter-2a estimation.

## Notes

- This artifact was scaffolded from plan.md, state.md, drift-log.md, and review.md for Squad's built-in Retrospective ceremony.
- Replace all TBD placeholders with evidence from the completed iteration before marking the retro phase complete.

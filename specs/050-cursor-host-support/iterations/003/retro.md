# Retrospective: Iteration 003

**Schema**: v1
**Date**: 2026-05-30

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T014 | 1 | 1 | 0 |
| T015 | 1 | 1 | 0 |
| T016 | 1 | 1 | 0 |

**Average variance**: 0. Docs + manual smoke estimated accurately.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done | done | 0 | Small docs slice. |
| Discovery/Spikes | 0 | 0 | 0 | None. |
| Implementation | 3 | 3 | 0 | 2 doc files + the human live smoke. |
| Review | ~0.5 | ~0.5 | 0 | Clean — no DECLINE this iteration (proactive disposition + markdownlint pre-commit). |
| Rework | buffer | 0 | — | None needed. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- **The live-Cursor smoke (T016) PASSED** — `specrew start --host cursor` launches cursor-agent interactively, reads AGENTS.md, begins specify. This is real end-to-end evidence that the whole feature works in a live Cursor session, not just unit/integration assertions (SC-001/005 satisfied).
- **markdownlint pre-commit caught the one defect** (a sparse table row left with 5 cells after a scripted 6-column expansion) before it reached review — the F-033 gate did its job.
- **Cleanest iteration of the three**: no review DECLINE, because the recurring lessons from iters 001-002 were applied proactively (form-vs-meaning dispositioned up front; review.md kept clean; full markdownlint run before commit).
- Docs are comprehensive: five-host counts, host table, launch examples, the full flag/capability/charter tables gained a Cursor column, and a dedicated interaction-model subsection explains the no-slash-palette model.

## What Didn't Go Well

- **Scripted markdown table column-expansion missed a sparse row.** Adding a Cursor column to the flag-translation matrix updated the data rows but not the mostly-empty `--autonomous` row, which kept 5 cells against a 6-column header. Caught by markdownlint, but the lesson: when widening a table by script, update EVERY row including the sparse/placeholder ones (or assert column-count after).

## Improvement Actions

1. Owner: Crew coordinator | Phase: docs edits | Type: process | Expected effect: after any scripted markdown-table column change, run markdownlint immediately (don't wait for the boundary gate) and verify column-count uniformity across all rows.
2. Owner: methodology | Phase: cross-feature | Type: process | Expected effect: the iters 001-003 review-friction pattern (artifact-integrity churn, evidence-breadth, state-truth) is now well-characterized across this feature — feed it into the reviewer-scaffolder-hardening + review-evidence-breadth proposal candidates already logged in the iter-001/002 retros.
3. Owner: methodology | Phase: boundary transitions | Type: tooling | Expected effect: address the **recurring branch-push-discipline gap** — commits accrued unpushed twice within F-050 (the cross-reviewer caught both; matches the established `project-codex-branch-push-discipline-gap` pattern). The fix is mechanical: either a `specrew sync-*` boundary command that includes a `git push` step, or a coordinator-governance reminder rule that prompts a push at each boundary transition. This is now an empirical 2-instances-in-one-feature pattern for this Crew — worth a small proposal.

## Calibration Suggestion

- Suggested capacity adjustment: none for docs iterations — the 3 SP estimate was exact, and applying the prior iterations' lessons proactively removed the review-friction overhead that iters 001-002 absorbed.
- Rationale: the learning curve flattened; iter-003 ran clean.

## Notes

- Iteration 003 = docs (getting-started quickstart + user-guide interaction model) + HUMAN-verified live-Cursor smoke. All 3 tasks pass.
- **Feature is functionally complete.** Remaining: iter-003 iteration-closeout → feature-closeout = rebase onto post-F-049 main (169-commit lag), resolve core-file conflicts (`specrew-start.ps1`/`_registry.ps1`/`host-flag-translation.ps1`/`deploy-squad-runtime.ps1`/`Specrew.psd1`/host tests/docs), re-run suite, set ModuleVersion 0.29.0, PR, beta-before-stable.
- Carry to feature-closeout: the iter-001 mirror-parity item (`.specify/` mirror sync of the FR-003 source edit) is a tracked closeout action; do it between PR merge and beta publish.

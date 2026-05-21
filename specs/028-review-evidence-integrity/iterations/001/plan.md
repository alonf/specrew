# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 18/20 story_points
**Started**: 2026-05-21
**Completed**: 2026-05-21

## Scope Summary

This iteration plan reflects the completed execution state for Feature 028 Iteration
001. The implementation, accepted review, retrospective, and iteration-closeout
packet are recorded on the current tree; the remaining lifecycle move is
feature-closeout for Proposal 073 and project metadata.

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001, FR-002, FR-003, FR-004 | Add the pre-review validator rule that compares declared completed work against `git diff <baseline>...HEAD` and emits the `review-evidence-integrity` hard failure when the diff is empty. | US-2 |
| FR-005, FR-006, FR-007 | Make reviewer artifacts surface the form-vs-meaning gap loudly instead of silently presenting "below threshold" reviewer evidence. | US-1 |
| FR-008 | Ship the reusable `Test-FormMeaningParity` helper with the immutable Proposal 030 seed contract. | US-3 |
| FR-009, FR-010, FR-011, FR-012 | Make reviewer artifact regeneration idempotent with `-Force`, `-Confirm:$false` automation support, and clear documentation that annotations belong in `review.md`. | US-4 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T004-T009 | Reviewer-artifact warnings and downstream evidence truthfulness | FR-005, FR-006, FR-007 | US-1 | 3.0 | Implementer | `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1` | done | Implementer | AI | pass |
| T010-T016 | Pre-review validator gate and false-positive prevention | FR-001, FR-002, FR-003, FR-004 | US-2 | 4.0 | Implementer | `extensions/specrew-speckit/scripts/validate-governance.ps1` | done | Implementer | AI | pass |
| T017-T023 | `Test-FormMeaningParity` helper and Proposal 030 contract validation | FR-008 | US-3 | 3.0 | Implementer | `extensions/specrew-speckit/scripts/shared-governance.ps1`, `specs/028-review-evidence-integrity/contracts/**`, `specs/028-review-evidence-integrity/research.md` | done | Implementer | AI | pass |
| T024-T031 | Idempotent `-Force` rerun semantics and documentation convention | FR-009, FR-010, FR-011, FR-012 | US-4 | 3.0 | Implementer | `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1`, `docs/user-guide.md`, `docs/api-reference.md` | done | Implementer | AI | pass |
| T032-T050 | Regression lane, AC8 sweep, docs, and changelog surfaces | FR-001, FR-005, FR-008, FR-009, FR-012 | US-1, US-2, US-3, US-4 | 5.0 | Reviewer | `tests/integration/review-evidence-integrity.tests.ps1`, `tests/integration/reviewer-artifacts.ps1`, `tests/integration/gap-governance.ps1`, `docs/**`, `CHANGELOG.md` | done | Reviewer | AI | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- The slice touched one shared governance surface (`validate-governance.ps1`) plus one shared scaffolder (`scaffold-reviewer-artifacts.ps1`), so the substantive implementation work stayed serial even though the docs and regression lane could be prepared in parallel.
- The accepted iteration shape groups the delivery into five evidence-backed work packets rather than mirroring every fine-grained task row from `tasks.md`.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | complete | Feature-level planning artifacts were generated and clarified before implementation started. |
| Discovery/Spikes | complete | Reviewer-gap diagnosis, baseline-source audit, and Proposal 030 API-shape validation were completed during planning/repair. |
| Implementation | 18 SP complete | Validator, helper, scaffolder, docs, and regression-lane work are complete on the current tree. |
| Review | complete | Accepted review and reviewer-evidence packet are recorded on the current tree. |
| Retro | complete | Retrospective is recorded before the iteration-closeout packet. |
| Iteration Closeout | complete | `dashboard.md`, reviewer packet, and closeout state are present; feature-closeout remains the next boundary. |
| Rework | none | No accepted review finding re-opened implementation after the repaired gate/test lane landed. |

## Traceability Summary

- Requirement scope for this iteration: FR-001 through FR-012.
- User stories represented in current scope: US-1, US-2, US-3, US-4.
- Detailed execution remains source-controlled in `specs/028-review-evidence-integrity/tasks.md`; this iteration plan is the truthful closeout companion for the delivered Iteration 001 tree.
- No iteration-scope deferral remains open on this tree; the remaining lifecycle work is feature-closeout bookkeeping for Proposal 073 and the proposal index.

## Notes

- This plan was normalized after implementation so the Tasks table reflects the actual delivered work packets and accepted review surface.
- Review, retro, and iteration-closeout are complete on the current tree.
- The feature-closeout boundary remains separate and is handled at the feature level (`closeout-dashboard.md`, proposal frontmatter, and proposal index state).

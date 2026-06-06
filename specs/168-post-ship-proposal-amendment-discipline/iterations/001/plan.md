# Iteration Plan: 001

**Schema**: v1
**Spec**: file:///C:/Dev/Specrew-post-ship-amendment-discipline/specs/168-post-ship-proposal-amendment-discipline/spec.md
**Feature Plan**: file:///C:/Dev/Specrew-post-ship-amendment-discipline/specs/168-post-ship-proposal-amendment-discipline/plan.md
**Tasks**: file:///C:/Dev/Specrew-post-ship-amendment-discipline/specs/168-post-ship-proposal-amendment-discipline/tasks.md
**Status**: planning
**Overall Verdict**: ready
**Capacity**: 6.5/20 story_points
**Started**: 2026-06-06
**Completed**:

## Scope Summary

Iteration 001 implements the full approved Feature 168 slice only if T002 confirms the direct validator and file:///C:/Dev/Specrew-post-ship-amendment-discipline/proposals/INDEX.md path is small. If discovery shows validator/status work exceeds the bounded slice, implementation must stop and propose deferral before coding beyond the approved scope.

Status surfacing stays docs/index-only if no existing narrower renderer exists. This iteration does not create a generated amendment index, hard-fail shipped/superseded normative edits, allow `Post-Ship Amendments` on active proposals, rewrite real shipped proposal bodies, bulk-migrate historical proposals, or reimplement shipped behavior.

## Release-Blocking Constraints

| Constraint | Requirement | Implementation Control | Review Evidence |
| --- | --- | --- | --- |
| Delta-based amendment planning | FR-006 | Any shipped-proposal amendment implementation path must identify amendment id or superseding proposal, delta from shipped behavior, preserve list, and tests required. | Claim-to-evidence ledger verifies the delivered work against the amendment delta, not the full shipped proposal body. |
| No historical rewrite or reimplementation | FR-015 | Real shipped proposal bodies must not be touched except synthetic fixtures or allowed documentation/template changes. | Delta-only diff audit confirms no real shipped proposal body rewrite, no bulk migration, and no prior shipped behavior reimplementation. |

## Branch Hygiene and Dirty Drift

Pre-implementation branch parity was confirmed by the human at `90c42993`. The following dirty paths remain out of scope and must not be staged unless a later explicit human decision makes a path in scope:

- file:///C:/Dev/Specrew-post-ship-amendment-discipline/.codex/
- file:///C:/Dev/Specrew-post-ship-amendment-discipline/.github/agents/squad.agent.md
- file:///C:/Dev/Specrew-post-ship-amendment-discipline/.squad/casting/registry.json
- file:///C:/Dev/Specrew-post-ship-amendment-discipline/.squad/config.json
- file:///C:/Dev/Specrew-post-ship-amendment-discipline/specs/140-unix-native-install/iterations/003/tasks-progress.yml
- file:///C:/Dev/Specrew-post-ship-amendment-discipline/.cursor/
- file:///C:/Dev/Specrew-post-ship-amendment-discipline/.specrew/version-check-cache.json

All implementation commits must use path-limited staging.

## Proposal 145 Review Discipline

Review readiness must include:

- Claim-to-evidence ledger mapping each delivered claim to files, tests, and review proof.
- Delta-only diff audit for FR-006 and FR-015.
- Branch hygiene proof showing HEAD/upstream parity and unrelated dirty drift classification.
- Over-strong-claim checks that reject evidence claiming more than tests or diffs prove.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T001 | Confirm implementation hygiene and path-limited staging plan | FR-015, TG-005, TG-007 | US1, US2, US3, US4 | 0.25 | Implementer, Reviewer | `specs/168-post-ship-proposal-amendment-discipline/iterations/001/**` | done | codex | `14b214f9` parity confirmed; dirty drift unchanged and out of scope | pass |
| T002 | Discover exact docs, validator, status, and fixture surfaces | FR-001, FR-007, FR-010, FR-013, FR-014 | US1, US2, US3, US4 | 0.25 | Implementer, Planner | `docs/methodology/**`; `extensions/**`; `.specify/extensions/**`; `tests/**`; `proposals/INDEX.md` | done | codex | Direct path is small: additive docs, validator plus mirror, focused synthetic fixtures/tests, and docs/index-only status surfacing in `proposals/INDEX.md`; no generated status renderer. | pass |
| T003 | Document mutability classes and active-proposal rule | FR-001, FR-004, FR-005 | US1 | 0.50 | Spec Steward | `docs/methodology/proposal-discipline.md` | done | codex | Mutability table added, including active-flow rule and shipped/superseded direct-edit limits. | pass |
| T004 | Add structured post-ship amendment template and statuses | FR-002, FR-003 | US1 | 0.50 | Spec Steward | `docs/methodology/proposal-discipline.md` | done | codex | `Post-Ship Amendments` template and allowed status meanings added. | pass |
| T005 | Add delta-based proposal review guidance | FR-006, FR-007, FR-008, FR-009, FR-015, TG-006, TG-007 | US3 | 0.25 | Reviewer | `docs/methodology/review-instructions.md` | done | codex | Reviewer guidance now requires amendment/superseding reference, preserve list, tests-required, and no unrelated shipped-scope reimplementation. | pass |
| T006 | Implement validator-side proposal/amendment reader | FR-002, FR-003, FR-010, FR-012 | US2 | 0.50 | Implementer | `extensions/specrew-speckit/scripts/validate-governance.ps1`; `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | done | codex | Validator parses proposal frontmatter, changed proposal diffs, and amendment fields locally. | pass |
| T007 | Add warning-first shipped/superseded normative edit detection | FR-004, FR-010, FR-011, FR-015 | US2 | 0.75 | Implementer | `extensions/specrew-speckit/scripts/validate-governance.ps1`; `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | done | codex | `WARN [post-ship-proposal] normative-body-edit` added for changed shipped/superseded sections outside allowed paths. | pass |
| T008 | Add separate malformed-amendment finding | FR-002, FR-003, FR-012 | US2 | 0.25 | Implementer | `extensions/specrew-speckit/scripts/validate-governance.ps1`; `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | done | codex | `WARN [post-ship-proposal] malformed-amendment` added for missing fields and invalid statuses. | pass |
| T009 | Surface accepted-unimplemented and active amendments in index/status | FR-013 | US4 | 0.25 | Implementer | `proposals/INDEX.md`; status renderer if discovered | done | codex | Human-maintained Post-Ship Amendment Backlog section added to `proposals/INDEX.md`. | pass |
| T010 | Suppress closed amendment states from unimplemented backlog | FR-013 | US4 | 0.25 | Implementer | `proposals/INDEX.md`; status renderer if discovered | done | codex | Index instructions limit backlog rows to `accepted-unimplemented` and `active`. | pass |
| T011 | Create synthetic proposal fixtures only | FR-010, FR-011, FR-012, FR-013, FR-014, FR-015 | US1, US2, US4 | 0.50 | Implementer | `tests/**/fixtures/**` | done | codex | Synthetic proposal and index fixtures added under `tests/unit/fixtures/168-post-ship-proposal-amendment-discipline/`. | pass |
| T012 | Add validator behavior tests | FR-010, FR-011, FR-012, FR-014 | US2 | 0.75 | Implementer | `tests/unit/**`; `tests/integration/**` | done | codex | Focused replay covers unsafe shipped/superseded edits, valid amendments, allowed corrections, mutable statuses, and malformed amendments. | pass |
| T013 | Add docs/reviewer/status behavior tests | FR-001, FR-002, FR-003, FR-007, FR-013, FR-014 | US1, US3, US4 | 0.50 | Implementer, Reviewer | `tests/unit/**`; `tests/integration/**` | done | codex | Focused replay asserts docs fields/statuses, reviewer delta checks, and `A1 accepted-unimplemented` status fixture. | pass |
| T014 | Preserve validator mirror parity | FR-010, FR-012, FR-014 | US2 | 0.25 | Implementer | `extensions/specrew-speckit/scripts/validate-governance.ps1`; `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | done | codex | `.specify` validator copy matches extension source exactly. | pass |
| T015 | Run focused checks and record quality evidence | FR-014, TG-006 | US1, US2, US3, US4 | 0.25 | Implementer | `specs/168-post-ship-proposal-amendment-discipline/iterations/001/quality/**` | planned | codex | — | — |
| T016 | Produce review gap ledger | FR-006, FR-007, FR-008, FR-009, FR-015, TG-006, TG-007 | US3 | 0.25 | Reviewer | `specs/168-post-ship-proposal-amendment-discipline/iterations/001/review.md`; reviewer artifacts | planned | codex | — | — |
| T017 | Perform final delta-only diff audit | FR-015, TG-005, TG-007 | US3 | 0.25 | Reviewer | `specs/168-post-ship-proposal-amendment-discipline/iterations/001/review.md`; reviewer artifacts | planned | codex | — | — |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Planned Effort | 6.5 | Bounded task estimate, visible as above the original 3-5 SP proposal estimate. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Scope stays fixed; discovery may trigger explicit deferral request if needed. |
| Overcommit Threshold | 1.0 | Planned effort is below capacity but above proposal estimate. |
| Defer Strategy | manual | Lowest-risk deferral is status surfacing beyond docs/index-only if renderer work grows. |

## Phase Baseline

| Phase | Estimated Effort | Notes |
| --- | --- | --- |
| Discovery/Hygiene | 0.5 | T001-T002 must run before code edits. |
| Documentation/Review Guidance | 1.25 | T003-T005. |
| Validator/Parser | 1.5 | T006-T008, warning-first only. |
| Status Surfacing | 0.5 | T009-T010, docs/index-only unless narrower renderer exists. |
| Fixtures/Tests | 1.75 | T011-T013, synthetic fixtures only. |
| Validation/Review Evidence | 1.0 | T014-T017. |

## Traceability Summary

- Requirement scope: FR-001 through FR-015, TG-005 through TG-007.
- User stories represented: US1, US2, US3, US4.
- Task coverage: all tasks map to at least one FR or TG and at least one SC through file:///C:/Dev/Specrew-post-ship-amendment-discipline/specs/168-post-ship-proposal-amendment-discipline/tasks.md.
- Effort arithmetic: task rows sum to 6.5 story points; this is above the source proposal estimate and below the configured 20 story point iteration capacity.
- Release-blocking requirements: FR-006 and FR-015.
- Overall Verdict: ready for implementation approval after human review of this before-implement package.

## Concurrency Rationale

- Documentation tasks T003-T005 can run in parallel after T002 because they touch separate files.
- Validator tasks T006-T008 should remain serial until parser shape is known.
- Status tasks T009-T010 can run in parallel with docs work after T002 if status work stays docs/index-only.
- Test tasks T012-T013 can run in parallel after T011 creates fixtures.
- Mirror parity T014 must run after validator edits and before final validation.

## Notes

- No implementation code is authorized by the tasks-to-before-implement verdict.
- Do not start T001 until the human explicitly approves implementation after this before-implement stop.
- If T002 finds the direct validator/index path is not small, stop and ask for a deferral decision before coding beyond the approved bounded slice.

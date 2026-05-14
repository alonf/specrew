# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retrospective-complete
**Capacity**: 13.0/20 story_points
**Started**: 2026-05-14
**Completed**: implementation completed on 2026-05-14 (`T001`-`T008`, `T011`-`T013`, `T018`-`T020`); review boundary opened on 2026-05-14 against commit `ed8dea9`; review-verdict-signoff boundary completed on 2026-05-14; retrospective boundary completed on 2026-05-14T10:13:30Z; iteration-closeout boundary authorized on 2026-05-14T11:27:03Z
**Hardening-Gate Sign-Off**: user sign-off recorded on 2026-05-14; authorization boundary committed in `e47da21`
**Implementation Authorization**: user directive on 2026-05-14 for FR-001 through FR-019 only; paired decisions recorded in `.squad/decisions.md`
**Review Completed**: 2026-05-14
**Review Verdict**: accepted (post-repair)
**Review-Verdict-Signoff**: user sign-off recorded on 2026-05-14; authorization entry added to `.squad/decisions.md` with decision ID `authorization-feature-016-iter-001-review-verdict-signoff`
**Retrospective Boundary**: retro.md drafted on 2026-05-14T10:13:30Z; retrospective boundary completed with authorization-feature-016-iter-001-retro-boundary entry
**Iteration-Closeout Boundary**: completed at `aa01752` (2026-05-14T11:27:03Z); current HEAD `5f04f4f` contains post-closeout bookkeeping alignment; next valid action is Iteration 2 planning authorization

## Scope Summary

Iteration 001 delivered the authorized Feature 016 governance and validator slice only: per-boundary authorization discipline, substantive boundary-handoff guidance, and `file:///` click-through navigation enforcement for FR-001 through FR-019. Iteration 2 proof, corpus, template, and documentation follow-through remains explicitly deferred.

| Scope Slice | Requirements | Tasks | Status | Notes |
| --- | --- | --- | --- | --- |
| Setup + foundations | FR-006, FR-007, FR-008, FR-009, FR-011, FR-016, FR-018 | T001-T004 | done | Baseline captured; shared governance/helper plumbing aligned before story work |
| User Story 1 — boundary discipline | FR-001 through FR-009 | T005-T008 | done | Seven named boundaries, single-step `continue`, paired authorization shape, bundled-boundary hard fail |
| User Story 2 — essence in console | FR-010 through FR-014 | T011-T013 | done | Substantive-threshold guidance and additive soft warnings shipped |
| User Story 3 — click-through navigation | FR-015 through FR-019 | T018-T020 | done | `file:///` guidance, bare-path soft warnings, exemption contexts, broken-link checks shipped |

## Tasks

| Task | Title | Scope Item | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ---------- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Capture repo baseline and record it in quickstart | Foundation | FR-006, FR-007, FR-011, FR-016 | US0 | 1.0 | Quality steward | `specs/016-substantive-interaction-model/quickstart.md`, `tests/integration/*.ps1`, `extensions/specrew-speckit/scripts/validate-governance.ps1` | done | Implementer | 1.0 | done |
| T002 | Reconcile approved design artifacts against Iteration 1 scope | Foundation | TG-005, TG-006 | US0 | 0.5 | Iteration facilitator | `specs/016-substantive-interaction-model/*.md`, `contracts/*.md` | done | Implementer | 0.5 | done |
| T003 | Reconcile boundary and validator contracts with the final helper vocabulary | Foundation | FR-008, FR-009, FR-016, FR-018 | US0 | 0.5 | Governance steward | `specs/016-substantive-interaction-model/contracts/*.md` | done | Implementer | 0.5 | done |
| T004 | Add shared helper plumbing for boundary/auth/handoff parsing | Foundation | FR-006, FR-007, FR-011, FR-016 | US0 | 1.5 | Validator steward | `extensions/specrew-speckit/scripts/shared-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` | done | Implementer | 1.5 | done |
| T005 | Update boundary-discipline coordinator guidance and examples | 1 | FR-001, FR-002, FR-003, FR-004, FR-005 | US1 | 1.5 | Governance steward | `.github/agents/squad.agent.md`, `extensions/specrew-speckit/prompts/*.md`, `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | done | Implementer | 1.5 | done |
| T006 | Add canonical authorization-record guidance and paired-entry rules | 1 | FR-008, FR-009 | US1 | 1.0 | Governance steward | `.github/agents/squad.agent.md`, `extensions/specrew-speckit/prompts/coordinator-response.md`, `specs/016-substantive-interaction-model/contracts/boundary-authorization-and-handoff.md` | done | Implementer | 1.0 | done |
| T007 | Implement bundled-boundary hard fail and canonical boundary recognition | 1 | FR-006, FR-007, FR-008, FR-009 | US1 | 2.0 | Validator steward | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `extensions/specrew-speckit/scripts/shared-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` | done | Implementer | 2.0 | done |
| T008 | Record boundary-discipline replay evidence | 1 | SC-001, SC-002, SC-003 | US1 | 0.5 | Quality steward | `specs/016-substantive-interaction-model/quickstart.md` | done | Implementer | 0.5 | done |
| T011 | Update substantive-handoff guidance and examples | 2 | FR-010, FR-014 | US2 | 1.0 | Governance steward | `.github/agents/squad.agent.md`, `extensions/specrew-speckit/prompts/coordinator-response.md`, `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`, `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | done | Implementer | 1.0 | done |
| T012 | Implement substantive-handoff soft warnings | 2 | FR-011, FR-012, FR-013 | US2 | 1.5 | Validator steward | `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`, `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | done | Implementer | 1.5 | done |
| T013 | Record console-substance validation evidence | 2 | SC-004, SC-005 | US2 | 0.5 | Quality steward | `specs/016-substantive-interaction-model/quickstart.md` | done | Implementer | 0.5 | done |
| T018 | Update navigation guidance to require `file:///` references | 3 | FR-015, FR-018, FR-019 | US3 | 1.0 | Governance steward | `.github/agents/squad.agent.md`, `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`, `extensions/specrew-speckit/prompts/coordinator-response.md`, `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | done | Implementer | 1.0 | done |
| T019 | Implement bare-path and broken-file-url warnings with exemptions | 3 | FR-016, FR-017, FR-018, FR-019 | US3 | 1.5 | Validator steward | `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`, `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `extensions/specrew-speckit/scripts/shared-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` | done | Implementer | 1.5 | done |
| T020 | Record navigation validation evidence | 3 | SC-006, SC-007, SC-008 | US3 | 0.5 | Quality steward | `specs/016-substantive-interaction-model/quickstart.md` | done | Implementer | 0.5 | done |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies |
| Iteration Bounding | scope | `scope` keeps requirements fixed |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time` |
| Overcommit Threshold | 1.0 | Warn when total planned effort exceeds capacity |
| Defer Strategy | manual | Explicit human approval required for any scope deferral |
| Calibration Enabled | true | Retro should update future capacity guidance as needed |

## Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Status |
| --- | --- | --- | --- |
| `validator-replay-clean` | tooling | `tests/integration/substantive-interaction-model-handoff-test.ps1`, `tests/integration/substantive-interaction-model-boundary-discipline-test.ps1`, repo validator | passed |
| `manual-handoff-readability-check` | manual-evidence | Iteration 1 handoff examples recorded in `quickstart.md` and exercised through the validator surface | passed |
| `grandfathering-check` | mechanical | Repo-wide `validate-governance.ps1 -ProjectPath .` passes on Feature 016's canonical implementation authorization sequence with anchored boundary patterns | passed |
| `mirror-sync-check` | mechanical | `extensions/` and `.specify/extensions/` script/template pairs updated together | passed |

## Decisions and Handoff

- **Planning Boundary**: committed at `0070a74`; planning artifacts remain authoritative for Iteration 001 scope.
- **Hardening-Gate Sign-Off**: recorded as `hardening-gate-signoff` in `file:///C:/Dev/Specrew/.squad/decisions.md`; `quality/hardening-gate.md` now records a validator-safe `ready` verdict.
- **Implementation Authorization**: recorded as `implementation` in `file:///C:/Dev/Specrew/.squad/decisions.md`; both authorization entries cite the user's verbatim approval text.
- **Implementation Repair**: completed post-`ed8dea9` (commits `37822b6` and `59f1b21`) to address FR-006/FR-009 validator-logic defects and NFR-001 evidence integrity concerns.
- **Review-Verdict-Signoff**: completed on 2026-05-14; authorization entry recorded as `authorization-feature-016-iter-001-review-verdict-signoff` in `file:///C:/Dev/Specrew/.squad/decisions.md` following independent human verifier validation against HEAD 59f1b21.
- **Current Boundary State**: iteration-closeout boundary is complete; next valid action is Iteration 2 planning authorization.
- **Session Restart Requirement**: required before a future fresh session can load the updated startup surfaces in `file:///C:/Dev/Specrew/.github/agents/squad.agent.md` and `file:///C:/Dev/Specrew/.squad/templates/squad.agent.md`.

## Scope and Deferrals

- **In Scope**: FR-001 through FR-019, limited to Iteration 1 behavior and the soft-warning rollout shape for `bare-path-in-boundary-handoff`.
- **Deferred**: FR-020 through FR-024; the Iteration 2 promotion half of FR-016; README lifecycle updates; corpus rows; per-feature handoff template updates; full violating/compliant fixture expansion.
- **Constraint**: Review, retro, and iteration closeout remain separately authorized boundaries.

## Evidence Snapshot

- **Repo validator timing**: `109134 ms` baseline (pre-Feature 016); `150007 ms` final-tree pass on accepted repaired tree (post-`59f1b21`); NFR-001 +37.5% delta accepted with documented rationale and deferred performance optimization.
- **Validator state**: All eight validation items pass on HEAD `6f0db62`: five preserved handoff-governance regressions, two new Feature 016 integration tests, and repo-wide `validate-governance.ps1 -ProjectPath .` green with anchored canonical boundary patterns and immutable Commit Reference matching discipline.
- **Prompt-line budget**: `100` added lines across the governed coordinator surfaces (`<=150`, within NFR-002).

## Next Action

Iteration 001 is closed. The next valid action is Iteration 2 planning authorization.



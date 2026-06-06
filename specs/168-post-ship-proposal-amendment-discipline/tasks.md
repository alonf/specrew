# Tasks: Post-Ship Proposal Amendment Discipline

**Feature**: 168-post-ship-proposal-amendment-discipline
**Branch**: 168-post-ship-proposal-amendment-discipline
**Total Tasks**: 17
**Iterations**: 1
**Total Effort**: ~6 SP
**Status**: Ready for before-implement approval with capacity risk visible

## Overview

This task list implements Proposal 167 as a narrow, fixture-driven governance slice. It adds post-ship proposal amendment documentation, warning-first validation, reviewer guidance, status surfacing, tests, and review evidence without rewriting historical shipped proposal bodies or reimplementing shipped behavior.

Implementation must use path-limited staging. Existing dirty drift outside Feature 168 remains out of scope as recorded in file:///C:/Dev/Specrew-post-ship-amendment-discipline/specs/168-post-ship-proposal-amendment-discipline/state-reconciliation.md.

Release-blocking constraints:

- **FR-006**: Any implementation planning or review path for shipped proposal amendments must state the delta from shipped behavior, amendment id or superseding proposal reference, preserve list, and tests required.
- **FR-015**: Do not rewrite historical shipped proposal bodies, bulk-migrate existing proposals, or reimplement shipped behavior from prior proposal work.

Tasks may touch real methodology docs, validator code, tests, templates, and status/index surfaces. Tasks must not touch real shipped proposal bodies except synthetic fixtures or explicitly allowed documentation/template changes.

## Iteration 001: Amendment Discipline, Validation, and Review Evidence

**User Stories**: US1 (safe historical amendments), US2 (validator warnings), US3 (delta-based review), US4 (unimplemented amendment visibility)
**Functional Requirements**: FR-001 through FR-015
**Success Criteria**: SC-001 through SC-009

### Phase 0: Hygiene and Surface Discovery

- [ ] T001 Confirm implementation hygiene before editing: record current branch, HEAD/upstream parity, dirty paths, and path-limited staging plan in implementation notes or iteration state. Do not stage file:///C:/Dev/Specrew-post-ship-amendment-discipline/.codex/, file:///C:/Dev/Specrew-post-ship-amendment-discipline/.github/agents/squad.agent.md, file:///C:/Dev/Specrew-post-ship-amendment-discipline/.squad/casting/registry.json, file:///C:/Dev/Specrew-post-ship-amendment-discipline/.squad/config.json, file:///C:/Dev/Specrew-post-ship-amendment-discipline/specs/140-unix-native-install/iterations/003/tasks-progress.yml, file:///C:/Dev/Specrew-post-ship-amendment-discipline/.cursor/, or file:///C:/Dev/Specrew-post-ship-amendment-discipline/.specrew/version-check-cache.json. [effort: 0.25 SP] [FR-015, TG-005, TG-007] [SC-007]
- [ ] T002 Discover the exact implementation surfaces before coding: proposal discipline docs, reviewer guidance, validator/mirror scripts, proposal index/status rendering, and best-fit fixture/test locations. Prefer file:///C:/Dev/Specrew-post-ship-amendment-discipline/proposals/INDEX.md for status surfacing unless an existing narrower status renderer is clearly more direct. [effort: 0.25 SP] [FR-001, FR-007, FR-010, FR-013, FR-014] [SC-001, SC-005, SC-006]

### Phase 1: Docs, Template, and Reviewer Guidance

- [ ] T003 Update file:///C:/Dev/Specrew-post-ship-amendment-discipline/docs/methodology/proposal-discipline.md with proposal mutability classes for `candidate`, `draft`, `active`, `shipped`, `superseded`, and `withdrawn`, including warning-first shipped/superseded amendment behavior and the rule that active proposals use active-feature amendment flow. [effort: 0.5 SP] [FR-001, FR-004, FR-005] [SC-001]
- [ ] T004 Add the structured `Post-Ship Amendments` template to proposal discipline docs with required fields `amendment-id`, `date`, `status`, `delta-summary`, `implementation-owner`, `preserve`, and `tests-required`, plus allowed statuses `proposed`, `accepted-unimplemented`, `active`, `implemented`, `rejected`, and `superseded`. [effort: 0.5 SP] [FR-002, FR-003] [SC-002]
- [ ] T005 Update file:///C:/Dev/Specrew-post-ship-amendment-discipline/docs/methodology/review-instructions.md so proposal reviewers verify amendment id or superseding proposal reference, delta summary, preserve list, tests required, no unrelated shipped-scope reimplementation, and final amendment disposition for closeout. [effort: 0.25 SP] [FR-006, FR-007, FR-008, FR-009, FR-015, TG-006, TG-007] [SC-005, SC-007, SC-009]

### Phase 2: Validator Parser and Warning Findings

- [ ] T006 Implement or extend the validator-side proposal reader to parse proposal front matter status and `Post-Ship Amendments` entries for real proposals and synthetic fixtures. Keep the parser small and local to the validator path unless an existing helper is clearly reusable. [effort: 0.5 SP] [FR-002, FR-003, FR-010, FR-012] [SC-002, SC-003, SC-008]
- [ ] T007 Add warning-first detection for shipped/superseded normative body edits outside `Post-Ship Amendments`. The warning must identify the proposal or fixture, the changed normative area when available, and the expected amendment/new-proposal path. Do not implement full semantic diffing. [effort: 0.75 SP] [FR-004, FR-010, FR-011, FR-015] [SC-003, SC-004, SC-007]
- [ ] T008 Add a separate malformed-amendment finding for missing required amendment fields or invalid amendment statuses. This finding must remain distinct from unsafe shipped/superseded body-edit warnings. [effort: 0.25 SP] [FR-002, FR-003, FR-012] [SC-002, SC-008]

### Phase 3: Status Surfacing

- [ ] T009 Surface unimplemented post-ship amendments in the proposal index/status path. Prefer file:///C:/Dev/Specrew-post-ship-amendment-discipline/proposals/INDEX.md first; if T002 finds a narrower existing status renderer, use that and document why. Show amendment id and status for `accepted-unimplemented` and `active` amendments, and do not create a generated amendment index. [effort: 0.25 SP] [FR-013] [SC-006]
- [ ] T010 Ensure implemented, rejected, and superseded amendments remain in the source proposal but do not appear as unimplemented backlog in index/status output. [effort: 0.25 SP] [FR-013] [SC-006]

### Phase 4: Synthetic Fixtures and Tests

- [ ] T011 Create synthetic proposal fixtures only; do not modify real shipped proposal bodies. Fixtures must cover shipped/superseded unsafe normative body edits, valid amendment-section edits, candidate/draft body edits, allowed typo/link/errata/supersession-pointer edits, active proposal exclusion, malformed amendment records, and unimplemented amendment status surfacing. [effort: 0.5 SP] [FR-010, FR-011, FR-012, FR-013, FR-014, FR-015] [SC-003, SC-004, SC-006, SC-008]
- [ ] T012 Add focused tests for validator behavior: shipped/superseded unsafe body edits warn, valid amendments do not warn solely because the proposal is shipped, allowed corrections do not false-positive, candidate/draft edits do not warn, active proposals do not use post-ship enforcement, and malformed amendments produce the separate finding. [effort: 0.75 SP] [FR-010, FR-011, FR-012, FR-014] [SC-003, SC-004, SC-008]
- [ ] T013 Add focused tests for docs/reviewer/status behavior: amendment template contains all required fields/statuses, reviewer guidance requires delta-based evidence, status/index output shows `A1 accepted-unimplemented`, and implemented/rejected/superseded amendments are not shown as backlog. [effort: 0.5 SP] [FR-001, FR-002, FR-003, FR-007, FR-013, FR-014] [SC-001, SC-002, SC-005, SC-006]

### Phase 5: Mirror Parity, Validation, and Review Evidence

- [ ] T014 Preserve validator mirror parity between file:///C:/Dev/Specrew-post-ship-amendment-discipline/extensions/specrew-speckit/scripts/validate-governance.ps1 and file:///C:/Dev/Specrew-post-ship-amendment-discipline/.specify/extensions/specrew-speckit/scripts/validate-governance.ps1 if either validator script changes. [effort: 0.25 SP] [FR-010, FR-012, FR-014] [SC-003, SC-008]
- [ ] T015 Run focused markdownlint, focused unit/integration tests, and governance validation. Record the exact commands and outcomes in iteration quality evidence before review. [effort: 0.25 SP] [FR-014, TG-006] [SC-001, SC-002, SC-003, SC-004, SC-005, SC-006, SC-008, SC-009]
- [ ] T016 Produce review evidence with a gap ledger classifying post-ship amendment discipline as documented, implemented, enforced, observable, and tested. Any gap must be fixed or explicitly deferred by the human before review signoff. [effort: 0.25 SP] [FR-006, FR-007, FR-008, FR-009, FR-015, TG-006, TG-007] [SC-005, SC-007, SC-009]
- [ ] T017 Perform final delta-only diff audit before review: confirm no real shipped proposal bodies were rewritten, no bulk migration occurred, no prior shipped behavior was reimplemented, and any touched shipped proposal file has an allowed reason recorded in review evidence. [effort: 0.25 SP] [FR-015, TG-005, TG-007] [SC-007, SC-009]

## Dependency Graph

```text
T001 -> T002
T002 -> T003,T004,T005
T002 -> T006 -> T007,T008
T002 -> T009 -> T010
T006,T007,T008,T009,T010 -> T011 -> T012,T013
T007,T008 -> T014
T003,T004,T005,T012,T013,T014 -> T015 -> T016 -> T017
```

## Parallel Opportunities

- T003, T004, and T005 can run in parallel after T002 because docs/template and reviewer guidance are separate surfaces.
- T006-T008 and T009-T010 can proceed in parallel after surface discovery if different files own validator and status work.
- T012 and T013 can run in parallel after fixtures exist.
- T014 can run immediately after validator edits are complete.

## Quality Gates and Acceptance Criteria

### Before Implementation

- Human approval for before-implement is recorded.
- Iteration plan and hardening gate are scaffolded and committed.
- Dirty-state classification from T001 is recorded.
- The implementation owner confirms path-limited staging.

### Implementation Complete

- Proposal discipline docs define mutability classes and amendment template.
- Reviewer guidance requires delta-based amendment review evidence.
- Validator emits warning-first findings for shipped/superseded unsafe normative edits and separate malformed-amendment findings.
- Proposal index/status output surfaces unimplemented post-ship amendments.
- Synthetic fixtures cover unsafe, allowed, malformed, active, candidate, draft, and status-surfacing cases.
- Real shipped proposal bodies are not rewritten.

### Review Complete

- Review evidence includes documented/implemented/enforced/observable/tested gap ledger.
- Final diff audit confirms no bulk historical migration and no unrelated shipped-scope reimplementation.
- Known gaps are fixed or explicitly deferred by the human.

## Traceability Matrix

| Task Range | User Stories | Functional Requirements | Success Criteria |
| --- | --- | --- | --- |
| T001-T002 | US1, US2, US3, US4 | FR-001, FR-007, FR-010, FR-013, FR-014, FR-015, TG-005, TG-007 | SC-001, SC-005, SC-006, SC-007 |
| T003-T005 | US1, US3 | FR-001 through FR-009, FR-015, TG-006, TG-007 | SC-001, SC-002, SC-005, SC-007, SC-009 |
| T006-T008 | US2 | FR-002, FR-003, FR-004, FR-010, FR-011, FR-012, FR-014, FR-015 | SC-002, SC-003, SC-004, SC-008 |
| T009-T010 | US4 | FR-013 | SC-006 |
| T011-T013 | US1, US2, US3, US4 | FR-001, FR-002, FR-003, FR-007, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015 | SC-001 through SC-008 |
| T014-T017 | US2, US3, US4 | FR-006, FR-007, FR-008, FR-009, FR-010, FR-012, FR-014, FR-015, TG-005, TG-006, TG-007 | SC-003, SC-005, SC-007, SC-008, SC-009 |

## Effort Verification

| Phase | Tasks | Planned SP |
| --- | --- | --- |
| Hygiene and discovery | T001-T002 | 0.5 |
| Docs/template/reviewer guidance | T003-T005 | 1.5 |
| Validator/parser | T006-T008 | 1.75 |
| Status surfacing | T009-T010 | 0.5 |
| Fixtures and tests | T011-T013 | 1.75 |
| Mirror, validation, review evidence | T014-T017 | 1.0 |

The summed task estimate is ~6 SP, slightly above the original 3-5 SP proposal target. The target pressure is managed by keeping status surfacing to file:///C:/Dev/Specrew-post-ship-amendment-discipline/proposals/INDEX.md or an existing renderer, avoiding a generated amendment index, and using focused synthetic fixtures. If implementation discovery shows the validator/status work exceeds this bounded slice, stop and propose a scoped deferral before coding beyond the approved work.

## Next Steps

1. Run after-tasks traceability validation.
2. Ask for explicit before-implement approval.
3. Scaffold iteration 001 planning and hardening artifacts after approval.
4. Implement tasks in dependency order with path-limited staging and no real shipped proposal body rewrites.

# Tasks: Boundary Authorization Prompt Truth + Human Re-entry Packet

**Feature**: 139-boundary-authorization-prompt-truth
**Branch**: 139-boundary-authorization-prompt-truth
**Total Tasks**: 30
**Iterations**: 1
**Total Effort**: ~17.5 SP
**Status**: Ready for before-implement approval

## Overview

This task list implements Proposal 154 as a narrow prompt/state/validator/test slice. It preserves Proposal 145's structured review lens as task coverage without implementing Proposal 145 itself. Every task maps to one or more functional requirements or success criteria from [spec.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/spec.md).

Implementation must keep full Proposal 150, hook enforcement, broad historical Proposal 151 migration, and lifecycle redesign out of scope.

## Iteration 001: Prompt Truth, Re-entry Packet, and Regression Proof (Target: <=20 SP; planned ~17.5 SP)

**User Stories**: US1 (Generated Prompt Tells the Boundary Truth), US2 (Boundary Stops Re-enter the Human Cleanly), US3 (Regression Coverage Blocks Backsliding)
**Functional Requirements**: FR-001 through FR-028
**Success Criteria**: SC-001 through SC-015

### Phase 0: Context Load and Branch Hygiene

- [ ] T001 Load and summarize implementation context from [Proposal 154](file:///C:/tmp/Specrew-main-boundary-auth/proposals/154-boundary-authorization-prompt-truth.md), the beta2 smoke failure described there, [Feature 016 handoff contract](file:///C:/tmp/Specrew-main-boundary-auth/specs/016-substantive-interaction-model/contracts/boundary-authorization-and-handoff.md), the clarified six-section packet in [spec.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/spec.md), and [Proposal 145](file:///C:/tmp/Specrew-main-boundary-auth/proposals/145-structured-multi-phase-reviewer.md) as a review lens only. Record any implementation-context gaps in the iteration drift log before coding. [effort: 0.5 SP] [FR-006, TG-005, TG-006] [SC-004, SC-005]
- [ ] T002 Classify dirty working-tree files before implementation begins; keep existing dirty session/runtime files excluded unless a specific file becomes necessary for Feature 139. If a dirty/session file is needed, classify it explicitly in the task notes or drift log before editing or staging it. [effort: 0.5 SP] [FR-022, TG-004, TG-005] [SC-011] [review-lens: branch-hygiene]
- [ ] T003 Discover the exact focused test files and fixture locations before implementation. Inspect existing test surfaces such as `tests/integration/start-command.ps1`, `tests/integration/launch-mode-boundary-enforcement.tests.ps1`, `tests/unit/validate-governance.interaction-model.tests.ps1`, and related fixtures; either reuse the best-fit files or create focused new files, then record the selected files in implementation notes. Do not assume a non-existent test file already exists. [effort: 0.5 SP] [FR-007, FR-021] [SC-002, SC-008, SC-009, SC-010]

### Phase 1: Boundary Policy Resolution and Start Context Snapshot

- [ ] T004 Implement or update `specrew start` policy resolution so generated boundary guidance is derived from the authoritative [`.specrew/config.yml`](file:///C:/tmp/Specrew-main-boundary-auth/.specrew/config.yml) policy source, with a conservative fallback that does not understate human-judgment boundaries when policy state is absent or incomplete. [effort: 1 SP] [FR-001, FR-002, FR-004] [SC-001, SC-003]
- [ ] T005 Persist the resolved boundary policy snapshot into generated [start-context.json](file:///C:/tmp/Specrew-main-boundary-auth/.specrew/start-context.json) under `boundary_enforcement.policy_classes`, ensuring the prompt and lifecycle state can be audited together. [effort: 0.5 SP] [FR-002, FR-020] [SC-001, SC-003]
- [ ] T006 Add positive tests proving the generated start context includes `boundary_enforcement.policy_classes` and that generated prompt guidance lists or summarizes the configured `human-judgment-required` boundaries from `.specrew/config.yml`. [effort: 0.5 SP] [FR-002, FR-020] [SC-001]

### Phase 2: Generated Prompt Boundary Truth

- [ ] T007 Remove the beta2-bad four-gate-only generated wording from [scripts/specrew-start.ps1](file:///C:/tmp/Specrew-main-boundary-auth/scripts/specrew-start.ps1) and any mirrored generated-prompt/governance surfaces touched by the implementation. Generated text must not claim that only `before-implement`, `review-signoff`, `iteration-closeout`, and `feature-closeout` hard-block when earlier boundaries are human-judgment-required. [effort: 0.75 SP] [FR-001, FR-006] [SC-002]
- [ ] T008 Remove or rewrite generated auto-chain guidance that tells coordinators to `continue automatically through` clarify, `before-plan`, `plan`, `tasks`, or `after-tasks` when `clarify -> plan` and `plan -> tasks` are human-judgment boundaries. [effort: 0.75 SP] [FR-003, FR-004, FR-006] [SC-003]
- [ ] T009 Render explicit `clarify -> plan` human authorization guidance under the default human-judgment policy, including the distinction that readiness helpers such as `before-plan` and `after-tasks` do not authorize skipping the human verdict for the next lifecycle boundary. [effort: 0.5 SP] [FR-003, FR-004, FR-006] [SC-003, SC-006]
- [ ] T010 Add negative prompt-regression tests or fixtures rejecting the beta2-bad phrases `only gate that HARD-BLOCKS` and `continue automatically through` when they appear in a context that bypasses human-judgment boundaries. [effort: 0.5 SP] [FR-007] [SC-002]

### Phase 3: Six-Section Human Re-entry Packet

- [ ] T011 Replace generated approval-stop wording with the canonical six-section human re-entry packet contract: `What I just did`, `Why I stopped`, `What needs your review`, `What happens next`, `Discussion prompts`, and `What I need from you`. [effort: 0.75 SP] [FR-008, FR-009] [SC-004, SC-008]
- [ ] T012 Implement generated guidance for `What I just did` and `Why I stopped`, requiring meaningful past-outcome summaries, committed evidence, decisions/assumptions/scope/risk notes, the exact lifecycle boundary, and the concrete reason human judgment is required. [effort: 0.5 SP] [FR-010, FR-011] [SC-004, SC-008]
- [ ] T013 Implement generated guidance for `What needs your review` and `What happens next`, requiring targeted review surfaces, bare `file:///` links, exact sections, high-impact choices, assumptions, uncertainties, safe-skim guidance, next phase/artifacts, whether code or only planning/tasks will be written, harder-to-change decisions, and the next expected boundary stop. [effort: 0.75 SP] [FR-012, FR-013] [SC-004, SC-005]
- [ ] T014 Implement generated guidance for contextual, proactive, decision-reducing `Discussion prompts`, including targeted prompt context, question, default/recommended path, consequence when relevant, and the general no-known-dilemma review question fallback. [effort: 0.75 SP] [FR-014, FR-015, FR-018] [SC-005, SC-009, SC-010]
- [ ] T015 Implement generated guidance for `What I need from you`, including allowed response shapes, explicit approval requirement, free-form discussion not counting as approval, and structured/free-form menu affordance where available. [effort: 0.5 SP] [FR-016, FR-017, FR-019] [SC-004]
- [ ] T016 Add positive tests proving generated prompt guidance includes all six packet sections, bare `file:///` review target guidance, contextual discussion prompt requirements, explicit approval semantics, and the `clarify -> plan` planning-consequence explanation. [effort: 0.5 SP] [FR-009, FR-012, FR-014, FR-017] [SC-004, SC-005]
- [ ] T017 Implement generated guidance that the future human re-entry packet is the primary stop contract and does not require duplicating the same stop with the legacy `=== SPECREW HANDOFF ===` block. Keep any current runtime legacy block behavior explicitly transitional until replaced by this feature. [effort: 0.5 SP] [FR-023] [SC-012]
- [ ] T018 Implement generated packet guidance requiring bare `file:///` review targets in the primary packet and high-impact/release-blocking review callouts, including `Status: Approved` evidence checks and beta3 smoke evidence when in scope. [effort: 0.5 SP] [FR-024, FR-025] [SC-013]
- [ ] T019 Implement generated discussion-prompt guidance that shows prompts together, says "You can answer any prompt that should change direction, or approve with the defaults.", and supports response options: approve as-is, approve with instructions, send back, and discuss prompt `#N`. [effort: 0.5 SP] [FR-026, FR-028] [SC-014]
- [ ] T020 Implement generated discussion-loop guidance for `discuss prompt #N`: discuss that item only, summarize the agreed decision, and ask again for explicit boundary approval. Free-form discussion remains non-approval unless the human clearly authorizes the boundary. [effort: 0.5 SP] [FR-017, FR-027] [SC-015]
- [ ] T021 Add positive and negative tests for no-legacy-duplication guidance, bare `file:///` primary review targets, release-blocking review callouts, grouped discussion prompts, `discuss prompt #N`, and renewed explicit approval after prompt-specific discussion. [effort: 1 SP] [FR-023, FR-024, FR-025, FR-026, FR-027, FR-028] [SC-012, SC-013, SC-014, SC-015]

### Phase 4: Non-compliant Handoff Fixtures and Status Approval Check

- [ ] T022 Add a non-compliant handoff fixture missing `Why I stopped` and a test or validator assertion that treats it as non-compliant. [effort: 0.5 SP] [FR-009, FR-011] [SC-008]
- [ ] T023 Add a non-compliant handoff fixture that asks only `approve?` or equivalent approval-only wording without discussion prompts, and a test or validator assertion that treats it as non-compliant. [effort: 0.5 SP] [FR-014, FR-016, FR-018] [SC-009]
- [ ] T024 Add a non-compliant handoff fixture whose targeted discussion prompts lack context, and ensure it fails unless the packet clearly uses the general no-known-dilemma review question. [effort: 0.5 SP] [FR-014, FR-015] [SC-010]
- [ ] T025 Implement the narrow `Status: Approved` without human verdict evidence check against the available feature artifact and verdict evidence surfaces, keeping it limited to this contradiction class rather than implementing broad historical Proposal 151 migration. [effort: 1 SP] [FR-005, FR-021, TG-005] [SC-007]
- [ ] T026 Add positive and negative tests for the `Status: Approved` check: no matching verdict evidence is flagged; non-approval readiness wording or matching verdict evidence does not fail. [effort: 0.5 SP] [FR-005, FR-021] [SC-007]

### Phase 5: Smoke Evidence, Validation, and Review Readiness

- [ ] T027 Produce or update the committed beta3 smoke evidence artifact at [beta3-smoke-evidence.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/smoke/beta3-smoke-evidence.md). The artifact must record tested version, fresh project path, host/runtime, stop boundary, `plan.md` pre-approval state, human re-entry packet excerpt, `.squad/decisions.md` approval state, and PASS/FAIL. [effort: 0.75 SP] [FR-022] [SC-006, SC-011]
- [ ] T028 Run the selected focused tests plus repo governance validation. At minimum, run the focused prompt/status/handoff tests selected in T003 and [validate-governance.ps1](file:///C:/tmp/Specrew-main-boundary-auth/.specify/extensions/specrew-speckit/scripts/validate-governance.ps1). Record test commands and outcomes for review evidence. [effort: 0.5 SP] [FR-007, FR-021, FR-022, TG-006] [SC-001, SC-002, SC-003, SC-004, SC-005, SC-006, SC-007, SC-008, SC-009, SC-010, SC-011, SC-012, SC-013, SC-014, SC-015]
- [ ] T029 Prepare review evidence with a Proposal 145-style gap ledger classifying lifecycle/governance behavior as `implemented`, `enforced`, `observable`, and `documented`. Any gap in prompt truth, state snapshot, packet shape, fixtures, smoke evidence, or status-check coverage must be fixed or explicitly sent back before release promotion. [effort: 0.5 SP] [FR-022, FR-023, FR-024, FR-025, FR-026, FR-027, FR-028, TG-006] [SC-011, SC-012, SC-013, SC-014, SC-015] [review-lens: output-synthesis]
- [ ] T030 Confirm the final implementation does not expand into full Proposal 150, hook enforcement, broad historical Proposal 151 migration, or lifecycle redesign; record any scope-risk finding in review evidence before release promotion. [effort: 0.25 SP] [TG-005] [SC-011]

## Dependency Graph

```text
T001 -> T002 -> T003
T003 -> T004 -> T005 -> T006
T004 -> T007 -> T008 -> T009 -> T010
T007,T008,T009 -> T011 -> T012,T013,T014,T015 -> T016
T011,T014,T015 -> T017,T018,T019,T020,T021
T011,T014 -> T022,T023,T024
T003 -> T025 -> T026
T006,T010,T016,T021,T022,T023,T024,T026 -> T027 -> T028 -> T029 -> T030
```

## Parallel Opportunities

- T004 and T003 are sequentially gated by context and test discovery, but T007/T008/T009 can be implemented in close succession once policy resolution shape is clear.
- T012, T013, T014, and T015 can be split by packet section ownership after T011 lands.
- T017, T018, T019, T020, and T021 can run in parallel after the packet contract surface exists.
- T022, T023, and T024 can run in parallel after the packet contract surface exists.
- T025/T026 can proceed independently from packet-fixture work once T003 selects the validation surface.

## Quality Gates and Acceptance Criteria

### Before Implementation

- Tasks are reviewed and approved by the human.
- Dirty working-tree classification from T002 is performed before staging implementation changes.
- Scope exclusions are rechecked: no full Proposal 150, no hook enforcement, no broad historical Proposal 151 migration, no lifecycle redesign.

### Implementation Complete

- Generated prompt derives human-judgment boundary guidance from `.specrew/config.yml`.
- Generated [start-context.json](file:///C:/tmp/Specrew-main-boundary-auth/.specrew/start-context.json) includes `boundary_enforcement.policy_classes`.
- Generated prompt does not contain the beta2-bad four-gate-only or auto-chain guidance.
- Generated prompt includes all six human re-entry packet sections and contextual prompt guidance.
- Generated future prompt uses the packet as the primary stop contract without requiring duplicate legacy `=== SPECREW HANDOFF ===` output.
- Tests include positive prompt contract coverage, negative beta2-bad prompt coverage, missing `Why I stopped`, approve-only handoff, context-free prompt fixture, `discuss prompt #N`, and `Status: Approved` contradiction coverage.
- [beta3-smoke-evidence.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/smoke/beta3-smoke-evidence.md) is committed with required evidence fields.

### Review Complete

- Review includes the implemented/enforced/observable/documented gap ledger.
- Any gap is fixed or explicitly sent back before release promotion.

## Traceability Matrix

| Task Range | User Stories | Functional Requirements | Success Criteria | Proposal 145 Lens |
| --- | --- | --- | --- | --- |
| T001-T003 | US1, US2, US3 | FR-006, FR-007, FR-021, TG-004, TG-005, TG-006 | SC-002, SC-004, SC-005, SC-008, SC-009, SC-010 | Context load, branch hygiene |
| T004-T006 | US1 | FR-001, FR-002, FR-004, FR-020 | SC-001, SC-003 | Functional correctness, state truth |
| T007-T010 | US1, US3 | FR-001, FR-003, FR-004, FR-006, FR-007 | SC-002, SC-003, SC-006 | Functional correctness, test integrity |
| T011-T016 | US2, US3 | FR-008 through FR-019 | SC-004, SC-005, SC-008, SC-009, SC-010 | Human factors, functional correctness |
| T017-T021 | US2, US3 | FR-017, FR-023, FR-024, FR-025, FR-026, FR-027, FR-028 | SC-012, SC-013, SC-014, SC-015 | Human factors, test integrity |
| T022-T024 | US2, US3 | FR-009, FR-011, FR-014, FR-015, FR-016, FR-018 | SC-008, SC-009, SC-010 | Test integrity |
| T025-T026 | US1, US3 | FR-005, FR-021, TG-005 | SC-007 | Functional correctness, system safety |
| T027 | US1, US2, US3 | FR-022 | SC-006, SC-011 | System safety, release evidence |
| T028-T030 | US1, US2, US3 | FR-007, FR-021, FR-022, FR-023, FR-024, FR-025, FR-026, FR-027, FR-028, TG-005, TG-006 | SC-001 through SC-015 | Output synthesis |

## Effort Verification

| Phase | Tasks | Planned SP |
| --- | --- | --- |
| Context and hygiene | T001-T003 | 1.5 |
| Policy and state | T004-T006 | 2.0 |
| Prompt truth | T007-T010 | 2.5 |
| Packet contract | T011-T021 | 6.75 |
| Fixtures and status check | T022-T026 | 3.0 |
| Smoke, validation, review readiness | T027-T030 | 2.0 |

The summed task markup is intentionally conservative for a release-blocking governance slice. If implementation discovers overlap that lowers effort, retain the task boundaries for review traceability rather than merging away required evidence.

## Next Steps

1. Review [tasks.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/tasks.md) for completeness and traceability.
2. Run after-tasks traceability validation.
3. Execute before-implement hardening and iteration planning after explicit human approval.
4. Implement tasks in dependency order with focused commits and no unrelated dirty-state staging.

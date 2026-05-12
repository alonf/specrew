# Tasks: Descriptive References in Handoffs

**Input**: Design documents from `C:\Dev\Specrew\specs\012-descriptive-id-handoffs\`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/descriptive-reference-handoff.md`  
**Tests**: Existing handoff-governance regression commands are required for the baseline and closeout; new scaffold-replay-path integration coverage lands only in Iteration 002 to preserve the approved split.  
**Scope Boundary**: Keep Iteration 001 limited to descriptive-reference guidance/rule rollout for authored narration and stop messages; reserve replay-path integration coverage, corpus seeding, and documentation polish for Iteration 002, and never widen the rule to tool-rendered or other excluded verbatim surfaces.

## Format: `[ID] [P?] [Story?] [Owner] [Effort] Description`

- **[P]**: Can run in parallel once dependencies are satisfied
- **[Story?]**: Present only for user-story tasks as `[US1]`, `[US2]`, or `[US3]`
- **[Owner]**: Primary owner role aligned to the approved requirement ownership in `spec.md`
- **[Effort]**: Relative implementation effort estimate (`S`, `M`, `L`)
- Every task includes exact file path(s) and explicit traceability to approved requirements, success criteria, plan clauses, or contract clauses

---

## Phase 1: Setup

**Purpose**: Establish the execution baseline and lock the approved feature boundary before shared validator and guidance work begins.

- [ ] T001 [Owner: Reviewer] [Effort: M] Run the pre-implementation baseline from repo root using `tests/integration/handoff-governance-jargon-response-test.ps1`, `tests/integration/handoff-governance-plain-language-response-test.ps1`, `tests/integration/handoff-governance-review-file-reference-test.ps1`, and `extensions/specrew-speckit/scripts/validate-governance.ps1`, then record the baseline result in `specs/012-descriptive-id-handoffs/plan.md`. (Trace: quickstart.md Pre-Implementation Baseline, TG-005, plan.md Required Quality Gates)
- [ ] T002 [P] [Owner: Planner] [Effort: S] Review `specs/012-descriptive-id-handoffs/spec.md`, `specs/012-descriptive-id-handoffs/plan.md`, `specs/012-descriptive-id-handoffs/research.md`, `specs/012-descriptive-id-handoffs/data-model.md`, `specs/012-descriptive-id-handoffs/quickstart.md`, and `specs/012-descriptive-id-handoffs/contracts/descriptive-reference-handoff.md` to confirm the two-iteration boundary, the authored-prose-only scope, and the non-blocking enforcement limit before editing implementation surfaces. (Trace: TG-004, TG-006, research.md Summary of Resolutions, plan.md Iteration Breakdown)

---

## Phase 2: Foundational (Blocking Prerequisites for Iteration 001)

**Purpose**: Implement the shared descriptive-reference rule and contract language that both P1 user stories rely on.

**⚠️ CRITICAL**: No user-story work should begin until the validator rule stays additive and the shared handoff contract is updated.

- [ ] T003 [Owner: Handoff-governance maintainer] [Effort: M] Extend `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` so authored narration and stop-message prose are scanned for opaque numeric references, excluded verbatim surfaces stay ignored, the threshold remains three-or-more references, and any new finding remains a soft warning alongside existing feature 007 findings. (Trace: FR-006, FR-008, FR-009, FR-010, TG-005, GOV-C1, GOV-C2, GOV-C3, GOV-C4)
- [ ] T004 [Owner: Coordinator maintainer] [Effort: M] Update `specs/001-specrew-product/contracts/coordinator-handoff-template.md` with shared descriptive-reference semantics for narration and stop messages, including grouped-list scope, commit explanation expectations, and preserved feature 007 progress-status / recommended-next-step fields. (Trace: FR-001, FR-002, FR-003, FR-004, FR-005, FR-010, TG-001, TG-002, NAR-C1, NAR-C2, NAR-C3, NAR-C4, NAR-C6, STOP-C1, STOP-C2, STOP-C3, STOP-C4)

**Checkpoint**: The shared validator and contract foundation is ready for the Iteration 001 story rollout.

---

## Phase 3: Iteration 001 - User Story 1 - Readable in-flight narration (Priority: P1) 🎯 MVP

**Goal**: Make in-flight narration understandable on first read by pairing numeric references with descriptive meaning everywhere Squad authors user-facing progress text.

**Independent Test**: Review narration guidance in `extensions/specrew-speckit/prompts/coordinator-response.md`, `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, and `specs/001-specrew-product/contracts/coordinator-handoff-template.md`; confirm feature, iteration, task, requirement, corpus, and commit references always carry inline or shared descriptive scope for a first-time reader.

- [ ] T005 [P] [US1] [Owner: Prompt maintainer] [Effort: M] Update `extensions/specrew-speckit/prompts/coordinator-response.md` with explicit narration rules for descriptive scope, grouped shared-scope handling, excluded-surface exclusions, and acceptable/unacceptable narration examples. (Trace: FR-001, FR-002, FR-003, FR-004, FR-006, FR-007, TG-001, NAR-C1, NAR-C2, NAR-C3, NAR-C4, NAR-C5)
- [ ] T006 [P] [US1] [Owner: Agent-guidance maintainer] [Effort: S] Update `.github/agents/squad.agent.md` so the installed Squad startup guidance uses descriptive work labels for narration and does not fall back to opaque numeric-only references. (Trace: FR-005, FR-007, TG-001, plan.md Drift/Reconciliation Gate)
- [ ] T007 [P] [US1] [Owner: Agent-guidance maintainer] [Effort: S] Mirror the same descriptive-reference narration guidance changes from `.github/agents/squad.agent.md` into `.squad/templates/squad.agent.md` so source and deployed startup instructions stay aligned. (Trace: FR-005, FR-007, FR-010, TG-001, plan.md Drift/Reconciliation Gate)
- [ ] T008 [US1] [Owner: Reviewer] [Effort: M] Run targeted narration spot checks against `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`, `extensions/specrew-speckit/prompts/coordinator-response.md`, `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, and `specs/001-specrew-product/contracts/coordinator-handoff-template.md` to confirm opaque numeric narration is warned only when descriptive scope is missing and excluded surfaces remain ignored. (Trace: SC-001, SC-002, TG-001, GOV-C2, GOV-C3)

**Checkpoint**: User Story 1 is independently understandable from the live narration prompt, the shared contract, and both Squad startup guidance surfaces.

---

## Phase 4: Iteration 001 - User Story 2 - Readable stop messages and handoffs (Priority: P1)

**Goal**: Make stop messages, blocked-work summaries, follow-up lists, and commit references understandable without forcing the reviewer to decode internal IDs.

**Independent Test**: Review stop-message guidance in `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`, `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md`, and the validator rule; confirm completed-work, blocker, follow-up, and commit references remain understandable from the handoff text alone.

- [ ] T009 [P] [US2] [Owner: Prompt maintainer] [Effort: M] Update `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md` with stop-message requirements for descriptive scope on completed-work, blocked-work, follow-up, and commit references, plus acceptable/unacceptable handoff examples. (Trace: FR-001, FR-002, FR-003, FR-007, TG-002, STOP-C1, STOP-C2, STOP-C3)
- [ ] T010 [P] [US2] [Owner: Handoff-governance maintainer] [Effort: M] Update `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md` with review checkpoints for descriptive references, grouped-list shared scope, excluded verbatim surfaces, non-blocking governance behavior, and preserved feature 007 progress-status / recommended-next-step expectations. (Trace: FR-006, FR-007, FR-010, TG-002, TG-005, STOP-C4, GOV-C1, GOV-C2, GOV-C3, GOV-C4, C-002, C-003)
- [ ] T011 [US2] [Owner: Reviewer] [Effort: M] Validate stop-message and handoff samples across `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`, `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md`, and `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` to confirm the handoff text alone explains each numeric reference and each commit mention. (Trace: SC-001, SC-002, SC-003, TG-002, TG-005, STOP-C1, STOP-C2, STOP-C3, STOP-C4)

**Checkpoint**: Iteration 001 is complete once both narration and stop-message guidance surfaces are readable, aligned, and still additive to feature 007.

---

## Phase 5: Iteration 002 - User Story 3 - Governance checks reinforce readable references (Priority: P2)

**Goal**: Add bounded replay-path evidence and seeded examples so the descriptive-reference rule stays durable, low-noise, and explicitly non-blocking.

**Independent Test**: Run the descriptive-reference replay lane and compare warn/pass fixtures; confirm authored prose with three or more opaque numeric references is flagged, descriptive prose passes, and excluded verbatim surfaces are ignored.

- [ ] T012 [P] [US3] [Owner: Test-infrastructure maintainer] [Effort: M] Create replay fixtures under `tests/integration/fixtures/descriptive-reference-authored-prose/warn/`, `tests/integration/fixtures/descriptive-reference-authored-prose/pass/`, and `tests/integration/fixtures/descriptive-reference-excluded-surfaces/` covering opaque numeric references, valid shared scope, and excluded verbatim/tool-rendered content. (Trace: FR-008, FR-009, SC-004, TG-006, C-003, C-005)
- [ ] T013 [P] [US3] [Owner: Test-infrastructure maintainer] [Effort: M] Add authored-prose replay assertions to `tests/integration/descriptive-reference-authored-prose.ps1` that exercise narration and stop-message samples through the real governance review path and verify soft-warning vs pass outcomes. (Trace: FR-008, FR-009, TG-003, SC-004, GOV-C1, GOV-C2, GOV-C4, GOV-C5)
- [ ] T014 [P] [US3] [Owner: Test-infrastructure maintainer] [Effort: M] Add excluded-surface replay assertions to `tests/integration/descriptive-reference-excluded-surfaces.ps1` proving quoted blocks, code blocks, raw tool output, and Copilot-rendered tool-call result blocks do not count toward the descriptive-reference warning threshold. (Trace: FR-006, FR-009, TG-003, SC-004, GOV-C3, C-003)
- [ ] T015 [P] [US3] [Owner: Quality governance maintainer] [Effort: M] Seed descriptive-reference warn/pass examples in `.specrew/quality/known-traps.md` and update `extensions/specrew-speckit/governance/validation-lane.md` with the Iteration 002 replay commands and low-noise review expectations. (Trace: FR-007, FR-008, FR-009, SC-004, TG-003, TG-006, GOV-C5)
- [ ] T016 [US3] [Owner: Quality governance maintainer] [Effort: M] Create `specs/012-descriptive-id-handoffs/quality/hardening-gate.md` and `specs/012-descriptive-id-handoffs/quality/trap-reapplication.md` with the approved Iteration 002 evidence structure for authored-prose discrimination, feature 007 compatibility, replay coverage, and corpus reapplication. (Trace: plan.md Phase 2 Slice Scope, plan.md Hardening Focus Areas, TG-006, C-003, C-005)
- [ ] T017 [US3] [Owner: Reviewer] [Effort: M] Run the Iteration 002 replay lane using `tests/integration/descriptive-reference-authored-prose.ps1`, `tests/integration/descriptive-reference-excluded-surfaces.ps1`, `tests/integration/handoff-governance-jargon-response-test.ps1`, `tests/integration/handoff-governance-plain-language-response-test.ps1`, `tests/integration/handoff-governance-review-file-reference-test.ps1`, and `extensions/specrew-speckit/scripts/validate-governance.ps1` to confirm low-noise soft-warning behavior and excluded-surface handling. (Trace: SC-004, TG-003, TG-005, GOV-C1, GOV-C2, GOV-C3, GOV-C4, GOV-C5)

**Checkpoint**: User Story 3 is complete once replay-path evidence, corpus seeds, and non-blocking governance proof all align with the approved rule.

---

## Phase 6: Polish & Cross-Cutting Concerns (Iteration 002 Closeout)

**Purpose**: Finish documentation polish, rerun the full lane, and audit the final scope boundary before handoff.

- [ ] T018 [Owner: Documentation maintainer] [Effort: S] Update `specs/012-descriptive-id-handoffs/quickstart.md` and `specs/012-descriptive-id-handoffs/plan.md` with the final Iteration 002 validation-lane commands and closeout notes once replay coverage and corpus seeding land. (Trace: quickstart.md Post-Implementation Validation Expectations, plan.md Iteration Breakdown, TG-006)
- [ ] T019 [Owner: Reviewer] [Effort: M] Run the full closeout lane from repo root using `tests/integration/handoff-governance-jargon-response-test.ps1`, `tests/integration/handoff-governance-plain-language-response-test.ps1`, `tests/integration/handoff-governance-review-file-reference-test.ps1`, `tests/integration/descriptive-reference-authored-prose.ps1`, `tests/integration/descriptive-reference-excluded-surfaces.ps1`, and `extensions/specrew-speckit/scripts/validate-governance.ps1`, then record the final evidence in `specs/012-descriptive-id-handoffs/quickstart.md` and `specs/012-descriptive-id-handoffs/quality/trap-reapplication.md`. (Trace: SC-001, SC-002, SC-004, TG-005, quickstart.md Post-Implementation Validation Expectations)
- [ ] T020 [Owner: Planner] [Effort: S] Audit the final diff across `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`, `extensions/specrew-speckit/prompts/coordinator-response.md`, `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`, `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md`, `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, `tests/integration/descriptive-reference-authored-prose.ps1`, `tests/integration/descriptive-reference-excluded-surfaces.ps1`, `tests/integration/fixtures/descriptive-reference-authored-prose/`, `tests/integration/fixtures/descriptive-reference-excluded-surfaces/`, `.specrew/quality/known-traps.md`, and `extensions/specrew-speckit/governance/validation-lane.md` to confirm the feature stayed additive, non-blocking, and limited to authored narration / stop messages. (Trace: FR-010, TG-004, TG-005, plan.md Constraints)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup** → no dependencies
- **Phase 2: Foundational** → depends on Phase 1 and blocks both Iteration 001 user stories
- **Phase 3: Iteration 001 - US1** → depends on Phase 2
- **Phase 4: Iteration 001 - US2** → depends on Phase 2 and should complete before Iteration 001 is considered done
- **Phase 5: Iteration 002 - US3** → depends on Phase 2, plus completed Iteration 001 guidance/rule rollout from Phases 3-4
- **Phase 6: Polish & Cross-Cutting Concerns** → depends on Phase 5 and any remaining Iteration 001 validation gaps being closed

### User Story Dependencies

- **US1 (P1)**: No user-story dependency after the foundational validator and contract work; this is the narrowest MVP slice
- **US2 (P1)**: Depends on the shared validator + contract from Phase 2, but not on replay-path evidence
- **US3 (P2)**: Depends on completed Iteration 001 wording and rule behavior so replay-path fixtures are seeded against stable guidance

### Iteration Dependencies

- **Iteration 001** = T001-T011. This iteration covers only descriptive-reference guidance/rule rollout across validator, contract, prompts, checklist, and Squad startup guidance.
- **Iteration 002** = T012-T020. This iteration adds replay-path integration coverage, corpus seeding, `quality/` evidence artifacts, and documentation polish only after Iteration 001 is stable.

### Within Each User Story

- Complete shared validator and contract updates before story-specific guidance edits
- Keep `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md` text aligned in the same change window
- Seed fixtures before writing replay assertions in Iteration 002
- Rerun the existing handoff-governance regression commands before closing Iteration 002

### Parallel Opportunities

- `T001` and `T002` can overlap once the feature boundary review starts
- `T005`, `T006`, and `T007` can run in parallel because they touch different narration surfaces
- `T009` and `T010` can run in parallel because the decision guidance and checklist are separate files
- `T012`, `T013`, `T014`, and `T015` can run in parallel once Iteration 002 begins because fixtures, replay tests, and corpus/documentation updates live in different paths

---

## Parallel Example: Iteration 001 - User Story 1

```text
Task: "T005 [US1] Update extensions/specrew-speckit/prompts/coordinator-response.md with descriptive-scope narration rules and worked examples"
Task: "T006 [US1] Update .github/agents/squad.agent.md so installed Squad startup guidance uses descriptive work labels"
Task: "T007 [US1] Update .squad/templates/squad.agent.md to mirror the same descriptive-reference narration guidance"
```

## Parallel Example: Iteration 002 - User Story 3

```text
Task: "T012 [US3] Create warn/pass replay fixtures under tests/integration/fixtures/descriptive-reference-authored-prose/ and tests/integration/fixtures/descriptive-reference-excluded-surfaces/"
Task: "T013 [US3] Add authored-prose replay assertions in tests/integration/descriptive-reference-authored-prose.ps1"
Task: "T014 [US3] Add excluded-surface replay assertions in tests/integration/descriptive-reference-excluded-surfaces.ps1"
Task: "T015 [US3] Seed .specrew/quality/known-traps.md and update extensions/specrew-speckit/governance/validation-lane.md"
```

---

## Implementation Strategy

### MVP First (Iteration 001 / User Story 1 First)

1. Complete Phase 1 and Phase 2
2. Deliver `T005` through `T008` for the narration-first MVP slice
3. Validate User Story 1 independently before broadening the rollout to stop messages
4. Complete User Story 2 before declaring Iteration 001 done

### Incremental Delivery

1. Ship the shared validator + contract foundation
2. Roll out readable narration guidance (US1)
3. Roll out readable stop-message and handoff guidance (US2)
4. Add replay-path evidence, corpus seeding, and `quality/` closeout artifacts (US3)
5. Finish with validation-lane polish and final scope audit

### Story-Independent Test Criteria

- The existing three handoff-governance regression commands must still pass after each iteration
- The descriptive-reference rule must stay a soft warning only
- Excluded verbatim content must never count toward the opaque-reference threshold
- `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md` must remain semantically aligned
- No task may widen the feature to tool-rendered output, historical transcripts, or unrelated governance checks

### Suggested MVP Scope

- **Minimum MVP**: Phase 1 + Phase 2 + Phase 3 (`T001`-`T008`)
- **Release-ready Iteration 001 scope**: Phase 1 through Phase 4 (`T001`-`T011`)

---

## Notes

- All tasks follow the required checklist format: checkbox, task ID, optional `[P]`, optional story label, explicit `[Owner: ...]`, explicit `[Effort: ...]`, exact file path(s), and explicit `(Trace: ...)`
- Iteration 001 intentionally avoids new replay-path files so the approved two-iteration split remains intact
- Iteration 002 is the first point where `specs/012-descriptive-id-handoffs/quality/` artifacts are created
- The feature remains bounded to Squad-authored narration and stop messages; verbatim tool output, quoted material, code blocks, and Copilot-rendered tool-call result blocks stay out of scope

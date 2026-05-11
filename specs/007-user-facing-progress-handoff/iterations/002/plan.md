# Iteration Plan: 002

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: planned  
**Capacity**: 10/20 story_points  
**Planned**: 2026-05-11

## Summary

Iteration 002 carries **Phase 3: Validation & Integration** — soft-validator runtime implementation, integration tests, validation lane updates, and polish. The hardening-gate.md planning artifact is drafted during planning (before implementation authorization). This iteration builds on the Foundation & Governance artifacts delivered in Iteration 001 (coordinator prompt, handoff template, decision guidance, Squad.agent.md codification, governance checklist, soft-validator concept design).

**Primary Focus**: Runtime soft-validator that flags missing handoff fields and three-or-more-acronyms pattern without blocking response delivery  
**Target Slice**: Phase 3 (`T007`-`T010`)  
**Prior Completion**: Iteration 001 delivered all Phase 1 + Phase 2 Foundation & Governance tasks (T001-T006, 10 sp) with zero drift and perfect estimation accuracy

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-016 | Soft Quality Warning — missing handoff fields = soft warning, not hard failure | ✅ `T007`, `T008`, `T009` | Governance-validator maintainer | Runtime validator + integration tests + validation lane registration |
| Human-Handoff Trap | Three-or-more governance acronyms in lead without plain-language paraphrase | ✅ `T007`, `T008` | Governance-validator maintainer | Formalized detection rule from `.specrew/quality/known-traps.md` row 12 |
| Test-Integrity | Integration tests must exercise actual validation runtime path | ✅ `T008` | Test maintainer | Cannot satisfy coverage by validating checklist artifact content alone |
| Validation-Lane-Completeness | Authorized commands documented in both plan and hardening-gate evidence | ✅ `T009` | Governance-validator maintainer | Cross-check authorization before sign-off |
| Iteration-005 Schema | Hardening gate uses Overall Verdict field + pending metadata + five canonical concerns first | ✅ `T010` | Feature owner | Pre-sign-off schema from `.specrew/quality/known-traps.md` row 9 |
| FR-001 to FR-015 | Foundation handoff semantics | ✅ Completed in Iteration 001 | — | Coordinator prompt, template, decision guidance, Squad.agent.md, governance checklist |
| US1, US2, US3 | User stories for clear completion handoff, blocker understanding, lightweight fluency | ✅ Iteration 001 + `T008`, `T010` | — | Guidance delivered in Iteration 001; test coverage and polish in Iteration 002 |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | Scope limited to Phase 3 (T007-T010) from approved `tasks.md`; Foundation & Governance explicitly complete in Iteration 001 |
| **Traceability** | ✅ PASS | Every task maps to Phase 3 requirements (FR-016, human-handoff trap, test-integrity, validation-lane-completeness, iteration-005 schema) with dependencies on completed Iteration 001 artifacts |
| **Ownership** | ✅ PASS | Task owners align to baseline Specrew roles in spec.md Requirement Ownership & Delivery |
| **Capacity** | ✅ PASS | 10/20 story_points; truthful slice with honest Phase 3 boundary |
| **Execution Support** | ✅ PASS | T006 soft-validator concept design provides clear implementation target; Iteration 001 retro identified session-restart boundary (satisfied) and soft-validator implementation clarity as action items |

---

## Phase 3 Quality Planning

**Phase Scope**: `phase-3-validation-integration` — Soft-validator runtime, integration tests, validation lane updates, polish  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for PowerShell governance scripts, Markdown/YAML/JSON artifact contracts, deterministic integration tests.

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| Soft-validator detection correctness | `required` | T007 must correctly detect missing progress status, missing next step, and three-or-more-acronyms pattern without false positives |
| Integration test coverage integrity | `required` | T008 must exercise actual soft-validator runtime path (not just checklist artifact validation) with assertions on user-visible output |
| Validation lane authorization accuracy | `required` | T009 must document exact authorized soft-validator commands in both plan task definition AND hardening-gate concern evidence; cross-check before sign-off to prevent validation-lane-completeness drift |
| Hardening gate schema compliance | `required` | T010 hardening-gate.md must use Iteration 005 pre-sign-off schema: Overall Verdict field, pending metadata, five canonical concerns first |
| Plain-language-first absorption | `required` | T007 soft-validator must implement detection rule from T006 design document without ambiguity; T008 must validate against human-handoff trap examples |
| Session-restart boundary awareness | `satisfied` | Iteration 001 T004 Squad.agent.md update required session restart; this boundary was satisfied before Iteration 002 planning began (per Iteration 001 retro.md line 54) |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T007 | Implement soft-validator handoff-governance check | FR-016, human-handoff trap | US2 | 4 | Governance-validator maintainer | `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | planned | — | — | — |
| T008 | Create integration tests for handoff validator | FR-016, human-handoff trap, test-integrity | US1, US2, US3 | 3 | Test maintainer | `tests/integration/handoff-governance-jargon-response-test.ps1`, `tests/integration/handoff-governance-plain-language-response-test.ps1` | planned | — | — | — |
| T009 | Update validation lane integration | FR-016, validation-lane-completeness | Cross-cutting | 2 | Governance-validator maintainer | `extensions/specrew-speckit/governance/validation-lane.md` (or equivalent authorized-commands registry) | planned | — | — | — |
| T010 | Polish & post-implementation hardening-gate evidence recording | iteration-005 schema, TG-001, TG-002, TG-003 | Cross-cutting | 1 | Feature owner | `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md`, `specs/007-user-facing-progress-handoff/iterations/002/quality/hardening-gate.md` | planned | — | — | — |

**Total Effort**: 10 story_points

---

## Task Detail

### T007: Implement soft-validator handoff-governance check

**Owner**: Governance-validator maintainer  
**File**: `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`  
**Scope**: Runtime detection of: (1) missing current progress status, (2) missing recommended next step, (3) three-or-more-governance-acronyms rule violation

**Implementation Contract**: T006 soft-validator design document (`extensions/specrew-speckit/design/soft-validator-handoff-governance.md`) provides the implementation target. Detection rules, pseudo-code, integration points, and expected output shape are specified without ambiguity.

**Integration**: Register with governance checklist surface (`extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`). Hook into post-response coordinator output path. Soft-validator MUST flag missing fields without blocking response delivery.

**Governance-Term Candidate Set**: Start with configurable list from T006 design: `before-implement`, `hardening-gate`, `approval ref`, `implementation approval`, `traceability`, `schema`, `FR-`, `TG-`, `gate`, `validator`. List may expand, but human-handoff trap examples must be detectable without ambiguity.

**Expected Output Shape**:
```text
status: warn
findings:
  - soft-warning.jargon-first-lead
summary:
  - Rewrite the lead sentence in plain language before formal lifecycle references.
```

**Acceptance**: Soft-validator executes against synthetic coordinator response text and emits soft warnings for missing handoff fields or jargon-first lead without blocking response delivery. Integration tests (T008) validate detection correctness.

**Effort**: 4 story_points

---

### T008: Create integration tests for handoff validator

**Owner**: Test maintainer  
**Files**: 
- `tests/integration/handoff-governance-jargon-response-test.ps1`
- `tests/integration/handoff-governance-plain-language-response-test.ps1`

**Scope**: Two test fixtures with validation logic exercising the actual soft-validator runtime path (T007).

**Fixture 1: Jargon-First Response (Must Flag)**

Synthetic coordinator response containing 3+ governance acronyms in lead without plain-language paraphrase:

Example violation text:
> `before-implement gate, hardening-gate sign-off, Implementation Approval evidence reuse, and governance trap`

Expected result: `handoff-governance-validator.ps1` flags as `soft-warning.jargon-first-lead`

**Fixture 2: Plain-Language-First Response (Must Pass)**

Synthetic coordinator response with plain-language lead followed by formal references in subsection:

Example compliant text:
> "We need three decisions before moving forward: (1) approval to proceed to implementation, (2) sign-off on our governance controls, (3) confirmation that we can reuse existing approval evidence. [formal references: before-implement gate, hardening-gate sign-off, Implementation Approval evidence reuse]"

Expected result: `handoff-governance-validator.ps1` passes without flag

**Test-Integrity Requirement**: Both fixtures must invoke the soft-validator runtime itself (not just mock internal state). Must assert user-visible output and governance surface response. Aligns with test-integrity trap (`.specrew/quality/known-traps.md` row 14).

**Acceptance**: Both tests pass against the soft-validator (T007). Tests exercise actual validation path with assertions on user-visible output.

**Effort**: 3 story_points

---

### T009: Update validation lane integration

**Owner**: Governance-validator maintainer  
**File**: `extensions/specrew-speckit/governance/validation-lane.md` (or equivalent authorized-commands registry)  
**Scope**: Register soft-validator command in authorized-commands list and add handoff-governance-validator task to validation-lane execution.

**Validation-Lane-Completeness Requirement**: Document exact authorized soft-validator commands in both:
1. Validation lane task definition (this file or equivalent)
2. Hardening-gate concern evidence (T010, `specs/007-user-facing-progress-handoff/iterations/002/quality/hardening-gate.md`)

Cross-check authorization against plan.md T007 definition before sign-off to prevent validation-lane-completeness drift (`.specrew/quality/known-traps.md` row 10).

**Authorized Command Example**:
```powershell
& '.\extensions\specrew-speckit\validators\handoff-governance-validator.ps1' -ResponseText $coordinatorResponse
```

**Acceptance**: Soft-validator command registered in authorized list and documented in both validation lane and hardening-gate evidence with human approval if list changes.

**Effort**: 2 story_points

---

### T010: Polish & post-implementation hardening-gate evidence recording

**Owner**: Feature owner (Alon Fliess)  
**Scope**: Final checklist tuning, template review, and post-implementation hardening-gate evidence recording

**Deliverables**:
1. Final tuning of all governance-checklist wording for clarity and consistency (`extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`)
2. Final review of handoff template examples for completeness across all three user stories (US1, US2, US3) (`specs/001-specrew-product/contracts/coordinator-handoff-template.md`)
3. Post-implementation evidence recording in existing hardening-gate.md (`specs/007-user-facing-progress-handoff/iterations/002/quality/hardening-gate.md`)

**Post-Implementation Evidence Requirements**:
- Update `Runtime Evidence Status` fields from `pending-post-implementation` to `recorded` for all applicable concerns
- Record validation lane execution results (T009 authorized commands)
- Record integration test pass evidence (T008 fixtures)
- Record soft-validator correctness verification (T007 detection accuracy)
- Update `Post-Implementation Verification` field to `✅ COMPLETE`
- Update `Verified At` field with completion timestamp

**Acceptance**: Checklist and template reviewed for completeness. Post-implementation evidence recorded in hardening-gate.md after T007-T009 complete. Documentation ready for final review.

**Effort**: 1 story_point

**Note**: The pre-implementation hardening-gate.md is a planning-time artifact created before implementation starts, not part of T010 scope. T010 records post-implementation evidence only.

---

## Planned Execution Order

1. **Soft-Validator Implementation**: `T007` implements the runtime validator based on T006 design contract
2. **Parallel Test Development**: `T008` develops integration test fixtures in parallel with T007, using T006 design patterns
3. **Validation Lane Registration**: `T009` registers soft-validator command after T007 implementation completes and T008 tests pass
4. **Final Polish**: `T010` runs after T007-T009 complete; final checklist/template tuning and post-implementation hardening-gate evidence recording

**Concurrency Notes**: T007 and T008 can execute in parallel if T008 test implementer references T006 design document directly. T009 must wait for T007 completion and T008 test pass. T010 runs last as final polish and post-implementation hardening-gate evidence recording.

---

## Deferred Follow-On

| Deferred Task(s) | Target Iteration | Reason |
| ---------------- | ---------------- | ------ |
| Feature 007 closeout validation sampling | Feature closeout (post-Iteration 002) | Handoff-contract durability validation via representative Squad completion sampling (recommended in Iteration 001 retro as Improvement Action #3) |

All feature 007 implementation work is scoped to Iterations 001-002. Feature closeout will include representative sampling validation before final sign-off.

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20.0 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | The Planner must make any future deferral decision explicit. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments when actual variance accumulates. |

---

## Concurrency Rationale

- Current roster snapshot: Governance-validator maintainer, Test maintainer, Feature owner
- Technology and scope signals: PowerShell governance scripts, deterministic integration tests, Markdown/YAML artifact updates
- Task dependency graph: T006 (Iteration 001) → T007 → T009; T006 → T008 (parallel with T007); T007+T008+T009 → T010
- Workstream separability: High. T007 (validator implementation) and T008 (integration tests) work on distinct surfaces and can execute in parallel. T009 (validation lane) depends on T007 completion. T010 (polish) waits for all prior tasks.
- Shared-surface conflict risk: Low. T007 creates new validator file. T008 creates new test files. T009 updates validation lane registry. T010 reviews/tunes existing artifacts without conflicting with prior work.
- Recommendation: Run T007 and T008 in parallel. After both pass, run T009. After all three complete, run T010 as final polish and post-implementation hardening-gate evidence recording.

---

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Iteration slicing, traceability packaging, this plan document |
| Discovery/Spikes | 0 | No separate spike authorized; T006 design document provides clear implementation target |
| Implementation | 10 | T007 (soft-validator), T008 (integration tests), T009 (validation lane), T010 (polish) |
| Review | 1 | Review soft-validator implementation, integration tests, validation lane updates, and hardening-gate draft |
| Rework | 0 | Small buffer reserved if validation finds issues or tests reveal detection gaps |

---

## Implementation Approval

- **Approval Verdict**: *(pending planning-level approval)*
- **Approved By**: *(pending human sign-off)*
- **Recorded Evidence**: *(pending)*
- **Recorded At**: *(pending)*
- **Scope Authorized**: Phase 3 (T007-T010, 10 story_points)
- **Gate Effect**: Planning stops at hardening-gate draft sign-off. Implementation authorization triggers T007-T009 execution. T010 records post-implementation evidence only.

---

## Iteration 001 Retro Learnings Carried Forward

### From Iteration 001 Retrospective (2026-05-11):

**Perfect Estimation Accuracy Pattern**: Iteration 001 delivered 10 story points at estimated effort with zero variance. This precision reflects well-defined coordination work and honest task decomposition. Iteration 002 planning maintains this discipline by scoping only Phase 3 runtime work with clear boundaries.

**Session-Restart Boundary (Satisfied)**: T004 Squad.agent.md update required session restart. Per Iteration 001 retro.md line 54: "This boundary has been satisfied: Iteration 001 was committed, the session restarted, and this session loaded the updated guidance. Iteration 002 planning proceeds in this session with the new coordinator baseline already active."

**Soft-Validator Implementation Clarity**: Iteration 001 Improvement Action #2 states: "Iteration 002 must begin with explicit understanding that T006 (soft-validator design) is the implementation contract. T007-T009 (runtime validator, integration tests, governance checklist integration) are the delivery tasks." This plan explicitly references T006 as the implementation target for T007.

**Plain-Language-First Principle Absorption**: Iteration 001 successfully absorbed the governance-acronym trap detection rule into coordinator prompt, handoff template, decision guidance, governance checklist, and soft-validator concept design. Iteration 002 T007 implements the runtime detection logic specified in T006.

**Handoff-Contract Durability Validation**: Iteration 001 Improvement Action #3 deferred to feature closeout: "Before feature closeout, sample representative Squad completions across at least three response types (implementation, review, lifecycle) to validate that final user-facing responses consistently include both current progress status and recommended next step."

---

## Notes

- This plan carries Phase 3 Validation & Integration work only—soft-validator runtime, integration tests, validation lane updates, and polish—after Iteration 001 delivered all Phase 1 + Phase 2 Foundation & Governance tasks (T001-T006, 10 sp, zero drift, perfect estimation accuracy).
- T006 soft-validator design document provides clear implementation target for T007 without ambiguity.
- T008 integration tests exercise actual soft-validator runtime path (not just checklist artifact validation) per test-integrity trap requirements.
- T009 validation lane update cross-checks authorized commands against plan.md task definition and hardening-gate evidence to prevent validation-lane-completeness drift.
- T010 records post-implementation evidence in hardening-gate.md after T007-T009 complete. The pre-implementation hardening-gate.md is a planning-time artifact created before implementation starts, not part of T010 scope.
- Session-restart boundary (required by Iteration 001 T004 Squad.agent.md changes) has been satisfied per Iteration 001 retro. This session began after Squad.agent.md update took effect. Iteration 002 planning proceeds with updated coordinator guidance active.
- With Iteration 002 completion, Feature 007 implementation is complete. Feature closeout will include representative sampling validation before final sign-off.

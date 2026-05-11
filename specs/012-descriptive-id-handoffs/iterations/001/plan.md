# Iteration Plan: 001 — Readable-Reference Rule and Guidance Rollout

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: complete  
**Capacity**: 9.5/20 story_points  
**Planned Start**: 2026-05-11  
**Started**: 2026-05-11  
**Completed**: 2026-05-11  
**Closed**: 2026-05-11  
**Hardening-Gate Sign-Off**: signed-2026-05-11  
**Implementation Authorization**: authorized-2026-05-11  
**Review Completed**: 2026-05-11  
**Review Verdict**: accepted  
**Retrospective Completed**: 2026-05-11  
**Closeout Validation**: green-2026-05-11

## Summary

Deliver the readable-reference rule and user-facing guidance surfaces for described numeric references in authored handoff prose. Iteration 001 rolls out the shared validator rule, updates prompts, checklists, contracts, and Squad startup guidance, and provides worked examples. Iteration 002 defers replay-path integration coverage, corpus seeding, and the trap-reapplication follow-through artifact.

## Iteration Scope

| Category | Coverage | Boundary |
| --- | --- | --- |
| **User Stories** | US1 (Readable in-flight narration), US2 (Readable stop messages and handoffs) | US3 and integration evidence deferred to Iteration 002 |
| **Rollout Slice** | Descriptive-reference guidance and soft-warning rule for authored narration and stop messages | No blocking enforcement, no replay-path fixtures, no corpus seeding |
| **Tasks** | T001-T011 | T012-T020 deferred to Iteration 002 |
| **Primary Surfaces** | Validator rule, coordinator prompt guidance, decision guidance, checklist, contract/template, Squad startup guidance, worked examples | Replay-path integration coverage and corpus seeding remain deferred to Iteration 002 |

## Rollout Checklist

- [x] **T001**: Pre-implementation baseline from existing handoff-governance tests
- [x] **T002**: Feature boundary and two-iteration split confirmation
- [x] **T003**: Extend validator rule for opaque numeric references (shared foundational task)
- [x] **T004**: Update coordinator handoff contract (shared foundational task)
- [x] **T005-T007**: Readable narration guidance (US1, runs in parallel)
- [x] **T008**: Narration spot-check validation (US1)
- [x] **T009-T010**: Readable stop-message guidance (US2, runs in parallel)
- [x] **T011**: Stop-message and handoff validation (US2)

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ------- |
| T001 | Run pre-implementation baseline from existing handoff-governance tests and record baseline result | TG-005 | Foundation | 1 | Reviewer | done | pass |
| T002 | Review feature boundary, two-iteration split, scope, and non-blocking enforcement | TG-004, TG-006 | Foundation | 0.5 | Planner | done | pass |
| T003 | Extend validator rule for opaque numeric references in authored prose | FR-006, FR-008, FR-009, FR-010 | Foundation | 1 | Handoff-governance maintainer | done | pass |
| T004 | Update coordinator handoff contract with descriptive-reference semantics | FR-001 through FR-005, FR-010 | Foundation | 1 | Coordinator maintainer | done | pass |
| T005 | Update coordinator-response.md prompt with narration rules and examples | FR-001, FR-002, FR-003, FR-004, FR-006, FR-007 | US1 | 1 | Prompt maintainer | done | pass |
| T006 | Update .github/agents/squad.agent.md with descriptive narration guidance | FR-005, FR-007 | US1 | 0.5 | Agent-guidance maintainer | done | pass |
| T007 | Mirror descriptive-reference narration guidance into .squad/templates/squad.agent.md | FR-005, FR-007, FR-010 | US1 | 0.5 | Agent-guidance maintainer | done | pass |
| T008 | Run targeted narration spot checks against validator and guidance surfaces | SC-001, SC-002 | US1 | 1 | Reviewer | done | pass |
| T009 | Update coordinator-decision-guidance.md prompt with stop-message requirements and examples | FR-001, FR-002, FR-003, FR-007 | US2 | 1 | Prompt maintainer | done | pass |
| T010 | Update coordinator-handoff-governance.md checklist with descriptive reference checkpoints | FR-006, FR-007, FR-010 | US2 | 1 | Handoff-governance maintainer | done | pass |
| T011 | Validate stop-message and handoff samples across guidance surfaces and validator rule | SC-001, SC-002, SC-003 | US2 | 1 | Reviewer | done | pass |

**Total Effort**: 9.5 story_points

**Primary Files Modified**: `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`, `extensions/specrew-speckit/prompts/coordinator-response.md`, `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`, `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md`, `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`

**Key Constraints**:
- Limit changes to authored narration and stop-message prose only
- Exclude verbatim/tool-rendered/code/quoted surfaces from the rule
- Keep the rule as a soft warning only
- Preserve all existing feature 007 guidance and checks
- Keep `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md` synchronized

**Regression Baseline**: Run the pre-implementation baseline once before starting implementation:
```powershell
tests/integration/handoff-governance-jargon-response-test.ps1
tests/integration/handoff-governance-plain-language-response-test.ps1
tests/integration/handoff-governance-review-file-reference-test.ps1
extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

**Regression Validation**: After all tasks complete, re-run the same four commands to confirm no existing guidance was lost.

## Quality Gates

| Gate | Status | Evidence |
| --- | --- | --- |
| Feature boundary locked | pass | T001 baseline and T002 boundary review recorded in `specs/012-descriptive-id-handoffs/plan.md`; Iteration 001 remains limited to T001-T011 |
| Existing feature 007 compatibility | pass | Existing three handoff-governance tests plus `validate-governance.ps1 -ProjectPath .` stayed green after the validator and prompt/checklist/template edits |
| Prompt/checklist/contract alignment | pass | Validator, coordinator prompts, checklist, contract template, and stop-message validation script now describe the same descriptive-reference behavior |
| Squad startup guidance synchronization | pass | `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md` now carry the same readable-reference contract and restart-boundary warning |
| Worked example coverage | pass | Narration and stop-message prompts now include explicit acceptable and unacceptable readable-reference examples |

## Known Dependencies

- T003 and T004 are foundational and must complete before T005-T011 begin
- T005, T006, T007 can run in parallel (all narration guidance)
- T009, T010 can run in parallel (all stop-message guidance)
- `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md` must stay synchronized in the same commit

## Risk Tracking

| Risk | Mitigation | Status |
| --- | --- | --- |
| Validator rule detects the wrong numeric patterns | Validate rule scope against both US1 and US2 acceptance scenarios from spec.md | mitigation-planned |
| Existing feature 007 warnings are lost or changed | Regression commands serve as the primary baseline | mitigation-planned |
| Agent startup guidance drifts between `.github/` and `.squad/` versions | Synchronization enforced in the same task and verified in T008 | mitigation-planned |
| Worked examples don't match the actual rule behavior | Examples must be validated via spot-check against the real validator before closeout | mitigation-planned |

## Phase Dependencies

This iteration depends on:
- Planning artifacts from feature 012 being finalized (spec.md, plan.md, research.md, data-model.md, quickstart.md, contracts/descriptive-reference-handoff.md)
- Pre-implementation baseline from the existing three handoff-governance tests being recorded
- Fresh authorization from the Spec Steward for Iteration 001 hardening-gate sign-off and implementation start

## Success Criteria

Iteration 001 is considered complete when:

1. T001-T011 all pass independently
2. The four regression commands pass with no regressions from the baseline
3. Numeric references in narration and stop messages are understandable on first read
4. Grouped lists use shared scope only when the grouping is unmistakable
5. Excluded verbatim surfaces are not being flagged
6. Existing feature 007 handoff expectations still read naturally
7. The rule is still described as non-blocking everywhere it appears
8. `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md` carry the same descriptive-reference guidance

## Explicit Deferrals

- Replay-path integration tests remain deferred to Iteration 002
- Corpus seeding remains deferred to Iteration 002
- Trap-reapplication follow-through remains deferred to Iteration 002
- Any blocking enforcement remains out of scope
- Any expansion to tool-rendered output remains out of scope

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort; Iteration 001 uses 8 of 20 available, leaving 12 for contingency or future work. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20.0 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | Any deferral decision must be explicit; US3 explicitly deferred to Iteration 002. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments when actual variance accumulates. |


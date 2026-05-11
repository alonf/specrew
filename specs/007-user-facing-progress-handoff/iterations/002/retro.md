# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-05-11

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T007 | 4 | 4 | 0 |
| T008 | 3 | 3 | 0 |
| T009 | 2 | 2 | 0 |
| T010 | 1 | 1 | 0 |

**Average variance**: +/- 0  
**Utilization**: 10/20 story_points (50% of capacity)

Perfect estimation accuracy matched Iteration 001 pattern. All tasks completed at estimated effort with zero variance. Clear implementation contract (T006 design document) and stable scope contributed to this precision.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 0.5 | -0.5 | Plan document reuse and clear scope boundaries from Iteration 001 reduced clarification overhead |
| Discovery/Spikes | 0 | 0 | 0 | No surprises; T006 design document provided clear implementation target |
| Implementation | 10 | 10 | 0 | T007-T010 all completed at estimated effort; implementation stayed within bounds |
| Review | 1 | 2 | +1 | Discovery of FR-017 gap (checklist-validator parity break) required independent repair cycle before acceptance |
| Rework | 0 | 1 | +1 | Spec Steward repair added validator detection, integration test, lane observability, and evidence correction |

**Net variance**: +1 sp (review discovery + repair absorbed within available buffer)

## Drift Summary

- Total drift events: 1 (DR-001: FR-017 review-link enforcement/observability gap)
- Resolved via spec update: 0
- Resolved via implementation correction: 1 (Validator implementation, test fixture, lane observability added)
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

**Drift Timeline**: Detected during review on 2026-05-11, repaired same day by Spec Steward, closed by accepted re-review.  
**Closure Method**: Independent repair (non-author) routed to Spec Steward; all required layers updated (validator, test, lane, evidence).

## What Went Well

- **Perfect estimation accuracy**: All four tasks delivered at estimated effort (zero variance). Clear scope and implementation contract (T006 design document) made task boundaries precise.
- **Session-restart discipline held**: Iteration 001 T004 updated Squad.agent.md (startup-loaded config), required session restart, boundary was satisfied before Iteration 002 planning. Fresh session loaded updated guidance without friction.
- **Implementation contract clarity**: T006 soft-validator design document provided unambiguous specification for T007 (detection rules, pseudo-code, output format, test scenarios). No discovery rework needed.
- **Multi-layer governance absorption**: Plain-language-first principle embedded into coordinator prompt, handoff template, decision guidance, governance checklist, and soft-validator concept design ensures durability across session boundaries.
- **Review caught the gap cleanly**: FR-017 parity break detected during review before acceptance. Independent repair routed to Spec Steward, all required layers touched (validator implementation, test fixture, lane observability, evidence update), re-review accepted.
- **Validation lane integration worked**: After repair, `tests\integration\validation-contract-lane.ps1` and `validate-governance.ps1` both passed, proving the FR-017 negative-path regression is now observable.

## What Didn't Go Well

- **Checklist-validator parity gap (FR-017)**: The governance checklist advertised `soft-warning.review-file-reference-format` (local review requests must include `file:///` URI), but T007 initial implementation did not emit that warning. T008 integration tests did not cover this specific scenario. This gap remained hidden until formal review.
- **Incomplete loop closure on checklist updates**: When checklist was updated to include the FR-017 review-file rule, the validator implementation was not synchronized. No pre-review validation that "every checklist warning has a corresponding test case and validator emission."
- **Test coverage incomplete until repair**: T008 integration tests covered jargon-first (pass/fail) and plain-language (pass) cases, but did not cover the FR-017 review-file-reference negative case until Spec Steward repair added `handoff-governance-review-file-reference-test.ps1`.
- **Observability gap in original hardening-gate evidence**: Hardening-gate.md claimed FR-017 enforcement was addressed with "recorded" evidence, but replay showed validator was not emitting the required soft warning. Gap between documentation claim and executable reality.

## Improvement Actions

1. **Owner**: Implementer (for future governance-rule additions) | **Phase**: during implementation | **Type**: process | **Action**: Before marking a checklist warning item complete, verify it has a corresponding validator test case and that the validator actually emits the warning in live execution (not just documented). Run a spot-check replay of the checklist scenario against the live validator to ensure parity.
   - **Expected effect**: Catch checklist-validator parity breaks before review instead of during review.
   - **Metric**: Next governance-rule addition in Feature 007 or downstream features should have zero parity gaps at first review submission.

2. **Owner**: Test maintainer (for future integration tests) | **Phase**: during implementation | **Type**: implementation | **Action**: When adding a new governance rule to the validator (like FR-017 review-file-reference), add both a must-pass and a must-fail test case as part of the same task. Run both cases through the validator to verify the rule is observable in the test suite.
   - **Expected effect**: Prevent "rule implemented in checklist but not tested" gaps.
   - **Metric**: All governance validator tests in next iteration should include negative-path fixtures for every soft-warning category.

3. **Owner**: Reviewer (for future governance iterations) | **Phase**: during review | **Type**: process | **Action**: Add a pre-review checklist step for governance-heavy features: "Run the published governance checklist against live validator output to detect parity breaks before formal review." This spot-check can catch gaps like FR-017 early and reduce rework cycles.
   - **Expected effect**: Early detection of observability gaps without waiting for formal review.
   - **Metric**: No governance rule parity breaks should reach formal review in the next phase.

## Calibration Suggestion

- **Suggested capacity adjustment**: 20 story_points → **20 story_points (no change)**
- **Rationale**: Iteration 002 delivered 10 story_points with zero task variance and stable scope. Like Iteration 001, the precision reflects well-defined scope and clear implementation targets. Rework (review discovery + repair) consumed 1 sp of planned review buffer but remained within total capacity. No capacity adjustment warranted; keep current 20 sp baseline and continue front-loading clarification work to maintain stability.
- **Confidence**: High. Two consecutive iterations (001, 002) with perfect estimation accuracy and stable scope indicate the estimation model is well-calibrated for this type of Spec Kit governance work.

## Session Boundary Observations

- **Startup-loaded config handling**: T004 Squad.agent.md update required session restart between Iteration 001 and 002. This boundary was honored correctly; the session was restarted before Iteration 002 planning, and updated guidance was active during planning and implementation.
- **Pattern confirmed**: Changes to startup-loaded files (like `.github/agents/squad.agent.md`) require explicit session boundaries. This pattern should be documented at every editing point and carried in retrospective handoff notes so team doesn't infer the requirement from code.

## Feature 007 Lifecycle Status

- **Iteration 001** (Foundation & Governance, T001-T006): CLOSED. Delivered coordinator prompt, handoff template, decision guidance, Squad.agent.md updates, governance checklist, soft-validator design. Zero drift, perfect estimation.
- **Iteration 002** (Validation & Integration, T007-T010): CLOSED. Delivered soft-validator runtime, integration tests, validation lane registration, review-link polish. One drift event detected and repaired during review; accepted re-review on 2026-05-11.
- **Feature 007 closeout** (post-Iteration 002): DEFERRED. Handoff-contract durability validation via representative Squad completion sampling (recommended in Iteration 001 Improvement Action #3). To be executed before feature closeout.

## Notes

- This artifact was scaffolded from plan.md, state.md, drift-log.md, and review.md and updated with actual evidence from the completed iteration.
- The core lesson from this iteration is **observability + documentation parity**. Checklist governance items alone are not sufficient; they must have corresponding validator implementations and test coverage. The review caught FR-017 parity break and Spec Steward repair fixed all layers.
- Iteration 002 confirms the Iteration 001 pattern: detailed design documents (like T006) and clear scope boundaries enable perfect estimation accuracy. This pattern should be replicated in Phase 4 (feature closeout) and downstream Spec Kit features.
- The session-restart discipline established in Iteration 001 worked correctly and should be formalized as a known coordination trap in the next governance update.
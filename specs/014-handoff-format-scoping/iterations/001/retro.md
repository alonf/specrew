# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-05-12

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 0.25 | 0.25 | 0 |
| T002 | 0.25 | 0.25 | 0 |
| T003 | 0.75 | 0.75 | 0 |
| T004 | 0.75 | 0.75 | 0 |
| T005 | 0.5 | 0.5 | 0 |
| T006 | 1 | 1 | 0 |
| T007 | 1 | 1 | 0 |
| T008 | 0.5 | 0.5 | 0 |
| T009 | 0.5 | 0.5 | 0 |
| T010 | 0.5 | 0.5 | 0 |
| T011 | 0.5 | 0.5 | 0 |
| T012 | 0.5 | 0.5 | 0 |
| T013 | 0.25 | 0.25 | 0 |
| T014 | 0.5 | 0.5 | 0 |
| T015 | 0.25 | 0.25 | 0 |

**Total Estimated**: 8.0 story_points  
**Total Actual**: 8.0 story_points  
**Average variance**: 0% (perfect estimation)

**Calibration Note**: Zero variance across T001-T015 reflects careful scoping discipline. The plan.md clearly separated Iteration 001 selector and warning rollout from the deferred Iteration 002 proof/calibration work. No discovery surprises emerged during implementation, and all first-review verdicts were `pass` with zero rework required. This is the clean-delivery pattern: when a feature's scope is locked before execution starts and no new unknowns surface during implementation, task-level estimation becomes predictable.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1.00 sp | 1.00 sp | 0% | Clarification, feature opening, task decomposition, and hardening gate all completed on baseline effort. No discovery surprises in planning phase. |
| Discovery/Spikes | 0.00 sp | 0.00 sp | 0% | No spikes required; source draft and clarification decisions resolved all major design questions before iteration started. |
| Implementation | 8.00 sp | 8.00 sp | 0% | All 15 tasks (T001-T015) delivered at estimated effort. No late-found gaps, no selector rework, no warning-tuning iterations. Prompt, validator, and guidance surfaces stayed aligned throughout. |
| Review | 1.00 sp | 1.00 sp | 0% | Independent review re-ran five preserved handoff-governance regressions plus two Feature 012 replay-path tests plus bounded direct-validator matrix plus repo-wide governance validation. All passed on first review; no blocking gaps found. |
| Rework | 1.00 sp | 0.00 sp | -100% | Rework buffer allocated in planning was not needed. All T001-T015 passed first review with no needs-work verdicts; zero review cycles were required. |

**Total Variance**: -12.5% (1 story_point rework buffer unused). The unused rework allocation is a sign of mature estimation discipline for well-scoped, well-understood features. This pattern should inform future capacity planning for feature refinements where the scope is similarly locked and upstream planning work is complete.

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

All implementation choices remained aligned to the approved spec (spec.md). No specification drift detected during Iteration 001 execution.

## What Went Well

1. **Tight Scoping Discipline**: Plan.md clearly separated Iteration 001 selector and additive-warning rollout (FR-001 through FR-007) from the deferred Iteration 002 proof and calibration work (FR-008 and FR-009). No scope creep occurred. Implementation stayed within the locked boundary, and review verified the boundary was preserved.

2. **Clear Task Decomposition**: Each of the 15 tasks had a focused owner role, a clear acceptance criterion (either "completed this artifact" or "ran this validation"), and a single responsibility surface (e.g., T006 = validator placeholder matching only, not also the transitional-stop rule). When task boundaries were tight, estimation accuracy followed.

3. **Preserved Regression Lane**: T014 re-ran the five pre-existing handoff-governance regression scripts plus the two Feature 012 replay-path tests. All passed, confirming that the new soft-warning rules were truly additive and backward-compatible. Regression discipline prevented silent capability loss.

4. **Zero-Rework Review Cycle**: All 15 tasks passed independent review on first submission. No needs-work verdicts, no late-found gaps, no selector tuning. This reflects careful pre-review hardening by the implementation team and clear acceptance criteria in the tasks themselves.

5. **Governance Surface Alignment**: T013 (reconciliation pass) caught and resolved minor wording inconsistencies across prompt, checklist, template, and agent-guidance surfaces before review. Cross-artifact alignment prevented validator-guided or reviewer-caught mismatches.

## What Didn't Go Well

1. **Review-Boundary-Without-Commit Pattern (Critical Process Gap)**: The review.md artifact was created at commit 8e99013 (review-boundary commit), which claims the review is complete and durable at that commit. However, the retrospective phase could not start until after retro.md was created by Alon's authorization. This created a window where the iteration lifecycle state was logically incomplete but claimed durable in a committed artifact. The review claim (8e99013) was durable, but the iteration state could not be verified as stable until the retrospective boundary was opened separately. This is a subtle but critical durability trap: a boundary claim in a committed artifact creates an implicit promise that all lifecycle preconditions for that boundary have been met, but if the next phase's required artifacts (retro.md, retro data) don't exist yet, the claim is hollow. Future iterations must ensure boundary claims are only recorded after all prerequisites for the next phase are durable or explicitly scoped.

2. **Planning-Output Drift Not Surfaced Until Review**: Plan.md and tasks.md were generated and committed at 1aeee29 (planning-boundary commit). The plan contained estimated effort and task descriptions, but the tasks themselves did not include explicit acceptance criteria for verification (e.g., "manual validator exercise will show X results for scenario Y"). When T008 was executed (manual validator exercise), the team had to infer the expected outputs from the contract artifact rather than from the task definition itself. This created a minor information-scattering problem: test expectations lived in spec/contract/tasks rather than unified in one task-definition source. Future planning should embed acceptance evidence signatures (e.g., "verify these five scenarios produce these warnings") into tasks themselves, not scattered across plan and contract.

3. **Agent-Guidance Startup Coupling**: T010 and T011 updated `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md`, files that are loaded at session startup. State.md correctly notes "Session Restart Requirement: required before a future session can load the updated guidance," but this requirement only appears in the retrospective artifact, not in the task description or the state artifact before the retro phase. This is a low-signal startup-coupling trap that should have been called out at task time so the team knew in advance that a session boundary was mandatory. The pattern: any task that modifies startup-loaded config files must declare the session-boundary requirement in the task itself, not just in downstream artifacts.

## Improvement Actions

1. **Owner**: Spec Steward + Iteration Facilitator | **Phase**: next planning | **Type**: process | **Expected Effect**: Create a "boundary-claim durability checklist" that validation teams must verify before any `-boundary` commit. Checklist items: (1) Preceding phase artifacts are complete and committed, (2) Succeeding phase artifacts exist or are explicitly deferred, (3) Lifecycle gate validation passes with both phases' minimum artifacts present. This prevents the review-boundary-without-commit pattern from recurring.

2. **Owner**: Iteration Facilitator + Governance prompt stewards | **Phase**: next iteration planning | **Type**: process | **Expected Effect**: Embed acceptance evidence signatures into task definitions in plan.md and tasks.md. Instead of "Manually exercise the new warning paths," write "Manually exercise these five scenarios: correct-final-stop → pass; placeholder-only → soft-warning.empty-user-action-section; etc." This ensures test expectations are unified in the task boundary rather than scattered.

3. **Owner**: Governance prompt stewards | **Phase**: next iteration planning | **Type**: process | **Expected Effect**: For any task that modifies startup-loaded config files (`.github/agents/`, `.squad/templates/`, `.specrew/`, etc.), add a mandatory task note: "Session restart required. Future sessions cannot load this change until the next session boundary." This prevents silent session-coupling bugs where users run old guidance in new sessions or vice versa.

## Calibration Suggestion

- **Suggested capacity adjustment**: 20 → 18 story_points for future well-scoped feature refinements where Iteration 001 is similarly focused on a bounded rollout and Iteration 002 is deferred proof/graduation work. The unused 1 sp rework buffer suggests future tight-scoped iterations can reduce reserved rework allocation by 0.5-1 sp without additional risk, while keeping exploration/spike capacity at a baseline 0.5 sp for discovery surprises.
- **Rationale**: Feature 014 iteration 001 achieved 0% variance and 0% rework necessity because the scope was locked before execution (all deferred work was kept out of the task backlog) and no new unknowns emerged during implementation. Reducing the rework buffer from 1.0 to 0.5 sp (50% reduction) remains conservative but more honest about the actual contingency needed for features with tight upstream planning. For comparison, Feature 007 iteration 001 also achieved 0% variance with similar planning rigor, supporting this pattern as durable rather than anomalous.

## Candidate Corpus Rows for Known Traps

### Candidate 1: `boundary-claim-without-commit`

**Pattern**: A committed boundary artifact (e.g., review.md) claims a lifecycle phase is complete and durable at a specific commit, but the next phase's required artifacts (e.g., retro.md) do not exist yet, and cannot be created until separate human authorization.

**Risk**: Iteration state becomes logically incomplete while appearing durably recorded. Downstream automation (validator, planner) may treat the boundary claim as truth when prerequisites are not yet met.

**Evidence**: Feature 014 iteration 001 at commit 8e99013 (review-boundary claim) had no retro.md until authorization and retro.md creation occurred in a later session. The review was truthfully accepted, but the iteration state could not transition to the next phase until retro artifacts were explicitly scaffolded.

**Detection Rule** (candidate for future implementation): Before accepting a `-boundary` commit:

1. Verify all artifacts for the current phase are complete and committed.
2. Verify that either (a) all required artifacts for the next phase exist and are committed, or (b) the next phase is explicitly deferred in state.md/plan.md with a human approval note.
3. If (a) and (b) both fail, reject the boundary claim and require either retro.md (if retro is authorized) or an explicit defer note (if retro is not yet authorized).

**Known-Traps Wording**: "Lifecycle boundary claims (review, retro, closeout) must not be recorded in a committed artifact unless all prerequisites for that boundary are durably met or explicitly deferred. A review-boundary claim without a retro-ready state creates a durability gap where the boundary appears stable in git history but is logically incomplete. Always pair boundary claims with explicit authorization artifacts or defer notes."

### Candidate 2: `startup-coupling-task-invisibility`

**Pattern**: A task modifies startup-loaded config files (`.github/agents/`, `.squad/templates/`, `.specrew/config.yml`), but the mandatory session-restart requirement is not documented in the task itself, only in downstream artifacts (state.md, retro.md).

**Risk**: Implementation team completes the task and artifacts are committed. Later, a reviewer or planner runs in the old session without knowing a restart is required, leading to confusion about whether the changes are active.

**Evidence**: Feature 014 iteration 001, tasks T010 and T011, modified `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md`. State.md notes "Session Restart Requirement: required before a future session can load the updated guidance," but this was discovered during retro, not documented in the task description.

**Detection Rule** (candidate): Scan task.md for tasks that edit files under `.github/agents/`, `.squad/templates/`, or `.specrew/` with startup-side-effects. Flag any task without a "Session restart required" note in the acceptance criteria.

**Known-Traps Wording**: "Tasks modifying startup-loaded config files must explicitly document the session-restart requirement in the task acceptance criteria, not just in downstream state or retro artifacts. Pattern: '[Task name] | Acceptance: Update X and commit. **Session restart required for next session.** New sessions cannot load this change until restarted.' This makes the coupling visible at task time, not discovered later."

### Candidate 3: `acceptance-evidence-scattering`

**Pattern**: Task acceptance criteria are defined in the task.md description, but expected test outputs, scenarios, and evidence formats are scattered across spec.md, contract.md, and state.md.

**Risk**: When a validator or tester executes the task, they must infer expected outcomes from multiple artifacts rather than reading a single authoritative task definition.

**Evidence**: Feature 014 iteration 001, task T008 (manual validator exercise) required the team to cross-reference spec.md (User Story 2 scenarios), contract.md (approved scenarios), and plan.md (task description) to understand what outputs should be observed. The expected evidence should have been unified in T008's definition.

**Detection Rule** (candidate): For any task with acceptance criteria "verify X" or "manually exercise Y," scan the task.md entry for explicit expected outcomes. If expected outcomes are missing, flag the task as underspecified.

**Known-Traps Wording**: "Task acceptance criteria must include expected evidence signatures in the task definition itself. Instead of 'T008 | Manually exercise the new warning paths,' write 'T008 | Manually exercise: (1) correct-final-stop → pass; (2) placeholder-only → soft-warning.empty-user-action-section; (3) [etc]. Update contract.md with observed results.' This unifies acceptance criteria in the task boundary rather than scattering it."

## Lessons for Future Iterations

1. **Pattern: Zero-Variance Delivery Model**: When upstream planning work is complete (scope locked, design decisions finalized, and upstream gates signed), and no discovery surprises surface during implementation, task-level estimation becomes highly predictable. Feature 014 iteration 001 achieved 0% variance with clear scoping discipline. This should inform future capacity planning: tight-scoped feature refinements can assume lower variance than exploratory features.

2. **Pattern: Governance Surface Alignment as a Distinct Phase**: User Story 3 (alignment phase, T009-T013) was deliberately split from implementation phases. This allowed prompt, checklist, template, and corpus surfaces to be verified as coherent before review. Future features should schedule a dedicated "surface reconciliation" phase between implementation and review to catch cross-artifact misalignment.

3. **Pattern: Preserved Regression Lane as a Confidence Signal**: T014 re-ran pre-existing tests. All passed. This was more than a gate; it was a confidence amplifier that the new rules were truly additive. Future features should make pre-existing regression runs a mandatory validation stage, not optional.

4. **Session Coupling as a Lifecycle Concern**: Startup-loaded config changes (T010, T011) created an implicit session boundary. Future governance work should track session-coupling tasks explicitly and require team coordination notes in state.md or decisions.md so the human running the next iteration knows when a restart is required.

## Notes

- This artifact was scaffolded from plan.md, state.md, drift-log.md, and review.md for the retrospective boundary.
- All TBD placeholders have been replaced with evidence from the completed iteration.
- The candidate corpus rows above represent process traps discovered during Iteration 001 execution; their inclusion in `.specrew/quality/known-traps.md` is deferred to Iteration 002 as part of the planned graduation work (FR-008).
- Review boundary commit: 8e99013. Implementation commit: f02688f. All task verdicts recorded in plan.md as pass.

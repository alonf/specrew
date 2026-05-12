# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 8.0/20 story_points
**Started**: 2026-05-12
**Completed**: (none)
**Hardening-Gate Sign-Off**: 2026-05-12 by Alon Fliess
**Implementation Authorization**: 2026-05-12

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | The system MUST define two governed response types for the coordinator's top-level human-facing output: **final stop message** and **in-flight progress update**. A final stop message applies only when the human is the bottleneck for the next lifecycle step and MUST use the existing three-section format with substantive content in all three sections. An in-flight progress update applies when Squad is still actively working, waiting on a background process, or transitioning between work stages and MUST omit the user-action section in favor of a concise single-line progress note. Session-opening acknowledgements are not exempt and MUST follow the same distinction. **Owner role**: Governance prompt stewards. **Delivery window**: Iteration 1. | — |
| FR-002 | The system MUST update the coordinator governance guidance with explicit decision criteria for choosing between the two response types, including at least one worked example for each type and an explanation of why the chosen format is correct. **Owner role**: Governance prompt stewards. **Delivery window**: Iteration 1. | — |
| FR-003 | The system MUST update the governed handoff template so it captures both response types, includes explicit examples of correct usage, preserves the existing three-section format unchanged for genuine stop points, and keeps in-flight progress updates as deliberately unstructured single-line prose rather than introducing an `Action \| Status \| Next` template. **Owner role**: Handoff-template stewards. **Delivery window**: Iteration 1. | — |
| FR-004 | The system MUST emit `soft-warning.empty-user-action-section` when a governed coordinator top-level response uses the three-section format but the "What I need from you" section is empty, contains a placeholder such as "Nothing yet" or "No action needed," or otherwise communicates no substantive human action. Placeholder matching MUST come from a fixed repository-maintained phrase list defined in code and tests for this feature, not a human-extensible configuration surface. **Owner role**: Validator maintainers. **Delivery window**: Iteration 1. | — |
| FR-005 | The system MUST emit `soft-warning.transitional-stop-claim` when a governed coordinator top-level response uses "Why I stopped" to describe in-flight work, waiting, or transition-state narration rather than a true human-blocked stop, especially when no substantive human action is identified. **Owner role**: Validator maintainers. **Delivery window**: Iteration 1. | — |
| FR-006 | The system MUST keep both new warning rules low-noise, advisory, and additive: warnings are evaluated per response, MUST NOT fire on legitimate substantive stop messages, MUST NOT introduce a positive `soft-info.well-scoped-handoff` emission in this feature, and MUST preserve the existing soft-warning workflow rather than blocking the response. **Owner role**: Validator maintainers. **Delivery window**: Iteration 1. | — |
| FR-007 | The system MUST update the `human-handoff-id-context` corpus row so its scope-of-applicability explicitly covers both final stop messages and in-flight progress updates, removing ambiguity about whether transitional narration is in scope. **Owner role**: Governance corpus stewards. **Delivery window**: Iteration 1. | — |
| FR-008 | The system MUST record the pattern "three-section stop-message format misapplied to in-flight transitions" in the known-traps catalog as a validator-enforced governance trap with citations to the governing rules and proving tests. **Owner role**: Governance corpus stewards. **Delivery window**: Iteration 2. | Deferred to Iteration 002 |
| FR-009 | The system MUST provide deterministic integration coverage for both new warning rules using violating and compliant fixtures, including at least one violating fixture and one compliant fixture per rule, and MUST calibrate the rules against a historical-response sample so false positives stay acceptably low. The coverage surface for this feature is the coordinator's top-level response, and the opposite symmetric misuse rule remains deferred to a follow-on. **Owner role**: Test maintainers and validator maintainers. **Delivery window**: Iteration 2. | Deferred to Iteration 002 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Confirm the approved Iteration 001 boundary and two-iteration split | FR-001, FR-006, FR-007 | Boundary | 0.25 | Spec steward | `specs/014-handoff-format-scoping/plan.md`, `specs/014-handoff-format-scoping/tasks.md` | planned | Spec Steward | — | pending |
| T002 | Confirm the deferred proof-work boundary and preserved regression lane | FR-006, FR-007 | Boundary | 0.25 | Iteration facilitator | `specs/014-handoff-format-scoping/quickstart.md` | planned | Planner | — | pending |
| T003 | Update response-type selector criteria and first-acknowledgement guidance | FR-001, FR-002 | US1 | 0.75 | Governance prompt stewards | `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md` | planned | Planner | — | pending |
| T004 | Update coordinator response instructions and worked examples | FR-001, FR-002 | US1 | 0.75 | Governance prompt stewards | `extensions/specrew-speckit/prompts/coordinator-response.md` | planned | Planner | — | pending |
| T005 | Update dual response-type examples while preserving the stop format | FR-003 | US1 | 0.50 | Handoff-template stewards | `specs/001-specrew-product/contracts/coordinator-handoff-template.md` | planned | Planner | — | pending |
| T006 | Add fixed placeholder-phrase matching and empty-user-action warning logic | FR-004 | US2 | 1.00 | Validator maintainers | `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | planned | Implementer | — | pending |
| T007 | Add transitional-stop-claim warning logic and preserve additive soft-warning behavior | FR-005, FR-006 | US2 | 1.00 | Validator maintainers | `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | planned | Implementer | — | pending |
| T008 | Manually exercise the new warning paths against the approved scenarios | FR-004, FR-005, FR-006 | US2 | 0.50 | Validator maintainers | `specs/014-handoff-format-scoping/contracts/coordinator-handoff-scoping.md`, `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | planned | Reviewer | — | pending |
| T009 | Update selector and mixed-case review criteria | FR-002 | US3 | 0.50 | Governance prompt stewards | `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md` | planned | Planner | — | pending |
| T010 | Update coordinator runtime guidance for stop-vs-progress scoping | FR-002 | US3 | 0.50 | Agent-guidance stewards | `.github/agents/squad.agent.md` | planned | Planner | — | pending |
| T011 | Update generated Squad template guidance for stop-vs-progress scoping | FR-002 | US3 | 0.50 | Agent-guidance stewards | `.squad/templates/squad.agent.md` | planned | Planner | — | pending |
| T012 | Extend the `human-handoff-id-context` row to cover both governed response types | FR-007 | US3 | 0.50 | Governance corpus stewards | `.specrew/quality/known-traps.md` | planned | Planner | — | pending |
| T013 | Reconcile cross-artifact wording against the approved selector contract | FR-002, FR-003, FR-007 | US3 | 0.25 | Iteration facilitator | `specs/014-handoff-format-scoping/contracts/coordinator-handoff-scoping.md`, `extensions/specrew-speckit/prompts/`, `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md` | planned | Planner | — | pending |
| T014 | Run preserved handoff-governance regression scripts for additive-warning compatibility | FR-006 | Validation | 0.50 | Test maintainers | `tests/integration/handoff-governance-*.ps1` | planned | Reviewer | — | pending |
| T015 | Run repository governance validation for bounded Iteration 001 compliance | FR-006 | Validation | 0.25 | Validator maintainers | `extensions/specrew-speckit/scripts/validate-governance.ps1` | planned | Reviewer | — | pending |

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

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Technology and scope signals: Mixed frontend and backend/service signals are present in the scoped requirements.
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: Current scope does not yet prove enough safe parallelism for same-specialty expansion; default to a smaller serial team until tasks are clearer.
- Shared-surface conflict risk: no elevated shared-surface warning inferred yet.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1.00 story_points | Feature opening, clarify, plan, tasks, and iteration scaffold repairs |
| Discovery/Spikes | 0.00 story_points | No spikes planned; source draft and clarify resolved the open design decisions |
| Implementation | 8.00 story_points | Sum of T001-T015 in the bounded Iteration 001 backlog |
| Review | 1.00 story_points | Reviewer pass across the coordinator, validator, and guidance surfaces after implementation |
| Rework | 1.00 story_points | Small bounded buffer if review finds wording or warning-noise issues |

## Traceability Summary

- Requirement scope for this iteration: FR-001 through FR-007
- User stories represented in current scope: US1, US2, and US3
- Deferred to Iteration 002: FR-008 and FR-009 (fixture proof, calibration, and misapplied-stop trap graduation)
- Overcommit guardrail: the bounded Iteration 001 task set totals 8.0 story_points, which remains under the 20 story_point capacity ceiling.

## Notes

- This plan is intentionally limited to the Iteration 001 rollout slice; Iteration 002 proof and graduation work stays deferred and is not scaffolded here.
- `Status` moved to `executing` once the pre-implementation hardening gate was signed off and implementation authorization was recorded on 2026-05-12.
- The current validator treats committed `review.md` and `retro.md` files as evidence that later lifecycle phases have already started, so those two artifacts must be scaffolded when the review and retrospective boundaries are actually opened rather than as planning-time placeholders.
- If the iteration scope changes later, update the task table, phase baseline, and deferral note in the same planning boundary.

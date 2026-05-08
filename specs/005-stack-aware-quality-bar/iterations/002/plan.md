# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: reviewing
**Capacity**: 18/20 story_points
**Started**: 2026-05-07
**Completed**:

## Summary

Iteration 002 completed the remaining shared Phase 1 evidence-foundation tasks (`T012`-`T017`) plus the final Phase 1 documentation reconciliation task (`T018`) after Iteration 001 established the quality asset registry and planning-time quality-profile infrastructure. All tasks in this iteration are now complete: mechanical findings, lifecycle evidence publication, fail-closed governance enforcement, and final Phase 1 operator guidance have been delivered and are under review.

This plan is now truthful about current lifecycle state: Iteration 001 is in `retro` with its reviewer closeout packet in place. Iteration 002 execution is complete with all Phase 1 shared evidence foundation work delivered. The quality-evidence contract, mechanical-findings publication, fail-closed governance enforcement, and quickstart reconciliation are now recorded as completed work. Final human sign-off and feature closure remain pending.

**Primary Focus**: mechanical findings, lifecycle evidence publication, fail-closed governance, and final Phase 1 operator guidance  
**Target Slices**: Slice C1-C3, Slice D1-D3, and Polish task `T018`  
**Execution Status**: All planned tasks complete (`T012`-`T018`)  
**Handoff**: Iteration 001 is in `retro`; Iteration 002 execution is complete with evidence ready for governance review  
**Out of Scope for This Iteration**: later-phase hardening gate, dedicated bug-hunter execution workflows, known-traps corpus, mixed-stack override expansion, quality-drift automation, and reference-implementation comparison

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-027, FR-028, FR-029 | Deterministic dead-field, anti-pattern, and test-integrity mechanical checks | ✅ `T012`, `T014` | Reviewer + Implementer | Establishes the Phase 1 mechanical rule/test foundation without starting later-phase lens execution |
| FR-030 | Structured machine-readable findings with remediation metadata | ✅ `T012`, `T014`, `T015` | Reviewer + Implementer | Publishes schema-compliant `mechanical-findings.json` into iteration artifacts |
| FR-030a | Reviewed demotion workflow for noisy mechanical rules | ✅ `T012`, `T014`, `T016` | Reviewer + Implementer | Keeps demoted rules visible via explicit `dispositionRef` and governance checks; no approval is presumed in advance |
| FR-011, FR-012 | Reviewable quality toolchain/evidence visibility and fail-closed evidence requirements | ✅ `T013`, `T015`, `T016`, `T017`, `T018` | Reviewer + Spec Steward | Covers `quality-evidence.md`, required gate enforcement, aligned reporting regressions, and final operator guidance |

---

## Execution Slice Acceptance Criteria

1. `tests\integration\mechanical-findings-contract.ps1` covers schema-compliant findings output and demotion visibility for the Phase 1 mechanical rule set.
2. `tests\integration\quality-evidence-governance.ps1` proves required quality gates appear in lifecycle evidence and that missing or unjustified evidence fails closed.
3. `extensions\specrew-speckit\scripts\run-mechanical-checks.ps1` emits deterministic dead-field, anti-pattern, and test-integrity findings that conform to `contracts\mechanical-findings.schema.json`, including `dispositionRef` when a rule is demoted.
4. Iteration artifact scaffolding publishes `quality-evidence.md` and `mechanical-findings.json` under `specs\<feature>\iterations\<NNN>\quality\` without bypassing the existing Specrew artifact flow.
5. `validate-governance.ps1` enforces required Phase 1 evidence, approved exceptions, and demotion visibility before work can be presented as meeting the planned quality bar.
6. `quickstart.md` and `extensions\specrew-speckit\README.md` are updated only after the evidence/scaffold/governance flow is implemented, so Phase 1 operator guidance matches reality.

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | Scope is limited to the remaining Phase 1 tasks already defined in `tasks.md`: `T012` through `T018`. Iteration 001's completed Slice A/B work is not reopened here. All tasks now complete with execution evidence present. |
| **Traceability** | ✅ PASS | Every planned task row maps to the in-scope FRs for evidence publication, structured findings, and documentation reconciliation. FR-030a is recorded explicitly. Required Quality Gates section added with Phase 1 contract gate declarations. |
| **Ownership** | ✅ PASS | Owners match the feature task table: Reviewer (`T012`, `T013`, `T015`, `T016`, `T017`), Implementer (`T014`), Spec Steward (`T018`). All completed. |
| **Capacity** | ✅ PASS | Planned effort is 18/20 story_points, keeping the remaining Phase 1 slice inside configured capacity. All effort allocated and delivered. |
| **Phase 1 Gate Metadata** | ✅ PASS | Phase Scope section added with clear iteration purpose. Required Quality Gates table added with all 5 Phase 1 gates: dead-field, anti-pattern, test-integrity, stack-tooling-evidence, quality-lens-review. Plan now declares the gates enforced by `validate-governance.ps1` and evidence published by the iteration. |
| **Execution Support** | ✅ PASS | `plan.md`, `state.md`, and `quality-evidence.md` now exist for Iteration 002 with complete execution record. All tasks marked `done`. Phase 1 governance metadata in place for fail-closed enforcement validation. |

---

## Phase Scope

This iteration advances Phase 1 implementation by completing the remaining shared evidence foundation and documentation tasks after Iteration 001 established the planning-time quality profile and preset/lens-checklist infrastructure. All tasks in this iteration are execution-phase work: deterministic mechanical checks (`T014`), structured findings and evidence publication (`T015`), fail-closed governance enforcement (`T016`), existing reporting alignment (`T017`), and operator documentation reconciliation (`T018`). Tests are part of the execution phase (`T012`-`T013`) and must pass before the slice is considered complete.

## Required Quality Gates

The Phase 1 quality gates declared for Iteration 002 align to the contract requirements in `contracts/quality-governance-artifacts.md` and the live `quality\quality-evidence.md` fixture:

| Gate | Requirement | Evidence Source | Rationale |
| --- | --- | --- | --- |
| `dead-field` | FR-011, FR-027, FR-030 | `specs/005-stack-aware-quality-bar/iterations/002/quality/mechanical-findings.json` | Mechanical check for declared but unused fields/parameters in Phase 1 implementation scope |
| `anti-pattern` | FR-011, FR-028, FR-030 | `specs/005-stack-aware-quality-bar/iterations/002/quality/mechanical-findings.json` | Mechanical check for known antipatterns in Phase 1 PowerShell/governance implementation |
| `test-integrity` | FR-011, FR-029, FR-030 | `specs/005-stack-aware-quality-bar/iterations/002/quality/mechanical-findings.json` | Mechanical check for test-quality regressions in the evidence-governance and mechanical-findings test suites |
| `stack-tooling-evidence` | FR-011 | `specs/005-stack-aware-quality-bar/iterations/002/quality/quality-evidence.md` | Phase 1 evidence publication of the inferred quality toolchain for PowerShell governance |
| `quality-lens-review` | FR-011, FR-012 | `specs/005-stack-aware-quality-bar/iterations/002/quality/quality-evidence.md` | Reviewer validation that Phase 1 quality gates are declared and enforced by the live iteration artifacts |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T012 | Add findings-schema and demotion regression coverage in `tests\integration\mechanical-findings-contract.ps1` | FR-027, FR-028, FR-029, FR-030, FR-030a | US-3 | 2 | Reviewer | `tests\integration\mechanical-findings-contract.ps1`, `tests\integration\fixtures\mechanical-findings-contract\**` | done |  |  |  |
| T013 | Add lifecycle evidence and missing-evidence regression coverage in `tests\integration\quality-evidence-governance.ps1` | FR-011, FR-012 | US-2 | 2 | Reviewer | `tests\integration\quality-evidence-governance.ps1`, `tests\integration\fixtures\quality-evidence-governance\**` | done |  |  |  |
| T014 | Implement deterministic dead-field, anti-pattern, and test-integrity rule execution with schema-compliant findings and `dispositionRef` support | FR-027, FR-028, FR-029, FR-030, FR-030a | US-3 | 5 | Implementer | `extensions\specrew-speckit\scripts\run-mechanical-checks.ps1` | done |  |  |  |
| T015 | Scaffold and publish `quality-evidence.md` and `mechanical-findings.json` in iteration/reviewer artifact flows | FR-011, FR-012, FR-030 | US-2 | 3 | Reviewer | `extensions\specrew-speckit\scripts\scaffold-iteration-artifacts.ps1`, `extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1`, `extensions\specrew-speckit\scripts\run-mechanical-checks.ps1` | done |  |  |  |
| T016 | Enforce required Phase 1 gate evidence, approved exceptions, and demotion visibility in `validate-governance.ps1` | FR-012, FR-030a | US-2, US-3 | 3 | Reviewer | `extensions\specrew-speckit\scripts\validate-governance.ps1` | done |  |  |  |
| T017 | Keep existing reporting regressions aligned with the Phase 1 evidence artifacts | FR-011 | US-2 | 2 | Reviewer | `tests\integration\process-quality-scorer.ps1`, `tests\integration\process-quality-report.ps1` | done |  |  |  |
| T018 | Update `quickstart.md` and `extensions\specrew-speckit\README.md` so the Phase 1 validation flow matches implemented commands | FR-011, FR-012 | US-2 | 1 | Spec Steward | `specs\005-stack-aware-quality-bar\quickstart.md`, `extensions\specrew-speckit\README.md` | done |  |  |  |

**Total Effort**: 18 story_points

---

## Planned Execution Order

1. Start with `T012` and `T013`; they are the failing-first regression tasks for the remaining slice and can proceed in parallel if explicit reviewer ownership is split by the non-overlapping file globs above.
2. `T014` depends on the mechanical findings expectations established by `T012`.
3. `T015` depends on the evidence contract from `T013` and the findings output shape from `T014`.
4. `T016` depends on `T015` because governance must validate the finalized evidence locations and demotion visibility rules.
5. `T017` follows once the evidence artifact paths are stable so the existing reporting regressions align to the new Phase 1 outputs.
6. `T018` closes the slice after the scaffold/findings/governance flow is real, so documentation reflects implemented behavior rather than forecasted behavior.

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | The Planner must make any future deferral decision explicit. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments when actual variance accumulates. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Technology and scope signals: this slice is dominated by PowerShell governance scripts, iteration artifact publishing, and deterministic integration tests rather than new planning-surface work.
- Task dependency graph: the remaining slice is test-first (`T012`/`T013`) → mechanical/evidence implementation (`T014`/`T015`) → governance/report alignment (`T016`/`T017`) → documentation reconciliation (`T018`).
- Workstream separability: `T012` and `T013` are the only clean parallel pair because their file surfaces do not overlap; the rest of the slice touches shared scripts and should stay serial.
- Shared-surface conflict risk: elevated after `T013` because `run-mechanical-checks.ps1`, scaffold scripts, and `validate-governance.ps1` all converge on the same quality artifact contract.
- Recommendation: keep the slice serial after the initial test pair. No same-specialty expansion is proposed beyond the bounded `T012`/`T013` opportunity already protected by explicit file globs.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 2 | Iteration slicing, traceability, approval packaging, and boundary-precondition review for the remaining Phase 1 work |
| Discovery/Spikes | 0 | No new spike is authorized in this planning pass |
| Implementation | 13 | `T012`-`T016` deliver the evidence foundation and governance enforcement |
| Review | 2 | `T017` regression alignment plus reviewer verification of fail-closed behavior |
| Rework | 1 | Small buffer for contract-alignment fixes discovered while landing the slice |

## Implementation Approval

- **Approval Verdict**: approved
- **Approved By**: Alon Fliess
- **Recorded Evidence**: current session explicit coordinator confirmation that human approval was given for Iteration 002 execution
- **Recorded At**: 2026-05-07T22:18:58Z
- **Scope Approved for Execution**: Iteration 002 active slice (`T012`-`T018`) only
- **Gate Effect**: the execution approval gate is now cleared for Iteration 002; `T012` and `T013` are the next ready tasks, while Iteration 001's pending retro actuals/final sign-off remain separate closure work and do not change this slice's scope.

## Notes

- Iteration 002 execution is now complete with all Phase 1 shared evidence-foundation and documentation work delivered. This repair pass updates the planning artifacts to truthfully reflect that T012-T018 are complete, adds the Phase Scope and Required Quality Gates sections required by the governance contract, and reconciles the plan with the live state.md and quality-evidence.md artifacts.
- `iterations\002\state.md` is authoritative for current execution status: all tasks `T012`-`T018` are recorded as complete, no tasks remaining.
- This plan now declares all Phase 1 quality gates required by the `contracts/quality-governance-artifacts.md` evidence contract. The `quality-evidence.md` and `mechanical-findings.json` artifacts are published under the `iterations/002/quality/` directory and available for governance validation.
- This plan is approved for governance validation; no additional scope beyond the iteration's completed `T012`-`T018` work is authorized.
- Final human sign-off for Iteration 002 and feature completion remain pending after governance validation passes.

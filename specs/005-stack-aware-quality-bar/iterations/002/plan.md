# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 18/20 story_points
**Started**: 2026-05-07
**Completed**:

## Summary

Iteration 002 is the next planned execution slice for feature `005-stack-aware-quality-bar` after Iteration 001 recorded the Phase 1 foundation and US-1 planning-profile work through `T011` in its handoff artifacts. This iteration is intentionally limited to the remaining shared evidence-foundation tasks (`T012`-`T017`) plus the final Phase 1 documentation reconciliation task (`T018`).

This plan is intentionally truthful about current lifecycle state: Iteration 001 is now in `retro`, its reviewer closeout packet exists, and the quality-asset registry plus planning-time profile publication slice through `T011` is recorded as delivered work. Final retro actuals and final human sign-off for Iteration 001 are still pending, while the evidence publication, mechanical findings, governance enforcement, and final operator guidance remain the unstarted work for this next slice. Iteration 002 exists only to prepare that remaining work for review and explicit approval; no implementation task in this slice has started.

**Primary Focus**: mechanical findings, lifecycle evidence publication, fail-closed governance, and final Phase 1 operator guidance  
**Target Slices**: Slice C1-C3, Slice D1-D3, and Polish task `T018`  
**Prior Handoff**: Iteration 001 is in `retro`; `state.md` records `T011` as last completed, `T012`-`T018` as remaining, and the reviewer closeout packet is present  
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
| **Spec Authority** | ✅ PASS | Scope is limited to the remaining Phase 1 tasks already defined in `tasks.md`: `T012` through `T018`. Iteration 001's completed Slice A/B work is not reopened here. |
| **Traceability** | ✅ PASS | Every planned task row maps to the in-scope FRs for evidence publication, structured findings, and documentation reconciliation. FR-030a is recorded explicitly even though the scaffold helper only seeded numeric FR scope. |
| **Ownership** | ✅ PASS | Owners match the feature task table: Reviewer (`T012`, `T013`, `T015`, `T016`, `T017`), Implementer (`T014`), Spec Steward (`T018`). |
| **Capacity** | ✅ PASS | Planned effort is 18/20 story_points, keeping the remaining Phase 1 slice inside configured capacity without hidden deferrals. |
| **Execution Support** | ✅ PASS | `plan.md`, `state.md`, and `drift-log.md` now exist for Iteration 002. Iteration 001 is already in `retro` with its closeout packet present, but Iteration 002 still remains `planning` until fresh explicit human approval is recorded. |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T012 | Add findings-schema and demotion regression coverage in `tests\integration\mechanical-findings-contract.ps1` | FR-027, FR-028, FR-029, FR-030, FR-030a | US-3 | 2 | Reviewer | `tests\integration\mechanical-findings-contract.ps1`, `tests\integration\fixtures\mechanical-findings-contract\**` | planned |  |  |  |
| T013 | Add lifecycle evidence and missing-evidence regression coverage in `tests\integration\quality-evidence-governance.ps1` | FR-011, FR-012 | US-2 | 2 | Reviewer | `tests\integration\quality-evidence-governance.ps1`, `tests\integration\fixtures\quality-evidence-governance\**` | planned |  |  |  |
| T014 | Implement deterministic dead-field, anti-pattern, and test-integrity rule execution with schema-compliant findings and `dispositionRef` support | FR-027, FR-028, FR-029, FR-030, FR-030a | US-3 | 5 | Implementer | `extensions\specrew-speckit\scripts\run-mechanical-checks.ps1` | planned |  |  |  |
| T015 | Scaffold and publish `quality-evidence.md` and `mechanical-findings.json` in iteration/reviewer artifact flows | FR-011, FR-012, FR-030 | US-2 | 3 | Reviewer | `extensions\specrew-speckit\scripts\scaffold-iteration-artifacts.ps1`, `extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1`, `extensions\specrew-speckit\scripts\run-mechanical-checks.ps1` | planned |  |  |  |
| T016 | Enforce required Phase 1 gate evidence, approved exceptions, and demotion visibility in `validate-governance.ps1` | FR-012, FR-030a | US-2, US-3 | 3 | Reviewer | `extensions\specrew-speckit\scripts\validate-governance.ps1` | planned |  |  |  |
| T017 | Keep existing reporting regressions aligned with the Phase 1 evidence artifacts | FR-011 | US-2 | 2 | Reviewer | `tests\integration\process-quality-scorer.ps1`, `tests\integration\process-quality-report.ps1` | planned |  |  |  |
| T018 | Update `quickstart.md` and `extensions\specrew-speckit\README.md` so the Phase 1 validation flow matches implemented commands | FR-011, FR-012 | US-2 | 1 | Spec Steward | `specs\005-stack-aware-quality-bar\quickstart.md`, `extensions\specrew-speckit\README.md` | planned |  |  |  |

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

- **Approval Verdict**: pending-human-approval
- **Approved By**: (none)
- **Recorded Evidence**: none
- **Scope Pending Approval**: Iteration 002 active slice (`T012`-`T018`) only
- **Gate Effect**: execution of `T012` and later remains blocked until a fresh explicit human approval is recorded for this plan; Iteration 001 approval does not carry forward automatically, and its pending retro actuals/final sign-off do not imply approval for Iteration 002

## Notes

- This pass creates the next iteration artifacts only; it does not start implementation.
- `iterations\001\state.md` is the authoritative handoff for current feature progress: `T011` is last complete and `T012`-`T018` remain pending, while Iteration 001 itself is already in `retro`.
- Iteration 001's reviewer closeout packet exists, but final retro actuals and final human sign-off for that prior iteration are still pending.
- This plan is review-ready pending fresh human approval for Iteration 002; no approval is implied by the Iteration 001 handoff or retro status.

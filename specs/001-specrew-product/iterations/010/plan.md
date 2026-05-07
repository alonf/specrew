# Iteration Plan: 010

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 7/20 story_points
**Started**: 2026-05-07
**Completed**:

## Summary

Iteration 010 implements FR-042 by turning Specrew's existing validation surfaces into an explicit three-lane strategy. The primary PR gate remains deterministic and artifact-based, a new contract lane validates start/review artifacts and persisted lifecycle traces without live agents, and a scheduled confidence lane now wraps the Copilot/Squad smoke harness with persisted JSON traces for replay.

The slice intentionally reuses the existing start-command, review replay, governance validation, and smoke harness behaviors. The work is mostly orchestration and trace persistence: define the lanes clearly, wire them into workflows, and persist the traces needed to turn confidence-lane failures into deterministic fixtures later.

---

## Scope

### In Scope

- Formalize the deterministic PR gate in CI as the primary validation lane
- Add a contract lane script/job for prompts, handoff context, review replay, routing policy, and lifecycle trace checks
- Add a confidence-lane wrapper that persists structured smoke traces and a scheduled workflow that uploads them
- Update validation documentation and roadmap numbering to reflect the corrective Iteration 009 shift

### Out of Scope

- New outcome scorers or a full end-to-end evaluation harness
- Live-agent assertions beyond the existing smoke harness contract and trace persistence
- Downstream repo hygiene contract (`FR-055`)

---

## Requirements Traceability

| Spec Ref | Requirement | Planned Deliverables | Owner |
|----------|-------------|----------------------|-------|
| FR-042 | Deterministic primary gate | CI job rename/structure that keeps artifact/governance/integration checks as the main PR gate | Planner + Implementer |
| FR-042 | Contract lane | `validation-contract-lane.ps1`, `lifecycle-trace-contract.ps1`, and CI contract-lane job | Implementer |
| FR-042 | Confidence lane | `copilot-squad-confidence-lane.ps1` plus scheduled/workflow-dispatch workflow with uploaded traces | Implementer |
| FR-042 | Replayable structured traces | JSON smoke traces that capture replay inputs, policy evidence, and output for later deterministic fixture conversion | Reviewer + Implementer |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-1001 | Formalize deterministic PR checks as the primary validation lane | FR-042 | US-6 | 1 | Planner | done | copilot-agent | 1 | pass |
| T-1002 | Add contract lane scripts and CI job for prompt/review/trace contracts | FR-042 | US-6 | 2 | Implementer | done | copilot-agent | 2 | pass |
| T-1003 | Add confidence-lane wrapper and scheduled workflow with persisted smoke traces | FR-042 | US-6 | 2 | Implementer | done | copilot-agent | 2 | pass |
| T-1004 | Update validation docs and roadmap numbering for the new lane strategy | FR-042 | US-6 | 2 | Reviewer | done | copilot-agent | 2 | pass |

**Planned Total**: 7 story_points

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Keep the slice fixed to validation-lane orchestration and trace persistence. |
| Time Limit (hours) | n/a | Not used for this scope-bounded iteration. |
| Overcommit Threshold | 1.0 | No overcommit expected at planned capacity 7/20. |
| Defer Strategy | manual | If further live-smoke depth is needed later, defer it explicitly rather than widening this lane-definition slice. |
| Calibration Enabled | true | Retro should confirm whether validation-lane work stays small and infrastructure-focused. |

---

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Map FR-042 to existing CI, replay, and smoke-harness surfaces |
| Implementation | 3 | Lane scripts, workflow updates, and trace persistence |
| Review | 2 | Contract-lane tests, governance validation, and reviewer closeout |
| Rework | 1 | Buffer for workflow or scratch-fixture mismatches |

---

## Acceptance Checkpoints

1. CI clearly separates the deterministic gate from the contract lane while keeping deterministic checks as the primary PR gate.
2. A contract-lane script validates prompt/handoff/review replay behavior plus persisted lifecycle traces without requiring live agents.
3. A confidence-lane wrapper persists structured JSON traces, and a scheduled/workflow-dispatch workflow uploads those traces as artifacts.
4. Validation docs and roadmap numbering reflect the new three-lane strategy and the corrective Iteration 009 shift.

## Notes

- Iteration 010 is the postponed FR-042 slice after the separate Iteration 009 corrective closeout-enforcement work.
- The confidence lane is intentionally non-blocking for PRs; it exists for scheduled or operator-triggered confidence checks, not for mandatory every-PR execution.

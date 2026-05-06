# Iteration Plan: 008

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 7/20 story_points
**Started**: 2026-05-06
**Completed**:

## Summary

Iteration 008 closes the concurrency-sizing slice around FR-038 through FR-041 by moving same-specialty planning rules into real governance surfaces. The iteration makes concurrency rationale visible in scaffolded iteration plans, teaches the validator to reject unsafe Junior/Senior same-specialty planning, and updates the normative plan contract so the dogfood artifacts match the new ownership-boundary schema.

This slice intentionally reuses the start-flow groundwork that already inferred Junior/Senior pair hints and routing guardrails. Rather than inventing a second concurrency system, the work hardens the planning and governance layers so same-specialty expansion now has auditable plan evidence and an explicit serial fallback when boundaries are missing.

---

## Scope

### In Scope

- Scaffold `## Concurrency Rationale` into iteration plans with roster, scope, and hotspot signals
- Extend task schema to carry `Owner File Globs` for same-specialty ownership boundaries
- Enforce safe same-specialty planning in governance validation
- Add integration coverage for rationale scaffolding and serial-vs-parallel planning policy
- Sync the iteration artifact contract and planning regression fixtures to the new schema

### Out of Scope

- New downstream CLI for concurrency analysis beyond the current plan scaffold and validator surfaces
- Role-label overrides in `.specrew\role-assignments.yml`
- Multi-lane validation scaffolding (Iteration 9)

---

## Requirements Traceability

| Spec Ref | Requirement | Planned Deliverables | Owner |
|----------|-------------|----------------------|-------|
| FR-038 | Concurrency-aware sizing analysis | plan scaffold rationale section with roster/scope/hotspot signals and explicit serial fallback guidance | Planner |
| FR-039 | Paired same-specialty proposal governance | plan/task schema that can represent Junior/Senior same-specialty ownership explicitly without anonymous cloning | Planner + Reviewer |
| FR-040 | Junior/Senior routing policy preservation | existing start-flow pair/routing guidance kept green while new governance surfaces stay aligned | Implementer |
| FR-041 | Safe parallel ownership boundaries | validator enforcement for `Owner File Globs` or explicit serial fallback, plus contract and test coverage | Reviewer + Implementer |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T-801 | Add auditable concurrency rationale scaffolding to iteration plans | FR-038 | US-9 | 2 | Planner | — | done | copilot-agent | 2 | pass |
| T-802 | Enforce same-specialty ownership boundaries or explicit serial fallback in governance validation | FR-041 | US-9 | 2 | Reviewer | extensions/specrew-speckit/scripts/validate-governance.ps1 | done | copilot-agent | 2 | pass |
| T-803 | Add integration coverage for concurrency rationale scaffolding and safe same-specialty planning | FR-038, FR-041 | US-9 | 2 | Implementer | tests/integration/concurrency-sizing.ps1 | done | copilot-agent | 2 | pass |
| T-804 | Sync iteration artifact contract/examples and planning regression fixtures to the new task schema | FR-039, FR-040, FR-041 | US-9 | 1 | Planner | specs/001-specrew-product/contracts/iteration-artifacts.md, tests/integration/planning-overcommit.ps1 | done | copilot-agent | 1 | pass |

**Planned Total**: 7 story_points

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Keep the slice fixed to concurrency planning and governance surfaces. |
| Time Limit (hours) | n/a | Not used for this scope-bounded iteration. |
| Overcommit Threshold | 1.0 | No overcommit expected at planned capacity 7/20. |
| Defer Strategy | manual | If follow-up concurrency work appears, defer explicitly rather than widening the slice. |
| Calibration Enabled | true | Retro should confirm whether governance-focused slices still fit the current baseline. |

---

## Concurrency Rationale

- Current roster snapshot: the baseline Specrew planning/review roles remain sufficient to implement the governance slice itself.
- Technology and scope signals: the product requirements call for concurrency-aware team shaping, but the implementation work in this iteration is concentrated in planning, validation, and contract surfaces.
- Task dependency graph: rationale scaffolding had to land before validator enforcement and before the new integration test could exercise serial-vs-parallel policy.
- Workstream separability: the code changes were separable across scaffold, validator, and tests, but same-specialty execution in downstream projects must still prove safe parallelism per-plan.
- Shared-surface conflict risk: same-specialty work becomes unsafe when tasks overlap on the same logical surface without an explicit boundary field.
- Prior reviewer ownership/hotspot evidence: the scaffold now surfaces the latest code-map hotspot hints when they exist so future same-specialty proposals are grounded in observed churn, not intuition alone.
- Recommendation: downstream plans may keep Junior/Senior same-specialty work serial by default. Parallel execution is only acceptable once `Owner File Globs` (or equivalent ownership boundaries) are recorded for the participating tasks.

---

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Map FR-038..FR-041 to scaffold, validator, and contract surfaces |
| Implementation | 3 | Add rationale generation, new task schema, and validator enforcement |
| Review | 2 | Run planning/governance/start-flow regression coverage |
| Rework | 1 | Buffer for validator or fixture mismatches |

---

## Acceptance Checkpoints

1. Newly scaffolded iteration plans include a `## Concurrency Rationale` section plus `Owner File Globs` in the task table.
2. Governance validation rejects same-specialty Junior/Senior plans that lack explicit ownership boundaries unless the rationale keeps the work serial.
3. The concurrency-sizing integration test proves both the failing and accepted governance paths for same-specialty planning.
4. Existing start-flow pair-hint and routing-guardrail behavior remains intact after the planning/governance hardening.

## Notes

- Iteration 008 hardens concurrency governance without expanding into a separate planner daemon or live runtime orchestrator.
- Existing Junior/Senior pair inference in `specrew-start.ps1` remains the proposal surface; this iteration makes the plan and validator carry the auditable evidence and safety checks.

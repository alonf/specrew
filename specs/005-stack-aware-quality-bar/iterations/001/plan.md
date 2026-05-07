# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 20/20 story_points
**Started**: 2026-05-07
**Completed**:

## Summary

Iteration 001 completed its bounded 20-point Phase 1 / first-slice execution scope for feature `005-stack-aware-quality-bar`, covering Slice A (quality asset registry + versioned sources) and Slice B (planning-time quality profile integration). Setup work `T001` and `T002` remained complete, `T003` through `T011` are now delivered, and the reviewer closeout packet is in place so this slice can be attributed cleanly before Iteration 002 proceeds.

The rest of the feature's approved Phase 1 scope remains in-bounds but is not hidden inside this iteration. Shared evidence foundation work (`T012`-`T017`) and the quickstart reconciliation task (`T018`) are deferred to the next iteration so this plan stays within the configured 20-point capacity and preserves the dependency order from the feature-level `plan.md`.

**Primary Focus**: quality asset registry + planning-time quality profile publication  
**Target Slices**: Slice A1-A3, Slice B1-B3  
**Target User Story**: US-1  
**Deferred Within Phase 1**: Slice C1-C3, Slice D1-D2, and Polish task `T018` (next iteration; not descoped from the feature)

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-022, FR-023 | Versioned lens checklist sources and human-readable storage | ✅ `T001`, `T005` | Spec Steward | Establishes the Phase 1 lens source-of-truth surface |
| FR-024, FR-024a, FR-025 | Versioned stack preset catalog and worked example | ✅ `T001`, `T004`, `T006` | Implementer + Planner | Covers preset scaffolding, discovery wiring, and required worked example |
| FR-026 | Reviewed lens upgrade workflow and authoring rules | ✅ `T005`, `T007` | Spec Steward | Documentation path stays explicit and auditable |
| FR-002, FR-003, FR-003a, FR-004 | Infer stack-aware quality profiles and stack-appropriate tool bundles | ✅ `T008`, `T009` | Reviewer + Planner | Recognized-stack plus bounded custom-composition planning path |
| FR-010, FR-011, FR-015 | Publish explicit quality profile, gates, and not-applicable rationale in planning artifacts | ✅ `T008`, `T010`, `T011` | Reviewer + Spec Steward + Planner | Rendering and governance wiring for the planning slice |
| FR-027 through FR-030a, FR-012 | Shared evidence foundation and governance enforcement | ⏳ Deferred to Iteration 002 (`T012`-`T017`) | Implementer + Reviewer | Follows after planning-time profile output is stable |
| FR-011, quickstart.md | Operator documentation reconciliation | ⏳ Deferred to Iteration 002 (`T018`) | Spec Steward | Update docs after evidence scaffolding lands |

---

## Execution Slice Acceptance Criteria

1. The Phase 1 quality asset roots, preset sources, and lens checklist sources exist and are scaffoldable from the extension-owned templates.
2. `tests\integration\quality-profile-foundation.ps1` covers scaffold/registry behavior plus recognized-stack and bounded custom-composition planning assertions.
3. `resolve-quality-profile.ps1` can resolve stack signals, risk dimensions, preset selection, and not-applicable reasoning for the approved Phase 1 planning slice.
4. Planning artifacts render the explicit quality profile, preset/tool-bundle references, required gates, and explicit Phase 2+ deferrals without implying later-slice evidence workflows.
5. The iteration remains reviewable as a bounded Slice A/B execution slice and does not silently absorb shared evidence foundation or later-phase work.

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | All tasks trace to the approved Phase 1 / first-slice scope from `spec.md`, feature `plan.md`, and `tasks.md`. Deferred follow-on tasks remain explicit. |
| **Traceability** | ✅ PASS | Every task row maps to requirement IDs and US-1. Deferred Phase 1 follow-on work is named rather than hidden. |
| **Ownership** | ✅ PASS | Owners follow the feature-level task table assignments: Spec Steward, Implementer, Planner, Reviewer. |
| **Capacity** | ✅ PASS | Active iteration load is capped at 20 story points by limiting Iteration 001 to `T001`-`T011`. `T012`-`T018` are deferred to the next iteration. |
| **Execution Support** | ✅ PASS | `plan.md`, `state.md`, `drift-log.md`, `review.md`, `retro.md`, and the reviewer closeout packet now describe the completed Slice A/B handoff without claiming final human sign-off or feature completion. |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Create the Phase 1 quality asset source roots in `extensions/specrew-speckit/templates/quality/presets/` and `extensions/specrew-speckit/templates/quality/lenses/` | FR-022, FR-023, FR-024 | US-1 | 1 | Spec Steward | `extensions/specrew-speckit/templates/quality/presets/**`, `extensions/specrew-speckit/templates/quality/lenses/**` | done |  |  |  |
| T002 | Create deterministic fixture roots for quality-profile, mechanical-findings, and quality-evidence coverage | FR-010, FR-011, FR-012 | US-1 | 1 | Implementer | `tests/integration/fixtures/quality-profile-foundation/**`, `tests/integration/fixtures/mechanical-findings-contract/**`, `tests/integration/fixtures/quality-evidence-governance/**` | done |  |  |  |
| T003 | Add scaffold-and-asset-registry regression coverage in `tests/integration/quality-profile-foundation.ps1` | FR-023, FR-024, FR-025 | US-1 | 2 | Reviewer | `tests/integration/quality-profile-foundation.ps1`, `tests/integration/fixtures/quality-profile-foundation/**` | done |  |  |  |
| T004 | Extend downstream quality asset discovery and scaffold output in `extensions/specrew-speckit/scripts/scaffold-governance.ps1` | FR-023, FR-024, FR-025 | US-1 | 3 | Implementer | `extensions/specrew-speckit/scripts/scaffold-governance.ps1` | done |  |  |  |
| T005 | Create versioned lens checklist sources for security, robustness, and test-integrity baselines | FR-022, FR-023, FR-026 | US-1 | 2 | Spec Steward | `extensions/specrew-speckit/templates/quality/lenses/*.md`, `extensions/specrew-speckit/templates/quality/README.md` | done |  |  |  |
| T006 | Create the Phase 1 preset catalog including the `node-public-ws-service` worked example | FR-024, FR-024a, FR-025, FR-026 | US-1 | 3 | Planner | `extensions/specrew-speckit/templates/quality/presets/*.md` | done |  |  |  |
| T007 | Document the reviewed lens-upgrade workflow and quality asset authoring rules | FR-026 | US-1 | 1 | Spec Steward | `extensions/specrew-speckit/templates/quality/README.md`, `extensions/specrew-speckit/README.md` | done |  |  |  |
| T008 | Add recognized-stack and bounded-custom-composition plan assertions in `tests/integration/quality-profile-foundation.ps1` | FR-002, FR-003, FR-003a, FR-004, FR-010, FR-015 | US-1 | 2 | Reviewer | `tests/integration/quality-profile-foundation.ps1`, `tests/integration/fixtures/quality-profile-foundation/**` | done |  |  |  |
| T009 | Implement stack-signal, risk-dimension, preset-selection, bounded custom-composition resolution, and not-applicable gate reasoning | FR-002, FR-003, FR-003a, FR-004, FR-015 | US-1 | 3 | Planner | `extensions/specrew-speckit/scripts/resolve-quality-profile.ps1` | done |  |  |  |
| T010 | Wire quality-profile resolution into before-plan governance and coordinator guidance | FR-010, FR-011, FR-015 | US-1 | 2 | Spec Steward | `extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md`, `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | done |  |  |  |
| T011 | Render the Phase 1 quality planning section in `.specify/templates/plan-template.md` | FR-010, FR-011, FR-015 | US-1 | 2 | Planner | `.specify/templates/plan-template.md` | done |  |  |  |

**Total Effort**: 20 story_points

---

## Deferred Follow-On Within Approved Phase 1 Scope

| Deferred Task(s) | Effort | Reason | Target |
| ---------------- | ------ | ------ | ------ |
| T012-T017 | 17 | Shared evidence foundation depends on the Slice A/B planning outputs and would push the active iteration above the configured 20-point limit. | Iteration 002 |
| T018 | 1 | Quickstart/README reconciliation should follow the implemented scaffold/evidence path, not precede it. | Iteration 002 |

This defer is a planning-capacity split, not a scope reduction. The deferred tasks remain part of the approved Phase 1 feature plan and must be carried into the next iteration.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | The Planner makes explicit defer decisions when a slice exceeds capacity. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments when actual variance accumulates. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Technology and scope signals: this slice touches shared governance templates, PowerShell scaffolding, and integration fixtures; the work is cross-cutting rather than cleanly separable by same-specialty pairs.
- Task dependency graph: Setup (`T001`-`T002`) is complete; Foundational Slice A (`T003`-`T007`) must land before User Story 1 Slice B (`T008`-`T011`) can finish safely.
- Workstream separability: limited. `T003`, `T005`, `T006`, and `T007` can progress in parallel after the shared roots exist, but the resolver/rendering tasks depend on the asset contract.
- Shared-surface conflict risk: elevated around the same template and governance files; keep execution serial unless an explicit handoff re-partitions ownership later.
- Recommendation: do not introduce Junior/Senior same-specialty expansion in this iteration. Keep the approved baseline roles and dependency order from `tasks.md`.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 4 | `T008`-`T011` publish the Phase 1 quality profile into planning surfaces |
| Discovery/Spikes | 0 | No separate spike is authorized in this repair pass |
| Implementation | 14 | `T001`-`T007` establish asset roots, fixtures, scaffold wiring, and versioned sources |
| Review | 1 | Reserve for review/demo handoff once the execution slice is complete |
| Rework | 1 | Small buffer for contract-alignment fixes discovered during slice execution |

## Implementation Approval

- **Approval Verdict**: approved-to-execute
- **Approved By**: Alon Fliess (human developer)
- **Recorded Evidence**: current session instruction — "OK, continue implementation"
- **Scope Approved for Execution**: Iteration 001 active slice (`T001`-`T011`) inside the already-approved Phase 1 / first-slice feature boundary
- **Gate Effect**: this plan authorized execution for the bounded Slice A/B scope; execution and review are now complete enough to place Iteration 001 in `retro`, while final human sign-off and feature completion remain open.

## Notes

- This repair pass now records the completed Iteration 001 execution slice and its review/closeout artifacts. It does not claim final human sign-off or feature completion.
- `T001` and `T002` are carried in as already-complete setup work because `tasks.md` records them complete and the corresponding scaffold roots/fixtures already exist in the repository.
- `T012` through `T018` remain approved Phase 1 follow-on work, but they belong to Iteration 002 and are no longer listed as remaining work for this iteration boundary.

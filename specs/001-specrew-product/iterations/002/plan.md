# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 16/20 story_points
**Started**: 2026-04-20
**Completed**: 2026-05-03

## Summary

Iteration 002 is the post-MVP capability pass focused on six deferred requirements:

- FR-007 configurable effort model
- FR-015 process-quality scorer slice
- FR-017 overcommit detection and deferral guidance
- FR-019 programmatic resume from persisted task state
- FR-020 brownfield-safe bootstrap merge behavior
- FR-021 cross-agent review routing (independent reviewer/spec steward preference)

Execution commenced 2026-04-20 following Iteration 001 closure and Picard's FR-020 brownfield audit. T-205 and T-206 (FR-020) are complete with binding PASS recorded in Worf's 2026-05-03 FR-020 acceptance review. T-204 (FR-019) is accepted, V-R7-2 and T-201 (planning/design spikes) are complete for FR-021 and FR-007 respectively, and T-202 (FR-017) plus T-207 (FR-015 process scorer slice) remain accepted in Worf's 2026-05-03 slice review. This final implementation batch closes T-203 and T-208; Iteration 002 review and retro are now recorded, and only Alon's final sign-off remains before the iteration can move from `retro` to `complete`.

---

## Scope

### In Scope

- Iteration planning model improvements (effort unit + capacity)
- Planning-time overcommit detection and defer suggestions
- Resume command behavior based on `state.md`
- Brownfield merge behavior in `specrew init` without overwrite
- Process-quality scoring output in `evaluation/`
- Per-role review routing validation and implementation path for `preferred_agent`

### Out of Scope

- FR-015 outcome scorer and full end-to-end harness (Iteration 3)
- FR-012 collision detector expansion (Iteration 3)
- FR-016 upgrade-preservation hardening pass (Iteration 3)

---

## Requirements Traceability

| Spec Ref | Requirement | Planned Deliverables | Owner |
|----------|-------------|----------------------|-------|
| FR-007 | Configurable effort unit and capacity | effort-model schema + planning integration + docs | Planner + Implementer |
| FR-015 (process slice) | Process-quality scoring | process scorer script + report section + fixture validation | Implementer |
| FR-017 | Overcommit detection + defer recommendations | planning checks + defer suggestion logic + test scenarios | Planner + Implementer |
| FR-019 | Programmatic resume command | resume script command path + state parser + restart behavior | Implementer |
| FR-020 | Brownfield-safe bootstrap merge | merge rules + conflict prompts + dry-run evidence | Implementer |
| FR-021 | Cross-agent review routing | V-R7-2 validation spike + routing config behavior + guardrails | Planner + Implementer |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| V-R7-2 | Validate per-role delegated-agent routing surface (`preferred_agent`) | FR-021 | US-3 | 1 | Planner | done | data | 1 | pass |
| T-201 | Add configurable effort model fields and defaults | FR-007 | US-2, US-4 | 2 | Planner | done | data | 2 | pass |
| T-202 | Implement overcommit detection + deferral suggestions in planning flow | FR-017 | US-2, US-4 | 2 | Implementer | done | copilot-agent | 2 | pass |
| T-203 | Wire effort model into planning artifact output | FR-007, FR-017 | US-2, US-4 | 1 | Implementer | done | copilot-agent | 1 | |
| T-204 | Implement resume command from `state.md` last-completed task | FR-019 | US-2 | 3 | Implementer | done | copilot-agent | 3 | |
| T-205 | Brownfield merge rules for roles/ceremonies/governance artifacts | FR-020 | US-1 | 3 | Implementer | done | Data | 3 | pass |
| T-206 | Brownfield dry-run and conflict prompt hardening | FR-020 | US-1 | 1 | Planner | done | Data | 1 | pass |
| T-207 | Implement process-quality scorer (artifact and phase adherence checks) | FR-015 | US-6 | 2 | Implementer | done | copilot-agent | 2 | pass |
| T-208 | Add process scorer report output in `evaluation/` | FR-015 | US-6 | 1 | Implementer | done | copilot-agent | 1 | |

**Planned Total**: 16 story_points

---

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

---

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 3 | V-R7-2, task decomposition, dependency ordering |
| Implementation | 10 | FR-007/017/019/020/021 and process scorer wiring |
| Review | 2 | Traceability and acceptance checks |
| Rework | 1 | Buffer for integration fixes |

---

## Acceptance Checkpoints

1. Planning artifacts can represent configurable effort and capacity, including an effort-model snapshot validated against `.specrew/iteration-config.yml` (FR-007).
2. Over-capacity plans are flagged with explicit defer recommendations (FR-017).
3. Resume command continues from last completed task recorded in `state.md` (FR-019).
4. Brownfield bootstrap does not silently overwrite user config and supports reviewable merge paths (FR-020).
5. Process scorer produces structured JSON plus Markdown report output under `evaluation\report.md` (FR-015 process slice only).
6. FR-021 routing implementation only proceeds after V-R7-2 confirms viable routing behavior (or records blocker path explicitly).

## Notes

- Iteration 002 execution began 2026-04-20 following Iteration 001 closeout (Alon sign-off 2026-04-18) and Picard's FR-020 brownfield audit which identified acceptance criteria for T-205/T-206.
- T-205/T-206 are complete with binding PASS recorded in `.squad/decisions.md` (2026-05-03 FR-020 Brownfield Bootstrap Safety Review — ACCEPTED); accepted evidence covers conflict blocking, dry-run artifact persistence, `-Force` non-bypass, and entrypoint validation.
- T-204 is implementation-complete and reviewer-ready: `resume-iteration.ps1` now repairs stale `state.md` task metadata from the authoritative task table, the downstream runtime continues to deploy the recovery skill and helper script, and `tests\integration\iteration-resume.ps1` covers the stale-state repair path.
- Capacity now reflects 16/20 configured story_points with 16 delivered inside the execution batch (4 accepted for FR-020, 3 completed for FR-019 awaiting review, 4 completed for FR-007/FR-017 planning-artifact wiring, 2 completed for FR-017 acceptance work, and 3 completed for the FR-015 process-scorer/report slice).
- State.md and drift-log.md created at execution start to track execution state and alignment drift per iteration-artifacts.md contract.
- T-202 is reviewer-accepted for FR-017: overcommitted planning artifacts now fail with explicit lowest-priority deferral guidance, backed by `tests\integration\planning-overcommit.ps1`.
- T-203 completes FR-007/FR-017 planning-artifact wiring: `scaffold-iteration-plan.ps1` remains the source of the effort-model snapshot, `validate-governance.ps1` now validates the `## Effort Model` section plus capacity/config alignment, and `tests\integration\planning-effort-model.ps1` covers custom-unit generation plus mismatch rejection.
- T-207 is reviewer-accepted for the FR-015 process slice: `evaluation\scorers\process-scorer.ps1` returns structured artifact/phase adherence output with fixture coverage in `tests\integration\process-quality-scorer.ps1`.
- T-208 adds report output for the FR-015 process slice: `evaluation\report.md` is now generated via `process-scorer.ps1 -WriteReport`, with fixture coverage in `tests\integration\process-quality-report.ps1` and outcome-quality sections explicitly deferred to Iteration 3.

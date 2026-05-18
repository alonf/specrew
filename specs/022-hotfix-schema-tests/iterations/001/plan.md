# Iteration Plan: 001 (Planning Scaffold)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 0/20 story_points
**Started**: 2026-05-18
**Completed**:

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | The feature MUST ensure the closeout-generated identity state contains the machine-readable session-state fields required by restart validation while preserving the existing human-readable summary fields. **Owner role**: Reliability steward. **Delivery window**: Iteration 001. | — |
| FR-002 | Machine-readable closeout state written at feature closeout MUST describe the active status, feature reference, boundary type, recorded timestamp, and any relevant iteration or authorization context needed for stale-state recovery. **Owner role**: Reliability steward. **Delivery window**: Iteration 001. | — |
| FR-003 | The closeout identity state MUST remain understandable to a human operator without requiring the operator to infer meaning from machine-only fields. **Owner role**: UX steward. **Delivery window**: Iteration 001. | — |
| FR-004 | The product MUST provide regression coverage proving that closeout-generated identity frontmatter can be consumed by the same parser used by stale-state validation. **Owner role**: Quality steward. **Delivery window**: Iteration 001. | — |
| FR-005 | Feature 022 MUST keep schema-parity auditing limited to the closeout identity surface at `.squad/identity/now.md`. Auditing `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/drift-log.md`, or other state artifacts for the same gap is explicitly out of scope for this hotfix and deferred to Proposal 054 / a future durable pre-merge gate. **Owner role**: Governance steward. **Delivery window**: Iteration 001. | — |
| FR-006 | The feature MUST restore boundary-state synchronization at all seven lifecycle boundaries: specify, clarify, plan, tasks, review-signoff, iteration closeout, and feature closeout. **Owner role**: Runtime steward. **Delivery window**: Iteration 001. | — |
| FR-007 | Each lifecycle boundary MUST record synchronization at the correct moment in the lifecycle so restart logic and lifecycle history agree on the current feature state. **Owner role**: Runtime steward. **Delivery window**: Iteration 001. | — |
| FR-008 | The brownfield boundary scripts that implement the seven lifecycle transitions MUST be audited so missing or misplaced synchronization calls are identified and corrected. **Owner role**: Runtime steward. **Delivery window**: Iteration 001. | — |
| FR-009 | The product MUST provide lifecycle coverage that verifies a simulated full lifecycle produces all seven boundary-sync entries in the decision ledger in order. **Owner role**: Quality steward. **Delivery window**: Iteration 001. | — |
| FR-010 | If a lifecycle boundary fails to synchronize correctly, the resulting mismatch MUST remain observable through restart validation or lifecycle evidence rather than silently passing. **Owner role**: Reliability steward. **Delivery window**: Iteration 001. | — |
| FR-011 | When stale session state is detected at `specrew start`, the product MUST present a usable recovery experience that accepts an operator's A/B/C recovery choice rather than exiting without progressing. **Owner role**: UX steward. **Delivery window**: Iteration 001. | — |
| FR-012 | The product MUST provide a `--recover` start option that bypasses the blocking stale-state gate and launches directly into recovery mode. **Owner role**: UX steward. **Delivery window**: Iteration 001. | — |
| FR-013 | Recovery mode MUST still explain why restart entered recovery and what next action the operator is expected to take. **Owner role**: UX steward. **Delivery window**: Iteration 001. | — |
| FR-014 | The `--recover` flag MUST bypass the stale-state pre-launch gate and launch recovery mode without implicitly changing any best-guess or autopilot-style confirmation behavior. If confirmation behavior ever needs separate control, it MUST be introduced through a distinct flag rather than folded into `--recover`. **Owner role**: Governance steward. **Delivery window**: Iteration 001. | — |
| FR-015 | The product MUST provide end-to-end restart coverage proving that a recently shipped feature does not leave `specrew start` blocked by stale-state errors. **Owner role**: Quality steward. **Delivery window**: Iteration 001. | — |
| FR-016 | This hotfix MUST remain scoped to a single iteration of approximately 10 story points and preserve the standard seven-boundary lifecycle model. **Owner role**: Product steward. **Delivery window**: Iteration 001. | — |
| FR-017 | The feature MUST carry forward the Feature 021 operating defaults for a 3-cycle repair budget, push-after-every-commit discipline, live bookkeeping during execution, and pre-handoff verification. **Owner role**: Governance steward. **Delivery window**: Iteration 001. | — |
| FR-018 | The specification MUST identify any known mismatch between the intended Feature 020 design and the observed brownfield behavior, along with the reconciliation path for this hotfix. **Owner role**: Governance steward. **Delivery window**: Iteration 001. | — |
| FR-019 | The possible fourth bug involving lifecycle inbox-to-ledger delivery / Scribe auto-consolidation MUST be recorded as follow-up work and remain out of Feature 022 acceptance scope. Feature 022 is limited to the three confirmed bugs plus the regression coverage needed to prevent their return. **Owner role**: Product steward. **Delivery window**: Iteration 001. | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Repository maximum from `.specrew/iteration-config.yml`; Feature 022 planning is additionally constrained to a 10 story point hotfix lock. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Planning note: the spec's stewardship labels are descriptive ownership cues only; `/speckit.plan` must map them onto baseline Squad roles rather than inventing a new roster.
- Task dependency graph: detailed dependencies are intentionally pending task decomposition in the planning ceremony.
- Workstream separability: the hotfix spans shared PowerShell lifecycle scripts, restart UX, and regression coverage, so assume a serial planning baseline until task boundaries are explicit.
- Shared-surface conflict risk: elevated across lifecycle/state helpers because late-boundary synchronization and restart recovery touch overlapping governance surfaces.
- Prior reviewer ownership/hotspot evidence: none recorded for this feature yet.
- Recommendation: keep the scaffold neutral and defer any same-specialty parallelism decision until the task table and owner globs exist.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | TBD | Detailed decomposition is intentionally deferred to `/speckit.plan` |
| Discovery/Spikes | TBD | Reserve only if brownfield investigation needs bounded proof during planning |
| Implementation | TBD | Final task mix must stay within the single-iteration hotfix lock |
| Review | TBD | Estimate after task and evidence lanes are defined |
| Rework | 1 | Keep 1 story point reserved inside the 10 story point Feature 022 hotfix ceiling |

## Traceability Summary

- Requirement scope for this stub: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-017, FR-018, FR-019
- User stories represented in current scope: 
- Pending detailed planning: populate the task table, then run specrew-capacity-planning and specrew-traceability-check before approval.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.
- Feature-specific guardrail: keep the final plan inside a single-iteration 10 story point lock with 1 story point reserved for bounded repair.

## Notes

- This planning scaffold captures the approved clarified scope ahead of detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.
- This file preserves the before-plan scaffold truthfully so `/speckit.plan` can continue with detailed decomposition without treating the planning boundary as unopened.

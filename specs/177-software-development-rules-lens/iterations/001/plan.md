# Iteration Plan: 001 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 13.5/20 story_points
**Started**: 2026-06-10
**Completed**: 2026-06-10

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
    (Common mistakes the validator REJECTS: `approved`, `in-progress`, `done`, `ready`.)
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
    Append explanatory notes in the Notes section at the bottom instead.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
    (Note `in-progress` uses a hyphen, not an underscore. `done` not `completed`.)
-->

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | A `code-implementation` lens MUST exist and be registered in the catalog (`index.yml`, | — |
| FR-002 | A data-driven `code-rules.yml` catalog MUST ship with Specrew encoding the 49 maintainer | — |
| FR-003 | Run via the workshop, the lens MUST resolve the feature's stack and present rules via the | — |
| FR-004 | The workshop MUST write a schema-valid, reference-by-ID `implementation-rules.yml` | — |
| FR-005 | A new `specrew-code-rules` skill MUST deploy to every host skill surface via the existing | — |
| FR-006 | `plan.md` MUST convert the selected rules into implement constraints (Planner directive), | — |
| FR-007 | The manifest MUST carry forward-compatible `context_scope` | — |
| FR-008 | With no manifest, the skill MUST still surface the catalog `baseline-default` rules | — |
| FR-009 | The human MUST be able to set/unset individual rules and add custom rules. | — |
| FR-010 | The lens MUST open with a "source of code-rules truth" question — whether the human has an | — |
| FR-011 | When a guideline is provided, the lens MUST perform assisted ingestion: map it onto the | — |
| FR-012 | Custom rules MUST be accepted via free-text OR a pasted document, captured into the | — |
| FR-013 | The lens MUST include a **Tooling / Dependency Selection Research** decision area that | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Author code-rules.yml catalog (baseline + 3 additions + per-stack) | FR-002 | US3 | 3 | Implementer | extensions/specrew-speckit/knowledge/design-lenses/code-rules.yml | done | copilot | | pass |
| T002 | Finalize implementation-rules.schema.json | FR-004 | US3 | 1.5 | Implementer | specs/177-software-development-rules-lens/contracts/implementation-rules.schema.json | done | copilot | | pass |
| T003 | Author code-implementation.md lens md | FR-001 | US2 | 2.5 | Implementer | extensions/specrew-speckit/knowledge/design-lenses/code-implementation.md | done | copilot | | pass |
| T004 | Register lens (index.yml, applicability-map, lens map, lensIds) | FR-001 | US1 | 0.5 | Implementer | extensions/specrew-speckit/knowledge/design-lenses/index.yml | done | copilot | | pass |
| T005 | Manifest writer/validator + overlay merge | FR-004 | US2 | 2.5 | Implementer | scripts/internal/code-implementation-lens.ps1 | done | copilot | | pass |
| T006 | Dependency-selection decision area | FR-013 | US2 | 1 | Implementer | extensions/specrew-speckit/knowledge/design-lenses/code-rules.yml | done | copilot | | pass |
| T007 | Test catalog integrity | FR-002 | US3 | 1 | Implementer | tests/unit/code-implementation-lens.tests.ps1 | done | copilot | | pass |
| T008 | Test manifest schema + overlay | FR-004 | US2 | 1 | Implementer | tests/unit/code-implementation-lens.tests.ps1 | done | copilot | | pass |
| T009 | Test registration | FR-001 | US1 | 0.5 | Implementer | tests/integration/code-rules-skill-multihost.tests.ps1 | done | copilot | | pass |

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
- Technology and scope signals: No single specialty dominates yet; treat the slice as general product work until task decomposition adds sharper evidence.
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: Current scope does not yet prove enough safe parallelism for same-specialty expansion; default to a smaller serial team until tasks are clearer.
- Shared-surface conflict risk: no elevated shared-surface warning inferred yet.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | TBD | Populate after task decomposition and approval gating |
| Discovery/Spikes | TBD | Capture any required risk-reduction work revealed during planning |
| Implementation | TBD | Sum planned delivery tasks once the task table is complete |
| Review | TBD | Estimate review/demo effort after verdict flow is defined |
| Rework | TBD | Expected needs-work buffer if review finds gaps |

## Traceability Summary

- Requirement scope for this stub: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013
- User stories represented in current scope: US1, US2, US3, US4
- Pending detailed planning: populate the task table, then run specrew-capacity-planning and specrew-traceability-check before approval.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.

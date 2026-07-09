# Iteration Plan: 001 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 5/26 story_points
**Started**: 2026-07-10
**Completed**:

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
| FR-033 | Deny-list lint lane over exactly the deploy surface; unannotated hit = red; lands first | US5 |
| FR-034 | Parameterization rule documented; lint red-output points at it | US5 |
| FR-037 | SelfLeakDenyList as versioned JSON (schema_version, entry shape, per-file-kind annotation escapes) | US5 |
| FR-038 | Spec-Kit pin 0.12.9: probe, migrate --ai to --integration, fixture suites, evidence-gated extension decisions, pin surfaces | US6 |
| FR-039 | Squad pin 0.11.0: minimums/defaults + scratch probe + layout suites | US6 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Spec-Kit 0.12.9 scratch probe (evidence recorded) | FR-038 | US6 | 0.5 | Implementer | specs/198-beta2-hardening/iterations/001/quality/** | planned | — | — | — |
| T002 | Spec-Kit migration + pin surfaces (fixture suites green) | FR-038 | US6 | 1.0 | Implementer | scripts/specrew-init.ps1, scripts/internal/version-check.ps1, extensions/specrew-speckit/extension.yml, .specify/** | planned | — | — | — |
| T003 | Squad 0.11.0 bump (probe + layout suites) | FR-039 | US6 | 0.5 | Implementer | scripts/internal/dependency-install.ps1, scripts/internal/validate-versions.ps1, .github/workflows/** | planned | — | — | — |
| T004 | SelfLeakDenyList data file + seed + shape tests | FR-037 | US5 | 1.0 | Implementer | extensions/specrew-speckit/data/**, Specrew.psd1, tests/unit/** | planned | — | — | — |
| T005 | Self-leak lint + blocking CI job (paired fixtures) | FR-033 | US5 | 1.5 | Implementer | scripts/internal/lint-self-leak.ps1, .github/workflows/specrew-ci.yml, tests/unit/** | planned | — | — | — |
| T006 | Parameterization rule doc (lint points at it) | FR-034 | US5 | 0.5 | Implementer | docs/methodology/** | planned | — | — | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 26 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 26 story_points (capacity 26 x threshold 1.0). |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Technology and scope signals: Backend/service-oriented signals dominate the scoped requirements.
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: Conflict-heavy signals are present, so keep same-specialty work serial unless ownership boundaries become explicit.
- Shared-surface conflict risk: elevated due to shared-state / cross-cutting cues in scope text.
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

- Requirement scope for this stub: FR-033, FR-034, FR-037, FR-038, FR-039
- User stories represented in current scope: US5 (self-leak firewall, author-time arm), US6 (toolchain currency)
- Pending detailed planning: populate the task table, then run specrew-capacity-planning and specrew-traceability-check before approval.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.

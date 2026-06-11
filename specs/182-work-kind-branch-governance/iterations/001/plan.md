# Iteration Plan: 001 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 0/20 story_points
**Started**: 2026-06-11
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
| FR-001 | Specrew MUST define a work-kind taxonomy covering at least `software-feature`, | — |
| FR-002 | The DevOps lens MUST present the default PR-backed branch-governance model and | — |
| FR-003 | The DevOps lens MUST capture a configurable **`branch_model`** — branching | — |
| FR-004 | Specrew MUST distinguish `feature-closeout` from release/post-merge | — |
| FR-005 | Specrew MUST provide a lightweight `docs-only` lifecycle surface completable | — |
| FR-006 | Specrew MUST provide a `devops` work-kind lifecycle surface (CI/CD, repo | — |
| FR-007 | A **provider-neutral** CI validator MUST check, on a PR, that (a) exactly one | — |
| FR-008 | The DevOps lens MUST ask single-repo vs multi-repo and capture the | — |
| FR-009 | A work item declares its kind via an authoritative, forge-neutral checked-in | — |
| FR-010 | Specrew MUST record enforcement posture honestly; partial runtime enforcement | — |
| FR-011 | Specrew MUST define an emergency/bypass path that leaves a durable audit | — |
| FR-012 | Capability detection MUST report the achievable enforcement mechanism | — |
| FR-013 | Specrew MUST dogfood this model on its own repository (protected branch via | — |
| FR-014 | The methodology, the declaration, and the CI validator **core** MUST import no | — |
| FR-015 | Specrew MUST ship the `ProviderAdapter` **contract** + a **GitHub reference | — |
| FR-016 | Specrew MUST provide on-the-fly adapter **synthesis** conduct: generate a | — |
| FR-017 | The DevOps lens MUST capture a **`review_gate`** — human approvals + | — |
| FR-018 | Governance answers MUST persist to a **project-level** | — |
| FR-019 | Specrew MUST audit + decouple ALL downstream-governing surfaces (lifecycle | — |
| FR-020 | `apply_protection` MUST be human-approved, never auto-applied, never from an | — |
| FR-021 | Specrew MUST detect an existing brownfield CI/CD + branch-protection + review | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |

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
| Planning | TBD | Populate after task decomposition and approval gating |
| Discovery/Spikes | TBD | Capture any required risk-reduction work revealed during planning |
| Implementation | TBD | Sum planned delivery tasks once the task table is complete |
| Review | TBD | Estimate review/demo effort after verdict flow is defined |
| Rework | TBD | Expected needs-work buffer if review finds gaps |

## Traceability Summary

- Requirement scope for **iteration 001 (methodology layer)**: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-008, FR-009, FR-010, FR-014, FR-015 (contract + fallback), FR-016 (doc), FR-017, FR-018, FR-019 (inventory only), FR-021 (content). Deferred to Iter 2: FR-007, FR-011, FR-012, FR-013, FR-015 (GitHub detect), FR-016 (exercised), FR-020, FR-021 (detector). Deferred to Iter 3: FR-019 (decouple migration).
- User stories represented in iteration 001: US1 (lifecycle truth), US2 (DevOps-lens governance), US3 (docs-only/devops lifecycles), US6 (brownfield content). US4/US5 runtime land in Iter 2.
- Pending detailed planning: populate the task table at the tasks phase, then run specrew-capacity-planning and specrew-traceability-check before the before-implement gate.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- **Iteration 001 = the methodology layer** (Iter 1 of the 3-iteration plan in `../../plan.md`). The
  Scope Summary table above lists the full feature FR set for reference; the actual iteration-001
  delivery scope is the subset in the Traceability Summary. The task table is decomposed at the tasks
  phase (next boundary); the hardening-gate `Overall Verdict: ready` + the populated task table land at
  the before-implement gate.
- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.

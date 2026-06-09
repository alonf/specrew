# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 14.0/20 story_points
**Started**: 2026-06-09
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
| FR-001 | The workshop MUST run the `product-domain` lens before technical-lens | — |
| FR-002 | The lens MUST choose a depth (Light / Standard / Deep) based on risk and | — |
| FR-003 | The lens MUST capture, at the selected depth, the product/problem | — |
| FR-004 | The lens MUST tag material product-domain statements with an evidence | — |
| FR-005 | The lens MUST persist a human-readable record | — |
| FR-006 | `spec.md` MUST summarize the product-domain decisions without becoming | — |
| FR-007 | The structured product-domain record MUST be forward-compatible with the | — |
| FR-008 | When Proposal 162 product-level context exists, the feature-level | — |
| FR-009 | Batch approval of the lens agenda MUST NOT count as product-domain | — |
| FR-010 | The specify-boundary gate MUST require a valid product-domain record — | — |
| FR-011 | A `research-needed` evidence tag MUST block the plan boundary only when it | — |
| FR-012 | The lens conduct MUST reframe a solution-first request into the problem/ | — |
| FR-013 | The product-domain conduct change MUST deploy to the host-managed skill | — |
| FR-014 | The product-domain lens MUST run before EVERY feature at adaptive depth — it is | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Lens file product-domain.md | FR-002, FR-003, FR-004, FR-012, FR-014 | US1 | 2 | Implementer | extensions/specrew-speckit/knowledge/design-lenses/product-domain.md | done | claude | as-planned | — |
| T002 | First-stage catalog registration | FR-001 | US1 | 0.5 | Implementer | extensions/specrew-speckit/knowledge/design-lenses/index.yml | done | claude | as-planned | — |
| T003 | Structured-record schema | FR-004, FR-007, FR-008, FR-014, SC-008, SC-009 | US3 | 1 | Implementer | specs/176-product-domain-lens/contracts/product-domain.schema.json | done | claude | as-planned | — |
| T004 | Record writer/validator | FR-002, FR-005, FR-006, FR-011, SC-002, SC-004, SC-006 | US1 | 2 | Implementer | scripts/internal/product-domain-lens.ps1 | done | claude | as-planned | — |
| T005 | First-stage phase conduct | FR-001, FR-006, FR-012, SC-001 | US1 | 1.5 | Implementer | .claude/skills/specrew-design-workshop/SKILL.md | done | claude | as-planned | — |
| T006 | Test: runs before questionnaire | FR-001, SC-001 | US1 | 0.5 | Implementer | tests/unit/product-domain-lens.tests.ps1 | done | claude | as-planned | — |
| T007 | Test: adaptive depth L/S/D | FR-002, SC-002 | US1 | 0.5 | Implementer | tests/unit/product-domain-lens.tests.ps1 | done | claude | as-planned | — |
| T008 | Test: evidence tags + research-block | FR-004, FR-011, SC-003, SC-006 | US1 | 0.75 | Implementer | tests/unit/product-domain-lens.tests.ps1 | done | claude | as-planned | — |
| T009 | Test: dual-artifact persistence | FR-005, SC-004 | US1 | 0.5 | Implementer | tests/unit/product-domain-lens.tests.ps1 | done | claude | as-planned | — |
| T010 | Specify-gate floor | FR-009, FR-010, SC-004, SC-005 | US2 | 1.5 | Reviewer | scripts/internal/design-analysis-gate.ps1 | done | claude | as-planned | — |
| T011 | Test: batch approval rejected | FR-009, SC-005 | US2 | 0.5 | Reviewer | tests/unit/product-domain-lens.tests.ps1 | done | claude | as-planned | — |
| T012 | Multi-host conduct deploy | FR-013, SC-007 | US3 | 1 | Implementer | .agents/skills/specrew-design-workshop/SKILL.md | done | claude | as-planned | — |
| T013 | Test: schema hooks | FR-007, FR-008, FR-014, SC-008, SC-009 | US3 | 0.5 | Implementer | tests/unit/product-domain-lens.tests.ps1 | done | claude | as-planned | — |
| T014 | Test: host-skill parity | FR-013, SC-007 | US3 | 0.75 | Implementer | tests/integration/product-domain-multihost.tests.ps1 | done | claude | as-planned | — |
| T015 | Test: graceful degradation (no silent skip) | FR-010, FR-013 | US3 | 0.5 | Reviewer | tests/unit/product-domain-lens.tests.ps1 | done | claude | as-planned | — |

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
- Technology and scope signals: Backend/service-oriented signals dominate the scoped requirements.
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: Current scope does not yet prove enough safe parallelism for same-specialty expansion; default to a smaller serial team until tasks are clearer.
- Shared-surface conflict risk: no elevated shared-surface warning inferred yet.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0 | Spec/plan/tasks completed pre-execution via the lifecycle boundaries |
| Discovery/Spikes | 0 | No risk-reduction spikes required; the design is settled (Option B) |
| Implementation | 9.5 | Build tasks T001, T002, T003, T004, T005, T010, T012 |
| Review | 4.5 | Test tasks T006, T007, T008, T009, T011, T013, T014, T015 (behavior-proving) |
| Rework | TBD | Needs-work buffer if review finds gaps (not in the 13.5 SP task budget) |

## Traceability Summary

- Requirement scope: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-014 (all covered; FR-007/FR-008 forward-compatible shape only via T003/T013, runtime wiring deferred to Proposals 156/162)
- User stories represented in current scope: US1 (T001-T009), US2 (T010-T011), US3 (T003, T012-T015)
- Capacity: 14.0/20 story_points planned (9.5 build + 4.5 tests); within the 20 SP cap, single iteration, no overcommit
- Overcommit guardrail: total planned effort 14.0 SP is under the 20 SP capacity x 1.0 threshold; no deferrals required this iteration (the +0.5 over 13.5 is T015, the maintainer-accepted graceful-degradation test)

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.

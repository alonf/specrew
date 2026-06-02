# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 18/20 story_points
**Started**: 2026-06-02
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose.
  - Task Status MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | Scaffold conformant per-iteration `design-analysis.md` from a template | US1 |
| FR-002 | Validate design-analysis before `plan.md` generation | US1 |
| FR-003 | Block substantive `plan.md` until artifact + human decision valid | US1 |
| FR-004 | Render typed design-analysis gate packet from typed fields | US2 |
| FR-005 | Validate the rendered gate packet | US2 |
| FR-006 | Scope typed packet to the design-analysis gate only | US2 |
| FR-007 | Preserve selected option/modifications as plan input | US2 |
| FR-008 | Extend (not rewrite) the Feature 140 helper | US1 |
| FR-016 | Multi-iteration delivery + this iteration's capacity | US0 |
| FR-017 | Stack on Feature 140; do not force its closeout | US0 |
| FR-018 | No beta/stable publishing | US0 |
| FR-019 | Avoid Unix/wrapper/bootstrap surfaces | US0 |
| FR-020 | Render+validate min; durable 155-lite scoped to this gate | US2 |
| FR-021 | Prompt + callable pre-plan validator; no host hooks | US1 |
| FR-022 | Tolerant By-the-book detection (validator robustness) | US1 |
| FR-023 | Single-recommendation parsing tolerant of context (validator robustness) | US1 |

Deferred this iteration (carried within Feature 141): FR-009, FR-010, SC-006
(Applicable Lenses) pre-deferred 2026-06-02; FR-011–FR-015 + SC-007–SC-010
(smoke-test bundle) in later iterations.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Confirm scope/Option B/cap + guardrails | FR-016, FR-017, FR-018, FR-019 | US0 | 1 | Spec Steward | specs/141-design-gate-runtime-hardening/** | done | claude | — | pass |
| T002 | Template file + scaffold path | FR-001, FR-008, TG-007 | US1 | 3 | Implementer | extensions/specrew-speckit/templates/design-analysis.template.md, scripts/internal/design-analysis-gate.ps1 | done | claude | — | pass |
| T003 | Tolerant By-the-book detection | FR-022 | US1 | 1 | Implementer | scripts/internal/design-analysis-gate.ps1 | done | claude | — | pass |
| T004 | Single-recommendation parser + unit tests | FR-023 | US1 | 2 | Implementer | scripts/internal/design-analysis-gate.ps1, tests/unit/** | done | claude | — | pass |
| T005 | Callable pre-plan validator + prompt enforcement | FR-002, FR-003, FR-021 | US1 | 3 | Implementer | scripts/internal/design-analysis-gate.ps1, scripts/specrew-start.ps1 | done | claude | — | pass |
| T006 | Typed packet renderer + validator | FR-004, FR-005 | US2 | 2 | Implementer | scripts/internal/design-analysis-gate.ps1 | done | claude | — | pass |
| T007 | Durable 155-lite packet + plan-input continuity | FR-006, FR-007, FR-020 | US2 | 2 | Implementer | scripts/internal/design-analysis-gate.ps1, scripts/internal/sync-boundary-state.ps1 | done | claude | — | pass |
| T009 | Unit tests (scaffold/packet/validator-robustness) | SC-001, SC-004, SC-014 | US1 | 2 | Implementer | tests/unit/** | done | claude | — | pass |
| T010 | Integration tests (block/pass, compatibility) | FR-002, FR-003, SC-012 | US1 | 1 | Reviewer | tests/integration/** | done | claude | — | pass |
| T011 | Docs refresh + review gap ledger | TG-006, SC-011 | US0 | 1 | Planner | specs/141-design-gate-runtime-hardening/** | done | claude | — | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | Lens (T008) pre-deferred; validator robustness held firm. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Most implementation tasks (T002–T007) edit `scripts/internal/design-analysis-gate.ps1`, a shared surface — keep them serial to avoid conflicts.
- T009/T010 tests and T011 docs can proceed once the surfaces they cover stabilize.
- No Junior/Senior same-specialty expansion is justified: the work is small and concentrated on one helper. Default to the serial baseline team.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | T001 scope confirmation. |
| Discovery/Spikes | 0 | No spikes required. |
| Implementation | 13 | T002–T007 (template/scaffold, validator robustness, pre-plan validator, packet, durable storage/continuity). |
| Review | 4 | T009–T011 (tests + docs + review gap ledger). |
| Rework | 2 | Buffer within the 2 SP headroom under the cap if review finds gaps. |

## Traceability Summary

- Requirement scope for Iteration 1: FR-001–FR-008, FR-016–FR-023 (FR-022/FR-023 folded in firm).
- Deferred-within-feature: FR-009, FR-010, SC-006 (lens); FR-011–FR-015 (smoke bundle, later iterations).
- User stories represented: US0, US1, US2 (US3 lens deferred).
- Capacity: 18/20 consumed; 2 SP headroom; T008 (2 SP) deferred, not counted.

## Notes

- Iteration 1 hardens the design-gate runtime path and validator robustness only.
- Option B selected at design-analysis (`approved for plan with Option B`, decided at `337e2523`).
- Keep Status: planning until before-implement approval; the human start-implementation go-ahead authorizes execution.
- T002–T007 sequence edits to `scripts/internal/design-analysis-gate.ps1`; do not parallelize shared-surface edits.

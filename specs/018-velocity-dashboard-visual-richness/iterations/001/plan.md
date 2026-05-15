# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: reviewing
**Capacity**: 14.5/20 story_points
**Started**: 2026-05-15
**Completed**: 2026-05-15
**Review Completed**: 2026-05-15
**Hardening-Gate Sign-Off**: human sign-off and implementation authorization were recorded in `.squad/decisions.md` on 2026-05-15; this iteration artifact now captures the exact concern set required before execution starts
**Implementation Authorization**: bundled authorization was executed after `/speckit.specrew-speckit.before-implement` passed on 2026-05-15; the implementation package then cleared review-verdict-signoff with bounded repair `R-018-V1`, and retro remains separately authorized

## Scope Summary

Feature 018 remains a single-iteration delivery slice. This execution scaffold keeps the full approved
feature in one bounded implementation pass while preserving the explicit out-of-scope items from
`spec.md` (`working-days projection`, `MVP/1.0 dual horizons`, `minimum-days stretching`,
`bootstrapped-date anchor changes`, and `configurable velocity windows`).

| Slice | Task Range | Coverage | Why This Slice Exists | Primary Owner |
| --- | --- | --- | --- | --- |
| Setup scaffolding | T001-T002 | FR-016, FR-017, FR-018, TG-004, SC-004 | Establish quality and fixture roots before renderer work begins | Reliability steward + Test steward |
| Shared rendering policy | T003-T005 | FR-001, FR-004, FR-005, FR-008, FR-019 | Lock one CLI/renderer policy path before story work fans out | CLI steward + UX steward |
| User Story 1 rich rendering | T006-T013 | FR-004, FR-006..FR-013, FR-016, SC-001, SC-004 | Deliver the visible value: rich dashboard density plus velocity sparkline | UX steward + Product steward + Roadmap steward + Test steward |
| User Story 2 fallback + artifact trust | T014-T020 | FR-001, FR-004, FR-005, FR-007, FR-008, FR-009, FR-010, FR-014, FR-017, TG-004 | Preserve compatibility, closeout semantics, and artifact safety | UX steward + Product steward + Reliability steward + Test steward |
| User Story 3 regression, docs, and budget | T021-T027 | FR-015..FR-020, SC-002..SC-005 | Prove the feature ships without regressing Feature 017 or documentation trust | Reliability steward + Documentation steward + Test steward |
| Polish + full replay | T028-T030 | FR-001..FR-003, FR-015..FR-018, TG-004, SC-002..SC-005 | Close the iteration with explicit validation replay and deferral discipline | Reliability steward + Spec Steward |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| I1-01 | Scaffold quality and fixture roots | FR-016, FR-017, FR-018, TG-004 | Setup | 1.0 | Reliability steward, Test steward | `specs/018-velocity-dashboard-visual-richness/iterations/001/quality/**`, `tests/integration/fixtures/feature-018-dashboard/**` | done | implementer | 1.0 | pass |
| I1-02 | Lock shared CLI/rendering policy | FR-001, FR-004, FR-005, FR-008, FR-019 | Foundational | 1.5 | CLI steward, UX steward | `scripts/specrew.ps1`, `scripts/specrew-where.ps1`, `scripts/internal/dashboard-renderer.ps1` | done | implementer | 1.5 | pass |
| I1-03 | Deliver rich-capable dashboard rendering | FR-004, FR-006, FR-007, FR-008, FR-009, FR-011, FR-012, FR-013, FR-014, FR-016 | US1 | 4.0 | UX steward, Product steward, Roadmap steward, Test steward | `scripts/internal/dashboard-renderer.ps1`, `tests/unit/feature-018-dashboard.tests.ps1`, `tests/integration/feature-018-rich-dashboard.ps1`, `tests/integration/fixtures/feature-018-dashboard/rich-capable-*` | done | implementer | 4.0 | pass |
| I1-04 | Preserve fallback truth and snapshot safety | FR-001, FR-004, FR-005, FR-007, FR-008, FR-009, FR-010, FR-014, FR-017, TG-004 | US2 | 3.5 | UX steward, Product steward, Reliability steward, Test steward | `scripts/internal/dashboard-renderer.ps1`, `extensions/specrew-speckit/scripts/*.ps1`, `.specify/extensions/specrew-speckit/scripts/*.ps1`, `tests/integration/fixtures/feature-018-dashboard/monochrome-*` | done | implementer | 3.5 | pass |
| I1-05 | Prove regression safety, docs, and performance | FR-015, FR-016, FR-017, FR-018, FR-019, FR-020 | US3 | 3.0 | Reliability steward, Documentation steward, Test steward | `tests/unit/*.ps1`, `tests/integration/*.ps1`, `docs/dashboard-guide.md`, `README.md`, `tests/manual/feature-017-dashboard-quickstart.md`, `specs/018-velocity-dashboard-visual-richness/quickstart.md` | done | implementer | 3.0 | pass |
| I1-06 | Replay validation and preserve explicit deferrals | FR-001, FR-002, FR-003, FR-015, FR-016, FR-017, FR-018, TG-004 | Polish | 1.5 | Reliability steward, Spec Steward | `specs/018-velocity-dashboard-visual-richness/iterations/001/quality/**`, `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | done | implementer | 1.5 | pass |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance |
| Capacity per Iteration | 20 | Repository capacity from `.specrew/iteration-config.yml` |
| Planned Effort | 14.5 | Grouped execution estimate for Iteration 001 |
| Size Calibration | S=0.25, M=0.5, L=1.0 | Converts the `tasks.md` S/M/L sizing into the story-point total above |
| Iteration Bounding | scope | Iteration closes only when the approved single-iteration scope is complete |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time` |
| Overcommit Threshold | 1.0 | No silent overcommit beyond the 20-point ceiling |
| Defer Strategy | manual | Any deferral must be named explicitly rather than hidden in task titles |
| Calibration Enabled | true | Retro should compare this grouped baseline against actual delivery |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- The work naturally splits into four safe lanes after the foundational policy lock: renderer-richness,
  fallback/artifact safety, fixture/test expansion, and docs/manual guidance.
- Shared-surface conflict risk is concentrated in `scripts/internal/dashboard-renderer.ps1` and the
  closeout scaffold scripts. That risk is handled by keeping T003-T005 serial before parallel story work.
- US1 and US2 may run in parallel once the shared option/rendering policy is stable, but both must preserve
  one renderer contract and one closeout-artifact contract.
- US3 and Polish stay downstream because they validate the combined behavior rather than creating new
  behavior in isolation.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| --- | --- | --- |
| Planning | 0.0 story_points | Planning artifacts are now scaffolded for the execution boundary |
| Discovery/Spikes | 0.5 story_points | Reserved only for bounded hardening clarification that emerges during T003-T005 |
| Implementation | 11.0 story_points | T001-T027 grouped execution work |
| Review | 1.5 story_points | Consumed by review-verdict-signoff, including bounded repair `R-018-V1` |
| Rework | 1.5 story_points | Reserved in the envelope for bounded review repairs without scope expansion |

## Phase 1 Quality Planning

**Phase Scope**: `feature-018-visual-richness-single-iteration-slice`  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: `feature-018-rich-dashboard-compatibility`

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `existing-dashboard-suite-pass` | tooling | `tests/integration/feature-017-dashboard-core.ps1` and `tests/unit/feature-017-dashboard.tests.ps1` | planned |
| `rich-mode-fixture-contract` | tooling | `tests/integration/feature-018-rich-dashboard.ps1` and rich expected-output fixtures | planned |
| `monochrome-fallback-contract` | tooling | `tests/integration/feature-018-rich-dashboard.ps1` and monochrome expected-output fixtures | planned |
| `artifact-persistence-contract` | manual-evidence | `specs/018-velocity-dashboard-visual-richness/iterations/001/quality/hardening-gate.md`, `quality-evidence.md`, and closeout-scaffold replay | planned |
| `flag-surface-contract` | manual-evidence | CLI help plus manual quickstart evidence for `--ASCII`, `--RecentCount`, and `--BarWidth` | planned |
| `render-budget-check` | tooling | `tests/integration/feature-018-render-budget.ps1` on the representative 16-feature fixture | planned |
| `fixture-encoding-consistency` | mechanical | `specs/018-velocity-dashboard-visual-richness/iterations/001/quality/mechanical-findings.json` plus UTF-8/LF fixture checks | planned |

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `Feature 018 iteration 001 pre-implementation readiness for rich rendering, fallback truthfulness, snapshot persistence, and regression-safe delivery`  
**Hardening Gate Artifact**: `specs/018-velocity-dashboard-visual-richness/iterations/001/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/018-velocity-dashboard-visual-richness/iterations/001/quality/trap-reapplication.md`

### Hardening Focus Areas

| Focus Area | Why It Matters | Planned Artifact / Evidence | Status |
| --- | --- | --- | --- |
| Terminal-capability precedence | Rich mode must enable only when the explicit precedence chain says it should | hardening gate + fallback fixtures + CLI help | required |
| Windows VT fallback truthfulness | Semantic emphasis must degrade cleanly when Windows ANSI support is absent | hardening gate + monochrome fixtures + manual quickstart | required |
| Render-budget preservation | The richer view only ships if NFR-001 remains intact | hardening gate + render-budget test + validation replay | required |
| Snapshot artifact integrity | Stored dashboards must strip ANSI while preserving readable Unicode | hardening gate + validator replay + closeout scaffold tests | required |
| Closeout rendering parity | Iteration-closeout and feature-closeout dashboard artifacts must stay truthful and immutable | hardening gate + scaffold replay + artifact notes | required |
| Documentation clarity | Operators must understand flags, fallback rules, and artifact semantics without source reading | hardening gate + docs/manual updates + quickstart checks | required |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Pre-implementation hardening review | strongest-available | strongest-available | `.squad/decisions.md` entries dated 2026-05-15 | Preserved through implementation and later referenced by `iterations/001/review.md` at review-verdict-signoff |

## Traceability Summary

- Full Iteration 001 scope remains in play: FR-001 through FR-020, all three user stories, and the five
  approved feature pillars.
- Grouped execution slices map cleanly to the detailed backlog in [`../../tasks.md`](../../tasks.md):
  I1-01 → T001-T002, I1-02 → T003-T005, I1-03 → T006-T013, I1-04 → T014-T020, I1-05 → T021-T027,
  I1-06 → T028-T030.
- The hardening gate records the reviewer-requested exact concern labels before implementation starts:
  `terminal-capability-decision-precedence`, `windows-vt-fallback-truthfulness`,
  `render-budget-stop-ship-evidence`, `ansi-stripping-with-unicode-preservation`, and
  `closeout-dashboard-artifact-rendering`.
- Review is now recorded in `review.md`; retro remains intentionally absent until separately authorized.

## Notes

- `tasks.md` remains the authoritative detailed backlog; this iteration plan groups that backlog into
  executable slices that can survive handoff without re-deriving dependencies.
- The execution scaffold deliberately uses iteration-scoped quality artifacts under
  `iterations/001/quality/` so `/speckit.specrew-speckit.before-implement` can validate a truthful
  pre-implementation boundary.
- The later review repair (`R-018-V1`) stayed inside the same five approved pillars and did not widen scope
  beyond the accepted implementation slice.

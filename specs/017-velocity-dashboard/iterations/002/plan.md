# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro-complete
**Capacity**: 16.0/20 story_points
**Started**: 2026-05-15
**Review Completed**: 2026-05-15
**Retro Completed**: 2026-05-15
**Planning Authority**: Iteration 002 executed from the feature-level `plan.md` carryover scope and
the detailed `tasks.md` breakdown for FR-019..FR-033 plus FR-042..FR-046; this artifact restores
the canonical per-iteration plan surface required by Specrew bookkeeping after implementation and
review completed.

## Scope Summary

| Scope Slice | Coverage | Planned Effort | Notes |
| --- | --- | --- | --- |
| Closeout integration | FR-019..FR-023 | 3.0 | Iteration-closeout hook, feature-closeout hook, immutability, and mirror parity |
| Documentation and discovery | FR-024..FR-030 | 3.0 | Help, onboarding, dashboard guide, roadmap guidance, FAQ, and routing examples |
| Validator and trap integration | FR-031 | 3.0 | Drift warnings, schema checks, grandfathering, and corpus carry-forward |
| Fixture and replay coverage | FR-032 | 3.0 | Healthy, sparse, malformed, no-roadmap, immutability, and replay-path tests |
| Production-uplift and compatibility | FR-033, FR-042..FR-046 | 2.0 | POC-to-production narrative plus preservation of the Iteration 001 renderer contract |
| Review-signoff truth repairs | R-V1, R-V2 | 2.0 | Branch-local shipped-status correction and planning-to-closeout day-span correction |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| I2-01 | Integrate dashboard generation into iteration and feature closeout scaffolds | FR-019..FR-023 | US3 | 3.0 | Governance steward | `extensions/specrew-speckit/scripts/**`, `.specify/extensions/specrew-speckit/scripts/**` | done | copilot | 3.0 | pass |
| I2-02 | Publish dashboard documentation, help, onboarding, and routing guidance | FR-024..FR-030 | US3 | 3.0 | Documentation steward | `README.md`, `docs/**`, `.github/copilot-instructions.md`, `scripts/specrew-where.ps1` | done | copilot | 3.0 | pass |
| I2-03 | Extend validator and corpus handling for dashboard drift and grandfathering | FR-031 | US2 | 3.0 | Validator steward | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specrew/quality/known-traps.md`, `specs/017-velocity-dashboard/quality/**` | done | copilot | 3.0 | pass |
| I2-04 | Prove behavior across repository fixtures and lifecycle replay paths | FR-032 | US2 | 3.0 | Test steward | `tests/integration/**`, `tests/unit/**`, `tests/integration/fixtures/feature-017-dashboard/**` | done | copilot | 3.0 | pass |
| I2-05 | Preserve the Iteration 001 renderer contract while documenting production uplift | FR-033, FR-042..FR-046 | US1/US3 | 2.0 | Product steward | `scripts/internal/dashboard-renderer.ps1`, `docs/**`, `specs/017-velocity-dashboard/**` | done | copilot | 2.0 | pass |
| I2-06 | Absorb accepted review-signoff repairs before retro-boundary | R-V1, R-V2 | US1/US2 | 2.0 | Reviewer + Implementer | `scripts/internal/dashboard-renderer.ps1`, `specs/017-velocity-dashboard/iterations/002/review.md`, `.squad/**` | done | copilot | 2.0 | pass |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in plan, state, and retro calibration |
| Capacity per Iteration | 20 | Repository capacity from `.specrew/iteration-config.yml` |
| Planned Effort | 16.0 | Clean baseline used by dashboard parsing and variance reporting |
| Planning Band | ~16-18 | Human-facing carryover estimate captured from Iteration 001 closeout/retro |
| Iteration Bounding | scope | Iteration closes when authorized scope is complete |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time` |
| Overcommit Threshold | 1.0 | No overcommit beyond capacity without explicit defer/replan |
| Defer Strategy | manual | Defer only by explicit planning/authorization rather than silent scope trimming |
| Calibration Enabled | true | Retro should preserve planned-vs-actual evidence |

## Notes

- Detailed task lineage remains in [`../../tasks.md`](../../tasks.md), especially T044-T082.
- Pre-implementation review authority remains in [`./pre-implementation-review.md`](./pre-implementation-review.md)
  and [`./quality/hardening-gate.md`](./quality/hardening-gate.md).
- This plan is deliberately lightweight because the feature-level plan and task ledger already carried
  the original execution detail; the retro-boundary repair here restores the canonical iteration
  artifact shape so dashboard and validator surfaces remain truthful.

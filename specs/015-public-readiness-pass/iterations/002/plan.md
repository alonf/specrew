# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 9.0/20 story_points
**Started**: 2026-05-13
**Completed**: implementation completed on 2026-05-13 (`T010`-`T016`)
**Hardening-Gate Sign-Off**: user sign-off recorded on 2026-05-13 for the Iteration 002 pre-implementation hardening gate
**Implementation Authorization**: user directive on 2026-05-13 for the bounded `T010`-`T016` scope only

## Scope Summary

Seven authorized scope items representing the remainder of Feature 015 public-readiness work:

| Scope Item | Requirement | Summary | Owner |
| --- | --- | --- | --- |
| 1 | FR-008 | `.specrew/config.yml` version bump to `0.14.0` as the authoritative active version source | Release steward |
| 2 | FR-009 | Top-level `CHANGELOG.md` with retroactive Features 001-014 entries (one-line summaries, known commit/merge refs) | Release steward |
| 3 | FR-010 | Annotated git tags `v0.13.0` (→ 21d9e7f) and `v0.14.0` (→ 3ff32d4) | Release steward |
| 4 | FR-012, FR-013 | Feature closeout authorization template Step 10: version bump / changelog / tag creation guidance across `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md` | Governance steward |
| 5 | FR-013 | Coordinator prompt/template updates for version-management discipline alignment (sub-item of Scope 4) | Governance steward |
| 6 | FR-014 | Versioning schema documentation: concise `README.md` summary and detailed `docs/versioning.md` policy (0.NN.0 feature-release, 0.NN.M hotfix) | Documentation steward |
| 7 | FR-016, FR-017 | Public-readiness drift detection via `Test-PublicReadinessSurfaces` in `validate-governance.ps1` (with fixtures, Pester tests); shipped-feature spec status reconciliation (specs/007, 009, 011, 012 Draft → Complete) | Governance steward, Spec steward |

## Tasks

| Task | Title | Scope Item | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ---------- | ----------- | ----- | ------ | ----- | -------------------------------- | ------ | ----- | ------ | ------- |
| T010 | `.specrew/config.yml` version bump to 0.14.0 | 1 | FR-008 | US2 | 0.5 | Release steward | `.specrew/config.yml` | done | Implementer | 0.5 | done |
| T011 | Create retroactive CHANGELOG.md for Features 001-014 | 2 | FR-009 | US2 | 1.5 | Release steward | `CHANGELOG.md` | done | Implementer | 1.5 | done |
| T012 | Create annotated git tags v0.13.0 and v0.14.0 | 3 | FR-010 | US2 | 0.5 | Release steward | (git tags) | done | Implementer | 0.5 | done |
| T013 | Add Feature Closeout Version Management to governance templates and coordinator prompts | 4, 5 | FR-012, FR-013 | US3 | 2.0 | Governance steward | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md` | done | Implementer | 2.0 | done |
| T014 | Document versioning schema: README summary + docs/versioning.md detailed policy | 6 | FR-014 | US2 | 1.5 | Documentation steward | `README.md`, `docs/versioning.md` | done | Implementer | 1.5 | done |
| T015 | Implement Test-PublicReadinessSurfaces and fixtures; verify version-truth alignment | 7 | FR-016 | US2 | 2.5 | Governance steward | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `tests/unit/fixtures/015-public-readiness-pass/`, `tests/unit/validate-governance.public-readiness.tests.ps1` | done | Implementer | 2.5 | done |
| T016 | Update shipped-feature specs (007, 009, 011, 012) status from Draft to Complete | 7 | FR-017 | US2 | 0.5 | Spec steward | `specs/007-user-facing-progress-handoff/spec.md`, `specs/009-project-path-resolution/spec.md`, `specs/011-specrew-start-conditional-pause/spec.md`, `specs/012-descriptive-id-handoffs/spec.md` | done | Spec Steward | 0.5 | done |

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

- Current roster snapshot: Release steward, Documentation steward, Governance steward, Spec steward
- Scope signals: Seven scope items covering version management (config.yml, CHANGELOG, tags), governance template updates (closeout workflow), versioning documentation, and public-readiness validation. Two natural workstreams: release-truth (T010-T012) and governance/validation (T013-T016).
- Task dependency graph: Version bump (T010) preceded CHANGELOG (T011) to establish baseline. Governance templates (T013) ran in parallel with docs (T014) and public-readiness work (T015). Spec status update (T016) completed after validation confidence was established.
- Workstream separability: Release baseline (T010-T012) completed independently of governance/validation work before the final implementation boundary was reconciled.
- Recommendation: Safe parallelism available across the seven scope items after foundational decisions (T010) lock the version baseline.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.0 story_points | Iteration 002 scope locked; no additional planning needed |
| Discovery/Spikes | 0.0 story_points | Scope is closed from authorization; no spike work planned |
| Implementation | 9.0 story_points | Sum of T010-T016 in the authorized Iteration 002 backlog |
| Review | 0.0 story_points | Review effort is carried inside the bounded seven-task plan rather than as a separate planning buffer |
| Rework | 0.0 story_points | No additional rework buffer is pre-allocated inside the planning boundary |

## Traceability Summary

- Requirement scope for this iteration: FR-008, FR-009, FR-010, FR-012, FR-013, FR-014, FR-016, FR-017
- Scope items represented: 7 scope items via 7 tasks (T010-T016)
- Deferred from Iteration 001: (none — Iteration 001 closed)
- Further deferrals: None; Iteration 002 represents all remaining authorized Feature 015 scope
- Overcommit guardrail: the Iteration 002 task set totals 9.0 story_points (0.45x capacity), well under the 20 story_point capacity ceiling

## Execution Split

- **Iteration 001 complete, closed on 2026-05-13**: `T001-T009` only
- **Iteration 002 authorized for execution on 2026-05-13**: `T010-T016`
- **Lifecycle boundary preserved**: all authorized Iteration 002 tasks (`T010`-`T016`) are now implemented; review and retro remain separate future boundaries

## Notes

- This plan covers the explicitly authorized Iteration 002 scope: seven scope items (FR-008, FR-009, FR-010, FR-012, FR-013, FR-014, FR-016, FR-017) mapped to seven tasks (T010-T016).
- The release/docs, governance/validator, and spec-alignment lanes all completed within the bounded `T010`-`T016` authorization.
- A fresh session restart will be required before future Squad runs can load the updated `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md` guidance.
- All authorized scope items are represented with clear FR-traceability and release-truth ownership.


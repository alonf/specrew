# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 10.0/20 story_points
**Started**: 2026-05-13
**Completed**: Authorized slice `T001-T009` completed on 2026-05-13; Feature 015 iteration 001 review boundary commit `6ca218f` accepted the slice and the retrospective is now complete on the current tree
**Hardening-Gate Sign-Off**: 2026-05-13 via current-session human authorization
**Implementation Authorization**: 2026-05-13 for T001-T009 only

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | The repository MUST provide a top-level `LICENSE` file containing the standard MIT license text with the copyright line `Copyright (c) 2026 Alon Fliess and contributors`. **Owner role**: Repository steward. **Delivery window**: Iteration 1. | — |
| FR-002 | The repository MUST provide a top-level `NOTICE.md` that credits Squad and Spec Kit as MIT-licensed upstream sources, preserves their required notice information, and clearly identifies the Specrew directories whose templates or scripts are derived from those upstream projects. **Owner role**: Repository steward. **Delivery window**: Iteration 1. | — |
| FR-003 | `README.md` MUST include a **Current State** section that states the repository is at version 0.14.0, frames Specrew as an alpha validated through dogfooding, and clearly states that multi-developer and multi-host support are not yet ready. **Owner role**: Documentation steward. **Delivery window**: Iteration 1. | — |
| FR-004 | `README.md` MUST include a **What's working** section that summarizes the shipped Specrew capabilities through Feature 014 in plain language for an outside reader. **Owner role**: Documentation steward. **Delivery window**: Iteration 1. | — |
| FR-005 | `README.md` MUST include a **What's NOT working yet** section that explicitly names the current roadmap deferrals, including multi-developer reconciliation, multi-host runtime, just-in-time brownfield cartography, and installable packaging. **Owner role**: Documentation steward. **Delivery window**: Iteration 1. | — |
| FR-006 | `README.md` MUST include both a **Recommended Lifecycle** section and a **PR-at-feature-close Workflow** section so an outside reader understands Specrew's current delivery phases, planning gates, and merge-at-close operating model. **Owner role**: Documentation steward. **Delivery window**: Iteration 1. | — |
| FR-007 | `README.md` MUST include **Roadmap**, **License**, and **Contributing** sections. The Contributing section MUST explicitly state that Specrew is still alpha-stage, welcomes reading, issues, and discussion, and is not yet accepting external pull requests until the operating model stabilizes. **Owner role**: Documentation steward. **Delivery window**: Iteration 1. | — |
| FR-011 | `specs/001-specrew-product/spec.md` MUST update its status from draft to `Active 0.14.0` and briefly explain that the product vision is now backed by 14 shipped implementing features. **Owner role**: Product spec steward. **Delivery window**: Iteration 1. | — |
| FR-015 | Planning and downstream execution artifacts for this feature MUST preserve the current authorization boundary: this feature is approved only through specification, Iteration 001 planning scaffold, and upstream-tracking push; hardening-gate sign-off and implementation start require later explicit human approval. **Owner role**: Planner and human reviewer. **Delivery window**: Iteration 1 planning boundary. | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Reconfirm the repaired branch name, two-iteration split, and approval boundary | FR-015 | Boundary | 0.25 | Planner | `specs/015-public-readiness-pass/spec.md`, `specs/015-public-readiness-pass/plan.md` | done | Planner | Updated the authoritative boundary text for the bounded `T001-T009` authorization and explicit `T010-T024` deferral. | pass |
| T002 | Scaffold Iteration 001 planning artifacts without review or retro placeholders | FR-015 | Boundary | 0.25 | Planner | `specs/015-public-readiness-pass/iterations/001/plan.md`, `specs/015-public-readiness-pass/iterations/001/state.md`, `specs/015-public-readiness-pass/iterations/001/drift-log.md`, `specs/015-public-readiness-pass/iterations/001/quality/hardening-gate.md` | done | Planner | Ran `extensions/specrew-speckit/scripts/scaffold-iteration-plan.ps1`; existing `iterations/001/plan.md` was preserved and no `review.md` or `retro.md` was created. | pass |
| T003 | Confirm `.specrew/config.yml` as the canonical version source for later release-truth work | FR-015 | Boundary | 0.50 | Release steward | `specs/015-public-readiness-pass/plan.md`, `specs/015-public-readiness-pass/contracts/public-readiness-warning-schema.md` | done | Planner | Reconciled the plan and public-readiness warning contract to treat `.specrew/config.yml` `specrew_version` as the authoritative version source for Iteration 002. | pass |
| T004 | Record the Iteration 001 versus Iteration 002 execution split in the iteration plan | FR-015 | Boundary | 0.50 | Planner | `specs/015-public-readiness-pass/iterations/001/plan.md` | done | Planner | Recorded the authorized Iteration 001 completion state and the explicit Iteration 002 deferral boundary. | pass |
| T005 | Create the MIT license text at the repository root | FR-001 | US1 | 1.00 | Repository steward | `LICENSE` | done | Implementer | Authored the repository MIT license with the required 2026 copyright line. | pass |
| T006 | Author top-level upstream attribution for Squad and Spec Kit | FR-002 | US1 | 1.50 | Repository steward | `NOTICE.md` | done | Implementer | Added root-level upstream attribution for Squad and Spec Kit, including the required derived directories. | pass |
| T007 | Rewrite README public-readiness sections for first-time observers | FR-003, FR-004, FR-005, FR-006, FR-007 | US1 | 4.00 | Documentation steward | `README.md` | done | Implementer | Rewrote the README around Current State, working scope, gaps, lifecycle, PR-at-feature-close, roadmap, license, and contributing guidance. | pass |
| T008 | Update the product spec status to `Active 0.14.0` | FR-011 | US1 | 0.50 | Product spec steward | `specs/001-specrew-product/spec.md` | done | Implementer | Promoted the product spec from Draft to Active 0.14.0 and added the shipped-feature note. | pass |
| T009 | Run first-time-reader review and markdown validation for Iteration 001 surfaces | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-011 | US1 | 1.50 | human reviewer | `LICENSE`, `NOTICE.md`, `README.md`, `specs/001-specrew-product/spec.md`, `specs/015-public-readiness-pass/quickstart.md` | done | Reviewer | Recorded first-time-reader, markdownlint, and governance-validation evidence in `specs/015-public-readiness-pass/quickstart.md`. | pass |

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
- Task dependency graph: Setup and foundational boundary work stayed serial; `T005`, `T006`, and `T008` were separable once the boundary locked; `T007` and `T009` followed sequentially.
- Workstream separability: The authorized slice allowed limited safe parallelism on independent landing-surface files only.
- Shared-surface conflict risk: README and quickstart remained the highest shared-surface risk, so those edits stayed serial.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: Keep Iteration 002 serial until later authorization lands; versioning, changelog, tags, and validator work all share the same release-truth surface.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1.00 story_points | Feature opening, clarify, plan, tasks, and Iteration 001 scaffold alignment |
| Discovery/Spikes | 0.00 story_points | Clarifications resolved the open planning questions; no spike work is planned |
| Implementation | 10.00 story_points | Sum of T001-T009 in the bounded Iteration 001 backlog |
| Review | 1.00 story_points | Human reviewer pass over landing surfaces and markdown validation evidence |
| Rework | 1.00 story_points | Small bounded buffer if the first-reader or markdown lane finds wording drift |

## Traceability Summary

- Requirement scope for this iteration: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-011, FR-015
- User stories represented in current scope: US1
- Deferred to Iteration 002: FR-008, FR-009, FR-010, FR-012, FR-013, FR-014, and FR-016
- Overcommit guardrail: the bounded Iteration 001 task set totals 10.0 story_points, which remains under the 20 story_point capacity ceiling.

## Execution Split

- **Iteration 001 authorized and completed in this slice**: `T001-T009` only
- **Iteration 002 still deferred**: `T010-T024`, including `.specrew/config.yml`, `CHANGELOG.md`, `docs/versioning.md`, release tags, `validate-governance.ps1` public-readiness warnings, and coordinator-governance extension work
- **Lifecycle boundary kept intact**: `review.md` records the accepted review boundary in Feature 015 iteration 001 review boundary commit `6ca218f`, `retro.md` now records the completed retrospective boundary on the current tree, and iteration closeout plus Iteration 002 remain separately authorized

## Notes

- This plan is intentionally limited to the Iteration 001 public-landing-surface slice; versioning, changelog, tags, validator warnings, and closeout-governance extension work stay deferred to Iteration 002.
- Hardening-gate sign-off and implementation authorization are recorded for Iteration 001 only; keep Iteration 002 deferred until later explicit human approval.
- `Status` moved to `reviewing` once `review.md` recorded the accepted independent review boundary on 2026-05-13, and now moves to `retro` because `retro.md` truthfully records the completed retrospective boundary while keeping iteration closeout blocked pending separate human authorization.
- The current validator treats committed `review.md` and `retro.md` files as evidence that later lifecycle phases have started, so this plan must keep lifecycle narration synchronized with the committed artifact boundary: retrospective is complete, iteration closeout is not.
- If the scope changes later, update the task table, execution split, and deferral note in the same planning boundary.

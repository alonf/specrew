# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 10.0/20 story_points
**Started**: 2026-05-13
**Completed**: (none)

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
| T001 | Reconfirm the repaired branch name, two-iteration split, and approval boundary | FR-015 | Boundary | 0.25 | Planner | `specs/015-public-readiness-pass/spec.md`, `specs/015-public-readiness-pass/plan.md` | planned | Planner | — | pending |
| T002 | Scaffold Iteration 001 planning artifacts without review or retro placeholders | FR-015 | Boundary | 0.25 | Planner | `specs/015-public-readiness-pass/iterations/001/plan.md`, `specs/015-public-readiness-pass/iterations/001/state.md`, `specs/015-public-readiness-pass/iterations/001/drift-log.md`, `specs/015-public-readiness-pass/iterations/001/quality/hardening-gate.md` | planned | Planner | — | pending |
| T003 | Confirm `.specrew/config.yml` as the canonical version source for later release-truth work | FR-015 | Boundary | 0.50 | Release steward | `specs/015-public-readiness-pass/plan.md`, `specs/015-public-readiness-pass/contracts/public-readiness-warning-schema.md` | planned | Planner | — | pending |
| T004 | Record the Iteration 001 versus Iteration 002 execution split in the iteration plan | FR-015 | Boundary | 0.50 | Planner | `specs/015-public-readiness-pass/iterations/001/plan.md` | planned | Planner | — | pending |
| T005 | Create the MIT license text at the repository root | FR-001 | US1 | 1.00 | Repository steward | `LICENSE` | planned | Implementer | — | pending |
| T006 | Author top-level upstream attribution for Squad and Spec Kit | FR-002 | US1 | 1.50 | Repository steward | `NOTICE.md` | planned | Implementer | — | pending |
| T007 | Rewrite README public-readiness sections for first-time observers | FR-003, FR-004, FR-005, FR-006, FR-007 | US1 | 4.00 | Documentation steward | `README.md` | planned | Implementer | — | pending |
| T008 | Update the product spec status to `Active 0.14.0` | FR-011 | US1 | 0.50 | Product spec steward | `specs/001-specrew-product/spec.md` | planned | Implementer | — | pending |
| T009 | Run first-time-reader review and markdown validation for Iteration 001 surfaces | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-011 | US1 | 1.50 | human reviewer | `LICENSE`, `NOTICE.md`, `README.md`, `specs/001-specrew-product/spec.md`, `specs/015-public-readiness-pass/quickstart.md` | planned | Reviewer | — | pending |

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

## Notes

- This plan is intentionally limited to the Iteration 001 public-landing-surface slice; versioning, changelog, tags, validator warnings, and closeout-governance extension work stay deferred to Iteration 002.
- Keep `Status: planning` until the pre-implementation hardening gate is signed off and implementation authorization is recorded.
- The current validator treats committed `review.md` and `retro.md` files as evidence that later lifecycle phases have started, so those artifacts must remain uncreated at planning time.
- If the iteration scope changes later, update the task table, phase baseline, and deferral note in the same planning boundary.

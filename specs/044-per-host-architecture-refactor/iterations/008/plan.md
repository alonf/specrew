# Iteration Plan: 008

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 10/20 story_points
**Started**: 2026-05-25
**Completed**: 2026-05-25

> Fifth LIVE-TRACKED iteration of F-044 (iter-004 + iter-005 + iter-006 + iter-007 + iter-008). Plan written before code; actuals filled at task close.

## Scope Summary

User-flagged docs gap observed at v0.27.0 release-readiness review: README + getting-started + user-guide all reference the closeout boundaries by name but never explain WHAT they produce, WHY they matter, or WHEN the user must act. Adjacent gap: no concrete worked example of a full feature lifecycle anywhere in the docs.

iter-008 closes both gaps:

1. **Closeout documentation** — explain iteration-closeout + feature-closeout as the events that produce final artifacts and gate the next iteration / next feature.
2. **Two-iteration calculator walkthrough** — narrative-only worked example showing iter-1 (basic four ops + memory) and iter-2 (add sin, cos, atan, sqrt) so a reader can follow the full lifecycle once before trying it themselves.

The user also flagged a deeper concern: when restarting Specrew + asking for a "new feature", does the user know whether older iterations/features are still open? Is multi-feature switching part of the methodology? Are never-closed features allowed? Those questions are scoped to a separate Proposal 109 candidate authored on main (per the "proposals always commit to main" rule) — explicitly out of iter-008 scope.

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-012 | Documentation updated for shipped state | US5 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | README — add closeout to "What's working today" + brief "How a feature finishes" subsection near the lifecycle bullet | FR-012 | US5 | 1 | Implementer | README.md | done | claude | 1 | pass |
| T002 | docs/getting-started.md — add Step 5 "Close the iteration (and the feature)" with explicit verdict shapes | FR-012 | US5 | 1 | Implementer | docs/getting-started.md | done | claude | 1 | pass |
| T003 | docs/user-guide.md — new major section "Closing iterations + features" explaining artifacts produced + why they matter + verdict shapes + transition to next iter/feature | FR-012 | US5 | 2 | Implementer | docs/user-guide.md | done | claude | 2 | pass |
| T004 | docs/user-guide.md — new "Walkthrough: a two-iteration calculator" section (narrative-only). iter-1: `+ - * /` + MR/MC/M+/M- memory. iter-2: add sin, cos, atan, sqrt. Show commands + boundary handoffs + artifacts produced at each major step | FR-012 | US5 | 2 | Implementer | docs/user-guide.md | done | claude | 2 | pass |
| T005 | Markdown lint sweep on touched docs + iter-008 artifacts + full-repo validator run + commit + push to PR #844 | FR-012 | US5 | 1 | Implementer | various | done | claude | 1 | pass |
| T006 | Restore three-section handoff format prominence in coordinator-governance.md — replace one-line directive in 14A with full template + welcoming-tone mandate; mirror to .specify/ deployed copy. **REGRESSION FIX surfaced post-T005 by user manual-test feedback** | FR-012 | US5 | 1.5 | Implementer | extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md; .specify/.../specrew-governance.md | done | claude | 1.5 | pass |
| T007 | Add `### Boundary handoff format` subsection to all 5 agent charters (spec-steward, planner, reviewer, retro-facilitator, implementer) explicitly mandating the three-section shape. Previously only Implementer mentioned it; the other 4 never did. Mirror all 5 to .specify/ deployed copies | FR-012 | US5 | 1 | Implementer | extensions/.../agents/*/charter.md; .specify/.../agents/*/charter.md | done | claude | 1 | pass |
| T008 | Add "What you'll see at every boundary" section to docs/user-guide.md so users know what good UX looks like + how to re-prompt when they see a regression | FR-012 | US5 | 0.5 | Implementer | docs/user-guide.md | done | claude | 0.5 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | Project default. |
| Iteration Bounding | scope | 8 tasks bounded by user-flagged docs gap + walkthrough scope + handoff-format regression fix. |
| Time Limit (hours) | n/a | |
| Overcommit Threshold | 1.0 | 10/20 = 50% — under threshold. |
| Defer Strategy | manual | If T004 walkthrough exposes a gap that demands code work, surface for re-planning. |
| Calibration Enabled | true | Fifth live-tracked iteration. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- T001 + T002 + T003 — sequential within the same docs surface, but no cross-file dependencies (different files).
- T004 — extends user-guide.md added by T003; serial after T003.
- T005 — final gate; runs last.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.5 | This plan + reading current docs structure. |
| Discovery/Spikes | 0 | No spike needed; docs scope is clear from user message. |
| Implementation | 5.5 | T001 + T002 + T003 + T004. |
| Review | 0.5 | Markdownlint + validator + visual review of the narrative. |
| Rework | 0.5 | Buffer if walkthrough requires example-output adjustment. |

## Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Docs additions | standard | Markdownlint + validator + visual review | n/a | iter-008's empirical test boundary is "user can read closeout section + walkthrough and understand the full lifecycle without other context". |

## Traceability Summary

- Task coverage: 5 tasks for 2 user-surfaced docs gaps (closeout explanation + worked example).
- Traceability check: PASS at plan-boundary.
- Overcommit guardrail: 7/20 = 35% capacity. Healthy.

## Notes

- **Why this is iter-008 of F-044, not a separate feature**: docs-readiness for the v0.27.0 release is part of F-044's FR-012 ("Documentation updated for shipped state"). Adding closeout-documentation post-hoc keeps the v0.27.0 release narrative coherent. User confirmed scope target as iter-008 on this branch (joins PR #844) in the scope question.
- **Out of scope** (Proposal 109 candidate, separate commits to main): open-feature awareness, multi-feature switching discipline, long-running/never-closed feature methodology. Authored separately per "proposals always commit to main" rule.
- **No new functional requirements**: iter-008 is documentation work against existing FR-012. No new tests required (the validation IS markdownlint + validator + user-facing reading test).

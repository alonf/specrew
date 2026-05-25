# Iteration 008 Drift Log

**Feature**: F-044 | **Iteration**: 008 — Closeout Documentation + 2-Iteration Calculator Walkthrough + Three-Section Handoff Format Regression Fix (LIVE-TRACKED)

## Drift #1 — Mid-iteration scope expansion: three-section handoff format regression fix

- **Planned (iter-008 v1)**: 5 tasks at 7 SP — closeout docs + calculator walkthrough.
- **Surfaced mid-iteration**: User manual-test feedback flagged the three-section handoff format ("What I did / Why I stopped / What I need from you") was no longer being applied consistently. User exact phrasing: "This is a fundementual part of the methodology and flow. I do not see that anymore... I really want this to be back in this release."
- **Investigation**: The format directive existed as a single bullet under coordinator-governance rule 14A, and only the Implementer charter referenced it (and only incidentally via Proposal 082 commit-discipline mentions). The other 4 agent charters (Spec Steward, Planner, Reviewer, Retro Facilitator) made no mention of the format at all. The canonical handoff template at `specs/001-specrew-product/contracts/coordinator-handoff-template.md` was Specrew-spec-only, never deployed to downstream projects.
- **Resolution**: Expanded iter-008 scope by 3 tasks (T006, T007, T008) and 3 SP, taking total to 10/20 SP. Restored prominence via:
  1. Full canonical template in coordinator-governance.md 14A (was a one-line bullet)
  2. New `### Boundary handoff format` subsection in ALL 5 agent charters (was 0 of 5; now 5 of 5)
  3. New docs/user-guide.md "What you'll see at every boundary" section so users know what good UX looks like + how to re-prompt regressions
- **Why this is in-scope, not new iteration**: Tightly coupled to iter-008's existing closeout-documentation work. The walkthrough I wrote in T004 already implicitly demonstrates three-section handoffs at every boundary — fixing the format propagation aligns canonical templates with what the walkthrough promises. Splitting into a separate iteration would have created two PRs that need to land together.
- **Calibration data point**: This is the second iteration in F-044 where mid-iteration user feedback expanded scope (iter-006 was the first, expanding to canonicalize Antigravity's patches). Pattern: when the user surfaces a methodology-fundamental regression during a docs/UX iteration, expanding scope is correct as long as spare capacity exists.

## Drift #2 — `.specify/` mirror discipline reinforced

- **Planned (T006 + T007)**: Update canonical templates in `extensions/.../squad-templates/`.
- **Realized**: Specrew's own self-dogfood `.specify/` directory mirrors the canonical templates. Both copies are git-tracked. Without mirroring, Specrew's own next `specrew start` would deploy the OLD templates, defeating the regression fix.
- **Resolution**: Mirrored all 6 template edits (1 coordinator-governance + 5 charters) to `.specify/extensions/.../`. This is the same pattern iter-007 reinforced for the Linux-portability fix; should eventually be automated by a `bin/sync-specify-mirror.ps1` script (future small-fix candidate).
- **Why not iter-008 scope**: Adding a sync script is its own slice (~2 SP). Mirroring manually for iter-008 is correct; deferring the automation captures the recurring-cost signal.

## Surfaced-but-deferred (recorded for traceability)

- **Proposal 109 candidate** — open-feature awareness + multi-feature switching discipline + long-running/never-closed feature methodology. User-raised in same message; user-scoped as "draft proposals now (separate commits to main)" per the scope question. Authored as separate commit to main after iter-008's branch commit + push.
- **Three-section handoff format validator-rule check**: the validator already parses `What I just did / Why I stopped / What I need from you` shape (per `shared-governance.ps1:2479`), but doesn't enforce it as a hard rule yet. Promoting it from parse-detect to enforcement is a methodology-evolution decision — out of iter-008 scope.

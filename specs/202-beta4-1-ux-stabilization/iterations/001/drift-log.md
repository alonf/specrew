# Drift Log: Iteration 001

**Schema**: v2

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 2
**Resolution rate**: 100% (2/2 resolved)
**Specification drift**: 1 (spec-updated at design-analysis)

## Events

### DRIFT-001 — FR-018 used the branch as a reconciliation source; the branch is not the feature (resolved)

- **Observed**: 2026-10-13, design-analysis co-design (DA-5). As approved at specify, FR-018 said a stale pointer is reconciled "from the branch and the in-flight work". The maintainer corrected this: this worktree ran feature 199 on branch `201-first-run-experience`, so the branch name is evidence of nothing.
- **Requirement**: FR-018, and US4 scenario 2 (spec.md).
- **Resolution**: spec-updated, by human decision at design-analysis. The precedence is now (1) the in-flight controller or pending crossing, (2) the pointer if written for the current branch, (3) the branch name as a hint only, always disclosing which source decided. US4 scenario 2 was updated to match. The data-storage lens binding `pointer-branch-guard: stale-on-branch-mismatch-reconcile-disclose` still holds.
- **Class closure**: NONE. This is a requirement correction, not a code defect; the resolver test for SC-006 pins the precedence order, including the 199-on-201 case.

<!--
  Every new ### DRIFT-... event includes:

  - **Class closure**: the executable mechanism that makes the next instance impossible or loud

  If the change fixes only this instance, write NONE — <why class closure is not in scope>.
  A bare Resolution: FIXED is not class closure.
-->

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
### DRIFT-002 — the design-analysis gate disclosed its required format one layer per refusal (observation)

- **Observed**: 2026-10-13, plan sync for iteration 001. Three consecutive refusals each named a different layer of the required design-analysis format. The first named missing Alternatives, Crew Recommendation, Human Decision fields and a detectable flow. The second named the Simplest, Reasonable and By-the-book labels. The third named per-option fields (Architectural pattern, Quality features considered, Effort estimate, Reversibility cost, a Mermaid diagram). Each refusal was accurate, but none listed the complete contract, so the agent spent three repair cycles. No human turn was consumed.
- **Requirement**: adjacent to FR-020 (B4F-102: a refusal names the producing step). The producing step exists (`New-SpecrewDesignAnalysisArtifact`, design-analysis-gate.ps1 ~950), and its scaffold would have carried the full format. The refusal never named it.
- **Resolution**: the content was restructured to the format with no change to any agreed decision. T013 (FR-020) is extended in scope to cover this case: the plan-gate refusal names the scaffold step and reports every missing field in one pass.
- **Class closure**: T013's fixture asserts that a design-analysis missing several layers gets one refusal listing all of them, together with the scaffold step.

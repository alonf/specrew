# Drift Log: Iteration 002

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

**Total drift events**: 3
**Resolution rate**: 100% (3/3 resolved for this feature; DRIFT-001 to DRIFT-003 class closure open)
**Specification drift**: None detected

## Events

### DRIFT-001 — the quality-profile resolver read the stack as Node plus a browser SPA again (observation, recurrence)

- **Observed**: 2026-11-13, before-plan for iteration 002. `resolve-quality-profile.ps1` returned
  `quality-profile.custom-composition.v1` with stack signals `node-rest-with-postgres` and `react-spa-public`, and the
  plan scaffold called the scope "frontend-oriented".
- **Real stack**: PowerShell 7 scripts, lens markdown, the spec template and tests.
- **Resolution**: the plan states the real stack; the profile's required dimensions (code quality, design quality,
  verification confidence, maintainability) still apply.
- **Class closure**: NONE — the resolver is outside 205's scope. Recurrence of iteration 001's DRIFT-001 and feature
  203's plan-verdict finding.

### DRIFT-002 — the iteration plan scaffold rejects every requirement of this spec when given a scope (finding)

- **Observed**: 2026-11-13. `scaffold-iteration-plan.ps1 -RequirementScope FR-022,FR-024` refused with
  `Requirement(s) not found in spec: FR-022,FR-024`, although both are in `spec.md`'s Functional Requirements. The same
  script with no scope listed them. The plan was scaffolded without a scope and its scope written by hand, as in
  iteration 001.
- **Class closure**: NONE — the scaffold is part of the deployed extension. Candidate for feature 203's hand-over.

### DRIFT-003 — after a closed iteration, the clarify sync opens no approval point (finding, handed over)

- **Observed**: 2026-11-13. Recorded first as DRIFT-205-INTAKE-005 (feature-level intake drift log), before this
  iteration's folder existed. The clarify sync for Amendment A1 recorded its boundary but opened no crossing, so the
  amendment reaches planning with no approval of its own.
- **Resolution**: the maintainer approves A1 at this iteration's plan boundary.
- **Class closure**: NONE — the sync is feature 203's area. Handed over as H-015.

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

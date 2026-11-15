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
**Resolution rate**: 100% (3/3 resolved)
**Specification drift**: FR-015 and FR-016 corrected by the design decision (DRIFT-206-I002-003)

## Events

### DRIFT-206-I002-001 — bug item 13's fifth sighting, rerun under the standing exception

- **Observed**: 2026-11-15. Specrew CI run 43709472794 attempt 1 on `ce604236` (records only), job 132798404429
  "Deterministic gate": `tests/continuous-co-review/unit/co-review-service.Tests.ps1:129`, "Expected $null or empty
  ... but got System.Diagnostics.Process (pwsh)", 1 of 131, the only failure; the Contract lane was skipped.
- **Resolution**: rerun once without asking under the maintainer's standing exception: attempt 2 green, every job run.
  Recorded in bug list item 13.
- **Class closure**: NONE — the test and its code are feature 203's (HO-206-8); this sighting goes into iteration
  002's hand-over to 203.

### DRIFT-206-I002-002 — the plan scaffold rejects any requirement scope (recurrence of 205's DRIFT-002)

- **Observed**: 2026-11-15. `scaffold-iteration-plan.ps1 -RequirementScope FR-015,FR-016` and a scope of eleven
  requirements, FR-003 among them, all refused with "Requirement(s) not found in spec". With no scope it scaffolds.
  The scope was written by hand, as feature 205 did.
- **Also**: the iteration artifact scaffold wrote a drift log with no trailing newline and hardening rows whose
  placeholders fail markdownlint (MD047, MD038), and an Overall Verdict of `blocked` that the validator refuses once
  the rows are filled. Each was corrected in the iteration 002 records.
- **Class closure**: NONE — the scaffolds are part of the deployed extension. For iteration 002's hand-over to 203,
  beside 205's H-015 class.

### DRIFT-206-I002-003 — FR-015 and FR-016 corrected by the design decision (spec-updated)

- **What**: the maintainer chose Option B (2026-11-15). Under D1-a, FR-015 covers a task deferred by a recorded
  decision only, and feature 203's T014 (scheduled after sign-off by the plan) stays with proposal 206. Under D2-a,
  FR-016 accepts the record-before-verdict state with a warning where `start-context.json` is absent (CI cannot see it:
  it is ignored by git). SC-009 gains that case.
- **Resolution**: spec-updated in `fd032d72`, before any implementation.
- **Class closure**: NONE — a design decision, not a defect.

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

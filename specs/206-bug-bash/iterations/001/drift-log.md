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

**Total drift events**: 1
**Resolution rate**: 0% (0/1 resolved; open until T007 lands)
**Specification drift**: None detected (process drift only)

## Events

### DRIFT-206-I001-001 — the OVERRIDE 5 revert, pushed alone, turned Specrew CI red on two iterations

- **Recorded**: 2026-11-11, at the maintainer's instruction.
- **Run**: Specrew CI run 42918626688 on `a3778f1a` (the revert of OVERRIDE 5, pushed alone by the
  maintainer's choice of "two plain pushes, no history rewrite"). Lint failed; the Deterministic gate and
  Contract lane were skipped. Test and Cross-Platform Validation were green.
- **Trigger**: the revert touched `.specrew/iteration-config.yml`, one of the validator's global-state paths,
  relative to the push base `435332da`. So `-ChangedOnly` fell back to the whole repository
  (`global-state-changed`, 159 iterations).
- **Failures, and what fixes each**:
  - `198-beta2-hardening/011`: "Complete iterations require review.md overall verdict 'accepted' (found
    'needs-rework')". The nightly's existing failure; fixed by T007 (marked abandoned by the maintainer's
    ruling).
  - `206-bug-bash/001`: "plan.md Capacity total '22' does not match iteration-config capacity_per_iteration
    '20'" (Capacity line and Effort Model). At `a3778f1a` the plan still read 21.75/22; fixed by `99eb5132`
    (20/20, T016 and T017 deferred to iteration 002), which is in the second push.
- **Process miss**: the revert was not validated on its own before it was pushed. The local runs validated
  the two commits together (and changed-only against `origin/main`, not against the push base CI uses), so
  the 206/001 failure was not seen. The maintainer had expected 198/011 only.
- **Class closure**: NONE — no executable guard is added in this feature; the working rule from here on is to
  validate each pushed head alone, changed-only against the push base CI will use (`SPECREW_SCOPE_BASE_REF`
  set to the previous pushed commit), before every push.

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

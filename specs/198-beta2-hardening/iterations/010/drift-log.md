# Drift Log: Iteration 010

**Schema**: v1

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

**Total drift events**: 0
**Resolution rate**: 100% (0/0 resolved)
**Specification drift**: None detected

## Events

No specification drift detected during Iteration 010 execution to date.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

### DRIFT-198-I010-001 — the effort model cannot express a round-bounded iteration

- **Status**: open; recorded at the plan boundary, not worked around
- **Severity**: minor schema gap with a planning-honesty consequence
- **Type**: effort-model vocabulary
- **Observed evidence**: Iteration 009's single most transferable lesson is that
  review-correction work must be bounded by ROUNDS or BUDGET, never by scope — "the approved
  finding cluster is fixed" does not bound anything when each fix reveals the next defect
  (009 delivered ~70 SP against a 20 cap across eight rounds). Encoding that in this plan
  fails: `validate-governance.ps1` requires the plan's `Iteration Bounding` to match
  `.specrew/iteration-config.yml`, and that file offers only `scope` or `time`. Setting
  `rounds` produced `plan.md Effort Model 'Iteration Bounding' value '**rounds**' does not
  match iteration-config 'scope'`.
- **Consequence**: the Effort Model line for Iteration 010 says `scope`, which is not what
  bounds this iteration. The real bound is the 3-round cap in the plan's termination rule.
  A reader trusting the structured field would draw the wrong conclusion, so the plan says
  so explicitly in `## Notes`.
- **Relation**: the fifth instance of the same meta-pattern in this feature — the schema
  cannot express the honest disposition. See DRIFT-198-I009-021, -034, -044 (the
  disposition-vocabulary cluster in Iteration 012 finality scope) and -020. Candidate for
  that same cluster rather than a separate fix.
- **Required correction (deferred)**: add `rounds` (and `budget`) to the supported
  `iteration_bounding` vocabulary, with the round cap as a first-class configured value the
  validator can check against the certification section.

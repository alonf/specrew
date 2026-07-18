# Drift Log: Iteration 008

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

**Total drift events**: 1
**Resolution rate**: 0% (0/1 resolved)
**Specification drift**: None detected

## Events

### DRIFT-198-I008-001 — Pending crossing cites stale pre-closeout identity

- **Status**: deferred; manually contained
- **Severity**: major governance identity defect
- **Type**: authority-binding drift, not specification drift
- **Requirements**: FR-041, FR-042, FR-044, FR-045, NFR-007
- **Observed evidence**: the generated pending `iteration-closeout -> plan` narrative cited commit `744e77d8`
  and tree `542c54f0`, while the actual Iteration 007 closeout commit is
  `ec2287c0b950ceb78522f3b5aae8dd94d4710a88`.
- **Human disposition**: the planning verdict explicitly binds only to `ec2287c0`; the stale citation carries
  no authority.
- **Immediate containment**: Iteration 008 planning state and plan record the exact human binding. No later
  boundary may rely on the stale pending record.
- **Priced correction**: optional T068, 0.75 SP, would narrowly rebind a pending crossing to the actual closeout
  commit/tree with paired current/stale tests. It is not selected by the planning verdict and must not expand
  into a matcher redesign.

### Resolution Strategies

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- The defect is visible even though execution has not started because it affected the authority offered to the
  planning boundary.
- The official scaffold's decorated-requirement parser limitation is recorded in plan.md as a planning-tool
  limitation; it did not create authority or implementation drift.

# Drift Log: Iteration 001

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
**Specification drift**: 1 detected (capacity model)

## Events

### D-001 — Capacity-model drift: tasks decompose to 139 SP vs spec 45–65 envelope (OPEN)

**Detected**: 2026-05-31 at before-implement re-verification (reviewer-standard capacity check).

**Drift**: The spec capacity model (Governance Alignment + TG-003 + TG-005) approves ~45–65 SP total across 4 iterations with per-iteration caps (Iter 1 ≤20, Iter 2 12–18, Iter 3 10–15, Iter 4 8–12). The tasks.md per-task `[effort: N SP]` markup sums to materially more, and every iteration breaches its cap:

- Iteration 1: 28 SP actual vs ≤20 cap (summary asserts 18)
- Iteration 2: 54 SP actual vs 12–18 cap (summary asserts 18)
- Iteration 3: 29 SP actual vs 10–15 cap (summary asserts 14)
- Iteration 4: 28 SP actual vs 8–12 cap (summary asserts 12)
- Feature total: 139 SP actual vs 62 stated vs 45–65 approved envelope

**Root cause**: the per-task SP markup added during the 48→97 task expansion (commit `3da2b23b`) was never reconciled with the "Effort Verification & SP Allocation" summary table, which retained the original 62 SP estimate. All four iteration "✓" marks are arithmetically false against the documented verification method (line 310: "Reviewers can compute iteration totals by summing effort values").

**Why it blocks**: TG-005 makes Iteration 1 ≤20 SP a hard requirement and the iteration acts as a dependency gate; the systemic 2.2× envelope breach means the approved spec scope and the executable plan disagree about the size of the work.

**Resolution**: human-decision (escalated to Alon). Candidate strategies: re-slice into more ≤20 SP iterations with spec TG-003 + envelope reconciliation ("split, don't raise"); de-scope tasks to fit 45–65; or honest per-task re-estimation if the 97-task decomposition over-fragmented. Pending architect decision; hardening-gate population paused until scope is settled.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

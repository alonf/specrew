# Drift Log: Iteration 003

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
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: 1 resolved (FR-025 wording)

## Events

### D-197-I003-001 — FR-025 reworded from "every increment" to current-state diff_hash freshness

- **Detected**: 2026-06-20, during before-implement design pressure-test.
- **Drift**: The initial FR-025 wording required the gate floor to prove "every
  implement increment carries passing or escalated evidence," implying per-increment
  git-history coverage. Design review found this over-engineered: because the
  co-review baseline advances only on a pass, a single current-state freshness check
  (recompute `diff_hash` from the last passing run's `baseline_ref` to the working
  tree) transitively proves every prior increment without git-history archaeology.
- **Citation**: FR-025, FR-027, SC-019, SC-020.
- **Resolution strategy**: spec-updated.
- **Resolution**: FR-025 reworded to the diff_hash/baseline-advances-on-pass
  semantics; `tasks.md` and `iterations/003/plan.md` T058/T061 updated; the separate
  checkpoint ledger was dropped in favor of reusing `.specrew/review/inline`
  evidence. Per-increment live review remains Phase B (Iteration 004) scope, so the
  always-on intent is unchanged.
- **State**: resolved.

### Resolution Strategies (Available)

The following resolution strategies remain available if further drift is detected:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded at before-implement so drift can be logged immediately
  when detected during Iteration 003 (Phase A) execution.

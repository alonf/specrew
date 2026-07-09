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
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: None detected (the recorded event is a
reviewer-side observation refuted against the committed tree)

## Events

### DRIFT-198-I001-001 — co-review mode-change finding refuted against the committed tree (resolved: human-decision pending ack)

- **Reported**: co-review run `20260709T224852258-bd274a8d` (2 blocking
  findings): "the diff changes install.sh and every bin/specrew* shell
  wrapper from mode 100755 to 100644".
- **Verification against the committed tree (2026-07-10)**:
  `git ls-tree HEAD` shows `100755` for `install.sh`, `bin/specrew`,
  `bin/specrew-init`, `bin/specrew-review`, `bin/specrew-start`,
  `bin/specrew-team`, `bin/specrew-update` — byte-identical blobs AND
  identical modes vs `origin/main`; `git diff origin/main...HEAD --summary`
  contains zero mode-change lines; `core.filemode=false` on this Windows
  checkout (mode bits never staged from the filesystem).
- **Classification**: reviewer-side materialization artifact — the
  isolated review worktree is materialized on Windows, where checkout
  does not reproduce executable bits; a change-set that compares the
  materialized filesystem against tree metadata fabricates
  `100755 -> 100644` rows. The committed tree ships the executable bits
  intact (requirement citation: FR-017's frozen-tree materialization and
  the FR-012 reviewer-can-still-see-it discipline are the iteration-003
  owners of honest worktree materialization; this event is field evidence
  for that work).
- **Resolution**: no tree change required or made (nothing to revert —
  the claimed regression does not exist in the committed tree). Evidence
  recorded here + surfaced to the maintainer at the material-work stop
  for the T096 human ack. Carried as a field input to iteration 003
  (materialization must preserve/compare modes tree-to-tree, not
  fs-to-tree, so honest reviewers stop seeing phantom mode diffs).

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

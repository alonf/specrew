# Drift Log: Iteration 002

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
**Resolution rate**: deferred (0/1 resolved; 1 deferred to iteration 003)
**Specification drift**: 1 deferred (D-002 SessionEnd hook wiring)

## Events

### D-002 — SessionEndHandoverManager built + tested but not yet hook-registered

**Requirement**: FR-009 (SessionEnd handover writing wired through the shipped hook path).

**Drift**: SessionEndHandoverManager (write-only handover) and HandoverStore (read) are built,
tested, and round-trip correctly (SC-003), but the manager is **not yet registered** to fire on a
SessionEnd hook event - the F-171 dispatcher does not dispatch SessionEnd today. So on a live
session-end the handover would not auto-write; FR-009's "wired through the hook path" exceeds the
shipped wiring.

**Resolution**: deferred to iteration 003 (the deploy/wiring slice, grouped with the iteration-001
D-001 downstream deploy). Approved canonical defer entry `defer-f174-i002-sessionend-wiring` in
`.squad\decisions.md`.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

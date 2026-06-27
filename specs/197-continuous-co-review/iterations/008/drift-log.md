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
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: One authorized dogfood repair is recorded: the review-signoff hard gate is default-on in 197-owned wiring and Specrew self-review includes the co-review runtime under test.

## Events

### D-197-I008-001 - Dogfood hard-gate repair after co-review evidence gap

**Status**: resolved
**Detected by**: live co-review `codex-hard-gate-20260627`
**Authorized by**: maintainer instruction on 2026-06-27 to make the co-review mechanism robust after the AISharedMemoryMCP host-switch dogfood failure

**Drift**: The implementation changed the review-signoff gate from an opt-in configuration key to a default-on backstop and changed the worktree reviewer visibility policy for Specrew self-review. Iteration 008 design previously treated the signoff evidence gate as surviving unchanged and the strip set as downstream methodology machinery; dogfooding proved those assumptions insufficient for the host-switch/compaction failure mode.

**Resolution**: Recorded T083/T084 in `specs/197-continuous-co-review/tasks.md`, added the dogfood repair decisions to `specs/197-continuous-co-review/iterations/008/design-analysis.md`, kept the implementation inside `scripts/internal/continuous-co-review/`, and removed the unapproved waiver parser change from protected `shared-governance.ps1` mirrors.

**Trace**: FR-025, FR-030, FR-031, NFR-001, SC-019, SC-020.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

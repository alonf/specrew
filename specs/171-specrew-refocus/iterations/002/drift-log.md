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
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: 1 reconciled (external-fact change)

## Events

### D-002 — FR-013 Copilot clause obsoleted by live research (resolved: spec-updated)

- **Requirement**: FR-013 (per-host binding declarations; Copilot documented-variance clause)
- **Detected**: 2026-06-07, T013 (live-doc research)
- **What drifted**: the spec stated "Copilot binds none until a surface exists"; Copilot CLI hooks went GA 2026-02-25 with sessionStart/postToolUse additionalContext + a per-user project-local settings analog — the premise is factually obsolete.
- **Resolution**: spec-updated — FR-013 reworded to bind the verified subset per the research matrix; Copilot enters T014 binding scope under the approved Option C "all hook-capable hosts" decision. Citations + access dates in research-matrix.md.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

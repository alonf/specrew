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

**Total drift events**: 2
**Resolution rate**: 100% (2/2 resolved)
**Specification drift**: None detected (both events are implementation/scope drift surfaced for visibility, not spec-vs-implementation drift)

## Events

### D-001 — Pre-existing lifecycle-boundary-sync test broken against current boundary gates (scope expansion)

**Type**: scope expansion / pre-existing test-infrastructure debt
**Detected**: T003 (extending `tests/integration/lifecycle-boundary-sync.tests.ps1`)
**Resolution**: implementation-reverted-to-real-lifecycle (test fixed to mirror boundary-commit discipline)

The test was failing on the committed baseline (verified by running `HEAD`'s version), independent of
F-054: its scratch scenarios never committed between syncs, so two gates added to `sync-boundary-state.ps1`
(the 2026-05-22 `feature-closeout-working-tree-gate` and the F-033 pre-boundary markdownlint gate) HALTED
the feature-closeout and out-of-order iteration-closeout syncs. Because my T003 placement assertions are
appended after those scenarios, they never executed.

To make T003's regression coverage runnable and the lane green, the test now commits the scratch project
before feature-closeout and before the out-of-order iteration-closeout sync (mirroring real Rule-45
boundary-commit discipline), and writes a lint-clean `review.md` fixture. This is scope expansion beyond
F-054's surfacing intent into pre-existing test-infra debt — surfaced here rather than fixed silently.
Net result: all five integration lanes PASS, including the new F-054 placement assertions.

### D-002 — Pre-existing markdownlint debt in untouched upstream Spec Kit templates

**Type**: pre-existing repo debt (out of F-054 scope)
**Detected**: T016 (markdownlint glob run)
**Resolution**: deferred (not F-054 scope)

The T016 lint glob (`.github/agents/*.md`, `.github/prompts/*.md`) reports ~58 MD031/MD032/MD047
violations in upstream Spec Kit agent/prompt templates **not modified by F-054** (e.g.
`speckit.clarify.agent.md`, `speckit.constitution.agent.md`, `speckit.git.*.agent.md`). All F-054-touched
markdown was auto-fixed to lint-clean. The untouched-template debt predates this slice and is left for a
dedicated cleanup chore; recorded here so it is visible at review rather than silently bundled.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

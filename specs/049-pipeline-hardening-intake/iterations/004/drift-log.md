# Drift Log: Iteration 004

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

No specification drift detected during Iteration 004 execution to date.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

## Tooling Anomalies (non-drift; out-of-scope for this slice)

Framework/tooling defects surfaced while implementing Iteration 004. NOT specification drift; deferred.

- **B-001 — Duplicate `Get-ObjectPropertyString` in `validate-governance.ps1`.** The helper is defined
  twice with DIFFERENT parameter names: line ~690 takes `-Names`, line ~1551 takes `-PropertyNames`.
  The later definition shadows the former at load time, so any caller using `-Names` silently gets the
  `-PropertyNames` version and returns null. Discovered when Pillar 4 (`Test-BoundaryStateAdvanceVerdict`)
  read an empty `boundary_type`. **Fix applied in scope:** Pillar 4 rewritten to use direct
  `PSObject.Properties` access. **Deferred:** consolidating the two definitions (and auditing existing
  `-Names` callers that may be silently broken) is a separate framework slice — risk of affecting other
  callers; out of scope for Proposal 120.
- **A-001 (recurrence) — `Get-QualityEvidenceContent` StrictMode crash.** Same shared-helper defect as
  Iteration 005; still blocks scaffold-iteration-artifacts / run-mechanical-checks / scaffold-reviewer-artifacts
  on the `| Gate | Target | Notes |` plan convention. Evidence envelope + reviewer artifacts hand-authored.
  Deferred to the framework-fix slice.

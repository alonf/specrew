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
**Specification drift**: 1 spec-wording gap (resolved spec-updated); 1 pre-existing external blocker (resolved deferred to owning sibling slice)

## Events

### DRIFT-001 — SC-004 allowed-classes wording incomplete (resolved: spec-updated)

- **Detected**: 2026-06-06, T005 reference scan.
- **What**: the scan surfaced 5 `evaluation/` hits in `.squad/decisions-archive.md` (and its frozen fixture copies), an archived historical ledger that SC-004's allowed classes (retirement wording; frozen fixtures) did not enumerate, even though the proposal's history-preservation intent (item 6) plainly covers it.
- **Resolution**: spec-updated — SC-004 gained class (c) "archived historical ledgers preserved unmodified" with an inline provenance note. No implementation change; the archive stays byte-identical (FR-008 diff confirms).

### DRIFT-002 — full smoke-suite run blocked by pre-existing main red (resolved: deferred to owning slice)

- **Detected**: 2026-06-06, T004 smoke-suite run.
- **What**: `tests/integration/multi-host-lifecycle-smoke.tests.ps1` halts at its Test 4 (`sync-boundary-state.ps1 must read specrew_version from project's .specrew\config.yml`) because the test asserts F-160's obsolete backslash literal while the shim now uses POSIX-safe forms. Confirmed pre-existing: the same assertion fails against `main`'s shim with no 170 changes involved. The 170-relevant assertions (Test 9 forward-slash literal, Test 10 parse check) were executed directly and PASS.
- **Resolution**: deferred — the obsolete-mechanism assertion class is owned by the active sibling slice `169-found-bug-fixes` (its red-3 commit fixes the same class in another file). FR-005 evidence for this feature is the direct Test 9/10 runs plus `t004a-smoke.log`; the full-suite green re-check lands when the sibling slice merges.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

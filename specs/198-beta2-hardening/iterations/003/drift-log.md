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
**Specification drift**: One implementation-vs-data-model divergence
(DRIFT-198-I003-001) in iteration-002's shipped FR-020 code, surfaced by
iteration-003 co-review and fixed in place with paired abuse tests.

## Events

### DRIFT-198-I003-001 — FR-020 tracker honesty check diverged from its TrackerClaims data model (resolved: implementation-corrected)

- **Requirement citation**: FR-020 (fail-closed tracker honesty check);
  data-model.md Entity `TrackerClaims` — `task_statuses` MUST use canonical
  enums only, "parse failure of any claim → fail-closed"; NFR-001 (no
  false-green path); the module's own header states the I3 fail-direction
  ("any parse ambiguity, any unknown file shape, any claim the check cannot
  map → NOT honest").
- **Divergence (shipped in iteration 002, T010)**:
  `Get-ContinuousCoReviewStateClaims` extracted only `Iteration Status` and
  `Last Completed Task` and IGNORED all other content, accepting any
  `[a-z-]+` status and any free-text last-task value; the `tasks-progress.yml`
  parser accepted any `[a-z-]+` status rather than the canonical enum set.
  A tracker-only edit could therefore inject an unmapped/foreign claim
  (a capacity or test-count line into state.md) or use a non-canonical
  status form and be treated as honest — retaining stale review evidence.
  A fail-OPEN door in the exact fail-closed machinery the feature promises.
- **Detection**: iteration-003 continuous co-review, run
  `20260711T163540953-1446b84c` (blocking). Verified against disk and the
  data model before acting — the finding was correct, not a stale replay.
- **Resolution (implementation-corrected, in place)**: canonical
  iteration-status and task-status enums are now required (non-canonical →
  fail-closed); `Last Completed Task` must be a `Tnnn` id or a `(none...)`
  sentinel (other free text → fail-closed); an injected capacity/test-count
  claim in a tracker file (their real homes are the non-tracker plan.md /
  coverage-evidence.md) declines the bypass. Five paired tests added to
  `tests/unit/tracker-honesty-check.tests.ps1` (Tests 7-11): four abuse
  paths prove decline, one paired legitimate case proves the fix did not
  over-close; the full suite is green and the signoff-gate wiring
  (degraded-evidence-gate 9/9) still accepts a legitimate tracker-only
  reconcile.
- **Scope note**: not a scope expansion — this REALIZES FR-020 per its own
  recorded data model; no new requirement. Recorded here (found/fixed in
  003) rather than reopening the closed 002 record.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration

### Notes

- DRIFT-198-I003-001 used implementation-correction (the code was brought to
  its data model), the honest direction for a fail-open in fail-closed
  machinery.

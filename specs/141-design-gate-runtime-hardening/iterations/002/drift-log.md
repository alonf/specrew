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
**Specification drift**: 1 implementation-vs-spec drift, resolved in-iteration (see Event 1)

## Events

### Event 1 — FR-024 confirm-gated cleanup silently undone within the same start run

- **Detected**: 2026-06-02, by the T009 end-to-end enforcement test (`tests/integration/start-recovery-flow.tests.ps1`).
- **Type**: implementation-vs-spec drift (implementation diverged from the FR-024 requirement).
- **Surface**: `scripts/specrew-start.ps1` recovery flow.
- **Drift**: FR-024 requires the confirm-gated cleanup to clear the runtime session references "that would otherwise re-anchor the next start" (the `Clear-SpecrewStaleSessionReference` contract). The cleanup did clear `start-context.json` `session_state` on disk, but the SAME `specrew start` run's end-of-run start-context regeneration re-serialized the stale in-memory `$validatedSessionState`, re-anchoring the deleted feature (`active=true`, `feature_ref: 051-old-merged`). Net effect: the cleanup did not stick for `start-context.json` (active-sessions.yml cleared correctly), so the next start would re-detect the identical stale session — an endless re-anchor loop. The unit tests passed because they exercise `Clear-SpecrewStaleSessionReference` in isolation; only the end-to-end flow exposed it.
- **Resolution** (`implementation-fixed`): after a confirmed+cleared cleanup, `scripts/specrew-start.ps1` nulls `$validatedSessionState` so the regenerated context records no active session and the mode falls to intake-or-resume. Verified by the new e2e enforcement test (asserts `session_state` is cleared and not re-anchored after the full run) and by re-running the targeted suite green.

## Reproduction Evidence (T001 — FR-011 + FR-014)

These are the planned smoke-defect fixes for this iteration (feature scope, not spec drift — the drift-event count above is unchanged). Reproduced before fixing, per the reproduce-first methodology:

- **FR-011 (empty `specs//` paths)** — Reproduced at the renderer layer: `Get-SpecrewHostOrientationBlock` emits a `file:///<project-root-url>/specs/<feature>/…` browse URL even when `$FeatureRef` is empty (greenfield/intake). The empty `specs//` appears when the coordinator substitutes the `<feature>` placeholder (Rule 48) with no feature. Note: grepping the generated `last-start-prompt.md` for `specs//` is vacuous — the file holds the literal `<feature>` placeholder; the defect is the renderer offering a feature-path-shaped URL in a no-feature context. Fixed by guarding the browse line when `$FeatureRef` is empty (explicit-placeholder guidance, no collapsing URL). Reproduce-first test: `tests/integration/multi-host-launch-path.tests.ps1` Test 9b.
- **FR-014 (host-wording leak)** — Reproduced empirically: greenfield `specrew start --host claude -NoLaunch` prints `Copilot approval mode: allow-all` (unconditional `specrew-start.ps1` launch line). A second instance of the same class: the new-window delegation success line hardcoded `Delegated to Copilot + <agent>`. Both fixed to host-accurate wording (`Approval mode:` / host-aware `$hostLabel`). Reproduce-first test: `multi-host-launch-path.tests.ps1` Test 18b. Runtime-confirmed clean post-fix.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

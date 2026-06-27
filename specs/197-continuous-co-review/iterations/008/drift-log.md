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

**Total drift events**: 2
**Resolution rate**: 100% (2/2 resolved)
**Specification drift**: One authorized dogfood repair is recorded: the review-signoff hard gate is default-on in 197-owned wiring and Specrew self-review includes the co-review runtime under test. A second event records the 2026-06-28 lifecycle-state reconciliation (governance-artifact drift, not requirement/implementation drift).

## Events

### D-197-I008-001 - Dogfood hard-gate repair after co-review evidence gap

**Status**: resolved
**Detected by**: live co-review `codex-hard-gate-20260627`
**Authorized by**: maintainer instruction on 2026-06-27 to make the co-review mechanism robust after the AISharedMemoryMCP host-switch dogfood failure
**Ratified by**: maintainer response "OK, do it" on 2026-06-27, confirming option B from `codex-hard-gate-rerun-20260627`: keep this drift event in Iteration 008 and keep Iteration 001 at zero drift events.

**Drift**: The implementation changed the review-signoff gate from an opt-in configuration key to a default-on backstop and changed the worktree reviewer visibility policy for Specrew self-review. Iteration 008 design previously treated the signoff evidence gate as surviving unchanged and the strip set as downstream methodology machinery; dogfooding proved those assumptions insufficient for the host-switch/compaction failure mode.

**Resolution**: Recorded T083/T084/T085 in `specs/197-continuous-co-review/tasks.md`, added the dogfood repair decisions to `specs/197-continuous-co-review/iterations/008/design-analysis.md`, kept the implementation inside `scripts/internal/continuous-co-review/`, removed the unapproved waiver parser change from protected `shared-governance.ps1` mirrors, added reviewer-runtime telemetry and smart budget guidance without restricting reviewer tool access, and deferred multi-reviewer fan-out unless it becomes a simple separate-output-dir seam.

**Trace**: FR-025, FR-030, FR-031, NFR-001, NFR-002, NFR-011, OBS-002, OBS-005, SC-005, SC-019, SC-020.

### D-197-I008-002 - Lifecycle-state reconciliation (frozen cursor + stale iter-001 + ledger drift)

**Status**: resolved
**Detected by**: session status check on 2026-06-28 (frozen `start-context.json` pointer surfaced during a `status?` query)
**Authorized by**: maintainer directive 2026-06-28 — "use git, commits and file modified time and update the artifacts; if we have new features or tasks, update plan.md and tasks.md retroactive"

**Drift**: `.specrew/start-context.json` was frozen at `iteration_number=001` / `before-implement` (generated 2026-06-17) while real work advanced through iterations 002-008. Because tooling treats a not-started iteration as active, telemetry/heartbeat writes landed in iter-001, and iter-001/`state.md` had been resume-re-scaffolded back to `not-started` (contradicting its own complete prose). `plan.md` was frozen at the iter-002 framing; `tasks.md` omitted T070-T082/T086 and collided T083-T085 across iter-006 and the iter-008 addendum. This is governance-artifact drift (issue #2784 class), not requirement or implementation drift.

**Resolution**: reconciled the cursor to iteration 008 (the live iteration with honest state); restored iter-001/`state.md` header to disk truth (`complete` / `review-signoff`); added reconciliation banners + the true iteration-status table to `tasks.md` and `plan.md`; recorded the iteration-009 robustness slice (R1-R5 -> T090-T094) and the T083-T085 collision cleanup (T095) as forward plan. No iteration-closeout/retro ceremonies were fabricated for the never-formally-closed iterations (001/006/007) per the 2026-06-24 anti-fabrication ruling. Known remaining (not back-authored): iter-008 has no `plan.md` (informal iteration; pre-existing validator FAIL); closed-iteration-index backfill for 003/004/005 deferred because `-RebuildClosedIndex` rebuilds the whole-repo index and risks dropping other features' entries. Durable fix for this drift class = Proposals 142/193 (separate feature, after F-197).

**Trace**: governance / lifecycle-state integrity (issue #2784; Proposals 142, 193).

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

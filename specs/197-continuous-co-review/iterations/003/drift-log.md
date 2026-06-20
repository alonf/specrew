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

**Total drift events**: 3
**Resolution rate**: 100% (3/3 resolved)
**Specification drift**: 1 resolved (FR-025 wording); 1 plan resequence (Stop-hook critical path); 1 implementation drift (145 review: gate did not meet FR-025, fixed)

## Events

### D-197-I003-001 — FR-025 reworded from "every increment" to current-state diff_hash freshness

- **Detected**: 2026-06-20, during before-implement design pressure-test.
- **Drift**: The initial FR-025 wording required the gate floor to prove "every
  implement increment carries passing or escalated evidence," implying per-increment
  git-history coverage. Design review found this over-engineered: because the
  co-review baseline advances only on a pass, a single current-state freshness check
  (recompute `diff_hash` from the last passing run's `baseline_ref` to the working
  tree) transitively proves every prior increment without git-history archaeology.
- **Citation**: FR-025, FR-027, SC-019, SC-020.
- **Resolution strategy**: spec-updated.
- **Resolution**: FR-025 reworded to the diff_hash/baseline-advances-on-pass
  semantics; `tasks.md` and `iterations/003/plan.md` T058/T061 updated; the separate
  checkpoint ledger was dropped in favor of reusing `.specrew/review/inline`
  evidence. Per-increment live review remains Phase B (Iteration 004) scope, so the
  always-on intent is unchanged.
- **State**: resolved.

### D-197-I003-002 — Phase A resequenced to put the Stop-hook trigger on the critical path

- **Detected**: 2026-06-20, after the maintainer set automatic per-stop reviewer
  execution as a hard requirement.
- **Drift**: The approved plan ordered Phase A (non-protected gate floor + dispatcher)
  fully before Phase B (the F-184-protected Stop hook), so automatic per-stop running
  would not land until Iteration 004. The requirement makes that ordering wrong.
- **Citation**: FR-024, FR-026, FR-030.
- **Resolution strategy**: human-decision (plan-updated).
- **Resolution**: Maintainer approved resequencing — critical path becomes T059
  dispatcher → T060 run-wiring → Stop-hook trigger → T061 gate floor as backstop. The
  F-184-protected Stop hook is pulled into Iteration 003 under the authorized
  coordination; the new Stop-hook task and the protected-surface scope/SC-006 update
  will be reflected in plan.md/tasks.md when T060 completes.
- **State**: resolved.

### D-197-I003-003 — Fresh-context Proposal 145 review found the gate did not meet FR-025

- **Detected**: 2026-06-20, by a fresh-context Proposal 145 reviewer sub-agent run on
  the T058/T061 commits (the feature dogfooding itself).
- **Drift**: The committed gate logic did not actually deliver FR-025: (F1) `git diff`
  ignores untracked files so the gate returned `allow` on genuinely un-reviewed
  content (proven live); (F2) the "last passing" resolver had no feature/iteration
  scoping, so the baseline-advances-on-pass invariant was unenforced; plus advisories
  (F3 reviewed_ref provenance, F4 trace overclaim, F5 non-falsifying tests, F6 sort,
  F7 diff_hash over the full not reviewable diff).
- **Citation**: FR-025, FR-007, FR-027, SC-020, the spec out-of-band-edit edge case.
- **Resolution strategy**: implementation-reverted (fixed implementation to match the
  spec).
- **Resolution**: all 7 findings fixed (F1 untracked-block, F2 `scope` field + filter
  threaded through resolver/gate/orchestrator, F3–F7); gate tests 4→8 now falsify the
  real failure modes; full continuous-co-review suite 148/0; re-review queued.
- **State**: resolved (pending the confirming re-review).

### Resolution Strategies (Available)

The following resolution strategies remain available if further drift is detected:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded at before-implement so drift can be logged immediately
  when detected during Iteration 003 (Phase A) execution.

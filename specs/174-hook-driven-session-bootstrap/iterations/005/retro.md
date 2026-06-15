# Retrospective: Iteration 005

**Schema**: v1
**Date**: 2026-06-09

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T029 | 2 | 2 | 0 |
| T030 | 2 | 2 | 0 |
| T031 | 2 | 2 | 0 |
| T032 | 1 | 1 | 0 |
| T033 | 2 | 2 | 0 |
| T034 | 1 | 1 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done | done | 0 | A/B-split design co-settled with the human (mechanism-not-pledge, iter-4 action-4). |
| Discovery/Spikes | 0 | 0 | 0 | Builds on the iter-4 rolling-handover machinery. |
| Implementation | 10 | 10 | 0 | T029-T034; all exact. |
| Review | 2 | 2 | 0 | 145 review passed first-pass + validator EXIT 0 - then a post-verdict honesty qualification was added (the build != live miss; not implementation rework). |
| Rework | 1 | 0 | -1 | No implementation send-back. NOTE: 0-rework + 0-variance did NOT mean clean - both metrics are blind to the build != live miss (see What Didn't Go Well). |

## Drift Summary

- Total drift events: 2 (logged in drift-log.md). D-008 (instruction #2 "Stop-time warns the agent" is
  unrealizable under P1 - delivered as option-1 non-blocking detection) RESOLVED in-iteration. D-009 (the
  failure-mode-A floor asserted dev-tree round-trip, not deployed-tree resolution - build != live)
  DEFERRED to iteration 6. Resolution rate 50% (1/2) - honestly, because D-009's live wiring is iter-6's
  deliverable, not a same-iteration fix.

## What Went Well

- **The A/B honest split was the right design.** Separating the CI-blocking PLUMBING (A) from the
  detected-not-prevented AUTHORING (B), and encoding it in SC-010 + drift D-008, kept the iteration from
  banking a behavioral pledge as a mechanism. That application of iter-4's action-4 to iter-5's OWN design
  held at the level it was aimed at (the B authoring claim is honestly scoped detect-not-prevent).
- **The greenfield dogfood (Claude + Codex) earned its keep.** It surfaced BOTH the deeper "the hook
  orients but does not DRIVE" gap (no launch contract, no `boundary_enforcement` init, no read-and-follow
  - the iter-6 charter) AND the "iter-5 handover does not fire live" gap, before either shipped silently.
  The diagnostic asymmetry it exposed - the SessionStart bootstrap DID resolve on `claude` (orientation
  rendered) while the Stop hook did NOT - is the precise key iter-6 needs.
- **The F-141 design workshop executed to full standard on both ends of the complexity range** - a light
  calculator (right-sized to 3 lenses) and a complex IaC monitor (scaled to 8 lenses). The earlier
  "workshop dodge" reading was retracted after the Ctrl+O transcript showed it routed correctly; the real
  finding is inconsistency, not failure (a separate proposal, not iter-5/6).
- **Estimation exact a fifth straight iteration** (0 variance) - but see the calibration caveat.

## What Didn't Go Well

- **HEADLINE - the failure-mode-A "floor" had its OWN build != live hole. The same lesson, a THIRD
  layer.** Iteration 5 was explicitly designed to apply action-4's "mechanism, not another pledge" lesson,
  and the failure-mode-A test floor WAS the mechanism - the strong, CI-blocking guarantee. But that floor
  asserted persisted-bytes == surfaced-bytes IN THE DEV TREE (components co-located via
  `$PSScriptRoot/bootstrap`) and NEVER that the provider can RESOLVE the persisting code in a DEPLOYED
  tree. So the very test built to be the mechanism was itself a dev-tree-only pledge, one level down. In a
  deployed downstream project the Stop provider cannot resolve HandoverStore (SPECREW_MODULE_PATH does not
  reach the Stop-hook child), so the handover silently never fires. Same build != live class as F-054 and
  the iter-3 D-002 send-back.
- **The 145 review's own "honesty check" congratulated itself while missing this.** Phase 6 recorded an
  explicit "Honesty check (the iter-5 lesson on its own deliverable)" - and it checked the B claim
  (authoring is not mechanically forced, correctly) while MISSING that the A evidence floor was
  dev-tree-only. The review then OVERCLAIMED on top ("the bootstrap surfaces ... fires") with no deployed
  qualifier. The lesson did not fully stick even in the iteration named after it - the strongest possible
  evidence that build != live needs a MECHANISM (action 2 below), not another careful intention.
- **It took a human correction to surface it.** Both the validator (EXIT 0) and the structured 145 review
  passed the overclaiming artifacts. Only the greenfield dogfood + the human's "does the start hook do
  exactly what `specrew start` does?" question exposed it. The catch was post-hoc and human, not
  in-harness.

## Improvement Actions

1. **Owner: Implementer | Phase: iter-6 test design | Type: methodology (the durable fix).** A "floor"
   test that runs only in the DEV tree (components co-located via `$PSScriptRoot`) is NOT a live-wiring
   guarantee - it structurally cannot witness deployed-tree component resolution. Any floor that claims a
   RUNTIME behavior MUST run against a DEPLOYED layout (installed module, or a deployed-config fixture), or
   its claim is explicitly scoped "dev-tree-only". This generalizes the iter-3 deployed-config-floor
   (`DeployedHostConfig.Tests`, which the iter-4 retro confirmed HELD for host-config) - it was simply
   never applied to the handover provider's component resolution. Iteration 6 carries a LIVE-WIRING FLOOR:
   a real DEPLOYED session writes the launch contract + the agent-authored handover to disk (not
   dev-tree-green).
2. **Owner: Reviewer | Phase: review-signoff (145 Phase 5/6) | Type: review-instruction candidate ->
   PROMOTE.** For any claim of the form "X surfaces / fires / renders at runtime", the 145 claim ledger
   MUST record an `evidence_locus: dev-tree | deployed`, and the review MUST REFUSE to mark a runtime
   behavior delivered-LIVE on dev-tree-only evidence (downgrade to "dev-tree-verified, live deferred").
   This makes build != live a review MECHANISM rather than a post-hoc human dogfood. Reconcile the exact
   shape with the F-174 rebase + the beta-2 #2216 state-truth work (`f174-action4-reconcile-with-2216`),
   like action-4's validator chore - file the genuine residual, not a duplicate.
3. **Owner: Implementer/Planner | Phase: iter-6 design | Type: process (the recurring meta-instruction).**
   Apply THIS iteration's own lesson to iter-6's design: do not let iter-6's "parity" floor be another
   dev-tree smoke. Bring the hook to parity with `specrew start` by REUSING its handoff/state generator
   (no second thin directive, no drift), and prove it with the deployed live-wiring floor from action 1.
4. **Owner: Implementer | Phase: cleanup / feature-closeout | Type: cleanup (carry).** Still pending from
   iter-4: `f174-followup-remove-dormant-sessionend-code` (delete the dormant SessionEnd code) + correct
   the inaccurate "REUSED" design-record phrase. Bundle with feature-closeout (non-blocking).

## Calibration Suggestion

- Keep the 10-18 SP band; iteration 5 was 10 SP at 0 variance (fifth straight iteration at 0 variance).
- **Honest caveat (new):** 0 SP variance does NOT mean the iteration was clean. Effort variance measures
  estimate accuracy; it is BLIND to a correctness-of-claims miss like the build != live overclaim. Do not
  read the 0-variance streak as a quality signal - read it as a velocity signal only. Quality is carried
  by the deployed-evidence mechanism (action 2), not by the variance number.

## Signals For Next Step (iteration 006, NOT feature-closeout)

- **Supersedes the iteration-4 retro's "Signals For Next Step".** The iter-4 retro stated "F-174 is
  functionally complete across iterations 1-4 ... feature-closeout ships 1-4". That signal is now
  **WRONG and superseded**: iteration 5 added FR-022 (dev-tree machinery, live wiring deferred), and
  iteration 6 is REQUIRED before any feature-closeout. F-174 stays OPEN.
- **Iteration 006 charter:** bring the SessionStart hook to parity with `specrew start` ON CLAUDE - hand
  the agent the SAME launch contract + state (`boundary_enforcement` init, the ~48-rule handoff,
  read-and-follow) by REUSING `specrew start`'s handoff/state generator, AND make the iter-5 agent-authored
  handover actually fire end-to-end in a DEPLOYED session. Carry the deployed live-wiring floor (action 1).
- **Honest scope for iter-6 (the maintainer's caveat):** target real parity ON CLAUDE; keep `specrew
  start` as the robust cross-host driver (Codex showed the hook output may not reach the model); fix the
  docs / F-174 claims so the hook is positioned as orientation/resume, NOT a `specrew start` replacement
  across hosts.
- **Feature-closeout (after iter-6):** ships iterations 1-6 together via push/PR/merge, **NO beta-publish**
  (`f174-closeout-no-beta-local-install`) - the maintainer validates by installing the module from this
  local dev folder; the PSGallery publish is deferred until after that local validation.

## Notes

- Dogfood findings captured for the iter-6 + closeout ledgers: the hook-doesn't-drive gap (iter-6
  charter); the iter-5-doesn't-fire-live gap (D-009 -> iter-6); the SessionStart-resolves /
  Stop-doesn't-resolve asymmetry (iter-6 diagnostic key); the recurring zero-commit-baseline trap in
  greenfield (`git add -A` sweeps scaffold - Rule 5/8); the design-workshop inconsistency (separate
  proposal, not iter-5/6).

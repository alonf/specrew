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

**Total drift events**: 6
**Resolution rate**: 4/6 resolved; HOLE A/B re-architecture in progress (T065-T067 done); F3/F5 advisories carried
**Specification drift**: FR-025 wording; plan resequence; impl drift fixed; HOLE A/B re-architecture (in progress); premature close reversed; gate false-allow F1 fixed

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

### D-197-I003-004 — Design-panel co-review found the gate model unsound (HOLE A/B); carried to Iteration 004

- **Detected**: 2026-06-20, by a multi-agent design judge-panel + adversarial re-review
  of the fixed gate (the feature dogfooding its own evidence model).
- **Drift**: The FR-025 gate's diff-from-baseline model has two model-level false-allows
  no localized patch closes: HOLE A (gitignored source is invisible to both gate probes)
  and HOLE B (the operator-chosen `--baseline-ref` is never verified as itself reviewed;
  the "baseline advances only on a pass" invariant is vacuous because no production caller
  threads `-RebaselineToLastPass`).
- **Citation**: FR-025 ("impossible to sign off on un-reviewed state"), FR-027.
- **Resolution strategy**: deferred (re-architecture) — Iteration 004.
- **Resolution**: NOT fixed in Iteration 003. The sound model (anchored chain +
  content-addressed reviewed-state identity that includes untracked/gitignored, +
  lineage-based identity + the agreed NEW-2/3/5/6 hardening) is the Iteration 004 scope.
  Neither hole is live-exploitable in 003 because the gate is unwired (deferred post-185).
- **State**: open -> addressed within Iteration 003 (gate re-architecture; see D-197-I003-005).

### D-197-I003-005 — Premature review-signoff close reversed; gate re-architecture stays in Iteration 003

- **Detected**: 2026-06-20, maintainer challenged the proposed partial-close-and-open-004.
- **Drift**: The coordinator drove iteration 003 toward a review-signoff partial close and
  a new iteration 004 for the gate re-architecture. That over-split coherent in-flight
  work: 003's FR-024/025/027 scope and gate goal are unchanged, so the content-addressed,
  anchored re-architecture is the correct completion of 003's existing gate, not new
  scope. A mid-implement design pivot is in-iteration drift to be re-planned, not a new
  iteration.
- **Citation**: FR-024, FR-025, FR-027; Specrew iteration-scope discipline.
- **Resolution strategy**: human-decision (process correction).
- **Resolution**: review-signoff packet (`b14fb8fb`) reversed; review.md removed; state
  reset to executing. The gate re-architecture (D-197-I003-004) is completed within 003.
  Iteration 004 remains reserved for Phase B (Stop-hook). A capacity split is taken ONLY
  if the re-planned remaining work exceeds the 20 SP cap (the F-185-style split-guard).
- **State**: resolved.

### D-197-I003-006 — Adversarial review of the re-architected gate (T065-T067): F1 false-allow fixed

- **Detected**: 2026-06-20, by a fresh-context Proposal 145 adversarial reviewer of the
  re-architected gate (the feature dogfooding itself again; repo left clean).
- **Drift**: The digest-identity denylist used substring globs `*secret*` / `*credential*`
  that over-matched legitimate SOURCE basenames (`src/credentials.ts`,
  `lib/secret-rotation.go`), stripping them from the gate tree-id so a post-pass edit was
  invisible to freshness == a false-allow on un-reviewed source (F1, empirically proven).
  My own digest test certified the over-match as desired (F2).
- **Citation**: FR-025 ("impossible to sign off on un-reviewed state").
- **Resolution strategy**: implementation-reverted (fix to match the spec invariant).
- **Resolution**: separated digest-IDENTITY exclusion (near-empty: runtime/ambient dirs +
  true secret FILES by name/extension) from reviewer-bundle CONFIDENTIALITY (the broad
  substring globs, owned by the bundle path). Removed `*secret*`/`*credential*` from the
  identity denylist; added the F2 regression (source named like a secret stays in the
  tree-id and its drift flips the digest). Digest 9/9, gate 9/9.
- **Carried (advisory, not blocking)**: F3/F4 override + run-record trust boundary -> bound
  to the deferred F-185 wiring (authenticate + persist; binding comment added in the gate).
  F5 trunk merge-base resolves a LOCAL ref -> address in T068 (configurable trunk + remote
  fallback). The chain-walk/anchor/coverage half and the self-pollution strip held under
  attack (HOLE B genuinely closed).
- **State**: resolved (F1/F2); F3/F4 -> wiring, F5 -> T068.

### Resolution Strategies (Available)

The following resolution strategies remain available if further drift is detected:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded at before-implement so drift can be logged immediately
  when detected during Iteration 003 (Phase A) execution.

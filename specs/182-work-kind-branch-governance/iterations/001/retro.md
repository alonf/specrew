# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-06-11

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 1.5 | 1.5 | 0 |
| T002 | 1 | 1 | 0 |
| T003 | 1.5 | 1.5 | 0 |
| T004 | 2 | 2 | 0 |
| T005 | 1 | 1 | 0 |
| T006 | 0.5 | 0.5 | 0 |
| T007 | 0.5 | 0.5 | 0 |
| T008 | 0.5 | 0.5 | 0 |
| T009 | 1.5 | 1.5 | 0 |
| T010 | 1 | 1 | 0 |
| T011 | 0.5 | 0.5 | 0 |
| T012 | 1.5 | 1.5 | 0 |
| T013 | 0.5 | 0.5 | 0 |
| T013b | 0.5 | 0 (deferred) | -0.5 |
| T014 | 1 | 1 | 0 |
| T015 | 1 | 1 | 0 |

**Average variance**: ~0 (on-target). SP actuals are qualitative (no per-task time-tracking);
the only delta is T013b (0.5 SP) deferred out of Iteration 1 to the release/deploy step. Consumed
15.5 / planned 16 / cap 20.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | — | — | on-track | Design workshop converged the architecture (provider-neutral, branch_model, review_gate) before plan. |
| Discovery/Spikes | — | small | +small | One unplanned spike: the YAML-parsing approach (Specrew avoids powershell-yaml → a focused reader). |
| Implementation | — | — | on-track | High reuse of the F-177 catalog→declaration→enforcement spine; no blockers. |
| Review | — | — | +rework | One review-caught task-status truthfulness drift (D-001) + a baseline-ref correction for review evidence. |
| Rework | — | small | +small | T013 split/correction; markdownlint `+`-at-line-start fixes. |

## Drift Summary

- Total drift events: 1
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 1 (D-001 — T013b to release/deploy, maintainer-approved)
- Escalated to human decision: 0

## What Went Well

- The design workshop did real work: provider-neutral core + pluggable `ProviderAdapter`,
  configurable `branch_model`, `review_gate`, and the forge-neutralization pillar all emerged from
  the lens discussions, not from the proposal alone — and the architecture held through implementation.
- The **dependency-free YAML reader** cleanly resolved the constraint that Specrew avoids
  `powershell-yaml`, keeping the `use-existing-no-new-dependency` policy intact; it's behavior-tested.
- The **safety guard** (`apply_protection` refused for read-only/unverified/unapproved adapters) was
  designed at the security lens and is test-asserted — the AI-generated-adapter risk is contained.
- **Honest phasing** held: no runtime enforcement was over-claimed; the validator/capability/dogfood
  are clearly Iter-2, and review accepted on behavioural evidence (58 assertions), not file-presence.
- The `psd1-sort.ps1` sorter made FileList registration mechanical + the completeness test caught it.

## What Didn't Go Well

- **The load-bearing miss: T013 was marked `done` while two of its three sub-parts were not done**
  (extension.yml bump + `.specify` coverage). The state.md prose admitted the deferral while the task
  status said `done` — a self-inconsistency I did not self-catch; **the maintainer caught it at review.**
  Root cause: T013 conflated an Iteration-1 action (FileList) with release/deploy actions, and I let
  "done-with-deferrals" stand as "done".
- The iteration **baseline ref** was the design-analysis scaffold commit, so the review-evidence diff
  spanned 42 files vs 15 tasks (a misleading form-vs-meaning warning) until corrected to the
  pre-implementation commit.
- Recurring **markdownlint `+`-at-line-start mangle**: several wrapped lines starting with `+` were
  auto-converted to `-` bullets by the gate's `--fix` (one corrupted prose before I caught it).
- The reviewer-artifact scaffolder's **`-Force` path is buggy** (ShouldProcess null-ref); delete +
  re-scaffold was the workaround.

## Improvement Actions

1. Owner: Implementer | Phase: every implement task | Type: process | **A task whose sub-parts span
   different lifecycle steps (implement vs release vs deploy) MUST be split before any part is marked
   `done`. "Done with deferrals" is never `done` — split it, mark the implement part done, and carry
   the rest as an explicit deferred task.** (Prevents the D-001 class.)
2. Owner: Implementer | Phase: review prep | Type: process | Set the iteration `Baseline Ref` to the
   **pre-implementation commit** (not the design-analysis scaffold commit) so review-evidence diffs
   match the implementation.
3. Owner: Implementer | Phase: authoring | Type: process | Author markdown with **no `+` at a wrapped
   line start** (use "and"/commas) to avoid the markdownlint `--fix` `+`→`-` mangle.
4. Owner: Implementer | Phase: tooling backlog | Type: implementation | File the reviewer-artifact
   `-Force` ShouldProcess null-ref as a tooling-defect candidate (Proposal-037 / scaffolder backlog).

## Calibration Suggestion

- Suggested capacity adjustment: keep the 20 SP iteration cap (Iter-1 consumed 15.5, comfortably under).
- Rationale: on-target estimation; the only variance was the approved T013b defer. The feature's total
  (~31 SP > the ~16–24 rough estimate) is the signal to watch — re-confirm the Iter-2/Iter-3 split (and
  the Iter-3 split-to-sibling escape hatch) at the next planning.

## Signals For Next Iteration (Iteration 2)

- **Carried watch-items** (review-accepted, not pulled into Iter-1): (1) add a contract test for the
  YAML reader as the schemas evolve; (2) **resolve the deployed-catalog location** — `.specify` mirrors
  `scripts/` but not `knowledge/`, so where the deployed validator reads `work-kinds.yml` is the first
  Iter-2 design decision; (3) the `New-*` ShouldProcess false-positive stays on the Proposal-037 queue.
- **T013b** (extension.yml version bump + deploy-time `.specify` coverage) is carried to Iter-2 dogfood
  (T019) / feature-closeout, where it is resolved (the version target is a release decision).
- Iteration 2 builds the runtime: the CI work-kind validator (FR-007), capability detection (FR-012),
  on-the-fly synthesis exercised (FR-016), apply_protection runtime + bypass audit (FR-011/FR-020), and
  the Specrew self-dogfood (FR-013/SC-007/SC-014).

## Notes

- Maintainer signed off the Iteration-1 review (accepted) and approved D-001; the three watch-items are
  carried forward, not pulled into Iteration 1.
- No push/PR/merge/tag/publish/release; no Iteration-2 work — stop after iteration-closeout per the
  maintainer's instruction.

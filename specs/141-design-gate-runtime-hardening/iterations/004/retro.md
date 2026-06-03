# Retrospective: Iteration 004

**Schema**: v1
**Date**: 2026-06-03

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 2 | 2 | 0 |
| T002 | 3 | 3 | 0 |
| T003 | 3 | 3 | 0 |
| T004 | 2 | 2 | 0 |
| T005 | 3 | 3 | 0 |
| T006 | 1 | 1 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | Design-analysis gate (Option B decoupled) + plan. First in-feature use of 141's own gate. |
| Implementation | 10 | 10 | 0 | Map + selector + JSON emit + render + template wire on estimate. |
| Review | 3 | 3 | 0 | Tests + docs/gap-ledger + the maintainer-requested dogfood render. |
| Rework | 0 | ~1 | +1 | Unplanned: the MD049 render-emphasis fix; the prove-first null-answers semantics correction; one commit hiccup. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0 (the spec was amended UP FRONT — Amendment A1 — not mid-flight)
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- **The dogfood converged.** Rendering iteration-4's own design-analysis "Applicable Lenses" through the implemented path (answers → selector → render) reproduced exactly the hand-judged set and the recorded JSON `selected` — strong end-to-end proof that the feature works on its own artifact. The maintainer's divergence guard (send back if it diverges) was satisfied without a send-back.
- **Prove-first caught a semantics bug before it shipped.** SC-006 requires answers-absent to degrade to "none available"; the first selector returned the always-on set. Corrected before commit.
- **Decoupled discipline held.** `index.yml` stays pure (test-asserted); the gating map is the sibling; the deterministic, LLM/network-free selector matches FR-025/SC-015; deferred 156 automation stayed out (FR-010).
- **The design-analysis gate dogfooded itself.** Iteration 4 is the first 141 iteration to run the gate 141 built.

## What Didn't Go Well

- **The render emitted MD049-violating emphasis** (underscore `_..._` where the repo config wants asterisk). The selector tests asserted no `+`-at-line-start but not emphasis style, so only the design-analysis.md markdownlint caught it. Fixed + added an emphasis-style regression assertion.
- **A commit hiccup:** an inline `pwsh` inside a bash double-quoted heredoc had its `$p` variable eaten by bash (empty path) → the command backgrounded/failed and nothing committed; redone cleanly. No data lost (the failure was diagnosed, not papered over).

## Improvement Actions

1. Owner: Reviewer | Phase: test authoring | Type: testing | Expected effect: any helper that EMITS markdown gets a markdownlint/emphasis-style assertion in its unit test — the MD049 render bug slipped the selector tests and was only caught at the artifact-lint layer.
2. Owner: Implementer | Phase: tooling | Type: process | Expected effect: do not embed `pwsh` with `$var` inside a bash double-quoted compound command (bash expands the `$var` first); use single-quotes, a here-string, or a separate step. Mirrors the self-host gotchas already in memory.

## Calibration Suggestion

- Keep the 20 SP iteration baseline; 14 SP held at 0 planned-task variance. The real signal is small unplanned rework (MD049 fix, semantics correction) absorbed without dropping scope.

## Notes

- Amendment A1 (spec un-deferral of FR-009/FR-010 + FR-025) was a deliberate, recorded up-front spec change driven by release-overhead economics — not mid-flight drift.
- Proposal 156 (main) updated to record implemented-vs-future; deferred deeper automation remains its open scope.

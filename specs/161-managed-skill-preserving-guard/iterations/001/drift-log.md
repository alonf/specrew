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
**Specification drift**: Both events reconciled within the iteration

## Events

### Event 1 — T007 promotion target: S7, not S4 (resolution: human-decision)

- **Detected**: 2026-06-06, during T006/T007 execution.
- **Drift**: tasks.md T007 title says "S4 probe → regression assertion"; the
  implementation promoted **S7** (the genuine v0.21-era generic artifact — the
  reachable case) and left S4/S4g as recorded probes.
- **Why**: at the verdict boundary stop the human selected the stricter fix
  shape (generic-kind branch only; front-matter heuristic untouched), which
  makes S4/S4g the accepted residual rather than fixed behavior.
- **Resolution**: human-decision — recorded in `.squad/decisions.md`
  (2026-06-06T12:20:00Z entry), `evidence.md` (Accepted Residual), and the
  review.md Gap Ledger (deferred entry). FR-004's "conditional narrow fix"
  is satisfied by the released scope; spec text needs no change (FR-004 was
  written as conditional on the verdict and the released shape).

### Event 2 — CI workflow surface not in the planned source list (resolution: spec-updated)

- **Detected**: 2026-06-06, during T008 review of FR-006.
- **Drift**: plan.md "Planned Source/Test Surfaces" lists only the deploy
  script, its mirror, and the two test files; satisfying FR-006 ("tests run
  in the repo test harness") required adding an explicit step to
  `.github/workflows/specrew-ci.yml` because the CI integration lane runs
  tests as explicit steps, not globs (Feature 140 lesson).
- **Resolution**: spec-updated (plan-level) — the CI step is recorded here
  and in review.md (Gap Ledger fixed-now entry); the addition is a direct
  consequence of FR-006 and stays within the feature's scope guard.

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.

# Drift Log: Iteration 004

**Schema**: v1

<!--
  Markdown authoring note: keep a BLANK LINE between a colon-ending sentence and the
  list that follows it (MD032). Author drift events the same way.
-->

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: None (the review send-back is an implementation-quality rework, not spec drift)

## Events

### D-401 — review send-back: SC-016 deployed-shape + real intake surface + SC-015 marker scope

- **Requirement**: FR-022 (SC-015), FR-023 (SC-016).
- **Observed**: the formal Prop-145 review (maintainer) sent the iteration back with 3 findings: (F1, blocking)
  `Get-SpecrewWorkKindLifecycle` resolved templates from the wrong roots — in the REAL deployed shape
  (catalog + templates under `.specify/extensions/specrew-speckit/`) it returned `Exists=false`; the
  lifecycle files were at repo-root `templates/lifecycle/`, outside the deployed extension tree. (F2,
  blocking) the lifecycle surface was wired only into the work-kind VALIDATOR, which runs too late — a work
  item can start with the agent improvising before the validator ever runs (the surface that caused DF-009
  is intake/start, not the validator). (F3, medium) `Test-RuntimeSurfaceClean` used a FILE-level marker, so
  one labeled block whitewashed a SEPARATE unlabeled `gh pr` elsewhere in `.github/agents/squad.agent.md`.
- **Resolution**: `implementation-reverted` (reworked). F1: moved the 4 lifecycle templates into the
  **extension tree** (`extensions/specrew-speckit/templates/lifecycle/`, which deploys) + the resolver now
  resolves relative to the **extension root** (catalog's parent), working identically in dev + the deployed
  `.specify` shape; the SC-016 test fixture rebuilt in the REAL deployed shape (`.specify/extensions/...`).
  F2: wired the surface into the **refocus engine** (the session-start/intake surface, all 3 copies),
  guarded + fail-open; the test asserts the refocus surface end-to-end in the deployed shape. F3: the
  runtime sweep is now **section-aware** for `gh pr` on `.md` surfaces (Specrew-publish + `.ps1` stay
  file-level); the two Squad-on-GitHub orchestration sections (Triggers, Issue-lifecycle) carry explicit
  section labels. FR-026 was confirmed solid by the reviewer (no change). All reworked + green; the
  validator field kept as a secondary CI surface.

(Pre-existing, OUT of iter-4 scope: `refocus-digests.tests.ps1` "specify.md scopes specrew-gate-stop
verdict routing by host" fails on the baseline with this rework stashed — a gate-stop digest gap
(F-165/F-171/Proposal-188 territory), not work-kind/forge; flagged, not fixed here.)

### Resolution Strategies

- **spec-updated**: available.
- **implementation-reverted**: available.
- **deferred**: available.
- **human-decision**: available.

### Notes

- Iteration 004 reopened Feature 182 before merge for the dogfood-findings completion (FR-022–FR-026).
  The reopen itself is recorded in [../../closeout.md](../../closeout.md) (superseded note) +
  [../../dogfood-findings.md](../../dogfood-findings.md), not as drift.

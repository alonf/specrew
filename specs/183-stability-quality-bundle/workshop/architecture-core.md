# Architecture Core Lens Record: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Date**: 2026-06-15
**Depth**: Medium
**Confirmation**: human-confirmed (lens-question scope)

## Decision Summary

The feature is one governed `software-feature` with bug-bash conduct per
vertical FR slice. It remains a single stability bundle unless capacity planning
proves the amended FR set cannot fit under the 20 SP cap.

## Decomposition

```text
Feature 183: Stability & Quality Bundle
|
+-- A. SessionStart Delivery Path
|     Proposal 179 + Proposal 180 + DirectiveDeliveryCap hermeticity
|     dispatcher/provider/refocus stdout cap and fallback behavior
|
+-- B. Session Identity and Journal State
|     Issue #2446
|     session-id extraction, sanitized fallback, per-session dedupe/breaker keys
|
+-- C. Closeout Sync and Classification
|     Issue #1627 sub-parts a/b/c
|     .specify dirty classification, upstream-aware messaging, dashboard auto-detect
|
+-- D. Mechanical Test Hygiene
|     Issue #1761 reds #2/#3
|     isolated scratch git context, module-internal ValidateSet assertion
|
+-- E. Release and Mirror Discipline
      source <-> deployed .specify mirror parity
      next 0.37.0-beta<N> -> real-host validation -> 0.37.0 stable
+
+-- F. Antigravity Hook Support
      upstream Antigravity hook config -> Specrew RefocusHookBindings/deploy support
      event mapping verified before parity is claimed
```

## Building Blocks

- **SessionStart Delivery Path** — dispatcher/provider/refocus join, hook-output
  cap handling, fail-loud fallback, and delivery-cap test hermeticity.
- **Session Identity and Journal State** — session ID extraction/sanitization,
  `unknown` fallback behavior, per-session dedupe/breaker/journal keys, and
  possible launcher redeploy implications.
- **Closeout Sync and Classification** — `.specify` dirty-surface
  classification, remote/upstream-aware commit-vs-push messaging, and dashboard
  auto-detect regeneration.
- **Mechanical Test Hygiene** — scratch git isolation for closeout identity tests
  and module-internal ValidateSet assertions for lifecycle sync commands.
- **Release and Mirror Discipline** — keep source and deployed extension mirror
  aligned, then publish the next appropriate beta, validate on a real host, and
  promote stable only after validation passes.
- **Antigravity Hook Support** — add Antigravity to Specrew's hook-capable host
  model based on the current official Antigravity hook surface, including config
  deployment, event mapping, tests, and docs cleanup. Parity may be claimed only
  for events whose Antigravity contract is verified.

## Volatility and Isolation

- **Hook cap policy** stays isolated because Proposal 191 may later optimize the
  baseline payload. Proposal 179 is the over-cap backstop, not a broad string
  trimming pass.
- **Fallback directive text** stays centralized so Proposal 180 wording changes
  do not alter dispatcher control flow.
- **Session ID extraction** is isolated so Issue #2446 can replace global
  `unknown` behavior with a per-launch fallback token without scattered changes.
- **Closeout dirty classification** stays in the closeout classifier path rather
  than ad hoc per-file exceptions.
- **Test fixture construction** is hermetic; tests must not measure ambient
  developer machine state.

## Binding Constraints

- Capacity cap remains 20 story points. Split or defer at plan if the six FRs do
  not fit.
- Beta-before-stable remains binding, but the exact beta tag is not hard-coded
  now. Before publish, check current release state and target the next
  appropriate `0.37.0-beta<N>`; stable promotion requires real-host validation
  of that beta.
- SessionStart delivery fixes require runtime evidence, not only unit tests.
- Runtime extension/provider changes must preserve source-to-deployed-mirror
  parity.
- Dogfood uses this worktree via `SPECREW_MODULE_PATH`; no global module upgrade
  or PSGallery dependency during implementation.
- Scope exclusions remain hard unless explicitly amended before planning.
- Amendment 2026-06-16: Antigravity hook support is explicitly added to scope
  after upstream hook support was identified. Planning must size it honestly
  against the 20 SP cap; if it does not fit with the other FRs, the plan must
  split/defer explicitly rather than silently dropping it.

## Out of Scope

- Proposal 191 payload-size optimization spike and durable reduction.
- Proposal 165 / Issue #2081 Claude workshop picker/render residual.
- Proposal 168 Claude boundary-packet Stop hook.
- Issue #78 Squad hardening-gate handoff.
- Proposal 159 Tier 2 optional self-update.
- Proposal 123 verdict-history atomic single-write refactor.
- Issue #1761 red #1 feature-closeout SDLC wording/design row.

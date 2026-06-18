# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-16
**Baseline Ref**: `a8f413d0f2d46deff4fce0965e1d337a96d212d1`
**Review Commit**: `b79b59d8`
**Overall Verdict**: accepted

## Primary Surfaces

| Surface | Files | Tasks | Notes |
| ------- | ----- | ----- | ----- |
| SessionStart cap/fallback and dispatcher fail-open behavior | file:///C:/Dev/183-stability-quality-bundle/scripts/internal/specrew-hook-dispatcher.ps1 plus mirrored dispatcher copies | T001, T003 | Preserves bootstrap/fallback fragments, emits governed fallback, exits 0, and shapes Antigravity output. |
| Session ID normalization and bootstrap state | file:///C:/Dev/183-stability-quality-bundle/scripts/internal/bootstrap/HostEventAdapter.ps1, file:///C:/Dev/183-stability-quality-bundle/scripts/internal/bootstrap/SessionBootstrapManager.ps1 | T003 | Missing, blank, and malformed IDs become per-launch tokens. |
| Hook deploy/status host model | file:///C:/Dev/183-stability-quality-bundle/hosts/, file:///C:/Dev/183-stability-quality-bundle/scripts/internal/deploy-refocus-hooks.ps1, file:///C:/Dev/183-stability-quality-bundle/scripts/internal/specrew-hook-health.ps1 | T006, T011 | `RefocusHookBindings` moves hook config shape and registrations into host manifests. |
| Extension/source mirror copies | file:///C:/Dev/183-stability-quality-bundle/extensions/specrew-speckit/, file:///C:/Dev/183-stability-quality-bundle/.specify/extensions/specrew-speckit/ | T007, T011 | Provider mirror parity passed after the deploy/status and dispatcher changes. |
| Closeout and test hygiene | file:///C:/Dev/183-stability-quality-bundle/scripts/internal/sync-boundary-state.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/integration/ | T004, T005 | Dirty `.specify` classification, no-upstream wording, dashboard refresh, and scratch fixture behavior. |
| Handoff context governance | file:///C:/Dev/183-stability-quality-bundle/extensions/specrew-speckit/prompts/coordinator-response.md, file:///C:/Dev/183-stability-quality-bundle/extensions/specrew-speckit/validators/handoff-governance-validator.ps1, mirrored `.specify` and `.agents` copies | T006, T011 | General downstream five-part context packet support; not a Specrew-only local fix. |
| Review and quality evidence | file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/ | T007, T008, T009, T010 | Mirror parity, release readiness, real-host validation, issue linkage, coverage, and review packet. |

## Hotspots

- file:///C:/Dev/183-stability-quality-bundle/scripts/internal/deploy-refocus-hooks.ps1 and its two mirrors: manifest-driven deploy rewrite.
- file:///C:/Dev/183-stability-quality-bundle/scripts/internal/specrew-hook-health.ps1: hook health derives installed/missing/stale/opted-out state from manifest data.
- file:///C:/Dev/183-stability-quality-bundle/scripts/internal/specrew-hook-dispatcher.ps1: provider fallback, output cap policy, Antigravity output shape, and per-launch session token behavior.

## Public Contract Changes

- `hosts/<kind>/host.psd1` hook-capable hosts now declare `RefocusHookBindings`.
- `Get-SpecrewHookCapableHosts` is capability-driven by manifest data.
- `specrew hooks install/status/remove` now includes Antigravity and reports manifest-driven health.
- Long-work and blocker stops require the five-part context packet:
  `What I just did`, `Why I stopped`, `What needs your review`,
  `What happens next`, and `What I need from you`.

## Review Notes

- The durability commit contains 103 files because DR-004 Option A accepted the
  host-model refactor and downstream context-packet repair into F-183.
- The full baseline-to-review range contains additional already-committed
  planning/spec artifacts; that is expected for this iteration and not an
  uncommitted-evidence warning.

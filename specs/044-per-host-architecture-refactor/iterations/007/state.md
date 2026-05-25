# Iteration State: 007

**Schema**: v1
**Last Completed Task**: T007 (pre-PR final verification — merged main, bumped manifests, ran full integration test suite)
**Tasks Remaining**: (none)
**In Progress**: (none)
**Baseline Ref**: 10c54031
**Updated**: 2026-05-25T00:00:00Z
**Current Phase**: iteration-closeout
**Iteration Status**: complete

**Feature**: F-044 Per-Host Architecture Refactor
**Branch**: `multi-host-integration-refactor`
**Iteration**: 007 — Linux Portability + Docs Sweep + PR Readiness (LIVE-TRACKED)
**Started**: 2026-05-25
**Closed**: 2026-05-25

## Summary

Antigravity's WSL dogfood of v0.27.0 (the iter-006 fixed branch) drove the FULL Specrew lifecycle on Linux end-to-end successfully — methodology milestone. The only friction Antigravity hit was one remaining Windows-only path constant in `scaffold-reviewer-artifacts.ps1` which it patched in its test project. iter-007 canonicalized that fix, audited the codebase for sibling bugs (found one in `evaluation/scorers/process-scorer.ps1`), added the host-switching narrative to the README (user-requested headline differentiator), updated user-guide.md for the v0.27.0 + 4-host state, ran markdown lint sweep on all 72 branch-changed MD files (auto-fixed 9 MD032 violations), added Linux-portability regression assertions to the smoke test, merged origin/main, bumped `.specrew/config.yml` + both extension.yml files to v0.27.0, and pre-created the iter-005 pr-review-resolution.md stub. Validator returns PASS for all 7 closed F-044 iterations.

## What Shipped (post-implement)

- `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1` Linux-portable (DirectorySeparatorChar-driven root prefix + trim length; also fixed line 990's `-replace '/', '\'` to use platform separator)
- `.specify/extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1` mirrored for in-repo dogfooding consistency
- `evaluation/scorers/process-scorer.ps1` line 92 — `'evaluation\report.md'` → `'evaluation/report.md'` (cross-platform Join-Path)
- `README.md` — added "Switch your AI host mid-feature — without losing your place" section near the "Why Specrew" copy; bumped version badge 0.25.0 → 0.27.0; removed duplicate F-043 entry from roadmap
- `docs/user-guide.md` — Multi-Host Launch section bumped to v0.27.0+ with Antigravity row added to flag-translation + capability matrices; launch-shape block extended with `agy` invocation
- `tests/integration/multi-host-lifecycle-smoke.tests.ps1` — added Tests 8, 9, 10 (scaffold-reviewer-artifacts Linux-portable assertion + process-scorer forward-slash assertion + iter-007 parse-check)
- `tests/integration/bootstrap-to-iteration.ps1` — updated 2 assertions to match Crew-neutral bootstrap output ("Add extra Crew members" / "Keep the Specrew-managed baseline charters intact")
- `.specrew/config.yml` — `specrew_version: 0.27.0`
- `extensions/specrew-speckit/extension.yml` + `.specify/extensions/specrew-speckit/extension.yml` — version 0.27.0 (Rule 15 manifest parity)
- `specs/044-per-host-architecture-refactor/iterations/005/pr-review-resolution.md` — placeholder stub created (clears pr-review-integration soft warning)
- All 7 F-044 iteration directories — 9 MD032 violations auto-fixed via `markdownlint --fix`

## Verification

```text
=== iter-007 verification ===
PASS All 8 host-related integration tests
PASS All 12 CI integration tests (after bootstrap-to-iteration assertion fix)
PASS Multi-host lifecycle smoke (iter-006 + iter-007): 10 assertions
PASS PSScriptAnalyzer Error-severity: 0 violations on 3 touched .ps1 files
PASS Markdownlint: 0 violations across 72 branch-changed .md files
PASS Validator (governance): 7/7 iterations (F-043 iter-001 + F-044 iter-001..006)
PASS Antigravity WSL end-to-end test surfaced 1 portability bug; canonicalized in iter-007 T001
```

## Live-tracked retrospective insight

iter-007 found one MORE Antigravity-empirical Linux portability fix than iter-006 (which thought iter-006 closed all of them). The pattern is: each new fresh-environment dogfood surfaces the next-rarest bug class. The methodology lesson is that "no remaining Antigravity patches" is the *empirical* completion test for per-host quality — automated lint + grep can find symptoms but not gaps where an agent had to work around bad Specrew code.

Sibling-bug audit (T002) caught one bug (process-scorer.ps1) that Antigravity hadn't even exercised — proactive grep paid off. ~5 minutes of grep saved a future dogfood surprise.

## Outstanding (deferred)

- `proposals/INDEX.md` entries for F-043 + F-044 + Proposal 108 — deferred to post-PR-merge chore per "proposals always commit to main" rule (already recorded in iter-005 drift-log)
- `dashboard.md` missing-artifact warnings for closed iterations 031/001, 043/001, 044/001..006 — pre-existing across multiple features; dashboard.md generation is its own open follow-up (Proposal 046/048)
- `baseline-hygiene` + `lifecycle-boundary-sync` integration tests pre-existing failures (markdownlint gate halting `Invoke-SpecrewBoundaryStateSync` on auto-fixed `last-start-prompt.md`) — confirmed pre-existing on origin/main; out of iter-007 scope. Candidate for separate small-fix iteration.

# Iteration 006 Drift Log

**Feature**: F-044 | **Iteration**: 006 — Boundary-Sync Hardening + Canonicalize Antigravity's Patches (LIVE-TRACKED)

## Drift #1 — T002 underran significantly (planned 2 SP, actual 0.5 SP)

- **Planned**: Diff Antigravity's project-deployed `.specify/.../scaffold-iteration-plan.ps1` against canonical; triage every change as real-fix vs workaround; apply real fixes back.
- **Actual**: The diff showed exactly ONE small change — Antigravity's StrictMode null-safety fix at line ~371. No other Antigravity-edited Specrew files in the project (verified via `diff -q -r`).
- **Resolution**: Applied the one fix verbatim. Closed in 0.5 SP instead of 2 SP.
- **Lesson**: Agent-applied patches to deployed Specrew code are typically small + surgical. The 2 SP estimate was speculative ("what if Antigravity rewrote half the scaffolder?"). The empirical answer for an LLM agent operating under StrictMode-rejection feedback is: minimal targeted edits. Future "canonicalize agent patches" iterations can budget 0.5-1 SP per agent-discovered fix.

## Drift #2 — `Get-RequirementSummaryMap` graceful-degrade is BEHAVIOR change, not pure refactor

- **Planned (T003)**: "Degrade gracefully when spec lacks canonical FR format".
- **Implemented**: Replaced hard `throw` with `Write-Warning` + FR-PLACEHOLDER row injected into `$requirementSummaries`. iteration plan still scaffolds; downstream consumers (Phase Variance table in retro, etc.) see a placeholder row instead of empty.
- **Behavior impact**: Users who relied on the hard throw to surface mistyped FR formats will no longer get the throw. Mitigation: `Write-Warning` is loud (visible in CI output, captured by validator). Trade-off is correct — Specrew should never block agent-driven iteration scaffold on a fixable spec format issue; it should warn + scaffold + let the user fix the FR format on the next pass.
- **Reviewer disposition**: Accepted as documented behavior change. Will surface in CHANGELOG when v0.28.0 ships.

## Surfaced-but-deferred (recorded for traceability)

- **Agent-autonomy boundary question**: Antigravity self-patched deployed Specrew scaffolders to work around bugs. Should Specrew's coordinator prompt explicitly forbid this? Tracked as candidate methodology proposal — methodology question, not a code bug. Deferred.
- **`scaffold-iteration-artifacts.ps1` quality-artifact behavior**: Antigravity's log probed `Test-PhaseTwoQualityArtifactScaffold` multiple times but no clear bug surfaced. Not changed in iter-006. May warrant iter-007 investigation if user's next dogfood surfaces it.
- **PSGallery publication of v0.27.0**: bundle is ready to PR-to-main; publication to PSGallery is the on-main post-merge step.

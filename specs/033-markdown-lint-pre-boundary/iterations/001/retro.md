# Retrospective: Iteration 001

**Schema**: v1
**Iteration**: 001
**Feature**: 033-markdown-lint-pre-boundary
**Facilitated By**: Retro Facilitator (Alon Fliess via Claude as authoring agent)
**Retro Date**: 2026-05-22
**Baseline Ref**: commit `81df3ae` (spec/plan/tasks scaffolding)
**Delivery Ref**: commit `45116a1` (implementation + tests)

---

## Summary

Feature 033 / Proposal 088 (Markdown Lint Pre-Boundary Auto-Fix Discipline) Iteration 001 delivered the full Pillar 1 + 2 scope — 2 helpers + boundary-sync gate + integration tests + mirror parity. After this slice ships, the catch-fix-retry cycle for markdown lint violations cannot recur at boundary-time — the gate auto-fixes and HALTs before state-file writes.

**Status**: Review-approved implementation delivered; retro complete.

---

## Estimation Accuracy

| Aspect | Planned | Actual | Variance | Notes |
| ------ | ------- | ------ | -------- | ----- |
| Proposal 088 markdown lint gate slice | 5.0 SP | 5.25 SP | +5% | Small overrun on auto-fix detection logic — initial git-diff approach false-positived on untracked files; refactored to SHA256 compare. |

### Effort & Capacity

| Metric | Value | Notes |
| ------ | ----- | ----- |
| Planned Effort | 5.0 SP | Proposal 088's low-end estimate |
| Actual Effort | 5.25 SP | Hash-compare refactor added 0.25 SP |
| Variance | +5% | Within tolerance |
| Capacity Utilization | 26% of 20 SP | Well within capacity |
| Overcommit Risk | None | No deferrals |

---

## Drift Summary

- Total drift events: 0
- Resolution rate: 100% (0/0 resolved)
- Specification drift: None detected
- Review-scope drift findings: None; iteration stayed inside Proposal 088's authorized scope.

---

## What Went Well

### Empirical Pay-Off Visible Up Front

- Proposal 088's motivation was concrete: 47 markdown violations across 3 PRs in 24 hours that hit PR-CI. The gate's value proposition was crystal clear before authoring began.
- Reusing Proposal 083's `Get-SpecrewLocalScopeBaseRef` for the scoping path meant zero new git-scoping logic to write or test.

### Composition Pattern Carries

- The gate-at-boundary-with-directive pattern from Proposal 088 + 090 (just shipped) reuses the same architectural idiom: detect violation → halt with directive → caller fixes and re-runs. Future gates (089 PR Review, possibly 086 P5 repetition detector) will fit the same shape.

### Test Approach Maturity

- The "extract function from script, dot-source, invoke directly" pattern established in F-032's `session-state-boundary-canonical.tests.ps1` carried forward — no need to spin up a full validator fixture; tests focused on the helper's contract.

---

## What Didn't Go Well

### Auto-Fix Detection False-Positive

- Initial implementation used `git diff --quiet` to detect auto-fixed files. This false-positived on untracked files because git considers them "different from index". Test 6 (clean file no-op) failed on first run. **Action**: Refactored to SHA256 hash compare (before/after `--fix`). Lesson: when detecting "did this tool modify this file?", prefer content-based comparison over git-state heuristics, since untracked and pre-existing-modified files both pass `git diff --quiet -- <file>` as "dirty."

### PowerShell Array-Wrapping Footgun

- `$result.AutoFixedFiles = ,@(...)` wraps the result in a single-element outer array, making `.Count` return 1 even when the inner array is empty. Took a debug iteration to spot. **Action**: Drop the leading comma; use plain `@(...)` to construct arrays. Captured as a lesson for future PowerShell helper authors.

---

## Improvement Actions

| Action | Owner | When | Expected Effect |
| ------ | ----- | ---- | --------------- |
| When detecting "did tool modify file?", prefer SHA256-hash compare over `git diff --quiet` to avoid false-positives on untracked files. | PowerShell helper authors | Future similar helpers | Cleaner detection, no false-positives. |
| Avoid `,@(...)` array wrapping unless intentionally preserving array semantics for a single-element return. | PowerShell authors | All scripts | Cleaner type semantics, fewer `.Count` surprises. |
| When Proposal 086 Pillar 1 (memoization) ships, extend `Invoke-MarkdownLintAutoFix` to cache by (file-hash, markdownlint-cli version, .markdownlint.json rules-hash). | Future small-fix slice | Post-086 P1 | Sub-millisecond gate runtime on unchanged files. |

---

## Process Notes

Iteration 001 demonstrated the pattern's portability: Proposal 088's pre-boundary gate reuses Proposal 083's auto-scope helper and Proposal 090's gate-at-boundary-with-directive pattern. Both predecessor proposals shipped in the v0.24.3 process-optimization bundle, so 088 inherits their abstractions cleanly without duplication.

---

## Metrics

| Metric | Value |
| ------ | ----- |
| Implementation Range | `81df3ae...45116a1` |
| Drift Events | 0 |
| Review Verdicts Needs-Work | 0 |
| Test Pass Rate | 100% (7/7 assertions) |
| Scope Adherence | 100% (all 8 FRs delivered) |
| Files Touched | 4 (2 mirrored shared-governance.ps1 + sync-boundary-state.ps1 + new test file) |

---

## Retro Sign-Off

**Closed By**: Retro Facilitator (Alon Fliess via Claude as authoring agent)
**Closed At**: 2026-05-22T06:35:00Z
**Iteration 001 Status**: **RETRO COMPLETE**

---

**Maintained by**: Retro Facilitator
**Next Action**: Iteration-closeout artifacts + feature-closeout (INDEX update + CHANGELOG) + PR open + Copilot review + merge.

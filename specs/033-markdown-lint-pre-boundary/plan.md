# Feature Plan: Markdown Lint Pre-Boundary Auto-Fix Discipline

**Feature**: 033
**Proposal**: [Proposal 088](../../proposals/088-markdown-lint-pre-boundary-auto-fix-discipline.md)
**Branch**: `chore-088-markdown-lint-pre-boundary`
**Created**: 2026-05-22
**Version**: v0.24.3 (process-optimization bundle, slot 2)

## Goal

Add a pre-sync gate to `Invoke-SpecrewBoundaryStateSync` that runs `markdownlint-cli --fix` on changed `.md` files at every boundary. Eliminates the catch-fix-retry cycle that's been costing ~10-15 min per PR by catching lint violations at boundary-time instead of at PR-CI-time.

## Scope

In scope: helpers (`Get-ChangedMarkdownFiles`, `Invoke-MarkdownLintAutoFix`) + boundary-sync integration + tests + CHANGELOG.

Out of scope: auto-commit, memoization, pre-commit hooks, PSScriptAnalyzer auto-fix.

## Iteration Breakdown

Single iteration.

## Phase Breakdown

| Phase | Effort | Tasks |
| ----- | ------ | ----- |
| Helpers in shared-governance.ps1 + mirror | 1.5 SP | T002, T003 |
| Boundary-sync integration | 1.0 SP | T004 |
| Tests | 1.5 SP | T005 |
| Mirror parity + closeout | 1.0 SP | T006, T007 |

**Total: 5.0 story_points** (aligned with Proposal 088's 5-8 SP estimate; targeting the low end).

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Tracked against this iteration's planned/actual effort |
| Capacity per Iteration | 20 | Baseline; this iteration: 5 |
| Iteration Bounding | scope | Keep requirements fixed |
| Time Limit (hours) | n/a | Uses scope-based bounding |
| Overcommit Threshold | 1.0 | Warn when planned > capacity |
| Defer Strategy | manual | Explicit deferral if needed |
| Calibration Enabled | true | Retrospective will suggest capacity adjustments |

## Dependencies

- Proposal 083 (Local Validator Auto-Scope, shipped) — provides `Get-SpecrewLocalScopeBaseRef` reused by `Get-ChangedMarkdownFiles`
- markdownlint-cli (already used by PR-CI Lint job; available via npx)

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22

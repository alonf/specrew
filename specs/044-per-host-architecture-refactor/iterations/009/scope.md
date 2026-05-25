# Iteration 009 Scope

**Feature**: F-044 | **Iteration**: 009 — Bare file:/// URI Enforcement (Smoke-Test Regression Fix) (LIVE-TRACKED)

## Bug-by-bug closure

| Issue | Empirical source | Fix |
|---|---|---|
| **Markdown-link-wrapped `file:///` URIs not clickable in PowerShell terminals** | User pre-smoke-test prep: "I do not get the links to the md files (spec, plan, ...) as clickable file urls. I do not know if PowerShell support the markdown links `[](url)`, but it does support `file:///` urls" | T001 coordinator-governance 14A tightened: explicit "BARE `file:///` URIs, NOT markdown-link form" mandate with example. T002 all 5 agent charters: same bold paragraph added. T003 user-guide.md "What you'll see at every boundary": explicit bare-URI explanation + re-prompt guidance |
| **iter-008's wording was ambiguous** | Same investigation: iter-008 said "use `file:///` URIs" without forbidding wrapping; agents legitimately emitted markdown-link form | Iter-009 tightens the wording, not the meaning |

## What iter-009 surfaced but is NOT in scope

- **Validator hardening for bare-URI enforcement**: a parse rule that flags markdown-link-wrapped file:/// URIs in handoff content. Captured in retro Improvement Actions for future small-fix.
- **Other PowerShell-terminal-incompatible patterns**: agents could emit non-clickable URLs in other shapes (e.g., HTML `<a>` tags, custom-protocol URLs). Not yet observed; not in scope until empirically surfaced.

## Methodology dogfood — sixth LIVE-TRACKED iteration

| Iteration | Pattern | SP planned | SP actual | Variance |
|---|---|---|---|---|
| iter-001 | Backfill | 18 | 18 | 0 (forced) |
| iter-002 | Backfill | 6 | 6 | 0 (forced) |
| iter-003 | Backfill | 4 | 4 | 0 (forced) |
| iter-004 | **LIVE** | 3 | 3 | 0 |
| iter-005 | **LIVE** | 8 | 8 (T007 deferred) | -0.5 |
| iter-006 | **LIVE** | 5.5 | 4 (T002 simpler than planned) | -1.5 |
| iter-007 | **LIVE** | 7 | 7 | 0 |
| iter-008 | **LIVE** | 7 → 10 (mid-iteration expansion) | 10 | 0 (final) |
| iter-009 | **LIVE** | 2.5 | 2.5 | 0 |

iter-009 is the smallest LIVE-tracked iteration in F-044's arc. Calibration insight: when the regression is wording-precision (not methodology evolution), the iteration scope is tiny but worth the ceremony — the durable artifact captures **why** the wording was tightened, preventing regression-of-the-regression-fix in future template edits.

## Cross-feature bundle disclosure

iter-009 ships in the same PR (#844) as F-043's iter-001 + F-044 iter-001..008. Joins PR #844 before the user's manual smoke-test run across all 4 hosts. See [closeout-dashboard.md](../../closeout-dashboard.md).

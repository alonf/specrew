# Iteration 012 Scope

**Feature**: F-044 | **Iteration**: 012 — v0.27.0 Release-Readiness Slice

## Bug-by-bug closure

| Issue | Empirical source | Fix |
|---|---|---|
| **`docs/release-notes-v0.27.0.md` missing** | Doc-readiness audit (2026-05-25) — v0.26.0 has release notes; v0.27.0 doesn't. First public multi-host release without dedicated notes is a publishing-hygiene gap | T003 — author full 5-section release notes |
| **getting-started.md quickstart missing antigravity example** | Audit: lines 78-88 show 3 hosts; missing parity with the table's 4-host claim | T004 — added 4th line for `--host antigravity` example |
| **getting-started.md missing Antigravity-cooperative-gate caveat** | Audit: smoke test empirically showed Antigravity at Gemini Flash tier skipped plan-approval gates and accepted hotfixes outside lifecycle; this isn't documented as a Known Limitation | T004 — added "Antigravity host caveats" entry to Known Limitations section |
| **getting-started.md missing per-host coordinator-overlay note** | Audit: Copilot users get a `.squad/coordinator-overlay.md` file; non-Copilot users don't (functionally equivalent via prompt but less discoverable) | T004 — added per-host overlay note to Known Limitations |
| **proposal-110 collision** | git log inspection on main: `3f2bcd01` (other Claude) and `6f489d8f` (me) both committed proposal-110-*.md files with different content; my INDEX entry registered mine; other Claude's file was on-disk but unlisted | T002 — renumbered my proposal to 112; registered other's 110 in INDEX |
| **INDEX.md feature-branch lagged behind main** | git log: branch was 5 commits behind main; audit ran against stale INDEX state | T001 — merged main into feature branch; INDEX now shows 104/108 shipped + 109/110/111 candidates from main |

## What iter-012 surfaced but is NOT in scope

- **iter-010 PR-review cleanup** (7 Copilot findings) — explicitly deferred per pre-iter-008 decision. Ships as separate small-fix slice OR v0.27.1 patch after merge.
- **Tag + PSGallery publish** — held per user direction "wait for all green before #7". Will happen after CI green on this iter-012 push + user approval.
- **dashboard.md missing-artifact warnings** for 9 closed iterations — pre-existing across multiple features; Proposal 046+048 scope.
- **Antigravity Windows-native smoke test** — empirical Linux/WSL test passed; Windows version pending broader user testing (Known Limitation now documented in release notes).

## Methodology dogfood — eighth LIVE-TRACKED iteration

| Iteration | Pattern | SP planned | SP actual | Variance |
|---|---|---|---|---|
| iter-001 | Backfill | 18 | 18 | 0 (forced) |
| iter-002 | Backfill | 6 | 6 | 0 (forced) |
| iter-003 | Backfill | 4 | 4 | 0 (forced) |
| iter-004 | **LIVE** | 3 | 3 | 0 |
| iter-005 | **LIVE** | 8 | 8 | -0.5 |
| iter-006 | **LIVE** | 5.5 | 4 | -1.5 |
| iter-007 | **LIVE** | 7 | 7 | 0 |
| iter-008 | **LIVE** | 7 → 10 | 10 | 0 (mid-iter expansion) |
| iter-009 | **LIVE** | 2.5 | 2.5 | 0 |
| iter-011 | **LIVE** | 3 | 3 | 0 |
| iter-012 | **LIVE** | 5 | 5 | 0 |

iter-012 hit on plan. Total F-044 iterations: 11 (iter-001..009 + 011 + 012). Total SP: ~70.5.

## Cross-feature bundle disclosure

iter-012 ships in same PR (#844) as iter-001..009 + iter-011. v0.27.0 ships from PR-merge after this iter's CI lands green.

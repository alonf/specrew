# Iteration 011 Scope

**Feature**: F-044 | **Iteration**: 011 — Host Menu Priority Ordering (Smoke-Test Bug Fix) (LIVE-TRACKED)

## Bug-by-bug closure

| Issue | Empirical source | Fix |
|---|---|---|
| **Interactive menu shows antigravity as default (1)** instead of documented `copilot` default | User pre-smoke-test prep 2026-05-25: "menu show the default as 1, Antigravity. The document says that copilot is the default" | T001 add `MenuPriority` to 4 manifests. T002 update `_registry.ps1` to sort by priority. T003 test asserts new order. T004 docs clarify two-defaults model |

## What iter-011 surfaced but is NOT in scope

- **Code-defined ordering remains brittle**: a future 5th host needs to pick a `MenuPriority` value. If priorities collide (two hosts both claim priority=2), fallback is kind-name alphabetical. Adequate for now; if collisions become common, add a validator rule that priorities are unique across hosts. Not iter-011 scope.
- **`--host` non-interactive default remains hardcoded**: `specrew-start.ps1` still falls back to `copilot` in non-TTY contexts via separate code path. The two-defaults model is intentional (Option 1 per user direction). A future iteration could unify both defaults via manifest field (e.g., `IsCIDefault: true` on copilot manifest) but adds methodology surface area without clear benefit. Not iter-011 scope.

## Methodology dogfood — seventh LIVE-TRACKED iteration

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

iter-011 is the tightest scope of any F-044 iteration after iter-009. Pattern: when the bug is a single deterministic root cause with a user-stated fix, the iteration ceremony is small but high-value (durable record of why MenuPriority exists + the two-defaults rationale).

## Cross-feature bundle disclosure

iter-011 joins PR #844 alongside iter-001..009 (iter-010 was reserved for PR-review cleanup, deferred). Ships in v0.27.0.

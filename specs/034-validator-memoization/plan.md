# Feature Plan: Validator Result Memoization

**Feature**: 034
**Proposal**: [Proposal 086 Pillar 1](../../proposals/086-validation-pipeline-performance-bundle.md)
**Branch**: `chore-086-p1-memoization`
**Created**: 2026-05-22
**Version**: v0.24.3 (process-optimization bundle, slot 3)

## Goal

Cache validator per-iteration results in `.specrew/.cache/validator-cache.json` keyed by `(iteration content hash, validator code hash, rules hash)`. Edit-validate-edit loops drop from ~30s to <100ms on cache hits. Would have saved ~80 of 113 min on F-030/083's 4× redundant runs.

## Scope

In scope: 4 helpers + validator integration + `.gitignore` entry + `-NoCacheRead` flag + tests.

Out of scope: cross-developer sharing, per-rule memoization (Pillar 2), TTL/manual purge.

## Phase Breakdown

| Phase | Effort | Tasks |
| ----- | ------ | ----- |
| Cache helpers (key + read + write + code-hash) | 2.0 SP | T002, T003 |
| Validator integration | 1.5 SP | T004 |
| -NoCacheRead + .gitignore | 0.5 SP | T005 |
| Tests | 1.5 SP | T006 |
| Mirror + closeout | 0.5 SP | T007, T008 |

**Total: 6.0 SP** (matches Proposal 086 Pillar 1 estimate).

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Tracked against this iteration's planned/actual effort |
| Capacity per Iteration | 20 | Baseline; this iteration: 6 |
| Iteration Bounding | scope | Keep requirements fixed |
| Time Limit (hours) | n/a | Uses scope-based bounding |
| Overcommit Threshold | 1.0 | Warn when planned > capacity |
| Defer Strategy | manual | Explicit deferral if needed |
| Calibration Enabled | true | Retrospective will suggest capacity adjustments |

## Dependencies

- Proposal 083 (Local Validator Auto-Scope, shipped) — composes with cache (only changed iterations are checked, and cache makes those checks ~instant on hits)
- No new external dependencies

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22

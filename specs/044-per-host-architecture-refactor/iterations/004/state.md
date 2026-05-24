# Iteration State: 004

**Schema**: v1
**Last Completed Task**: T003 (BinaryAliases detection)
**Tasks Remaining**: (none)
**In Progress**: (none)
**Baseline Ref**: 4d0ef055
**Updated**: 2026-05-24T23:30:00Z
**Current Phase**: iteration-closeout
**Iteration Status**: complete

**Feature**: F-044 Per-Host Architecture Refactor
**Branch**: `multi-host-integration-refactor`
**Iteration**: 004 — Host UX Improvements (LIVE-TRACKED)
**Started**: 2026-05-24
**Closed**: 2026-05-24

## Execution Summary

- T001 done: `Invoke-SpecrewFirstRunHostProbe` rewritten — numbered menu (1-N) showing installed hosts first, then non-installed group with install URLs. Backwards-compat: still accepts kind-name input. New helper `Test-SpecrewHostBinaryAvailable` extracted.
- T002 done: `Invoke-SpecrewHostList` rewritten — installed hosts in green group, non-installed hosts in dark-gray group with `(not installed)  (install: <url>)` hints.
- T003 done: `Test-SpecrewHostAvailable` in `detect-hosts.ps1` now probes Binary + BinaryAliases (was Binary-only). Closes the contract-vs-consumer gap where BinaryAliases was declared but unused.
- Smoke-test verified: `specrew host list` shows the user's requested grouping; first-run probe handles installed-count = 0, 1, multiple, and non-TTY cases.
- Parse-check: 3/3 OK on touched files.

## Notes

This is F-044's first LIVE-TRACKED iteration. plan.md was written BEFORE implementation; SP estimates filled at plan-boundary; actuals filled at iteration-closeout (this artifact set). Future iterations follow this same flow.

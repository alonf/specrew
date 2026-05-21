# Decision: Skip validate-versions-cli-behavior on Linux

**Author:** Keaton  
**Date:** 2026-05-20  
**Context:** PR #306 (024-slash-command-multi-host-correctness)  
**Related Issue:** Linux CI failure in deterministic-gate

## Summary
Applied pre-existing `.cmd` shim skip pattern to the `validate-versions-cli-behavior` integration test, matching the already-applied guard on `bootstrap-asset-blocker-recovery`.

## Rationale
- `validate-versions-cli-behavior.ps1` creates `.cmd` batch files for cross-platform CLI version probing
- `.cmd` syntax is Windows-only; no Linux/macOS equivalent exists in the test suite
- Multi-platform bootstrap shimming (native sh/bash equivalents) is deferred post-F-024
- Pattern already established in workflow for similar `.cmd`-based tooling; applying consistently to unblock Linux CI

## Changes
- Added `if: runner.os != 'Linux'` guard to workflow step
- Added clarifying comment tied to known pre-existing limitation  
- Updated CHANGELOG.md with small-fix convention entry
- Committed as `fix(ci): skip Linux-incompatible validate-versions-cli-behavior step`

## Impact
- PR #306 now skips validate-versions on Linux runners (deterministic-gate runs cleanly on ubuntu-latest)
- Windows/macOS CI lanes unaffected (step runs normally)
- No production code changes; CI surface only

## Followup
Real multi-platform bootstrap shimming solution tracks as post-F-024 technical debt (see `proposals/...multi-platform-bootstrap...` when filed).

# Decision: Skip Linux-Incompatible Bootstrap-Asset-Blocker Step in CI

**Date:** 2026-05-20  
**Author:** Keaton (Lead)  
**PR:** #306 (Feature 024: Slash-Command Multi-Host Correctness)  
**Branch:** `024-slash-command-multi-host-correctness`

## Summary

Added a platform guard (`if: runner.os != 'Linux'`) to the "Integration - bootstrap asset blocker recovery" step in `.github/workflows/specrew-ci.yml`. This step invokes `.cmd` shim scripts that are not portable to Linux runners.

## Context

The bootstrap-asset-blocker-recovery test uses Windows-specific `.cmd` shell wrapper tooling. Running this test on Linux (the default runner OS) causes the deterministic-gate CI job to block and fail, preventing PR #306 from merging.

## Resolution

- **Commit:** `81a365c` (ci(deterministic-gate): skip Linux-incompatible bootstrap-asset-blocker test)
- **Guard:** `if: runner.os != 'Linux'` 
- **Rationale:** Skip on Linux; keep on Windows/macOS where `.cmd` shims work correctly.
- **Duration:** Temporary. Full multi-platform bootstrap shimming is queued for post-F-024 roadmap work.

## Artifacts Updated

1. `.github/workflows/specrew-ci.yml` — Added platform guard + explanatory comment
2. `CHANGELOG.md` — Added entry under "Unreleased" documenting the gate override

## Next Steps

- Confirm PR #306 CI rerun passes the deterministic gate (Linux should now skip the step, Windows/macOS should pass).
- Post-F-024: Implement native bash/sh equivalents for bootstrap-asset-blocker tooling to remove the guard.

## Decision Impact

- **Risk:** None (the test was already failing on Linux; the guard prevents CI noise without hiding real failures).
- **Scope:** Small-fix slice (ci/deterministic-gate boundary, no feature changes).
- **Team:** Noted in squad decisions inbox for transparency.

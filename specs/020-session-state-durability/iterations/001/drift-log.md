# Drift Log: Iteration 001

**Schema**: v1

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1 resolved)
**Specification drift**: none
**Status**: resolved

## Notes

### Event 2026-05-18 — Version mismatch warning not observable in CI

- **Status**: resolved
- **Category**: implementation-drift
- **Detected by**: `tests/integration/version-checks.tests.ps1`
- **Affected artifacts**:
  - `scripts/specrew-start.ps1`
- **Description**: The Iteration 001 version-mismatch lane implemented the FR-026 warning string, but the warning did not surface in the integration harness because `Get-InstalledSpecrewVersion` only checked PowerShell module inventory or a project-local `Specrew.psd1`. In the test fixture, the running Specrew scripts came from the repository checkout rather than an installed module, so the warning path never activated.
- **Resolution path**:
  - Added a running-module manifest fallback (`<repo-root>\Specrew.psd1`) before the project-local manifest lookup so `specrew start` can resolve the current Specrew version even when the module is not installed into PowerShell's module path.
  - Emitted the non-blocking mismatch warning on standard output so the integration harness captures the exact `Module version mismatch detected` text required by FR-026.
- **Validation**:
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\version-checks.tests.ps1`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\stale-state-detection.tests.ps1`
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\boundary-sync-atomicity.tests.ps1`
- **Target disposition**: implementation-repaired
- **Resolved At**: 2026-05-18T01:20:06+03:00
- **Resolution Notes**: This repair stayed inside the authorized Iteration 001 lane (FR-025 through FR-028) and did not touch the deferred PSGallery latest-version work (FR-029+).

## Resolution Strategies

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **implementation-repaired**: Repair implementation to deliver promised behavior
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

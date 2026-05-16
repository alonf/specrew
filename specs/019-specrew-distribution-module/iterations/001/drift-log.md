# Drift Log: Iteration 001

**Schema**: v1

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: 0 open implementation-vs-contract drifts; the review-discovered allowlist drift has been repaired and revalidated

## Events

### Event 2026-05-16 — Explicit `FileList` allowlist drift discovered at review boundary

- **Status**: resolved
- **Category**: implementation-drift
- **Detected by**: independent review boundary for Iteration 001
- **Affected artifacts**:
  - `Specrew.psd1`
  - `tests\integration\distribution-module-init.ps1`
  - `tests\integration\distribution-module-publish.ps1`
  - `specs\019-specrew-distribution-module\iterations\001\review.md`
- **Description**: The approved T001/T010/T013 distribution contract relies on an explicit `FileList` allowlist, but review comparison against the working tree found real distributable files still missing from `Specrew.psd1`. The missing set included `scripts\internal\invoke-module-release.ps1`, `templates\github\agents\squad.agent.md`, and the additional docs / extension README surfaces named by review. The original integration tests masked the drift because they staged full directory trees instead of a manifest-driven package surface.
- **Impact**: Review could not truthfully sign off FR-006 through FR-009 package-bundling claims or the installed-module bootstrap / publish evidence until the allowlist and the package-surface tests were repaired together.
- **Resolution path**: bounded repair items `R-019-R1` and `R-019-R2` in `iterations\001\review.md`
- **Target disposition**: implementation-reverted (repair implementation/tests to match the approved explicit allowlist strategy)
- **Resolved At**: 2026-05-16T20:25:00Z
- **Resolution Notes**: `Specrew.psd1` now allowlists the missing shipped files, `distribution-module-init.ps1` and `distribution-module-publish.ps1` stage scratch workspaces from the manifest-defined package surface, and the repaired lane revalidated with `Test-ModuleManifest`, both integration tests, and `validate-governance.ps1 -IterationPath`.

### Resolution Strategies

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- The implementation stayed inside the approved Windows-first scope; the review blocker was contract parity, not unauthorized scope widening.
- T041 / T054 remain deferred, and T042 / T053 remain human/manual follow-up only.
- This drift log now records a resolved review-repair event rather than an open blocker narrative.

# Drift Log: Iteration 001

**Schema**: v1

## Summary

**Total drift events**: 1
**Resolution rate**: 0% (0/1 resolved)
**Specification drift**: 1 open implementation-vs-contract drift discovered during review

## Events

### Event 2026-05-16 — Explicit `FileList` allowlist drift discovered at review boundary

- **Status**: open
- **Category**: implementation-drift
- **Detected by**: independent review boundary for Iteration 001
- **Affected artifacts**:
  - `Specrew.psd1`
  - `tests\integration\distribution-module-init.ps1`
  - `tests\integration\distribution-module-publish.ps1`
  - `specs\019-specrew-distribution-module\iterations\001\review.md`
- **Description**: The approved T001/T010/T013 distribution contract relies on an explicit `FileList` allowlist, but review comparison against the working tree found real distributable files still missing from `Specrew.psd1`. The missing set includes at least `scripts\internal\invoke-module-release.ps1` and `templates\github\agents\squad.agent.md`, plus additional docs / extension README surfaces. The current integration tests masked the drift because they stage full directory trees instead of a manifest-driven package surface.
- **Impact**: Review cannot truthfully sign off FR-006 through FR-009 package-bundling claims or the installed-module bootstrap / publish evidence until the allowlist and the package-surface tests are repaired together.
- **Resolution path**: bounded repair items `R-019-R1` and `R-019-R2` in `iterations\001\review.md`
- **Target disposition**: implementation-reverted (repair implementation/tests to match the approved explicit allowlist strategy)

### Resolution Strategies

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- The implementation stayed inside the approved Windows-first scope; the review blocker is contract parity, not unauthorized scope widening.
- T041 / T054 remain deferred, and T042 / T053 remain human/manual follow-up only.
- This drift log now supersedes the earlier zero-drift placeholder narrative for Iteration 001.

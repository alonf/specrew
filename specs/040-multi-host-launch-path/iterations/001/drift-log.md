# Iteration 001 Drift Log: Multi-Host Launch Path

**Feature**: F-040 | **Iteration**: 001 | **Date**: 2026-05-23

## Drift entries

### DRIFT-001: `$Host` PowerShell automatic-variable clash

**Discovered during**: T002-T007 implementation, surfaced in test execution.
**Drift type**: implementation-discovery (not spec-vs-implementation).
**Description**: The initial implementation used `$Host` as a parameter name across the new helper scripts (`detect-hosts.ps1`, `host-flag-translation.ps1`, `coordinator-prompt-surgery.ps1`) and the top-level `specrew-start.ps1` parameter. PowerShell's `$Host` is a read-only constant automatic variable representing the runspace's host. Under `Set-StrictMode -Version Latest`, parameter binding to `$Host` triggers "Cannot overwrite variable Host because it is read-only or constant."
**Reconciliation**: Renamed parameter to `-HostKind` everywhere; CLI alias `--host` retained for user-facing surface. Loop variables `$host` (lowercase, same automatic) renamed to `$hk` or `$kind`. Documented in retro.md "What was hard" + lessons-learned for future Specrew PowerShell code.
**Impact on spec**: None. Spec referenced `-Host` parameter; the user-facing CLI surface `--host` is unchanged. Internal parameter name is implementation detail.

### DRIFT-002: Double-replacement bug in bulk rename

**Discovered during**: T009 test execution after global `$Host` → `$HostKind` replace.
**Drift type**: tooling-error during refactor.
**Description**: First global replace of `$Host` → `$HostKind` ran successfully. A second invocation (intended for callers in other files) re-ran on already-renamed code, producing `$HostKindKind`. Caught by test execution.
**Reconciliation**: Fixed via targeted replace `$HostKindKind` → `$HostKind`. Re-ran tests; all 15 assertions pass.
**Impact on spec**: None. Pure implementation issue.

### DRIFT-003: Spec said `[string]$Host` parameter; implementation uses `[string]$HostKind`

**Discovered during**: T001 implementation.
**Drift type**: spec-vs-implementation cosmetic.
**Description**: Spec.md and plan.md reference `-Host` as the PowerShell parameter name (e.g., FR-001: "specrew start MUST accept a `-Host <kind>` parameter"). Per DRIFT-001 the parameter was renamed to `-HostKind` to avoid clash with PowerShell's automatic variable. CLI alias `--host` unchanged.
**Reconciliation accepted**: The user-facing CLI surface (`--host copilot`) is what FR-001 cares about; the PowerShell parameter NAME is implementation detail. Documented in retro + this drift log. No spec update needed because the spec's `-Host` reference was inherited from research.md's per-host-CLI-flag table (where `-Host` referred to a hypothetical Specrew flag, not a PowerShell parameter).

## Reconciliation summary

All drift entries reconciled in-iteration. No deferred drift. No spec amendment required because the user-facing contract (`--host` flag, behavior per FR-001 through FR-015) is unchanged.

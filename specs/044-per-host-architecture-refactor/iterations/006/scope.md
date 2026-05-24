# Iteration 006 Scope

**Feature**: F-044 | **Iteration**: 006 — Boundary-Sync Hardening + Canonicalize Antigravity's Patches (LIVE-TRACKED)

## Bug-by-bug closure

| Bug | Empirical source | Fix |
|---|---|---|
| **Stale-install silent dispatch** | Antigravity iter-005 session: shim found 0.25.0 PSGallery install; internal helpers lacked v0.27.0 boundary types; agent got stuck searching for the "right" module | T001 — env-override + walk-up + ListAvailable resolution chain + version comparison refuses dispatch if installed < project-expected |
| **Agent-spawned child shells can't find Dev tree** | Antigravity ran `powershell -File <shim>`; new session, no imported modules, Get-Module returned empty | T001 — Specrew.psm1 sets `$env:SPECREW_MODULE_PATH` on import → child processes inherit it → shim resolves via env override |
| **`$RequirementScope` StrictMode null-binding crash** | Antigravity hit StrictMode error on `if ($RequirementScope -and ...)` when no scope passed; patched its deployed copy | T002 — canonicalized fix: `$null -ne $RequirementScope -and $RequirementScope.Count -gt 0` |
| **Hard throw on zero canonical FRs** | Antigravity wrote spec in prose, hit `throw "No functional requirements"`, had to rewrite spec with `- **FR-NNN**: ...` bullets | T003 — Write-Warning + FR-PLACEHOLDER row; iteration plan still scaffolds; retro can land |
| **No automated regression coverage** | Antigravity's session was the only "test"; would re-break on next user-test cycle | T004 — `multi-host-lifecycle-smoke.tests.ps1` 7 assertions covering all 4 fixes |

## What Antigravity surfaced but is NOT in iter-006 scope

- **Antigravity's own task management UX** (it created internal "tasks" via `ManageTask`): out-of-scope, Antigravity-CLI-specific.
- **Agent autonomy boundary** (Antigravity self-patched deployed scaffolders rather than reporting them): tracked as candidate proposal — should Specrew's coordinator prompt explicitly forbid agents from editing deployed `.specify/...` files? Methodology question, deferred.
- **`scaffold-iteration-artifacts.ps1` quality-artifact behavior**: Antigravity's log showed `Test-PhaseTwoQualityArtifactScaffold` probe + multiple re-reads; no clear bug surfaced in the diff. Not changed in iter-006.

## Methodology dogfood — third LIVE-TRACKED iteration

| Iteration | Pattern | SP planned | SP actual | Variance |
|---|---|---|---|---|
| iter-001 | Backfill | 18 | 18 | 0 (forced zero) |
| iter-002 | Backfill | 6 | 6 | 0 (forced zero) |
| iter-003 | Backfill | 4 | 4 | 0 (forced zero) |
| iter-004 | **LIVE** | 3 | 3 | 0 |
| iter-005 | **LIVE** | 8 | 8 (-0.5 on T007 → deferred) | -0.5 |
| iter-006 | **LIVE** | 5.5 | 4 (T002 was 0.5 not 2 — simpler than planned) | -1.5 |

iter-006's T002 underran significantly: I'd budgeted 2 SP for diffing + triaging Antigravity's patches, but the diff showed only ONE small line-level change. Real signal that **canonicalizing agent-applied patches** is cheaper than I'd estimated when the agent's edits are small + surgical. Calibration data for future agent-discovered-fix iterations.

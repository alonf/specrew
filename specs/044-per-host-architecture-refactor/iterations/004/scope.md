# Iteration 004 Scope

**Feature**: F-044 | **Iteration**: 004 — Host UX Improvements (LIVE-TRACKED)

## User-surfaced concerns addressed

1. **Numbered menu for `specrew start` host selection** — user wanted 1/2/3 numeric input instead of typing kind names. Closed by T001.
2. **`specrew host list` should sort installed first + show non-installed group** — user wanted installed hosts up top, then a `(not installed)` section showing install URLs. Closed by T002.
3. **Proactive: BinaryAliases declared but unused** — contract documents `BinaryAliases` field; all 3 detection sites only checked `Binary`. Closed by T001 (helper) + T002 (host list) + T003 (`Test-SpecrewHostAvailable`).

## Task → user concern mapping

| Task | Closes | Files |
| ---- | ------ | ----- |
| T001 | Concerns 1 + 3 (helper) | `scripts/internal/host-history.ps1` |
| T002 | Concern 2 | `scripts/specrew-host.ps1` |
| T003 | Concern 3 (consumer parity) | `scripts/internal/detect-hosts.ps1` |

## Out of iter-004 scope

- **Cross-environment host detection** (e.g., detect `agy` installed in WSL from Windows PowerShell): out of scope. Specrew correctly probes only the PATH of its current shell. Cross-environment detection is a proposal-scale feature, not a UX fix.
- **`specrew host install <kind>`**: not implemented. Current "install URL" hints point users to the host vendor's installer; orchestrating the actual install is a separate UX scope.
- **Bug 7e (Copilot "3 skills failed" beyond `iteration-resume`)**: still queued from iter-003 retro — needs reproduction against current Copilot CLI which user can't do until weekly quota refills.

## Verification

Smoke test (`.scratch/iter004-smoke.ps1`):

- `Test-SpecrewHostBinaryAvailable` returns correct binary name or `$null` for each host on the user's PATH.
- `Test-SpecrewHostAvailable` (detect-hosts) matches `Test-SpecrewHostBinaryAvailable` (host-history) for every host — no consumer-vs-helper divergence.
- First-run probe non-interactive: returns `non-interactive-no-default` when ≥2 hosts available + no TTY (matches FR-013).
- `specrew-host.ps1 -Subcommand list`: produces the exact two-group output the user requested.

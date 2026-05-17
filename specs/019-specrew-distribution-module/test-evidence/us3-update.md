# US3 Update Evidence

**Iteration**: 001  
**Scope**: Windows-first update and template-refresh behavior  
**Status**: validated

## Evidence Summary

1. **Installed-module update scenario**
   - Command: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\distribution-module-update.ps1`
   - Result: PASS
   - Verified outcomes:
     - module-only template changes refresh in place
     - user-only template changes are preserved
     - both-modified templates receive Git-style conflict markers
     - matching `.specrew\template-conflicts\*.conflict` artifacts are emitted
     - deleted templates emit `.deletion` review artifacts
     - `.specrew\config.yml` records the refreshed Specrew version
     - `specrew start` surfaces unresolved template-refresh artifacts in the next-session prompt

2. **Command-surface update behavior**
   - Command: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\update-command.ps1`
   - Result: PASS
   - Verified outcomes:
     - `specrew update --info` is read-only
     - bare `specrew update` refreshes Specrew-managed assets only
     - `specrew update --all` respects explicit upgrade scopes

## Iteration 001 Truth Note

- The checklist item originally said "template-refresh dry-run"; the shipped command surface does not expose a dedicated `--dry-run` flag in Iteration 001.
- The executed installed-module regression fixture above is the truthful Windows-first evidence for the expected diff/artifact behavior.

# Quickstart: checking 206's fixes

Every command runs from the worktree root, with PowerShell 7. Before and after any test run, hash the home
hook files (SC-007): `~/.specrew/specrew-hook-launch.ps1`, every file in `~/.specrew/hook-bindings/`,
`~/.codex/hooks.json`, `~/.copilot/hooks/*.json`, `~/.cursor/hooks.json`. Any change stops the work.

| Criterion | How it is checked |
| --- | --- |
| SC-001 | `pwsh -File tests/integration/project-path-resolution-regression.ps1` ends green without a timeout; its no-console stale-state case gets the plain refusal and a non-zero exit |
| SC-002 | `pwsh -File tests/integration/validator-hardening-iteration2.ps1` passes all three B5F-036 assertions |
| SC-003 | `$env:CI='true'; ./extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath . -FullRun` reports no failure; any warning for a closed iteration names a frozen entry or is gone |
| SC-004 | add an unregistered `tests/integration/zz-probe.ps1` (any name); the lane guard fails; remove it; the guard passes |
| SC-005 | add a key to `.specrew/legacy-frozen.yml`; its guard test fails |
| SC-006 | the resolver run on this repository with feature 201's spec selects no Node or React preset; the moved stack-detection assertion passes on its fixture |
| SC-007 | the home hook-file hashes match before and after every run above |

Condition checks from the design verdict:

- **Closed-definition table**: `specs/206-bug-bash/iterations/001/closed-definition-table.md`, produced
  before the definition changes; the SC-003 replay shows no new finding from any row whose answer changed.
- **Frozen means judged by nothing**: the frozen-list Pester suite asserts zero validator findings for each
  of the 18 entries.
- **Matched markers**: the change-classifier suite covers a matched block, a missing or unbalanced marker,
  and a user change outside the markers.
- **Private-free issue**: the notifier suite renders the title, body and comments for a red night and asserts
  no paths and no user or machine names; the workflow grants `issues: write` only to the notifier job.

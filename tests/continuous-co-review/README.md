# Continuous Co-Review Tests

These tests belong to Proposal 197's reviewer-domain spine. They intentionally stay under `tests/continuous-co-review/` and exercise only local PowerShell, JSON fixtures, and repository contracts.

## Local invocation

The Beta2 release gate is the explicit, process-isolated F-198 registry. From the repository root:

```powershell
pwsh -NoProfile -File ./tests/f198-regression-suite.ps1
```

That bounded manifest runs each suite in a fresh child process and names the exact contracts on which the Beta2 honesty bar depends. Do not substitute `Invoke-Pester -Path 'tests/continuous-co-review'`: the directory also retains pre-campaign legacy characterization files and intentionally non-gating proposal tests whose assumptions are incompatible in one shared Pester process after the one-way campaign-authority cutover.

For one current Pester file, invoke that file directly in a fresh PowerShell process, for example:

```powershell
$env:SPECREW_MODULE_PATH = (Get-Location).Path
$result = Invoke-Pester -Path 'tests/continuous-co-review/unit/review-public-campaign-command.Tests.ps1' -Output Detailed -PassThru
exit ([int]$result.FailedCount)
```

For the Iteration 001 contract slice only:

```powershell
Invoke-Pester -Path 'tests/continuous-co-review/contracts/reviewer-contracts.Tests.ps1'
```

## Fixture ownership

- `tests/continuous-co-review/fixtures/contracts/` contains producer and consumer examples for the Proposal 197 DTO contracts.
- Fixtures are owned with the contract tests. When a schema changes compatibly, update producer and consumer examples together.
- Fixtures must not contain secrets, raw provider transcripts, raw prompts, environment variables, token stores, or live provider output.

## Protected-surface guard

Use the protected-surface precheck before handing changes to review:

```powershell
git --no-pager status --short
git --no-pager diff --name-only
```

The changed-file list must not include F-184 protected host, hook, provider, registry, refocus, shared-governance, mirrored `.specify/extensions/specrew-speckit/scripts/` files, or `validate-governance.ps1`.

## Future composition target

Proposal 197 keeps local contract hooks and fixtures ready for a future Proposal 181 plus Proposal 194 canary composition target. This directory does not add automated live cross-host CI, scheduled provider smoke tests, brokered-key automation, or drift-canary automation.

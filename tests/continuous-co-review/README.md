# Continuous Co-Review Tests

These tests belong to Proposal 197's reviewer-domain spine. They intentionally stay under `tests/continuous-co-review/` and exercise only local PowerShell, JSON fixtures, and repository contracts.

## Local invocation

From the repository root:

```powershell
$testTemp = New-Item -ItemType Directory -Force -Path '.scratch/tmp'
$env:TEMP = $testTemp.FullName
$env:TMP = $testTemp.FullName
$env:SPECREW_MODULE_PATH = 'C:\Dev\197-continuous-co-review'
Import-Module 'C:\Dev\197-continuous-co-review\Specrew.psd1' -Force
Invoke-Pester -Path 'tests/continuous-co-review'
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

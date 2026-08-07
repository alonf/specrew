#!/usr/bin/env pwsh
# F-198 Prop-145 CROSS-PLATFORM VERIFICATION entry point - REPLAYABLE FROM A FRESH CHECKOUT on Windows OR Linux:
#
#   pwsh -File tests/cross-platform-verify.ps1
#
# Runs the hook-health redesign's focused unit suites (Pester) + the production-path integration script, and exits
# 0 iff all are green (non-zero otherwise), so it can be recorded through the T018 recorded-run wrapper against the
# committed reviewed digest on BOTH operating systems. Pester 5.6.1 is installed to CurrentUser if absent (so it
# runs in a bare pwsh container); the ubuntu CI and a normal dev checkout already have Pester + git. `git` is a
# prerequisite (any checkout has it; the test-evidence-recorder suite exercises the git-bound recorded-run digest).
#
# The optional -Label is a no-op differentiator so a Windows and a Linux recorded run key to DISTINCT entries in the
# same digest record (the T018 runner keys runs by executable+arguments).
[CmdletBinding()]
param([string]$Label = '')

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Write-Host ("=== cross-platform-verify  pwsh=$($PSVersionTable.PSVersion)  IsWindows=$IsWindows  label='$Label' ===")

if (-not (Get-Module -ListAvailable Pester | Where-Object { $_.Version -ge [version]'5.0' })) {
    Set-PSRepository PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    Install-Module Pester -RequiredVersion 5.6.1 -Force -Scope CurrentUser -SkipPublisherCheck -ErrorAction Stop
}
Get-Module Pester -All | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module Pester -MinimumVersion 5.0 -Force

$fail = 0
$units = @(
    'tests/continuous-co-review/unit/hook-health-receipt.Tests.ps1',
    'tests/continuous-co-review/unit/codex-headless-preflight.Tests.ps1',
    'tests/continuous-co-review/unit/host-support-reconciliation.Tests.ps1',
    'tests/continuous-co-review/unit/test-evidence-recorder.Tests.ps1',
    # 2026-07-14 (maintainer f2/f3 residual decision): the verification-plan child-environment (empty-map +
    # evidence-justified engine baseline) and the recorder's private-by-default output contract carry PAIRED
    # cross-platform evidence - these suites ARE that evidence and MUST run on both OSes.
    'tests/continuous-co-review/unit/verification-plan-contract.Tests.ps1',
    'tests/continuous-co-review/unit/verification-plan-runner.Tests.ps1',
    'tests/continuous-co-review/unit/recorded-run.Tests.ps1'
)
foreach ($u in $units) {
    $c = New-PesterConfiguration; $c.Run.Path = (Join-Path $repo $u); $c.Output.Verbosity = 'None'; $c.Run.PassThru = $true
    $r = Invoke-Pester -Configuration $c
    Write-Host ("{0} -> passed={1} failed={2} skipped={3}" -f (Split-Path -Leaf $u), $r.PassedCount, $r.FailedCount, $r.SkippedCount)
    $fail += [int]$r.FailedCount
}

# production-path (a 'script' suite; run in an isolated child so its exit code is captured).
& pwsh -NoProfile -File (Join-Path $repo 'tests/integration/f198-iter005-hook-health-production-path.tests.ps1')
$pp = $LASTEXITCODE
Write-Host "production-path -> exit=$pp"
if ($pp -ne 0) { $fail++ }

Write-Host ''
if ($fail -gt 0) { Write-Host ("CROSS-PLATFORM VERIFY: FAILED ({0})" -f $fail) -ForegroundColor Red; exit 1 }
Write-Host 'CROSS-PLATFORM VERIFY: OK' -ForegroundColor Green
exit 0

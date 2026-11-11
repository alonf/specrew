# Self-test of the feature 203 sweep driver (crew maintenance tooling; not packaged). Maintainer rulings 2026-11-11 on
# DRIFT-055 and the index.lock trace:
#   1. The sweep runs every suite the sign-off lanes name (.specrew/verification-plan.signoff-lanes.json at the swept
#      revision), with the list it was given.
#   2. Standby is detected per suite by comparing its wall-clock seconds with its awake seconds; a difference above a
#      small threshold marks it "spanned standby, rerun", never pass or fail. Both numbers are reported. A sweep with
#      such a suite is not valid to close a task. (The power log is supporting evidence in the report only.)
#   3. While a sweep runs, the driver holds a keep-awake request with Windows (system required; the display may sleep)
#      and releases it in a finally block, on error and on cancel too. Cases 5 and 6 prove the release.
# Plain script; run it with pwsh -File. Written first: before sweep-support.ps1 exists every case fails.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$repo = (Resolve-Path (Join-Path $here '../../..')).Path
$support = Join-Path $here 'sweep-support.ps1'
$sweepFull = Join-Path $here 'sweep-full.ps1'
$runSuites = Join-Path $here 'run-suites.ps1'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

if (-not (Test-Path -LiteralPath $support -PathType Leaf)) {
    Write-Fail 'sweep-support.ps1 exists beside the driver'
    Write-Host 'sweep-driver: 1 failure (nothing else can run)' -ForegroundColor Red
    exit 1
}
. $support
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('sweep-selftest-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $scratch | Out-Null
$savedTrace = $env:SPECREW_SWEEP_KEEPAWAKE_TRACE
try {
    Write-Host 'Case 1: a suite is marked as spanning standby only when its wall time exceeds its awake time by more than the threshold'
    Assert-True ((Get-SweepStandbyVerdict -WallSeconds 63 -AwakeSeconds 63 -ThresholdSeconds 20) -eq '') 'equal wall and awake time: no mark'
    Assert-True ((Get-SweepStandbyVerdict -WallSeconds 83 -AwakeSeconds 63 -ThresholdSeconds 20) -eq '') 'a difference equal to the threshold: no mark'
    Assert-True ((Get-SweepStandbyVerdict -WallSeconds 84 -AwakeSeconds 63 -ThresholdSeconds 20) -eq 'spanned standby, rerun') 'a difference above the threshold: marked'
    Assert-True ((Get-SweepStandbyVerdict -WallSeconds 3528 -AwakeSeconds 63 -ThresholdSeconds 20) -eq 'spanned standby, rerun') 'the 2026-11-10 coverage run (3,528 s wall, about 63 s awake): marked'

    Write-Host 'Case 2: the awake clock keeps pace with the wall clock while the machine is awake'
    $a0 = Get-SweepAwakeSeconds; $w0 = [DateTime]::UtcNow
    Start-Sleep -Milliseconds 1500
    $a1 = Get-SweepAwakeSeconds; $w1 = [DateTime]::UtcNow
    $awake = $a1 - $a0; $wall = ($w1 - $w0).TotalSeconds
    Assert-True ($awake -gt 1.0 -and [Math]::Abs($wall - $awake) -lt 0.5) ("awake {0:N2} s against wall {1:N2} s" -f $awake, $wall)

    Write-Host 'Case 3: each suite line reports wall and awake seconds; the summary says whether the sweep may close a task'
    $fakeRepo = Join-Path $scratch 'repo'
    New-Item -ItemType Directory -Force -Path (Join-Path $fakeRepo 'tests') | Out-Null
    Set-Content -LiteralPath (Join-Path $fakeRepo 'tests/quick.ps1') -Value "Write-Host 'quick'; exit 0" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $fakeRepo 'tests/red.ps1') -Value "Write-Host 'FAIL: red'; exit 1" -Encoding UTF8
    $list = Join-Path $scratch 'list.txt'
    Set-Content -LiteralPath $list -Value @('tests/quick.ps1', 'tests/red.ps1') -Encoding UTF8
    $out = @(& pwsh -NoProfile -File $runSuites -ListFile $list -Repo $fakeRepo -Throttle 2 -SuiteTimeoutSeconds 60 2>&1 | ForEach-Object { [string]$_ })
    $quick = @($out | Where-Object { $_ -like '=== tests/quick.ps1 *' })
    Assert-True ($quick.Count -eq 1 -and $quick[0] -match 'wall \d+ s, awake \d+ s') ("the suite line carries both numbers ({0})" -f ($quick -join ''))
    Assert-True (@($out | Where-Object { $_ -match '^--- 2 suite\(s\), 1 failed, 0 known red, 0 spanned standby' }).Count -eq 1) ("the summary counts suites that spanned standby ({0})" -f (($out | Where-Object { $_ -like '--- *' }) -join ' | '))
    Assert-True (@($out | Where-Object { $_ -eq '--- valid to close a task: yes (no suite spanned standby)' }).Count -eq 1) 'with none, the sweep may close a task'

    Write-Host 'Case 4: the keep-awake request is taken and released once'
    $trace4 = Join-Path $scratch 'trace4.txt'
    $env:SPECREW_SWEEP_KEEPAWAKE_TRACE = $trace4
    $request = Enter-SweepKeepAwake -Reason 'sweep self-test case 4'
    Assert-True ([bool]$request.Active -or -not $IsWindows) ("the request is held on Windows ({0})" -f [string]$request.Detail)
    Exit-SweepKeepAwake -Request $request
    Exit-SweepKeepAwake -Request $request
    $lines4 = @(Get-Content -LiteralPath $trace4)
    Assert-True ($lines4.Count -eq 2 -and $lines4[0] -like 'acquire *' -and $lines4[1] -like 'release *') ("acquired, then released once ({0})" -f ($lines4 -join ' | '))

    Write-Host 'Case 5: a sweep that fails releases the request'
    $trace5 = Join-Path $scratch 'trace5.txt'
    $env:SPECREW_SWEEP_KEEPAWAKE_TRACE = $trace5
    $null = & pwsh -NoProfile -File $sweepFull -Rev 'no-such-revision-zz' -List $list -SkipLanes 2>&1
    $exit5 = $LASTEXITCODE
    $lines5 = @(if (Test-Path -LiteralPath $trace5) { Get-Content -LiteralPath $trace5 })
    Assert-True ($exit5 -ne 0) "the sweep of a revision that does not exist fails (exit $exit5)"
    Assert-True ($lines5.Count -eq 2 -and $lines5[0] -like 'acquire *' -and $lines5[1] -like 'release *') ("it held the request and released it ({0})" -f ($lines5 -join ' | '))

    Write-Host 'Case 6: a sweep that is cancelled releases the request'
    $trace6 = Join-Path $scratch 'trace6.txt'
    $env:SPECREW_SWEEP_KEEPAWAKE_TRACE = $trace6
    $ps = [PowerShell]::Create()
    $null = $ps.AddCommand($sweepFull).AddParameter('Rev', 'HEAD').AddParameter('List', $list).AddParameter('SkipLanes').AddParameter('SelfTestHoldSeconds', 60)
    $handle = $ps.BeginInvoke()
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    while ([DateTime]::UtcNow -lt $deadline -and -not ((Test-Path -LiteralPath $trace6) -and @(Get-Content -LiteralPath $trace6) -match '^acquire ')) { Start-Sleep -Milliseconds 200 }
    $held6 = (Test-Path -LiteralPath $trace6) -and (@(Get-Content -LiteralPath $trace6) -match '^acquire ').Count -gt 0
    $ps.Stop()
    try { $null = $ps.EndInvoke($handle) } catch { $null = $_ }
    $ps.Dispose()
    $lines6 = @(if (Test-Path -LiteralPath $trace6) { Get-Content -LiteralPath $trace6 })
    Assert-True $held6 'the request was held while the sweep ran'
    Assert-True ($lines6.Count -eq 2 -and $lines6[1] -like 'release *') ("cancelling the sweep released it ({0})" -f ($lines6 -join ' | '))

    Write-Host 'Case 7: the sweep list includes every suite the sign-off lanes name at the swept revision'
    $named = @(Get-SweepSignoffSuites -Repo $repo -Rev 'HEAD')
    Assert-True ($named.Count -ge 60 -and $named -contains 'tests/unit/coverage-is-a-decision.tests.ps1') ("the sign-off lanes name {0} suites, coverage-is-a-decision among them" -f $named.Count)
    $combined = @(Get-SweepSuiteList -ListPath $list -Repo $repo -Rev 'HEAD')
    Assert-True ($combined.Count -eq ($named.Count + 2) -and $combined -contains 'tests/quick.ps1' -and $combined -contains 'tests/unit/coverage-is-a-decision.tests.ps1') ("the list given plus the sign-off suites, once each ({0})" -f $combined.Count)
    $dupList = Join-Path $scratch 'dup.txt'
    Set-Content -LiteralPath $dupList -Value @('tests/unit/coverage-is-a-decision.tests.ps1') -Encoding UTF8
    Assert-True (@(Get-SweepSuiteList -ListPath $dupList -Repo $repo -Rev 'HEAD').Count -eq $named.Count) 'a suite in both is run once'
    Assert-True (@(Get-SweepSuiteList -ListPath $list -Repo $repo -Rev 'HEAD' -SkipSignoffSuites).Count -eq 2) '-SkipSignoffSuites runs only the list given'
}
finally {
    $env:SPECREW_SWEEP_KEEPAWAKE_TRACE = $savedTrace
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}
if ($script:failCount -gt 0) { Write-Host ("sweep-driver: {0} failure(s)" -f $script:failCount) -ForegroundColor Red; exit 1 }
Write-Host 'sweep-driver: all passed' -ForegroundColor Green

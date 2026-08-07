# T070: deterministic fixtures for the host-independent conformance turn-delta core.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\conformance-turn-delta.ps1')
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('specrew-turn-delta-' + [guid]::NewGuid().ToString('N'))
$script:Failures = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host "PASS: $Message" -ForegroundColor Green }
    else { Write-Host "FAIL: $Message" -ForegroundColor Red; $script:Failures++ }
}

function Invoke-Git {
    param([string[]]$Arguments)
    $result = & git -C $scratch @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed: $($result -join [Environment]::NewLine)" }
    return @($result)
}

try {
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specrew') -Force | Out-Null
    $null = Invoke-Git @('init', '--quiet')
    [IO.File]::WriteAllText((Join-Path $scratch 'README.md'), "baseline`n", [Text.UTF8Encoding]::new($false))
    $null = Invoke-Git @('add', 'README.md')
    $null = Invoke-Git @('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '--quiet', '-m', 'baseline')

    # A pre-existing dirty file belongs to the live turn-start baseline; a read-only turn has no delta.
    New-Item -ItemType Directory -Path (Join-Path $scratch 'src') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $scratch 'src/preexisting.txt'), "before`n", [Text.UTF8Encoding]::new($false))
    $turnStart = Get-SpecrewTurnSnapshot -ProjectRoot $scratch
    $baseline = New-SpecrewTurnBaselineRecord -Snapshot $turnStart -CaptureEvent 'UserPromptSubmit'
    $readOnly = Compare-SpecrewTurnSnapshot -Baseline $baseline -Current (Get-SpecrewTurnSnapshot -ProjectRoot $scratch) -ProjectRoot $scratch
    Assert-True (-not [bool]$readOnly.material -and [int]$readOnly.user_file_count -eq 0) 'stale dirty worktree at genuine turn start is not attributed to a read-only turn'

    # Content fingerprints re-arm the same dirty path even when porcelain status remains unchanged.
    [IO.File]::WriteAllText((Join-Path $scratch 'src/preexisting.txt'), "after`n", [Text.UTF8Encoding]::new($false))
    $samePath = Compare-SpecrewTurnSnapshot -Baseline $baseline -Current (Get-SpecrewTurnSnapshot -ProjectRoot $scratch) -ProjectRoot $scratch
    Assert-True ([bool]$samePath.material -and [int]$samePath.user_file_count -eq 1 -and @($samePath.changed_paths) -contains 'src/preexisting.txt') 'same-path re-edit is detected by content fingerprint'
    Assert-True ([string]$samePath.attribution_mode -eq 'exact-turn') 'genuine prompt baseline produces exact-turn attribution'

    # Consecutive turns refresh their own complete baseline and stay quiet until another edit occurs.
    $baselinePath = Join-Path $scratch '.specrew/runtime/turn-baseline.json'
    $afterFirstTurn = Get-SpecrewTurnSnapshot -ProjectRoot $scratch
    Assert-True (Write-SpecrewTurnBaseline -Path $baselinePath -Snapshot $afterFirstTurn -CaptureEvent 'UserPromptSubmit') 'owner-scoped baseline writes atomically and validates after publication'
    $nextBaseline = Read-SpecrewTurnBaseline -Path $baselinePath
    $nextReadOnly = Compare-SpecrewTurnSnapshot -Baseline $nextBaseline -Current (Get-SpecrewTurnSnapshot -ProjectRoot $scratch) -ProjectRoot $scratch
    Assert-True (-not [bool]$nextReadOnly.material) 'consecutive read-only turn over the refreshed baseline stays quiet'
    [IO.File]::WriteAllText((Join-Path $scratch 'src/preexisting.txt'), "after-again`n", [Text.UTF8Encoding]::new($false))
    $nextEdit = Compare-SpecrewTurnSnapshot -Baseline $nextBaseline -Current (Get-SpecrewTurnSnapshot -ProjectRoot $scratch) -ProjectRoot $scratch
    Assert-True ([bool]$nextEdit.material -and [int]$nextEdit.user_file_count -eq 1) 'consecutive turn re-arms after a new same-path edit'

    # A missing genuine prompt event enters an explicit degraded worktree mode, never fabricated exact attribution.
    $degradedBaseline = New-SpecrewDegradedTurnBaseline -Current (Get-SpecrewTurnSnapshot -ProjectRoot $scratch)
    $degraded = Compare-SpecrewTurnSnapshot -Baseline $degradedBaseline -Current (Get-SpecrewTurnSnapshot -ProjectRoot $scratch) -ProjectRoot $scratch
    Assert-True ([bool]$degraded.material -and [string]$degraded.attribution_mode -eq 'degraded-worktree') 'capability-absent fallback declares degraded worktree attribution'
    Assert-True ([int]$degraded.current_dirty_user_file_count -eq 1) 'degraded result reports the current dirty worktree count'
    $sessionStartBaseline = New-SpecrewTurnBaselineRecord -Snapshot (Get-SpecrewTurnSnapshot -ProjectRoot $scratch) -CaptureEvent 'SessionStart'
    [IO.File]::WriteAllText((Join-Path $scratch 'src/preexisting.txt'), "after-session-start`n", [Text.UTF8Encoding]::new($false))
    $sessionStartDelta = Compare-SpecrewTurnSnapshot -Baseline $sessionStartBaseline -Current (Get-SpecrewTurnSnapshot -ProjectRoot $scratch) -ProjectRoot $scratch
    Assert-True ([string]$sessionStartDelta.attribution_mode -eq 'degraded-worktree') 'SessionStart-only fallback never claims exact per-prompt attribution'

    # Managed governance/runtime paths are excluded from user-material evidence.
    [IO.File]::WriteAllText((Join-Path $scratch '.specrew/runtime/managed.json'), '{}', [Text.UTF8Encoding]::new($false))
    $managedExcluded = Get-SpecrewTurnSnapshot -ProjectRoot $scratch
    Assert-True ([int]$managedExcluded.dirty_user_file_count -eq 1 -and @($managedExcluded.entries.path) -notcontains '.specrew/runtime/managed.json') 'Specrew-managed paths are excluded from the live user-file surface'

    # Packet demand stays in the core, including satisfied and foreign-owner suppression.
    $demand = Resolve-SpecrewTurnPacketDemand -Delta $nextEdit -Owner 'claude|one'
    $satisfied = Resolve-SpecrewTurnPacketDemand -Delta $nextEdit -SatisfiedKey ([string]$nextEdit.key) -Owner 'claude|one'
    $foreign = Resolve-SpecrewTurnPacketDemand -Delta $nextEdit -Owner 'claude|two' -OwnerRecord ([pscustomobject]@{ key = [string]$nextEdit.key; owner = 'claude|one'; epoch = 100 }) -NowEpoch 101
    Assert-True ([bool]$demand.demand) 'unsatisfied exact delta demands a packet'
    Assert-True (-not [bool]$satisfied.demand -and [bool]$satisfied.already_satisfied) 'satisfied delta does not demand another packet'
    Assert-True (-not [bool]$foreign.demand -and [bool]$foreign.foreign_owner_suppressed) 'recent foreign owner suppresses cross-session packet billing'

    # Commit-only progress is material even when the worktree returns clean.
    $commitBaseline = New-SpecrewTurnBaselineRecord -Snapshot (Get-SpecrewTurnSnapshot -ProjectRoot $scratch) -CaptureEvent 'PreInvocation'
    [IO.File]::WriteAllText((Join-Path $scratch 'committed.txt'), "committed`n", [Text.UTF8Encoding]::new($false))
    $null = Invoke-Git @('add', 'committed.txt')
    $null = Invoke-Git @('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '--quiet', '-m', 'turn commit')
    $commitDelta = Compare-SpecrewTurnSnapshot -Baseline $commitBaseline -Current (Get-SpecrewTurnSnapshot -ProjectRoot $scratch) -ProjectRoot $scratch
    Assert-True ([bool]$commitDelta.material -and [int]$commitDelta.new_commit_count -eq 1) 'new commit after turn start is material even when its file is clean'
}
finally {
    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($script:Failures -gt 0) { throw "T070 turn-delta fixture failures: $script:Failures" }
Write-Host 'All T070 host-independent turn-delta fixtures passed.' -ForegroundColor Green

<#
.SYNOPSIS
    Multi-developer signal detection for Specrew multi-session recommendations (F-051 Iteration 2b).
#>

Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'internal\session-config.ps1')
. (Join-Path $PSScriptRoot 'internal\session-management.ps1')

function Get-SpecrewRecentGitAuthorEmails {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [int]$SinceDays = 90
    )

    $since = ('{0} days ago' -f $SinceDays)
    $output = @(& git -C $ProjectRoot log --since=$since --format='%ae' 2>$null)
    if ($LASTEXITCODE -ne 0) { return @() }

    return @($output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim().ToLowerInvariant() } | Select-Object -Unique)
}

function Get-SpecrewActiveMachineFingerprintCount {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $sessions = @(Read-ActiveSessions -ProjectRoot $ProjectRoot)
    return @($sessions | ForEach-Object { [string]$_['machine_fingerprint'] } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique).Count
}

function Get-SpecrewConcurrentWriteSignalCount {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $stateFiles = @(
        Join-Path $ProjectRoot '.specrew/start-context.json'
        Join-Path $ProjectRoot '.specrew/last-start-prompt.md'
        Join-Path $ProjectRoot '.squad/identity/now.md'
        Join-Path $ProjectRoot '.squad/decisions.md'
        Join-Path $ProjectRoot '.squad/active-features.yml'
    ) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | ForEach-Object { Get-Item -LiteralPath $_ }

    if (@($stateFiles).Count -lt 2) { return 0 }

    $ordered = @($stateFiles | Sort-Object LastWriteTimeUtc)
    $signals = 0
    for ($i = 1; $i -lt $ordered.Count; $i++) {
        $delta = ($ordered[$i].LastWriteTimeUtc - $ordered[$i - 1].LastWriteTimeUtc).Duration()
        if ($delta.TotalSeconds -le 60) { $signals++ }
    }

    return $signals
}

function Get-SpecrewBranchFanoutCount {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $branches = @(& git -C $ProjectRoot for-each-ref --format='%(refname:short)' refs/heads 2>$null)
    if ($LASTEXITCODE -ne 0) { return 0 }

    return @($branches | Where-Object { $_ -match '^\d{3}[-_]' } | Select-Object -Unique).Count
}

function Get-SpecrewMultiDeveloperSignals {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [int]$SinceDays = 90
    )

    $authors = @(Get-SpecrewRecentGitAuthorEmails -ProjectRoot $ProjectRoot -SinceDays $SinceDays)
    $machineCount = Get-SpecrewActiveMachineFingerprintCount -ProjectRoot $ProjectRoot
    $writeSignals = Get-SpecrewConcurrentWriteSignalCount -ProjectRoot $ProjectRoot
    $branchFanout = Get-SpecrewBranchFanoutCount -ProjectRoot $ProjectRoot
    $sessionMode = Get-SessionMode -ProjectRoot $ProjectRoot

    $hasSignals = ($authors.Count -ge 2) -or ($machineCount -ge 2) -or ($writeSignals -ge 1) -or ($branchFanout -ge 3)
    $suppressed = $sessionMode -eq 'multi'
    $reasonParts = New-Object System.Collections.Generic.List[string]
    if ($authors.Count -ge 2) { $reasonParts.Add(('{0} unique git authors' -f $authors.Count)) | Out-Null }
    if ($machineCount -ge 2) { $reasonParts.Add(('{0} active machines' -f $machineCount)) | Out-Null }
    if ($writeSignals -ge 1) { $reasonParts.Add(('{0} close-together shared-state writes' -f $writeSignals)) | Out-Null }
    if ($branchFanout -ge 3) { $reasonParts.Add(('{0} feature branches' -f $branchFanout)) | Out-Null }

    $recommendation = $null
    if ($hasSignals -and -not $suppressed) {
        $detail = if ($reasonParts.Count -gt 0) { $reasonParts -join ', ' } else { 'multi-developer activity' }
        $recommendation = "Multiple developers detected ($detail). Consider enabling multi-session mode: ``specrew config set session_mode multi``"
    }

    return [pscustomobject]@{
        schema_version             = 'v1'
        session_mode               = $sessionMode
        unique_git_author_count    = $authors.Count
        unique_machine_count       = $machineCount
        concurrent_write_count     = $writeSignals
        branch_fanout_count        = $branchFanout
        has_multi_developer_signal = $hasSignals
        recommendation_suppressed  = $suppressed
        recommendation_message     = $recommendation
        summary                    = if ($reasonParts.Count -gt 0) { $reasonParts -join '; ' } else { 'no multi-developer signals' }
    }
}

function Get-SpecrewMultiDeveloperRecommendation {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $signals = Get-SpecrewMultiDeveloperSignals -ProjectRoot $ProjectRoot
    if ([string]::IsNullOrWhiteSpace([string]$signals.recommendation_message)) {
        return $null
    }

    return $signals.recommendation_message
}

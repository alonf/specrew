<#
.SYNOPSIS
    Active-session lock management for Specrew multi-session foundation (F-051 Iteration 2a).

.DESCRIPTION
    Maintains the per-session lock file `.specrew/active-sessions.yml` (FR-007) and the
    collision-detection / stale-clearing logic (FR-008 through FR-011). The lock is LOCAL
    (gitignored, per-session): it catches same-machine/worktree concurrent starts. Cross-
    machine coordination is the committed feature-claims file's job (see feature-claims.ps1,
    drift D-003). The rich machine_fingerprint stays only in this gitignored file (FR-043).

    All writes route through the shared race-safe atomic primitive; corrupt/missing files
    degrade to empty (safe-degradation). Dot-source to use.
#>

Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'atomic-write.ps1')
. (Join-Path $PSScriptRoot 'yaml-list.ps1')

$script:SpecrewActiveSessionsTopKey = 'sessions'

function Get-ActiveSessionsPath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    return (Join-Path $ProjectRoot '.specrew/active-sessions.yml')
}

function Get-SpecrewUtcNow {
    return ((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))
}

function ConvertTo-SpecrewUtc {
    <# Parse an ISO-8601 timestamp to a UTC DateTimeOffset; $null on failure. #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    try {
        $styles = [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal
        return [System.DateTimeOffset]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture, $styles)
    }
    catch { return $null }
}

function Get-MachineFingerprint {
    <#
    .SYNOPSIS
        Local-only machine fingerprint (FR-043): hostname + username + a short stable local
        hash. Computed entirely from local identifiers; makes NO network/telemetry call.
    #>
    $machine = [System.Environment]::MachineName
    $user = [System.Environment]::UserName
    $seed = '{0}|{1}' -f $machine, $user
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($seed))
    }
    finally { $sha.Dispose() }
    $short = -join ($bytes[0..3] | ForEach-Object { $_.ToString('x2') })
    return ('{0}-{1}-{2}' -f $machine, $user, $short)
}

function Read-ActiveSessions {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    return @(Read-SpecrewYamlList -Path (Get-ActiveSessionsPath -ProjectRoot $ProjectRoot) -TopKey $script:SpecrewActiveSessionsTopKey)
}

function Write-ActiveSessions {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowEmptyCollection()][AllowNull()][object[]]$Sessions
    )
    $content = ConvertTo-SpecrewYamlList -TopKey $script:SpecrewActiveSessionsTopKey -Entries $Sessions
    Write-SpecrewFileAtomic -Path (Get-ActiveSessionsPath -ProjectRoot $ProjectRoot) -Content $content
}

function Register-SessionLock {
    <# Add or refresh the lock entry for (feature_id + this machine). Idempotent (FR-008). #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureId,
        [string]$User = [System.Environment]::UserName,
        [string]$Fingerprint = (Get-MachineFingerprint),
        [string]$NowUtc = (Get-SpecrewUtcNow)
    )
    $sessions = @(Read-ActiveSessions -ProjectRoot $ProjectRoot)
    $existing = $sessions | Where-Object { $_['feature_id'] -eq $FeatureId -and $_['machine_fingerprint'] -eq $Fingerprint } | Select-Object -First 1
    if ($null -ne $existing) {
        $existing['last_heartbeat_time'] = $NowUtc
    }
    else {
        $sessions = @($sessions) + ,([ordered]@{
                feature_id          = $FeatureId
                user                = $User
                machine_fingerprint = $Fingerprint
                session_start_time  = $NowUtc
                last_heartbeat_time = $NowUtc
            })
    }
    Write-ActiveSessions -ProjectRoot $ProjectRoot -Sessions $sessions
}

function Remove-SessionLock {
    <# Remove the lock entry for (feature_id [+ fingerprint]); no-op if absent (FR-009). #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureId,
        [string]$Fingerprint
    )
    $sessions = @(Read-ActiveSessions -ProjectRoot $ProjectRoot)
    $kept = @($sessions | Where-Object {
            -not ($_['feature_id'] -eq $FeatureId -and ([string]::IsNullOrEmpty($Fingerprint) -or $_['machine_fingerprint'] -eq $Fingerprint))
        })
    if ($kept.Count -ne $sessions.Count) {
        Write-ActiveSessions -ProjectRoot $ProjectRoot -Sessions $kept
    }
}

function Test-SessionCollision {
    <# Return an active lock for the same feature held by a DIFFERENT machine, else $null (FR-010). #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureId,
        [string]$Fingerprint = (Get-MachineFingerprint)
    )
    $sessions = @(Read-ActiveSessions -ProjectRoot $ProjectRoot)
    return ($sessions | Where-Object { $_['feature_id'] -eq $FeatureId -and $_['machine_fingerprint'] -ne $Fingerprint } | Select-Object -First 1)
}

function Clear-StaleSessionLocks {
    <# Remove locks whose last_heartbeat_time is older than ThresholdHours; return count cleared (FR-011). #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [int]$ThresholdHours = 24,
        [string]$NowUtc = (Get-SpecrewUtcNow)
    )
    $now = ConvertTo-SpecrewUtc -Value $NowUtc
    if ($null -eq $now) { return 0 }
    $sessions = @(Read-ActiveSessions -ProjectRoot $ProjectRoot)
    $kept = @($sessions | Where-Object {
            $hb = ConvertTo-SpecrewUtc -Value ([string]$_['last_heartbeat_time'])
            # Keep entries that are not parseable (do not silently destroy) OR within threshold.
            ($null -eq $hb) -or (($now - $hb).TotalHours -lt $ThresholdHours)
        })
    $cleared = $sessions.Count - $kept.Count
    if ($cleared -gt 0) {
        Write-ActiveSessions -ProjectRoot $ProjectRoot -Sessions $kept
    }
    return $cleared
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

function ConvertFrom-SpecrewFrontmatterBlock {
    param([AllowNull()][string]$Content)

    $frontmatter = [ordered]@{}
    if ([string]::IsNullOrWhiteSpace($Content) -or $Content -notmatch '(?ms)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)$') {
        return $frontmatter
    }

    foreach ($line in ($Matches[1] -split '\r?\n')) {
        if ($line -match '^\s*([^:]+):\s*(.*?)\s*$') {
            $key = $Matches[1].Trim()
            $value = $Matches[2].Trim()
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            $frontmatter[$key] = $value
        }
    }

    return $frontmatter
}

function Get-WorktreeSessionState {
    param([Parameter(Mandatory = $true)][string]$WorktreePath)

    $promptPath = Join-Path $WorktreePath '.specrew\last-start-prompt.md'
    if (-not (Test-Path -LiteralPath $promptPath -PathType Leaf)) {
        return $null
    }

    $frontmatter = ConvertFrom-SpecrewFrontmatterBlock -Content (Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8)
    if ($frontmatter.Count -eq 0) {
        return $null
    }

    return [pscustomobject]@{
        feature_ref   = if ($frontmatter.Contains('session_state_feature')) { [string]$frontmatter['session_state_feature'] } else { $null }
        boundary_type = if ($frontmatter.Contains('session_state_boundary')) { [string]$frontmatter['session_state_boundary'] } else { $null }
        recorded_at   = if ($frontmatter.Contains('session_state_recorded_at')) { [string]$frontmatter['session_state_recorded_at'] } else { $null }
        feature_path  = if ($frontmatter.Contains('session_state_feature_path')) { [string]$frontmatter['session_state_feature_path'] } else { $null }
        iteration     = if ($frontmatter.Contains('session_state_iteration')) { [string]$frontmatter['session_state_iteration'] } else { $null }
    }
}

function Get-WorktreeFeatureRef {
    param([Parameter(Mandatory = $true)][string]$WorktreePath)

    $featureJsonPath = Join-Path $WorktreePath '.specify\feature.json'
    if (Test-Path -LiteralPath $featureJsonPath -PathType Leaf) {
        try {
            $featureJson = Get-Content -LiteralPath $featureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if (-not [string]::IsNullOrWhiteSpace([string]$featureJson.feature_directory)) {
                return Split-Path -Leaf ([string]$featureJson.feature_directory)
            }
        }
        catch {
        }
    }

    $sessionState = Get-WorktreeSessionState -WorktreePath $WorktreePath
    if ($null -ne $sessionState -and -not [string]::IsNullOrWhiteSpace([string]$sessionState.feature_ref) -and [string]$sessionState.feature_ref -ne '(none)') {
        return [string]$sessionState.feature_ref
    }

    return $null
}

function Get-WorktreeBoundarySummary {
    param([Parameter(Mandatory = $true)][string]$WorktreePath)

    $sessionState = Get-WorktreeSessionState -WorktreePath $WorktreePath
    if ($null -ne $sessionState -and -not [string]::IsNullOrWhiteSpace([string]$sessionState.boundary_type) -and [string]$sessionState.boundary_type -ne '(none)') {
        return $sessionState
    }

    return [pscustomobject]@{
        boundary_type = $null
        recorded_at   = $null
        feature_path  = $null
        iteration     = $null
    }
}

function Get-WorktreeFeatureNumber {
    param([AllowNull()][string]$FeatureRef)

    if ([string]::IsNullOrWhiteSpace($FeatureRef)) {
        return $null
    }

    if ($FeatureRef -match '^(?<number>\d{3})[-_]') {
        return $Matches['number']
    }

    return $FeatureRef
}

function Get-WorktreeRecords {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $output = @(& git -C $resolvedProjectRoot worktree list --porcelain 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw ("Failed to enumerate git worktrees: {0}" -f (($output -join [Environment]::NewLine).Trim()))
    }

    $records = New-Object System.Collections.Generic.List[object]
    $current = $null
    foreach ($line in $output) {
        $text = [string]$line
        if ($text -match '^worktree\s+(.+)$') {
            if ($null -ne $current) {
                $records.Add([pscustomobject]$current) | Out-Null
            }

            $current = [ordered]@{
                path     = $Matches[1].Trim()
                branch   = $null
                head     = $null
                prunable = $false
            }
            continue
        }

        if ($null -eq $current -or [string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        if ($text -match '^branch\s+(.+)$') {
            $current.branch = $Matches[1].Trim()
        }
        elseif ($text -match '^HEAD\s+(.+)$') {
            $current.head = $Matches[1].Trim()
        }
        elseif ($text -match '^prunable') {
            $current.prunable = $true
        }
    }

    if ($null -ne $current) {
        $records.Add([pscustomobject]$current) | Out-Null
    }

    return $records.ToArray()
}

function Get-WorktreeState {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $records = @(Get-WorktreeRecords -ProjectRoot $resolvedProjectRoot)
    $states = New-Object System.Collections.Generic.List[object]

    foreach ($record in $records) {
        $worktreePath = [System.IO.Path]::GetFullPath([string]$record.path)
        $exists = Test-Path -LiteralPath $worktreePath -PathType Container
        $featureRef = if ($exists) { Get-WorktreeFeatureRef -WorktreePath $worktreePath } else { $null }
        $boundary = if ($exists) { Get-WorktreeBoundarySummary -WorktreePath $worktreePath } else { $null }
        $lastActivity = if ($null -ne $boundary -and -not [string]::IsNullOrWhiteSpace([string]$boundary.recorded_at) -and [string]$boundary.recorded_at -ne '(none)') {
            [string]$boundary.recorded_at
        }
        elseif ($exists) {
            $promptPath = Join-Path $worktreePath '.specrew\last-start-prompt.md'
            if (Test-Path -LiteralPath $promptPath -PathType Leaf) {
                (Get-Item -LiteralPath $promptPath).LastWriteTimeUtc.ToString('o')
            }
            else {
                $null
            }
        }
        else {
            $null
        }

        $states.Add([pscustomobject]@{
                path           = $worktreePath
                is_current     = ($worktreePath -eq $resolvedProjectRoot)
                exists         = $exists
                feature_ref    = $featureRef
                feature_number = Get-WorktreeFeatureNumber -FeatureRef $featureRef
                boundary_type  = if ($exists -and $null -ne $boundary) { [string]$boundary.boundary_type } else { $null }
                last_activity  = $lastActivity
                branch         = [string]$record.branch
                head           = [string]$record.head
                note           = if (-not $exists) { '(path not found; run git worktree prune)' } elseif ($record.prunable) { '(prunable)' } else { $null }
            }) | Out-Null
    }

    return $states.ToArray()
}

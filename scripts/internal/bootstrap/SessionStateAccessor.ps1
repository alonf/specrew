<#
.SYNOPSIS
  Read the session anchor and write the advisory SessionStart marker.
.DESCRIPTION
  Resource accessor (IDesign): the only component that touches the session-state and marker
  files. Reads fail open (return $null on missing/corrupt). Absolute-path anchors are treated
  as non-portable and must be re-resolved against the current project root before use (FR-015).
  The marker is local-only and never committed (integration-api d2). Property access is
  defensive so the functions are safe under Set-StrictMode. Feature 174 (FR-013, FR-015, FR-018).
#>

function Get-SpecrewProp {
    # StrictMode-safe property read: returns $null when the property is absent.
    param([AllowNull()]$Object, [Parameter(Mandatory)][string] $Name)
    if ($null -eq $Object) { return $null }
    $p = $Object.PSObject.Properties[$Name]
    if ($p) { return $p.Value }
    return $null
}

function Get-SpecrewSessionAnchor {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string] $StatePath)

    if (-not (Test-Path -LiteralPath $StatePath)) { return $null }
    try {
        $obj = (Get-Content -LiteralPath $StatePath -Raw -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop
    }
    catch { return $null }

    $s = Get-SpecrewProp $obj 'session_state'
    if ($null -eq $s) { return $null }

    [pscustomobject]@{
        feature_ref      = Get-SpecrewProp $s 'feature_ref'
        feature_path     = Get-SpecrewProp $s 'feature_path'
        boundary         = Get-SpecrewProp $s 'boundary_type'
        iteration        = Get-SpecrewProp $s 'iteration_number'
        auth_commit_hash = Get-SpecrewProp $s 'auth_commit_hash'
        recorded_at      = Get-SpecrewProp $s 'recorded_at'
        active           = [bool](Get-SpecrewProp $s 'active')
    }
}

function Write-SpecrewSessionMarker {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $MarkerPath,
        [Parameter(Mandatory)][string] $HostName,
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter()][string] $Branch,
        [Parameter()][string] $HeadCommit,
        # Caller supplies the timestamp (keeps the accessor deterministic + unit-testable).
        [Parameter(Mandatory)][string] $StartedAt
    )

    $marker = [pscustomobject]@{
        started_at   = $StartedAt
        host         = $HostName
        project_root = $ProjectRoot
        branch       = $Branch
        head_commit  = $HeadCommit
    }
    $dir = Split-Path -Parent $MarkerPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $marker | ConvertTo-Json | Set-Content -LiteralPath $MarkerPath -Encoding UTF8
    $marker
}

function Test-SpecrewAnchorPortable {
    # An absolute feature_path that does not resolve under the current project root is
    # non-portable (the merged-Feature-171 cross-worktree incident). FR-015.
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter()][AllowNull()]$Anchor, [Parameter(Mandatory)][string] $ProjectRoot)

    if ($null -eq $Anchor) { return $false }
    $fp = Get-SpecrewProp $Anchor 'feature_path'
    if ([string]::IsNullOrWhiteSpace($fp)) { return $true }  # nothing absolute recorded -> re-resolve project-local
    if ([System.IO.Path]::IsPathRooted($fp)) {
        $norm = ([string]$fp).Replace('\', '/').TrimEnd('/')
        $root = $ProjectRoot.Replace('\', '/').TrimEnd('/')
        return $norm.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)
    }
    return $true
}

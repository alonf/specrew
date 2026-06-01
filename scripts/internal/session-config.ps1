<#
.SYNOPSIS
    Session-mode configuration helpers for Specrew multi-session foundation (F-051).

.DESCRIPTION
    Reads and writes the `session_mode` scalar in `.specrew/config.yml`. Session mode
    is the opt-in switch (FR-001..FR-003) that gates multi-developer coordination
    behavior; `single` is the default and keeps existing projects inert.

    Dot-source this file to use Get-SessionMode / Set-SessionMode. Writes are atomic
    (write-temp-then-rename) so a concurrent reader never observes a partial file.
#>

Set-StrictMode -Version Latest

# Write-SpecrewFileAtomic lives in the shared atomic-write helper (extracted in F-051
# Iteration 2a, T020) so locks/claims/config share one race-safe primitive.
. (Join-Path $PSScriptRoot 'atomic-write.ps1')

$script:SpecrewValidSessionModes = @('single', 'multi')

function Get-SpecrewConfigPath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    return (Join-Path $ProjectRoot '.specrew/config.yml')
}

function Get-SessionMode {
    <#
    .SYNOPSIS
        Return the configured session mode, or 'single' when unset/missing (FR-003 default).
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $configPath = Get-SpecrewConfigPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return 'single'
    }

    foreach ($line in Get-Content -LiteralPath $configPath -Encoding UTF8) {
        if ($line -match '^\s*session_mode:\s*"?(?<value>[^"#]+?)"?\s*$') {
            return $Matches['value'].Trim()
        }
    }

    return 'single'
}

function Set-SessionMode {
    <#
    .SYNOPSIS
        Validate and persist the session mode to `.specrew/config.yml` (FR-001, FR-002).
    .DESCRIPTION
        Throws on an invalid value (anything other than single|multi) WITHOUT modifying
        the file. Replaces an existing session_mode line in place, or appends one.
        Writes atomically via a temp file + Move-Item -Force.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Value
    )

    $normalized = $Value.Trim().ToLowerInvariant()
    if ($script:SpecrewValidSessionModes -notcontains $normalized) {
        throw ("Invalid session_mode '{0}'. Valid values: {1}." -f $Value, ($script:SpecrewValidSessionModes -join ', '))
    }

    $configPath = Get-SpecrewConfigPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw ("Specrew config not found at '{0}'. Run 'specrew init' first." -f $configPath)
    }

    $content = Get-Content -LiteralPath $configPath -Raw
    $replacement = 'session_mode: "{0}"' -f $normalized
    if ($content -match '(?m)^\s*session_mode:\s*.*$') {
        $updated = [regex]::Replace($content, '(?m)^\s*session_mode:\s*.*$', $replacement)
    }
    else {
        $updated = $content.TrimEnd() + [Environment]::NewLine + $replacement + [Environment]::NewLine
    }

    Write-SpecrewFileAtomic -Path $configPath -Content $updated
    return $normalized
}

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

function Write-SpecrewFileAtomic {
    <#
    .SYNOPSIS
        Write text to a path atomically (write to .tmp sibling, then Move-Item -Force).
    .DESCRIPTION
        Move-Item -Force is atomic on the same volume, so no reader observes a partial
        write - the race-safe write pattern from the F-051 research (R3).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $tempPath = '{0}.{1}.tmp' -f $Path, ([System.Guid]::NewGuid().ToString('N'))
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($tempPath, $Content, $utf8NoBom)
    Move-Item -LiteralPath $tempPath -Destination $Path -Force
}

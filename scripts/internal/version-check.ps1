Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

function Get-SpecrewVersionConfigValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $configPath = Join-Path (Resolve-ProjectPath -Path $ProjectRoot) '.specrew\config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return $null
    }

    foreach ($line in Get-Content -LiteralPath $configPath -Encoding UTF8) {
        if ($line -match ('^\s*{0}:\s*"?(?<value>[^"#]+?)"?\s*$' -f [regex]::Escape($Key))) {
            return $Matches['value'].Trim()
        }
    }

    return $null
}

function Get-SpecrewInstalledVersion {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $module = @(Get-Module -Name Specrew -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1)
    if ($module.Count -gt 0 -and $module[0].Version) {
        return $module[0].Version.ToString()
    }

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $manifestCandidates = @(
        (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'Specrew.psd1'),
        (Join-Path $resolvedProjectRoot 'Specrew.psd1')
    ) | Select-Object -Unique

    foreach ($manifestPath in $manifestCandidates) {
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            continue
        }

        try {
            $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
            if ($manifest.ContainsKey('ModuleVersion')) {
                return [string]$manifest.ModuleVersion
            }
        }
        catch {
        }
    }

    return $null
}

function ConvertTo-SpecrewSemanticVersion {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $match = [regex]::Match($Value, '(?<version>\d+\.\d+\.\d+(?:\.\d+)?)')
    if (-not $match.Success) {
        return $null
    }

    try {
        return [version]$match.Groups['version'].Value
    }
    catch {
        return $null
    }
}

function Get-SpecrewVersionCheckCachePath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    return Join-Path (Resolve-ProjectPath -Path $ProjectRoot) '.specrew\version-check-cache.json'
}

function Test-SpecrewSkipUpdateCheck {
    param([bool]$SkipUpdateCheck)

    if ($SkipUpdateCheck) {
        return $true
    }

    return ($env:SPECREW_SKIP_UPDATE_CHECK -eq '1')
}

function Get-SpecrewVersionCheckCacheState {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $cachePath = Get-SpecrewVersionCheckCachePath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $cachePath -PathType Leaf)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $cachePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 6
    }
    catch {
        return $null
    }
}

function Set-SpecrewVersionCheckCacheState {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$LatestVersion,
        [Parameter(Mandatory = $true)][string]$CheckedAt,
        [Parameter(Mandatory = $true)][string]$CacheValidUntil,
        [Parameter(Mandatory = $true)][string]$Source
    )

    $payload = [ordered]@{
        schema            = 'v1'
        latest_version    = $LatestVersion
        checked_at        = $CheckedAt
        cache_valid_until = $CacheValidUntil
        source            = $Source
    } | ConvertTo-Json -Depth 6

    Write-Utf8FileAtomic -Path (Get-SpecrewVersionCheckCachePath -ProjectRoot $ProjectRoot) -Content ($payload + [Environment]::NewLine)
}

function Test-SpecrewVersionCacheValid {
    param([AllowNull()][object]$CacheState)

    if ($null -eq $CacheState -or [string]::IsNullOrWhiteSpace([string]$CacheState.cache_valid_until)) {
        return $false
    }

    try {
        $cacheValidUntil = [datetime]::Parse([string]$CacheState.cache_valid_until, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
        return ($cacheValidUntil -gt (Get-Date).ToUniversalTime())
    }
    catch {
        return $false
    }
}

function Invoke-SpecrewPSGalleryLatestVersionQuery {
    param([int]$TimeoutSeconds = 10)

    if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_PSGALLERY_LATEST_VERSION)) {
        return [pscustomobject]@{
            LatestVersion = $env:SPECREW_PSGALLERY_LATEST_VERSION
            Source        = 'override'
        }
    }

    if ($env:SPECREW_PSGALLERY_FORCE_FAILURE -eq '1') {
        throw 'Simulated PSGallery failure.'
    }

    $job = Start-Job -ScriptBlock {
        $module = Find-Module -Name Specrew -Repository PSGallery -ErrorAction Stop
        [pscustomobject]@{
            LatestVersion = [string]$module.Version
            Source        = 'psgallery'
        }
    }

    try {
        if (-not (Wait-Job -Job $job -Timeout $TimeoutSeconds)) {
            Stop-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
            throw ("Timed out after {0} seconds while querying PSGallery." -f $TimeoutSeconds)
        }

        $result = Receive-Job -Job $job -ErrorAction Stop
        if ($null -eq $result -or [string]::IsNullOrWhiteSpace([string]$result.LatestVersion)) {
            throw 'PSGallery query returned no version.'
        }

        return $result
    }
    finally {
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

function Get-PSGalleryLatestVersion {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [switch]$ForceRefresh,
        [bool]$SkipCheck
    )

    if (Test-SpecrewSkipUpdateCheck -SkipUpdateCheck $SkipCheck) {
        return [pscustomobject]@{
            Skipped       = $true
            LatestVersion = $null
            Source        = 'skipped'
        }
    }

    $cacheState = Get-SpecrewVersionCheckCacheState -ProjectRoot $ProjectRoot
    if (-not $ForceRefresh -and (Test-SpecrewVersionCacheValid -CacheState $cacheState) -and -not [string]::IsNullOrWhiteSpace([string]$cacheState.latest_version)) {
        return [pscustomobject]@{
            Skipped       = $false
            LatestVersion = [string]$cacheState.latest_version
            Source        = 'cache'
            CheckedAt     = [string]$cacheState.checked_at
            CacheValidUntil = [string]$cacheState.cache_valid_until
        }
    }

    try {
        $queryResult = Invoke-SpecrewPSGalleryLatestVersionQuery
        $checkedAt = (Get-Date).ToUniversalTime().ToString('o')
        $cacheValidUntil = (Get-Date).ToUniversalTime().AddHours(24).ToString('o')
        Set-SpecrewVersionCheckCacheState `
            -ProjectRoot $ProjectRoot `
            -LatestVersion ([string]$queryResult.LatestVersion) `
            -CheckedAt $checkedAt `
            -CacheValidUntil $cacheValidUntil `
            -Source ([string]$queryResult.Source)

        return [pscustomobject]@{
            Skipped         = $false
            LatestVersion   = [string]$queryResult.LatestVersion
            Source          = [string]$queryResult.Source
            CheckedAt       = $checkedAt
            CacheValidUntil = $cacheValidUntil
        }
    }
    catch {
        Write-Verbose ("PSGallery latest-version query failed: {0}" -f $_.Exception.Message)
        return $null
    }
}

function Get-PSGalleryUpdateWarning {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [bool]$SkipCheck
    )

    if (Test-SpecrewSkipUpdateCheck -SkipUpdateCheck $SkipCheck) {
        return $null
    }

    $installedVersionText = Get-SpecrewInstalledVersion -ProjectRoot $ProjectRoot
    $installedVersion = ConvertTo-SpecrewSemanticVersion -Value $installedVersionText
    if ($null -eq $installedVersion) {
        return $null
    }

    $latestState = Get-PSGalleryLatestVersion -ProjectRoot $ProjectRoot -SkipCheck:$SkipCheck
    if ($null -eq $latestState -or [string]::IsNullOrWhiteSpace([string]$latestState.LatestVersion)) {
        return $null
    }

    $latestVersion = ConvertTo-SpecrewSemanticVersion -Value ([string]$latestState.LatestVersion)
    if ($null -eq $latestVersion -or $latestVersion -le $installedVersion) {
        return $null
    }

    return "Newer version available: $($latestVersion.ToString()) (current: $($installedVersion.ToString())). To update: Update-Module Specrew"
}

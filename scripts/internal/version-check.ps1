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

function Get-SpecrewModulePathOverrideManifestPath {
    # F-044 dev-trial parity. When SPECREW_MODULE_PATH names a VALID Specrew tree, the CLI is dispatching from
    # THERE (Specrew.psm1), so that tree's manifest IS the version actually running -- not whatever stale copy
    # Get-Module -ListAvailable surfaces from PSModulePath. Validity uses the SAME marker the dispatcher uses
    # (Specrew.psd1 + scripts/specrew.ps1), so a bogus override path is ignored and resolution falls through.
    # Returns the override manifest path, or $null when the env var is unset/invalid.
    if ([string]::IsNullOrWhiteSpace($env:SPECREW_MODULE_PATH)) { return $null }
    $overrideRoot = $env:SPECREW_MODULE_PATH
    $overrideManifest = Join-Path $overrideRoot 'Specrew.psd1'
    $overrideCli = Join-Path $overrideRoot 'scripts/specrew.ps1'
    if ((Test-Path -LiteralPath $overrideManifest -PathType Leaf) -and (Test-Path -LiteralPath $overrideCli -PathType Leaf)) {
        return $overrideManifest
    }
    return $null
}

function Get-SpecrewInstalledVersion {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    # Step 0 (F-044 dev-trial parity): an active SPECREW_MODULE_PATH override is the version actually running;
    # honor it before Get-Module -ListAvailable, which would otherwise report a stale Gallery copy and produce a
    # misleading INCOMPATIBLE banner in every dev-trial of an unpublished branch.
    $overrideManifestPath = Get-SpecrewModulePathOverrideManifestPath
    if ($overrideManifestPath) {
        try {
            $overrideManifest = Import-PowerShellDataFile -LiteralPath $overrideManifestPath
            if ($overrideManifest -and $overrideManifest.ContainsKey('ModuleVersion')) {
                return [string]$overrideManifest.ModuleVersion
            }
        }
        catch {
            # Unreadable override manifest -> fall through to the normal resolution.
        }
    }

    # Step 1: Get-Module -ListAvailable. SilentlyContinue + try/catch because on Linux,
    # PSModulePath often contains directories with malformed modules or permission
    # issues; without SilentlyContinue, those produce non-terminating errors that
    # $ErrorActionPreference='Stop' (set at the top of this script) turns into
    # terminating exceptions, which silently fail the whole function via outer catch.
    try {
        $module = @(Get-Module -Name Specrew -ListAvailable -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending |
            Select-Object -First 1)
        if ($module.Count -gt 0 -and $module[0].Version) {
            return $module[0].Version.ToString()
        }
    }
    catch {
        # Fall through to manifest check.
    }

    # Step 2: manifest path search. Always try the repo-root manifest (two parents
    # up from this script). Add ProjectRoot manifest only if Resolve-ProjectPath
    # succeeds (it normally does; defensive).
    $manifestCandidates = @(
        (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'Specrew.psd1')
    )

    try {
        $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
        $manifestCandidates += (Join-Path $resolvedProjectRoot 'Specrew.psd1')
    }
    catch {
        # ProjectRoot may be unresolvable; the repo-root manifest is still tried.
    }

    $manifestCandidates = @($manifestCandidates | Select-Object -Unique)

    foreach ($manifestPath in $manifestCandidates) {
        try {
            if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
                continue
            }

            $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
            if ($manifest -and $manifest.ContainsKey('ModuleVersion')) {
                return [string]$manifest.ModuleVersion
            }
        }
        catch {
            continue
        }
    }

    return $null
}

function Get-SpecrewVersionInfoFromManifest {
    <#
    .SYNOPSIS
    Read a Specrew manifest and return its base version + prerelease label (for DISPLAY).
    .DESCRIPTION
    Pure manifest parse (no module resolution), so it is deterministically unit-testable.
    The prerelease label lives in PrivateData.PSData.Prerelease; stable manifests carry an
    empty string there.
    .OUTPUTS
    pscustomobject @{ Version; Prerelease; Display } or $null when the manifest is unreadable
    or has no ModuleVersion.
    #>
    param([Parameter(Mandatory = $true)][string]$ManifestPath)

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        return $null
    }

    try {
        $manifest = Import-PowerShellDataFile -LiteralPath $ManifestPath
    }
    catch {
        return $null
    }

    if (-not ($manifest -and $manifest.ContainsKey('ModuleVersion'))) {
        return $null
    }
    $baseVersion = [string]$manifest.ModuleVersion

    $prerelease = ''
    if ($manifest.ContainsKey('PrivateData') -and $manifest.PrivateData -is [hashtable]) {
        $privateData = $manifest.PrivateData
        if ($privateData.ContainsKey('PSData') -and $privateData.PSData -is [hashtable] -and $privateData.PSData.ContainsKey('Prerelease')) {
            $prerelease = [string]$privateData.PSData.Prerelease
        }
    }

    $display = if (-not [string]::IsNullOrWhiteSpace($prerelease)) { "$baseVersion-$prerelease" } else { $baseVersion }
    return [pscustomobject]@{
        Version    = $baseVersion
        Prerelease = $prerelease
        Display    = $display
    }
}

function Get-SpecrewInstalledVersionInfo {
    <#
    .SYNOPSIS
    Resolve the installed Specrew version AND its prerelease label, for the version report.
    .DESCRIPTION
    Get-SpecrewInstalledVersion returns the BASE version only and stays that way, so every
    semver comparison (module/project baseline compatibility) is unaffected. This reads
    the SAME resolved manifest to also surface the prerelease label, so `specrew version` can
    report e.g. 0.31.0-beta3 instead of a bare 0.31.0 that cannot be told apart from a stable
    0.31.0. Resolution mirrors Get-SpecrewInstalledVersion: highest installed module first,
    then the repo-root / project-root manifest.
    .OUTPUTS
    pscustomobject @{ Version; Prerelease; Display } or $null.
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    # Step 0 (F-044 dev-trial parity): prefer an active SPECREW_MODULE_PATH override manifest, so the version
    # report (base + prerelease label) reflects the tree actually dispatching, not a stale Gallery copy.
    $manifestPath = Get-SpecrewModulePathOverrideManifestPath

    if (-not $manifestPath) {
        try {
            $module = @(Get-Module -Name Specrew -ListAvailable -ErrorAction SilentlyContinue |
                Sort-Object Version -Descending |
                Select-Object -First 1)
            if ($module.Count -gt 0 -and $module[0].ModuleBase) {
                $candidate = Join-Path $module[0].ModuleBase 'Specrew.psd1'
                if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                    $manifestPath = $candidate
                }
            }
        }
        catch {
            # Fall through to the manifest path search.
        }
    }

    if (-not $manifestPath) {
        $manifestCandidates = @(
            (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'Specrew.psd1')
        )
        try {
            $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
            $manifestCandidates += (Join-Path $resolvedProjectRoot 'Specrew.psd1')
        }
        catch {
            # ProjectRoot may be unresolvable; the repo-root manifest is still tried.
        }
        foreach ($candidate in (@($manifestCandidates) | Select-Object -Unique)) {
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $manifestPath = $candidate
                break
            }
        }
    }

    if (-not $manifestPath) {
        return $null
    }

    return Get-SpecrewVersionInfoFromManifest -ManifestPath $manifestPath
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

function Get-SpecrewSupportedVersionsPath {
    return Join-Path $PSScriptRoot 'supported-versions.yml'
}

function Get-SpecrewSupportedVersions {
    param(
        [string]$Path = (Get-SpecrewSupportedVersionsPath)
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    try {
        $result = [ordered]@{
            Schema  = $null
            Speckit = [ordered]@{ Min = $null; MaxTested = $null; Notes = '' }
            Squad   = [ordered]@{ Min = $null; MaxTested = $null; Notes = '' }
        }

        $currentSection = $null
        foreach ($line in (Get-Content -LiteralPath $Path -Encoding UTF8)) {
            if ($line -match '^\s*(?:#.*)?$') { continue }

            if ($line -match '^schema:\s*"?(?<value>[^"#\r\n]+?)"?\s*(?:#.*)?$') {
                $result.Schema = $Matches['value'].Trim()
                $currentSection = $null
                continue
            }

            if ($line -match '^(?<section>speckit|squad):\s*(?:#.*)?$') {
                $currentSection = $Matches['section']
                continue
            }

            if ($currentSection -and ($line -match '^\s+(?<key>min|max_tested|notes):\s*"?(?<value>[^"#\r\n]*?)"?\s*(?:#.*)?$')) {
                $key = $Matches['key']
                $value = $Matches['value'].Trim()

                $sectionMap = if ($currentSection -eq 'speckit') { $result.Speckit } else { $result.Squad }
                switch ($key) {
                    'min'        { $sectionMap.Min = $value }
                    'max_tested' { $sectionMap.MaxTested = $value }
                    'notes'      { $sectionMap.Notes = $value }
                }
            }
        }

        if ([string]::IsNullOrWhiteSpace($result.Speckit.Min) -or
            [string]::IsNullOrWhiteSpace($result.Speckit.MaxTested) -or
            [string]::IsNullOrWhiteSpace($result.Squad.Min) -or
            [string]::IsNullOrWhiteSpace($result.Squad.MaxTested)) {
            return $null
        }

        if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_SUPPORTED_MAX_SPECKIT)) {
            $result.Speckit.MaxTested = $env:SPECREW_SUPPORTED_MAX_SPECKIT.Trim()
        }
        if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_SUPPORTED_MAX_SQUAD)) {
            $result.Squad.MaxTested = $env:SPECREW_SUPPORTED_MAX_SQUAD.Trim()
        }

        return $result
    }
    catch {
        return $null
    }
}

function Get-SpecrewVersionStatus {
    param(
        [AllowNull()][string]$Current,
        [AllowNull()][string]$Min,
        [AllowNull()][string]$MaxTested
    )

    if ([string]::IsNullOrWhiteSpace($Current)) {
        return 'not-installed'
    }

    $currentVersion = ConvertTo-SpecrewSemanticVersion -Value $Current
    if ($null -eq $currentVersion) {
        return 'unknown'
    }

    $minVersion = ConvertTo-SpecrewSemanticVersion -Value $Min
    $maxTestedVersion = ConvertTo-SpecrewSemanticVersion -Value $MaxTested

    if (($null -ne $minVersion) -and ($currentVersion -lt $minVersion)) {
        return 'behind-supported'
    }

    if ($null -ne $maxTestedVersion) {
        if ($currentVersion -eq $maxTestedVersion) { return 'current' }
        if ($currentVersion -lt $maxTestedVersion) { return 'update-available-supported' }
        if ($currentVersion -gt $maxTestedVersion) { return 'ahead-of-supported' }
    }

    return 'unknown'
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
        # F-023: Use -AsHashtable for StrictMode compatibility; hashtable indexer tolerates missing fields
        $cache = Get-Content -LiteralPath $cachePath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 6
        
        # F-023: Legacy schema handling - missing 'schema' field implies v0
        $schema = $cache['schema']
        if (-not $schema) {
            Write-Debug "schema-implied-v0 for $cachePath"
            # v0 behavior: all cache fields are optional
        }
        # v1+ behavior: same as v0 for this cache (no behavioral divergence yet)
        
        return $cache
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

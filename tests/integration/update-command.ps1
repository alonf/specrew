[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Write-Skip {
    param([string]$Message)
    Write-Host "SKIP: $Message" -ForegroundColor Yellow
}

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return @{
        Output = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

function Assert-Contains {
    param(
        [string]$Content,
        [string]$Pattern,
        [string]$FailureMessage
    )

    if ($Content -notmatch $Pattern) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Get-ConfigValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $pattern = '(?m)^\s*{0}:\s*"?(?<value>[^"\r\n]+)"?\s*$' -f [regex]::Escape($Key)
    $match = [regex]::Match((Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8), $pattern)
    if (-not $match.Success) {
        return $null
    }

    return $match.Groups['value'].Value.Trim()
}

function Set-ConfigValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $content = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8
    $updated = [regex]::Replace($content, ("(?m)^\s*{0}:\s*.*$" -f [regex]::Escape($Key)), ('{0}: "{1}"' -f $Key, $Value))
    [System.IO.File]::WriteAllText($ConfigPath, $updated, [System.Text.UTF8Encoding]::new($false))
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$entryScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew.ps1'
$initScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-init.ps1'
$updateScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-update.ps1'
$extensionManifestPath = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\extension.yml'
$extensionReadmePath = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\README.md'

foreach ($requiredScript in @($entryScript, $initScript, $updateScript, $extensionManifestPath, $extensionReadmePath)) {
    if (-not (Test-Path -LiteralPath $requiredScript -PathType Leaf)) {
        Write-Fail "Missing required file: $requiredScript"
        exit 1
    }
}

$missingTools = @()
if (-not (Get-Command -Name 'specify' -ErrorAction SilentlyContinue)) {
    $missingTools += 'specify'
}
if (-not (Get-Command -Name 'squad' -ErrorAction SilentlyContinue)) {
    $missingTools += 'squad'
}

if ($missingTools.Count -gt 0) {
    Write-Skip ("Update command tests require tools not available in this environment: {0}" -f ($missingTools -join ', '))
    exit 0
}

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\update-command'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -Path $projectRoot -ItemType Directory -Force
$gitInitOutput = @(& git -C $projectRoot init --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    foreach ($line in $gitInitOutput) {
        Write-Host $line
    }

    Write-Fail "Failed to initialize git repository in scratch project: $projectRoot"
    exit 1
}

Write-Host "Initializing Specrew project for update tests..."
$initResult = Invoke-TestScript -ScriptPath $initScript -ArgumentList @('-ProjectPath', $projectRoot, '-Force', '-NoAgents')
if ($initResult.ExitCode -ne 0) {
    Write-Host "Bootstrap output:"
    foreach ($line in $initResult.Output) {
        Write-Host $line
    }

    Write-Fail 'Bootstrap failed'
    exit 1
}

$configPath = Join-Path -Path $projectRoot -ChildPath '.specrew\config.yml'
$installedExtensionReadmePath = Join-Path -Path $projectRoot -ChildPath '.specify\extensions\specrew-speckit\README.md'
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    Write-Fail "Missing project config: $configPath"
    exit 1
}
if (-not (Test-Path -LiteralPath $installedExtensionReadmePath -PathType Leaf)) {
    Write-Fail "Missing installed extension README: $installedExtensionReadmePath"
    exit 1
}

$sourceSpecrewVersion = [regex]::Match((Get-Content -LiteralPath $extensionManifestPath -Raw -Encoding UTF8), '(?m)^\s*version:\s*"?(?<version>[^"\r\n]+)').Groups['version'].Value.Trim()
$currentSpecKitVersion = Get-ConfigValue -ConfigPath $configPath -Key 'speckit_version'
$currentSquadVersion = Get-ConfigValue -ConfigPath $configPath -Key 'squad_version'

$originalSpecrewOverride = [Environment]::GetEnvironmentVariable('SPECREW_UPDATE_LATEST_SPECREW', 'Process')
$originalSpecKitOverride = [Environment]::GetEnvironmentVariable('SPECREW_UPDATE_LATEST_SPECKIT', 'Process')
$originalSquadOverride = [Environment]::GetEnvironmentVariable('SPECREW_UPDATE_LATEST_SQUAD', 'Process')
$originalSpecKitMaxOverride = [Environment]::GetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SPECKIT', 'Process')
$originalSquadMaxOverride = [Environment]::GetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SQUAD', 'Process')

try {
    [Environment]::SetEnvironmentVariable('SPECREW_UPDATE_LATEST_SPECREW', $sourceSpecrewVersion, 'Process')
    [Environment]::SetEnvironmentVariable('SPECREW_UPDATE_LATEST_SPECKIT', '99.0.0', 'Process')
    [Environment]::SetEnvironmentVariable('SPECREW_UPDATE_LATEST_SQUAD', '99.0.0', 'Process')
    # Proposal 079: align supported-max with upstream-latest so tests exercise the "supported update available" path.
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SPECKIT', '99.0.0', 'Process')
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SQUAD', '99.0.0', 'Process')

    Write-Host "`nTest 1: update help advertises the command surface"
    $helpResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('update', '--help')
    if ($helpResult.ExitCode -ne 0) {
        Write-Fail 'specrew update --help failed'
        exit 1
    }

    $helpOutput = $helpResult.Output -join "`n"
    foreach ($pattern in @('specrew update', '--info', '--all', '--spec-kit', '--squad')) {
        if (-not (Assert-Contains -Content $helpOutput -Pattern $pattern -FailureMessage ("Help output is missing '{0}'." -f $pattern))) {
            exit 1
        }
    }
    Write-Pass 'Help output includes update command options'

    Write-Host "`nTest 2: info mode reports versions and does not mutate project config"
    Set-ConfigValue -ConfigPath $configPath -Key 'specrew_version' -Value '0.0.1'
    $configBeforeInfo = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8

    $infoResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('update', '--project-path', $projectRoot, '--info')
    if ($infoResult.ExitCode -ne 0) {
        Write-Fail 'specrew update --info failed'
        foreach ($line in $infoResult.Output) {
            Write-Host $line
        }
        exit 1
    }

    $infoOutput = $infoResult.Output -join "`n"
    foreach ($pattern in @('Version info', 'Specrew', 'Spec Kit', 'Squad', '99\.0\.0')) {
        if (-not (Assert-Contains -Content $infoOutput -Pattern $pattern -FailureMessage ("Info output is missing '{0}'." -f $pattern))) {
            exit 1
        }
    }

    $configAfterInfo = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
    if ($configAfterInfo -ne $configBeforeInfo) {
        Write-Fail 'specrew update --info mutated .specrew\config.yml'
        exit 1
    }
    Write-Pass 'Info mode is read-only and reports all platforms'

    Write-Host "`nTest 3: bare specrew update refreshes Specrew-managed assets only"
    [System.IO.File]::WriteAllText($installedExtensionReadmePath, "stale extension content`n", [System.Text.UTF8Encoding]::new($false))
    Set-ConfigValue -ConfigPath $configPath -Key 'specrew_version' -Value '0.0.1'

    $defaultUpdateResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('update', '--project-path', $projectRoot)
    if ($defaultUpdateResult.ExitCode -ne 0) {
        Write-Fail 'bare specrew update failed'
        foreach ($line in $defaultUpdateResult.Output) {
            Write-Host $line
        }
        exit 1
    }

    $updatedReadme = Get-Content -LiteralPath $installedExtensionReadmePath -Raw -Encoding UTF8
    $sourceReadme = Get-Content -LiteralPath $extensionReadmePath -Raw -Encoding UTF8
    if ($updatedReadme -ne $sourceReadme) {
        Write-Fail 'Bare specrew update did not refresh the managed Spec Kit extension asset.'
        exit 1
    }

    $updatedSpecrewVersion = Get-ConfigValue -ConfigPath $configPath -Key 'specrew_version'
    if ($updatedSpecrewVersion -ne $sourceSpecrewVersion) {
        Write-Fail ("Bare specrew update did not refresh specrew_version in config.yml (expected {0}, found {1})." -f $sourceSpecrewVersion, $updatedSpecrewVersion)
        exit 1
    }

    $defaultUpdateOutput = $defaultUpdateResult.Output -join "`n"
    if (-not (Assert-Contains -Content $defaultUpdateOutput -Pattern 'Additional platform updates are available' -FailureMessage 'Bare specrew update did not notify about newer Squad / Spec Kit versions.')) {
        exit 1
    }
    if (-not (Assert-Contains -Content $defaultUpdateOutput -Pattern '99\.0\.0' -FailureMessage 'Bare specrew update did not report the newer latest-known platform versions.')) {
        exit 1
    }
    Write-Pass 'Bare specrew update refreshes Specrew-managed assets and leaves broader upgrades explicit'

    Write-Host "`nTest 4: --all honors explicit scopes without upgrading already-current platforms"
    [Environment]::SetEnvironmentVariable('SPECREW_UPDATE_LATEST_SPECKIT', $currentSpecKitVersion, 'Process')
    [Environment]::SetEnvironmentVariable('SPECREW_UPDATE_LATEST_SQUAD', $currentSquadVersion, 'Process')
    # Proposal 079: realign max-tested to current so status is 'current' (no upgrade needed).
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SPECKIT', $currentSpecKitVersion, 'Process')
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SQUAD', $currentSquadVersion, 'Process')

    $allResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('update', '--project-path', $projectRoot, '--all')
    if ($allResult.ExitCode -ne 0) {
        Write-Fail 'specrew update --all failed when platforms were already current'
        foreach ($line in $allResult.Output) {
            Write-Host $line
        }
        exit 1
    }

    $allOutput = $allResult.Output -join "`n"
    foreach ($pattern in @('already-current', 'Spec Kit', 'Squad')) {
        if (-not (Assert-Contains -Content $allOutput -Pattern $pattern -FailureMessage ("Update --all output is missing '{0}'." -f $pattern))) {
            exit 1
        }
    }
    Write-Pass '--all handles explicit platform scopes without unnecessary upgrades'

    Write-Host "`nTest 5: --spec-kit does not mutate specrew_version (regression coverage for 94b44d7)"
    $preserveTestSpecrewVersion = '0.99.0'
    Set-ConfigValue -ConfigPath $configPath -Key 'specrew_version' -Value $preserveTestSpecrewVersion

    $specKitOnlyResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('update', '--project-path', $projectRoot, '--spec-kit')
    if ($specKitOnlyResult.ExitCode -ne 0) {
        Write-Fail 'specrew update --spec-kit failed'
        foreach ($line in $specKitOnlyResult.Output) {
            Write-Host $line
        }
        exit 1
    }

    $specrewVersionAfterSpecKit = Get-ConfigValue -ConfigPath $configPath -Key 'specrew_version'
    if ($specrewVersionAfterSpecKit -ne $preserveTestSpecrewVersion) {
        Write-Fail ("specrew update --spec-kit mutated specrew_version (expected '{0}', found '{1}'). Regression of bug fixed in 94b44d7." -f $preserveTestSpecrewVersion, $specrewVersionAfterSpecKit)
        exit 1
    }
    Write-Pass '--spec-kit preserves specrew_version (no-mutation contract holds)'

    Write-Host "`nTest 6: --squad does not mutate specrew_version (regression coverage for 94b44d7)"
    Set-ConfigValue -ConfigPath $configPath -Key 'specrew_version' -Value $preserveTestSpecrewVersion

    $squadOnlyResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('update', '--project-path', $projectRoot, '--squad')
    if ($squadOnlyResult.ExitCode -ne 0) {
        Write-Fail 'specrew update --squad failed'
        foreach ($line in $squadOnlyResult.Output) {
            Write-Host $line
        }
        exit 1
    }

    $specrewVersionAfterSquad = Get-ConfigValue -ConfigPath $configPath -Key 'specrew_version'
    if ($specrewVersionAfterSquad -ne $preserveTestSpecrewVersion) {
        Write-Fail ("specrew update --squad mutated specrew_version (expected '{0}', found '{1}'). Regression of bug fixed in 94b44d7." -f $preserveTestSpecrewVersion, $specrewVersionAfterSquad)
        exit 1
    }
    Write-Pass '--squad preserves specrew_version (no-mutation contract holds)'

    Write-Host "`nTest 7: --info --upstream-latest suppresses advisory and uses two-state status (Proposal 079 AC5)"
    # Restore upstream-latest > max_tested scenario (current behind upstream)
    [Environment]::SetEnvironmentVariable('SPECREW_UPDATE_LATEST_SPECKIT', '99.0.0', 'Process')
    [Environment]::SetEnvironmentVariable('SPECREW_UPDATE_LATEST_SQUAD', '99.0.0', 'Process')
    # Set max_tested BELOW upstream so default --info shows 'ahead-of-supported' + advisory
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SPECKIT', $currentSpecKitVersion, 'Process')
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SQUAD', $currentSquadVersion, 'Process')

    $defaultInfoResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('update', '--project-path', $projectRoot, '--info')
    if ($defaultInfoResult.ExitCode -ne 0) {
        Write-Fail 'specrew update --info (default) failed'
        exit 1
    }
    $defaultInfoOutput = $defaultInfoResult.Output -join "`n"
    if (-not (Assert-Contains -Content $defaultInfoOutput -Pattern 'Specrew has validated only through' -FailureMessage 'Default --info should surface advisory line when upstream > max_tested')) {
        exit 1
    }
    Write-Pass 'Default --info surfaces advisory when upstream beyond max_tested'

    $upstreamInfoResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('update', '--project-path', $projectRoot, '--info', '--upstream-latest')
    if ($upstreamInfoResult.ExitCode -ne 0) {
        Write-Fail 'specrew update --info --upstream-latest failed'
        foreach ($line in $upstreamInfoResult.Output) {
            Write-Host $line
        }
        exit 1
    }
    $upstreamInfoOutput = $upstreamInfoResult.Output -join "`n"
    if ($upstreamInfoOutput -match 'Specrew has validated only through') {
        Write-Fail '--info --upstream-latest should NOT surface the advisory (user opted into upstream view)'
        exit 1
    }
    if (-not (Assert-Contains -Content $upstreamInfoOutput -Pattern 'update-available' -FailureMessage '--info --upstream-latest should show two-state update-available status')) {
        exit 1
    }
    if ($upstreamInfoOutput -match 'update-available-supported') {
        Write-Fail '--info --upstream-latest should NOT show four-state update-available-supported status'
        exit 1
    }
    Write-Pass '--info --upstream-latest suppresses advisory + uses two-state status'

    Write-Host "`nTest 8: --upstream-latest is in the slash-command argument whitelist"
    $whitelistResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('update', '--info', '--upstream-latest', '--skip-update-check', '--project-path', $projectRoot)
    if ($whitelistResult.ExitCode -ne 0) {
        Write-Fail 'specrew update --info --upstream-latest --skip-update-check failed (whitelist rejection?)'
        foreach ($line in $whitelistResult.Output) {
            Write-Host $line
        }
        exit 1
    }
    if (($whitelistResult.Output -join "`n") -match 'Unsupported argument') {
        Write-Fail '--upstream-latest should be in the update-command whitelist'
        exit 1
    }
    Write-Pass '--upstream-latest passes whitelist check'
}
finally {
    [Environment]::SetEnvironmentVariable('SPECREW_UPDATE_LATEST_SPECREW', $originalSpecrewOverride, 'Process')
    [Environment]::SetEnvironmentVariable('SPECREW_UPDATE_LATEST_SPECKIT', $originalSpecKitOverride, 'Process')
    [Environment]::SetEnvironmentVariable('SPECREW_UPDATE_LATEST_SQUAD', $originalSquadOverride, 'Process')
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SPECKIT', $originalSpecKitMaxOverride, 'Process')
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SQUAD', $originalSquadMaxOverride, 'Process')
}

Write-Host "`nAll update command tests passed." -ForegroundColor Green
exit 0

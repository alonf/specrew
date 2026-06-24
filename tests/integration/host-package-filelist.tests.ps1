[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) throw "FAIL: $Message" }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$generator = Join-Path $repoRoot 'scripts\internal\update-host-package-filelist.ps1'
. $generator

# Real tree must already be the deterministic generated projection.
$real = Update-SpecrewHostPackageFileList -ProjectRoot $repoRoot -Check
if ($real.HostEntryCount -ne 15) {
    Write-Fail "Expected 15 generated host package entries for five three-file packages; got $($real.HostEntryCount)."
}
Write-Pass 'Real Specrew.psd1 host-package projection is generation-clean'

$scratch = Join-Path $repoRoot ('.scratch\host-package-filelist-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path (Join-Path $scratch 'hosts\alpha') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch 'hosts\beta') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch 'scripts') -Force | Out-Null

    foreach ($kind in @('alpha', 'beta')) {
        $hostRoot = Join-Path $scratch "hosts\$kind"
        Set-Content -LiteralPath (Join-Path $hostRoot 'host.psd1') -Encoding UTF8 -Value "@{ Kind = '$kind' }"
        Set-Content -LiteralPath (Join-Path $hostRoot 'handlers.ps1') -Encoding UTF8 -Value "# $kind handlers"
        Set-Content -LiteralPath (Join-Path $hostRoot 'coordinator-rules.psd1') -Encoding UTF8 -Value '@{ Rules = @() }'
    }
    Set-Content -LiteralPath (Join-Path $scratch 'hosts\beta\hook-adapter.ps1') -Encoding UTF8 -Value '# package-private adapter'
    Set-Content -LiteralPath (Join-Path $scratch 'scripts\keep.ps1') -Encoding UTF8 -Value '# non-host entry'
    Set-Content -LiteralPath (Join-Path $scratch 'Specrew.psd1') -Encoding UTF8 -Value @'
@{
    FileList = @(
        'scripts/keep.ps1',
        'hosts/stale/host.psd1'
    )
    PrivateData = @{
    }
}
'@

    $first = Update-SpecrewHostPackageFileList -ProjectRoot $scratch
    if (-not $first.Changed) { Write-Fail 'Fixture generation should replace the stale host projection.' }
    $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $scratch 'Specrew.psd1')
    $actual = @($manifest.FileList | ForEach-Object { [string]$_ })
    $expectedHostFiles = @(
        'hosts/alpha/coordinator-rules.psd1',
        'hosts/alpha/handlers.ps1',
        'hosts/alpha/host.psd1',
        'hosts/beta/coordinator-rules.psd1',
        'hosts/beta/handlers.ps1',
        'hosts/beta/hook-adapter.ps1',
        'hosts/beta/host.psd1'
    )
    foreach ($expected in @($expectedHostFiles + 'scripts/keep.ps1')) {
        if ($expected -notin $actual) { Write-Fail "Generated FileList is missing '$expected'." }
    }
    if (@($actual | Where-Object { $_ -like 'hosts/stale/*' }).Count -ne 0) {
        Write-Fail 'Stale host-package entries survived regeneration.'
    }
    $ordinal = [string[]]@($actual)
    $ordinalKeys = [string[]]@($ordinal | ForEach-Object { $_.ToLowerInvariant() })
    [Array]::Sort($ordinalKeys, $ordinal, [System.StringComparer]::Ordinal)
    if (($actual -join "`n") -cne ($ordinal -join "`n")) {
        Write-Fail 'Generated FileList order is not ordinal/deterministic.'
    }
    $second = Update-SpecrewHostPackageFileList -ProjectRoot $scratch
    if ($second.Changed) { Write-Fail 'Second generation should be byte-idempotent.' }
    $null = Update-SpecrewHostPackageFileList -ProjectRoot $scratch -Check
    Write-Pass 'Fixture generation removes stale rows, includes package-private files, sorts ordinally, and is idempotent'

    $manifestPath = Join-Path $scratch 'Specrew.psd1'
    $manifestContent = Get-Content -LiteralPath $manifestPath -Raw
    $duplicateContent = $manifestContent.Replace(
        "        'scripts/keep.ps1'",
        "        'scripts/keep.ps1',`r`n        'scripts/keep.ps1'"
    )
    Set-Content -LiteralPath $manifestPath -Encoding UTF8 -Value $duplicateContent -NoNewline
    $duplicateError = ''
    try { Update-SpecrewHostPackageFileList -ProjectRoot $scratch | Out-Null }
    catch { $duplicateError = $_.Exception.Message }
    if ($duplicateError -notmatch 'Duplicate FileList entries') {
        Write-Fail "Duplicate FileList input did not fail clearly: $duplicateError"
    }
    Set-Content -LiteralPath $manifestPath -Encoding UTF8 -Value $manifestContent -NoNewline
    Write-Pass 'Duplicate FileList paths fail generation'

    $escapeTarget = Join-Path $scratch 'escape-target'
    $escapeLink = Join-Path $scratch 'hosts\beta\escape-link'
    New-Item -ItemType Directory -Path $escapeTarget -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $escapeTarget 'escaped.ps1') -Encoding UTF8 -Value '# outside the host package'
    $linkType = if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }
    New-Item -ItemType $linkType -Path $escapeLink -Target $escapeTarget | Out-Null
    $escapeError = ''
    try { Update-SpecrewHostPackageFileList -ProjectRoot $scratch | Out-Null }
    catch { $escapeError = $_.Exception.Message }
    if ($escapeError -notmatch 'reparse-point directory') {
        Write-Fail "Escaping package link did not fail clearly: $escapeError"
    }
    Remove-Item -LiteralPath $escapeLink -Force
    Write-Pass 'Escaping package links fail generation'

    New-Item -ItemType Directory -Path (Join-Path $scratch 'hosts\gamma') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch 'hosts\gamma\host.psd1') -Encoding UTF8 -Value "@{ Kind = 'gamma' }"
    Set-Content -LiteralPath (Join-Path $scratch 'hosts\gamma\handlers.ps1') -Encoding UTF8 -Value '# gamma handlers'
    Set-Content -LiteralPath (Join-Path $scratch 'hosts\gamma\coordinator-rules.psd1') -Encoding UTF8 -Value '@{ Rules = @() }'
    $null = Update-SpecrewHostPackageFileList -ProjectRoot $scratch
    $withFixtureHost = Import-PowerShellDataFile -LiteralPath (Join-Path $scratch 'Specrew.psd1')
    foreach ($required in @('host.psd1', 'handlers.ps1', 'coordinator-rules.psd1')) {
        if ("hosts/gamma/$required" -notin @($withFixtureHost.FileList)) {
            Write-Fail "Folder-only fixture host did not generate '$required'."
        }
    }
    Write-Pass 'A fixture host is packaged by adding its folder only'

    Remove-Item -LiteralPath (Join-Path $scratch 'hosts\gamma\handlers.ps1') -Force
    $missingError = ''
    try { Update-SpecrewHostPackageFileList -ProjectRoot $scratch | Out-Null }
    catch { $missingError = $_.Exception.Message }
    if ($missingError -notmatch "missing required file 'handlers.ps1'") {
        Write-Fail "Missing required package file did not fail clearly: $missingError"
    }
    Write-Pass 'Missing required host package files fail generation before manifest mutation'

    Set-Content -LiteralPath (Join-Path $scratch 'hosts\gamma\handlers.ps1') -Encoding UTF8 -Value '# gamma handlers'
    Set-Content -LiteralPath (Join-Path $scratch 'hosts\gamma\host.psd1') -Encoding UTF8 -Value "@{ Kind = 'other' }"
    $kindError = ''
    try { Update-SpecrewHostPackageFileList -ProjectRoot $scratch | Out-Null }
    catch { $kindError = $_.Exception.Message }
    if ($kindError -notmatch 'exact matching manifest Kind') {
        Write-Fail "Folder/Kind mismatch did not fail clearly: $kindError"
    }
    Write-Pass 'Folder/manifest Kind mismatch fails generation'
}
finally {
    if (Test-Path -LiteralPath $scratch) {
        Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`nHost-package FileList generation: all assertions pass" -ForegroundColor Green

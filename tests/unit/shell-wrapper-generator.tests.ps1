[CmdletBinding()]
param()

# Unit tests for scripts/internal/generate-shell-wrappers.ps1 (feature 140 / T005).
# Exercises the REAL generator against a synthetic module tree (registry parsing,
# template rendering, LF output, thin alias->subcommand dispatch, idempotency, and
# the -Check drift mode: in-sync / tampered / missing / extra).

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; throw $m }

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$generator = Join-Path $repoRoot 'scripts/internal/generate-shell-wrappers.ps1'
if (-not (Test-Path -LiteralPath $generator)) { Write-Fail "generator not found: $generator" }

function Invoke-Generator {
    param([string]$Root, [switch]$Check)
    if ($Check) {
        & pwsh -NoProfile -File $generator -RepoRoot $Root -Check *> $null
    }
    else {
        & pwsh -NoProfile -File $generator -RepoRoot $Root *> $null
    }
    return $LASTEXITCODE
}

$testRoot = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "specrew-genwrap-$([System.IO.Path]::GetRandomFileName())")
$bin = Join-Path $testRoot 'bin'

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot 'scripts') | Out-Null
    Set-Content -LiteralPath (Join-Path $testRoot 'scripts/specrew.ps1') -Value '# dummy dispatcher' -Encoding utf8 -NoNewline
    Set-Content -LiteralPath (Join-Path $testRoot 'Specrew.psd1') -Value @'
@{
  ModuleVersion = '0.0.1'
  AliasesToExport = @('specrew', 'specrew-init', 'specrew-foo')
}
'@ -Encoding utf8

    if ((Invoke-Generator -Root $testRoot) -ne 0) { Write-Fail 'generator exited non-zero' }
    foreach ($n in 'specrew', 'specrew-init', 'specrew-foo') {
        if (-not (Test-Path -LiteralPath (Join-Path $bin $n))) { Write-Fail "missing bin/$n" }
    }
    Write-Pass 'generator creates one wrapper per registry alias (root + 2)'

    $rootContent = [System.IO.File]::ReadAllText((Join-Path $bin 'specrew'))
    if ($rootContent -match "`r") { Write-Fail 'bin/specrew contains CR; wrappers must be LF-only' }
    Write-Pass 'generated wrappers are LF-only'

    if ($rootContent -notmatch 'specrew\.ps1" "\$@"') { Write-Fail 'root wrapper must exec specrew.ps1 with no subcommand' }
    $initContent = [System.IO.File]::ReadAllText((Join-Path $bin 'specrew-init'))
    if ($initContent -notmatch 'specrew\.ps1" init "\$@"') { Write-Fail 'specrew-init must dispatch the init subcommand' }
    $fooContent = [System.IO.File]::ReadAllText((Join-Path $bin 'specrew-foo'))
    if ($fooContent -notmatch 'specrew\.ps1" foo "\$@"') { Write-Fail 'specrew-foo must dispatch the foo subcommand' }
    Write-Pass 'root has no subcommand; aliases dispatch their subcommand (thin alias->subcommand)'

    if ($rootContent -notmatch 'command -v pwsh') { Write-Fail 'wrapper missing pwsh presence check' }
    if ($rootContent -notmatch 'while \[ -L') { Write-Fail 'wrapper missing symlink-resolution loop' }
    if ($rootContent -match 'getopts') { Write-Fail 'wrapper must not parse options (getopts found)' }
    Write-Pass 'wrappers are thin forwarders (pwsh check + symlink loop; no option parsing)'

    $before = (Get-FileHash (Join-Path $bin 'specrew')).Hash
    if ((Invoke-Generator -Root $testRoot) -ne 0) { Write-Fail 'second generation exited non-zero' }
    $after = (Get-FileHash (Join-Path $bin 'specrew')).Hash
    if ($before -ne $after) { Write-Fail 'generator is not idempotent (byte differ on re-run)' }
    Write-Pass 'generator is idempotent (byte-identical re-run)'

    if ((Invoke-Generator -Root $testRoot -Check) -ne 0) { Write-Fail '-Check should pass when wrappers are in sync' }
    Write-Pass '-Check passes when wrappers are in sync'

    Add-Content -LiteralPath (Join-Path $bin 'specrew') -Value '# tamper'
    if ((Invoke-Generator -Root $testRoot -Check) -eq 0) { Write-Fail '-Check should fail on a tampered wrapper' }
    Write-Pass '-Check fails on drift (tampered wrapper)'

    Invoke-Generator -Root $testRoot | Out-Null
    Remove-Item -LiteralPath (Join-Path $bin 'specrew-foo') -Force
    if ((Invoke-Generator -Root $testRoot -Check) -eq 0) { Write-Fail '-Check should fail on a missing wrapper' }
    Write-Pass '-Check fails on drift (missing wrapper)'

    Invoke-Generator -Root $testRoot | Out-Null
    Set-Content -LiteralPath (Join-Path $bin 'specrew-extra') -Value '# extra' -Encoding utf8
    if ((Invoke-Generator -Root $testRoot -Check) -eq 0) { Write-Fail '-Check should fail on an extra wrapper not in the registry' }
    Write-Pass '-Check fails on drift (extra wrapper not in registry)'
}
finally {
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -Recurse -Force -LiteralPath $testRoot -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host 'All shell-wrapper-generator tests passed.' -ForegroundColor Green

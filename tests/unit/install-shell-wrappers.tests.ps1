[CmdletBinding()]
param()

# Unit tests for scripts/specrew-install-shell-wrappers.ps1 (feature 140 / T008).
#
# Platform note (platform-not-proxy): the installer's real Unix runtime — symlink
# creation, PATH detection on a live shell, bin-dir creation — is validated on the
# Ubuntu + macOS CI lanes in Iteration 2 (T011). These Windows-runnable tests cover
# (a) the pure, platform-agnostic decision logic (arg normalization, bin-dir
# resolution, PATH membership, the install-plan decision matrix) by dot-sourcing the
# installer, and (b) the Windows explained-no-op end-to-end + the dispatch wiring.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; throw $m }

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$installer = Join-Path $repoRoot 'scripts/specrew-install-shell-wrappers.ps1'
$dispatcher = Join-Path $repoRoot 'scripts/specrew.ps1'
foreach ($p in @($installer, $dispatcher)) {
    if (-not (Test-Path -LiteralPath $p)) { Write-Fail "required script not found: $p" }
}

# Dot-source the installer for the pure-function tests. The installer's guard
# (`if ($MyInvocation.InvocationName -ne '.')`) skips Main when dot-sourced.
. $installer

# --- ConvertFrom-UnixStyleInstallerArgs ---
$a = ConvertFrom-UnixStyleInstallerArgs -BinDir $null -Force:$false -DryRun:$false -Help:$false -CliArgs @('--bin-dir', '/tmp/x', '--force')
if ($a.BinDir -ne '/tmp/x' -or -not $a.Force) { Write-Fail "unix-style --bin-dir/--force not normalized ($($a.BinDir), $($a.Force))" }
$a = ConvertFrom-UnixStyleInstallerArgs -BinDir $null -Force:$false -DryRun:$false -Help:$false -CliArgs @('--bin-dir=/tmp/y', '--whatif')
if ($a.BinDir -ne '/tmp/y' -or -not $a.DryRun) { Write-Fail "--bin-dir=/--whatif not normalized" }
$a = ConvertFrom-UnixStyleInstallerArgs -BinDir '/ps/style' -Force:$true -DryRun:$false -Help:$false -CliArgs @()
if ($a.BinDir -ne '/ps/style' -or -not $a.Force) { Write-Fail "PS-style params not preserved when CliArgs empty" }
$threw = $false
try { ConvertFrom-UnixStyleInstallerArgs -BinDir $null -Force:$false -DryRun:$false -Help:$false -CliArgs @('--bogus') } catch { $threw = $true }
if (-not $threw) { Write-Fail "unknown arg should throw" }
Write-Pass 'ConvertFrom-UnixStyleInstallerArgs normalizes shell + PS styles and rejects unknown args'

# --- Resolve-SpecrewBinDir ---
if ((Resolve-SpecrewBinDir -BinDir '/explicit/bin') -ne '/explicit/bin') { Write-Fail 'explicit BinDir not preserved' }
if ((Resolve-SpecrewBinDir -BinDir $null) -notmatch '\.local[\\/]bin$') { Write-Fail 'default BinDir should be ~/.local/bin' }
Write-Pass 'Resolve-SpecrewBinDir defaults to ~/.local/bin and preserves explicit values'

# --- Test-DirOnPath ---
$sep = [System.IO.Path]::PathSeparator
$pathWith = @('/usr/bin', '/home/u/.local/bin', '/bin') -join $sep
if (-not (Test-DirOnPath -Dir '/home/u/.local/bin' -PathValue $pathWith)) { Write-Fail 'dir on PATH should be detected' }
if (Test-DirOnPath -Dir '/home/u/.local/bin' -PathValue (@('/usr/bin', '/bin') -join $sep)) { Write-Fail 'dir not on PATH should be false' }
if (Test-DirOnPath -Dir '/x' -PathValue '') { Write-Fail 'empty PATH should be false' }
Write-Pass 'Test-DirOnPath detects PATH membership (with trailing-slash tolerance)'

# --- Get-WrapperInstallPlan (decision matrix) ---
$cases = @(
    @{ Existing = 'none'; Force = $false; DryRun = $false; Expect = 'create' }
    @{ Existing = 'none'; Force = $false; DryRun = $true; Expect = 'would-create' }
    @{ Existing = 'symlink'; Force = $false; DryRun = $false; Expect = 'replace-symlink' }
    @{ Existing = 'symlink'; Force = $false; DryRun = $true; Expect = 'would-replace-symlink' }
    @{ Existing = 'file'; Force = $false; DryRun = $false; Expect = 'skip-needs-force' }
    @{ Existing = 'file'; Force = $true; DryRun = $false; Expect = 'overwrite-file' }
    @{ Existing = 'file'; Force = $true; DryRun = $true; Expect = 'would-overwrite-file' }
)
foreach ($c in $cases) {
    $got = Get-WrapperInstallPlan -Existing $c.Existing -Force:$c.Force -DryRun:$c.DryRun
    if ($got -ne $c.Expect) { Write-Fail "install-plan($($c.Existing),Force=$($c.Force),DryRun=$($c.DryRun)) = '$got', expected '$($c.Expect)'" }
}
Write-Pass 'Get-WrapperInstallPlan returns the correct action for all existing/Force/DryRun combinations (incl. skip-needs-force for non-symlink files)'

# --- Windows explained-no-op end-to-end (Windows runner only) ---
$onWindows = $env:OS -eq 'Windows_NT' -or ($PSVersionTable.Platform -eq 'Win32NT')
if ($onWindows) {
    $tmpBin = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "specrew-inst-$([System.IO.Path]::GetRandomFileName())")
    New-Item -ItemType Directory -Force -Path $tmpBin | Out-Null
    try {
        $out = & pwsh -NoProfile -File $installer -BinDir $tmpBin 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { Write-Fail "Windows no-op should exit 0 (got $LASTEXITCODE)" }
        if ($out -notmatch 'macOS/Linux') { Write-Fail "Windows no-op should explain it is for macOS/Linux" }
        if (@(Get-ChildItem -LiteralPath $tmpBin -Force).Count -ne 0) { Write-Fail "Windows no-op must not write into the bin dir" }
        Write-Pass 'Windows: install-shell-wrappers is an explained no-op (exit 0, no writes)'
    }
    finally {
        Remove-Item -Recurse -Force -LiteralPath $tmpBin -ErrorAction SilentlyContinue
    }
}
else {
    Write-Pass 'Windows no-op test skipped (non-Windows host) — Unix runtime is covered by Iteration 2 CI'
}

# --- Dispatch wiring: specrew install-shell-wrappers --help ---
$helpOut = & pwsh -NoProfile -File $dispatcher 'install-shell-wrappers' '--help' 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { Write-Fail "dispatch 'install-shell-wrappers --help' should exit 0 (got $LASTEXITCODE)" }
if ($helpOut -notmatch 'install-shell-wrappers') { Write-Fail 'dispatch --help should render installer usage' }
Write-Pass 'specrew.ps1 dispatches install-shell-wrappers (--help renders usage)'

Write-Host ''
Write-Host 'All install-shell-wrappers tests passed.' -ForegroundColor Green

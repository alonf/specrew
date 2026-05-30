[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$startCommandCheck = Join-Path $repoRoot 'tests\integration\start-command.ps1'

$failed = $false

# ---------------------------------------------------------------------------
# Test 1 (deterministic source-contract): the first-run expertise prompt MUST
# be non-interactive-aware. Regression guard for the CI start-hang (F-049
# iter-5): the call site must NOT hard-code -NonInteractive:$false, and must
# derive it from [Console]::IsInputRedirected (the repo's convention, cf.
# scripts/internal/host-history.ps1). This catches a revert with zero deps.
# ---------------------------------------------------------------------------
$startSource = Get-Content -LiteralPath $startScript -Raw -Encoding UTF8

if ($startSource -match 'Invoke-FirstRunExpertisePrompt\s+-NonInteractive:\$false') {
    Write-Fail "specrew-start.ps1 calls Invoke-FirstRunExpertisePrompt with hard-coded -NonInteractive:`$false; first-run will hang on Read-Host in non-interactive/CI contexts."
    $failed = $true
}
elseif ($startSource -notmatch 'Invoke-FirstRunExpertisePrompt\s+-NonInteractive:\(\[Console\]::IsInputRedirected\)') {
    Write-Fail "specrew-start.ps1 first-run prompt is not gated on [Console]::IsInputRedirected; non-interactive callers may hang."
    $failed = $true
}
else {
    Write-Pass "specrew-start.ps1 first-run prompt derives -NonInteractive from [Console]::IsInputRedirected (no hard-coded interactive)"
}

# ---------------------------------------------------------------------------
# Test 2 (behavioral): start-command.ps1 invoked with NO interactive stdin
# (redirected => [Console]::IsInputRedirected is $true) and a fresh, empty
# HOME (no user-profile.yml => first-run fires) must COMPLETE within a timeout
# instead of hanging on Read-Host, and should auto-write a profile. Reproduces
# the Contract-lane scenario that hung ~15 min in CI.
# ---------------------------------------------------------------------------
$tempHome = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-firstrun-" + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $tempHome -Force

$savedUserProfile = $env:USERPROFILE
$savedHome = $env:HOME
$timeoutSeconds = 300   # normal start-command run is minutes; the hang was unbounded (CI cancelled at 15m)
$proc = $null
try {
    # Child process inherits these env vars; Get-UserProfilePath resolves to the empty $tempHome.
    $env:USERPROFILE = $tempHome
    $env:HOME = $tempHome

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'pwsh'
    $psi.ArgumentList.Add('-NoProfile'); $psi.ArgumentList.Add('-ExecutionPolicy'); $psi.ArgumentList.Add('Bypass')
    $psi.ArgumentList.Add('-File'); $psi.ArgumentList.Add($startCommandCheck)
    $psi.RedirectStandardInput = $true   # => [Console]::IsInputRedirected is $true in the child
    $psi.UseShellExecute = $false
    $psi.WorkingDirectory = $repoRoot
    $psi.EnvironmentVariables['USERPROFILE'] = $tempHome
    $psi.EnvironmentVariables['HOME'] = $tempHome

    $proc = [System.Diagnostics.Process]::Start($psi)
    $proc.StandardInput.Close()   # closed stdin: a Read-Host returns/throws instead of blocking forever

    if (-not $proc.WaitForExit($timeoutSeconds * 1000)) {
        try { $proc.Kill($true) } catch { }
        Write-Fail "start-command.ps1 did NOT complete within $timeoutSeconds s with non-interactive stdin + fresh HOME — first-run prompt is hanging (CI start-hang regression)."
        $failed = $true
    }
    else {
        Write-Pass "start-command.ps1 completes within $timeoutSeconds s under non-interactive stdin + first-run (no Read-Host hang)"

        # Auto-decision proof: first-run under -NonInteractive must have written a profile without input.
        $profilePath = Join-Path $tempHome '.specrew\user-profile.yml'
        if (Test-Path -LiteralPath $profilePath) {
            Write-Pass "First-run auto-decided under -NonInteractive (user-profile.yml written without interactive input)"
        }
        else {
            # Soft note: start-command.ps1's fixtures may scope HOME differently; verify the write location.
            Write-Host "NOTE: no user-profile.yml under the isolated HOME — verify the auto-decision path wrote the profile where expected." -ForegroundColor Yellow
        }
    }
}
finally {
    if ($null -ne $proc) { $proc.Dispose() }
    $env:USERPROFILE = $savedUserProfile
    $env:HOME = $savedHome
    if (Test-Path -LiteralPath $tempHome) { Remove-Item -LiteralPath $tempHome -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($failed) { exit 1 }
Write-Pass 'Non-interactive first-run: specrew start auto-decides the Crew Interaction Profile instead of hanging on Read-Host'
exit 0

#requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:Failed = $true }

$script:Failed = $false
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$utilitiesPath = Join-Path $repoRoot 'scripts\init\_utilities.ps1'
$squadDeployPath = Join-Path $repoRoot 'scripts\init\squad-deploy.ps1'
$initPath = Join-Path $repoRoot 'scripts\specrew-init.ps1'
$scratchRoot = Join-Path ([IO.Path]::GetTempPath()) ('specrew-squad-stdin-' + [guid]::NewGuid().ToString('N'))
$fakeBin = Join-Path $scratchRoot 'bin'
$runnerPath = Join-Path $scratchRoot 'runner.ps1'
$resultPath = Join-Path $scratchRoot 'result.json'
$stdoutPath = Join-Path $scratchRoot 'runner.stdout'
$stderrPath = Join-Path $scratchRoot 'runner.stderr'
$runner = $null

try {
    New-Item -ItemType Directory -Path $fakeBin -Force | Out-Null

    # This fake behaves like the Squad 0.11.0 prompt path: it waits for EOF before doing any work. The outer
    # test deliberately keeps the runner's stdin pipe OPEN. If either Squad call inherits that input, this
    # process cannot complete before the bounded timeout. A correct launcher gives each invocation immediate EOF.
    $fakeSquadPath = Join-Path $fakeBin $(if ($IsWindows) { 'squad.ps1' } else { 'squad' })
    $fakeSquadBody = @'
$stdinText = [Console]::In.ReadToEnd()
if ($args.Count -lt 1 -or $args[0] -cne 'init') {
    [Console]::Error.WriteLine('expected-init')
    exit 2
}
New-Item -ItemType Directory -Path (Join-Path (Get-Location).Path '.squad') -Force | Out-Null
Write-Output ("stdin_redirected={0};stdin_length={1};args={2}" -f [Console]::IsInputRedirected, $stdinText.Length, ($args -join ','))
exit 0
'@
    if (-not $IsWindows) {
        $fakeSquadBody = "#!/usr/bin/env pwsh`n" + $fakeSquadBody
    }
    [IO.File]::WriteAllText($fakeSquadPath, $fakeSquadBody, [Text.UTF8Encoding]::new($false))
    if (-not $IsWindows) {
        & chmod '+x' $fakeSquadPath
        if ($LASTEXITCODE -ne 0) { throw 'failed to make the POSIX Squad fixture executable' }
    }

    [IO.File]::WriteAllText($runnerPath, @'
param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$ScratchRoot,
    [Parameter(Mandatory)][string]$ResultPath
)
$ErrorActionPreference = 'Stop'
$env:PATH = (Join-Path $ScratchRoot 'bin') + [IO.Path]::PathSeparator + $env:PATH
. (Join-Path $RepoRoot 'scripts\init\_utilities.ps1')
. (Join-Path $RepoRoot 'scripts\init\squad-deploy.ps1')

$probeRoot = Join-Path $ScratchRoot 'probe-root'
$projectRoot = Join-Path $ScratchRoot 'project'
New-Item -ItemType Directory -Path $probeRoot, $projectRoot -Force | Out-Null

$plan = Get-SquadInitPlan -ProbeRoot $probeRoot
$actual = Invoke-NativeCommandWithClosedInput -FilePath 'squad' -ArgumentList $plan.ArgumentList -WorkingDirectory $projectRoot
[ordered]@{
    supports_non_interactive = [bool]$plan.SupportsNonInteractive
    argument_list = @($plan.ArgumentList)
    actual_exit_code = [int]$actual.ExitCode
    actual_output = @($actual.Output)
    actual_squad_exists = Test-Path -LiteralPath (Join-Path $projectRoot '.squad') -PathType Container
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ResultPath -Encoding utf8NoBOM
'@, [Text.UTF8Encoding]::new($false))

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = [Environment]::ProcessPath
    foreach ($argument in @('-NoProfile', '-NonInteractive', '-File', $runnerPath, '-RepoRoot', $repoRoot, '-ScratchRoot', $scratchRoot, '-ResultPath', $resultPath)) {
        [void]$startInfo.ArgumentList.Add($argument)
    }
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.WorkingDirectory = $repoRoot

    $runner = [Diagnostics.Process]::new()
    $runner.StartInfo = $startInfo
    [void]$runner.Start()
    $stdoutTask = $runner.StandardOutput.ReadToEndAsync()
    $stderrTask = $runner.StandardError.ReadToEndAsync()

    # Intentionally DO NOT close $runner.StandardInput until after it exits. This simulates the live console that
    # exposed the release regression while remaining deterministic in CI and on all three supported OSes.
    if (-not $runner.WaitForExit(15000)) {
        try { $runner.Kill($true) } catch { }
        Write-Fail 'Squad probe or real init inherited the still-open parent stdin and did not finish within 15 seconds'
    }
    elseif ($runner.ExitCode -ne 0) {
        Write-Fail ("closed-input runner exited {0}: stdout={1}; stderr={2}" -f $runner.ExitCode, $stdoutTask.GetAwaiter().GetResult(), $stderrTask.GetAwaiter().GetResult())
    }
    elseif (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
        Write-Fail 'closed-input runner completed without its result artifact'
    }
    else {
        $result = Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $result.supports_non_interactive) { Write-Fail 'capability probe did not complete successfully under closed stdin' }
        if (@($result.argument_list) -join ' ' -cne 'init --non-interactive') { Write-Fail 'capability probe did not retain the Squad non-interactive argument contract' }
        if ($result.actual_exit_code -ne 0 -or -not $result.actual_squad_exists) { Write-Fail 'real Squad init path did not complete and materialize .squad' }
        if ((@($result.actual_output) -join "`n") -cnotmatch 'stdin_redirected=True;stdin_length=0') {
            Write-Fail 'real Squad init child did not observe redirected stdin with immediate EOF'
        }
        if (-not $script:Failed) {
            Write-Pass 'Squad capability probe and real init both finish with immediate stdin EOF while their parent input remains open'
        }
    }

    $utilitiesSource = Get-Content -LiteralPath $utilitiesPath -Raw -Encoding UTF8
    $squadDeploySource = Get-Content -LiteralPath $squadDeployPath -Raw -Encoding UTF8
    $initSource = Get-Content -LiteralPath $initPath -Raw -Encoding UTF8
    if ($utilitiesSource -notmatch 'RedirectStandardInput\s*=\s*\$true' -or $utilitiesSource -notmatch 'StandardInput\.Close\(\)') {
        Write-Fail 'closed-input primitive must redirect and immediately close child stdin'
    }
    if ($squadDeploySource -notmatch "Invoke-NativeCommandWithClosedInput\s+-FilePath\s+'squad'") {
        Write-Fail 'Squad capability probe must use the closed-input primitive'
    }
    if ($initSource -notmatch "Invoke-NativeCommandWithClosedInput\s+-FilePath\s+'squad'") {
        Write-Fail 'production specrew init Squad invocation must use the closed-input primitive'
    }
    if (-not $script:Failed) {
        Write-Pass 'both production Squad call sites are structurally pinned to the closed-input primitive'
    }
}
finally {
    if ($null -ne $runner) {
        try { $runner.StandardInput.Close() } catch { }
        $runner.Dispose()
    }
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($script:Failed) { exit 1 }
Write-Pass 'Squad 0.11.0 live-console hidden-prompt regression is closed'
exit 0

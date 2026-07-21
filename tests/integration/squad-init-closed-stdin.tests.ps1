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
$timeoutChildPidPath = Join-Path $scratchRoot 'timeout-child.pid'
$runner = $null

try {
    New-Item -ItemType Directory -Path $fakeBin -Force | Out-Null

    # This fake behaves like the Squad 0.11.0 prompt path: it waits for EOF before doing any work. The outer
    # test deliberately keeps the runner's stdin pipe OPEN. If either Squad call inherits that input, this
    # process cannot complete before the bounded timeout. A correct launcher gives each invocation immediate EOF.
    $fakeSquadPath = Join-Path $fakeBin $(if ($IsWindows) { 'squad.ps1' } else { 'squad' })
    $fakeSquadBody = @'
if ($env:SPECREW_TEST_SQUAD_HANG -ceq '1') {
    $child = Start-Process -FilePath ([Environment]::ProcessPath) `
        -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', 'Start-Sleep -Seconds 120') `
        -PassThru
    [IO.File]::WriteAllText($env:SPECREW_TEST_CHILD_PID_PATH, [string]$child.Id)
    while ($true) { Start-Sleep -Seconds 1 }
}

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
$actual = Invoke-NativeCommandWithClosedInput -FilePath 'squad' -ArgumentList $plan.ArgumentList -WorkingDirectory $projectRoot -TimeoutSeconds 5

$timeoutProbeReturned = $false
$timeoutExceptionType = $null
$timeoutExceptionMessage = $null
$env:SPECREW_TEST_SQUAD_HANG = '1'
$env:SPECREW_TEST_CHILD_PID_PATH = Join-Path $ScratchRoot 'timeout-child.pid'
try {
    $null = Test-SquadInitSupportsNonInteractive -ProbeRoot (Join-Path $ScratchRoot 'timeout-probe-root') -TimeoutSeconds 1
    $timeoutProbeReturned = $true
}
catch [System.TimeoutException] {
    $timeoutExceptionType = $_.Exception.GetType().FullName
    $timeoutExceptionMessage = $_.Exception.Message
}
finally {
    Remove-Item Env:SPECREW_TEST_SQUAD_HANG -ErrorAction SilentlyContinue
    Remove-Item Env:SPECREW_TEST_CHILD_PID_PATH -ErrorAction SilentlyContinue
}

$timeoutChildPid = 0
$timeoutChildAlive = $false
$timeoutChildPidPath = Join-Path $ScratchRoot 'timeout-child.pid'
if (Test-Path -LiteralPath $timeoutChildPidPath -PathType Leaf) {
    $timeoutChildPid = [int](Get-Content -LiteralPath $timeoutChildPidPath -Raw -Encoding UTF8)
    $timeoutChildAlive = $null -ne (Get-Process -Id $timeoutChildPid -ErrorAction SilentlyContinue)
}

[ordered]@{
    supports_non_interactive = [bool]$plan.SupportsNonInteractive
    argument_list = @($plan.ArgumentList)
    actual_exit_code = [int]$actual.ExitCode
    actual_output = @($actual.Output)
    actual_squad_exists = Test-Path -LiteralPath (Join-Path $projectRoot '.squad') -PathType Container
    timeout_probe_returned = $timeoutProbeReturned
    timeout_exception_type = $timeoutExceptionType
    timeout_exception_message = $timeoutExceptionMessage
    timeout_child_pid = $timeoutChildPid
    timeout_child_alive = $timeoutChildAlive
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
        if ($result.timeout_probe_returned -or $result.timeout_exception_type -cne 'System.TimeoutException') {
            Write-Fail 'a timed-out capability probe must throw a fatal TimeoutException instead of selecting fallback'
        }
        if ([string]$result.timeout_exception_message -cnotmatch '^native-command-timeout:file=squad:timeout_seconds=1:termination=verified:diagnostics=complete') {
            Write-Fail 'timeout failure did not carry the stable timeout, termination, and diagnostics contract'
        }
        if ([int]$result.timeout_child_pid -le 0 -or [bool]$result.timeout_child_alive) {
            Write-Fail 'timeout did not prove that the complete fake Squad descendant process tree was terminated'
        }
        if (-not $script:Failed) {
            Write-Pass 'Squad normal paths finish on EOF; timeout fails fatally and terminates the descendant process tree'
        }
    }

    $utilitiesSource = Get-Content -LiteralPath $utilitiesPath -Raw -Encoding UTF8
    $squadDeploySource = Get-Content -LiteralPath $squadDeployPath -Raw -Encoding UTF8
    $initSource = Get-Content -LiteralPath $initPath -Raw -Encoding UTF8
    if ($utilitiesSource -notmatch 'RedirectStandardInput\s*=\s*\$true' -or $utilitiesSource -notmatch 'StandardInput\.Close\(\)') {
        Write-Fail 'closed-input primitive must redirect and immediately close child stdin'
    }
    if ($utilitiesSource -notmatch 'WaitForExit\(\$TimeoutSeconds \* 1000\)' -or $utilitiesSource -notmatch 'Kill\(\$true\)') {
        Write-Fail 'closed-input primitive must bound completion and terminate the complete process tree'
    }
    if ($squadDeploySource -notmatch 'Invoke-NativeCommandWithClosedInput\s+-FilePath\s+''squad''.*-TimeoutSeconds\s+\$TimeoutSeconds' -or
        $squadDeploySource -notmatch 'catch\s+\[System\.TimeoutException\]\s*\{\s*[^}]*throw') {
        Write-Fail 'Squad capability probe must use its explicit bound and preserve timeout as a fatal failure'
    }
    if ($initSource -notmatch "Invoke-NativeCommandWithClosedInput\s+-FilePath\s+'squad'.*-TimeoutSeconds\s+120") {
        Write-Fail 'production specrew init Squad invocation must use the closed-input primitive with its explicit bound'
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
    if (Test-Path -LiteralPath $timeoutChildPidPath -PathType Leaf) {
        $timeoutChildPid = [int](Get-Content -LiteralPath $timeoutChildPidPath -Raw -Encoding UTF8)
        $timeoutChild = Get-Process -Id $timeoutChildPid -ErrorAction SilentlyContinue
        if ($null -ne $timeoutChild) {
            try { $timeoutChild.Kill($true) } catch { }
        }
    }
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($script:Failed) { exit 1 }
Write-Pass 'Squad 0.11.0 live-console hidden-prompt regression is closed'
exit 0

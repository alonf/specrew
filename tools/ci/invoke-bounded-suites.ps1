#requires -Version 7.0
# Feature 203 T015 (DRIFT-005; 206's DRIFT-206-I002-012). Runs each deterministic review suite in its OWN pwsh under
# a wall-clock limit. Before this, the Cross-Platform step ran every suite in one process with no per-suite limit:
# a Windows hang ran until the job's limit cancelled the whole job, the log was lost, and nothing named the suite.
# Here a suite that exceeds the limit is named, its process tree is stopped, and the run fails while the step can
# still write its log. A suite whose Pester result is not 'Passed' fails the run the same way as before, including
# the failed-container case (FailedCount 0 with a failed BeforeAll), because the gate reads the terminal Result.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Suite,
    [ValidateRange(1, 3600)][int]$SuiteTimeoutSeconds = 300,
    [string]$PesterVersion = '5.7.1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-BoundedSuiteChildScript {
    # The child imports the pinned Pester, runs one suite with detailed output, and writes its terminal result
    # where the parent can read it; the exit code alone cannot distinguish a failed container from a pass.
    param([Parameter(Mandatory)][string]$SuitePath, [Parameter(Mandatory)][string]$ResultPath)
    $suiteLiteral = $SuitePath -replace "'", "''"
    $resultLiteral = $ResultPath -replace "'", "''"
    return ("`$ErrorActionPreference = 'Stop'; Import-Module Pester -RequiredVersion {0} -Force; " +
        "`$r = Invoke-Pester -Path '{1}' -Output Detailed -PassThru; " +
        "Set-Content -LiteralPath '{2}' -Value ('{{0}}|{{1}}' -f `$r.Result, `$r.FailedCount) -Encoding UTF8; " +
        "if (`$r.Result -ne 'Passed') {{ exit 1 }}") -f $PesterVersion, $suiteLiteral, $resultLiteral
}

function Invoke-BoundedSuite {
    # Returns $null when the suite passed, otherwise the failure text that names it.
    param([Parameter(Mandatory)][string]$SuitePath, [Parameter(Mandatory)][int]$TimeoutSeconds)
    $resultPath = Join-Path ([System.IO.Path]::GetTempPath()) ('bounded-suite-' + [guid]::NewGuid().ToString('N') + '.txt')
    $psi = [System.Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
    $psi.UseShellExecute = $false
    foreach ($argument in @('-NoProfile', '-NonInteractive', '-Command', (Get-BoundedSuiteChildScript -SuitePath $SuitePath -ResultPath $resultPath))) {
        [void]$psi.ArgumentList.Add($argument)
    }
    $child = [System.Diagnostics.Process]::Start($psi)
    try {
        if (-not $child.WaitForExit($TimeoutSeconds * 1000)) {
            # Kill the whole tree: a hung suite's own children (reviewer stubs, supervisors) must not outlive it.
            try { $child.Kill($true) } catch { $null = $_ }
            $null = $child.WaitForExit(10000)
            return ('deterministic-suite-timeout:{0} (no result after {1} s; its process tree was stopped)' -f $SuitePath, $TimeoutSeconds)
        }
        $child.WaitForExit()
        $result = if (Test-Path -LiteralPath $resultPath -PathType Leaf) { (Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8).Trim() } else { 'none|?' }
        $parts = $result -split '\|', 2
        if ($child.ExitCode -eq 0 -and $parts[0] -eq 'Passed') { return $null }
        return ('review-fault-suite-failed:{0} (result={1} failed={2} exit={3})' -f $SuitePath, $parts[0], $parts[1], $child.ExitCode)
    }
    finally {
        $child.Dispose()
        Remove-Item -LiteralPath $resultPath -Force -ErrorAction SilentlyContinue
    }
}

foreach ($suitePath in $Suite) {
    Write-Host "--- deterministic suite: $suitePath" -ForegroundColor Cyan
    $failure = Invoke-BoundedSuite -SuitePath $suitePath -TimeoutSeconds $SuiteTimeoutSeconds
    if ($null -ne $failure) {
        Write-Host $failure
        if ($env:GITHUB_ACTIONS -eq 'true') { Write-Host "::error::$failure" }
        exit 1
    }
}
exit 0

#requires -Version 7.0
# Runs the named suites, each in its own process, in parallel; prints one summary block per suite.
# Pester suites are classified by Describe, not by file name.
# Each suite gets its own closed stdin (B5F-034: git under an inherited, already-read stdin pipe hangs at start-up) and a
# time limit, after which its whole process tree is killed and the suite is reported as timed out.
# Maintainer ruling 2026-11-11: each suite is timed on the wall clock and on a clock that stops while the machine sleeps.
# A suite whose wall time exceeds its awake time by more than -StandbyThresholdSeconds spanned standby: it is reported
# "spanned standby, rerun", never as a pass or a fail, and the sweep is not valid to close a task. The time limits are
# awake time (Windows waits do not count sleep), which is why the 2026-11-10 coverage run took 58 minutes of wall time.
param([string[]]$Suites, [string]$ListFile, [int]$Throttle = 6, [string]$Repo = 'C:\Dev\specrew-b4f-142', [int]$SuiteTimeoutSeconds = 900, [double]$StandbyThresholdSeconds = 20)
$supportPath = Join-Path $PSScriptRoot 'sweep-support.ps1'
if ($ListFile) { $Suites = @(Get-Content -LiteralPath $ListFile | Where-Object { $_.Trim() }) }
# Known-red suites (known-red.txt beside this script; maintainer, 2026-11-10): each runs with its own short limit, is
# reported as "known red, <finding>" by name, and does not count toward the failures. One that passes is reported too.
$knownRed = @{}
$knownRedPath = Join-Path $PSScriptRoot 'known-red.txt'
if (Test-Path -LiteralPath $knownRedPath) {
    foreach ($line in @(Get-Content -LiteralPath $knownRedPath | Where-Object { $_.Trim() -and -not $_.TrimStart().StartsWith('#') })) {
        $parts = @($line -split '\|' | ForEach-Object { $_.Trim() })
        if ($parts.Count -ge 3) { $knownRed[$parts[0]] = [pscustomobject]@{ Seconds = [int]$parts[1]; Finding = $parts[2] } }
    }
}
$results = $Suites | ForEach-Object -ThrottleLimit $Throttle -Parallel {
    . $using:supportPath
    function Invoke-Suite {
        param([string[]]$Arguments, [string]$WorkingDirectory, [int]$TimeoutSeconds)
        $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
        foreach ($a in $Arguments) { $psi.ArgumentList.Add($a) }
        $psi.WorkingDirectory = $WorkingDirectory
        $psi.UseShellExecute = $false
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $p = [Diagnostics.Process]::Start($psi)
        $p.StandardInput.Close()
        $outTask = $p.StandardOutput.ReadToEndAsync()
        $errTask = $p.StandardError.ReadToEndAsync()
        $finished = $p.WaitForExit($TimeoutSeconds * 1000)
        if (-not $finished) { try { $p.Kill($true) } catch { $null = $_ }; $null = $p.WaitForExit(30000) } else { $p.WaitForExit() }
        $null = [Threading.Tasks.Task]::WaitAll(@($outTask, $errTask), 30000)
        $text = $(if ($outTask.IsCompleted) { $outTask.Result } else { '' }) + "`n" + $(if ($errTask.IsCompleted) { $errTask.Result } else { '' })
        return [pscustomobject]@{ Finished = $finished; ExitCode = $(if ($finished) { $p.ExitCode } else { -1 }); Lines = @($text -split '\r?\n' | Where-Object { $_ -ne '' }) }
    }
    $path = Join-Path $using:Repo $_
    $known = ($using:knownRed)[$_]
    $limit = if ($null -ne $known) { [int]$known.Seconds } else { [int]$using:SuiteTimeoutSeconds }
    $started = Get-Date
    $awakeStart = Get-SweepAwakeSeconds
    $isPester = (Get-Content -LiteralPath $path -Raw) -match '(?m)^\s*Describe\s'
    if ($isPester) {
        $cmd = "`$c = New-PesterConfiguration; `$c.Run.Path = '$path'; `$c.Run.PassThru = `$true; `$c.Output.Verbosity = 'None'; `$r = Invoke-Pester -Configuration `$c; " +
            "'{0} passed, {1} failed, {2} skipped' -f `$r.PassedCount, `$r.FailedCount, `$r.SkippedCount; foreach (`$t in `$r.Failed) { '  FAILED: ' + `$t.ExpandedPath; `$m = ((`$t.ErrorRecord | Select-Object -First 1) -replace '\s+', ' '); '    ' + `$m.Substring(0, [Math]::Min(500, `$m.Length)) }"
        $run = Invoke-Suite -Arguments @('-NoProfile', '-Command', $cmd) -WorkingDirectory $using:Repo -TimeoutSeconds $limit
        $failed = (-not $run.Finished) -or (($run.Lines -join "`n") -notmatch '\b0 failed')
        $kind = if ($run.Finished) { 'Pester' } else { "Pester TIMED OUT after ${limit}s" }
        $wall = ((Get-Date) - $started).TotalSeconds; $awake = (Get-SweepAwakeSeconds) - $awakeStart
        [pscustomobject]@{ Suite = $_; Kind = $kind; Failed = $failed; Wall = [int]$wall; Awake = [int]$awake; Standby = (Get-SweepStandbyVerdict -WallSeconds $wall -AwakeSeconds $awake -ThresholdSeconds $using:StandbyThresholdSeconds); Lines = @($run.Lines | Select-Object -Last 40); Known = $known }
    }
    else {
        $run = Invoke-Suite -Arguments @('-NoProfile', '-File', $path) -WorkingDirectory $using:Repo -TimeoutSeconds $limit
        $code = $run.ExitCode
        $lines = if (-not $run.Finished) { @($run.Lines | Select-Object -Last 15) } elseif ($code -ne 0) { @($run.Lines | Where-Object { $_ -match 'FAIL|Exception|error|Error' } | Select-Object -First 25) } else { @() }
        $kind = if ($run.Finished) { "script exit $code" } else { "script TIMED OUT after ${limit}s" }
        $wall = ((Get-Date) - $started).TotalSeconds; $awake = (Get-SweepAwakeSeconds) - $awakeStart
        [pscustomobject]@{ Suite = $_; Kind = $kind; Failed = ((-not $run.Finished) -or $code -ne 0); Wall = [int]$wall; Awake = [int]$awake; Standby = (Get-SweepStandbyVerdict -WallSeconds $wall -AwakeSeconds $awake -ThresholdSeconds $using:StandbyThresholdSeconds); Lines = $lines; Known = $known }
    }
}
foreach ($r in $results | Sort-Object Suite) {
    # A suite that spanned standby is neither a pass nor a fail: its result says nothing about the code.
    $mark = if (-not [string]::IsNullOrEmpty([string]$r.Standby)) { ' ' + [string]$r.Standby }
    elseif ($null -ne $r.Known) { $(if ($r.Failed) { " known red, $($r.Known.Finding)" } else { " PASSED although listed known red ($($r.Known.Finding)): remove it from known-red.txt" }) }
    elseif ($r.Failed) { ' FAILED' } else { '' }
    '=== {0} ({1}, wall {2} s, awake {3} s){4}' -f $r.Suite, $r.Kind, $r.Wall, $r.Awake, $mark
    if ([string]::IsNullOrEmpty([string]$r.Standby) -and $null -eq $r.Known -and ($r.Failed -or $r.Kind -eq 'Pester')) { $r.Lines }
}
$counted = @($results | Where-Object { [string]::IsNullOrEmpty([string]$_.Standby) })
$standby = @($results | Where-Object { -not [string]::IsNullOrEmpty([string]$_.Standby) })
$knownResults = @($counted | Where-Object { $null -ne $_.Known })
'--- {0} suite(s), {1} failed, {2} known red, {3} spanned standby{4}' -f @($results).Count, @($counted | Where-Object { $_.Failed -and $null -eq $_.Known }).Count,
    @($knownResults | Where-Object Failed).Count, $standby.Count, $(if (@($knownResults | Where-Object Failed).Count -gt 0) { ' (' + (($knownResults | Where-Object Failed | ForEach-Object { '{0}: {1}' -f $_.Known.Finding, (Split-Path -Leaf $_.Suite) }) -join '; ') + ')' } else { '' })
if ($standby.Count -eq 0) { '--- valid to close a task: yes (no suite spanned standby)' }
else { '--- valid to close a task: no ({0} suite(s) spanned standby; rerun them: {1})' -f $standby.Count, (($standby | ForEach-Object { $_.Suite }) -join ', ') }

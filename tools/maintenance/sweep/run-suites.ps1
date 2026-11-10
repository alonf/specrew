#requires -Version 7.0
# Runs the named suites, each in its own process, in parallel; prints one summary block per suite.
# Pester suites are classified by Describe, not by file name.
# Each suite gets its own closed stdin (B5F-034: git under an inherited, already-read stdin pipe hangs at start-up) and a
# time limit, after which its whole process tree is killed and the suite is reported as timed out.
param([string[]]$Suites, [string]$ListFile, [int]$Throttle = 6, [string]$Repo = 'C:\Dev\specrew-b4f-142', [int]$SuiteTimeoutSeconds = 900)
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
    $isPester = (Get-Content -LiteralPath $path -Raw) -match '(?m)^\s*Describe\s'
    if ($isPester) {
        $cmd = "`$c = New-PesterConfiguration; `$c.Run.Path = '$path'; `$c.Run.PassThru = `$true; `$c.Output.Verbosity = 'None'; `$r = Invoke-Pester -Configuration `$c; " +
            "'{0} passed, {1} failed, {2} skipped' -f `$r.PassedCount, `$r.FailedCount, `$r.SkippedCount; foreach (`$t in `$r.Failed) { '  FAILED: ' + `$t.ExpandedPath; `$m = ((`$t.ErrorRecord | Select-Object -First 1) -replace '\s+', ' '); '    ' + `$m.Substring(0, [Math]::Min(500, `$m.Length)) }"
        $run = Invoke-Suite -Arguments @('-NoProfile', '-Command', $cmd) -WorkingDirectory $using:Repo -TimeoutSeconds $limit
        $failed = (-not $run.Finished) -or (($run.Lines -join "`n") -notmatch '\b0 failed')
        $kind = if ($run.Finished) { 'Pester' } else { "Pester TIMED OUT after ${limit}s" }
        [pscustomobject]@{ Suite = $_; Kind = $kind; Failed = $failed; Seconds = [int]((Get-Date) - $started).TotalSeconds; Lines = @($run.Lines | Select-Object -Last 40); Known = $known }
    }
    else {
        $run = Invoke-Suite -Arguments @('-NoProfile', '-File', $path) -WorkingDirectory $using:Repo -TimeoutSeconds $limit
        $code = $run.ExitCode
        $lines = if (-not $run.Finished) { @($run.Lines | Select-Object -Last 15) } elseif ($code -ne 0) { @($run.Lines | Where-Object { $_ -match 'FAIL|Exception|error|Error' } | Select-Object -First 25) } else { @() }
        $kind = if ($run.Finished) { "script exit $code" } else { "script TIMED OUT after ${limit}s" }
        [pscustomobject]@{ Suite = $_; Kind = $kind; Failed = ((-not $run.Finished) -or $code -ne 0); Seconds = [int]((Get-Date) - $started).TotalSeconds; Lines = $lines; Known = $known }
    }
}
foreach ($r in $results | Sort-Object Suite) {
    $mark = if ($null -ne $r.Known) { $(if ($r.Failed) { " known red, $($r.Known.Finding)" } else { " PASSED although listed known red ($($r.Known.Finding)): remove it from known-red.txt" }) }
    elseif ($r.Failed) { ' FAILED' } else { '' }
    '=== {0} ({1}, {2}s){3}' -f $r.Suite, $r.Kind, $r.Seconds, $mark
    if ($null -eq $r.Known -and ($r.Failed -or $r.Kind -eq 'Pester')) { $r.Lines }
}
$knownResults = @($results | Where-Object { $null -ne $_.Known })
'--- {0} suite(s), {1} failed, {2} known red{3}' -f @($results).Count, @($results | Where-Object { $_.Failed -and $null -eq $_.Known }).Count,
    @($knownResults | Where-Object Failed).Count, $(if ($knownResults.Count -gt 0) { ' (' + (($knownResults | Where-Object Failed | ForEach-Object { '{0}: {1}' -f $_.Known.Finding, (Split-Path -Leaf $_.Suite) }) -join '; ') + ')' } else { '' })

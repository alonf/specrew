param([string]$Dir, [string[]]$LaneIds)
$plan = Get-Content -LiteralPath (Join-Path $Dir '.specrew/verification-plan.json') -Raw | ConvertFrom-Json
foreach ($id in $LaneIds) {
    $lane = $plan.commands | Where-Object command_id -eq $id
    if (-not $lane) { "$id MISSING from the verification plan"; continue }
    $psi = [Diagnostics.ProcessStartInfo]::new($lane.executable)
    foreach ($a in $lane.arguments) { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $Dir
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    # The lane gets its own stdin, closed at once. Inherited from a Start-Job host, stdin is the job's remoting pipe with
    # a read always pending, and Git for Windows' start-up query of its stdin's name (NtQueryObject) waits on that read
    # forever: the lanes-94205372 hang (git init, 3 h, 4 s CPU). Reproduced by repro-git-stdin.ps1.
    $psi.RedirectStandardInput = $true
    $psi.Environment.Clear()
    foreach ($k in $lane.env_refs) { $v = [Environment]::GetEnvironmentVariable($k); if ($null -ne $v) { $psi.Environment[$k] = $v } }
    # B5F-032: the lane's environment is cleared to its env_refs, so the sweep's redirected home is passed explicitly.
    if ($env:SPECREW_USER_HOME_OVERRIDE) { $psi.Environment['SPECREW_USER_HOME_OVERRIDE'] = $env:SPECREW_USER_HOME_OVERRIDE }
    $limit = [int]$lane.timeout_seconds
    if ($limit -le 0) { throw "lane $id has no timeout_seconds" }
    $t = [Diagnostics.Stopwatch]::StartNew()
    $p = [Diagnostics.Process]::Start($psi)
    $p.StandardInput.Close()
    $outTask = $p.StandardOutput.ReadToEndAsync()
    $errTask = $p.StandardError.ReadToEndAsync()
    $finished = $p.WaitForExit($limit * 1000)
    if (-not $finished) {
        # The lane's own limit, enforced: the whole tree goes, so no git or pwsh is left holding the checkout.
        $p.Kill($true)
        $null = $p.WaitForExit(30000)
    }
    else { $p.WaitForExit() }   # flushes the async readers
    $null = [Threading.Tasks.Task]::WaitAll(@($outTask, $errTask), 30000)
    $text = $(if ($outTask.IsCompleted) { $outTask.Result } else { '' }) + $(if ($errTask.IsCompleted) { $errTask.Result } else { '' })
    $verdict = if ($finished) { "exit=$($p.ExitCode)" } else { "TIMED OUT, process tree killed" }
    "$id $verdict t=$([int]$t.Elapsed.TotalSeconds)s (timeout ${limit}s, env vars $(@($lane.env_refs).Count))"
    if (-not $finished -or $p.ExitCode -ne 0) { $text -split "`n" | Select-Object -Last 15 | ForEach-Object { '  ' + $_ } }
}

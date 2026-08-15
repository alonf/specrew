#requires -Version 7.0

<#
Disk-wide test census. The F-198 registry is intentionally curated; this runner answers the
different question “which PowerShell test files are on disk, and do they execute?” without
turning probes, fixtures, or other support scripts into tests merely because they live below
tests/. A test file is any *.ps1 whose filename ends in test.ps1 or tests.ps1 (case-insensitive).

Each file runs in a fresh pwsh process with bounded parallelism and a per-file timeout. Pester
containers are detected from executable Describe syntax and use Run.Exit so discovery/container
failures cannot hide behind FailedCount=0. Direct assertion scripts run with -File semantics.
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 16)][int]$MaxParallel = 4,
    [ValidateRange(1, 3600)][int]$PerFileTimeoutSeconds = 300,
    [string[]]$ExcludeRelativePath = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$baseline = @(& git -C $repoRoot status --porcelain=v1 --untracked-files=all)

$files = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'tests') -Recurse -File -Filter '*.ps1' |
        Where-Object { $_.Name -match '(?i)tests?\.ps1$' } |
        Where-Object { $_.FullName.Substring($repoRoot.Length + 1) -notin @($ExcludeRelativePath) } |
        Sort-Object FullName)

# A file-level bound prevents wedges, but the default must not misclassify known, intentionally broad integration
# matrices. The changed-only suite creates fourteen isolated repositories and runs the full validator in each one;
# measured on this branch it needs about fourteen minutes alone and crossed fifteen minutes under normal four-way
# overlap. The cross-host conformance matrix normally takes about four minutes by itself but can exceed the generic
# five-minute bound while three other processes are active. Keep exceptional ceilings explicit and reviewable
# instead of weakening the default for every other file.
$fileTimeoutOverrides = @{
    'tests\integration\validate-governance-changed-only.tests.ps1' = 1200
    'tests\integration\conformance-detection.tests.ps1' = 600
    'tests\continuous-co-review\unit\review-public-campaign-command.Tests.ps1' = 600
}

# These suites launch enough nested repositories/processes that overlapping them with three other
# files changes the thing being measured: Spec Kit init can fail transiently, process-containment
# tests can race machine-wide resources, and the changed-only matrix can cross its otherwise ample
# 20-minute ceiling. Keep the default parallel lane for the rest of the census, but drain it before
# each measured process-heavy suite and run that suite alone.
$serialRelativePaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($relativePath in @(
        'tests\integration\validate-governance-changed-only.tests.ps1',
        'tests\unit\boundary-authorization-prompt-truth.tests.ps1',
        'tests\continuous-co-review\unit\isolated-task-launcher.Tests.ps1')) {
    [void]$serialRelativePaths.Add($relativePath)
}

function Start-SweepFile {
    param([Parameter(Mandatory)]$File, [int]$Index)
    $source = Get-Content -LiteralPath $File.FullName -Raw -Encoding UTF8
    $kind = if ($source -match '(?m)^\s*Describe\s+[''"]') { 'pester' } else { 'script' }
    $quoted = $File.FullName.Replace("'", "''")
    $command = if ($kind -ceq 'pester') {
        "Import-Module Pester -MinimumVersion 5.0 -Force; `$c=New-PesterConfiguration; `$c.Run.Path='$quoted'; `$c.Run.Exit=`$true; `$c.Output.Verbosity='None'; Invoke-Pester -Configuration `$c"
    }
    else {
        # Direct assertion scripts often invoke a child that is EXPECTED to fail and then prove its
        # output. LASTEXITCODE therefore describes the last child, not the suite. If the script
        # returns normally it passed; throw/exit 1 still terminates this isolated process non-zero.
        "try { & '$quoted'; exit 0 } catch { Write-Error `$_; exit 1 }"
    }
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $token = '{0:D4}-{1}' -f $Index, ([guid]::NewGuid().ToString('N'))
    $stdout = Join-Path ([IO.Path]::GetTempPath()) "specrew-full-sweep-$token.out"
    $stderr = Join-Path ([IO.Path]::GetTempPath()) "specrew-full-sweep-$token.err"
    $start = Get-Date
    $relativePath = $File.FullName.Substring($repoRoot.Length + 1)
    $isSerial = $serialRelativePaths.Contains($relativePath)
    $timeoutSeconds = if ($fileTimeoutOverrides.ContainsKey($relativePath)) {
        [int]$fileTimeoutOverrides[$relativePath]
    }
    else { $PerFileTimeoutSeconds }
    $process = Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-EncodedCommand', $encoded) `
        -WorkingDirectory $repoRoot -PassThru -NoNewWindow -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    return [pscustomobject]@{
        index = $Index; file = $File; kind = $kind; process = $process; started = $start
        stdout = $stdout; stderr = $stderr; timeout_seconds = $timeoutSeconds; serial = $isSerial
    }
}

function Complete-SweepFile {
    param([Parameter(Mandatory)]$Running, [switch]$TimedOut)
    if ($TimedOut) {
        try { $Running.process.Kill($true) } catch { $null = $_ }
        try { $null = $Running.process.WaitForExit(5000) } catch { $null = $_ }
    }
    else { $Running.process.WaitForExit() }
    $output = ((Get-Content -LiteralPath $Running.stdout -Raw -ErrorAction SilentlyContinue) + "`n" +
        (Get-Content -LiteralPath $Running.stderr -Raw -ErrorAction SilentlyContinue))
    Remove-Item -LiteralPath $Running.stdout,$Running.stderr -Force -ErrorAction SilentlyContinue
    return [pscustomobject]@{
        index = $Running.index; path = $Running.file.FullName.Substring($repoRoot.Length + 1)
        kind = $Running.kind; status = if ($TimedOut) { 'timeout' } elseif ($Running.process.ExitCode -eq 0) { 'passed' } else { 'failed' }
        exit_code = if ($TimedOut) { $null } else { $Running.process.ExitCode }
        duration_seconds = ((Get-Date) - $Running.started).TotalSeconds
        output = $output
    }
}

$active = [Collections.Generic.List[object]]::new()
$results = [Collections.Generic.List[object]]::new()
$next = 0
while ($next -lt $files.Count -or $active.Count -gt 0) {
    while ($next -lt $files.Count -and $active.Count -lt $MaxParallel) {
        $nextRelativePath = $files[$next].FullName.Substring($repoRoot.Length + 1)
        $nextIsSerial = $serialRelativePaths.Contains($nextRelativePath)
        $serialIsRunning = @($active | Where-Object { $_.serial }).Count -gt 0
        if ($serialIsRunning -or ($nextIsSerial -and $active.Count -gt 0)) { break }
        $active.Add((Start-SweepFile -File $files[$next] -Index $next)) | Out-Null
        $next++
        if ($nextIsSerial) { break }
    }
    $progress = $false
    foreach ($running in @($active.ToArray())) {
        $timedOut = ((Get-Date) - $running.started).TotalSeconds -ge $running.timeout_seconds
        if ($running.process.HasExited -or $timedOut) {
            $result = Complete-SweepFile -Running $running -TimedOut:$timedOut
            $results.Add($result) | Out-Null
            $active.Remove($running) | Out-Null
            $progress = $true
            if ($result.status -cne 'passed') {
                Write-Host ("{0}: {1} ({2}, {3:N2}s)" -f $result.status.ToUpperInvariant(), $result.path, $result.kind, $result.duration_seconds) -ForegroundColor Red
            }
            elseif ($results.Count % 25 -eq 0) {
                Write-Host ("Progress: {0}/{1} named test files completed" -f $results.Count, $files.Count) -ForegroundColor DarkGray
            }
        }
    }
    if (-not $progress -and $active.Count -gt 0) { Start-Sleep -Milliseconds 100 }
}

$after = @(& git -C $repoRoot status --porcelain=v1 --untracked-files=all)
$contaminated = ($baseline -join "`n") -cne ($after -join "`n")
$failed = @($results | Where-Object status -cne 'passed')
$pesterCount = @($results | Where-Object kind -ceq 'pester').Count
$scriptCount = @($results | Where-Object kind -ceq 'script').Count
Write-Host ''
Write-Host ("Full PowerShell test sweep: files={0}, pester={1}, scripts={2}, failed={3}, caller_contaminated={4}" -f
        $files.Count, $pesterCount, $scriptCount, $failed.Count, $contaminated)
if ($contaminated) {
    Write-Host 'FAIL: the caller working-tree status changed during the sweep.' -ForegroundColor Red
    exit 1
}
if ($failed.Count -gt 0) {
    $reportPath = Join-Path ([IO.Path]::GetTempPath()) ("specrew-full-sweep-failures-{0}.json" -f ([guid]::NewGuid().ToString('N')))
    [IO.File]::WriteAllText($reportPath, ($failed | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
    Write-Host 'Failed paths:' -ForegroundColor Red
    @($failed | Sort-Object path) | ForEach-Object { Write-Host ("  - {0}" -f $_.path) -ForegroundColor Red }
    Write-Host ("Full diagnostics: {0}" -f $reportPath) -ForegroundColor Red
    exit 1
}
Write-Host 'Full PowerShell test sweep: all named test files green.' -ForegroundColor Green

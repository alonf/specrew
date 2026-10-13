# Feature 202 T005 case (e) (FR-001, FR-025; SC-002): two real pwsh processes append to the hook-output journal
# at once; both succeed, every line is intact, and nothing degrades.
#
# Cases (a) to (d) - a lock released inside the retry window, a lock held past it, recovery, and the reader's view
# of buffered output - are hook-output-journal.tests.ps1 (T003). This file is the concurrency half, and it is the
# one the 3-OS matrix runs: research.md (T003) measured that a .NET Append stream loses and tears lines under
# concurrent writers on Windows, so the journal opens an AppendData-only handle there and a plain Append stream
# elsewhere. Whether Linux and macOS need the permitted per-write lock is decided by this file going green or red
# on those legs.
#
# Part 1 drives the SHIPPED writer: the journal functions are lifted from the dispatcher source by the parser
# (not copied), and each process calls Write-DispatcherHookOutputAuthorityRecord in a tight loop after both are
# released by one barrier. Part 2 runs pairs of real dispatcher processes on Stop at the same moment.
#
# Mutations that turn this file red: open the journal with [IO.File]::Open(Append, ...) on Windows (lost or torn
# lines, measured); FileShare.Read on the writer (the second writer degrades: buffer files and a degraded
# transition appear); write `.unhealthy` on a failed append.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$dispatcherSource = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }
function Get-TextHash { param([string]$Text) return ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text.Trim())))).ToLowerInvariant() }

$writerCount = 2
$appendsPerWriter = 1000
$platform = if ($IsWindows) { 'windows' } elseif ($IsMacOS) { 'macos' } else { 'linux' }

function Get-RuntimeFile { param([string]$Root, [string]$Leaf) return [IO.Path]::Combine($Root, '.specrew', 'runtime', $Leaf) }

function Get-JournalReport {
    param([string]$Root)
    $journal = Get-RuntimeFile $Root 'hook-output-authority.jsonl'
    $lines = if (Test-Path -LiteralPath $journal) { @([IO.File]::ReadAllText($journal) -split "`n" | Where-Object { $_.Trim() }) } else { @() }
    $hashes = [Collections.Generic.HashSet[string]]::new()
    $torn = 0
    foreach ($line in $lines) {
        try {
            $record = $line | ConvertFrom-Json -ErrorAction Stop
            if ([string]$record.output_hash -match '^[0-9a-f]{64}$') { [void]$hashes.Add([string]$record.output_hash) } else { $torn++ }
        }
        catch { $torn++ }
    }
    $bufferDir = Get-RuntimeFile $Root 'hook-output-buffer'
    $health = Get-RuntimeFile $Root 'hook-output-health.jsonl'
    return [pscustomobject]@{
        Lines       = $lines.Count
        Torn        = $torn
        Hashes      = $hashes
        BufferFiles = @(if (Test-Path -LiteralPath $bufferDir -PathType Container) { Get-ChildItem -LiteralPath $bufferDir -File }).Count
        Degraded    = (Test-Path -LiteralPath $health) -and ([IO.File]::ReadAllText($health) -match '"state"\s*:\s*"degraded"')
        Marker      = Test-Path -LiteralPath ($journal + '.unhealthy')
    }
}

function Wait-Processes {
    param([Diagnostics.Process[]]$Processes, [int]$TimeoutMs)
    foreach ($p in $Processes) { if (-not $p.WaitForExit($TimeoutMs)) { $p.Kill($true); throw 'a writer process timed out' } }
}

# --- Part 1: the shipped writer, two processes, one barrier ---------------------------------------------------------
$names = 'Write-DispatcherWarn', 'Get-DispatcherHookOutputHash', 'Get-DispatcherHookOutputPaths', 'Open-DispatcherAppendStream',
'Add-DispatcherJournalText', 'Read-DispatcherSharedLines', 'Get-DispatcherLastHealthRecord', 'Write-DispatcherHookOutputHealth',
'Write-DispatcherHookOutputAuthorityRecord', 'Complete-DispatcherHookOutputRecovery'
$ast = [Management.Automation.Language.Parser]::ParseFile($dispatcherSource, [ref]$null, [ref]$null)
$functions = @($ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $names -contains $n.Name }, $false))
Assert-True ($functions.Count -eq $names.Count) ("the shipped journal functions are lifted from the dispatcher ({0} of {1})" -f $functions.Count, $names.Count)

$root = [IO.Path]::GetFullPath([IO.Path]::Combine([IO.Path]::GetTempPath(), 'jfi-' + [guid]::NewGuid().ToString('N').Substring(0, 8)))
try {
    [IO.Directory]::CreateDirectory((Get-RuntimeFile $root '')) | Out-Null
    $go = Join-Path $root 'go'
    $writerScript = Join-Path $root 'writer.ps1'
    # The lifted functions come first; the loop reads its inputs from $args, so the script needs no param block.
    $body = (@($functions | ForEach-Object { $_.Extent.Text }) -join "`n`n") + @'

$HostKind = 'fault-injection-e'
$writer = $args[0]; $count = [int]$args[1]; $projectRoot = $args[2]; $go = $args[3]; $resultPath = $args[4]
while (-not (Test-Path -LiteralPath $go)) { Start-Sleep -Milliseconds 1 }
$ok = 0
for ($i = 0; $i -lt $count; $i++) {
    if (Write-DispatcherHookOutputAuthorityRecord -ProjectRoot $projectRoot -Text ("case-e {0} {1}" -f $writer, $i) -EventName 'Stop' -OutputKind 'stop-block-reason') { $ok++ }
}
[IO.File]::WriteAllText($resultPath, [string]$ok)
'@
    [IO.File]::WriteAllText($writerScript, $body, [Text.UTF8Encoding]::new($false))

    $procs = foreach ($w in 1..$writerCount) {
        $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
        foreach ($a in '-NoProfile', '-NonInteractive', '-File', $writerScript, "w$w", [string]$appendsPerWriter, $root, $go, (Join-Path $root "result-w$w")) { $psi.ArgumentList.Add($a) }
        $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
        $p = [Diagnostics.Process]::Start($psi)
        $null = $p.StandardOutput.ReadToEndAsync(); $null = $p.StandardError.ReadToEndAsync()
        $p
    }
    Start-Sleep -Milliseconds 1500   # both processes are up and polling the barrier
    [IO.File]::WriteAllText($go, '1')
    Wait-Processes -Processes @($procs) -TimeoutMs 180000

    $expected = $writerCount * $appendsPerWriter
    $report = Get-JournalReport $root
    $missing = 0
    foreach ($w in 1..$writerCount) { foreach ($i in 0..($appendsPerWriter - 1)) { if (-not $report.Hashes.Contains((Get-TextHash ("case-e w{0} {1}" -f $w, $i)))) { $missing++ } } }
    foreach ($w in 1..$writerCount) {
        $result = Join-Path $root "result-w$w"
        $ok = if (Test-Path -LiteralPath $result) { [int][IO.File]::ReadAllText($result) } else { -1 }
        Assert-True ($ok -eq $appendsPerWriter) ("[$platform] (e) writer w$w recorded every append ({0}/{1})" -f $ok, $appendsPerWriter)
    }
    Assert-True ($report.Lines -eq $expected) ("[$platform] (e) the journal holds exactly one line per append ({0}/{1})" -f $report.Lines, $expected)
    Assert-True ($report.Torn -eq 0) ("[$platform] (e) no torn or interleaved line ({0} unparseable)" -f $report.Torn)
    Assert-True ($missing -eq 0) ("[$platform] (e) every appended hash is in the journal ({0} missing)" -f $missing)
    Assert-True ($report.BufferFiles -eq 0) "[$platform] (e) nothing degraded to the outage buffer"
    Assert-True (-not $report.Degraded) "[$platform] (e) no degraded health transition"
    Assert-True (-not $report.Marker) "[$platform] (e) no .unhealthy marker"
}
finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }

# --- Part 2: real dispatcher processes on Stop, two at a time -------------------------------------------------------
$root = [IO.Path]::GetFullPath([IO.Path]::Combine([IO.Path]::GetTempPath(), 'jfi-d-' + [guid]::NewGuid().ToString('N').Substring(0, 8)))
try {
    $scripts = [IO.Path]::Combine($root, '.specify', 'extensions', 'specrew-speckit', 'scripts')
    [IO.Directory]::CreateDirectory($scripts) | Out-Null
    [IO.Directory]::CreateDirectory((Get-RuntimeFile $root '')) | Out-Null
    Copy-Item -LiteralPath $dispatcherSource -Destination (Join-Path $scripts 'specrew-hook-dispatcher.ps1')
    [IO.File]::WriteAllText((Join-Path $scripts 'stub-block.ps1'), 'Write-Output ("<<<SPECREW-STOP-BLOCK>>>`n" + $env:JFI_REASON); exit 0', [Text.UTF8Encoding]::new($false))
    $catalog = [ordered]@{ schema_version = '1'; providers = @([ordered]@{ id = 'stub-block'; kind = 'inject'; events = @('Stop'); order = 40; budget_share = 1.0; command = 'stub-block.ps1' }) }
    [IO.File]::WriteAllText([IO.Path]::Combine($root, '.specify', 'extensions', 'specrew-speckit', 'refocus-scopes.json'), ($catalog | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))

    $pairs = 5
    $reasons = [Collections.Generic.List[string]]::new()
    foreach ($pair in 1..$pairs) {
        $procs = foreach ($side in 'left', 'right') {
            $reason = 'RENDER THE PACKET NOW (e) {0} {1} {2}' -f $pair, $side, [guid]::NewGuid().ToString('N')
            $reasons.Add($reason)
            $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
            foreach ($a in '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $scripts 'specrew-hook-dispatcher.ps1'), '-Event', 'Stop', '-HostKind', 'claude') { $psi.ArgumentList.Add($a) }
            $psi.WorkingDirectory = $root
            $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
            $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
            $psi.Environment['SPECREW_MODULE_PATH'] = $repoRoot
            $psi.Environment['JFI_REASON'] = $reason
            foreach ($var in 'CLAUDE_PROJECT_DIR', 'COPILOT_PROJECT_DIR', 'CURSOR_PROJECT_DIR') { $psi.Environment[$var] = $root }
            $p = [Diagnostics.Process]::Start($psi)
            $null = $p.StandardOutput.ReadToEndAsync(); $null = $p.StandardError.ReadToEndAsync()
            $p.StandardInput.Write(('{{"session_id":"jfi-{0}-{1}","stop_hook_active":false,"hook_event_name":"Stop"}}' -f $pair, $side)); $p.StandardInput.Close()
            $p
        }
        Wait-Processes -Processes @($procs) -TimeoutMs 90000
        foreach ($p in $procs) { Assert-True ($p.ExitCode -eq 0) "[$platform] (e) dispatcher pair $pair exits 0" }
    }
    $report = Get-JournalReport $root
    $missing = @($reasons | Where-Object { -not $report.Hashes.Contains((Get-TextHash $_)) }).Count
    Assert-True ($missing -eq 0) ("[$platform] (e) every concurrent dispatcher journaled its stop reason ({0} missing of {1})" -f $missing, $reasons.Count)
    Assert-True ($report.Torn -eq 0) "[$platform] (e) the dispatcher journal has no torn line"
    Assert-True ($report.BufferFiles -eq 0 -and -not $report.Degraded -and -not $report.Marker) "[$platform] (e) concurrent dispatchers never degrade"
}
finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }

if ($script:failCount -gt 0) { Write-Host "journal-fault-injection: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host "journal-fault-injection: all passed ($platform)" -ForegroundColor Green

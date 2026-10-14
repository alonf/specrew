# Feature 202 T003 (FR-001..FR-005, FR-008, FR-025 cases a-d; SC-002): a latch-free hook-output journal.
#
# The journal lets the workshop authority reader refuse a "reply" that is really hook output the host replayed.
# B4F-108: the dispatcher opened it with FileShare.Read, so a second hook process appending at the same moment got a
# sharing violation, and the catch wrote `.unhealthy` - a permanent marker that made the reader refuse EVERY later
# reply. Codex's product-domain checkpoint deadlocked on it.
#
# Every case runs the real dispatcher in its own process, on a real Stop with a stub provider requesting a stop
# block, while a separate process holds the journal lock. The authority reader is the shipped store function.
#
# RED before T003: case (a) latches `.unhealthy` instead of retrying; case (b) refuses an unrelated typed reply;
# case (c) never recovers; the legacy marker refuses every reply; no buffer or health journal exists.
#
# Mutations that turn this file red: write `.unhealthy` again in the dispatcher's catch; drop the retry loop (a);
# skip reading the buffer in the store (b, d); skip the flush (c); emit output that was neither journaled nor
# buffered (buffer-failure case).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$dispatcherSource = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-hook-dispatcher.ps1'
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\workshop-authority-store.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function Get-TextHash { param([string]$Text) return ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text.Trim())))).ToLowerInvariant() }

function New-JournalProject {
    $root = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ('hoj-' + [guid]::NewGuid().ToString('N').Substring(0, 8))))
    $scripts = Join-Path $root '.specify\extensions\specrew-speckit\scripts'
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew\runtime'), $scripts | Out-Null
    Copy-Item -LiteralPath $dispatcherSource -Destination (Join-Path $scripts 'specrew-hook-dispatcher.ps1')
    # The stub requests a stop block. With HOJ_HOLD_MS set it first starts a separate process that takes the
    # journal with FileShare.None and holds it that long, and returns only once the lock is held - so the
    # dispatcher's journal write, a few milliseconds after this provider exits, is guaranteed to meet it.
    $stub = @'
if ($env:HOJ_HOLD_MS) {
    $journal = Join-Path (Get-Location).Path '.specrew/runtime/hook-output-authority.jsonl'
    $ready = Join-Path (Get-Location).Path ('lock-ready-' + [guid]::NewGuid().ToString('N'))
    $holder = '$f = [IO.File]::Open(''{0}'', ''OpenOrCreate'', ''ReadWrite'', ''None''); [IO.File]::WriteAllText(''{1}'', ''1''); Start-Sleep -Milliseconds {2}; $f.Dispose()' -f $journal, $ready, $env:HOJ_HOLD_MS
    Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-Command', $holder) -WindowStyle Hidden | Out-Null
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while (-not (Test-Path -LiteralPath $ready) -and $sw.ElapsedMilliseconds -lt 15000) { Start-Sleep -Milliseconds 5 }
}
Write-Output ("<<<SPECREW-STOP-BLOCK>>>`n" + $env:HOJ_REASON)
exit 0
'@
    [IO.File]::WriteAllText((Join-Path $scripts 'stub-block.ps1'), $stub, [Text.UTF8Encoding]::new($false))
    $catalog = [ordered]@{ schema_version = '1'; providers = @([ordered]@{ id = 'stub-block'; kind = 'inject'; events = @('Stop'); order = 40; budget_share = 1.0; command = 'stub-block.ps1' }) }
    [IO.File]::WriteAllText((Join-Path $root '.specify\extensions\specrew-speckit\refocus-scopes.json'), ($catalog | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
    return $root
}

function Get-RuntimePath { param([string]$Root, [string]$Leaf) return (Join-Path $Root ".specrew\runtime\$Leaf") }

function Invoke-StopWithReason {
    param([string]$Root, [string]$Reason, [int]$HoldMs = 0)
    $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
    foreach ($a in '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Root '.specify\extensions\specrew-speckit\scripts\specrew-hook-dispatcher.ps1'), '-Event', 'Stop', '-HostKind', 'claude') { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $Root
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.Environment['SPECREW_MODULE_PATH'] = $repoRoot
    $psi.Environment['HOJ_REASON'] = $Reason
    if ($HoldMs -gt 0) { $psi.Environment['HOJ_HOLD_MS'] = [string]$HoldMs } else { $psi.Environment.Remove('HOJ_HOLD_MS') | Out-Null }
    foreach ($var in 'CLAUDE_PROJECT_DIR', 'COPILOT_PROJECT_DIR', 'CURSOR_PROJECT_DIR') { $psi.Environment[$var] = $Root }
    $p = [Diagnostics.Process]::Start($psi)
    $o = $p.StandardOutput.ReadToEndAsync(); $e = $p.StandardError.ReadToEndAsync()
    $p.StandardInput.Write('{"session_id":"hoj-session","stop_hook_active":false,"hook_event_name":"Stop"}'); $p.StandardInput.Close()
    if (-not $p.WaitForExit(60000)) { $p.Kill($true); throw 'dispatcher timed out' }
    return [pscustomobject]@{ ExitCode = $p.ExitCode; StdOut = $o.Result; StdErr = $e.Result }
}

function Wait-JournalUnlocked {
    # The holder the stub started may outlive the dispatcher; wait until the journal opens exclusively again.
    param([string]$Root)
    $journal = Get-RuntimePath $Root 'hook-output-authority.jsonl'
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt 20000) {
        try { $f = [IO.File]::Open($journal, 'OpenOrCreate', 'ReadWrite', 'None'); $f.Dispose(); return }
        catch { Start-Sleep -Milliseconds 50 }
    }
    throw 'journal stayed locked'
}
function Get-LastHealthState { param([string]$Root) $s = @(Get-HealthStates $Root); if ($s.Count -eq 0) { return $null } return $s[$s.Count - 1] }

function Get-JournalHashes {
    param([string]$Root)
    $path = Get-RuntimePath $Root 'hook-output-authority.jsonl'
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    return @([IO.File]::ReadAllLines($path) | Where-Object { $_.Trim() } | ForEach-Object { ($_ | ConvertFrom-Json).output_hash })
}
function Get-BufferFiles { param([string]$Root) $d = Get-RuntimePath $Root 'hook-output-buffer'; if (Test-Path -LiteralPath $d -PathType Container) { return @(Get-ChildItem -LiteralPath $d -File) } return @() }
function Get-HealthStates {
    param([string]$Root)
    $path = Get-RuntimePath $Root 'hook-output-health.jsonl'
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    return @([IO.File]::ReadAllLines($path) | Where-Object { $_.Trim() } | ForEach-Object { ($_ | ConvertFrom-Json).state })
}
function Get-AllStoreText {
    param([string]$Root)
    $texts = foreach ($f in @(Get-ChildItem -LiteralPath (Get-RuntimePath $Root '') -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'hook-output*' -or $_.DirectoryName -like '*hook-output-buffer*' })) { [IO.File]::ReadAllText($f.FullName) }
    return ($texts -join "`n")
}

$root = New-JournalProject
try {
    $typedReply = 'Yes, MVP is the single-user CLI; Hebrew too: שלום'

    Write-Host '--- case (a): a lock released inside the retry window is absorbed by the retry ---'
    $reasonA = 'RENDER THE PACKET NOW (a) ' + [guid]::NewGuid().ToString('N')
    $r = Invoke-StopWithReason -Root $root -Reason $reasonA -HoldMs 120
    Wait-JournalUnlocked $root
    Assert-True ($r.ExitCode -eq 0) '(a) the dispatcher exits 0'
    Assert-True ((Get-JournalHashes $root) -contains (Get-TextHash $reasonA)) '(a) the stop reason is journaled once the lock frees'
    Assert-True (@(Get-BufferFiles $root).Count -eq 0) '(a) nothing went to the outage buffer'
    Assert-True (-not (@(Get-HealthStates $root) -contains 'degraded')) '(a) no degraded transition'
    Assert-True (-not (Test-Path -LiteralPath ((Get-RuntimePath $root 'hook-output-authority.jsonl') + '.unhealthy'))) '(a) no .unhealthy marker is written (B4F-108 latch)'

    Write-Host '--- case (b): a lock held past the window degrades to the per-process buffer, never a latch ---'
    $reasonB = 'RENDER THE PACKET NOW (b) ' + [guid]::NewGuid().ToString('N')
    $r = Invoke-StopWithReason -Root $root -Reason $reasonB -HoldMs 4000
    Assert-True ($r.ExitCode -eq 0) '(b) the dispatcher exits 0'
    Assert-True ($r.StdOut -match '"decision"\s*:\s*"block"') '(b) the stop block is still delivered (its hash is buffered, so it is safe to show)'
    $bufferText = (@(Get-BufferFiles $root) | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }) -join "`n"
    Assert-True ($bufferText -match (Get-TextHash $reasonB)) '(b) the reason hash is in an outage-buffer file'
    # Co-review round 2: every buffered record is published as its own closed file, never appended to a visible one -
    # on Linux and macOS a flush could otherwise remove a file a writer still held open, losing what it wrote next.
    $bufferFilesB = @(Get-BufferFiles $root)
    $lineCounts = @($bufferFilesB | ForEach-Object { @([IO.File]::ReadAllLines($_.FullName) | Where-Object { $_.Trim() }).Count })
    Assert-True ($bufferFilesB.Count -ge 2 -and @($lineCounts | Where-Object { $_ -ne 1 }).Count -eq 0) ("(b) each buffered record is its own published file ({0} files, lines per file: {1})" -f $bufferFilesB.Count, ($lineCounts -join ','))
    Assert-True (@($bufferFilesB | Where-Object { $_.Extension -ne '.jsonl' }).Count -eq 0) '(b) no half-written buffer file is left visible'
    Assert-True (@(Get-HealthStates $root) -contains 'degraded') '(b) a degraded transition is recorded in the health journal'
    Assert-True (-not (Test-Path -LiteralPath ((Get-RuntimePath $root 'hook-output-authority.jsonl') + '.unhealthy'))) '(b) still no .unhealthy marker'
    # The next prompt decision: the lock has gone, the buffer still holds the hash (nothing has flushed it yet).
    Wait-JournalUnlocked $root
    Assert-True (@(Get-BufferFiles $root).Count -gt 0) '(b) the buffer is still pending before the next append'
    Assert-True (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $reasonB) '(b)(d) the buffered hook output is refused as a reply'
    Assert-True (-not (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $typedReply)) '(b) an unrelated typed reply is NOT refused while degraded (no latch)'

    Write-Host '--- case (c): the next good append flushes the buffer and records recovery ---'
    $reasonC = 'RENDER THE PACKET NOW (c) ' + [guid]::NewGuid().ToString('N')
    $r = Invoke-StopWithReason -Root $root -Reason $reasonC
    Assert-True ($r.ExitCode -eq 0) '(c) the dispatcher exits 0'
    $hashes = Get-JournalHashes $root
    Assert-True ($hashes -contains (Get-TextHash $reasonB)) '(c) the buffered hash is flushed into the journal'
    Assert-True ($hashes -contains (Get-TextHash $reasonC)) '(c) the new reason is journaled'
    Assert-True (@(Get-BufferFiles $root).Count -eq 0) '(c) the buffer files are removed after the flush'
    $states = @(Get-HealthStates $root)
    Assert-True ((Get-LastHealthState $root) -eq 'recovered') '(c) a recovered transition follows the degraded one'
    Assert-True (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $reasonB) '(c)(d) the flushed output is still refused as a reply'
    Assert-True (-not (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $typedReply)) '(c) a typed reply counts'

    Write-Host '--- unread buffer data is never removed (co-review round 1) ---'
    # A buffer file another process holds open so it cannot be READ, while still allowing it to be deleted. The old
    # flush swallowed the read error and then deleted every file it had listed, so this hash was lost.
    $bufferDirH = Get-RuntimePath $root 'hook-output-buffer'
    [IO.Directory]::CreateDirectory($bufferDirH) | Out-Null
    $reasonH = 'RENDER THE PACKET NOW (h) ' + [guid]::NewGuid().ToString('N')
    $bufferH = Join-Path $bufferDirH '999-held.jsonl'
    [IO.File]::WriteAllText($bufferH, (([ordered]@{ schema_version = '1.0'; output_hash = (Get-TextHash $reasonH); event = 'Stop' } | ConvertTo-Json -Compress) + "`n"))
    $readyH = Join-Path $root ('held-ready-' + [guid]::NewGuid().ToString('N'))
    $holderH = '$f = [IO.File]::Open(''{0}'', ''Open'', ''ReadWrite'', ''Delete''); [IO.File]::WriteAllText(''{1}'', ''1''); Start-Sleep -Milliseconds 6000; $f.Dispose()' -f $bufferH, $readyH
    $holderProc = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-Command', $holderH) -WindowStyle Hidden -PassThru
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while (-not (Test-Path -LiteralPath $readyH) -and $sw.ElapsedMilliseconds -lt 15000) { Start-Sleep -Milliseconds 20 }
    $r = Invoke-StopWithReason -Root $root -Reason ('RENDER THE PACKET NOW (h1) ' + [guid]::NewGuid().ToString('N'))
    Assert-True ($r.ExitCode -eq 0) '(h) the dispatcher exits 0'
    Assert-True (@(Get-BufferFiles $root | Where-Object { $_.Name -like '*.jsonl' }).Count -ge 1) '(h) the buffer file it could not read is kept'
    $holderProc.WaitForExit(20000) | Out-Null
    Assert-True (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $reasonH) '(h) its hash is still recognized as hook output'
    $r = Invoke-StopWithReason -Root $root -Reason ('RENDER THE PACKET NOW (h2) ' + [guid]::NewGuid().ToString('N'))
    Assert-True ((Get-JournalHashes $root) -contains (Get-TextHash $reasonH)) '(h) once readable, the next good append flushes it into the journal'
    Assert-True (@(Get-BufferFiles $root).Count -eq 0) '(h) and only then is the buffer file removed'

    Write-Host '--- (i) the episode stays degraded while a kept buffer file is unreadable (co-review round 2) ---'
    # A degraded episode, then its buffered record held unreadable through the next good append. The old flush kept
    # the file but still recorded 'recovered', which hid the degraded disclosure and closed the recovery question
    # while the unreadable buffer kept prompts from being vouched for.
    $reasonI = 'RENDER THE PACKET NOW (i) ' + [guid]::NewGuid().ToString('N')
    $r = Invoke-StopWithReason -Root $root -Reason $reasonI -HoldMs 4000
    Wait-JournalUnlocked $root
    Assert-True ((Get-LastHealthState $root) -eq 'degraded') '(i) the held journal opened a degraded episode'
    $heldI = @(Get-BufferFiles $root | Where-Object { [IO.File]::ReadAllText($_.FullName) -match (Get-TextHash $reasonI) }) | Select-Object -First 1
    $readyI = Join-Path $root ('held-ready-' + [guid]::NewGuid().ToString('N'))
    $holderI = '$f = [IO.File]::Open(''{0}'', ''Open'', ''ReadWrite'', ''Delete''); [IO.File]::WriteAllText(''{1}'', ''1''); Start-Sleep -Milliseconds 6000; $f.Dispose()' -f $heldI.FullName, $readyI
    $holderProcI = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-Command', $holderI) -WindowStyle Hidden -PassThru
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while (-not (Test-Path -LiteralPath $readyI) -and $sw.ElapsedMilliseconds -lt 15000) { Start-Sleep -Milliseconds 20 }
    $r = Invoke-StopWithReason -Root $root -Reason ('RENDER THE PACKET NOW (i1) ' + [guid]::NewGuid().ToString('N'))
    Assert-True ($r.ExitCode -eq 0) '(i) the dispatcher exits 0'
    Assert-True (@(Get-BufferFiles $root).Count -ge 1) '(i) the unreadable buffer file is kept'
    Assert-True ((Get-LastHealthState $root) -eq 'degraded') '(i) the episode is NOT closed while that buffer is unreadable'
    Assert-True ($null -ne (Get-SpecrewReplyRecordingDegradedSince -ProjectRoot $root)) '(i) so the degraded disclosure and the recovery question still apply'
    $holderProcI.WaitForExit(20000) | Out-Null
    $r = Invoke-StopWithReason -Root $root -Reason ('RENDER THE PACKET NOW (i2) ' + [guid]::NewGuid().ToString('N'))
    Assert-True ((Get-JournalHashes $root) -contains (Get-TextHash $reasonI)) '(i) once readable, the next good append flushes it'
    Assert-True (@(Get-BufferFiles $root).Count -eq 0 -and (Get-LastHealthState $root) -eq 'recovered') '(i) and only then is the episode recorded as recovered'

    Write-Host '--- legacy marker: an .unhealthy file from an older version is degraded, not a permanent refusal ---'
    $marker = (Get-RuntimePath $root 'hook-output-authority.jsonl') + '.unhealthy'
    [IO.File]::WriteAllText($marker, 'The process cannot access the file because it is being used by another process.')
    Assert-True (-not (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $typedReply)) 'legacy marker: a typed reply is not refused (FR-003)'
    Assert-True (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $reasonC) 'legacy marker: journaled hook output is still refused'
    $reasonL = 'RENDER THE PACKET NOW (legacy) ' + [guid]::NewGuid().ToString('N')
    $r = Invoke-StopWithReason -Root $root -Reason $reasonL
    Assert-True (-not (Test-Path -LiteralPath $marker)) 'legacy marker: the next good append clears it'
    Assert-True ((Get-LastHealthState $root) -eq 'recovered') 'legacy marker: the clear is recorded as recovered'

    Write-Host '--- buffer write fails too: only that turn fails closed ---'
    $bufferDir = Get-RuntimePath $root 'hook-output-buffer'
    if (Test-Path -LiteralPath $bufferDir) { Remove-Item -LiteralPath $bufferDir -Recurse -Force }
    [IO.File]::WriteAllText($bufferDir, 'a file where the buffer directory should be')
    $reasonF = 'RENDER THE PACKET NOW (f) ' + [guid]::NewGuid().ToString('N')
    $r = Invoke-StopWithReason -Root $root -Reason $reasonF -HoldMs 4000
    Assert-True ($r.ExitCode -eq 0) 'buffer failure: the dispatcher exits 0'
    Assert-True (-not ($r.StdOut -match [regex]::Escape($reasonF))) 'buffer failure: output that could not be recorded is withheld this turn, so it cannot be replayed as a reply'
    Assert-True ($r.StdErr -match 'HOOK_OUTPUT') 'buffer failure: the withheld output is reported on stderr'
    Wait-JournalUnlocked $root
    Remove-Item -LiteralPath $bufferDir -Force
    $reasonG = 'RENDER THE PACKET NOW (g) ' + [guid]::NewGuid().ToString('N')
    $r = Invoke-StopWithReason -Root $root -Reason $reasonG
    Assert-True ($r.StdOut -match '"decision"\s*:\s*"block"') 'buffer failure: the next turn delivers normally (only that turn failed closed)'
    Assert-True (-not (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $typedReply)) 'buffer failure: typed replies still count afterwards'

    Write-Host '--- integrity stores hold hashes only (FR-008) ---'
    $storeText = Get-AllStoreText $root
    foreach ($reason in $reasonA, $reasonB, $reasonC, $reasonL, $reasonG) {
        Assert-True (-not $storeText.Contains($reason)) ("no reason text is stored: '{0}...'" -f $reason.Substring(0, 26))
    }
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}

if ($script:failCount -gt 0) { Write-Host "hook-output-journal: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'hook-output-journal: all passed' -ForegroundColor Green

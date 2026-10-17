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
# The helper processes' platform shape (202 DRIFT-018). Hidden windows exist only on Windows. To make a buffer file
# unreadable to another reader, Windows needs only a Delete-only share (which still lets the round-1 flush delete
# it - that was the RED); on Linux and macOS only an exclusive hold blocks a reader (.NET's flock mapping).
$HiddenWindow = if ($IsWindows) { @{ WindowStyle = 'Hidden' } } else { @{} }
$script:UnreadableShare = if ($IsWindows) { 'Delete' } else { 'None' }
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
    # journal's write lock exclusively and holds it that long, and returns only once the lock is held - so the
    # dispatcher's journal write, a few milliseconds after this provider exits, is guaranteed to meet it.
    #
    # WHERE THAT LOCK LIVES DIFFERS BY OS (202 DRIFT-018, first 3-OS run of this suite). On Windows it is the journal
    # itself: a FileShare.None handle refuses the dispatcher's open. On Linux and macOS, .NET takes an advisory flock
    # only for FileShare.None or for read-only access, so a writer opening the journal with ReadWrite sharing is never
    # blocked by a holder of the journal; contention between Specrew writers lives on the sidecar `<journal>.lock`
    # the per-write lock takes. The holder therefore takes that sidecar off Windows - the real Unix contention point.
    $stub = @'
if ($env:HOJ_HOLD_MS) {
    $journal = Join-Path (Get-Location).Path '.specrew/runtime/hook-output-authority.jsonl'
    if (-not $IsWindows) { $journal = $journal + '.lock' }
    $ready = Join-Path (Get-Location).Path ('lock-ready-' + [guid]::NewGuid().ToString('N'))
    $holder = '$f = [IO.File]::Open(''{0}'', ''OpenOrCreate'', ''ReadWrite'', ''None''); [IO.File]::WriteAllText(''{1}'', ''1''); [Threading.Thread]::Sleep({2}); $f.Dispose()' -f $journal, $ready, $env:HOJ_HOLD_MS
    # Off Windows the holder's output goes to files: Start-Process there lets the child inherit this stub's stdout,
    # which is the dispatcher's pipe, so the dispatcher's read of this provider's output would wait for the holder to
    # exit - and the lock would be gone before the append it is meant to meet.
    $hidden = if ($IsWindows) { @{ WindowStyle = 'Hidden' } } else { @{ RedirectStandardOutput = ($ready + '.out'); RedirectStandardError = ($ready + '.err') } }
    Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-Command', $holder) @hidden | Out-Null
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while (-not (Test-Path -LiteralPath $ready) -and $sw.ElapsedMilliseconds -lt 15000) { Start-Sleep -Milliseconds 5 }
}
Write-Output ("<<<SPECREW-STOP-BLOCK>>>`n" + $env:HOJ_REASON)
exit 0
'@
    [IO.File]::WriteAllText((Join-Path $scripts 'stub-block.ps1'), $stub, [Text.UTF8Encoding]::new($false))
    # Co-review round 3: a prompt-time provider that has just used (or refused) the human's reply. It journals that
    # receipt outcome the way the store does, then starts the same lock holder, so the dispatcher's FINAL append is the
    # first one to fail - after the provider composed its payload while recording was still healthy.
    $injectStub = @'
if ($env:HOJ_OUTCOME) {
    # Like the store: the row names the reply it answers (its hash) and the session it was typed in. HOJ_OUTCOME_SESSION
    # writes it as ANOTHER session's outcome, landing inside this fire.
    $hash = ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes('It is for support staff.')))).ToLowerInvariant()
    $session = if ($env:HOJ_OUTCOME_SESSION) { $env:HOJ_OUTCOME_SESSION } else { 'hoj-session' }
    $row = [ordered]@{ status = $env:HOJ_OUTCOME; reason = 'stub'; feature_ref = '001-x'; phase = 'product-domain'; consumed = ($env:HOJ_OUTCOME -eq 'recorded'); recorded_at = [DateTimeOffset]::UtcNow.ToString('o'); response_hash = $hash; session_id = $session }
    # T022 (FR-033): in that session's own folder, as the store records it.
    $owner = -join ([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes('claude|' + $session)) | ForEach-Object { $_.ToString('x2') })
    $dir = Join-Path (Get-Location).Path ('.specrew/runtime/conformance-sessions/' + $owner)
    [IO.Directory]::CreateDirectory($dir) | Out-Null
    [IO.File]::WriteAllText((Join-Path $dir 'workshop-receipt-outcome.json'), ([ordered]@{ schema_version = '1.0'; last = $row; refusals = @{} } | ConvertTo-Json -Depth 6 -Compress))
}
if ($env:HOJ_STAMP) {
    # Like the bootstrap provider: the session's orientation stamp is written before the payload is returned.
    [IO.File]::WriteAllText((Join-Path (Get-Location).Path '.specrew/runtime/hook-bootstrap-orientation-hoj-session.json'), '{"supplied_at":"stub"}')
}
if ($env:HOJ_NOTRECORDED) {
    # Like the store's not-recorded disclosure: the line is marked said for this session before the payload carries it.
    $drops = Join-Path (Get-Location).Path '.specrew/runtime/authority-capture-drops.jsonl'
    Add-Content -LiteralPath $drops -Value ('{"event":"authority-phrase-not-recorded","phrase":"review-round-approval","reason":"message-hook-did-not-record","retype":"approved for review round","entry_key":"' + $env:HOJ_NOTRECORDED + '","host_kind":"claude","session_id":"hoj-session","recorded_at":"' + [DateTimeOffset]::UtcNow.ToString('o') + '"}') -Encoding UTF8
    Add-Content -LiteralPath $drops -Value ('{"event":"authority-phrase-not-recorded-disclosed","entry_key":"' + $env:HOJ_NOTRECORDED + '","host_kind":"claude","session_id":"hoj-session","recorded_at":"' + [DateTimeOffset]::UtcNow.ToString('o') + '"}') -Encoding UTF8
    # HOJ_NOTRECORDED_LOST: the provider marked the line said and then lost it (a timeout, a failure) - the payload omits it.
    if (-not $env:HOJ_NOTRECORDED_LOST) { $env:HOJ_REASON = $env:HOJ_REASON + "`nSpecrew: your earlier 'approved for review round' was not recorded." }
}
if ($env:HOJ_RECOVERY) {
    # Like the store's recovery ask: the open question is recorded for this session before the payload that asks it.
    [IO.File]::WriteAllText((Join-Path (Get-Location).Path '.specrew/runtime/reply-recording-recovery-request.json'), ('{"schema_version":"1.0","asked_at":"' + [DateTimeOffset]::UtcNow.ToString('o') + '","asked_session":"hoj-session","degraded_since":"2026-10-16T00:00:00.0000000+00:00","question_hash":"stub"}'))
}
'@ + "`n" + ($stub -replace '(?s)Write-Output \("<<<SPECREW-STOP-BLOCK>>>`n" \+ \$env:HOJ_REASON\)', 'Write-Output $env:HOJ_REASON')
    [IO.File]::WriteAllText((Join-Path $scripts 'stub-inject.ps1'), $injectStub, [Text.UTF8Encoding]::new($false))
    $catalog = [ordered]@{ schema_version = '1'; providers = @(
            [ordered]@{ id = 'stub-block'; kind = 'inject'; events = @('Stop'); order = 40; budget_share = 1.0; command = 'stub-block.ps1' },
            [ordered]@{ id = 'stub-inject'; kind = 'inject'; events = @('UserPromptSubmit'); order = 40; budget_share = 1.0; command = 'stub-inject.ps1' }) }
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

function Invoke-PromptWithPayload {
    param([string]$Root, [string]$Payload, [int]$HoldMs = 0, [string]$Outcome = '', [switch]$Stamp, [switch]$Recovery, [string]$OutcomeSession = '', [string]$NotRecordedKey = '', [switch]$NotRecordedLost)
    $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
    foreach ($a in '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Root '.specify\extensions\specrew-speckit\scripts\specrew-hook-dispatcher.ps1'), '-Event', 'UserPromptSubmit', '-HostKind', 'claude') { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $Root
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.Environment['SPECREW_MODULE_PATH'] = $repoRoot
    $psi.Environment['HOJ_REASON'] = $Payload
    if ($HoldMs -gt 0) { $psi.Environment['HOJ_HOLD_MS'] = [string]$HoldMs } else { $psi.Environment.Remove('HOJ_HOLD_MS') | Out-Null }
    if ($Outcome) { $psi.Environment['HOJ_OUTCOME'] = $Outcome } else { $psi.Environment.Remove('HOJ_OUTCOME') | Out-Null }
    if ($Stamp) { $psi.Environment['HOJ_STAMP'] = '1' } else { $psi.Environment.Remove('HOJ_STAMP') | Out-Null }
    if ($Recovery) { $psi.Environment['HOJ_RECOVERY'] = '1' } else { $psi.Environment.Remove('HOJ_RECOVERY') | Out-Null }
    if ($NotRecordedKey) { $psi.Environment['HOJ_NOTRECORDED'] = $NotRecordedKey } else { $psi.Environment.Remove('HOJ_NOTRECORDED') | Out-Null }
    if ($NotRecordedLost) { $psi.Environment['HOJ_NOTRECORDED_LOST'] = '1' } else { $psi.Environment.Remove('HOJ_NOTRECORDED_LOST') | Out-Null }
    if ($OutcomeSession) { $psi.Environment['HOJ_OUTCOME_SESSION'] = $OutcomeSession } else { $psi.Environment.Remove('HOJ_OUTCOME_SESSION') | Out-Null }
    foreach ($var in 'CLAUDE_PROJECT_DIR', 'COPILOT_PROJECT_DIR', 'CURSOR_PROJECT_DIR') { $psi.Environment[$var] = $Root }
    $p = [Diagnostics.Process]::Start($psi)
    $o = $p.StandardOutput.ReadToEndAsync(); $e = $p.StandardError.ReadToEndAsync()
    $p.StandardInput.Write('{"session_id":"hoj-session","prompt":"It is for support staff.","hook_event_name":"UserPromptSubmit"}'); $p.StandardInput.Close()
    if (-not $p.WaitForExit(60000)) { $p.Kill($true); throw 'dispatcher timed out' }
    $context = $null
    try { $context = [string](($o.Result | ConvertFrom-Json).hookSpecificOutput.additionalContext) } catch { $context = $null }
    return [pscustomobject]@{ ExitCode = $p.ExitCode; StdOut = $o.Result; StdErr = $e.Result; Context = $context }
}

function Wait-JournalUnlocked {
    # The holder the stub started may outlive the dispatcher; wait until the journal opens exclusively again.
    param([string]$Root)
    $journal = Get-RuntimePath $Root 'hook-output-authority.jsonl'
    if (-not $IsWindows) { $journal = $journal + '.lock' }  # the lock the stub's holder takes off Windows
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
    return @([IO.File]::ReadAllLines($path) | Where-Object { $_.Trim() } | ForEach-Object { $h = $_ | ConvertFrom-Json; if ($h -is [pscustomobject] -and $h.PSObject.Properties['state']) { $h.state } })
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
    # Co-review round 4 (202, FR-007): the stop block's own append is where this episode began, so the block says so in
    # the same turn - before, only the injection path disclosed it and a stop block went out unchanged.
    $blockB = try { ($r.StdOut | ConvertFrom-Json).reason } catch { '' }
    Assert-True ([string]$blockB -match [regex]::Escape($reasonB) -and [string]$blockB -match 'recorded in a fallback record') '(b) the stop block carries the same-turn disclosure that recording is degraded'
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
    $holderH = '$f = [IO.File]::Open(''{0}'', ''Open'', ''ReadWrite'', ''{2}''); [IO.File]::WriteAllText(''{1}'', ''1''); Start-Sleep -Milliseconds 6000; $f.Dispose()' -f $bufferH, $readyH, $script:UnreadableShare
    $holderProc = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-Command', $holderH) @HiddenWindow -PassThru
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
    $holderI = '$f = [IO.File]::Open(''{0}'', ''Open'', ''ReadWrite'', ''{2}''); [IO.File]::WriteAllText(''{1}'', ''1''); Start-Sleep -Milliseconds 6000; $f.Dispose()' -f $heldI.FullName, $readyI, $script:UnreadableShare
    $holderProcI = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-Command', $holderI) @HiddenWindow -PassThru
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
    # Co-review round 4 (202, FR-007): withheld is still said. The stop block carries the one 'Specrew:' sentence instead
    # of {} - before, the stop was allowed with no word that guidance was held back.
    $blockF = try { ($r.StdOut | ConvertFrom-Json).reason } catch { '' }
    Assert-True ([string]$blockF -match '^Specrew:' -and [string]$blockF -match 'held back') 'buffer failure: the stop block says the guidance was held back'
    Assert-True (-not (Test-SpecrewWorkshopHumanResponseText -Text ([string]$blockF))) 'buffer failure: that unrecorded sentence can never count as a typed reply'
    Wait-JournalUnlocked $root
    Remove-Item -LiteralPath $bufferDir -Force
    $reasonG = 'RENDER THE PACKET NOW (g) ' + [guid]::NewGuid().ToString('N')
    $r = Invoke-StopWithReason -Root $root -Reason $reasonG
    Assert-True ($r.StdOut -match '"decision"\s*:\s*"block"') 'buffer failure: the next turn delivers normally (only that turn failed closed)'
    Assert-True (-not (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $typedReply)) 'buffer failure: typed replies still count afterwards'

    # Co-review round 3 (202): a health line that is valid JSON but not a record ({}) was handed back as the last
    # record, and reading its state under StrictMode threw on every append after it - on the good path and the
    # degraded one. The line stays in the append-only journal, so that was a latch.
    Write-Host '--- a damaged health line never stops the next append ---'
    [IO.File]::AppendAllText((Get-RuntimePath $root 'hook-output-health.jsonl'), "{}`n")
    $reasonH2 = 'RENDER THE PACKET NOW (h2) ' + [guid]::NewGuid().ToString('N')
    $r = Invoke-StopWithReason -Root $root -Reason $reasonH2
    Assert-True ($r.ExitCode -eq 0 -and $r.StdOut -match [regex]::Escape($reasonH2)) 'damaged health line: the good-path append delivers the output'
    Assert-True ((Get-JournalHashes $root) -contains (Get-TextHash $reasonH2)) 'damaged health line: the good-path output is journaled'
    $reasonH3 = 'RENDER THE PACKET NOW (h3) ' + [guid]::NewGuid().ToString('N')
    $r = Invoke-StopWithReason -Root $root -Reason $reasonH3 -HoldMs 4000
    Wait-JournalUnlocked $root
    Assert-True ($r.ExitCode -eq 0 -and $r.StdOut -match [regex]::Escape($reasonH3)) 'damaged health line: the degraded path buffers and delivers the output'
    Assert-True ((Get-LastHealthState $root) -eq 'degraded') 'damaged health line: the degraded transition is still recorded'
    $reasonH4 = 'RENDER THE PACKET NOW (h4) ' + [guid]::NewGuid().ToString('N')
    $r = Invoke-StopWithReason -Root $root -Reason $reasonH4
    Assert-True ((Get-LastHealthState $root) -eq 'recovered' -and @(Get-BufferFiles $root).Count -eq 0) 'damaged health line: the next good append flushes and recovers'

    # Co-review round 6 (202, FR-003): a last health line with a state but no class or first_seen passed round 3's guard,
    # and the recovery reader then threw on the missing fields under StrictMode, after every good append - a new latch.
    Write-Host '--- a partial degraded health line never stops the next append, and recovery still closes it ---'
    [IO.File]::AppendAllText((Get-RuntimePath $root 'hook-output-health.jsonl'), '{"state":"degraded"}' + "`n")
    $reasonH5 = 'RENDER THE PACKET NOW (h5) ' + [guid]::NewGuid().ToString('N')
    $r = Invoke-StopWithReason -Root $root -Reason $reasonH5
    Assert-True ($r.ExitCode -eq 0 -and $r.StdOut -match [regex]::Escape($reasonH5)) 'partial health line: the good-path append delivers the output'
    Assert-True ((Get-LastHealthState $root) -eq 'recovered') 'partial health line: the episode is closed with a recovered line'
    Assert-True ($r.StdErr -notmatch 'PROVIDER_FAILED') 'partial health line: the dispatcher does not fail open'

    # Co-review round 3 (202, FR-007 / SC-002): a degraded episode that STARTS at the dispatcher's final append - after
    # the provider composed its payload while recording was healthy - is said in that same turn, with whether the reply
    # was used. Before the fix the payload went out unchanged and only stderr knew.
    Write-Host '--- recording that first fails at the final append is disclosed in the same turn ---'
    $p4 = New-JournalProject
    try {
        $payloadA = 'Thanks - recorded your product answer. Next question: what is the main pain? ' + [guid]::NewGuid().ToString('N')
        $r = Invoke-PromptWithPayload -Root $p4 -Payload $payloadA -HoldMs 4000 -Outcome 'recorded'
        Wait-JournalUnlocked $p4
        Assert-True ($r.ExitCode -eq 0 -and $null -ne $r.Context -and $r.Context.Contains($payloadA)) 'final-append degrade: the payload is still delivered'
        Assert-True ($null -ne $r.Context -and $r.Context -match 'recorded in a fallback record' -and $r.Context -match 'your reply was used as your workshop answer') 'final-append degrade: the same turn says recording is degraded, and that the reply was used'
        Assert-True ($null -ne $r.Context -and (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $p4 -Response $r.Context)) 'final-append degrade: the output as delivered, disclosure included, is recorded as hook output'

        $payloadB = 'Already degraded: the provider said so itself. Specrew: replies are being recorded in a fallback record until the main one is free again; your reply was used as your workshop answer, and nothing is lost. ' + [guid]::NewGuid().ToString('N')
        $r = Invoke-PromptWithPayload -Root $p4 -Payload $payloadB -HoldMs 4000 -Outcome 'recorded'
        Wait-JournalUnlocked $p4
        Assert-True ($null -ne $r.Context -and ([regex]::Matches($r.Context, 'recorded in a fallback record')).Count -eq 1) 'a payload that already discloses it is not given a second copy'

        # Co-review round 5 (202, FR-007): the outcome journal is shared by every session in the project. An outcome
        # another session recorded during this fire is not this reply's, and the turn must not claim it was used.
        $payloadD = 'Guidance while another session answers ' + [guid]::NewGuid().ToString('N')
        $r = Invoke-PromptWithPayload -Root $p4 -Payload $payloadD -HoldMs 4000 -Outcome 'recorded' -OutcomeSession 'another-session'
        Wait-JournalUnlocked $p4
        Assert-True ($null -ne $r.Context -and $r.Context -match 'recorded in a fallback record') 'another session''s outcome: the degraded turn is still disclosed'
        Assert-True ($null -ne $r.Context -and $r.Context -notmatch 'your reply was used as your workshop answer') 'another session''s outcome: the turn does not claim this reply was used'

        $bufferDir4 = Get-RuntimePath $p4 'hook-output-buffer'
        if (Test-Path -LiteralPath $bufferDir4) { Remove-Item -LiteralPath $bufferDir4 -Recurse -Force }
        [IO.File]::WriteAllText($bufferDir4, 'a file where the buffer directory should be')
        $payloadC = 'Guidance that cannot be recorded this turn ' + [guid]::NewGuid().ToString('N')
        $r = Invoke-PromptWithPayload -Root $p4 -Payload $payloadC -HoldMs 4000 -Outcome 'refused'
        Wait-JournalUnlocked $p4
        Assert-True (-not $r.StdOut.Contains($payloadC)) 'withheld: the unrecordable payload is still withheld (FR-005)'
        Assert-True ($null -ne $r.Context -and $r.Context -match '^Specrew:' -and $r.Context -match 'held back' -and $r.Context -match 'your reply was not used as your workshop answer') 'withheld: the turn still says so, and whether the reply was used'
        Assert-True ($null -ne $r.Context -and -not (Test-SpecrewWorkshopHumanResponseText -Text $r.Context)) 'withheld: that unrecorded disclosure can never count as a typed reply'
        Remove-Item -LiteralPath $bufferDir4 -Force

        # Co-review round 4 (202, FR-005 / FR-014): an orientation stamped as supplied during a fire whose output was
        # withheld was never delivered. The stamp must not survive, or every later prompt skips the orientation.
        $stampPath = Get-RuntimePath $p4 'hook-bootstrap-orientation-hoj-session.json'
        if (Test-Path -LiteralPath $stampPath) { Remove-Item -LiteralPath $stampPath -Force }
        [IO.File]::WriteAllText($bufferDir4, 'a file where the buffer directory should be')
        $r = Invoke-PromptWithPayload -Root $p4 -Payload ('Orientation that cannot be recorded ' + [guid]::NewGuid().ToString('N')) -HoldMs 4000 -Stamp
        Wait-JournalUnlocked $p4
        Assert-True ($null -ne $r.Context -and $r.Context -match 'held back') 'withheld orientation: the turn says its guidance was held back'
        Assert-True (-not (Test-Path -LiteralPath $stampPath)) 'withheld orientation: the stamp written during that fire is removed, so the next prompt supplies it again'
        Remove-Item -LiteralPath $bufferDir4 -Force
        $r = Invoke-PromptWithPayload -Root $p4 -Payload ('Orientation delivered ' + [guid]::NewGuid().ToString('N')) -Stamp
        Assert-True ((Test-Path -LiteralPath $stampPath) -and $null -ne $r.Context -and $r.Context -match 'Orientation delivered') 'delivered orientation: its stamp stays'
        [IO.File]::WriteAllText($bufferDir4, 'a file where the buffer directory should be')
        $r = Invoke-PromptWithPayload -Root $p4 -Payload ('Later guidance that cannot be recorded ' + [guid]::NewGuid().ToString('N')) -HoldMs 4000
        Wait-JournalUnlocked $p4
        Assert-True (Test-Path -LiteralPath $stampPath) 'a later withheld turn leaves an earlier, delivered orientation stamp alone'
        Remove-Item -LiteralPath $bufferDir4 -Force

        # Co-review round 5 (202, FR-009): the recovery question is recorded as open before the payload that asks it.
        # When that fire's output was withheld, the human never saw the question, so a later "yes" must not answer it.
        $requestPath = Get-RuntimePath $p4 'reply-recording-recovery-request.json'
        if (Test-Path -LiteralPath $requestPath) { Remove-Item -LiteralPath $requestPath -Force }
        [IO.File]::WriteAllText($bufferDir4, 'a file where the buffer directory should be')
        $r = Invoke-PromptWithPayload -Root $p4 -Payload ('Recovery question that cannot be recorded ' + [guid]::NewGuid().ToString('N')) -HoldMs 4000 -Recovery
        Wait-JournalUnlocked $p4
        Assert-True ($null -ne $r.Context -and $r.Context -match 'held back') 'withheld recovery question: the turn says its guidance was held back'
        Assert-True (-not (Test-Path -LiteralPath $requestPath)) 'withheld recovery question: the open question recorded during that fire is removed, so a later yes cannot answer it'
        Remove-Item -LiteralPath $bufferDir4 -Force
        $r = Invoke-PromptWithPayload -Root $p4 -Payload ('Recovery question delivered ' + [guid]::NewGuid().ToString('N')) -Recovery
        Assert-True ((Test-Path -LiteralPath $requestPath) -and $null -ne $r.Context -and $r.Context -match 'Recovery question delivered') 'delivered recovery question: it stays open'
        [IO.File]::WriteAllText($bufferDir4, 'a file where the buffer directory should be')
        $r = Invoke-PromptWithPayload -Root $p4 -Payload ('Later guidance that cannot be recorded ' + [guid]::NewGuid().ToString('N')) -HoldMs 4000
        Wait-JournalUnlocked $p4
        Assert-True (Test-Path -LiteralPath $requestPath) 'a later withheld turn leaves an earlier, delivered recovery question open'
        Remove-Item -LiteralPath $bufferDir4 -Force

        # Co-review round 2 (202 iteration 002, FR-027): the not-recorded approval line is marked said before the payload
        # that carries it. When that fire's output was withheld, the line is put back so the next message says it.
        $drops = Get-RuntimePath $p4 'authority-capture-drops.jsonl'
        $undelivered = { param($k) @(if (Test-Path -LiteralPath $drops) { [IO.File]::ReadAllLines($drops) | Where-Object { $_ -match 'not-recorded-undelivered' -and $_ -match ('"' + $k + '"') } }).Count }
        [IO.File]::WriteAllText($bufferDir4, 'a file where the buffer directory should be')
        $r = Invoke-PromptWithPayload -Root $p4 -Payload ('Not-recorded line that cannot be delivered ' + [guid]::NewGuid().ToString('N')) -HoldMs 4000 -NotRecordedKey 'nr-withheld'
        Wait-JournalUnlocked $p4
        Assert-True ($null -ne $r.Context -and $r.Context -match 'held back') 'withheld not-recorded line: the turn says its guidance was held back'
        Assert-True ((& $undelivered 'nr-withheld') -eq 1) 'withheld not-recorded line: the line marked said during that fire is put back'
        Remove-Item -LiteralPath $bufferDir4 -Force
        $r = Invoke-PromptWithPayload -Root $p4 -Payload ('Not-recorded line delivered ' + [guid]::NewGuid().ToString('N')) -NotRecordedKey 'nr-delivered'
        Assert-True ((& $undelivered 'nr-delivered') -eq 0) 'delivered not-recorded line: it stays said'
        # Co-review round 3: a provider that marked the line said and then lost it (timeout, failure) delivers output
        # without the line, and nothing was withheld. The line is put back all the same.
        $r = Invoke-PromptWithPayload -Root $p4 -Payload ('Guidance from a provider that lost the line ' + [guid]::NewGuid().ToString('N')) -NotRecordedKey 'nr-lost' -NotRecordedLost
        Assert-True ($null -ne $r.Context -and $r.Context -notmatch 'held back') 'lost not-recorded line: the output itself was delivered'
        Assert-True ((& $undelivered 'nr-lost') -eq 1) 'lost not-recorded line: the line the human did not get is put back'
    }
    finally { Remove-Item -LiteralPath $p4 -Recurse -Force -ErrorAction SilentlyContinue }

    # Co-review round 4 (202 iteration 002, FR-027): the dispatcher itself fails after the provider marked the line said
    # (here: the session's refocus state can be read but not written). Its fail-open exit delivers no line, so the line
    # is put back there too.
    $p5 = New-JournalProject
    try {
        # The not-recorded provider runs first; the refocus row after it dirties the session state, whose save then fails.
        [IO.File]::WriteAllText((Join-Path $p5 '.specify\extensions\specrew-speckit\scripts\stub-noop.ps1'), '', [Text.UTF8Encoding]::new($false))
        $catalog5 = [ordered]@{ schema_version = '1'; providers = @(
                [ordered]@{ id = 'stub-inject'; kind = 'inject'; events = @('UserPromptSubmit'); order = 40; budget_share = 0.5; command = 'stub-inject.ps1' },
                [ordered]@{ id = 'refocus'; kind = 'inject'; events = @('UserPromptSubmit'); order = 60; budget_share = 0.5; command = 'stub-noop.ps1' }) }
        [IO.File]::WriteAllText((Join-Path $p5 '.specify\extensions\specrew-speckit\refocus-scopes.json'), ($catalog5 | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
        $state5 = Get-RuntimePath $p5 'refocus-state-hoj-session.json'
        [IO.File]::WriteAllText($state5, '{"session_id":"hoj-session","last_seen_boundary":null,"context_mtime":null,"breaker":null,"journal":[]}')
        if ($IsWindows) { [IO.File]::SetAttributes($state5, [IO.FileAttributes]::ReadOnly) } else { & chmod 444 $state5 }
        $drops5 = Get-RuntimePath $p5 'authority-capture-drops.jsonl'
        $r = Invoke-PromptWithPayload -Root $p5 -Payload ('Guidance from a fire that fails after the line was marked ' + [guid]::NewGuid().ToString('N')) -NotRecordedKey 'nr-dispatcher-failed'
        Assert-True ($r.StdErr -match 'dispatcher fail-open') 'dispatcher failure: the fire took the fail-open exit'
        $restored5 = @(if (Test-Path -LiteralPath $drops5) { [IO.File]::ReadAllLines($drops5) | Where-Object { $_ -match 'not-recorded-undelivered' -and $_ -match '"nr-dispatcher-failed"' } }).Count
        Assert-True ($restored5 -eq 1) 'dispatcher failure: the line the human did not get is put back'
    }
    finally {
        if ($IsWindows) { [IO.File]::SetAttributes($state5, [IO.FileAttributes]::Normal) } else { & chmod 644 $state5 }
        Remove-Item -LiteralPath $p5 -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host '--- integrity stores hold hashes only (FR-008) ---'
    $storeText = Get-AllStoreText $root
    foreach ($reason in $reasonA, $reasonB, $reasonC, $reasonL, $reasonG, $reasonH2, $reasonH3, $reasonH4) {
        Assert-True (-not $storeText.Contains($reason)) ("no reason text is stored: '{0}...'" -f $reason.Substring(0, 26))
    }
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}

if ($script:failCount -gt 0) { Write-Host "hook-output-journal: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'hook-output-journal: all passed' -ForegroundColor Green

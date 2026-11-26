# Feature 203 iteration 002 (the maintainer's "Fix codex", 2026-11-26 about 02:57 local; the reviewer session's ruling: the
# guard alone, the cause to the hand-back): A HOOK THAT SAYS A VERDICT WAS CAPTURED HAS RECORDED ONE.
#
# Measured on 203's engine in a scratch copy of this project (2026-11-26 01:13 local), Codex only: an assistant message holds a
# bare review-signoff marker, the human types the approval while no crossing waits (refused, correctly), the crossing opens,
# and the human's next, ordinary message makes the prompt hook print "Verdict captured: approved for review-signoff ... begins
# in this turn" while nothing was recorded. The marker reader read the earlier phrase from the Codex transcript; a Codex
# transcript line carries no record id and no session, so the entry took the act identity of another session's Claude
# reservation with the same text (the maintainer's iteration-001 sign-off); that identity was already a recorded verdict, so
# the writer handed back that old verdict as if it had written one, and the capture said "authorized" on the writer's silence.
# It then registered the newest verdict's turn on the ledger as minted by Codex.
#
# This suite builds that project shape - an earlier cycle's verdict whose Claude reservation has the same text - and runs the
# deployed hook commands of each host (the real deployer, a redirected home, the recorded payloads) through the part-D steps.
# The red case asserts the line and the ledger; the controls beside it pin what must not change: the normal capture on Codex,
# Claude and Copilot records and says so, a phrase with nothing waiting is refused, and a second bare phrase after a recorded
# verdict answers "already approved" and records nothing.
[CmdletBinding()]
param([switch]$KeepFixtures)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'tests\support\cited-typed-turn.ps1')
$payloads = Join-Path $repoRoot 'tests\fixtures\hook-payloads'
$deployer = Join-Path $repoRoot 'scripts\internal\deploy-refocus-hooks.ps1'
$script:failCount = 0
$script:hookRun = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

# The base folder is this suite's own, under the temp folder, and is the only thing it removes.
$base = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ('codex-line-' + [guid]::NewGuid().ToString('N').Substring(0, 8))))
$phrase = 'approved for review-signoff'
$utf8 = [Text.UTF8Encoding]::new($false)

function New-CaptureFixture {
    # A project in its second cycle: iteration 001 was signed off in an earlier Claude session (that session's prompt-hook
    # reservation of the phrase is on the ledger with its prompt event), iteration 002's before-implement is authorized and
    # implementation runs; review-signoff opens when the crew syncs it. Returns the project, its home, the head and the two
    # Claude turns in the history: the earlier sign-off and the newest verdict.
    param([Parameter(Mandatory)][string]$Name)
    $proj = Join-Path $base $Name
    $userHome = Join-Path $base ($Name + '-home')
    $feature = Join-Path $proj 'specs\046-test'
    $iteration = Join-Path $feature 'iterations\002'
    New-Item -ItemType Directory -Force -Path (Join-Path $proj '.specrew\authority'), (Join-Path $proj '.specify\extensions'), (Join-Path $iteration 'quality'), $userHome | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit') -Destination (Join-Path $proj '.specify\extensions\specrew-speckit') -Recurse -Force
    [IO.File]::WriteAllText((Join-Path $feature 'spec.md'), "# Feature Specification: Test`n`nBody.`n", $utf8)
    foreach ($rel in @('plan.md', 'tasks.md', 'state.md', 'review.md', 'quality\hardening-gate.md')) {
        [IO.File]::WriteAllText((Join-Path $iteration $rel), ("# {0}`n`n**Status**: fixture`n" -f $rel), $utf8)
    }
    [IO.File]::WriteAllText((Join-Path $proj '.gitignore'), ".specrew/`n.claude/`n", $utf8)
    & git -C $proj init -q -b main
    & git -C $proj config user.email 't@t'
    & git -C $proj config user.name 't'
    & git -C $proj add -A
    & git -C $proj commit -q -m fixture
    $head = ([string](& git -C $proj rev-parse HEAD)).Trim()
    # The two Claude turns: iteration 001's sign-off, and the newest verdict (iteration 002's before-implement).
    $oldTurn = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'claude'; message_id = 'prompt-old-signoff'; text = $phrase })).Identity
    $newestTurn = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'claude'; message_id = 'prompt-newest-before-implement'; text = 'approved for before-implement' })).Identity
    $entry = {
        param($From, $To, $Text, $At, $Turn)
        $e = [ordered]@{ from_boundary = $From; to_boundary = $To; verdict_text = $Text; authorizing_human = 'unattributed'; recorded_at = $At
            auth_commit_hash = $head; evidence_source = 'hook-captured-from-transcript'; kind = 'standard'; out_of_band = $false; feature_ref = '046-test' }
        if ($Turn) { $e['turn_identity'] = $Turn }
        $e
    }
    $history = @(
        (& $entry 'plan' 'tasks' 'approved for tasks' '2026-11-01T10:00:00Z' $null)
        (& $entry 'tasks' 'before-implement' 'approved for before-implement' '2026-11-01T11:00:00Z' $null)
        (& $entry 'before-implement' 'review-signoff' $phrase '2026-11-02T10:00:00Z' $oldTurn)
        (& $entry 'review-signoff' 'retro' 'approved for retro' '2026-11-02T11:00:00Z' $null)
        (& $entry 'retro' 'iteration-closeout' 'approved for iteration-closeout' '2026-11-02T12:00:00Z' $null)
        (& $entry 'iteration-closeout' 'plan' 'approved for plan' '2026-11-03T10:00:00Z' $null)
        (& $entry 'plan' 'tasks' 'approved for tasks' '2026-11-03T11:00:00Z' $null)
        (& $entry 'tasks' 'before-implement' 'approved for before-implement' '2026-11-03T12:00:00Z' $newestTurn)
    )
    $ctx = [ordered]@{
        schema               = 'v2'
        session_state        = [ordered]@{ active = $true; boundary_type = 'before-implement'; feature_ref = '046-test'; feature_path = $feature; iteration_number = '002'; auth_commit_hash = $head; recorded_at = '2026-11-03T12:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'before-implement'; pending_next_boundary = $null; verdict_history = $history; bypass_history = @() }
    }
    [IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), $utf8)
    # The earlier session's prompt-hook reservation of that verdict, as Claude's prompt hook writes it (with its prompt event).
    $row = [ordered]@{ schema_version = '1.0'; fact_type = 'typed-turn-exhausted'; turn_id = $oldTurn; content_hash = (Get-SpecrewHumanAuthorityHash -Text $phrase)
        host_kind = 'claude'; source_event = 'UserPromptSubmit'; minted = ''; session_id = 'earlier-claude-session'; identity = 'typed-act'
        observed_at = '2026-11-02T09:59:58.0000000Z'; turn_origin = 'typed-user'; prompt_event = ([guid]::NewGuid().ToString('N'))
        transcript_path = (Join-Path $base 'earlier-claude-session.jsonl'); message_id = 'prompt-old-signoff' }
    [IO.File]::WriteAllText((Join-Path $proj '.specrew\authority\exhausted-turns.jsonl'), (($row | ConvertTo-Json -Compress) + "`n"), $utf8)
    return [pscustomobject]@{ Root = $proj; Home = $userHome; Head = $head; OldTurn = $oldTurn; NewestTurn = $newestTurn }
}

function Get-DeployedCommand {
    # The command the real deployer wrote for this host and event.
    param([Parameter(Mandatory)]$Fixture, [Parameter(Mandatory)][ValidateSet('codex', 'claude', 'copilot')][string]$HostKind, [Parameter(Mandatory)][string]$Event)
    $log = Join-Path $base ('deploy-{0}-{1}.log' -f (Split-Path -Leaf $Fixture.Root), $HostKind)
    if (-not (Test-Path -LiteralPath $log)) {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $deployer -ProjectPath $Fixture.Root -HostKind $HostKind -UserHomeOverride $Fixture.Home *> $log
        if ($LASTEXITCODE -ne 0) { throw ('the real deployer failed for {0}: {1}' -f $HostKind, ((Get-Content -LiteralPath $log -Raw) -replace '\s+', ' ')) }
    }
    switch ($HostKind) {
        'codex' { return [string]((Get-Content -LiteralPath (Join-Path $Fixture.Home '.codex\hooks.json') -Raw | ConvertFrom-Json).hooks.$Event[0].hooks[0].command) }
        'claude' { return [string]((Get-Content -LiteralPath (Join-Path $Fixture.Root '.claude\settings.local.json') -Raw | ConvertFrom-Json).hooks.$Event[0].hooks[0].command) }
        'copilot' { return [string]((Get-Content -LiteralPath (Join-Path $Fixture.Home '.copilot\hooks\specrew-refocus.json') -Raw | ConvertFrom-Json).hooks.$Event[0].powershell) }
    }
}

function Invoke-DeployedHook {
    # Runs the deployed command with the payload on stdin, from the project, with the redirected home. The variables a
    # surrounding session would pass on (an agent running this suite) are removed, so the hook resolves this project only.
    param([Parameter(Mandatory)]$Fixture, [Parameter(Mandatory)][string]$HostKind, [Parameter(Mandatory)][string]$Event, [Parameter(Mandatory)]$Payload)
    $command = Get-DeployedCommand -Fixture $Fixture -HostKind $HostKind -Event $Event
    $tokens = [System.Collections.Generic.List[string]]::new()
    foreach ($m in [regex]::Matches($command, '"((?:[^"\\]|\\.)*)"|(\S+)')) { if ($m.Groups[1].Success) { $tokens.Add($m.Groups[1].Value.Replace('\"', '"')) } else { $tokens.Add($m.Groups[2].Value) } }
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $tokens[0]
    foreach ($a in $tokens[1..($tokens.Count - 1)]) { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $Fixture.Root
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    foreach ($inherited in @('CLAUDE_PROJECT_DIR', 'CURSOR_PROJECT_DIR', 'CLAUDECODE', 'CLAUDE_CODE_SESSION_ID', 'CLAUDE_CODE_ENTRYPOINT', 'SPECREW_REFOCUS_DISABLE')) { [void]$psi.Environment.Remove($inherited) }
    if ($HostKind -eq 'claude') { $psi.Environment['CLAUDE_PROJECT_DIR'] = $Fixture.Root }
    $psi.Environment['SPECREW_MODULE_PATH'] = $repoRoot
    $psi.Environment['SPECREW_USER_HOME_OVERRIDE'] = $Fixture.Home
    $bytes = $utf8.GetBytes(($Payload | ConvertTo-Json -Compress -Depth 6))
    $proc = [System.Diagnostics.Process]::Start($psi)
    $outTask = $proc.StandardOutput.ReadToEndAsync(); $errTask = $proc.StandardError.ReadToEndAsync()
    $proc.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length); $proc.StandardInput.Close()
    if (-not $proc.WaitForExit(180000)) { $proc.Kill($true); throw ('the deployed {0} {1} hook timed out' -f $HostKind, $Event) }
    $result = [pscustomobject]@{ Exit = $proc.ExitCode; Out = [string]$outTask.Result; Err = [string]$errTask.Result }
    # Each run's output, beside the fixtures, for a red run kept with -KeepFixtures.
    $script:hookRun++
    [IO.File]::WriteAllText((Join-Path $base ('hook-{0:d2}-{1}-{2}-{3}.txt' -f $script:hookRun, (Split-Path -Leaf $Fixture.Root), $HostKind, $Event)), ("exit={0}`n--- out`n{1}`n--- err`n{2}" -f $result.Exit, $result.Out, $result.Err), $utf8)
    return $result
}

function Get-History { param($Fixture) @((Get-Content -LiteralPath (Join-Path $Fixture.Root '.specrew\start-context.json') -Raw | ConvertFrom-Json -Depth 20).boundary_enforcement.verdict_history) }
function Get-Enforcement { param($Fixture) (Get-Content -LiteralPath (Join-Path $Fixture.Root '.specrew\start-context.json') -Raw | ConvertFrom-Json -Depth 20).boundary_enforcement }
function Get-LedgerRows { param($Fixture) @(Get-Content -LiteralPath (Join-Path $Fixture.Root '.specrew\authority\exhausted-turns.jsonl') | Where-Object { $_ } | ForEach-Object { $_ | ConvertFrom-Json }) }
function Get-MintedVerdictRows {
    # The ledger rows after the first $Skip that say this host minted a boundary verdict.
    param($Fixture, [int]$Skip, [string]$HostKind)
    @(Get-LedgerRows -Fixture $Fixture | Select-Object -Skip $Skip | Where-Object { [string]$_.host_kind -eq $HostKind -and [string]$_.minted -match 'boundary-verdict' })
}

function Open-Crossing {
    # The crossing writer the sign-off sync calls (before-implement -> review-signoff), in this repository's engine.
    param($Fixture)
    $cmd = "`$ErrorActionPreference='Stop'; . '$repoRoot\extensions\specrew-speckit\scripts\shared-governance.ps1'; Get-ChildItem '$repoRoot\scripts\internal\bootstrap\*.ps1' | ForEach-Object { . `$_.FullName }; `$ErrorActionPreference='Stop'; Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot '$($Fixture.Root)' -WorkingBoundary review-signoff -BoundaryCommitHash '$($Fixture.Head)' -RecordedAt '$([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))' -OpenNextCrossingWhenBoundaryAuthorized | Out-Null"
    $writerOut = & pwsh -NoProfile -NonInteractive -Command $cmd 2>&1
    $pending = (Get-Enforcement -Fixture $Fixture).pending_crossing
    if ($null -eq $pending -or [string]$pending.to_boundary -ne 'review-signoff') { throw ('the review-signoff crossing did not open in the fixture: {0}' -f ((@($writerOut) -join ' ') -replace '\s+', ' ')) }
    return [string]$pending.crossing_id
}

# --- Each host's transcript, in the shape the host writes it --------------------------------------
function New-Conversation {
    param([Parameter(Mandatory)][ValidateSet('codex', 'claude', 'copilot')][string]$HostKind, [Parameter(Mandatory)]$Fixture)
    $sid = [guid]::NewGuid().ToString()
    $tx = Join-Path $base ('{0}-{1}-{2}.jsonl' -f (Split-Path -Leaf $Fixture.Root), $HostKind, $sid)
    [IO.File]::WriteAllText($tx, '', $utf8)
    $c = [pscustomobject]@{ HostKind = $HostKind; Fixture = $Fixture; Session = $sid; Transcript = $tx; Turn = '' }
    if ($HostKind -eq 'codex') { Add-Line -Conversation $c -Object ([ordered]@{ timestamp = (Get-Iso); type = 'session_meta'; payload = [ordered]@{ id = $sid; cwd = $Fixture.Root } }) }
    return $c
}
function Get-Iso { [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ') }
function Add-Line { param($Conversation, $Object) [IO.File]::AppendAllText($Conversation.Transcript, (($Object | ConvertTo-Json -Compress -Depth 10) + "`n"), $utf8) }
function Add-Message {
    param($Conversation, [ValidateSet('user', 'assistant')][string]$Role, [string]$Text)
    switch ($Conversation.HostKind) {
        'codex' {
            if ($Role -eq 'user') { Add-Line -Conversation $Conversation -Object ([ordered]@{ timestamp = (Get-Iso); type = 'turn_context'; payload = [ordered]@{ turn_id = $Conversation.Turn; cwd = $Conversation.Fixture.Root } }) }
            Add-Line -Conversation $Conversation -Object ([ordered]@{ timestamp = (Get-Iso); type = 'response_item'; payload = [ordered]@{ type = 'message'; role = $Role; content = @([ordered]@{ type = $(if ($Role -eq 'user') { 'input_text' } else { 'output_text' }); text = $Text }) } })
        }
        'claude' {
            if ($Role -eq 'user') { Add-Line -Conversation $Conversation -Object ([ordered]@{ type = 'user'; uuid = [guid]::NewGuid().ToString(); promptId = $Conversation.Turn; sessionId = $Conversation.Session; timestamp = (Get-Iso); origin = [ordered]@{ kind = 'human' }; turnOrigin = 'human'; promptSource = 'typed'; message = [ordered]@{ role = 'user'; content = $Text } }) }
            else { Add-Line -Conversation $Conversation -Object ([ordered]@{ type = 'assistant'; uuid = [guid]::NewGuid().ToString(); sessionId = $Conversation.Session; timestamp = (Get-Iso); message = [ordered]@{ role = 'assistant'; content = @([ordered]@{ type = 'text'; text = $Text }) } }) }
        }
        'copilot' { Add-Line -Conversation $Conversation -Object ([ordered]@{ type = "$Role.message"; data = [ordered]@{ content = $Text; messageId = [guid]::NewGuid().ToString() }; id = [guid]::NewGuid().ToString(); timestamp = (Get-Iso) }) }
    }
}
function Invoke-Prompt {
    # The prompt hook fires before the host writes the message; then the host writes it.
    param($Conversation, [string]$Text)
    $Conversation.Turn = [guid]::NewGuid().ToString()
    $f = $Conversation.Fixture
    $payload = switch ($Conversation.HostKind) {
        'codex' { $p = Get-Content -LiteralPath (Join-Path $payloads 'codex\tui-userpromptsubmit-typed.json') -Raw | ConvertFrom-Json; $p.session_id = $Conversation.Session; $p.turn_id = $Conversation.Turn; $p.transcript_path = $Conversation.Transcript; $p.cwd = $f.Root; $p.prompt = $Text; $p }
        'claude' { $p = Get-Content -LiteralPath (Join-Path $payloads 'claude\tui-userpromptsubmit-typed.json') -Raw | ConvertFrom-Json; $p.session_id = $Conversation.Session; $p.prompt_id = $Conversation.Turn; $p.transcript_path = $Conversation.Transcript; $p.cwd = $f.Root; $p.prompt = $Text; $p }
        'copilot' { $p = Get-Content -LiteralPath (Join-Path $payloads 'copilot\tui-userpromptsubmitted-typed.json') -Raw | ConvertFrom-Json; $p.sessionId = $Conversation.Session; $p.timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $p.cwd = $f.Root; $p.prompt = $Text; $p }
    }
    $event = if ($Conversation.HostKind -eq 'copilot') { 'userPromptSubmitted' } else { 'UserPromptSubmit' }
    $r = Invoke-DeployedHook -Fixture $f -HostKind $Conversation.HostKind -Event $event -Payload $payload
    Add-Message -Conversation $Conversation -Role user -Text $Text
    return $r
}
function Invoke-Stop {
    param($Conversation, [string]$Reply)
    Add-Message -Conversation $Conversation -Role assistant -Text $Reply
    $f = $Conversation.Fixture
    $payload = switch ($Conversation.HostKind) {
        'codex' { $p = Get-Content -LiteralPath (Join-Path $payloads 'codex\tui-stop.json') -Raw | ConvertFrom-Json; $p.session_id = $Conversation.Session; $p.turn_id = $Conversation.Turn; $p.transcript_path = $Conversation.Transcript; $p.cwd = $f.Root; $p.last_assistant_message = $Reply; $p }
        'claude' { $p = Get-Content -LiteralPath (Join-Path $payloads 'claude\tui-stop.json') -Raw | ConvertFrom-Json; $p.session_id = $Conversation.Session; $p.prompt_id = $Conversation.Turn; $p.transcript_path = $Conversation.Transcript; $p.cwd = $f.Root; $p.last_assistant_message = $Reply; $p }
        'copilot' { $p = Get-Content -LiteralPath (Join-Path $payloads 'copilot\tui-agentstop.json') -Raw | ConvertFrom-Json; $p.sessionId = $Conversation.Session; $p.timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $p.cwd = $f.Root; $p.transcriptPath = $Conversation.Transcript; $p }
    }
    $event = if ($Conversation.HostKind -eq 'copilot') { 'agentStop' } else { 'Stop' }
    return (Invoke-DeployedHook -Fixture $f -HostKind $Conversation.HostKind -Event $event -Payload $payload)
}

$captured = 'Verdict captured: approved for review-signoff'
$alreadyApproved = "'review-signoff' is already approved, so nothing was recorded"
try {
    # --- THE RED CASE: Codex, the part-D shape ---------------------------------------------------------------------------
    Write-Host 'Case 1 (Codex): an ordinary message after a refused early phrase and a bare marker is never told a verdict was captured'
    $f1 = New-CaptureFixture -Name 'codex-red'
    $c1 = New-Conversation -HostKind codex -Fixture $f1
    $rows0 = @(Get-LedgerRows -Fixture $f1).Count
    $history0 = @(Get-History -Fixture $f1).Count
    Add-Message -Conversation $c1 -Role assistant -Text 'An example of a marker: <!-- SPECREW-VERDICT-BOUNDARY: before-implement -> review-signoff -->'
    $p1 = Invoke-Prompt -Conversation $c1 -Text $phrase
    Assert-True ($p1.Exit -eq 0 -and $p1.Out -match 'NO crossing is pending' -and @(Get-History -Fixture $f1).Count -eq $history0) 'control: the phrase typed while nothing waits is refused at the prompt and records nothing'
    $s1 = Invoke-Stop -Conversation $c1 -Reply 'Nothing is waiting.'
    Assert-True ($s1.Exit -eq 0 -and @(Get-History -Fixture $f1).Count -eq $history0) 'control: the turn end of that turn records nothing'
    $minted1 = @(Get-MintedVerdictRows -Fixture $f1 -Skip $rows0 -HostKind codex)
    Assert-True ($minted1.Count -eq 0) ('nothing recorded, so nothing is registered as a verdict Codex minted at that turn end (got {0}: {1})' -f $minted1.Count, ((@($minted1 | ForEach-Object { '{0} at {1}' -f ([string]$_.turn_id).Substring(0, 8), $_.source_event })) -join ', '))
    $null = Open-Crossing -Fixture $f1
    $rows1 = @(Get-LedgerRows -Fixture $f1).Count
    $p3 = Invoke-Prompt -Conversation $c1 -Text 'Thank you, carry on.'
    $history3 = @(Get-History -Fixture $f1)
    Assert-True ($p3.Exit -eq 0) 'the deployed Codex prompt hook exits 0 on the ordinary message'
    Assert-True (-not ($p3.Out.Contains($captured) -and $history3.Count -eq $history0)) ('the prompt hook does not say a verdict was captured when none was recorded (history {0} -> {1}; said captured: {2})' -f $history0, $history3.Count, $p3.Out.Contains($captured))
    $minted3 = @(Get-MintedVerdictRows -Fixture $f1 -Skip $rows1 -HostKind codex)
    $foreign3 = @($minted3 | Where-Object { [string]$_.turn_id -in @($f1.OldTurn, $f1.NewestTurn) })
    Assert-True ($foreign3.Count -eq 0) ('no Claude turn of the earlier cycle is registered as a verdict Codex minted (got {0})' -f $foreign3.Count)
    $s3 = Invoke-Stop -Conversation $c1 -Reply 'Fine.'
    $history3s = @(Get-History -Fixture $f1)
    $minted3s = @(Get-MintedVerdictRows -Fixture $f1 -Skip $rows1 -HostKind codex | Where-Object { [string]$_.turn_id -in @($f1.OldTurn, $f1.NewestTurn) })
    Assert-True ($s3.Exit -eq 0 -and $minted3s.Count -eq 0) ('after the turn end too, no earlier Claude turn is registered as a verdict Codex minted (got {0})' -f $minted3s.Count)
    $newest3 = if ($history3s.Count -gt 0) { $history3s[-1] } else { $null }
    Assert-True ($history3s.Count -eq $history0 -or ([string]$newest3.to_boundary -eq 'review-signoff' -and [string]$newest3.turn_identity -notin @($f1.OldTurn, $f1.NewestTurn))) 'whatever the turn end did, the record holds no verdict under another session''s turn'

    # --- CONTROLS: the normal capture on each host, and the second bare phrase ------------------------------------------
    foreach ($hostKind in @('codex', 'claude', 'copilot')) {
        Write-Host ("Case 2 ({0}): the normal capture records and says so; the bare phrase after it answers already approved" -f $hostKind)
        $f2 = New-CaptureFixture -Name ($hostKind + '-control')
        $c2 = New-Conversation -HostKind $hostKind -Fixture $f2
        $crossing = Open-Crossing -Fixture $f2
        $history0 = @(Get-History -Fixture $f2).Count
        Add-Message -Conversation $c2 -Role assistant -Text ("The packet for review-signoff.`n`n<!-- SPECREW-VERDICT-BOUNDARY: before-implement -> review-signoff @ {0} -->" -f $crossing)
        $p = Invoke-Prompt -Conversation $c2 -Text $phrase
        $h = @(Get-History -Fixture $f2)
        Assert-True ($p.Exit -eq 0 -and $h.Count -eq ($history0 + 1) -and [string]$h[-1].to_boundary -eq 'review-signoff' -and [string]$h[-1].turn_identity -notin @('', $f2.OldTurn, $f2.NewestTurn)) ("{0}: the typed verdict is recorded once, under its own turn (history {1} -> {2})" -f $hostKind, $history0, $h.Count)
        Assert-True ($p.Out.Contains($captured)) ("{0}: the prompt hook says the verdict was captured" -f $hostKind)
        $s = Invoke-Stop -Conversation $c2 -Reply 'Recorded. The retro begins.'
        Assert-True ($s.Exit -eq 0 -and @(Get-History -Fixture $f2).Count -eq ($history0 + 1)) ("{0}: the turn end records it no second time" -f $hostKind)
        $again = Invoke-Prompt -Conversation $c2 -Text $phrase
        Assert-True ($again.Exit -eq 0 -and $again.Out.Contains($alreadyApproved) -and -not $again.Out.Contains($captured) -and @(Get-History -Fixture $f2).Count -eq ($history0 + 1)) ("{0}: the bare phrase after the recorded verdict answers already approved and records nothing" -f $hostKind)
        $null = Invoke-Stop -Conversation $c2 -Reply 'It is already approved.'
        Assert-True (@(Get-History -Fixture $f2).Count -eq ($history0 + 1)) ("{0}: and its turn end records nothing" -f $hostKind)
    }
}
finally {
    if ($KeepFixtures) { Write-Host ('fixtures kept: {0}' -f $base) }
    elseif ($base.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()), [StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $base) -like 'codex-line-*') {
        Remove-Item -LiteralPath $base -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($script:failCount -gt 0) { Write-Host "codex-capture-line-agrees-with-record: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'codex-capture-line-agrees-with-record: all passed' -ForegroundColor Green
exit 0

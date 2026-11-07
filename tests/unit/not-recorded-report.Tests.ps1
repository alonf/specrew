# Feature 203 T006 (FR-026, FR-027; B4F-151): A TYPED APPROVAL THAT RECORDS NOTHING SAYS SO, IN THE SAME TURN, WHERE THE HUMAN READS.
#
# B4F-151: a message whose approval form could not be read recorded nothing and said nothing. The classifier already
# names each reason a standalone phrase records nothing (Resolve-SpecrewTypedAct's Report flag), but the prompt hook read
# that flag nowhere: a stop answer with no review stop waiting, a `defer` with no destination and a phrase no writer
# takes were all dropped without a word. And what was said went to the model only (additionalContext): Claude shows the
# human a hook's `systemMessage`, not its context (research.md R3), and no adapter emitted one.
#
# Now every reason but `already-recorded` and `not-standalone` (which has its own one-line refusal) is reported with its
# own words at the prompt event that saw it; the report checks the store as it speaks and stays silent for a message
# recorded since; and the handover provider marks each human-facing line, which the dispatcher shows as `systemMessage`
# on a host whose binding names that field and turns into the turn end's one stop on a host that has none (FR-027).
#
# Mutations that turn this file red: drop the router's report (cases 1 to 4); drop a reason's own words (cases 1 to 4);
# drop the store check (case 5); report `already-recorded` (case 6); stop marking the visible lines (case 7); drop the
# dispatcher's visible field (case 8); keep the line as context only on a host with no visible field (case 9); block more
# than once for one line (case 9); tell a boundary already approved to send it again (case 10); write the old confirmation or
# accept the new one without its turn (case 11); say "the reason you gave" (case 11); throw a launcher refusal (case 12).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
Get-ChildItem (Join-Path $repoRoot 'scripts\internal\bootstrap\*.ps1') | ForEach-Object { . $_.FullName }
$provider = Join-Path $repoRoot 'scripts\internal\specrew-handover-provider.ps1'
$dispatcherSource = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-hook-dispatcher.ps1'
$savedModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot
$script:failCount = 0
$script:roots = @()
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-ReportFixture {
    # A governed project at tasks, nothing pending.
    $root = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ("nrr-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    $script:roots += $root
    $feature = Join-Path $root 'specs\001-feat'
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew\runtime'), (Join-Path $feature 'iterations\001') | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    & git -C $root init -q -b main
    & git -C $root config user.email 't@t'
    & git -C $root config user.name 't'
    & git -C $root add -A
    & git -C $root commit -q -m fixture
    $ctx = [ordered]@{
        schema = 'v2'; feature_path = $feature
        session_state = [ordered]@{ active = $true; boundary_type = 'tasks'; feature_ref = '001-feat'; host = 'claude'; iteration_number = '001'; recorded_at = '2026-08-29T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [IO.File]::WriteAllText((Join-Path $root '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
    return $root
}
function Send-Prompt {
    # One prompt event, in this process, so a test can make a reader fail. Returns the handover's result.
    param([string]$Root, [string]$Text, [string]$Session = 'nrr-session', [string]$HostKind = 'claude')
    return (Update-SpecrewRollingHandover -ProjectRoot $Root -HostKind $HostKind -Source 'UserPromptSubmit' -LastUserMessage $Text -TurnOrigin 'typed-user' `
            -SessionId $Session -MessageId ('prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 12)) -MessageIdentity 'declared' -NowUtc ([DateTimeOffset]::UtcNow.ToString('o')))
}
function Get-Visible { param($Result) if ($null -ne $Result -and $Result.PSObject.Properties['visible']) { return [string]$Result.visible } return '' }
function Test-Says { param([string]$Line, [string]$Phrase, [string]$Because) return ($Line -match '(?i)not recorded' -and $Line.Contains("'$Phrase'") -and $Line -match $Because) }
function Get-DropRows { param([string]$Root)
    $j = Join-Path $Root '.specrew\runtime\authority-capture-drops.jsonl'
    if (-not (Test-Path -LiteralPath $j)) { return @() }
    return @(Get-Content -LiteralPath $j | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { [string]$_.event -ceq 'authority-phrase-not-recorded' })
}

$originalForm = ${function:Resolve-SpecrewApprovalForm}
$originalPending = ${function:Get-SpecrewTypedActPendingState}
try {
    Write-Host 'Case 1 (B4F-151): a message whose approval form cannot be read records nothing and says so at its own prompt event'
    $r1 = New-ReportFixture
    ${function:Resolve-SpecrewApprovalForm} = { param([string]$Text, [string]$HostKind) throw 'the form reader failed' }
    try { $o1 = Send-Prompt -Root $r1 -Text 'approved for review round' } finally { ${function:Resolve-SpecrewApprovalForm} = $originalForm }
    $v1 = Get-Visible $o1
    Assert-True (Test-Says $v1 'approved for review round' 'could not read') "the human is told it could not be read (got '$v1')"
    Assert-True (@(Get-DropRows $r1 | Where-Object { [string]$_.reason -ceq 'form-unreadable' }).Count -eq 1) 'and the journal row names the reason'

    Write-Host 'Case 2: a stop answer with no review stop waiting records nothing and says what it looked for'
    $r2 = New-ReportFixture
    $v2 = Get-Visible (Send-Prompt -Root $r2 -Text 'drop finding F1')
    Assert-True (Test-Says $v2 'drop finding F1' 'no review stop is waiting') "it says no review stop waits (got '$v2')"

    Write-Host 'Case 3: `defer finding <id>` with no destination says the form to type'
    $r3 = New-ReportFixture
    ${function:Get-SpecrewTypedActPendingState} = { param([string]$ProjectRoot) [pscustomobject]@{ Crossing = $null; Pause = [pscustomobject]@{ Kind = 'b-dispute-or-defer'; Id = 'run-1' }; WorkshopQuestion = $null; PreBudgetReviewActs = $true } }
    try { $v3 = Get-Visible (Send-Prompt -Root $r3 -Text 'defer finding F1') } finally { ${function:Get-SpecrewTypedActPendingState} = $originalPending }
    Assert-True (Test-Says $v3 'defer finding F1' 'destination' -and $v3.Contains('defer finding F1 to <')) "it names the missing destination and the form (got '$v3')"

    Write-Host 'Case 4: an answer the review stop waits for but no writer records yet says so, never silence'
    $r4 = New-ReportFixture
    ${function:Get-SpecrewTypedActPendingState} = { param([string]$ProjectRoot) [pscustomobject]@{ Crossing = $null; Pause = [pscustomobject]@{ Kind = 'b-dispute-or-defer'; Id = 'run-1' }; WorkshopQuestion = $null; PreBudgetReviewActs = $true } }
    try { $v4 = Get-Visible (Send-Prompt -Root $r4 -Text 'drop finding F1') } finally { ${function:Get-SpecrewTypedActPendingState} = $originalPending }
    Assert-True (Test-Says $v4 'drop finding F1' 'cannot record') "it says this version cannot record that answer (got '$v4')"

    Write-Host 'Case 5: the report checks the store when it speaks: a message recorded since its report is not reported'
    $r5 = New-ReportFixture
    $shape5 = [pscustomobject]@{ Kind = 'review-round-approval'; Retype = 'approved for review round' }
    $null = Write-SpecrewAuthorityNotRecordedReport -ProjectRoot $r5 -Shape $shape5 -EntryKey 'turn-5' -HostKind claude -SessionId 'nrr-session' -Reason 'message-hook-did-not-record'
    $null = Register-SpecrewExhaustedTurn -ProjectRoot $r5 -TurnId 'turn-5' -HostKind claude -SourceEvent 'stop-transcript' -MintedWriters 'round-approval' -ContentHash 'h' -SessionId 'nrr-session' -Identity 'typed-act'
    $d5 = Get-SpecrewAuthorityNotRecordedDisclosure -ProjectRoot $r5 -HostKind claude -SessionId 'nrr-session'
    Assert-True ([string]::IsNullOrWhiteSpace([string]$d5)) "a recorded approval never gets the line (got '$d5')"

    Write-Host 'Case 6: an approval this message already recorded reports nothing'
    $r6 = New-ReportFixture
    $o6a = Send-Prompt -Root $r6 -Text 'approved for review round'
    $o6b = Send-Prompt -Root $r6 -Text 'approved for review round'
    Assert-True ([string]::IsNullOrWhiteSpace((Get-Visible $o6a)) -and [string]::IsNullOrWhiteSpace((Get-Visible $o6b))) "two recorded round approvals, no line (got '$(Get-Visible $o6a)' / '$(Get-Visible $o6b)')"

    Write-Host 'Case 7: the provider marks each human-facing line for the visible channel'
    $r7 = New-ReportFixture
    $out7 = (& pwsh -NoProfile -File $provider --project-root $r7 --host-kind claude --session-id 'nrr-session' --source-event UserPromptSubmit --last-user-message 'drop finding F1' `
            --turn-origin typed-user --message-identity declared --message-id 'prompt-7' 2>$null) -join "`n"
    Assert-True ($out7 -match '(?m)^<<<SPECREW-VISIBLE-LINE>>>.*drop finding F1') "a marked line (got '$out7')"

    # The dispatcher, with stub providers, as hook-output-journal runs it.
    function New-DispatcherProject {
        $root = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ('nrd-' + [guid]::NewGuid().ToString('N').Substring(0, 8))))
        $script:roots += $root
        $scripts = Join-Path $root '.specify\extensions\specrew-speckit\scripts'
        New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew\runtime'), $scripts | Out-Null
        Copy-Item -LiteralPath $dispatcherSource -Destination (Join-Path $scripts 'specrew-hook-dispatcher.ps1')
        [IO.File]::WriteAllText((Join-Path $scripts 'stub-inject.ps1'), "if (`$env:NRD_LINE) { Write-Output ('<<<SPECREW-VISIBLE-LINE>>>' + `$env:NRD_LINE) }`nWrite-Output 'context for the model'`nexit 0", [Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText((Join-Path $scripts 'stub-quiet.ps1'), "exit 0", [Text.UTF8Encoding]::new($false))
        $catalog = [ordered]@{ schema_version = '1'; providers = @(
                [ordered]@{ id = 'stub-inject'; kind = 'inject'; events = @('UserPromptSubmit'); order = 40; budget_share = 1.0; command = 'stub-inject.ps1' },
                [ordered]@{ id = 'stub-quiet'; kind = 'inject'; events = @('Stop', 'agentStop'); order = 40; budget_share = 1.0; command = 'stub-quiet.ps1' }) }
        [IO.File]::WriteAllText((Join-Path $root '.specify\extensions\specrew-speckit\refocus-scopes.json'), ($catalog | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
        return $root
    }
    function Invoke-Dispatcher {
        param([string]$Root, [string]$Event, [string]$HostKind, [string]$Payload, [string]$Line = '')
        $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
        foreach ($a in '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Root '.specify\extensions\specrew-speckit\scripts\specrew-hook-dispatcher.ps1'), '-Event', $Event, '-HostKind', $HostKind) { $psi.ArgumentList.Add($a) }
        $psi.WorkingDirectory = $Root; $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
        $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
        $psi.Environment['SPECREW_MODULE_PATH'] = $repoRoot
        if ($Line) { $psi.Environment['NRD_LINE'] = $Line } else { $psi.Environment.Remove('NRD_LINE') | Out-Null }
        foreach ($var in 'CLAUDE_PROJECT_DIR', 'COPILOT_PROJECT_DIR', 'CURSOR_PROJECT_DIR') { $psi.Environment[$var] = $Root }
        $p = [Diagnostics.Process]::Start($psi)
        $o = $p.StandardOutput.ReadToEndAsync(); $e = $p.StandardError.ReadToEndAsync()
        $p.StandardInput.Write($Payload); $p.StandardInput.Close()
        if (-not $p.WaitForExit(60000)) { $p.Kill($true); throw 'dispatcher timed out' }
        return [string]$o.Result
    }
    $line = "Specrew: your 'drop finding F1' was received but not recorded - no review stop is waiting for it."

    Write-Host 'Case 8: on Claude the marked line is the systemMessage the human sees, and the model still gets it as context'
    $r8 = New-DispatcherProject
    $o8 = Invoke-Dispatcher -Root $r8 -Event 'UserPromptSubmit' -HostKind 'claude' -Line $line -Payload '{"session_id":"nrd-s","prompt":"drop finding F1","prompt_id":"p8","hook_event_name":"UserPromptSubmit"}'
    $j8 = $null; try { $j8 = $o8 | ConvertFrom-Json } catch { $j8 = $null }
    $sys8 = if ($null -ne $j8 -and $j8.PSObject.Properties['systemMessage']) { [string]$j8.systemMessage } else { '' }
    $ctx8 = if ($null -ne $j8 -and $j8.PSObject.Properties['hookSpecificOutput']) { [string]$j8.hookSpecificOutput.additionalContext } else { '' }
    Assert-True ($sys8 -ceq $line) "systemMessage is the line (got '$o8')"
    Assert-True ($ctx8.Contains($line) -and $ctx8.Contains('context for the model') -and -not $ctx8.Contains('<<<SPECREW-VISIBLE-LINE>>>')) "and the context keeps it, without the marker (got '$ctx8')"

    Write-Host 'Case 9: on a host with no visible field the line is the turn end''s stop, once'
    $r9 = New-DispatcherProject
    $o9 = Invoke-Dispatcher -Root $r9 -Event 'UserPromptSubmit' -HostKind 'codex' -Line $line -Payload '{"session_id":"nrd-s","turn_id":"t9","prompt":"drop finding F1","hook_event_name":"UserPromptSubmit","permission_mode":"default","cwd":"x","model":"m","transcript_path":null}'
    Assert-True (-not $o9.Contains('systemMessage') -and $o9.Contains($line)) "the prompt event gives the model the line (got '$o9')"
    $s9a = Invoke-Dispatcher -Root $r9 -Event 'Stop' -HostKind 'codex' -Payload '{"session_id":"nrd-s","turn_id":"t9","hook_event_name":"Stop","stop_hook_active":false,"permission_mode":"default","cwd":"x","model":"m","transcript_path":null,"last_assistant_message":"done"}'
    $s9b = Invoke-Dispatcher -Root $r9 -Event 'Stop' -HostKind 'codex' -Payload '{"session_id":"nrd-s","turn_id":"t10","hook_event_name":"Stop","stop_hook_active":false,"permission_mode":"default","cwd":"x","model":"m","transcript_path":null,"last_assistant_message":"done"}'
    Assert-True ($s9a -match '"decision"\s*:\s*"block"' -and $s9a.Contains('drop finding F1')) "the turn end stops with the line (got '$s9a')"
    Assert-True ($s9b -notmatch '"decision"\s*:\s*"block"') "and only once (got '$s9b')"

    Write-Host 'Case 10 (DRIFT-039 a): a phrase for the boundary already approved is told so, never to send it again later'
    $r10 = New-ReportFixture
    $v10 = Get-Visible (Send-Prompt -Root $r10 -Text 'approved for tasks')
    Assert-True ($v10 -match 'already approved' -and $v10 -notmatch '(?i)send the phrase again|when the .* crossing is presented') "already approved, nothing needed (got '$v10')"

    Write-Host 'Case 11 (DRIFT-039 b, DRIFT-041 c): a design decision names its evidence, and the rationale is not called the human''s'
    $store = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\design-decision-store.ps1'
    . $store
    $base = [ordered]@{ question = 'q'; options = @([pscustomobject]@{ id = '1'; summary = 'a' }, [pscustomobject]@{ id = '2'; summary = 'b' }); chosen = '1'; rationale = 'r'
        confirmation_scope = 'design-decision'; human_turn = 'design decision: option 1'; recorded_at = '2026-11-07T00:00:00Z' }
    function New-Decision { param([hashtable]$Extra) $h = [ordered]@{}; foreach ($k in $base.Keys) { $h[$k] = $base[$k] }; foreach ($k in $Extra.Keys) { $h[$k] = $Extra[$k] }; return [pscustomobject]$h }
    $verified = New-Decision @{ confirmation = 'typed-turn-verified'; turn_identity = 'turn-1' }
    $unverified = New-Decision @{ confirmation = 'typed-turn-verified' }
    $legacy = New-Decision @{ confirmation = 'crew-declared-human-reply' }
    Assert-True ([bool](Test-SpecrewDesignDecisionRecord -Record $verified).valid -and -not [bool](Test-SpecrewDesignDecisionRecord -Record $unverified).valid) 'typed-turn-verified is valid only with the turn it rests on'
    Assert-True ([bool](Test-SpecrewDesignDecisionRecord -Record $legacy).valid) 'a record written before T004 stays valid'
    $writer = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\record-design-decision.ps1') -Raw
    Assert-True ($writer -notmatch 'reason you gave' -and $writer -match 'confirmation\s*=\s*\$script:SpecrewDesignDecisionConfirmation') 'the writer records the new value and never calls the rationale the human''s'

    Write-Host 'Case 12 (DRIFT-018): the launcher''s refusals are plain text, not a thrown error'
    $deploy = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\internal\deploy-refocus-hooks.ps1') -Raw
    $pinText = [regex]::Match($deploy, '(?s)function Get-LiveEnginePinLauncherText \{.*?\n\}').Value
    $launcher = [regex]::Match($deploy, '(?s)function Install-ProjectHookLauncher \{.*?\n\}').Value
    Assert-True ($pinText -match '__REFUSAL__' -and $pinText -notmatch 'throw ''__' -and $pinText -match '\[Console\]::Error\.WriteLine\(''__REFUSAL__''\); exit 1') 'the pin refusals write plain text and exit 1'
    Assert-True ($launcher -match 'could not find its hook dispatcher' -and $launcher -notmatch 'throw "Specrew dispatcher not found') 'the project launcher''s missing-dispatcher refusal too'
}
finally {
    ${function:Resolve-SpecrewApprovalForm} = $originalForm
    ${function:Get-SpecrewTypedActPendingState} = $originalPending
    $env:SPECREW_MODULE_PATH = $savedModulePath
    foreach ($r in $script:roots) { if (Test-Path -LiteralPath $r) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } }
}
Write-Host ''
if ($script:failCount -gt 0) { Write-Host "not-recorded-report: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'not-recorded-report: all pass' -ForegroundColor Green
exit 0

# Feature 203 iteration 001, T004 (FR-015, FR-016; maintainer's decision 2026-11-04, option 1): Cursor and Antigravity
# send no message id, and research R1 decided an identity only for Claude, Codex and Copilot. Their substitute is the
# prompt event's own position key from feature 202, on the prompt path only, as Copilot's stand-in is: the turn end
# records nothing on them and reports a message the prompt hook did not see.
#
# The substitute rests on an UNVERIFIED assumption, recorded in both bindings and in the plan: one prompt event per
# message. T001 probed only Claude, Codex and Copilot, and Cursor can also run Claude Code hooks, which is the shape
# that doubled every Copilot hook. The 202 key carries the time the hook ran, so a message whose prompt hook fires
# twice would be two keys and two acts. This suite pins that it is one act:
#
#   1. the bindings declare the position key, and the deployed hook hands the provider 'position-key' on the prompt
#      event and 'none' at the turn end;
#   2. one message whose prompt hook fires twice, at once or one after the other, records one act, not two, and
#      reports nothing as not recorded;
#   3. the same message through Cursor's hook and through the Claude Code hook Cursor may also run (labelled claude,
#      with no prompt_id) is still one act;
#   4. the human typing the same phrase again after the window is a second message.
#
# RED before the position key: both bindings declare nothing, the provider receives 'none', and an approval on these
# hosts records nothing (no identity, FR-015).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provider = Join-Path $repoRoot 'scripts\internal\specrew-handover-provider.ps1'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

. (Join-Path $repoRoot 'tests\host-probes\deployed-hook-harness.ps1')
. (Join-Path $repoRoot 'scripts\internal\bootstrap\HumanAuthorityStore.ps1')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ArgValue {
    param([string[]]$ArgList, [string]$Name)
    for ($i = 0; $i -lt $ArgList.Count - 1; $i++) { if ($ArgList[$i] -ceq $Name) { return $ArgList[$i + 1] } }
    return $null
}

function New-PositionKeyProject {
    # A project waiting on the plan -> tasks verdict, with the stage evidence that crossing needs.
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ('specrew-poskey-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
    $proj = Join-Path $tmp 'proj'
    New-Item -ItemType Directory -Force -Path (Join-Path $proj 'specs/001-feat/iterations/001/quality'), (Join-Path $proj '.specrew') | Out-Null
    Set-Content -LiteralPath (Join-Path $proj '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $proj 'specs/001-feat/spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $proj 'specs/001-feat/iterations/001/plan.md') -Value "# Iteration Plan: 001`n`n**Status**: planning" -Encoding UTF8
    git -C $proj init -q -b main 2>$null; git -C $proj config user.email 't@t' 2>$null; git -C $proj config user.name 't' 2>$null
    git -C $proj add -A 2>$null; git -C $proj commit -q -m init 2>$null
    git -C $proj checkout -q -b '001-feat' 2>$null
    $ctx = [ordered]@{
        schema               = 'v2'
        session_state        = [ordered]@{ active = $true; boundary_type = 'tasks'; feature_ref = '001-feat'; host = 'cursor'; iteration_number = '001'; recorded_at = '2026-01-01T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'plan'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [IO.File]::WriteAllText((Join-Path $proj '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
    $tx = Join-Path $tmp 'transcript.jsonl'
    $packet = @{ type = 'assistant'; message = @{ role = 'assistant'; content = @(@{ type = 'text'; text = "boundary packet. <!-- SPECREW-VERDICT-BOUNDARY: plan -> tasks --> What's your verdict?" }) } }
    [IO.File]::WriteAllText($tx, ($packet | ConvertTo-Json -Depth 8 -Compress), [Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Tmp = $tmp; Proj = $proj; Transcript = $tx }
}

function Get-PromptArgs {
    # The arguments the deployed prompt hook hands the handover provider on these hosts (part 1 pins them).
    param($Project, [string]$HostKind, [string]$Prompt, [string]$Identity = 'position-key', [string]$Session = 'conv-1')
    $sourceEvent = if ($HostKind -eq 'antigravity') { 'PreInvocation' } else { 'UserPromptSubmit' }
    return @('-NoProfile', '-File', $provider, '--project-root', $Project.Proj, '--host-kind', $HostKind, '--source-event', $sourceEvent,
        '--transcript-path', $Project.Transcript, '--last-user-message', $Prompt, '--turn-origin', 'typed-user',
        '--message-identity', $Identity, '--session-id', $Session)
}

function Invoke-PromptFires {
    # Each argument list as its own hook process; -Together starts them all before waiting for any, as two hook
    # registrations firing for one message do.
    param([object[]]$ArgLists, [switch]$Together)
    $outputs = @()
    if ($Together) {
        $procs = foreach ($argList in $ArgLists) {
            $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
            foreach ($a in $argList) { $psi.ArgumentList.Add([string]$a) }
            $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.CreateNoWindow = $true
            [Diagnostics.Process]::Start($psi)
        }
        foreach ($p in $procs) { $outputs += $p.StandardOutput.ReadToEnd(); [void]$p.StandardError.ReadToEnd(); $p.WaitForExit() }
    }
    else {
        foreach ($argList in $ArgLists) { $outputs += ((& pwsh @argList 2>$null) -join "`n") }
    }
    return $outputs
}

function Get-LedgerKeys {
    # The distinct keys this message was reserved under: a recorded act writes two lines under one key, the
    # reservation and then what it minted.
    param([object[]]$Entries)
    return @($Entries | ForEach-Object { [string]$_.turn_id } | Sort-Object -Unique)
}

function Get-LedgerEntries {
    param($Project, [string]$Text)
    $path = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $Project.Proj
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    $hash = Get-SpecrewHumanAuthorityHash -Text $Text.Trim()
    return @(Get-Content -LiteralPath $path | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.PSObject.Properties['content_hash'] -and [string]$_.content_hash -ceq $hash })
}

function Format-LedgerEntries {
    # One line per ledger entry for a failure message: key prefix, source event, identity, what it minted.
    param([object[]]$Entries)
    return (@($Entries | ForEach-Object { '{0}/{1}/{2}/{3}' -f ([string]$_.turn_id).Substring(0, 8), $_.source_event, $_.identity, $_.minted }) -join '; ')
}

function Get-TasksVerdicts {
    param($Project)
    $be = (Get-Content -LiteralPath (Join-Path $Project.Proj '.specrew/start-context.json') -Raw | ConvertFrom-Json -Depth 12).boundary_enforcement
    return @(@($be.verdict_history) | Where-Object { $null -ne $_ -and [string]$_.to_boundary -eq 'tasks' })
}

function Get-NotRecordedReports {
    param($Project)
    $path = Get-SpecrewAuthorityNotRecordedJournalPath -ProjectRoot $Project.Proj
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    return @(Get-Content -LiteralPath $path | Where-Object { $_.Trim() })
}

$cleanup = [System.Collections.Generic.List[string]]::new()
try {
    # === 1. The bindings declare the position key; the deployed hook hands it over on the prompt event only. ===
    $nativePrompt = @{ cursor = 'beforeSubmitPrompt'; antigravity = 'PreInvocation' }
    $nativeStop = @{ cursor = 'stop'; antigravity = 'Stop' }
    $promptPayload = @{
        cursor      = '{"conversation_id":"conv-1","hook_event_name":"beforeSubmitPrompt","prompt":"approved for tasks","workspace_roots":[]}'
        antigravity = '{"conversationId":"conv-1","prompt":"approved for tasks"}'
    }
    $stopPayload = @{
        cursor      = '{"conversation_id":"conv-1","hook_event_name":"stop","status":"completed"}'
        antigravity = '{"conversationId":"conv-1"}'
    }
    foreach ($h in 'cursor', 'antigravity') {
        $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $repoRoot "hosts\$h\host.psd1")
        $runtime = $manifest.RefocusHookBindings.DispatcherRuntime
        $declared = if ($runtime.ContainsKey('MessageIdentity')) { [string]$runtime.MessageIdentity.Kind } else { '' }
        Assert-True ($declared -ceq 'position-key') "[$h] the binding declares the position key as its message identity (got '$declared')"
        $assumption = if ($runtime.ContainsKey('MessageIdentity') -and $runtime.MessageIdentity.ContainsKey('Assumption')) { [string]$runtime.MessageIdentity.Assumption } else { '' }
        Assert-True ($assumption -match '(?i)unverified' -and $assumption -match '(?i)one prompt event per message') "[$h] the binding records 'one prompt event per message' as an unverified assumption"

        $fx = New-TurnRecordProject -HostKind $h
        $cleanup.Add($fx.Base)
        $r = Invoke-DeployedHook -Fixture $fx -NativeEvent $nativePrompt[$h] -StdinBytes ([Text.UTF8Encoding]::new($false).GetBytes($promptPayload[$h]))
        $hand = $r.Calls['specrew-handover-provider.ps1']
        Assert-True ($null -ne $hand) "[$h] the deployed prompt hook runs the handover provider"
        if ($null -ne $hand) {
            Assert-True ((Get-ArgValue $hand '--message-identity') -ceq 'position-key') "[$h] the prompt event hands the provider message identity 'position-key' (got '$(Get-ArgValue $hand '--message-identity')')"
            Assert-True ($null -eq (Get-ArgValue $hand '--message-id')) "[$h] and no message id: the provider builds the position key from the event itself"
        }
        $r = Invoke-DeployedHook -Fixture $fx -NativeEvent $nativeStop[$h] -StdinBytes ([Text.UTF8Encoding]::new($false).GetBytes($stopPayload[$h]))
        $hand = $r.Calls['specrew-handover-provider.ps1']
        if ($null -ne $hand) {
            Assert-True ((Get-ArgValue $hand '--message-identity') -ceq 'none') "[$h] the turn end hands the provider 'none': it records nothing on this host (got '$(Get-ArgValue $hand '--message-identity')')"
        }
        else { Write-Pass "[$h] the turn end runs no handover provider on this host, so it records nothing" }
    }

    # === 2. One message whose prompt hook fires twice records one act, at once or one after the other. ===
    foreach ($h in 'cursor', 'antigravity') {
        foreach ($mode in 'together', 'one after the other') {
            $p = New-PositionKeyProject; $cleanup.Add($p.Tmp)
            $fires = @((Get-PromptArgs -Project $p -HostKind $h -Prompt 'approved for tasks'), (Get-PromptArgs -Project $p -HostKind $h -Prompt 'approved for tasks'))
            $null = Invoke-PromptFires -ArgLists $fires -Together:($mode -eq 'together')
            $verdicts = @(Get-TasksVerdicts -Project $p)
            Assert-True ($verdicts.Count -eq 1) "[$h, $mode] the approval is recorded once (got $($verdicts.Count) verdict(s) for tasks)"
            $entries = @(Get-LedgerEntries -Project $p -Text 'approved for tasks')
            Assert-True (@(Get-LedgerKeys $entries).Count -eq 1) "[$h, $mode] the message is reserved under one key, not one per fire (got $(@(Get-LedgerKeys $entries).Count): $(Format-LedgerEntries $entries))"
            Assert-True (@(Get-NotRecordedReports -Project $p).Count -eq 0) "[$h, $mode] the second fire reports nothing as not recorded"
        }
    }

    # A non-verdict act, whose writer records each call: two fires are still one reserved message and one act.
    foreach ($h in 'cursor', 'antigravity') {
        $p = New-PositionKeyProject; $cleanup.Add($p.Tmp)
        $fires = @((Get-PromptArgs -Project $p -HostKind $h -Prompt 'approved for review round'), (Get-PromptArgs -Project $p -HostKind $h -Prompt 'approved for review round'))
        $null = Invoke-PromptFires -ArgLists $fires -Together
        $entries = @(Get-LedgerEntries -Project $p -Text 'approved for review round')
        Assert-True (@(Get-LedgerKeys $entries).Count -eq 1) "[$h] a round approval fired twice is one reserved message (got $(@(Get-LedgerKeys $entries).Count): $(Format-LedgerEntries $entries))"
        $minted = @($entries | Where-Object { $_.PSObject.Properties['minted'] -and -not [string]::IsNullOrWhiteSpace([string]$_.minted) })
        Assert-True ($minted.Count -le 1) "[$h] and at most one act (got $($minted.Count) minted)"
    }

    # === 3. Cursor's own hook and the Claude Code hook it may also run: still one act. ===
    $p = New-PositionKeyProject; $cleanup.Add($p.Tmp)
    $fires = @((Get-PromptArgs -Project $p -HostKind 'cursor' -Prompt 'approved for tasks'), (Get-PromptArgs -Project $p -HostKind 'claude' -Prompt 'approved for tasks' -Identity 'declared'))
    $null = Invoke-PromptFires -ArgLists $fires -Together
    $verdicts = @(Get-TasksVerdicts -Project $p)
    Assert-True ($verdicts.Count -eq 1) "[cursor + claude-labelled] the approval is recorded once (got $($verdicts.Count))"
    Assert-True (@(Get-NotRecordedReports -Project $p).Count -eq 0) "[cursor + claude-labelled] the claude-labelled fire reports nothing as not recorded"

    # === 4. The same phrase typed again after the window is a second message. ===
    $p = New-PositionKeyProject; $cleanup.Add($p.Tmp)
    $null = Invoke-PromptFires -ArgLists @(, (Get-PromptArgs -Project $p -HostKind 'cursor' -Prompt 'approved for review round'))
    Start-Sleep -Seconds 6
    $null = Invoke-PromptFires -ArgLists @(, (Get-PromptArgs -Project $p -HostKind 'cursor' -Prompt 'approved for review round'))
    $entries = @(Get-LedgerEntries -Project $p -Text 'approved for review round')
    Assert-True (@(Get-LedgerKeys $entries).Count -eq 2) "[cursor] the same phrase typed again after the window is a second message (got $(@(Get-LedgerKeys $entries).Count) keys)"
}
finally {
    foreach ($dir in $cleanup) { Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($script:failCount -gt 0) { Write-Host "$script:failCount failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'position-key-identity: all passed' -ForegroundColor Green
exit 0

# Feature 202 T005 (FR-024, FR-025; SC-001, SC-002): cross-host workshop acceptance.
#
# One workshop walk per validated host - product-domain, then the agenda, then one lens - with exactly ONE typed
# reply per checkpoint, delivered the way the host delivers it: the exact hook command the real deployer wrote for
# that host (Claude's guarded encoded command; the per-machine launcher for Codex and Copilot), the host's recorded
# T001 typed-prompt payload on stdin with only its prompt text replaced, the real dispatcher, the real handover
# provider and the shipped workshop authority store. Each host must yield 3 receipts, one per checkpoint, from 3
# replies, and no reply may come back refused or degraded.
#
# The open question for each checkpoint is written as the workshop leaves it on disk (the question record and the
# controller state); everything from the host's keystroke to the receipt is the shipped path.
#
# Experimental hosts: Cursor and Antigravity have no T001 payloads, so they are not walked here and are reported
# as unvalidated in the output (research.md, T001).
#
# Mutations that turn this file red: drop a host's Prompt field from its InputFieldMap (no reply reaches the
# store); decode the dispatcher's stdin with [Console]::In again (measured: Claude's Hebrew lens reply is mangled and
# its hash differs; the Codex and Copilot launcher reads the bytes itself, so those two stay green); make the
# dispatcher's prompt origin anything but typed-user for a typed reply (the receipt is refused); latch the journal
# again (every later reply is refused).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fixtureRoot = Join-Path $repoRoot 'tests\fixtures\hook-payloads'
$deployer = Join-Path $repoRoot 'scripts\internal\deploy-refocus-hooks.ps1'
$extensionScripts = Join-Path $repoRoot 'extensions\specrew-speckit\scripts'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }
function Assert-Equal { param($Actual, $Expected, [string]$Message) Assert-True ([string]$Actual -ceq [string]$Expected) ("{0} (expected '{1}', got '{2}')" -f $Message, $Expected, $Actual) }

. (Join-Path $extensionScripts 'workshop-authority-store.ps1')

$featureRef = '001-link-checker'
$nativePrompt = @{ claude = 'UserPromptSubmit'; codex = 'UserPromptSubmit'; copilot = 'userPromptSubmitted' }
$typedFixture = @{ claude = 'tui-userpromptsubmit-typed'; codex = 'tui-userpromptsubmit-typed'; copilot = 'tui-userpromptsubmitted-typed' }

function Write-Utf8 { param([string]$Path, [string]$Text) [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false)) }

function New-WorkshopHostProject {
    param([string]$HostKind)
    $base = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ('chw-{0}-{1}' -f $HostKind, [guid]::NewGuid().ToString('N').Substring(0, 8))))
    $proj = Join-Path $base 'proj'
    $userHome = Join-Path $base 'home'
    $scripts = Join-Path $proj '.specify\extensions\specrew-speckit\scripts'
    New-Item -ItemType Directory -Force -Path (Join-Path $proj '.specrew\runtime'), (Join-Path $proj '.specrew\handover'), $scripts, $userHome, (Join-Path $proj "specs\$featureRef\workshop") | Out-Null
    foreach ($leaf in 'specrew-hook-dispatcher.ps1', 'specrew-handover-provider.ps1', 'workshop-authority-store.ps1') {
        Copy-Item -LiteralPath (Join-Path $extensionScripts $leaf) -Destination (Join-Path $scripts $leaf)
    }
    $catalog = [ordered]@{
        schema_version = '1'
        providers      = @([ordered]@{ id = 'handover'; kind = 'inject'; events = @('UserPromptSubmit', 'PreInvocation', 'Stop', 'agentStop'); order = 30; budget_share = 1.0; command = 'specrew-handover-provider.ps1' })
    }
    Write-Utf8 (Join-Path $proj '.specify\extensions\specrew-speckit\refocus-scopes.json') ($catalog | ConvertTo-Json -Depth 6)
    Write-Utf8 (Join-Path $proj '.specrew\config.yml') 'version: 1'
    Write-Utf8 (Join-Path $proj "specs\$featureRef\spec.md") '# Link Checker'
    $deployLog = Join-Path $base 'deploy.log'
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $deployer -ProjectPath $proj -HostKind $HostKind -UserHomeOverride $userHome *> $deployLog
    if ($LASTEXITCODE -ne 0) { throw ("deployer failed for {0}: {1}" -f $HostKind, (Get-Content -LiteralPath $deployLog -Raw)) }
    return [pscustomobject]@{ Base = $base; Project = $proj; Home = $userHome; HostKind = $HostKind }
}

function Get-DeployedHookCommand {
    param($Fixture, [string]$NativeEvent)
    switch ($Fixture.HostKind) {
        'claude' { return [string](Get-Content -LiteralPath (Join-Path $Fixture.Project '.claude\settings.local.json') -Raw | ConvertFrom-Json).hooks.$NativeEvent[0].hooks[0].command }
        'codex' { return [string](Get-Content -LiteralPath (Join-Path $Fixture.Home '.codex\hooks.json') -Raw | ConvertFrom-Json).hooks.$NativeEvent[0].hooks[0].command }
        'copilot' { return [string](Get-Content -LiteralPath (Join-Path $Fixture.Home '.copilot\hooks\specrew-refocus.json') -Raw | ConvertFrom-Json).hooks.$NativeEvent[0].powershell }
    }
    throw "no deployed command reader for $($Fixture.HostKind)"
}

function Split-CommandLine {
    param([string]$CommandLine)
    $tokens = [System.Collections.Generic.List[string]]::new()
    foreach ($m in [regex]::Matches($CommandLine, '"((?:[^"\\]|\\.)*)"|(\S+)')) {
        if ($m.Groups[1].Success) { $tokens.Add($m.Groups[1].Value.Replace('\"', '"')) } else { $tokens.Add($m.Groups[2].Value) }
    }
    return $tokens.ToArray()
}

function Send-TypedReply {
    # One keystroke-to-hook delivery: the host's recorded typed-prompt payload with only the prompt replaced, sent as
    # UTF-8 bytes to the deployed command, spawned with a hidden console the way hosts spawn hooks.
    # With -RecordedFixture the named fixture's bytes are sent unchanged (a host-injected prompt, as recorded).
    param($Fixture, [string]$Reply, [string]$RecordedFixture)
    if ($RecordedFixture) {
        $bytes = [IO.File]::ReadAllBytes((Join-Path $fixtureRoot ("{0}\{1}.json" -f $Fixture.HostKind, $RecordedFixture)))
    }
    else {
        $payload = [IO.File]::ReadAllText((Join-Path $fixtureRoot ("{0}\{1}.json" -f $Fixture.HostKind, $typedFixture[$Fixture.HostKind])), [Text.Encoding]::UTF8) | ConvertFrom-Json
        $payload.prompt = $Reply
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($payload | ConvertTo-Json -Compress))
    }
    $argv = Split-CommandLine -CommandLine (Get-DeployedHookCommand -Fixture $Fixture -NativeEvent $nativePrompt[$Fixture.HostKind])
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $argv[0]
    foreach ($a in $argv[1..($argv.Count - 1)]) { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $Fixture.Project
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    foreach ($var in 'CLAUDE_PROJECT_DIR', 'CURSOR_PROJECT_DIR', 'COPILOT_PROJECT_DIR') { $psi.Environment[$var] = $Fixture.Project }
    $psi.Environment['SPECREW_MODULE_PATH'] = $repoRoot
    $psi.Environment.Remove('SPECREW_REFOCUS_DISABLE') | Out-Null
    $psi.Environment.Remove('SPECREW_DISABLE_EVENTS') | Out-Null
    $proc = [System.Diagnostics.Process]::Start($psi)
    $outTask = $proc.StandardOutput.ReadToEndAsync(); $errTask = $proc.StandardError.ReadToEndAsync()
    $proc.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
    $proc.StandardInput.Close()
    if (-not $proc.WaitForExit(120000)) { $proc.Kill($true); throw "deployed prompt hook timed out ($($Fixture.HostKind))" }
    return [pscustomobject]@{ ExitCode = $proc.ExitCode; StdOut = $outTask.Result; StdErr = $errTask.Result }
}

function Set-OpenQuestion {
    param($Fixture, [string]$Phase, [string]$Lens, [string]$AgendaStatus, [string]$QuestionHash, $AgendaBinding)
    $question = [ordered]@{
        schema = 'v3'; status = 'workshop-active'; scope = 'feature'; feature_ref = $featureRef; iteration_number = ''
        lens = $Lens; phase = $Phase; agenda_status = $AgendaStatus; question = 'open question'; message_hash = $QuestionHash
        artifact_path = (Join-Path $Fixture.Project "specs\$featureRef\lens-applicability.json")
    }
    if ($null -ne $AgendaBinding) {
        $question['agenda_binding'] = $AgendaBinding
        $question['agenda_digest'] = Get-SpecrewWorkshopAgendaDigest -Binding $AgendaBinding
    }
    Write-Utf8 (Join-Path $Fixture.Project '.specrew\handover\workshop-question.json') ($question | ConvertTo-Json -Depth 6)
}

function Set-ControllerState {
    param($Fixture, [string]$AgendaStatus, [string[]]$Selected, $Agenda, $Skipped)
    $state = [ordered]@{
        schema_version = '1.1'; workshop_intake = $true; confirmation_required = $true; agenda_contract = 'complete-coverage-v1'
        human_turn_contract = 'typed-turns-v1'; agenda_status = $AgendaStatus; selected = @($Selected); agenda = $Agenda; skipped = $Skipped
        agenda_confirmation = $(if ($AgendaStatus -eq 'confirmed') { 'human-confirmed' } else { 'pending' }); agenda_confirmation_scope = 'lens-selection'
        agenda_turn_receipt = $(if ($AgendaStatus -eq 'confirmed') { 'from-checkpoint-2' } else { 'pending' }); workshop = [ordered]@{}
    }
    Write-Utf8 (Join-Path $Fixture.Project "specs\$featureRef\lens-applicability.json") ($state | ConvertTo-Json -Depth 8)
}

function Get-Receipts {
    param($Fixture)
    $path = Get-SpecrewWorkshopAuthorityReceiptPath -ProjectRoot $Fixture.Project
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    return @([IO.File]::ReadAllLines($path, [Text.Encoding]::UTF8) | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
}

function Get-Outcomes {
    param($Fixture)
    $path = Join-Path $Fixture.Project '.specrew\runtime\workshop-receipt-outcomes.jsonl'
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    return @([IO.File]::ReadAllLines($path, [Text.Encoding]::UTF8) | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
}

function Test-Checkpoint {
    # Exactly one reply; it must produce exactly one new receipt for this checkpoint, with no refusal said.
    param($Fixture, [string]$Label, [string]$Reply, [string]$Phase, [string]$Lens, [string]$Scope)
    $prefix = "[$($Fixture.HostKind)] $Label"
    $before = @(Get-Receipts $Fixture).Count
    $r = Send-TypedReply -Fixture $Fixture -Reply $Reply
    Assert-True ($r.ExitCode -eq 0) "$prefix - the deployed prompt hook exits 0"
    $after = @(Get-Receipts $Fixture)
    Assert-Equal ($after.Count - $before) 1 "$prefix - one typed reply yields exactly one receipt"
    if ($after.Count -eq 0) { return }
    $receipt = $after[$after.Count - 1]
    Assert-Equal $receipt.phase $Phase "$prefix - the receipt binds this checkpoint's phase"
    Assert-Equal $receipt.lens $Lens "$prefix - the receipt binds this checkpoint's lens"
    Assert-Equal $receipt.confirmation 'human-confirmed' "$prefix - recorded as the human's typed confirmation"
    Assert-Equal $receipt.confirmation_scope $Scope "$prefix - scope"
    Assert-Equal $receipt.host_kind $Fixture.HostKind "$prefix - the receipt names the host the reply came from"
    Assert-Equal $receipt.response_hash (Get-SpecrewWorkshopAuthorityHash -Text $Reply) "$prefix - the reply reached the store byte-exact (its hash matches)"
    $refusals = @(Get-Outcomes $Fixture | Where-Object { [string]$_.status -in 'refused', 'degraded' })
    Assert-Equal $refusals.Count 0 "$prefix - no reply was refused or degraded"
    Assert-True (-not ($r.StdOut -match 'was not used|could(?:n''t| not) record')) "$prefix - no refusal is said to the human"
}

$visibleAgenda = [ordered]@{ 'architecture-core' = [ordered]@{ depth = 'light'; decision = 'choose the pipeline boundaries' } }
$visibleSkipped = [ordered]@{ 'ui-ux' = 'a command-line tool has no visual surface' }
$agendaBinding = ConvertTo-SpecrewWorkshopAgendaBinding -Agenda $visibleAgenda -Skipped $visibleSkipped

$projects = @{}
try {
    foreach ($h in 'claude', 'codex', 'copilot') {
        $fx = New-WorkshopHostProject -HostKind $h
        $projects[$h] = $fx
        Write-Host "--- ${h}: product-domain, agenda, one lens ---"

        Set-ControllerState -Fixture $fx -AgendaStatus 'pending-confirmation' -Selected @() -Agenda ([ordered]@{}) -Skipped ([ordered]@{})
        Set-OpenQuestion -Fixture $fx -Phase 'product-domain' -Lens 'product-domain' -AgendaStatus 'pending-confirmation' -QuestionHash 'q-product'
        Test-Checkpoint -Fixture $fx -Label 'checkpoint 1, product-domain' -Reply 'The users are developers and QA engineers; the MVP checks one site.' -Phase 'product-domain' -Lens 'product-domain' -Scope 'lens-question'

        Write-Utf8 (Join-Path $fx.Project "specs\$featureRef\workshop\product-domain.md") '# Product domain'
        Write-Utf8 (Join-Path $fx.Project "specs\$featureRef\workshop\product-domain.yml") 'depth: light'
        Set-OpenQuestion -Fixture $fx -Phase 'agenda' -Lens 'product-domain' -AgendaStatus 'pending-confirmation' -QuestionHash 'q-agenda' -AgendaBinding $agendaBinding
        Test-Checkpoint -Fixture $fx -Label 'checkpoint 2, agenda' -Reply 'Confirm the selected and skipped lenses exactly as shown.' -Phase 'agenda' -Lens 'product-domain' -Scope 'lens-selection'

        Set-ControllerState -Fixture $fx -AgendaStatus 'confirmed' -Selected @('architecture-core') -Agenda $visibleAgenda -Skipped $visibleSkipped
        Set-OpenQuestion -Fixture $fx -Phase 'lens' -Lens 'architecture-core' -AgendaStatus 'confirmed' -QuestionHash 'q-architecture'
        Test-Checkpoint -Fixture $fx -Label 'checkpoint 3, one lens (Hebrew reply)' -Reply 'One pipeline with bounded concurrency; בדיקה אחת לכל אתר.' -Phase 'lens' -Lens 'architecture-core' -Scope 'lens-question'

        Assert-Equal @(Get-Receipts $fx).Count 3 "[$h] the walk yields 3 receipts from 3 replies"

        # FR-006, enforced end to end (co-review round 1): a host-injected prompt arriving while a question is open is
        # never the human's answer. Hosts with a rule-classified recorded or synthetic injected prompt are exercised.
        $injected = @{ claude = 'tui-userpromptsubmit-host-injected-task-notification'; copilot = 'synthetic-userpromptsubmitted-skipped-question' }
        if ($injected.ContainsKey($h)) {
            Set-OpenQuestion -Fixture $fx -Phase 'lens' -Lens 'architecture-core' -AgendaStatus 'confirmed' -QuestionHash 'q-architecture-2'
            $outcomesBefore = @(Get-Outcomes $fx).Count
            $r = Send-TypedReply -Fixture $fx -RecordedFixture $injected[$h]
            Assert-True ($r.ExitCode -eq 0) "[$h] host-injected prompt ($($injected[$h])) - the deployed hook exits 0"
            Assert-Equal @(Get-Receipts $fx).Count 3 "[$h] host-injected prompt ($($injected[$h])) - produces no receipt"
            $outcomes = @(Get-Outcomes $fx | Select-Object -Skip $outcomesBefore)
            if ($h -eq 'copilot') {
                # The human dismissed a question: they did something, so the turn says it was not taken as an answer.
                Assert-True ($outcomes.Count -eq 1 -and [string]$outcomes[0].reason -eq 'not-typed-by-human') "[$h] host-injected prompt - refused as not typed by the human, and said"
            }
            else {
                # A task notification is not a reply at all: no receipt, and nothing to tell the human.
                Assert-Equal $outcomes.Count 0 "[$h] host-injected prompt - not a reply, so nothing is refused or said"
            }
        }

        # FR-003 through the deployed hook (co-review round 2): a malformed line in the hook-output journal is skipped by
        # the dispatcher's origin check exactly as by the store's reader. Before, the dispatcher read it as an unreadable
        # store, gave every later typed prompt origin 'unknown', and the receipt writer refused them all.
        if ($h -in 'claude', 'codex') {
            $journal = Join-Path $fx.Project '.specrew\runtime\hook-output-authority.jsonl'
            $valid = [ordered]@{ schema_version = '1.0'; output_hash = ('0' * 64); event = 'Stop'; host = $h; output_kind = 'stop-reason'; observed_at = '2026-10-14T00:00:00Z' }
            [IO.File]::AppendAllText($journal, (($valid | ConvertTo-Json -Compress) + "`n" + '{"schema_version":"1.0","output_hash":' + "`n"), [Text.UTF8Encoding]::new($false))
            Set-OpenQuestion -Fixture $fx -Phase 'lens' -Lens 'architecture-core' -AgendaStatus 'confirmed' -QuestionHash 'q-architecture-3'
            Test-Checkpoint -Fixture $fx -Label 'a typed reply after a malformed journal line' -Reply 'Keep the pipeline; one retry per site.' -Phase 'lens' -Lens 'architecture-core' -Scope 'lens-question'
        }
    }
    Write-Host 'Experimental hosts not walked (no T001 payloads, unvalidated): cursor, antigravity' -ForegroundColor Yellow
}
finally {
    foreach ($p in $projects.Values) { if ($p -and (Test-Path -LiteralPath $p.Base)) { Remove-Item -LiteralPath $p.Base -Recurse -Force -ErrorAction SilentlyContinue } }
}

if ($script:failCount -gt 0) { Write-Host "cross-host-workshop: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'cross-host-workshop: all passed' -ForegroundColor Green

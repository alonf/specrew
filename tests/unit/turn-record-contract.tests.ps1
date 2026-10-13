# Feature 202 T002 (FR-006, FR-024; SC-001 contract; DA-1 option B): one standard turn record, built from
# each host's DECLARED binding, delivered through the REAL deployed path.
#
# Every case runs the exact hook command the real deployer wrote for that host (Claude's guarded encoded
# command; the per-machine launcher for Codex and Copilot) with a T001 fixture's bytes on stdin. Probe
# providers in a temp project record the arguments the dispatcher hands them, which is what the shipped
# providers receive. Nothing calls the shared path directly.
#
# RED before T002:
#   - no --turn-origin / --turn-record reaches a provider (there is no turn record);
#   - a Hebrew prompt reaches the provider mangled: hook stdin is UTF-8 but [Console]::In decodes with the
#     process console code page (measured ibm437 on all three hosts, research.md T001);
#   - the bootstrap and the dispatcher normalize the same payload differently (the bootstrap accepts an
#     `id` key the dispatcher ignores, so their session ids differ).
#
# Mutations that turn this file red: decode stdin with [Console]::In again (Hebrew cases); drop an origin
# rule from a host binding (injected cases); re-add a host-name branch in shared code (parity check);
# let the bootstrap read the raw event instead of the record (id-key case).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fixtureRoot = Join-Path $repoRoot 'tests\fixtures\hook-payloads'
$deployer = Join-Path $repoRoot 'scripts\internal\deploy-refocus-hooks.ps1'
$deployedDispatcherSource = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-hook-dispatcher.ps1'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }
function Assert-Equal { param($Actual, $Expected, [string]$Message) Assert-True ([string]$Actual -ceq [string]$Expected) ("{0} (expected '{1}', got '{2}')" -f $Message, $Expected, $Actual) }

$probeBody = @'
# Probe provider: records the arguments the dispatcher hands a provider, then stays silent.
$out = Join-Path (Get-Location).Path '.probe'
[IO.Directory]::CreateDirectory($out) | Out-Null
$name = '{0}-{1}.json' -f (Split-Path -Leaf $PSCommandPath), [guid]::NewGuid().ToString('N')
[IO.File]::WriteAllText((Join-Path $out $name), (ConvertTo-Json -InputObject @($args | ForEach-Object { [string]$_ }) -Compress), [Text.UTF8Encoding]::new($false))
exit 0
'@

function New-TurnRecordProject {
    param([string]$HostKind)
    $base = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ('trc-{0}-{1}' -f $HostKind, [guid]::NewGuid().ToString('N').Substring(0, 8))))
    $proj = Join-Path $base 'proj'
    $userHome = Join-Path $base 'home'
    $scripts = Join-Path $proj '.specify\extensions\specrew-speckit\scripts'
    New-Item -ItemType Directory -Force -Path (Join-Path $proj '.specrew\runtime'), $scripts, $userHome | Out-Null
    Copy-Item -LiteralPath $deployedDispatcherSource -Destination (Join-Path $scripts 'specrew-hook-dispatcher.ps1')
    # The probes take the shipped providers' file names, so the dispatcher's provider-keyed argument rules apply.
    foreach ($leaf in 'specrew-handover-provider.ps1', 'specrew-bootstrap-provider.ps1') {
        [IO.File]::WriteAllText((Join-Path $scripts $leaf), $probeBody, [Text.UTF8Encoding]::new($false))
    }
    $catalog = [ordered]@{
        schema_version = '1'
        providers      = @(
            [ordered]@{ id = 'bootstrap'; kind = 'inject'; events = @('SessionStart', 'PreInvocation'); order = 20; budget_share = 0.5; command = 'specrew-bootstrap-provider.ps1' },
            [ordered]@{ id = 'handover'; kind = 'inject'; events = @('UserPromptSubmit', 'PreInvocation', 'Stop', 'agentStop'); order = 30; budget_share = 0.5; command = 'specrew-handover-provider.ps1' }
        )
    }
    [IO.File]::WriteAllText((Join-Path $proj '.specify\extensions\specrew-speckit\refocus-scopes.json'), ($catalog | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
    $deployLog = Join-Path $base 'deploy.log'
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $deployer -ProjectPath $proj -HostKind $HostKind -UserHomeOverride $userHome *> $deployLog
    if ($LASTEXITCODE -ne 0) { throw ("deployer failed for {0}: {1}" -f $HostKind, (Get-Content -LiteralPath $deployLog -Raw)) }
    return [pscustomobject]@{ Base = $base; Project = $proj; Home = $userHome; HostKind = $HostKind }
}

function Get-DeployedHookCommand {
    param($Fixture, [string]$NativeEvent)
    switch ($Fixture.HostKind) {
        'claude' {
            $cfg = Get-Content -LiteralPath (Join-Path $Fixture.Project '.claude\settings.local.json') -Raw | ConvertFrom-Json
            return [string]$cfg.hooks.$NativeEvent[0].hooks[0].command
        }
        'codex' {
            $cfg = Get-Content -LiteralPath (Join-Path $Fixture.Home '.codex\hooks.json') -Raw | ConvertFrom-Json
            return [string]$cfg.hooks.$NativeEvent[0].hooks[0].command
        }
        'copilot' {
            $cfg = Get-Content -LiteralPath (Join-Path $Fixture.Home '.copilot\hooks\specrew-refocus.json') -Raw | ConvertFrom-Json
            return [string]$cfg.hooks.$NativeEvent[0].powershell
        }
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

function Invoke-DeployedHook {
    # Runs the deployed command exactly as the host would: stdin carries the fixture's raw bytes, and every
    # project-root variable any host manifest names is pinned to the temp project, so a fixture can never
    # resolve to a real (governed) project from this test process's environment.
    param($Fixture, [string]$NativeEvent, [byte[]]$StdinBytes)
    Get-ChildItem -LiteralPath (Join-Path $Fixture.Project '.probe') -ErrorAction SilentlyContinue | Remove-Item -Force
    $argv = Split-CommandLine -CommandLine (Get-DeployedHookCommand -Fixture $Fixture -NativeEvent $NativeEvent)
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $argv[0]
    foreach ($a in $argv[1..($argv.Count - 1)]) { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $Fixture.Project
    $psi.UseShellExecute = $false
    # Hosts spawn hooks with a hidden console, so the hook's console input code page is the OEM one (measured
    # ibm437 on every validated host, research.md T001). Without a console .NET falls back to UTF-8 and the
    # decoding defect is invisible, so the test spawns the same way the hosts do.
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    foreach ($var in 'CLAUDE_PROJECT_DIR', 'CURSOR_PROJECT_DIR', 'COPILOT_PROJECT_DIR') { $psi.Environment[$var] = $Fixture.Project }
    $psi.Environment.Remove('SPECREW_REFOCUS_DISABLE') | Out-Null
    $psi.Environment.Remove('SPECREW_DISABLE_EVENTS') | Out-Null
    $proc = [System.Diagnostics.Process]::Start($psi)
    $outTask = $proc.StandardOutput.ReadToEndAsync()
    $errTask = $proc.StandardError.ReadToEndAsync()
    $proc.StandardInput.BaseStream.Write($StdinBytes, 0, $StdinBytes.Length)
    $proc.StandardInput.Close()
    if (-not $proc.WaitForExit(90000)) { $proc.Kill($true); throw "deployed hook timed out ($($Fixture.HostKind) $NativeEvent)" }
    $null = $outTask.Result; $stderr = $errTask.Result
    $calls = @{}
    foreach ($f in @(Get-ChildItem -LiteralPath (Join-Path $Fixture.Project '.probe') -Filter *.json -ErrorAction SilentlyContinue)) {
        $leaf = $f.Name -replace '-[0-9a-f]{32}\.json$', ''
        $calls[$leaf] = @([IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8) | ConvertFrom-Json)
    }
    return [pscustomobject]@{ ExitCode = $proc.ExitCode; Calls = $calls; StdErr = $stderr }
}

function Get-ArgValue {
    param([string[]]$ArgList, [string]$Name)
    for ($i = 0; $i -lt $ArgList.Count - 1; $i++) { if ($ArgList[$i] -ceq $Name) { return $ArgList[$i + 1] } }
    return $null
}

function Get-SafeSessionId { param([string]$Raw) return ((([string]$Raw) -replace '[^a-zA-Z0-9-]+', '-').Trim('-')) }

function Add-HookOutputJournalLine {
    # The dispatcher journals every hook output it emits (Write-DispatcherHookOutputAuthorityRecord). A replayed
    # Stop reason is therefore already in the journal when the host re-submits it; seed exactly that line.
    param([string]$ProjectRoot, [string]$Text)
    $hash = ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text.Trim())))).ToLowerInvariant()
    $line = ([ordered]@{ schema_version = '1.0'; output_hash = $hash; event = 'Stop'; host = 'seed'; output_kind = 'stop-block-reason'; observed_at = [DateTimeOffset]::UtcNow.ToString('o') } | ConvertTo-Json -Compress) + "`n"
    [IO.File]::AppendAllText((Join-Path $ProjectRoot '.specrew\runtime\hook-output-authority.jsonl'), $line, [Text.UTF8Encoding]::new($false))
}

$nativePrompt = @{ claude = 'UserPromptSubmit'; codex = 'UserPromptSubmit'; copilot = 'userPromptSubmitted' }
$nativeStart = @{ claude = 'SessionStart'; codex = 'SessionStart'; copilot = 'sessionStart' }
$nativeStop = @{ claude = 'Stop'; codex = 'Stop'; copilot = 'agentStop' }

$cases = @(
    # host, fixture, kind, expected origin, label
    @('claude', 'print-userpromptsubmit-typed-hebrew', 'prompt', 'typed-user', 'recorded typed prompt (Hebrew)'),
    @('claude', 'tui-userpromptsubmit-typed', 'prompt', 'typed-user', 'recorded typed prompt'),
    @('claude', 'tui-userpromptsubmit-host-injected-task-notification', 'prompt', 'host-injected', 'recorded host-injected <task-notification>'),
    @('codex', 'tui-userpromptsubmit-typed', 'prompt', 'typed-user', 'recorded typed prompt'),
    @('codex', 'exec-userpromptsubmit-typed', 'prompt', 'typed-user', 'recorded typed prompt (exec)'),
    @('codex', 'synthetic-userpromptsubmit-host-injected', 'prompt-journaled', 'host-injected', 'SYNTHETIC host-injected text caught by the journal match'),
    @('copilot', 'print-userpromptsubmitted-typed-hebrew', 'prompt', 'typed-user', 'recorded typed prompt (Hebrew)'),
    @('copilot', 'tui-userpromptsubmitted-typed', 'prompt', 'typed-user', 'recorded typed prompt'),
    @('copilot', 'print-userpromptsubmitted-host-injected-stop-reason-replay', 'prompt-journaled', 'host-injected', 'recorded Stop-reason replay caught by the journal match'),
    @('copilot', 'synthetic-userpromptsubmitted-skipped-question', 'prompt', 'host-injected', 'SYNTHETIC skipped-question string via the named transform'),
    @('claude', 'print-sessionstart-startup', 'start', 'unknown', 'recorded SessionStart'),
    @('claude', 'tui-sessionstart-startup', 'start', 'unknown', 'recorded SessionStart (TUI)'),
    @('codex', 'tui-sessionstart-startup', 'start', 'unknown', 'recorded SessionStart'),
    @('codex', 'exec-sessionstart-startup', 'start', 'unknown', 'recorded SessionStart (exec)'),
    @('copilot', 'print-sessionstart-new', 'start', 'unknown', 'recorded sessionStart'),
    @('copilot', 'tui-sessionstart-new', 'start', 'unknown', 'recorded sessionStart (TUI)'),
    @('claude', 'tui-stop', 'stop', 'unknown', 'recorded Stop'),
    @('codex', 'tui-stop', 'stop', 'unknown', 'recorded Stop'),
    @('copilot', 'tui-agentstop', 'stop', 'unknown', 'recorded agentStop')
)

$projects = @{}
try {
    foreach ($h in 'claude', 'codex', 'copilot') { $projects[$h] = New-TurnRecordProject -HostKind $h }

    foreach ($case in $cases) {
        $h, $fixtureName, $kind, $expectedOrigin, $label = $case
        $fx = $projects[$h]
        $bytes = [IO.File]::ReadAllBytes((Join-Path $fixtureRoot "$h\$fixtureName.json"))
        $payload = [Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-Json
        $prefix = "[$h $fixtureName] $label"
        switch ($kind) {
            { $_ -in 'prompt', 'prompt-journaled' } {
                $promptKey = @('prompt') | Where-Object { $payload.PSObject.Properties[$_] } | Select-Object -First 1
                $promptText = [string]$payload.$promptKey
                if ($kind -eq 'prompt-journaled') { Add-HookOutputJournalLine -ProjectRoot $fx.Project -Text $promptText }
                $r = Invoke-DeployedHook -Fixture $fx -NativeEvent $nativePrompt[$h] -StdinBytes $bytes
                Assert-True ($r.ExitCode -eq 0) "$prefix - the deployed hook exits 0"
                $hand = $r.Calls['specrew-handover-provider.ps1']
                Assert-True ($null -ne $hand) "$prefix - the handover provider ran"
                if ($null -eq $hand) { continue }
                Assert-Equal (Get-ArgValue $hand '--last-user-message') $promptText "$prefix - the prompt text reaches the provider byte-exact"
                Assert-Equal (Get-ArgValue $hand '--turn-origin') $expectedOrigin "$prefix - origin"
                $sid = if ($payload.PSObject.Properties['session_id']) { $payload.session_id } else { $payload.sessionId }
                Assert-Equal (Get-ArgValue $hand '--session-id') (Get-SafeSessionId $sid) "$prefix - the session id comes from the declared field map"
            }
            'start' {
                $r = Invoke-DeployedHook -Fixture $fx -NativeEvent $nativeStart[$h] -StdinBytes $bytes
                Assert-True ($r.ExitCode -eq 0) "$prefix - the deployed hook exits 0"
                $boot = $r.Calls['specrew-bootstrap-provider.ps1']
                Assert-True ($null -ne $boot) "$prefix - the bootstrap provider ran"
                if ($null -eq $boot) { continue }
                $encoded = Get-ArgValue $boot '--turn-record'
                Assert-True (-not [string]::IsNullOrWhiteSpace($encoded)) "$prefix - the bootstrap receives the turn record"
                if ([string]::IsNullOrWhiteSpace($encoded)) { continue }
                $record = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded)) | ConvertFrom-Json
                $sid = if ($payload.PSObject.Properties['session_id']) { $payload.session_id } else { $payload.sessionId }
                Assert-Equal $record.schema 'specrew-turn-record/v1' "$prefix - record schema"
                Assert-Equal $record.event 'SessionStart' "$prefix - neutral event name"
                Assert-Equal $record.host $h "$prefix - host"
                Assert-Equal $record.session_id $sid "$prefix - session id"
                Assert-Equal $record.safe_session_id (Get-SafeSessionId $sid) "$prefix - safe session id"
                Assert-Equal $record.source $payload.source "$prefix - source"
                Assert-Equal $record.origin $expectedOrigin "$prefix - a non-prompt event has origin unknown"
                Assert-True ($null -eq $record.PSObject.Properties['typed_text']) "$prefix - the --turn-record argument carries no user text"
                Assert-Equal (Get-ArgValue $boot '--session-id') (Get-SafeSessionId $sid) "$prefix - the dispatcher's session id equals the record's"
            }
            'stop' {
                $r = Invoke-DeployedHook -Fixture $fx -NativeEvent $nativeStop[$h] -StdinBytes $bytes
                Assert-True ($r.ExitCode -eq 0) "$prefix - the deployed hook exits 0"
                $hand = $r.Calls['specrew-handover-provider.ps1']
                Assert-True ($null -ne $hand) "$prefix - the handover provider ran"
                if ($null -eq $hand) { continue }
                $tp = if ($payload.PSObject.Properties['transcript_path']) { $payload.transcript_path } else { $payload.transcriptPath }
                Assert-Equal (Get-ArgValue $hand '--transcript-path') $tp "$prefix - the transcript path comes from the declared field map"
                Assert-True ($null -eq (Get-ArgValue $hand '--turn-origin')) "$prefix - a Stop event carries no prompt origin"
            }
        }
    }

    # Derived (not recorded): a replayed Specrew directive is host-injected by the declared prefix rule on every host.
    foreach ($h in 'claude', 'codex', 'copilot') {
        $fx = $projects[$h]
        $typed = Join-Path $fixtureRoot ("$h\" + $(if ($h -eq 'copilot') { 'tui-userpromptsubmitted-typed' } else { 'tui-userpromptsubmit-typed' }) + '.json')
        $payload = [IO.File]::ReadAllText($typed, [Text.Encoding]::UTF8) | ConvertFrom-Json
        $payload.prompt = 'Specrew: boundary state is pending and no turn-end declaration for this turn recorded the pending crossing.'
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($payload | ConvertTo-Json -Compress))
        $r = Invoke-DeployedHook -Fixture $fx -NativeEvent $nativePrompt[$h] -StdinBytes $bytes
        $hand = $r.Calls['specrew-handover-provider.ps1']
        Assert-Equal $(if ($hand) { Get-ArgValue $hand '--turn-origin' } else { $null }) 'host-injected' "[$h DERIVED from recorded typed prompt] a replayed Specrew directive is host-injected"
    }

    # One normalizer: a payload carrying only an `id` key. The old bootstrap normalizer accepted `id`; the
    # dispatcher did not, so the two disagreed. Now no declared map names `id`, and the bootstrap receives the
    # dispatcher's record, so both see "no host session id" and the record carries a per-launch safe id.
    $fx = $projects['claude']
    $idOnly = [Text.UTF8Encoding]::new($false).GetBytes('{"id":"abc-123","source":"startup","hook_event_name":"SessionStart"}')
    $r = Invoke-DeployedHook -Fixture $fx -NativeEvent 'SessionStart' -StdinBytes $idOnly
    $boot = $r.Calls['specrew-bootstrap-provider.ps1']
    $encoded = if ($boot) { Get-ArgValue $boot '--turn-record' } else { $null }
    $record = if ($encoded) { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded)) | ConvertFrom-Json } else { $null }
    Assert-True ($null -ne $record -and $null -eq $record.session_id) '[id-key RED] the record has no host session id for an id-only payload'
    Assert-True ($null -ne $record -and ([string]$record.safe_session_id).StartsWith('launch-')) '[id-key RED] the record carries a per-launch safe id, the one the bootstrap will use'
    Assert-True ($null -eq (Get-ArgValue $boot '--session-id')) '[id-key RED] the dispatcher forwards no host session id either'

    # Every declared binding is data: each validated host declares a field map, origin rules and (optionally) a
    # transform name; the shared dispatcher holds no host-name branch.
    foreach ($h in 'claude', 'codex', 'copilot') {
        $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $repoRoot "hosts\$h\host.psd1")
        $runtime = $manifest.RefocusHookBindings.DispatcherRuntime
        Assert-True ($runtime.ContainsKey('InputFieldMap') -and $runtime.InputFieldMap.ContainsKey('SessionId') -and $runtime.InputFieldMap.ContainsKey('Prompt')) "[$h] declares InputFieldMap with SessionId and Prompt"
        Assert-True ($runtime.ContainsKey('OriginRules') -and @($runtime.OriginRules).Count -gt 0) "[$h] declares OriginRules"
    }
    $dispatcherText = [IO.File]::ReadAllText($deployedDispatcherSource)
    $turnRecordBody = [regex]::Match($dispatcherText, '(?s)function ConvertTo-SpecrewTurnRecord\b.*?\n}\r?\n').Value
    Assert-True ($turnRecordBody.Length -gt 0) 'the dispatcher defines ConvertTo-SpecrewTurnRecord'
    Assert-True (-not ($turnRecordBody -match "(?i)['""](claude|codex|copilot|cursor|antigravity)['""]")) 'ConvertTo-SpecrewTurnRecord names no host'
    $adapter = [IO.File]::ReadAllText((Join-Path $repoRoot 'scripts\internal\bootstrap\HostEventAdapter.ps1'))
    Assert-True (-not ($adapter -match 'function ConvertFrom-SpecrewHostHookEvent')) 'the second normalizer (ConvertFrom-SpecrewHostHookEvent) is gone'
}
finally {
    foreach ($p in $projects.Values) { if ($p -and (Test-Path -LiteralPath $p.Base)) { Remove-Item -LiteralPath $p.Base -Recurse -Force -ErrorAction SilentlyContinue } }
}

if ($script:failCount -gt 0) { Write-Host "turn-record-contract: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'turn-record-contract: all passed' -ForegroundColor Green

# Feature 202 iteration 002, T016 (FR-028, DA-1; B4F-129): a hook acts only for its own host.
#
# Copilot 1.0.98 also runs the hooks in .claude/settings.local.json, which `specrew init` writes into every project, so
# in the live walk every Specrew hook fired twice: as copilot, and seconds later as claude. Every receipt was doubled
# and the Claude-labelled end-of-turn check blocked every Copilot turn.
#
# The rule (the maintainer's change to DA-1): each host binding declares the payload fields only its host sends, and
# a hook STANDS DOWN - does nothing, writes nothing, exits 0 - only when the payload positively matches ANOTHER known
# host. A payload that matches no known host is handled as today and logged once, so a host that changes its payload
# shape can never switch governance off without a trace.
#
# Every case runs the exact hook command the real deployer wrote, with a recorded payload's bytes on stdin; probe
# providers record whether anything ran. A third part proves the receipt store refuses a receipt ID it already holds.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fixtureRoot = Join-Path $repoRoot 'tests\fixtures\hook-payloads'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

# The deploy-and-run harness is shared with the layer-1 host payload probe (B4F-145).
. (Join-Path $repoRoot 'tests\host-probes\deployed-hook-harness.ps1')

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


$nativeEvent = @{
    claude  = @{ prompt = 'UserPromptSubmit'; start = 'SessionStart'; stop = 'Stop' }
    codex   = @{ prompt = 'UserPromptSubmit'; start = 'SessionStart'; stop = 'Stop' }
    copilot = @{ prompt = 'userPromptSubmitted'; start = 'sessionStart'; stop = 'agentStop' }
}
function Get-FixtureKind { param([string]$Name) if ($Name -match '(?i)userprompt') { 'prompt' } elseif ($Name -match '(?i)sessionstart') { 'start' } elseif ($Name -match '(?i)stop') { 'stop' } else { $null } }
function Clear-Runtime { param($Fixture) foreach ($d in '.probe', '.specrew\runtime\hook-health') { Get-ChildItem -LiteralPath (Join-Path $Fixture.Project $d) -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue } }
function Get-HealthFiles { param($Fixture) @(Get-ChildItem -LiteralPath (Join-Path $Fixture.Project '.specrew\runtime\hook-health') -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^unrecognized-payload-' }) }
function Get-UnrecognizedLogs { param($Fixture) @(Get-ChildItem -LiteralPath (Join-Path $Fixture.Project '.specrew\runtime\hook-health') -File -Filter 'unrecognized-payload-*' -ErrorAction SilentlyContinue) }

$projects = @{}
try {
    foreach ($h in 'claude', 'codex', 'copilot') { $projects[$h] = New-TurnRecordProject -HostKind $h }

    Write-Host '--- part 1: every recorded payload against every validated host deployed hook ---'
    foreach ($target in 'claude', 'codex', 'copilot') {
        $fx = $projects[$target]
        foreach ($source in 'claude', 'codex', 'copilot') {
            foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $fixtureRoot $source) -Filter *.json | Where-Object { $_.Name -ne 'provenance.json' })) {
                $kind = Get-FixtureKind $file.BaseName
                if ($null -eq $kind) { continue }
                Clear-Runtime $fx
                $r = Invoke-DeployedHook -Fixture $fx -NativeEvent $nativeEvent[$target][$kind] -StdinBytes ([IO.File]::ReadAllBytes($file.FullName))
                $label = "[$source payload -> $target hook] $($file.BaseName)"
                Assert-True ($r.ExitCode -eq 0) "$label - exits 0"
                # The reader for the unrecognized-payload record (B4F-144): no recorded payload may produce one.
                Assert-True (@(Get-UnrecognizedLogs $fx).Count -eq 0) "$label - recognized: no unrecognized-payload record"
                $ran = @($r.Calls.Keys).Count -gt 0
                if ($source -eq $target) {
                    Assert-True $ran "$label - its own host payload is handled (a provider ran)"
                }
                else {
                    Assert-True (-not $ran) "$label - another host payload stands down: no provider ran"
                    Assert-True (@(Get-HealthFiles $fx).Count -eq 0) "$label - and nothing was written, not even a hook-health receipt"
                }
            }
        }
    }

    Write-Host '--- part 1b: what the layer-1 probe captured from the real hosts, on every channel (B4F-144) ---'
    # tests/fixtures/hook-payloads/probe/<channel>/ comes from tests/host-probes/host-payload-capture-probe.ps1. The
    # copilot-claude-hooks channel is Claude's hooks as Copilot runs them: the channel B4F-129 is about, which T016's
    # fixtures never covered. Its payloads must stand down in Claude's hook and in Codex's; Copilot's own hook never
    # receives them. Every other channel is handled by its own host's hook and stands down in the others.
    $probeRoot = Join-Path $fixtureRoot 'probe'
    $probeNative = @{
        claude  = @{ prompt = 'UserPromptSubmit'; start = 'SessionStart'; stop = 'Stop'; tool = 'PostToolUse' }
        codex   = @{ prompt = 'UserPromptSubmit'; start = 'SessionStart'; stop = 'Stop'; tool = 'PostToolUse' }
        copilot = @{ prompt = 'userPromptSubmitted'; start = 'sessionStart'; stop = 'agentStop' }
    }
    function Get-ProbeFixtureKind { param([string]$Name) if ($Name -match '(?i)userprompt') { 'prompt' } elseif ($Name -match '(?i)sessionstart') { 'start' } elseif ($Name -match '(?i)stop') { 'stop' } elseif ($Name -match '(?i)posttooluse') { 'tool' } else { $null } }
    # Iteration 003 review round 2: a sub-agent's stop is not the end of the human's turn. Copilot fires agentStop for a
    # sub-agent too; its own hook stands down on it, as on a payload from another host.
    function Test-SubAgentPayload { param([string]$Path) $keys = @((Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json).PSObject.Properties.Name); return (@($keys | Where-Object { $_ -cin @('agent_id', 'parent_agent_id', 'agentId', 'parentAgentId') }).Count -gt 0) }
    $probeChannels = @(Get-ChildItem -LiteralPath $probeRoot -Directory | Sort-Object Name)
    Assert-True (@($probeChannels | Where-Object Name -eq 'copilot-claude-hooks').Count -eq 1) 'the probe fixtures include the Claude-hook channel as Copilot runs it'
    foreach ($channel in $probeChannels) {
        foreach ($file in @(Get-ChildItem -LiteralPath $channel.FullName -Filter *.json | Where-Object { $_.Name -ne 'provenance.json' })) {
            $kind = Get-ProbeFixtureKind $file.BaseName
            if ($null -eq $kind) { continue }
            foreach ($target in 'claude', 'codex', 'copilot') {
                if ($channel.Name -eq 'copilot-claude-hooks' -and $target -eq 'copilot') { continue }
                $native = $probeNative[$target][$kind]
                if ($null -eq $native) { continue }
                $fx = $projects[$target]
                $deployed = $null
                try { $deployed = Get-DeployedHookCommand -Fixture $fx -NativeEvent $native } catch { $deployed = $null }
                if ([string]::IsNullOrWhiteSpace($deployed)) { continue }   # Specrew deploys no hook on this event for this host
                Clear-Runtime $fx
                $before = Get-HarnessRuntimeSnapshot $fx
                $r = Invoke-DeployedHook -Fixture $fx -NativeEvent $native -StdinBytes ([IO.File]::ReadAllBytes($file.FullName))
                $label = "[probe $($channel.Name) payload -> $target hook] $($file.BaseName)"
                Assert-True ($r.ExitCode -eq 0) "$label - exits 0"
                Assert-True (@(Get-UnrecognizedLogs $fx).Count -eq 0) "$label - recognized: no unrecognized-payload record"
                $ran = @($r.Calls.Keys).Count -gt 0
                if ($channel.Name -eq $target -and $kind -eq 'stop' -and (Test-SubAgentPayload $file.FullName)) {
                    Assert-True (-not $ran) "$label - a sub-agent's stop stands down: no provider ran"
                    $changed = @(Compare-Object -ReferenceObject $before -DifferenceObject (Get-HarnessRuntimeSnapshot $fx))
                    Assert-True ($changed.Count -eq 0) "$label - and nothing under .specrew/runtime changed"
                }
                elseif ($channel.Name -eq $target) {
                    if ($kind -ne 'tool') { Assert-True $ran "$label - its own host payload is handled (a provider ran)" }
                }
                else {
                    Assert-True (-not $ran) "$label - another host payload stands down: no provider ran"
                    $changed = @(Compare-Object -ReferenceObject $before -DifferenceObject (Get-HarnessRuntimeSnapshot $fx))
                    Assert-True ($changed.Count -eq 0) "$label - and nothing under .specrew/runtime changed"
                }
            }
        }
    }

    Write-Host '--- part 2: a payload that matches no known host is handled as today and logged once ---'
    $fx = $projects['claude']
    Clear-Runtime $fx
    $odd = [Text.Encoding]::UTF8.GetBytes((@{ session_id = 'odd-1'; prompt = 'hello'; cwd = $fx.Project; some_new_field = 1 } | ConvertTo-Json -Compress))
    $r1 = Invoke-DeployedHook -Fixture $fx -NativeEvent 'UserPromptSubmit' -StdinBytes $odd
    Assert-True (@($r1.Calls.Keys).Count -gt 0) '[unknown shape -> claude hook] handled as today (a provider ran)'
    Assert-True (@(Get-UnrecognizedLogs $fx).Count -eq 1) '[unknown shape -> claude hook] logged'
    $r2 = Invoke-DeployedHook -Fixture $fx -NativeEvent 'UserPromptSubmit' -StdinBytes $odd
    Assert-True (@($r2.Calls.Keys).Count -gt 0) '[unknown shape -> claude hook] a second fire is handled too'
    Assert-True (@(Get-UnrecognizedLogs $fx).Count -eq 1) '[unknown shape -> claude hook] and logged once, not twice'
    $logs = @(Get-UnrecognizedLogs $fx)
    $log = if ($logs.Count -gt 0) { Get-Content -LiteralPath $logs[0].FullName -Raw } else { '' }
    Assert-True ($log -match 'some_new_field' -and $log -notmatch 'hello') '[unknown shape] the log names the field names, never a value'
}
finally {
    foreach ($p in $projects.Values) { if ($p -and (Test-Path -LiteralPath $p.Base)) { Remove-Item -LiteralPath $p.Base -Recurse -Force -ErrorAction SilentlyContinue } }
}

Write-Host '--- part 3: the receipt store refuses a receipt ID it already holds ---'
$storeSource = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/workshop-authority-store.ps1'
$provider = Join-Path $repoRoot 'scripts/internal/specrew-handover-provider.ps1'
$root = Join-Path ([IO.Path]::GetTempPath()) ('hbm-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
try {
    $feature = '001-mail-summary'
    foreach ($d in @('.specrew/handover', '.specrew/runtime', '.specify/extensions/specrew-speckit/scripts', "specs/$feature/workshop")) { New-Item -ItemType Directory -Path (Join-Path $root $d) -Force | Out-Null }
    Copy-Item -LiteralPath $storeSource -Destination (Join-Path $root '.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1') -Force
    Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value 'version: 1' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root "specs/$feature/spec.md") -Value '# Mail Summary' -Encoding UTF8
    $controller = [ordered]@{ human_turn_contract = 'typed-turns-v1'; agenda_contract = 'complete-coverage-v1'; agenda_status = 'pending-confirmation'; selected = @('architecture-core'); workshop = @{} }
    [IO.File]::WriteAllText((Join-Path $root "specs/$feature/lens-applicability.json"), ($controller | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $question = [ordered]@{ schema = 'v3'; status = 'workshop-active'; scope = 'feature'; feature_ref = $feature; iteration_number = ''; lens = ''
        phase = 'product-domain'; agenda_status = 'pending-confirmation'; question = 'Who is this for?'; message_hash = ('a' * 64); artifact_path = '' }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/handover/workshop-question.json'), ($question | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $ctx = [ordered]@{ schema = 'v2'; session_state = [ordered]@{ active = $true; feature_ref = $feature; boundary_type = 'specify'; host = 'copilot' } }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $reply = 'It is for support staff who read the shared inbox.'
    foreach ($hk in 'copilot', 'claude') { & pwsh -NoProfile -File $provider --project-root $root --host-kind $hk --source-event UserPromptSubmit --last-user-message $reply --turn-origin typed-user *> $null }
    $receiptPath = Join-Path $root '.specrew/runtime/workshop-authority.jsonl'
    $rows = if (Test-Path -LiteralPath $receiptPath) { @(Get-Content -LiteralPath $receiptPath | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }) } else { @() }
    Assert-True ($rows.Count -eq 1) ("one reply offered twice (the walk's copilot-then-claude double) leaves one receipt (got {0})" -f $rows.Count)
    Assert-True ($rows.Count -ge 1 -and [string]$rows[0].host_kind -eq 'copilot') 'the receipt kept is the first one written'
}
finally { if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue } }

Write-Host '--- part 4: the recorded probe fixtures name no user and keep their capture times exact (review round 2) ---'
. (Join-Path $repoRoot 'tests\host-probes\probe-fixture-redaction.ps1')
foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $fixtureRoot 'probe') -Recurse -File -Filter *.json)) {
    $text = [IO.File]::ReadAllText($file.FullName)
    Assert-True (-not (Test-ProbeFixtureTextHasUserPath -Text $text)) ("[probe fixture] {0}/{1} - no user profile path" -f $file.Directory.Name, $file.Name)
    if ($file.Name -eq 'provenance.json') {
        $times = @((ConvertFrom-Json -InputObject $text -DateKind String).fixtures | ForEach-Object { [string]$_.captured_utc })
        $bad = @($times | Where-Object { $_ -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$' })
        Assert-True ($times.Count -gt 0 -and $bad.Count -eq 0) ("[probe provenance] {0} - every captured_utc is an ISO 8601 UTC time (not: {1})" -f $file.Directory.Name, ($bad -join '; '))
    }
}

if ($script:failCount -gt 0) { Write-Host "host-binding-match: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'host-binding-match: all assertions pass' -ForegroundColor Green
exit 0

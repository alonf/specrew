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
$deployer = Join-Path $repoRoot 'scripts\internal\deploy-refocus-hooks.ps1'
$deployedDispatcherSource = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-hook-dispatcher.ps1'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

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

if ($script:failCount -gt 0) { Write-Host "host-binding-match: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'host-binding-match: all assertions pass' -ForegroundColor Green
exit 0

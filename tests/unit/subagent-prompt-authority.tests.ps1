# Feature 202 iteration 002, T028 (FR-027, FR-028; B4F-147): a sub-agent's task text is never a human approval.
#
# In the SC-011 re-walk (Copilot 1.0.98) a sub-agent's task text reached both hosts' prompt hooks as a user prompt: on
# Copilot's own channel and, through Claude's hooks that Copilot also runs, on the Claude channel. The probe
# (tests/host-probes/host-payload-capture-probe.ps1) recorded the shapes on Copilot 1.0.101: Copilot's own channel marks
# the payload with agentId, agentType and parentAgentId; the Claude channel with agent_id, agent_type and
# parent_agent_id. The task text is written by the model, so if it carries an approval phrase it must record nothing.
#
# Each case puts 'approved for review round' in a payload that carries a sub-agent field, runs the hook command the
# real deployer wrote, and then runs the REAL handover provider with exactly the arguments the dispatcher handed it.
# The provider runs with --project-root, working directory and host project variables all set to a temp project,
# and the suite fails if the repo's own stores change (DRIFT-007: a first version wrote into the repo). Nothing may
# be stored. The controls are the same payloads without the sub-agent field: those store the approval,
# so the chain under test is one that can record.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$probeFixtures = Join-Path $repoRoot 'tests\fixtures\hook-payloads\probe'
$realProvider = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-handover-provider.ps1'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

. (Join-Path $repoRoot 'tests\host-probes\deployed-hook-harness.ps1')

$approval = 'approved for review round'

function New-ApprovalProject {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('f202-subagent-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "specrew_version: `"0.40.0`"`nbootstrap_mode: `"fixture`"" -Encoding UTF8
    & git init -q -b 001-fixture $root 2>&1 | Out-Null
    return $root
}

function Test-RoundApprovalStored {
    param([string]$Root)
    $p = Join-Path $Root '.specrew/review/round-approval/pending-round-approval.json'
    if (-not (Test-Path -LiteralPath $p)) { return $false }
    return [string]::IsNullOrWhiteSpace([string](Get-Content -LiteralPath $p -Raw | ConvertFrom-Json).spent_at)
}

function New-Payload {
    # A recorded payload with the approval as its prompt, plus or minus the given fields.
    param([string]$Channel, [string]$Fixture, [hashtable]$Add = @{}, [string[]]$Remove = @())
    $o = [IO.File]::ReadAllText((Join-Path $probeFixtures "$Channel\$Fixture"), [Text.Encoding]::UTF8) | ConvertFrom-Json
    $o.prompt = $approval
    foreach ($name in $Remove) { $o.PSObject.Properties.Remove($name) }
    foreach ($name in $Add.Keys) { $o | Add-Member -NotePropertyName $name -NotePropertyValue $Add[$name] -Force }
    return [Text.Encoding]::UTF8.GetBytes(($o | ConvertTo-Json -Depth 10 -Compress))
}

function Invoke-PinnedProvider {
    # The real provider, with its working directory and every host project variable set to the temp project.
    param([string]$Root, [string[]]$Arguments)
    $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
    foreach ($a in @('-NoProfile', '-NonInteractive', '-File', $realProvider) + $Arguments) { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $Root
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    foreach ($name in 'CLAUDE_PROJECT_DIR', 'COPILOT_PROJECT_DIR', 'CURSOR_PROJECT_DIR') { $psi.Environment[$name] = $Root }
    $psi.Environment['SPECREW_MODULE_PATH'] = $repoRoot
    $proc = [Diagnostics.Process]::Start($psi)
    $null = $proc.StandardOutput.ReadToEndAsync(); $null = $proc.StandardError.ReadToEndAsync()
    if (-not $proc.WaitForExit(120000)) { $proc.Kill($true); throw 'the provider did not finish in 120 seconds' }
}

function Get-RepoStoreSnapshot {
    # The repo's own approval, authority and journal stores. The suite must leave every one of them as it found it.
    $paths = @('.specrew\review\round-approval', '.specrew\authority', '.specrew\runtime\handover-journal.jsonl', '.specrew\runtime\conformance-sessions')
    foreach ($rel in $paths) {
        $full = Join-Path $repoRoot $rel
        if (-not (Test-Path -LiteralPath $full)) { "$rel <absent>"; continue }
        foreach ($f in @(Get-ChildItem -LiteralPath $full -Recurse -File -Force -ErrorAction SilentlyContinue) + @(Get-Item -LiteralPath $full | Where-Object { -not $_.PSIsContainer })) {
            '{0} {1}' -f $f.FullName.Substring($repoRoot.Length), (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
        }
    }
}

function Invoke-Chain {
    # The deployed hook, then the real provider on the arguments the dispatcher gave the handover provider.
    param($Fixture, [string]$NativeEvent, [byte[]]$Payload)
    Clear-HarnessRuntime $Fixture
    $r = Invoke-DeployedHook -Fixture $Fixture -NativeEvent $NativeEvent -StdinBytes $Payload
    $handover = $r.Calls['specrew-handover-provider.ps1']
    $root = New-ApprovalProject
    $origin = $null
    if ($null -ne $handover) {
        $argv = @($handover | ForEach-Object { [string]$_ })
        for ($i = 0; $i -lt $argv.Count - 1; $i++) {
            if ($argv[$i] -ceq '--project-root') { $argv[$i + 1] = $root }
            if ($argv[$i] -ceq '--turn-origin') { $origin = $argv[$i + 1] }
        }
        # The dispatcher passes no --project-root, so the provider would resolve its root from its working
        # directory and the host's project variables: run from the repo, it writes into the repo's own stores
        # (DRIFT-007, B4F-148). Pin all three to the temp project.
        if ($argv -cnotcontains '--project-root') { $argv += @('--project-root', $root) }
        Invoke-PinnedProvider -Root $root -Arguments $argv
    }
    return [pscustomobject]@{ Ran = ($null -ne $handover); Origin = $origin; Stored = (Test-RoundApprovalStored -Root $root); Root = $root
        Unrecognized = @(Get-HarnessUnrecognizedLogs $Fixture).Count }
}

$projects = @{}
$roots = New-Object System.Collections.Generic.List[string]
$repoStoresBefore = @(Get-RepoStoreSnapshot)
try {
    foreach ($h in 'claude', 'copilot') { $projects[$h] = New-TurnRecordProject -HostKind $h }

    $cases = @(
        # Copilot's own channel: the recorded sub-agent prompt, and a typed prompt given one sub-agent field at a time.
        @{ Name = 'copilot channel: the recorded sub-agent prompt'; Target = 'copilot'; Event = 'userPromptSubmitted'; Channel = 'copilot'; Fixture = 'probe-userpromptsubmitted-subagent-1.json' }
        @{ Name = 'copilot channel: agentId alone'; Target = 'copilot'; Event = 'userPromptSubmitted'; Channel = 'copilot'; Fixture = 'probe-userpromptsubmitted-1.json'; Add = @{ agentId = 'a1' } }
        @{ Name = 'copilot channel: parentAgentId alone'; Target = 'copilot'; Event = 'userPromptSubmitted'; Channel = 'copilot'; Fixture = 'probe-userpromptsubmitted-1.json'; Add = @{ parentAgentId = 'p1' } }
        @{ Name = 'copilot channel: agent_id alone'; Target = 'copilot'; Event = 'userPromptSubmitted'; Channel = 'copilot'; Fixture = 'probe-userpromptsubmitted-1.json'; Add = @{ agent_id = 'a1' } }
        @{ Name = 'copilot channel: parent_agent_id alone'; Target = 'copilot'; Event = 'userPromptSubmitted'; Channel = 'copilot'; Fixture = 'probe-userpromptsubmitted-1.json'; Add = @{ parent_agent_id = 'p1' } }
        # The Claude channel, as Copilot runs Claude's hooks.
        @{ Name = 'Claude channel under Copilot: the recorded sub-agent prompt'; Target = 'claude'; Event = 'UserPromptSubmit'; Channel = 'copilot-claude-hooks'; Fixture = 'probe-userpromptsubmit-subagent-1.json' }
        @{ Name = 'Claude channel under Copilot: agent_id alone'; Target = 'claude'; Event = 'UserPromptSubmit'; Channel = 'copilot-claude-hooks'; Fixture = 'probe-userpromptsubmit-1.json'; Add = @{ agent_id = 'a1' } }
        @{ Name = 'Claude channel under Copilot: parent_agent_id alone'; Target = 'claude'; Event = 'UserPromptSubmit'; Channel = 'copilot-claude-hooks'; Fixture = 'probe-userpromptsubmit-1.json'; Add = @{ parent_agent_id = 'p1' } }
        # Claude Code's own channel sends no prompt event for a sub-agent today; if it ever does, the same rule holds.
        @{ Name = 'Claude channel: agent_id alone'; Target = 'claude'; Event = 'UserPromptSubmit'; Channel = 'claude'; Fixture = 'probe-userpromptsubmit-1.json'; Add = @{ agent_id = 'a1' } }
        @{ Name = 'Claude channel: parent_agent_id alone'; Target = 'claude'; Event = 'UserPromptSubmit'; Channel = 'claude'; Fixture = 'probe-userpromptsubmit-1.json'; Add = @{ parent_agent_id = 'p1' } }
    )
    foreach ($case in $cases) {
        $add = if ($case.ContainsKey('Add')) { $case.Add } else { @{} }
        $r = Invoke-Chain -Fixture $projects[$case.Target] -NativeEvent $case.Event -Payload (New-Payload -Channel $case.Channel -Fixture $case.Fixture -Add $add)
        $roots.Add($r.Root) | Out-Null
        $how = if ($r.Ran) { "origin $($r.Origin)" } else { 'the hook stood down' }
        Assert-True (-not $r.Stored) ("[{0}] '{1}' records no approval ({2})" -f $case.Name, $approval, $how)
        Assert-True ($r.Unrecognized -eq 0) ("[{0}] the payload is recognized (no unrecognized-payload record)" -f $case.Name)
        if ($r.Ran) { Assert-True ($r.Origin -ne 'typed-user') ("[{0}] the dispatcher does not call it typed by the human" -f $case.Name) }
    }

    # Controls: the same chain, without any sub-agent field, stores the approval the human typed.
    $controls = @(
        @{ Name = 'copilot channel, typed'; Target = 'copilot'; Event = 'userPromptSubmitted'; Channel = 'copilot'; Fixture = 'probe-userpromptsubmitted-1.json' }
        @{ Name = 'Claude channel, typed'; Target = 'claude'; Event = 'UserPromptSubmit'; Channel = 'claude'; Fixture = 'probe-userpromptsubmit-1.json' }
    )
    foreach ($case in $controls) {
        $r = Invoke-Chain -Fixture $projects[$case.Target] -NativeEvent $case.Event -Payload (New-Payload -Channel $case.Channel -Fixture $case.Fixture)
        $roots.Add($r.Root) | Out-Null
        Assert-True ($r.Ran -and $r.Origin -eq 'typed-user') ("[control: {0}] the human's typed prompt reaches the provider as typed-user (got {1})" -f $case.Name, $r.Origin)
        Assert-True $r.Stored ("[control: {0}] and '{1}' is stored" -f $case.Name, $approval)
    }
}
finally {
    $storeChanges = @(Compare-Object -ReferenceObject $repoStoresBefore -DifferenceObject @(Get-RepoStoreSnapshot))
    Assert-True ($storeChanges.Count -eq 0) ("the repo's own approval, authority and journal stores are unchanged ({0} difference(s))" -f $storeChanges.Count)
    foreach ($c in $storeChanges) { Write-Host "  $($c.SideIndicator) $($c.InputObject)" }
    foreach ($p in $projects.Values) { if ($p -and (Test-Path -LiteralPath $p.Base)) { Remove-Item -LiteralPath $p.Base -Recurse -Force -ErrorAction SilentlyContinue } }
    foreach ($root in $roots) { if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue } }
}

if ($script:failCount -gt 0) { Write-Host "subagent-prompt-authority: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'subagent-prompt-authority: all assertions pass' -ForegroundColor Green
exit 0

#requires -Version 7.0
# Feature 202 T008 (FR-014, SC-003, DA-3; B4F-096): the orientation reaches the human before the first question.
#
# The bootstrap provider supplies the FINISHED orientation with the session's first prompt, marked as system output
# (the dispatcher journals every provider's output). The Stop never demands it afterwards. On a host that shows hook
# output to the human directly, the agent is told not to repeat it. The "bootstrap delivered" check reads only this
# session's render claim.
#
# Driven through the real bootstrap and conformance providers, with the standard turn record the dispatcher passes.
#
# Cases:
#   1. The catalog binds the bootstrap provider to the prompt event (both copies).
#   2. The first prompt carries the finished orientation: real version, host, feature, the pending decision and its
#      approval phrase, the artifacts link and the dials line - and the instruction to show it as written.
#   3. Once per session: the second prompt carries nothing, and the conformance lane adds no second dials line.
#   4. A host flagged for direct display gets the orientation with no instruction to repeat it.
#   5. B4F-096 replay: a reply that asks the first question without the orientation is not blocked at Stop.
#   6. Another session's bootstrap does not count as this session's.
#
# RED: run with SPECREW_T008_SCRIPTS_ROOT pointing at the pre-T008 scripts; cases 1, 2, 4, 5 and 6 fail there.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scriptsRoot = if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_T008_SCRIPTS_ROOT)) { $env:SPECREW_T008_SCRIPTS_ROOT } else { Join-Path $repoRoot 'extensions\specrew-speckit\scripts' }
$catalogRoot = Split-Path -Parent $scriptsRoot
$bootstrap = Join-Path $scriptsRoot 'specrew-bootstrap-provider.ps1'
$provider = Join-Path $scriptsRoot 'specrew-conformance-provider.ps1'
$declare = Join-Path $scriptsRoot 'declare-turn-end.ps1'
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
Get-ChildItem (Join-Path $repoRoot 'scripts\internal\bootstrap\*.ps1') | ForEach-Object { . $_.FullName }
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\turn-end-store.ps1')
$savedModulePath = $env:SPECREW_MODULE_PATH
$savedProfilePath = $env:SPECREW_USER_PROFILE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot
$script:failCount = 0

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-PendingProject {
    param([switch]$NoPendingDecision)
    $root = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ("t008-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    $feature = Join-Path $root 'specs/001-feat'
    $iter = Join-Path $feature 'iterations/001'
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew/runtime') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $iter 'quality') | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'plan.md') -Value "# Iteration Plan: 001`n`n**Status**: executing" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'state.md') -Value "# Iteration State: 001`n`n**Current Phase**: tasks" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'quality/hardening-gate.md') -Value "# Hardening Gate`n`n**Overall Verdict**: ready" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    & git -C $root init -q -b main
    & git -C $root config user.email 't@t'
    & git -C $root config user.name 't'
    & git -C $root config core.autocrlf false
    & git -C $root add -A
    & git -C $root commit -q -m fixture
    $head = ([string](& git -C $root rev-parse HEAD)).Trim()
    $ctx = [ordered]@{
        schema = 'v2'
        feature_path = $feature
        session_state = [ordered]@{ active = $true; boundary_type = 'before-implement'; feature_ref = '001-feat'; host = 'claude'; iteration_number = '001'; auth_commit_hash = $head; recorded_at = '2026-10-14T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [System.IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    if ($NoPendingDecision) {
        # The workshop shape B4F-096 was recorded in: nothing is waiting for a decision (working == last approved).
        $ctx.boundary_enforcement.last_authorized_boundary = 'before-implement'
        [System.IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
        return [pscustomobject]@{ Root = $root; Feature = $feature; Profile = $null }
    }
    $tree = Get-SpecrewGitArtifactStateId -ProjectRoot $root -BoundaryCommitHash $head
    $scope = New-SpecrewPendingCrossingScope -LastAuthorizedBoundary 'tasks' -WorkingBoundary 'before-implement' -BoundaryCommitHash $head -ArtifactStateId $tree -RecordedAt '2026-10-14T00:00:01Z' -ExistingScope $null
    $st = Get-SpecrewBoundaryEnforcementState -ProjectRoot $root
    $upd = [ordered]@{ enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = [string]$scope['to_boundary']; pending_crossing = $scope; verdict_history = @(); correction_history = @(); bypass_history = @() }
    Set-SpecrewBoundaryEnforcementState -ProjectRoot $root -BoundaryEnforcement $upd -Context $st.Context | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $root '.specrew/runtime/pending-verdict-stop.md'), (@('# Specrew Pending Verdict Stop', '', 'Boundary to ask for: tasks -> before-implement', 'Human approval phrase: approved for before-implement', 'Marker last line exactly:', '<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->') -join "`n"), [System.Text.UTF8Encoding]::new($false))
    $profilePath = Join-Path $root 'user-profile.yml'
    [System.IO.File]::WriteAllText($profilePath, "expertise:`n  product_strategy: 3`n  software_architecture: 5`n", [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Root = $root; Feature = $feature; Profile = $profilePath }
}

function Invoke-Pwsh {
    param([string]$Root, [string]$Script, [string[]]$Arguments)
    Push-Location -LiteralPath $Root
    try { return (@(& pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script @Arguments 2>&1) -join "`n") }
    finally { Pop-Location }
}

function Invoke-BootstrapPrompt {
    # The prompt event as the dispatcher hands it to the bootstrap provider: the standard turn record, base64 JSON.
    param($Project, [string]$Session, [string]$HostBinding)
    $record = [ordered]@{ schema = 'specrew-turn-record/v1'; event = 'UserPromptSubmit'; host = 'claude'; session_id = $Session; safe_session_id = $Session; source = $null; origin = 'typed-user'; transcript_path = $null; stop_hook_active = $false }
    $encoded = [Convert]::ToBase64String([Text.UTF8Encoding]::new($false).GetBytes(($record | ConvertTo-Json -Compress)))
    $arguments = @('--turn-record', $encoded, '--host-kind', 'claude', '--source-event', 'UserPromptSubmit', '--project-root', $Project.Root)
    if (-not [string]::IsNullOrWhiteSpace($HostBinding)) { $arguments += @('--host-binding', $HostBinding) }
    return (Invoke-Pwsh -Root $Project.Root -Script $bootstrap -Arguments $arguments)
}

$script:Turn = 0
function Invoke-StopWithReply {
    param($Project, [string]$Session, [string]$Reply)
    $start = Invoke-Pwsh -Root $Project.Root -Script $provider -Arguments @('--host-kind', 'claude', '--source-event', 'UserPromptSubmit', '--session-id', $Session, '--last-user-message', 'Build me a link checker.', '--turn-origin', 'typed-user')
    $m = [regex]::Match($start, '-Token\s+([0-9a-f]{16,})')
    $script:Turn++
    $draftPath = Join-Path $Project.Root (".specrew/runtime/draft-{0}.md" -f $script:Turn)
    [System.IO.File]::WriteAllText($draftPath, $Reply, [System.Text.UTF8Encoding]::new($false))
    $null = Invoke-Pwsh -Root $Project.Root -Script $declare -Arguments @('-Kind', 'conversational', '-MessagePath', $draftPath, '-Summary', 'first question', '-Token', $(if ($m.Success) { $m.Groups[1].Value } else { '' }))
    $transcript = Join-Path $Project.Root (".specrew/runtime/transcript-{0}.jsonl" -f $script:Turn)
    $lines = @(
        ([pscustomobject]@{ type = 'user'; message = [pscustomobject]@{ role = 'user'; content = @([pscustomobject]@{ type = 'text'; text = 'Build me a link checker.' }) } } | ConvertTo-Json -Depth 8 -Compress),
        ([pscustomobject]@{ type = 'assistant'; message = [pscustomobject]@{ role = 'assistant'; content = @([pscustomobject]@{ type = 'text'; text = $Reply }) } } | ConvertTo-Json -Depth 8 -Compress)
    )
    [System.IO.File]::WriteAllLines($transcript, [string[]]$lines, [System.Text.UTF8Encoding]::new($false))
    $out = Invoke-Pwsh -Root $Project.Root -Script $provider -Arguments @('--host-kind', 'claude', '--source-event', 'Stop', '--session-id', $Session, '--transcript-path', $transcript)
    return [pscustomobject]@{ Blocked = ($out -match '<<<SPECREW-STOP-BLOCK>>>'); Output = $out; Start = $start }
}

$projects = [System.Collections.Generic.List[object]]::new()
try {
    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 1: the catalog binds the bootstrap provider to the prompt event'
    foreach ($catalogPath in @((Join-Path $catalogRoot 'refocus-scopes.json'), (Join-Path $repoRoot '.specify\extensions\specrew-speckit\refocus-scopes.json'))) {
        $entry = @((Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json).providers | Where-Object { $_.id -eq 'bootstrap' })
        Assert-True ($entry.Count -eq 1 -and @($entry[0].events) -contains 'UserPromptSubmit') ("{0}: bootstrap runs on UserPromptSubmit" -f $catalogPath.Substring($repoRoot.Length).TrimStart('\'))
    }

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 2: the first prompt carries the finished orientation'
    $p = New-PendingProject; $projects.Add($p)
    $env:SPECREW_USER_PROFILE_PATH = $p.Profile
    $first = Invoke-BootstrapPrompt -Project $p -Session 'sess-o'
    $featureUrl = ([System.Uri]::new($p.Feature + [IO.Path]::DirectorySeparatorChar)).AbsoluteUri
    Assert-True ($first.TrimStart().StartsWith('[specrew-system]')) 'marked as system output'
    Assert-True ($first -match 'Show it to the human as written, at the start of this reply and before any question') 'the agent is told to show it as written, first'
    Assert-True ($first -match 'Specrew is active here\. It writes down what you want before anything is built') 'it opens in plain words'
    Assert-True ($first -match '- Version and host: Specrew \d+\.\d+\.\d+' -and $first -match 'running on Claude Code') 'it names the real version and host'
    Assert-True ($first -match "feature 001-feat is waiting for your decision on 'before-implement'\. When you are ready, type: approved for before-implement") 'it states the pending decision and its approval phrase'
    Assert-True ($first.Contains($featureUrl)) 'it links the feature''s artifacts'
    Assert-True ($first.Contains('How I am adapting to you: product_strategy=3, software_architecture=5; correct me if that is wrong.')) 'it carries the dials line'
    Assert-True ($first -notmatch '<one specific action|<project-root-url>|<feature-id>') 'nothing is left for the agent to fill in'
    foreach ($noun in 'crossing', 'marker', 'verdict capture', 'controller') { Assert-True ($first -notmatch ('(?i)\b' + [regex]::Escape($noun) + '\b')) ("no internal noun '{0}' reaches the human" -f $noun) }

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 3: once per session, and no second dials line'
    # The stamp the dispatcher checks to skip launching the provider on every later prompt (named by session).
    Assert-True (Test-Path -LiteralPath (Join-Path $p.Root '.specrew/runtime/hook-bootstrap-orientation-sess-o.json') -PathType Leaf) 'the supply leaves the per-session stamp the dispatcher skips on'
    $dispatcherText = Get-Content -LiteralPath (Join-Path $scriptsRoot 'specrew-hook-dispatcher.ps1') -Raw
    Assert-True ($dispatcherText -match "providerId -eq 'bootstrap' -and \`$Event -eq 'UserPromptSubmit'" -and $dispatcherText.Contains('hook-bootstrap-orientation-{0}.json')) 'the dispatcher skips the bootstrap on a prompt once that stamp exists'
    $second = Invoke-BootstrapPrompt -Project $p -Session 'sess-o'
    Assert-True ([string]::IsNullOrWhiteSpace($second)) 'the second prompt carries nothing'
    $conformanceStart = Invoke-Pwsh -Root $p.Root -Script $provider -Arguments @('--host-kind', 'claude', '--source-event', 'UserPromptSubmit', '--session-id', 'sess-o', '--last-user-message', 'Hi.', '--turn-origin', 'typed-user')
    Assert-True ($conformanceStart -notmatch 'How I am adapting to you') 'the conformance lane does not add the dials line again'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 4: a host that shows hook output directly gets no instruction to repeat it'
    $binding = [Convert]::ToBase64String([Text.UTF8Encoding]::new($false).GetBytes((@{ HookOutputDirectDisplay = $true } | ConvertTo-Json -Compress)))
    $direct = Invoke-BootstrapPrompt -Project $p -Session 'sess-d' -HostBinding $binding
    Assert-True ($direct -match 'shown to the human directly, so the assistant does not repeat it' -and $direct -notmatch 'Show it to the human as written') 'direct display: shown once, by the host, not again by the agent'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 5: B4F-096 replay - the first question without the orientation is not blocked'
    $w = New-PendingProject -NoPendingDecision; $projects.Add($w)
    $pv5 = Get-SpecrewPendingVerdictState -ProjectRoot $w.Root
    Assert-True (-not [bool]$pv5.HasPendingVerdict) 'the replay fixture has nothing waiting for a decision, as in the recorded B4F-096 shape'
    [System.IO.File]::WriteAllText((Join-Path $w.Root '.specrew/runtime/hook-bootstrap-render-sess-w-startup.json'), '{"rendered":true}', [System.Text.UTF8Encoding]::new($false))
    $question = 'Before I design anything: who will run this checker, and on how many Markdown files at a time?'
    $r5 = Invoke-StopWithReply -Project $w -Session 'sess-w' -Reply $question
    Assert-True (-not $r5.Blocked) 'the Stop asks for nothing: 0 corrective exchanges, 0 extra Stop blocks'
    Assert-True ($r5.Output -notmatch '(?i)orientation') 'and names no orientation demand'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 6: another session''s bootstrap is not this session''s'
    $q = New-PendingProject -NoPendingDecision; $projects.Add($q)
    [System.IO.File]::WriteAllText((Join-Path $q.Root '.specrew/runtime/hook-bootstrap-render-sess-other-startup.json'), '{"rendered":true}', [System.Text.UTF8Encoding]::new($false))
    $shown = 'Specrew 0.40.0-beta4 is active here, on Claude Code. What I know about you: expert on architecture.'
    $null = Invoke-StopWithReply -Project $q -Session 'sess-mine' -Reply $shown
    $mine = Get-SpecrewTurnEndPaths -ProjectRoot $q.Root -HostKind 'claude' -SessionId 'sess-mine'
    Assert-True (-not (Test-Path -LiteralPath $mine.OrientationPath -PathType Leaf)) 'no orientation receipt is credited to a session that was never handed a bootstrap'
}
finally {
    foreach ($px in $projects) { try { Remove-Item -LiteralPath $px.Root -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
    $env:SPECREW_MODULE_PATH = $savedModulePath
    $env:SPECREW_USER_PROFILE_PATH = $savedProfilePath
}
if ($script:failCount -gt 0) { throw ("orientation-order: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'orientation-order: all assertions passed' -ForegroundColor Green

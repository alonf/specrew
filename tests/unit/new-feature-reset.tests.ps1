#requires -Version 7.0
# Feature 202 T011 (FR-026, SC-006, SC-009; B4F-109): a new feature after a closed one is a new cycle.
#
# One cycle-reset rule (Get-SpecrewBoundaryCycleReset) serves the crossing deriver and the authorization writer: after
# an authorized feature-closeout, a DIFFERENT feature's specify opens feature-closeout -> specify. New ledger entries
# and crossings carry feature_ref; legacy entries are never rewritten; the review-coverage line reads only the
# resolved feature's campaigns.
#
# Driven through the real boundary sync (the .specify wrapper) and the real prompt-time verdict capture.
#
# Cases:
#   1. A second feature's specify sync, after the first feature's closeout, opens feature-closeout -> specify, and
#      the crossing names the new feature.
#   2. The human's typed verdict is captured against it: specify is authorized, with 0 out-of-band entries, and the
#      new entry names the new feature.
#   3. Append-only: every legacy entry is byte-identical afterwards; `auth-83b0f0c2...`-style out-of-band entries
#      stay exactly as recorded.
#   4. The rule: a re-sync of the SAME closed feature is not a reset; the iteration loop still is; a plain backward
#      move is still refused by the writer.
#   5. The coverage line names 0 campaigns of the closed feature (SC-009).
#
# RED: run with SPECREW_T011_ROOT pointing at a pre-T011 module tree; cases 1, 2 and 5 fail there.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$moduleRoot = if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_T011_ROOT)) { $env:SPECREW_T011_ROOT } else { $repoRoot }
$syncWrapper = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
$handover = Join-Path $moduleRoot 'scripts\internal\specrew-handover-provider.ps1'
. (Join-Path $moduleRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
$savedModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $moduleRoot
$script:failCount = 0

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }
function Write-Utf8 { param([string]$Path, [string]$Text) New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null; [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false)) }

$legacyHistory = @(
    [ordered]@{ from_boundary = 'iteration-closeout'; to_boundary = 'feature-closeout'; verdict_text = 'approved for feature-closeout'; authorizing_human = 'unattributed'; recorded_at = '2026-09-08T22:37:33Z'; auth_commit_hash = $null; evidence_source = 'hook-captured-from-transcript'; kind = 'standard'; out_of_band = $false }
)

function New-ClosedProject {
    # 001-old closed at feature-closeout (a legacy ledger entry that does not name its feature); 002-new scaffolded.
    $root = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ("t011-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    foreach ($dir in '.specrew', '.specify', '.squad', '.github\agents', 'specs\001-old', 'specs\002-new') { New-Item -ItemType Directory -Force -Path (Join-Path $root $dir) | Out-Null }
    Write-Utf8 (Join-Path $root '.specrew\config.yml') "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n"
    Write-Utf8 (Join-Path $root '.specify\feature.json') "{`n  `"feature_directory`": `"`"`n}"
    Write-Utf8 (Join-Path $root '.squad\team.md') "# Team`n"
    Write-Utf8 (Join-Path $root '.squad\config.json') "{}`n"
    Write-Utf8 (Join-Path $root '.squad\decisions.md') "# Decisions`n"
    Write-Utf8 (Join-Path $root '.github\agents\squad.agent.md') "# Squad Agent`n"
    Write-Utf8 (Join-Path $root 'specs\001-old\spec.md') "# Spec: old`n`n**Status**: shipped`n"
    Write-Utf8 (Join-Path $root 'specs\002-new\spec.md') "# Spec: new`n`n## Clarifications`n`n### Session 2026-10-14 (clarify)`n`n- Q: fixture question? -> A: fixture answer.`n"
    Write-Utf8 (Join-Path $root 'README.md') "# Test Repo`n"
    Write-Utf8 (Join-Path $root '.gitignore') ".specrew/runtime/`n"
    $history = @($legacyHistory | ForEach-Object { $e = [ordered]@{}; foreach ($k in $_.Keys) { $e[$k] = $_[$k] }; $e['authorization_id'] = Get-SpecrewBoundaryAuthorizationEntryId -Entry $e; $e })
    $context = [ordered]@{
        schema = 'v2'
        feature_path = Join-Path $root 'specs\001-old'
        generated_at_utc = '2026-09-08T22:37:33Z'
        session_state = [ordered]@{ active = $false; boundary_type = 'feature-closeout'; feature_ref = '001-old'; feature_path = (Join-Path $root 'specs\001-old'); iteration_number = '001'; task_id = $null; auth_commit_hash = $null; recorded_at = '2026-09-08T22:37:33Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'feature-closeout'; pending_next_boundary = $null; pending_crossing = $null; verdict_history = $history; correction_history = @(); bypass_history = @() }
    }
    Write-Utf8 (Join-Path $root '.specrew\start-context.json') ($context | ConvertTo-Json -Depth 12)
    & git -C $root init -q -b main
    & git -C $root add -A
    & git -C $root -c user.email=t@t -c user.name=t commit -q -m seed
    & git -C $root checkout -q -b 002-new
    return $root
}

function Get-Context { param([string]$Root) return (Get-Content -LiteralPath (Join-Path $Root '.specrew\start-context.json') -Raw | ConvertFrom-Json -AsHashtable -Depth 20) }

$roots = [System.Collections.Generic.List[string]]::new()
try {
    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 1: the second feature''s specify sync opens feature-closeout -> specify'
    $root = New-ClosedProject; $roots.Add($root)
    $legacyBefore = @((Get-Context $root)['boundary_enforcement']['verdict_history'] | ForEach-Object { $_ | ConvertTo-Json -Depth 8 -Compress })
    $sync = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $syncWrapper -ProjectPath $root -BoundaryType 'specify' -FeatureRef '002-new' -AuthCommitHash 'HEAD' 2>&1)
    Assert-True ($LASTEXITCODE -eq 0) ("the specify sync succeeds (exit {0}{1})" -f $LASTEXITCODE, $(if ($LASTEXITCODE -ne 0) { ': ' + (($sync | Select-Object -Last 3) -join ' | ') } else { '' }))
    $scope = (Get-Context $root)['boundary_enforcement']['pending_crossing']
    $scopeFrom = if ($null -ne $scope) { [string]$scope['from_boundary'] } else { '' }
    $scopeTo = if ($null -ne $scope) { [string]$scope['to_boundary'] } else { '' }
    Assert-True ($scopeFrom -eq 'feature-closeout' -and $scopeTo -eq 'specify') ("a crossing opens: feature-closeout -> specify (got '{0}' -> '{1}')" -f $scopeFrom, $scopeTo)
    Assert-True ($null -ne $scope -and $scope.Contains('feature_ref') -and [string]$scope['feature_ref'] -eq '002-new') 'the crossing names the new feature'
    $stopPath = Join-Path $root '.specrew\runtime\pending-verdict-stop.md'
    $stopText = if (Test-Path -LiteralPath $stopPath) { Get-Content -LiteralPath $stopPath -Raw } else { '' }
    Assert-True ($stopText -match 'Boundary to ask for: feature-closeout -> specify' -and $stopText -match 'Human approval phrase: approved for specify') 'the stop artifact asks for this crossing'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 2: the typed verdict is captured, with 0 out-of-band entries'
    $marker = ([regex]::Match($stopText, '<!--\s*SPECREW-VERDICT-BOUNDARY:[^\r\n]*-->')).Value
    $packet = "## What I Just Did`n`nWrote the spec for 002-new.`n`n## Why I Stopped`n`nThe specify boundary needs your verdict. My recommendation: approve.`n`n## What Needs Your Review`n`nThe spec: file:///$($root.Replace('\','/'))/specs/002-new/spec.md`n`n## What Happens Next`n`nClarify starts on approval.`n`n## Discussion Prompts`n`n1. Is the scope right?`n`n## What I Need From You`n`nWhat would you like to do? Type one of these:`n`n  approved for specify`n  changes needed: <what to change>`n`n$marker"
    $transcript = Join-Path $root '.specrew\runtime\capture.jsonl'
    $lines = @(
        ([pscustomobject]@{ type = 'assistant'; message = [pscustomobject]@{ role = 'assistant'; content = @([pscustomobject]@{ type = 'text'; text = $packet }) } } | ConvertTo-Json -Depth 8 -Compress),
        ([pscustomobject]@{ type = 'user'; message = [pscustomobject]@{ role = 'user'; content = @([pscustomobject]@{ type = 'text'; text = 'approved for specify' }) } } | ConvertTo-Json -Depth 8 -Compress)
    )
    Write-Utf8 $transcript (($lines -join "`n") + "`n")
    $null = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $handover --project-root $root --host-kind claude --source-event UserPromptSubmit --session-id t011 --transcript-path $transcript --last-user-message 'approved for specify' --turn-origin typed-user 2>&1)
    $after = Get-Context $root
    $enforcement = $after['boundary_enforcement']
    Assert-True ([string]$enforcement['last_authorized_boundary'] -eq 'specify') ("specify is authorized (last authorized: {0})" -f $enforcement['last_authorized_boundary'])
    $history = @($enforcement['verdict_history'])
    $newest = $history[$history.Count - 1]
    Assert-True ($history.Count -eq ($legacyBefore.Count + 1) -and [string]$newest['to_boundary'] -eq 'specify' -and [string]$newest['from_boundary'] -eq 'feature-closeout') 'one new entry: feature-closeout -> specify'
    Assert-True (-not [bool]$newest['out_of_band'] -and @($enforcement['bypass_history']).Count -eq 0) 'captured, not out of band: 0 out-of-band entries'
    Assert-True ($newest.Contains('feature_ref') -and [string]$newest['feature_ref'] -eq '002-new') 'the new entry names the new feature'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 3: append-only'
    $legacyAfter = @($history | Select-Object -First $legacyBefore.Count | ForEach-Object { $_ | ConvertTo-Json -Depth 8 -Compress })
    Assert-True (($legacyAfter -join "`n") -ceq ($legacyBefore -join "`n")) 'every legacy entry is byte-identical afterwards'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 4: the rule'
    . (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
    Assert-True (-not [bool](Get-SpecrewBoundaryCycleReset -LastAuthorizedBoundary 'feature-closeout' -WorkingBoundary 'specify' -ClosedFeatureRef '001-old' -WorkingFeatureRef '001-old').IsReset) 'a re-sync of the SAME closed feature is not a reset'
    $iter = Get-SpecrewBoundaryCycleReset -LastAuthorizedBoundary 'iteration-closeout' -WorkingBoundary 'plan'
    Assert-True ([bool]$iter.IsReset -and $iter.Kind -eq 'iteration' -and $iter.FromBoundary -eq 'iteration-closeout' -and $iter.ToBoundary -eq 'plan') 'the iteration loop is still a reset, from the same rule'
    $backward = New-ClosedProject; $roots.Add($backward)
    $ctx = Get-Context $backward
    $ctx['boundary_enforcement']['last_authorized_boundary'] = 'plan'
    $ctx['session_state']['feature_ref'] = '002-new'
    Write-Utf8 (Join-Path $backward '.specrew\start-context.json') ($ctx | ConvertTo-Json -Depth 12)
    $refused = $false
    try { $null = Add-SpecrewBoundaryAuthorization -ProjectRoot $backward -CurrentBoundary 'plan' -AuthorizedBoundary 'specify' -AuthorizingHuman 'human' -VerdictText 'approved for specify' -EvidenceSource 'hook-captured-from-transcript' }
    catch { $refused = $_.Exception.Message -match 'moves backward' }
    Assert-True $refused 'a plain backward move (plan -> specify, no closeout) is still refused'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 5: the coverage line reads only the resolved feature''s campaigns (SC-009)'
    $cov = New-ClosedProject; $roots.Add($cov)
    $ctx = Get-Context $cov
    $ctx['session_state']['active'] = $true
    $ctx['session_state']['feature_ref'] = '002-new'
    $ctx['session_state']['boundary_type'] = 'clarify'
    $ctx['boundary_enforcement']['last_authorized_boundary'] = 'specify'
    Write-Utf8 (Join-Path $cov '.specrew\start-context.json') ($ctx | ConvertTo-Json -Depth 12)
    $runDir = Join-Path $cov '.specrew\review\authority\campaigns\cmp-001-old-i002\runs\run-20260908-000000001-aaaaaaaa'
    $result = [ordered]@{ schema_version = '1.0'; campaign_id = 'cmp-001-old-i002'; run_id = 'run-20260908-000000001-aaaaaaaa'; target_digest = ('a' * 40); completion = 'complete'; verdict = 'pass'; ended_at = '2026-09-08T00:01:00Z'; findings = @() }
    Write-Utf8 (Join-Path $runDir 'result.json') ($result | ConvertTo-Json -Depth 5)
    . (Join-Path $moduleRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
    $line = ''
    try { $line = [string](Get-SpecrewReviewCoverageLine -ProjectRoot $cov) } catch { $line = '' }
    $state = $null
    try { $state = Get-SpecrewReviewCoverageState -ProjectRoot $cov } catch { $state = $null }
    $stateCampaign = if ($null -ne $state) { [string]$state.campaign_id } else { '' }
    Assert-True ($line -notmatch 'cmp-001-old' -and $stateCampaign -notmatch 'cmp-001-old') ("the coverage line and state name 0 campaigns of the closed feature (state campaign: '{0}')" -f $stateCampaign)

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 6 (DRIFT-006): readiness never counts the previous feature''s cycle'
    # 202's own shape: the previous feature closed, then the new feature authorized specify through tasks, and no
    # before-implement verdict yet. The readiness line said READY on the closed feature's feature-closeout.
    $ready = New-ClosedProject; $roots.Add($ready)
    $ctx = Get-Context $ready
    $hist = [System.Collections.Generic.List[object]]::new()
    foreach ($e in @($ctx['boundary_enforcement']['verdict_history'])) { $hist.Add($e) }
    $prev = 'feature-closeout'
    foreach ($to in 'specify', 'clarify', 'plan', 'tasks') {
        $hist.Add([ordered]@{ from_boundary = $prev; to_boundary = $to; verdict_text = "approved for $to"; authorizing_human = 'human'; recorded_at = '2026-10-13T12:00:00Z'; auth_commit_hash = $null; evidence_source = 'hook-captured-from-transcript'; kind = 'standard'; out_of_band = $false; feature_ref = '002-new' })
        $prev = $to
    }
    $ctx['boundary_enforcement']['verdict_history'] = $hist.ToArray()
    $ctx['boundary_enforcement']['last_authorized_boundary'] = 'tasks'
    Write-Utf8 (Join-Path $ready '.specrew\start-context.json') ($ctx | ConvertTo-Json -Depth 12)
    $readiness = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $moduleRoot 'extensions\specrew-speckit\scripts\readiness-verdict.ps1') -ProjectPath $ready -Boundary 'before-implement' 2>&1) -join ' ')
    Assert-True ($readiness -match 'Overall verdict: BLOCKED for implementation' -and $readiness -notmatch 'feature-closeout') ("before its before-implement verdict, the new feature is BLOCKED, not READY on the closed feature's cycle ({0})" -f $readiness.Substring(0, [Math]::Min(140, $readiness.Length)))
}
finally {
    foreach ($r in $roots) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue }
    $env:SPECREW_MODULE_PATH = $savedModulePath
}
if ($script:failCount -gt 0) { throw ("new-feature-reset: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'new-feature-reset: all assertions passed' -ForegroundColor Green

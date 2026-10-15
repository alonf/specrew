#requires -Version 7.0
# B4F-116, the dangerous direction (maintainer instruction 2026-10-15, before any implement or review boundary stop):
# with the review decision PENDING - in ledger terms before-implement -> review-signoff, the decision at 202's sign-off -
# the human's typed round approval "approved for review round" must never be recorded as a boundary verdict. Only the
# review-round authority may take that phrase. With no decision pending, the classifier misreads it harmlessly ("nothing
# is pending"); with the review decision pending, a capture would be an authorization the human never gave.
#
# Driven through the real prompt-time capture (the handover provider on UserPromptSubmit), against a real pending
# decision built with the shared-governance writers. The phrase and the marker are the ones the real stop writer derives
# from that pending state.
#
# WHY THE CONTROL CHECKS WHERE A REPLY STOPS, NOT ONLY THE LEDGER: this fixture has no review.md and no completed review
# run, so even the real phrase is refused afterwards for absent stage evidence. A ledger-only assertion would then pass
# for the wrong reason. The control proves the real phrase is CAPTURED by the classifier (and refused only by the
# evidence check); every round-phrase case must be turned away BEFORE that - never captured at all.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$handover = Join-Path $repoRoot 'scripts\internal\specrew-handover-provider.ps1'
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
Get-ChildItem (Join-Path $repoRoot 'scripts\internal\bootstrap\*.ps1') | ForEach-Object { . $_.FullName }
$savedModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-ReviewPendingProject {
    # A feature authorized through before-implement, with the review decision (-> review-signoff) pending.
    $root = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ("b4f116-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    $feature = Join-Path $root 'specs/001-feat'
    $iter = Join-Path $feature 'iterations/001'
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew/runtime'), (Join-Path $iter 'quality') | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'plan.md') -Value "# Iteration Plan: 001`n`n**Status**: executing" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'state.md') -Value "# Iteration State: 001`n`n**Current Phase**: implement" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    $null = & git -C $root init -q -b main 2>&1
    $null = & git -C $root config user.email 't@t' 2>&1
    $null = & git -C $root config user.name 't' 2>&1
    $null = & git -C $root config core.autocrlf false 2>&1
    $null = & git -C $root add -A 2>&1
    $null = & git -C $root commit -q -m fixture 2>&1
    $head = ([string](& git -C $root rev-parse HEAD)).Trim()
    $ctx = [ordered]@{
        schema = 'v2'
        feature_path = $feature
        session_state = [ordered]@{ active = $true; boundary_type = 'review-signoff'; feature_ref = '001-feat'; host = 'claude'; iteration_number = '001'; auth_commit_hash = $head; recorded_at = '2026-10-15T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'before-implement'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
    $tree = Get-SpecrewGitArtifactStateId -ProjectRoot $root -BoundaryCommitHash $head
    $scope = New-SpecrewPendingCrossingScope -LastAuthorizedBoundary 'before-implement' -WorkingBoundary 'review-signoff' -BoundaryCommitHash $head -ArtifactStateId $tree -RecordedAt '2026-10-15T00:00:01Z' -ExistingScope $null
    $st = Get-SpecrewBoundaryEnforcementState -ProjectRoot $root
    $upd = [ordered]@{ enabled = $true; last_authorized_boundary = 'before-implement'; pending_next_boundary = [string]$scope['to_boundary']; pending_crossing = $scope; verdict_history = @(); correction_history = @(); bypass_history = @() }
    Set-SpecrewBoundaryEnforcementState -ProjectRoot $root -BoundaryEnforcement $upd -Context $st.Context | Out-Null
    return $root
}

function Get-Enforcement { param([string]$Root) return ((Get-Content -LiteralPath (Join-Path $Root '.specrew/start-context.json') -Raw | ConvertFrom-Json -AsHashtable -Depth 20)['boundary_enforcement']) }

function Send-TypedReply {
    # The packet as a real stop presents it (phrase and marker derived from the pending state exactly as the stop writer
    # derives them), then the human's typed reply, through the real prompt-time capture. Returns the provider's output.
    param([string]$Root, [string]$Text)
    $p = Get-SpecrewPendingVerdictState -ProjectRoot $Root
    $phrase = 'approved for {0}' -f $p.PendingToMarkerBoundary
    $marker = '<!-- SPECREW-VERDICT-BOUNDARY: {0} -> {1} @ {2} -->' -f $p.PendingFromMarkerBoundary, $p.PendingToMarkerBoundary, $p.CrossingId
    $specUrl = ([Uri]::new((Join-Path $Root 'specs/001-feat/spec.md'))).AbsoluteUri
    $packet = "## What I Just Did`n`nImplemented the iteration.`n`n## Why I Stopped`n`nThe review boundary needs your verdict. My recommendation: approve.`n`n## What Needs Your Review`n`nThe spec: $specUrl`n`n## What Happens Next`n`nReview starts on approval.`n`n## Discussion Prompts`n`n1. Anything to change?`n`n## What I Need From You`n`nWhat would you like to do? Type one of these:`n`n  $phrase`n  $phrase - <your instructions>`n  changes needed: <what to change>`n  discuss prompt 1`n`n$marker"
    $transcript = Join-Path $Root ('.specrew/runtime/capture-{0}.jsonl' -f [guid]::NewGuid().ToString('N').Substring(0, 6))
    $lines = @(
        ([pscustomobject]@{ type = 'assistant'; message = [pscustomobject]@{ role = 'assistant'; content = @([pscustomobject]@{ type = 'text'; text = $packet }) } } | ConvertTo-Json -Depth 8 -Compress),
        ([pscustomobject]@{ type = 'user'; message = [pscustomobject]@{ role = 'user'; content = @([pscustomobject]@{ type = 'text'; text = $Text }) } } | ConvertTo-Json -Depth 8 -Compress)
    )
    [IO.File]::WriteAllText($transcript, (($lines -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
    return (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $handover --project-root $Root --host-kind claude --source-event UserPromptSubmit --session-id b4f116 --transcript-path $transcript --last-user-message $Text --turn-origin typed-user 2>&1) -join "`n")
}

$roots = [Collections.Generic.List[string]]::new()
try {
    Write-Host 'Control: the real phrase for the pending review decision reaches the capture'
    $control = New-ReviewPendingProject; $roots.Add($control)
    $pending = Get-SpecrewPendingVerdictState -ProjectRoot $control
    $realPhrase = 'approved for {0}' -f $pending.PendingToMarkerBoundary
    Assert-True ([bool]$pending.HasPendingVerdict -and [string]$pending.PendingFromMarkerBoundary -eq 'before-implement' -and [string]$pending.PendingToMarkerBoundary -eq 'review-signoff') ("the review decision is pending: {0} -> {1}" -f $pending.PendingFromMarkerBoundary, $pending.PendingToMarkerBoundary)
    $out = Send-TypedReply -Root $control -Text $realPhrase
    Assert-True ($out -match [regex]::Escape("captured '$realPhrase'")) ("the classifier captures '{0}' (it is then refused only for this fixture's absent review evidence)" -f $realPhrase)

    Write-Host 'Cases: the round phrase, in every shape a human types it, is never captured as a boundary verdict'
    $pasted = "> earlier message text`n> with a quoted line`n`napproved for review round"
    foreach ($text in @('approved for review round', 'Approved for review round.', 'approved for review round - also record the lock ruling', 'approved for review round, then present the packet', $pasted, "approved for review round`n`nThanks.")) {
        $root = New-ReviewPendingProject; $roots.Add($root)
        $out = Send-TypedReply -Root $root -Text $text
        $e = Get-Enforcement $root
        $label = ($text -replace "`r?`n", ' / ')
        Assert-True (-not ($out -match '(?i)captured ''approved for review')) ("'{0}': the classifier does not capture it as a boundary verdict" -f $label)
        Assert-True (-not ($out -match 'VERDICT_REFUSED_STAGE_EVIDENCE_ABSENT')) ("'{0}': it never reaches the evidence check that follows a capture" -f $label)
        Assert-True ([string]$e['last_authorized_boundary'] -eq 'before-implement' -and @($e['verdict_history']).Count -eq 0 -and @($e['bypass_history']).Count -eq 0) ("'{0}': the ledger is unchanged (last authorized: {1}, entries: {2})" -f $label, $e['last_authorized_boundary'], @($e['verdict_history']).Count)
        $pc = $e['pending_crossing']
        Assert-True ($null -ne $pc -and [string]$pc['to_boundary'] -eq 'review-signoff') ("'{0}': the review decision is still pending" -f $label)
    }
}
finally {
    foreach ($r in $roots) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue }
    $env:SPECREW_MODULE_PATH = $savedModulePath
}
if ($script:failCount -gt 0) { Write-Host "round-phrase-never-boundary-verdict: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'round-phrase-never-boundary-verdict: all passed' -ForegroundColor Green

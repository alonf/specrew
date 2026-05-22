[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$sharedGovernancePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'
$mirroredSharedGovernancePath = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\shared-governance.ps1'
$driftLogPath = Join-Path $repoRoot 'specs\039-launch-mode-boundary-enforcement\iterations\001\drift-log.md'

. $sharedGovernancePath

function New-BoundaryFixture {
    param([string]$Name)

    $fixtureRoot = Join-Path $repoRoot ('.scratch\' + $Name)
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }

    $null = New-Item -ItemType Directory -Path $fixtureRoot -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $fixtureRoot '.specrew') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $fixtureRoot '.squad\identity') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $fixtureRoot '.specify') -Force
    [IO.File]::WriteAllText((Join-Path $fixtureRoot '.specrew\config.yml'), @'
schema: "v1"
boundary_enforcement:
  policy_classes:
    specify: "human-judgment-required"
    clarify: "human-judgment-required"
    plan: "human-judgment-required"
    tasks: "human-judgment-required"
    before-implement: "human-judgment-required"
    review-signoff: "human-judgment-required"
    retro: "human-judgment-required"
    iteration-closeout: "human-judgment-required"
    feature-closeout: "human-judgment-required"
'@, [System.Text.UTF8Encoding]::new($false))
    return $fixtureRoot
}

function Set-BoundaryFixtureState {
    param(
        [string]$FixtureRoot,
        [string]$Boundary,
        [AllowNull()][object[]]$VerdictHistory = @(),
        [AllowNull()][object[]]$BypassHistory = @(),
        [AllowNull()][string]$LastAuthorizedBoundary = $Boundary,
        [AllowNull()][string]$PendingNextBoundary = $null
    )

    $context = [ordered]@{
        schema            = 'v2'
        mode              = 'resume-feature'
        launch_mode       = 'same-window'
        generated_at_utc  = '2026-05-22T16:21:00Z'
        session_state     = [ordered]@{
            active           = $true
            boundary_type    = $Boundary
            feature_ref      = '039-launch-mode-boundary-enforcement'
            feature_path     = (Join-Path $repoRoot 'specs\039-launch-mode-boundary-enforcement')
            iteration_number = '001'
            task_id          = $null
            auth_commit_hash = '97b70074307190a1e8edae8081882a8ee727f74f'
            recorded_at      = '2026-05-22T16:21:00Z'
        }
        boundary_enforcement = [ordered]@{
            enabled                  = $true
            last_authorized_boundary = $LastAuthorizedBoundary
            pending_next_boundary    = $PendingNextBoundary
            verdict_history          = @($VerdictHistory)
            bypass_history           = @($BypassHistory)
        }
    }

    [IO.File]::WriteAllText((Join-Path $FixtureRoot '.specrew\start-context.json'), (($context | ConvertTo-Json -Depth 12) + [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $FixtureRoot '.specrew\last-start-prompt.md'), ("---`nsession_state_active: true`nsession_state_boundary: {0}`n---`n" -f $Boundary), [System.Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $FixtureRoot '.squad\identity\now.md'), ("---`nsession_state_active: true`nsession_state_boundary: {0}`n---`n" -f $Boundary), [System.Text.UTF8Encoding]::new($false))
}

function Get-BoundaryContext {
    param([string]$FixtureRoot)
    return Get-Content -LiteralPath (Join-Path $FixtureRoot '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
}

$fixtureRoot = New-BoundaryFixture -Name 'launch-mode-boundary-enforcement'
try {
    $sharedHash = (Get-FileHash -LiteralPath $sharedGovernancePath -Algorithm SHA256).Hash
    $mirrorHash = (Get-FileHash -LiteralPath $mirroredSharedGovernancePath -Algorithm SHA256).Hash
    if ($sharedHash -ne $mirrorHash) {
        Write-Fail 'Mirrored shared-governance.ps1 files are not identical.'
    }
    Write-Pass 'Mirrored shared-governance.ps1 files remain identical'

    foreach ($commandName in @(
        'speckit.specrew-speckit.sync-specify.md',
        'speckit.specrew-speckit.sync-clarify.md',
        'speckit.specrew-speckit.sync-plan.md',
        'speckit.specrew-speckit.sync-tasks.md',
        'speckit.specrew-speckit.before-implement.md',
        'speckit.specrew-speckit.sync-review-signoff.md',
        'speckit.specrew-speckit.sync-retro.md',
        'speckit.specrew-speckit.sync-iteration-closeout.md',
        'speckit.specrew-speckit.sync-feature-closeout.md'
    )) {
        $primaryHash = (Get-FileHash -LiteralPath (Join-Path $repoRoot ('extensions\specrew-speckit\commands\' + $commandName)) -Algorithm SHA256).Hash
        $secondaryHash = (Get-FileHash -LiteralPath (Join-Path $repoRoot ('.specify\extensions\specrew-speckit\commands\' + $commandName)) -Algorithm SHA256).Hash
        if ($primaryHash -ne $secondaryHash) {
            Write-Fail "Mirrored command file '$commandName' is not identical."
        }
    }
    Write-Pass 'Mirrored command files remain identical'

    Set-BoundaryFixtureState -FixtureRoot $fixtureRoot -Boundary 'plan' -LastAuthorizedBoundary 'plan'
    $blocked = Test-SpecrewBoundaryAuthorization -ProjectRoot $fixtureRoot -CurrentBoundary 'plan' -RequestedBoundary 'tasks' -SessionId 'qs-f039-block-001' -AgentResponseSnippet '/speckit.plan -> /speckit.tasks in one turn'
    if ($blocked.Authorized -or $blocked.DirectiveSentinel -ne 'SPECREW_BOUNDARY_BLOCKED' -or -not $blocked.BypassAttemptDetected) {
        Write-Fail 'Plan -> tasks should block with SPECREW_BOUNDARY_BLOCKED and bypass-attempt evidence.'
    }
    $blockedDirective = Write-SpecrewBoundaryAuthorizationDirective -CurrentBoundary 'plan' -RequestedBoundary 'tasks' -DirectiveSentinel $blocked.DirectiveSentinel
    if (($blockedDirective -split '\r?\n')[0] -ne 'SPECREW_BOUNDARY_BLOCKED') {
        Write-Fail 'Blocked directive did not start with SPECREW_BOUNDARY_BLOCKED.'
    }
    $blockedContext = Get-BoundaryContext -FixtureRoot $fixtureRoot
    if ($blockedContext.boundary_enforcement.pending_next_boundary -ne 'tasks') {
        Write-Fail 'Blocked authorization did not persist pending_next_boundary=tasks.'
    }
    $decisionsContent = Get-Content -LiteralPath (Join-Path $fixtureRoot '.squad\decisions.md') -Raw -Encoding UTF8
    if ($decisionsContent -notmatch 'Boundary enforcement: tasks' -or $decisionsContent -notmatch 'Enforcement Action\*\*: blocked') {
        Write-Fail 'Blocked authorization did not append the expected ledger entry.'
    }
    Write-Pass 'Blocked plan -> tasks path is deterministic and auditable'

    $approvedVerdict = Parse-SpecrewBoundaryVerdict -VerdictText 'approved for tasks-boundary entry'
    if (-not $approvedVerdict.Authorized -or $approvedVerdict.DirectiveSentinel -ne 'SPECREW_BOUNDARY_AUTHORIZED' -or $approvedVerdict.Boundaries.Count -ne 1 -or $approvedVerdict.Boundaries[0] -ne 'tasks') {
        Write-Fail 'Approved verdict parsing did not normalize to canonical tasks authorization.'
    }
    Add-SpecrewBoundaryAuthorization -ProjectRoot $fixtureRoot -CurrentBoundary 'plan' -AuthorizedBoundary 'tasks' -AuthorizingHuman 'Alon Fliess' -VerdictText 'approved for tasks-boundary entry' | Out-Null
    $authorized = Test-SpecrewBoundaryAuthorization -ProjectRoot $fixtureRoot -CurrentBoundary 'plan' -RequestedBoundary 'tasks'
    if (-not $authorized.Authorized -or $authorized.DirectiveSentinel -ne 'SPECREW_BOUNDARY_AUTHORIZED') {
        Write-Fail 'Persisted plan -> tasks authorization was not honored on re-check.'
    }
    $authorizedContext = Get-BoundaryContext -FixtureRoot $fixtureRoot
    if ($authorizedContext.boundary_enforcement.last_authorized_boundary -ne 'tasks' -or $authorizedContext.boundary_enforcement.pending_next_boundary) {
        Write-Fail 'Persisted authorization did not update last_authorized_boundary/pending_next_boundary correctly.'
    }
    if (@($authorizedContext.boundary_enforcement.verdict_history).Count -lt 1) {
        Write-Fail 'Persisted authorization did not append verdict_history.'
    }
    Write-Pass 'Approved continuation persists verdict history and clears the pending boundary'

    $ambiguousVerdict = Parse-SpecrewBoundaryVerdict -VerdictText 'looks good'
    if ($ambiguousVerdict.Authorized -or $ambiguousVerdict.DirectiveSentinel -ne 'SPECREW_BOUNDARY_VERDICT_UNRECOGNIZED') {
        Write-Fail 'Ambiguous verdicts must remain unauthorized with SPECREW_BOUNDARY_VERDICT_UNRECOGNIZED.'
    }
    Write-Pass 'Ambiguous verdicts stay unauthorized'

    $compoundVerdict = Parse-SpecrewBoundaryVerdict -VerdictText 'approved for review-boundary AND review-signoff'
    if (-not $compoundVerdict.Authorized -or $compoundVerdict.Boundaries.Count -lt 1 -or $compoundVerdict.Boundaries[0] -ne 'review-signoff') {
        Write-Fail 'Compound review verdict did not normalize to canonical review-signoff authorization.'
    }
    Set-BoundaryFixtureState -FixtureRoot $fixtureRoot -Boundary 'before-implement' -LastAuthorizedBoundary 'before-implement'
    Add-SpecrewBoundaryAuthorization -ProjectRoot $fixtureRoot -CurrentBoundary 'before-implement' -AuthorizedBoundary 'review-signoff' -AuthorizingHuman 'Alon Fliess' -VerdictText 'approved for review-boundary AND review-signoff' | Out-Null
    $compoundContext = Get-BoundaryContext -FixtureRoot $fixtureRoot
    if ($compoundContext.boundary_enforcement.last_authorized_boundary -ne 'review-signoff') {
        Write-Fail 'Compound verdict persistence did not advance to review-signoff.'
    }
    Write-Pass 'Compound verdicts normalize and persist canonically'

    Set-BoundaryFixtureState -FixtureRoot $fixtureRoot -Boundary 'tasks' -LastAuthorizedBoundary 'tasks'
    Add-SpecrewBoundaryBypassRecord -ProjectRoot $fixtureRoot -SessionId 'session-bypass-001' -Reason 'schema migration replay' -Boundary $null -LaunchMode 'same-window/autonomous' -AgentResponseSnippet 'operator activated bypass' | Out-Null
    $bypassed = Test-SpecrewBoundaryAuthorization -ProjectRoot $fixtureRoot -CurrentBoundary 'tasks' -RequestedBoundary 'before-implement' -SessionId 'session-bypass-001' -EmergencyBypassActive
    if (-not $bypassed.Authorized -or $bypassed.Decision -ne 'bypassed' -or $bypassed.DirectiveSentinel -ne 'SPECREW_BOUNDARY_BYPASS_ACTIVE') {
        Write-Fail 'Emergency bypass should return bypassed semantics and SPECREW_BOUNDARY_BYPASS_ACTIVE.'
    }
    $bypassDirective = Write-SpecrewBoundaryAuthorizationDirective -CurrentBoundary 'tasks' -RequestedBoundary 'before-implement' -DirectiveSentinel $bypassed.DirectiveSentinel -BypassReason 'schema migration replay'
    if (($bypassDirective -split '\r?\n')[0] -ne 'SPECREW_BOUNDARY_BYPASS_ACTIVE') {
        Write-Fail 'Bypass directive did not start with SPECREW_BOUNDARY_BYPASS_ACTIVE.'
    }
    $bypassContext = Get-BoundaryContext -FixtureRoot $fixtureRoot
    if (@($bypassContext.boundary_enforcement.bypass_history).Count -lt 1) {
        Write-Fail 'Emergency bypass did not append bypass_history.'
    }
    Write-Pass 'Emergency bypass is auditable and session-scoped'

    $policyClass = Get-SpecrewBoundaryPolicyClass -ProjectRoot $fixtureRoot -Boundary 'tasks'
    if ($policyClass -ne 'human-judgment-required') {
        Write-Fail 'Policy seam did not default to human-judgment-required.'
    }
    Write-Pass 'Policy seam defaults to human-judgment-required'

    $malformedContext = Get-BoundaryContext -FixtureRoot $fixtureRoot
    $malformedContext.boundary_enforcement.verdict_history = 'invalid'
    [IO.File]::WriteAllText((Join-Path $fixtureRoot '.specrew\start-context.json'), (($malformedContext | ConvertTo-Json -Depth 12) + [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
    $threwFailClosed = $false
    try {
        Test-SpecrewBoundaryAuthorization -ProjectRoot $fixtureRoot -CurrentBoundary 'tasks' -RequestedBoundary 'before-implement' | Out-Null
    }
    catch {
        $threwFailClosed = $_.Exception.Message -match 'malformed'
    }
    if (-not $threwFailClosed) {
        Write-Fail 'Malformed boundary_enforcement payload must fail closed.'
    }
    Write-Pass 'Malformed boundary_enforcement payloads fail closed'

    if (-not (Test-Path -LiteralPath $driftLogPath -PathType Leaf)) {
        Write-Fail 'Replay drift-log evidence is missing.'
    }
    $driftLogContent = Get-Content -LiteralPath $driftLogPath -Raw -Encoding UTF8
    if ($driftLogContent -notmatch '2026-05-22' -or $driftLogContent -notmatch 'clarify' -or $driftLogContent -notmatch 'tasks') {
        Write-Fail 'Replay drift-log evidence does not reference the 2026-05-22 clarify -> plan -> tasks incident.'
    }
    Write-Host "Replay 2026-05-22 chain-past-plan incident"
    Set-BoundaryFixtureState -FixtureRoot $fixtureRoot -Boundary 'plan' -LastAuthorizedBoundary 'plan'
    $replayResult = Test-SpecrewBoundaryAuthorization -ProjectRoot $fixtureRoot -CurrentBoundary 'plan' -RequestedBoundary 'tasks' -AgentResponseSnippet 'clarify -> plan -> tasks'
    if ($replayResult.Authorized -or $replayResult.DirectiveSentinel -ne 'SPECREW_BOUNDARY_BLOCKED') {
        Write-Fail 'Replay scenario must block at tasks when authorization is missing.'
    }
    Write-Pass 'Replay 2026-05-22 chain-past-plan incident blocks at tasks'

    $summary = Get-SpecrewBoundaryEnforcementSummary -ProjectRoot $fixtureRoot
    if ($summary.LastAuthorizedBoundary -ne 'plan' -or $summary.PendingNextBoundary -ne 'tasks' -or $summary.EnforcementEventCount -lt 0) {
        Write-Fail 'Boundary enforcement summary did not report the expected state.'
    }
    Write-Pass 'Boundary enforcement summary exposes current status for dashboard/where surfaces'
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host 'Launch-mode boundary enforcement integration assertions: all pass'
exit 0

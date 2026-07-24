#requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Pass([string]$Message) { Write-Host "PASS: $Message" -ForegroundColor Green }
function Fail([string]$Message) { throw "FAIL: $Message" }
function Assert-True([bool]$Condition, [string]$Message) { if (-not $Condition) { Fail $Message }; Pass $Message }
function Assert-Throws([scriptblock]$Action, [string]$Pattern, [string]$Message) {
    try { & $Action; Fail "$Message (did not throw)" }
    catch {
        if ($_.Exception.Message -like 'FAIL:*') { throw }
        if ($_.Exception.Message -notmatch $Pattern) { Fail "$Message (unexpected error: $($_.Exception.Message))" }
        Pass $Message
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
. (Join-Path $repoRoot 'scripts\internal\bootstrap\HandoverStore.ps1')

$scratch = Join-Path $repoRoot '.scratch\boundary-correction-ledger'
if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
$null = New-Item -ItemType Directory -Path (Join-Path $scratch '.specrew') -Force

try {
    [System.IO.File]::WriteAllText((Join-Path $scratch 'README.md'), "# Fixture`n", [System.Text.UTF8Encoding]::new($false))
    & git -C $scratch init --quiet
    & git -C $scratch config user.email 'test@specrew.local'
    & git -C $scratch config user.name 'Specrew Test'
    & git -C $scratch add README.md
    & git -C $scratch commit --quiet -m 'fixture boundary state'
    $boundaryCommit = ([string](& git -C $scratch rev-parse HEAD)).Trim().ToLowerInvariant()
    $boundaryTree = ([string](& git -C $scratch rev-parse 'HEAD^{tree}')).Trim().ToLowerInvariant()

    $original = [ordered]@{
        from_boundary     = 'plan'
        to_boundary       = 'tasks'
        verdict_text      = 'approved for tasks'
        authorizing_human = 'human@example.test'
        recorded_at       = '2026-07-01T10:00:00Z'
        auth_commit_hash  = $boundaryCommit
        evidence_source   = 'hook-captured-from-transcript'
        kind              = 'standard'
    }
    $originalId = Get-SpecrewBoundaryAuthorizationEntryId -Entry $original
    $scope = New-SpecrewBoundaryCrossingIdentity -FromBoundary 'plan' -ToBoundary 'tasks' -WorkingBoundary 'tasks' -BoundaryCommitHash $boundaryCommit -ArtifactStateId $boundaryTree -RecordedAt '2026-07-02T10:00:00Z'
    $context = [ordered]@{
        schema = 'v2'
        session_state = [ordered]@{
            active = $true; boundary_type = 'tasks'; feature_ref = '198-test'; feature_path = $null
            iteration_number = '007'; task_id = 'T033'; auth_commit_hash = $boundaryCommit
            recorded_at = '2026-07-02T10:00:00Z'
        }
        boundary_enforcement = [ordered]@{
            enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = $null
            pending_crossing = $scope; policy_classes = Get-SpecrewBoundaryPolicyClassMap -ProjectRoot $scratch
            verdict_history = @($original); correction_history = @(); bypass_history = @()
        }
    }
    [System.IO.File]::WriteAllText((Join-Path $scratch '.specrew\start-context.json'), (($context | ConvertTo-Json -Depth 24) + "`n"), [System.Text.UTF8Encoding]::new($false))

    $beforeState = Get-SpecrewBoundaryEnforcementState -ProjectRoot $scratch
    $beforeVerdictJson = @($beforeState.State['verdict_history']) | ConvertTo-Json -Depth 16 -Compress
    $correctionArgs = @{
        ProjectRoot = $scratch
        OriginalEntryId = $originalId
        ScopeFromBoundary = 'plan'
        ScopeToBoundary = 'tasks'
        WorkingBoundary = 'tasks'
        ScopeBoundaryCommitHash = $boundaryCommit
        ScopeArtifactStateId = $boundaryTree
        ResultingLastAuthorizedBoundary = 'plan'
        CorrectingAuthority = 'human@example.test'
        AuthorityVerdictText = 'approved for plan'
        AuthorityAuthCommitHash = $boundaryCommit
        Reason = 'The historical verdict was valid in its original cycle but was reused for this different scoped crossing.'
        RecordedAt = '2026-07-02T10:05:00Z'
    }
    $write = Add-SpecrewBoundaryAuthorizationCorrection @correctionArgs
    Assert-True ([bool]$write.Appended) 'correction appends once under explicit human authority'

    $after = Get-SpecrewBoundaryEnforcementState -ProjectRoot $scratch
    $afterVerdictJson = @($after.State['verdict_history']) | ConvertTo-Json -Depth 16 -Compress
    Assert-True ($afterVerdictJson -ceq $beforeVerdictJson) 'raw verdict_history remains byte-equivalent JSON evidence after correction'
    Assert-True (@($after.State['verdict_history']).Count -eq 1 -and @($after.State['correction_history']).Count -eq 1) 'correction is append-only and does not delete historical verdict evidence'
    $record = ConvertTo-SpecrewBoundaryMap -Value @($after.State['correction_history'])[0]
    Assert-True ([string]$record['original_entry_id'] -eq $originalId -and [string]$record['scope_crossing_id'] -eq [string]$scope['crossing_id']) 'correction names the exact original authorization and exact scoped crossing'
    Assert-True ([string](ConvertTo-SpecrewBoundaryMap -Value $record['original_entry_identity'])['auth_commit_hash'] -eq $boundaryCommit) 'correction preserves the original entry identity tuple'
    Assert-True (@($after.EffectiveState['verdict_history']).Count -eq 0 -and [string]$after.EffectiveState['last_authorized_boundary'] -eq 'plan') 'effective authority excludes the target only for the active corrected crossing'

    $pending = Get-SpecrewPendingVerdictState -ProjectRoot $scratch
    Assert-True ([bool]$pending.HasPendingVerdict -and $pending.IntegrityStatus -eq 'scoped-verified') 'corrected crossing is pending only after its Git-bound scope verifies'
    Assert-True ($pending.CrossingId -eq [string]$scope['crossing_id'] -and $pending.BoundaryCommitHash -eq $boundaryCommit -and $pending.ArtifactStateId -eq $boundaryTree) 'pending verdict exposes stable crossing, commit, and Git-tree identity'
    Assert-True ($pending.PendingFromMarkerBoundary -eq 'plan' -and $pending.PendingToMarkerBoundary -eq 'tasks') 'pending ask is derived from corrected authority, not stale session narrative'

    $gate = Test-SpecrewBoundaryAuthorization -ProjectRoot $scratch -CurrentBoundary 'plan' -RequestedBoundary 'tasks'
    Assert-True (-not [bool]$gate.Authorized) 'live boundary gate consumes effective history and blocks the invalidated authorization use'
    $unreconciled = Get-SpecrewUnreconciledBoundary -ProjectRoot $scratch
    Assert-True ($null -ne $unreconciled -and $unreconciled.Boundary -eq 'tasks' -and $unreconciled.LastAuthorized -eq 'plan') 'shared unreconciled reader consumes the corrected effective cursor'
    $summaryState = Get-SpecrewBoundaryEnforcementState -ProjectRoot $scratch
    Assert-True ($summaryState.Issues.Count -eq 0) ("corrected state remains shape-valid after a blocked gate read: {0}" -f (@($summaryState.Issues) -join '; '))
    $summary = Get-SpecrewBoundaryEnforcementSummary -ProjectRoot $scratch
    Assert-True ($summary.LastAuthorizedBoundary -eq 'plan' -and $summary.CorrectionEventCount -eq 1) ("status summary reports effective authority and correction count (boundary={0}, corrections={1})" -f $summary.LastAuthorizedBoundary, $summary.CorrectionEventCount)

    Sync-SpecrewPendingVerdictArtifactAfterAuthorization -ProjectRoot $scratch -NowUtc '2026-07-02T10:06:00Z'
    $artifactPath = Join-Path $scratch '.specrew\runtime\pending-verdict-stop.md'
    $renderOne = Get-Content -LiteralPath $artifactPath -Raw -Encoding UTF8
    Sync-SpecrewPendingVerdictArtifactAfterAuthorization -ProjectRoot $scratch -NowUtc '2026-07-02T10:06:00Z'
    $renderTwo = Get-Content -LiteralPath $artifactPath -Raw -Encoding UTF8
    Assert-True ($renderOne -ceq $renderTwo) 'repeat render is stable for the same crossing identity'
    foreach ($required in @(
        "Crossing ID: $($scope['crossing_id'])",
        "Boundary commit hash: $boundaryCommit",
        "Artifact state: git-tree $boundaryTree",
        'Human approval phrase: approved for tasks',
        '<!-- SPECREW-VERDICT-BOUNDARY: plan -> tasks -->',
        'Numeric labels are non-authoritative'
    )) {
        Assert-True ($renderOne.Contains($required)) "pending packet carries exact scoped semantic: $required"
    }

    $duplicate = Add-SpecrewBoundaryAuthorizationCorrection @correctionArgs
    Assert-True (-not [bool]$duplicate.Appended -and @((Get-SpecrewBoundaryEnforcementState -ProjectRoot $scratch).State['correction_history']).Count -eq 1) 'same correction is idempotent and does not append twice'

    $beforeRejectedCount = @((Get-SpecrewBoundaryEnforcementState -ProjectRoot $scratch).State['correction_history']).Count
    $numericArgs = $correctionArgs.Clone(); $numericArgs['AuthorityVerdictText'] = '1'
    Assert-Throws { Add-SpecrewBoundaryAuthorizationCorrection @numericArgs } 'explicit.*approved for plan|numeric aliases' 'bare numeric reply cannot authorize a correction'
    $wrongTreeArgs = $correctionArgs.Clone(); $wrongTreeArgs['ScopeArtifactStateId'] = ('0' * 40)
    Assert-Throws { Add-SpecrewBoundaryAuthorizationCorrection @wrongTreeArgs } 'does not match boundary commit' 'mismatched Git-tree identity fails closed'
    $wrongCrossingArgs = $correctionArgs.Clone(); $wrongCrossingArgs['ScopeFromBoundary'] = 'tasks'; $wrongCrossingArgs['ScopeToBoundary'] = 'before-implement'
    Assert-Throws { Add-SpecrewBoundaryAuthorizationCorrection @wrongCrossingArgs } 'not the requested correction crossing' 'entry identity cannot be relabeled as a different crossing'
    $conflictArgs = $correctionArgs.Clone(); $conflictArgs['Reason'] = 'Conflicting rewrite attempt.'
    Assert-Throws { Add-SpecrewBoundaryAuthorizationCorrection @conflictArgs } 'conflicting correction' 'conflicting correction for the same entry and scope fails closed'
    Assert-True (@((Get-SpecrewBoundaryEnforcementState -ProjectRoot $scratch).State['correction_history']).Count -eq $beforeRejectedCount) 'rejected correction attempts leave the append-only ledger unchanged'

    [System.IO.File]::AppendAllText((Join-Path $scratch 'README.md'), "second tree`n", [System.Text.UTF8Encoding]::new($false))
    & git -C $scratch add README.md
    & git -C $scratch commit --quiet -m 'unrelated crossing state'
    $otherCommit = ([string](& git -C $scratch rev-parse HEAD)).Trim().ToLowerInvariant()
    $otherTree = ([string](& git -C $scratch rev-parse 'HEAD^{tree}')).Trim().ToLowerInvariant()
    $otherScope = New-SpecrewBoundaryCrossingIdentity -FromBoundary 'plan' -ToBoundary 'tasks' -WorkingBoundary 'tasks' -BoundaryCommitHash $otherCommit -ArtifactStateId $otherTree -RecordedAt '2026-07-03T00:00:00Z'
    $unrelatedRaw = [ordered]@{
        enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = $null; pending_crossing = $otherScope
        verdict_history = @($original); correction_history = @($after.State['correction_history']); bypass_history = @()
    }
    $unrelatedEffective = Get-SpecrewEffectiveBoundaryEnforcementState -BoundaryEnforcement $unrelatedRaw
    Assert-True (@($unrelatedEffective['verdict_history']).Count -eq 1 -and $unrelatedEffective['last_authorized_boundary'] -eq 'tasks') 'scoped correction does not globally invalidate a valid historical verdict'

    Add-SpecrewBoundaryAuthorization -ProjectRoot $scratch -CurrentBoundary 'plan' -AuthorizedBoundary 'tasks' -AuthorizingHuman 'human@example.test' -VerdictText 'approved for tasks' -AuthCommitHash $boundaryCommit -RecordedAt '2026-07-02T10:10:00Z' -EvidenceSource 'human-confirmed-at-resume' | Out-Null
    $reauthorized = Get-SpecrewBoundaryEnforcementState -ProjectRoot $scratch
    Assert-True (@($reauthorized.State['verdict_history']).Count -eq 2 -and @($reauthorized.State['correction_history']).Count -eq 1) 'fresh explicit re-authorization appends without rewriting verdict or correction history'
    $newEntry = ConvertTo-SpecrewBoundaryMap -Value @($reauthorized.State['verdict_history'])[-1]
    Assert-True ([string]$newEntry['authorization_id'] -match '^auth-[0-9a-f]{64}$') 'new authorization persists its stable entry identity'
    Assert-True ([string]$reauthorized.EffectiveState['last_authorized_boundary'] -eq 'tasks' -and $null -eq $reauthorized.State['pending_crossing']) 'fresh authorization advances and retires the exact pending crossing'
    $cleanPending = Get-SpecrewPendingVerdictState -ProjectRoot $scratch
    Assert-True (-not [bool]$cleanPending.HasPendingVerdict -and $cleanPending.IntegrityStatus -eq 'scoped-clean') 'cleared scoped state never falls back to stale session_state'
    $authorizedGate = Test-SpecrewBoundaryAuthorization -ProjectRoot $scratch -CurrentBoundary 'plan' -RequestedBoundary 'tasks'
    Assert-True ([bool]$authorizedGate.Authorized) 'fresh current-cycle authorization satisfies the live gate after correction'

    Write-Host ''
    Write-Host 'All boundary correction-ledger tests passed.' -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }
}

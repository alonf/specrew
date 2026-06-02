[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 141 iteration 002 (FR-024). These tests dot-source the extracted
# scripts/internal/session-recovery.ps1 helper directly. That dot-source is itself the
# regression proof for the extraction: specrew-start.ps1 now consumes the same helper via
# a compatibility wrapper, so loading + exercising it here proves the recovery/session-state
# behavior still works after being moved out of the 4k-line entry script. Integration-level
# regression (the real entry script through the wrapper) is covered by
# tests/integration/{stale-state-detection,start-recovery-flow,stale-state-retro}.tests.ps1.

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { Write-Fail $Message } }
function Assert-Equal { param($Expected, $Actual, [string]$Message) if ($Expected -ne $Actual) { Write-Fail ("{0} (expected '{1}', got '{2}')" -f $Message, $Expected, $Actual) } }

$recoveryScript = Join-Path $PSScriptRoot '..\..\scripts\internal\session-recovery.ps1'
. $recoveryScript

function New-TempRoot {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('sr-test-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path (Join-Path $tmp '.specrew') -Force
    return $tmp
}

function Write-StartContext {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$FeatureRef = '051-old-merged',
        [string]$FeaturePath = 'C:/Dev/Specrew-051-deleted',
        [bool]$Active = $true
    )
    $payload = @{
        schema               = 'v2'
        session_state        = @{
            active           = $Active
            boundary_type    = 'tasks'
            feature_ref      = $FeatureRef
            feature_path     = $FeaturePath
            iteration_number = '003'
            task_id          = 'T009'
        }
        boundary_enforcement = @{ enabled = $true; last_authorized_boundary = 'tasks' }
    }
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\start-context.json'), ($payload | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
}

function Write-ActiveSessions {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot, [Parameter(Mandatory = $true)][string]$SiblingPath)
    $content = @"
sessions:
  - feature_id: "051-old-merged"
    feature_path: "C:/Dev/Specrew-051-deleted"
    started_at: "2026-05-31T10:00:00Z"
  - feature_id: "141-design-gate-runtime-hardening"
    feature_path: "$SiblingPath"
    started_at: "2026-06-02T10:00:00Z"
"@
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\active-sessions.yml'), $content, [System.Text.UTF8Encoding]::new($false))
}

Write-Host '--- Group 1: extraction / dot-sourceability (functions available standalone) ---'
foreach ($fn in 'Get-SpecrewConfigValue', 'Get-SpecrewSessionStateSnapshot', 'Test-SpecrewStaleSessionState',
    'Read-SpecrewRecoveryChoice', 'New-SpecrewRecoverySession', 'Resolve-SpecrewRecoverySelection',
    'Clear-SpecrewStaleSessionReference', 'Invoke-SpecrewStaleSessionCleanupDecision') {
    Assert-True ([bool](Get-Command $fn -ErrorAction SilentlyContinue)) "Extracted helper exposes $fn"
}
Write-Pass 'All recovery/session-state functions load from the extracted helper'

Write-Host '--- Group 2: Resolve-SpecrewRecoverySelection existing behavior (regression) ---'
$existingDir = New-TempRoot
$ssExisting = [pscustomobject]@{ feature_ref = '141'; feature_path = $existingDir; active = 'true' }
$planAexisting = Resolve-SpecrewRecoverySelection -Choice 'A' -SessionState $ssExisting
Assert-Equal $existingDir $planAexisting.ResumeFeatureOverride 'Choice A with existing path re-anchors to that path'
Assert-Equal $false $planAexisting.SkipAutoResume 'Choice A with existing path resumes (SkipAutoResume false)'
Assert-True (-not ($planAexisting.PSObject.Properties.Name -contains 'RequiresStaleCleanupConfirmation')) 'Choice A with existing path does NOT request cleanup'
Write-Pass 'Choice A with existing feature path re-anchors (unchanged behavior)'

$ssEmpty = [pscustomobject]@{ feature_ref = ''; feature_path = ''; active = 'true' }
$planAauto = Resolve-SpecrewRecoverySelection -Choice 'A' -SessionState $ssEmpty
Assert-Equal 'auto' $planAauto.ResumeFeatureOverride 'Choice A with empty path re-anchors to auto'
Write-Pass 'Choice A with empty feature path falls back to auto re-anchor (unchanged behavior)'

$planB = Resolve-SpecrewRecoverySelection -Choice 'B' -SessionState $ssExisting
Assert-True ($null -eq $planB.ResumeFeatureOverride) 'Choice B does not re-anchor'
Assert-Equal $true $planB.SkipAutoResume 'Choice B skips auto resume'
$planC = Resolve-SpecrewRecoverySelection -Choice 'C' -SessionState $ssExisting
Assert-Equal $true $planC.ForceNoLaunch 'Choice C forces no launch'
Assert-Equal $true $planC.SkipAutoResume 'Choice C skips auto resume'
Write-Pass 'Choices B and C preserve their existing semantics'
Remove-Item -Recurse -Force $existingDir

Write-Host '--- Group 3: FR-024 detection in Test-SpecrewStaleSessionState ---'
# 3a: missing EXTERNAL path -> "outside the current worktree"
$rootExternal = New-TempRoot
Write-StartContext -ProjectRoot $rootExternal -FeaturePath 'C:/Dev/Specrew-051-deleted-external'
$detectExternal = Test-SpecrewStaleSessionState -ProjectRoot $rootExternal
Assert-Equal $true $detectExternal.IsStale 'Missing external feature path is detected as stale'
$externalIssue = @($detectExternal.Issues | Where-Object { $_ -match 'no longer exists' -and $_ -match 'outside the current worktree' })
Assert-True ($externalIssue.Count -ge 1) 'External missing-path stale issue names "outside the current worktree"'
Write-Pass 'FR-024 detects a missing external/deleted-worktree feature path'
Remove-Item -Recurse -Force $rootExternal

# 3b: missing INSIDE path -> "no longer exists" without "outside"
$rootInside = New-TempRoot
$insideMissing = Join-Path $rootInside 'specs\051-inside-gone'
Write-StartContext -ProjectRoot $rootInside -FeaturePath $insideMissing
$detectInside = Test-SpecrewStaleSessionState -ProjectRoot $rootInside
Assert-Equal $true $detectInside.IsStale 'Missing in-worktree feature path is detected as stale'
$insideIssue = @($detectInside.Issues | Where-Object { $_ -match 'no longer exists' -and $_ -notmatch 'outside the current worktree' })
Assert-True ($insideIssue.Count -ge 1) 'In-worktree missing-path stale issue is reported without the "outside" wording'
Write-Pass 'FR-024 detects a missing in-worktree feature path distinctly'
Remove-Item -Recurse -Force $rootInside

# 3c: EXISTING path -> no FR-024 missing-path issue
$rootExists = New-TempRoot
$existsFeature = Join-Path $rootExists 'specs\exists-feature'
$null = New-Item -ItemType Directory -Path $existsFeature -Force
Write-StartContext -ProjectRoot $rootExists -FeaturePath $existsFeature
$detectExists = Test-SpecrewStaleSessionState -ProjectRoot $rootExists
$noMissingIssue = @($detectExists.Issues | Where-Object { $_ -match 'feature path no longer exists' })
Assert-Equal 0 $noMissingIssue.Count 'Existing feature path produces no FR-024 missing-path issue'
Write-Pass 'FR-024 does not false-positive on an existing feature path'
Remove-Item -Recurse -Force $rootExists

Write-Host '--- Group 4: FR-024 recovery guard (no re-anchor to a missing path) ---'
$ssMissing = [pscustomobject]@{ feature_ref = '051-old-merged'; feature_path = 'C:/Dev/Specrew-051-deleted'; active = 'true' }
$planGuard = Resolve-SpecrewRecoverySelection -Choice 'A' -SessionState $ssMissing
Assert-True ($null -eq $planGuard.ResumeFeatureOverride) 'Choice A on a missing path does NOT re-anchor'
Assert-Equal $true $planGuard.SkipAutoResume 'Choice A on a missing path skips auto resume'
Assert-True ($planGuard.PSObject.Properties.Name -contains 'RequiresStaleCleanupConfirmation') 'Guard surfaces RequiresStaleCleanupConfirmation'
Assert-Equal $true $planGuard.RequiresStaleCleanupConfirmation 'Guard requests confirm-gated cleanup'
Assert-Equal 'C:/Dev/Specrew-051-deleted' $planGuard.StaleFeaturePath 'Guard reports the stale feature path'
Write-Pass 'FR-024 recovery guard refuses to re-anchor and requests confirm-gated cleanup'

Write-Host '--- Group 5: FR-024 cleanup execution (confirm-gated, artifact-safe) ---'
# 5a: without -Confirmed -> no-op
$rootNoConfirm = New-TempRoot
Write-StartContext -ProjectRoot $rootNoConfirm
Write-ActiveSessions -ProjectRoot $rootNoConfirm -SiblingPath $rootNoConfirm
$noConfirm = Clear-SpecrewStaleSessionReference -ProjectRoot $rootNoConfirm -StaleFeatureRef '051-old-merged'
Assert-Equal $false $noConfirm.Cleared 'Cleanup without confirmation does not clear'
Assert-Equal 'confirmation-required' $noConfirm.Reason 'Cleanup without confirmation reports confirmation-required'
$ctxAfterNoConfirm = (Get-Content (Join-Path $rootNoConfirm '.specrew\start-context.json') -Raw | ConvertFrom-Json).session_state.active
Assert-Equal $true $ctxAfterNoConfirm 'start-context session_state untouched without confirmation'
Write-Pass 'Cleanup is a no-op without explicit confirmation'
Remove-Item -Recurse -Force $rootNoConfirm

# 5b: with -Confirmed -> clears refs, preserves sibling + artifacts, no commits
$rootConfirm = New-TempRoot
$siblingPath = $rootConfirm
$artifact = Join-Path $rootConfirm 'specs\051-old-merged\iterations\003\state.md'
$null = New-Item -ItemType Directory -Path (Split-Path -Parent $artifact) -Force
[System.IO.File]::WriteAllText($artifact, 'kept feature artifact', [System.Text.UTF8Encoding]::new($false))
Write-StartContext -ProjectRoot $rootConfirm
Write-ActiveSessions -ProjectRoot $rootConfirm -SiblingPath $siblingPath
$confirm = Clear-SpecrewStaleSessionReference -ProjectRoot $rootConfirm -StaleFeatureRef '051-old-merged' -Confirmed
Assert-Equal $true $confirm.Cleared 'Confirmed cleanup clears references'
Assert-Equal $false $confirm.TouchedArtifacts 'Confirmed cleanup does not touch feature artifacts'
Assert-Equal $false $confirm.MadeCommits 'Confirmed cleanup makes no commits'
$ctxAfter = (Get-Content (Join-Path $rootConfirm '.specrew\start-context.json') -Raw | ConvertFrom-Json).session_state
Assert-Equal $false $ctxAfter.active 'start-context session_state deactivated after cleanup'
Assert-Equal '' ([string]$ctxAfter.feature_ref) 'start-context feature_ref cleared after cleanup'
Assert-Equal '' ([string]$ctxAfter.feature_path) 'start-context feature_path cleared after cleanup'
$activeAfter = Get-Content (Join-Path $rootConfirm '.specrew\active-sessions.yml') -Raw
Assert-True (-not $activeAfter.Contains('051-old-merged')) 'Stale active-sessions entry removed'
Assert-True ($activeAfter.Contains('141-design-gate-runtime-hardening')) 'Sibling active-sessions entry preserved'
Assert-True (Test-Path -LiteralPath $artifact) 'Feature artifact preserved through cleanup'
Write-Pass 'Confirmed cleanup clears only runtime refs; preserves sibling session + artifacts; no commits'
Remove-Item -Recurse -Force $rootConfirm

Write-Host '--- Group 6: FR-024 enforcement decision (Invoke-SpecrewStaleSessionCleanupDecision) ---'
# 6a: plan without the flag -> not attempted
$rootDecision = New-TempRoot
Write-StartContext -ProjectRoot $rootDecision
Write-ActiveSessions -ProjectRoot $rootDecision -SiblingPath $rootDecision
$ssDec = [pscustomobject]@{ feature_ref = '051-old-merged'; feature_path = 'C:/Dev/Specrew-051-deleted'; active = 'true' }
$planNoFlag = Resolve-SpecrewRecoverySelection -Choice 'B' -SessionState $ssDec
$decNoFlag = Invoke-SpecrewStaleSessionCleanupDecision -RecoveryPlan $planNoFlag -ProjectRoot $rootDecision -SessionState $ssDec -Confirmed $true
Assert-Equal $false $decNoFlag.Attempted 'Plan without cleanup flag is not attempted even if confirmed'
Write-Pass 'Enforcement decision ignores plans that did not request cleanup'

# 6b: plan with flag + not confirmed -> attempted, no mutation
$planFlag = Resolve-SpecrewRecoverySelection -Choice 'A' -SessionState $ssDec
$decUnconfirmed = Invoke-SpecrewStaleSessionCleanupDecision -RecoveryPlan $planFlag -ProjectRoot $rootDecision -SessionState $ssDec -Confirmed $false
Assert-Equal $true $decUnconfirmed.Attempted 'Cleanup-requesting plan is attempted'
Assert-Equal $false $decUnconfirmed.Confirmed 'Unconfirmed decision does not confirm'
$ctxUnconfirmed = (Get-Content (Join-Path $rootDecision '.specrew\start-context.json') -Raw | ConvertFrom-Json).session_state.active
Assert-Equal $true $ctxUnconfirmed 'Unconfirmed decision performs no mutation'
Write-Pass 'Enforcement decision blocks mutation until confirmed'

# 6c: plan with flag + confirmed -> executes cleanup on disk
$decConfirmed = Invoke-SpecrewStaleSessionCleanupDecision -RecoveryPlan $planFlag -ProjectRoot $rootDecision -SessionState $ssDec -Confirmed $true
Assert-Equal $true $decConfirmed.Attempted 'Confirmed decision is attempted'
Assert-Equal $true $decConfirmed.Confirmed 'Confirmed decision is confirmed'
Assert-True ($null -ne $decConfirmed.Result -and $decConfirmed.Result.Cleared) 'Confirmed decision executes the cleanup'
$ctxConfirmed = (Get-Content (Join-Path $rootDecision '.specrew\start-context.json') -Raw | ConvertFrom-Json).session_state.active
Assert-Equal $false $ctxConfirmed 'Confirmed decision deactivates the stale session on disk'
Write-Pass 'Enforcement decision performs runtime cleanup when confirmed'
Remove-Item -Recurse -Force $rootDecision

Write-Host ''
Write-Host 'All session-recovery extraction + FR-024 tests passed.' -ForegroundColor Green

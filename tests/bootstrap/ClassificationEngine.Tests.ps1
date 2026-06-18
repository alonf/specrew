Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../scripts/internal/bootstrap/ClassificationEngine.ps1"

function Assert-Equal {
    param([AllowNull()]$Actual, [AllowNull()]$Expected, [string]$Message)
    if ($Actual -ne $Expected) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# Valid anchor -> welcome-back.
$m1 = Resolve-SpecrewBootstrapMode -AnchorValid $true
Assert-Equal $m1.mode 'welcome-back' 'valid anchor resolves welcome-back'

# Anchor cleared -> cleared-anchor with a reason naming the cause.
$m2 = Resolve-SpecrewBootstrapMode -AnchorValid $false -AnchorClearedReason 'merged'
Assert-Equal $m2.mode 'cleared-anchor' 'cleared anchor resolves cleared-anchor mode'
Assert-True ($m2.reason -match 'merged') 'cleared-anchor reason names the cause'

# No anchor and nothing cleared -> full.
$m3 = Resolve-SpecrewBootstrapMode -AnchorValid $false
Assert-Equal $m3.mode 'full' 'no valid anchor, nothing cleared resolves full'

# Valid handover takes precedence (handover-first stage).
$m4 = Resolve-SpecrewBootstrapMode -AnchorValid $false -HandoverValid $true
Assert-Equal $m4.mode 'welcome-back' 'valid handover resolves welcome-back'

# Same-session marker is not a competing same-worktree session.
$now = '2026-06-17T00:00:00Z'
$projectRoot = if ($IsWindows) { 'C:\work\repo' } else { '/work/repo' }
$ownMarker = [pscustomobject]@{
    started_at   = '2026-06-16T23:59:00Z'
    host         = 'antigravity'
    session_id   = 'anti-session-1'
    project_root = $projectRoot
    branch       = 'main'
    head_commit  = 'abc123'
}
$own = Test-SpecrewConcurrentSession -Marker $ownMarker -ProjectRoot $projectRoot -NowUtc $now -CurrentSessionId 'anti-session-1'
Assert-True (-not [bool]$own.concurrent) 'same-session marker is not concurrent'
Assert-Equal $own.reason 'same-session' 'same-session marker reason recorded'

# A different fresh marker in the same worktree still produces the advisory.
$otherMarker = [pscustomobject]@{
    started_at   = '2026-06-16T23:59:00Z'
    host         = 'antigravity'
    session_id   = 'other-session'
    project_root = $projectRoot
    branch       = 'main'
    head_commit  = 'abc123'
}
$other = Test-SpecrewConcurrentSession -Marker $otherMarker -ProjectRoot $projectRoot -NowUtc $now -CurrentSessionId 'anti-session-1'
Assert-True ([bool]$other.concurrent) 'different fresh marker remains concurrent'
Assert-Equal $other.reason 'fresh-marker' 'different marker reason remains fresh-marker'

Write-Host 'ClassificationEngine: all tests passed.' -ForegroundColor Green

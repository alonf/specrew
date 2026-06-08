$ErrorActionPreference = 'Stop'

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/ProjectMetadataAccessor.ps1"
. "$base/SessionStateAccessor.ps1"
. "$base/ValidationEngine.ps1"
. "$base/ClassificationEngine.ps1"

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

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t009-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $tmp 'specs/feat-x') -Force | Out-Null
try {
    # T009 - handover validity (recency necessary but not sufficient).
    Assert-True (-not (Test-SpecrewHandoverValidity -Handover $null -ProjectRoot $tmp).valid) 'null handover is invalid'

    $stale = [pscustomobject]@{ fresh = $false; active_feature = 'feat-x'; recorded_at = '2026-01-01T00:00:00Z' }
    Assert-Equal (Test-SpecrewHandoverValidity -Handover $stale -ProjectRoot $tmp).reason 'stale' 'stale handover -> stale reason'

    $fresh = [pscustomobject]@{ fresh = $true; active_feature = 'feat-x'; recorded_at = '2026-06-08T12:00:00Z' }
    Assert-True (Test-SpecrewHandoverValidity -Handover $fresh -ProjectRoot $tmp).valid 'fresh handover for a present, unmerged feature is valid'

    $ghost = [pscustomobject]@{ fresh = $true; active_feature = 'ghost'; recorded_at = '2026-06-08T12:00:00Z' }
    Assert-Equal (Test-SpecrewHandoverValidity -Handover $ghost -ProjectRoot $tmp).reason 'missing' 'handover for an absent feature -> missing reason'

    # T010 - handover-first welcome-back.
    $m = Resolve-SpecrewBootstrapMode -AnchorValid $false -HandoverValid $true
    Assert-Equal $m.mode 'welcome-back' 'valid handover resolves welcome-back'
    Assert-True ($m.reason -match 'handover') 'welcome-back reason names the handover (handover-first)'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'HandoverValidation: all tests passed.' -ForegroundColor Green

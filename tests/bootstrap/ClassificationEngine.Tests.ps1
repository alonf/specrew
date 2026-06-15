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

Write-Host 'ClassificationEngine: all tests passed.' -ForegroundColor Green

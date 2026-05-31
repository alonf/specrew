[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red }

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if (-not $Condition) {
        Write-Fail $Message
        exit 1
    }
    Write-Pass $Message
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$contractsDir = Join-Path $repoRoot 'specs\054-activate-spec-surfaces\contracts'

Write-Host ''
Write-Host '=== Discovery Surface Contract Lane (F-054) ===' -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot"
Write-Host ''

# --- Test 1: required contracts exist ---
Write-Host '--- Test 1: discovery/placement/quality contracts exist ---'
$discoveryContract = Join-Path $contractsDir 'discovery-surfaces.md'
$placementContract = Join-Path $contractsDir 'lifecycle-placement.md'
$qualityContract = Join-Path $contractsDir 'quality-governance-artifacts.md'
foreach ($contractPath in @($discoveryContract, $placementContract, $qualityContract)) {
    Assert-True -Condition (Test-Path -LiteralPath $contractPath) -Message "contract present: $([System.IO.Path]::GetFileName($contractPath))"
}

# --- Test 2: placement contract declares the authoritative lifecycle placements ---
Write-Host ''
Write-Host '--- Test 2: placement contract declares authoritative placements ---'
$placement = Get-Content -LiteralPath $placementContract -Raw
Assert-True -Condition ($placement -match '(?i)/speckit\.checklist.*before-plan') -Message 'placement contract: checklist -> before-plan'
Assert-True -Condition ($placement -match '(?i)/speckit\.analyze.*before-implement') -Message 'placement contract: analyze -> before-implement'
Assert-True -Condition ($placement -match '(?i)/speckit\.taskstoissues.*deferred') -Message 'placement contract: taskstoissues -> deferred'

# --- Test 3: top-level discovery surfaces stay consistent with the placement contract ---
Write-Host ''
Write-Host '--- Test 3: README + user-guide consistent with placement contract ---'
$discoverySurfaces = @(
    [pscustomobject]@{ Name = 'README.md'; Path = (Join-Path $repoRoot 'README.md') },
    [pscustomobject]@{ Name = 'docs/user-guide.md'; Path = (Join-Path $repoRoot 'docs\user-guide.md') }
)
foreach ($surface in $discoverySurfaces) {
    Assert-True -Condition (Test-Path -LiteralPath $surface.Path) -Message "discovery surface present: $($surface.Name)"
    $content = Get-Content -LiteralPath $surface.Path -Raw
    Assert-True -Condition (($content -like '*/speckit.checklist*') -and ($content -like '*before-plan*')) -Message "$($surface.Name): checklist surfaced at before-plan"
    Assert-True -Condition (($content -like '*/speckit.analyze*') -and ($content -like '*before-implement*')) -Message "$($surface.Name): analyze surfaced at before-implement"
    Assert-True -Condition (($content -like '*/speckit.taskstoissues*') -and ($content -match '(?i)deferred')) -Message "$($surface.Name): taskstoissues marked deferred"
}

# --- Test 4: analyze framing stays additive to governance (FR-007) ---
Write-Host ''
Write-Host '--- Test 4: analyze surfaces keep additive-to-governance framing ---'
$analyzeAgent = Get-Content -LiteralPath (Join-Path $repoRoot '.github\agents\speckit.analyze.agent.md') -Raw
Assert-True -Condition ($analyzeAgent -match '(?i)additive' -or ($analyzeAgent -match '(?i)complements' -and $analyzeAgent -match '(?i)does not replace')) -Message 'analyze agent: additive / complements-not-replaces framing'

# --- Test 5: checklist framing stays proportional (FR-004) ---
Write-Host ''
Write-Host '--- Test 5: checklist surfaces keep proportional framing ---'
$checklistAgent = Get-Content -LiteralPath (Join-Path $repoRoot '.github\agents\speckit.checklist.agent.md') -Raw
Assert-True -Condition ($checklistAgent -match '(?i)optional' -or $checklistAgent -match '(?i)proportional') -Message 'checklist agent: proportional / optional framing'

# --- Test 6: taskstoissues deferment is consistent and never default (FR-010, SC-005) ---
Write-Host ''
Write-Host '--- Test 6: taskstoissues deferment consistent across agent + prompt ---'
foreach ($relPath in @('.github\agents\speckit.taskstoissues.agent.md', '.github\prompts\speckit.taskstoissues.prompt.md')) {
    $content = Get-Content -LiteralPath (Join-Path $repoRoot $relPath) -Raw
    Assert-True -Condition ($content -match '(?i)deferred') -Message "${relPath}: states deferred"
    Assert-True -Condition ($content -match '(?i)not part of the default') -Message "${relPath}: states not part of the default lifecycle"
}

Write-Host ''
Write-Host '=== Discovery surface contract lane passed ===' -ForegroundColor Green
Write-Host ''
exit 0

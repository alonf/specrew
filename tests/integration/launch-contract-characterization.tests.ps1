[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# F-174 iteration 006 (T035a). CHARACTERIZATION FLOOR for the T035 extraction.
#
# The design pass called the specrew-start integration suite "the behavior-preserving
# regression floor" for moving Get-StartPrompt into a shared lib (launch-contract.ps1).
# Confirming that BEFORE extracting (before-implement instruction #2) revealed the suite
# pins the directive-block wrapping + pause-and-confirm, but NOT Get-StartPrompt's actual
# CONTRACT content nor the boundary_enforcement init (drift D-010). This test is the
# genuine net: it pins the invariant contract markers + the boundary_enforcement init so
# the T035 move-not-rewrite cannot silently alter the contract and stay green.

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$startScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-start.ps1'
if (-not (Test-Path -LiteralPath $startScript -PathType Leaf)) {
    Write-Fail "Missing required script: $startScript"; exit 1
}

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\launch-contract-characterization'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'
if (Test-Path -Path $scratchRoot) { Remove-Item -Path $scratchRoot -Recurse -Force }
$null = New-Item -Path $projectRoot -ItemType Directory -Force

$failures = 0
function Assert-Contains {
    param([string]$Haystack, [string]$Needle, [string]$Label)
    if ($Haystack -notmatch [regex]::Escape($Needle)) {
        Write-Fail "$Label (marker absent: '$Needle')"; $script:failures++
    }
    else { Write-Pass $Label }
}

try {
    # --- minimal Specrew project (proven setup, mirrors specrew-start-end-to-end.ps1) ---
    $null = & git -C $projectRoot init --quiet 2>&1
    $null = & git -C $projectRoot config user.email "test@specrew.local" 2>&1
    $null = & git -C $projectRoot config user.name "Test User" 2>&1

    $specrewRoot = Join-Path $projectRoot '.specrew'
    $null = New-Item -Path $specrewRoot -ItemType Directory -Force
    $null = New-Item -Path (Join-Path $projectRoot '.specify') -ItemType Directory -Force
    $null = New-Item -Path (Join-Path $projectRoot '.squad') -ItemType Directory -Force
    $null = New-Item -Path (Join-Path $projectRoot '.github\agents') -ItemType Directory -Force
    Set-Content -LiteralPath (Join-Path $specrewRoot 'config.yml') -Value "version: 1" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $projectRoot '.squad\team.md') -Value "# Team`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $projectRoot '.squad\config.json') -Value "{}" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $projectRoot '.squad\decisions.md') -Value "# Decisions`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $projectRoot '.github\agents\squad.agent.md') -Value "# Squad Agent`n" -Encoding UTF8
    $null = & git -C $projectRoot add -A 2>&1
    $null = & git -C $projectRoot commit -m "Initial commit" --quiet 2>&1

    # --- run specrew start (the contract generator + state init path) ---
    $null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

    $promptPath = Join-Path $specrewRoot 'last-start-prompt.md'
    $contextPath = Join-Path $specrewRoot 'start-context.json'
    if (-not (Test-Path -LiteralPath $promptPath)) { Write-Fail "last-start-prompt.md not written"; exit 1 }
    if (-not (Test-Path -LiteralPath $contextPath)) { Write-Fail "start-context.json not written"; exit 1 }
    $prompt = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

    # --- the CONTRACT invariant markers (what makes the hook DRIVE, not just orient) ---
    Assert-Contains $prompt '## Lifecycle Quick Reference' 'contract: Lifecycle Quick Reference section present'
    Assert-Contains $prompt 'Phase agents and the artifacts they produce' 'contract: phase-agents table present'
    Assert-Contains $prompt 'before-implement' 'contract: before-implement gate row present'
    Assert-Contains $prompt 'HUMAN APPROVAL GATE' 'contract: human-approval-gate language present'
    Assert-Contains $prompt 'Governance scripts' 'contract: governance-scripts table present'
    Assert-Contains $prompt 'Boundary authorization' 'contract: boundary-authorization block present'
    Assert-Contains $prompt 'boundary_enforcement.policy_classes' 'contract: boundary-policy resolution line present'

    # --- the boundary_enforcement init in start-context.json ---
    $context = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -eq $context.PSObject.Properties['boundary_enforcement'] -or $null -eq $context.boundary_enforcement) {
        Write-Fail 'state: boundary_enforcement initialized in start-context.json'; $failures++
    }
    else {
        Write-Pass 'state: boundary_enforcement initialized in start-context.json'
        if ($null -eq $context.boundary_enforcement.PSObject.Properties['policy_classes']) {
            Write-Fail 'state: boundary_enforcement.policy_classes present'; $failures++
        }
        else { Write-Pass 'state: boundary_enforcement.policy_classes present' }
    }
}
finally {
    if (Test-Path -Path $scratchRoot) { Remove-Item -Path $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($failures -gt 0) {
    Write-Fail "launch-contract characterization: $failures assertion(s) failed."
    exit 1
}
Write-Host 'launch-contract characterization: all assertions passed.' -ForegroundColor Green
exit 0

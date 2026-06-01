[CmdletBinding()]
param()

# Regression test for feature 090 (spike-speckit-090):
# Spec Kit 0.9.0 changed .specify/extensions.yml `installed:` from object entries to
# bare extension-id strings (e.g. "- specrew-speckit"). Ensure-ExtensionRegistration
# (deploy-speckit-extension.ps1) must register/no-op specrew-speckit as a STRING on
# such lists rather than inserting a legacy object entry — which produced a malformed
# mixed-type list with specrew-speckit registered twice (validated defect; the silent
# corruption that `specrew update --specrew` caused on 0.9.0-initialized projects).
#
# Cases:
#   A. 0.9.0 bare-string list already containing specrew-speckit  -> single entry, idempotent
#   B. 0.9.0 bare-string list missing specrew-speckit             -> added as a bare string
#   C. legacy (<=0.8.x) object-format list                        -> updated in place, no string dup

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; throw $m }

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$realDeployScript = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1'
$realSharedGov    = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1'
foreach ($p in @($realDeployScript, $realSharedGov)) {
    if (-not (Test-Path -LiteralPath $p)) { Write-Fail "Source file not found: $p" }
}

$testRoot = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "specrew-extreg-test-$([System.IO.Path]::GetRandomFileName())")
$fakeModuleRoot = Join-Path $testRoot 'module/extensions/specrew-speckit'

function New-FakeModule {
    param([string]$Root)
    foreach ($d in @('commands', 'scripts', 'templates', 'squad-templates')) {
        New-Item -ItemType Directory -Force -Path (Join-Path $Root $d) | Out-Null
    }
    Set-Content -LiteralPath (Join-Path $Root 'extension.yml') -Value @'
schema_version: "1.0"
schema: "v1"
extension:
  id: specrew-speckit
  name: "Specrew Spec Kit Extension"
  version: "0.30.0"
requires:
  speckit_version: ">=0.8.4"
'@ -Encoding utf8 -NoNewline
    Set-Content -LiteralPath (Join-Path $Root 'README.md') -Value 'test' -Encoding utf8 -NoNewline
    Set-Content -LiteralPath (Join-Path $Root 'commands/placeholder.md') -Value '# placeholder' -Encoding utf8 -NoNewline
    Set-Content -LiteralPath (Join-Path $Root 'scripts/placeholder.ps1') -Value '# placeholder' -Encoding utf8 -NoNewline
    Set-Content -LiteralPath (Join-Path $Root 'templates/placeholder.md') -Value '# placeholder' -Encoding utf8 -NoNewline
    Set-Content -LiteralPath (Join-Path $Root 'squad-templates/placeholder.md') -Value '# placeholder' -Encoding utf8 -NoNewline
    Copy-Item -LiteralPath $realDeployScript -Destination (Join-Path $Root 'scripts/deploy-speckit-extension.ps1') -Force
    Copy-Item -LiteralPath $realSharedGov    -Destination (Join-Path $Root 'scripts/shared-governance.ps1') -Force
}

function New-Project {
    param([string]$Path, [string]$ExtensionsYml)
    $specify = Join-Path $Path '.specify'
    New-Item -ItemType Directory -Force -Path $specify | Out-Null
    Set-Content -LiteralPath (Join-Path $specify 'extensions.yml') -Value $ExtensionsYml -Encoding utf8 -NoNewline
    return (Join-Path $specify 'extensions.yml')
}

function Get-InstalledBlock {
    param([string]$ManifestPath)
    $raw = Get-Content -LiteralPath $ManifestPath -Raw
    return (($raw -split '(?m)^settings:')[0])
}

try {
    New-FakeModule -Root $fakeModuleRoot
    $deploy = Join-Path $fakeModuleRoot 'scripts/deploy-speckit-extension.ps1'

    $stringListWithEntry = @'
installed:
- agent-context
- git
- specrew-speckit
settings:
  auto_execute_hooks: true
hooks: {}
'@

    $stringListMissing = @'
installed:
- agent-context
- git
settings:
  auto_execute_hooks: true
hooks: {}
'@

    $objectList = @'
installed:
  - name: specrew-speckit
    version: 0.18.0
    enabled: true
    source: local
    path: .specify/extensions/specrew-speckit
settings:
  auto_execute_hooks: true
hooks: {}
'@

    # --- Case A: 0.9.0 bare-string list already containing specrew-speckit ---
    $manifestA = New-Project -Path (Join-Path $testRoot 'proj-string') -ExtensionsYml $stringListWithEntry
    & $deploy -ProjectPath (Split-Path -Parent (Split-Path -Parent $manifestA)) -RefreshExisting -PassThru | Out-Null
    $blockA = Get-InstalledBlock -ManifestPath $manifestA
    $cntA = ([regex]::Matches($blockA, '(?m)^\s*-\s*specrew-speckit\s*$')).Count
    if ($cntA -ne 1) { Write-Fail "Case A: expected exactly 1 bare-string specrew-speckit entry, got $cntA.`n$blockA" }
    if ($blockA -match '(?m)^\s*-\s*name:\s*specrew-speckit') { Write-Fail "Case A: a legacy object entry was inserted into a bare-string list (corruption).`n$blockA" }
    Write-Pass 'Case A: bare-string list keeps a single specrew-speckit string (no object insertion)'

    # Idempotency: a second run is a no-op (preserved-registration), still one entry.
    $actionsA2 = @(& $deploy -ProjectPath (Split-Path -Parent (Split-Path -Parent $manifestA)) -RefreshExisting -PassThru)
    $blockA2 = Get-InstalledBlock -ManifestPath $manifestA
    if (([regex]::Matches($blockA2, '(?m)^\s*-\s*specrew-speckit\s*$')).Count -ne 1) { Write-Fail "Case A idempotency: expected 1 entry after 2nd run.`n$blockA2" }
    if (@($actionsA2 | Where-Object { $_.Action -eq 'preserved-registration' }).Count -lt 1) { Write-Fail 'Case A idempotency: expected a preserved-registration action on the 2nd run' }
    Write-Pass 'Case A: registration is idempotent (2nd run preserved, still a single entry)'

    # --- Case B: 0.9.0 bare-string list missing specrew-speckit ---
    $manifestB = New-Project -Path (Join-Path $testRoot 'proj-string-missing') -ExtensionsYml $stringListMissing
    & $deploy -ProjectPath (Split-Path -Parent (Split-Path -Parent $manifestB)) -RefreshExisting -PassThru | Out-Null
    $blockB = Get-InstalledBlock -ManifestPath $manifestB
    if (([regex]::Matches($blockB, '(?m)^\s*-\s*specrew-speckit\s*$')).Count -ne 1) { Write-Fail "Case B: expected specrew-speckit added as a single bare string.`n$blockB" }
    if ($blockB -match '(?m)^\s*-\s*name:\s*specrew-speckit') { Write-Fail "Case B: inserted an object entry instead of a bare string.`n$blockB" }
    Write-Pass 'Case B: missing specrew-speckit in a bare-string list is added as a bare string'

    # --- Case C: legacy object-format list (<=0.8.x) updated in place ---
    $manifestC = New-Project -Path (Join-Path $testRoot 'proj-object') -ExtensionsYml $objectList
    & $deploy -ProjectPath (Split-Path -Parent (Split-Path -Parent $manifestC)) -RefreshExisting -PassThru | Out-Null
    $blockC = Get-InstalledBlock -ManifestPath $manifestC
    if (([regex]::Matches($blockC, '(?m)^\s*-\s*name:\s*specrew-speckit\s*$')).Count -ne 1) { Write-Fail "Case C: expected a single object specrew-speckit entry updated in place.`n$blockC" }
    if ($blockC -match '(?m)^\s*-\s*specrew-speckit\s*$') { Write-Fail "Case C: a stray bare-string entry was added alongside the object entry.`n$blockC" }
    if ($blockC -notmatch 'version:\s*0\.30\.0') { Write-Fail "Case C: expected the object entry version updated in place to 0.30.0.`n$blockC" }
    Write-Pass 'Case C: legacy object-format list updated in place (no bare-string duplicate)'
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -Recurse -Force -LiteralPath $testRoot -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host 'All extension-registration-format tests passed.' -ForegroundColor Green

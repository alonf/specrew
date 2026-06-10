$ErrorActionPreference = 'Stop'

# F-174 iteration 007 (T045): the bootstrap provider exists in TWO tracked copies that MUST stay in sync.
#   - MODULE copy  : scripts/internal/specrew-bootstrap-provider.ps1
#                    (the self-host provider AND the tier-3 component source the deployed copy resolves).
#   - EXTENSION copy: extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1
#                    (what deploy-speckit-extension ships into a downstream .specify/, and which
#                     Resolve-ProviderCommandPath resolves FIRST for a downstream project).
# iter-6 updated ONLY the module copy, so downstream deployments shipped the stale iter-4 provider (no
# contract write, no inline) - the exact gap the iter-6 review-signoff was sent back for. The provider's
# resolution is $PSScriptRoot-relative (location-agnostic), so the two copies are meant to be BYTE-IDENTICAL.
# This guard asserts that, so the divergence cannot recur silently. Line endings are normalized so a
# CRLF/LF difference (git autocrlf on checkout) is not a false divergence.

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$moduleProvider = Join-Path $repoRoot 'scripts/internal/specrew-bootstrap-provider.ps1'
$extProvider = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

Assert-True (Test-Path -LiteralPath $moduleProvider) 'module bootstrap provider exists (scripts/internal)'
Assert-True (Test-Path -LiteralPath $extProvider) 'extension-source bootstrap provider exists (extensions/specrew-speckit/scripts)'

$modText = (Get-Content -LiteralPath $moduleProvider -Raw) -replace "`r`n", "`n"
$extText = (Get-Content -LiteralPath $extProvider -Raw) -replace "`r`n", "`n"

Assert-True ($modText -eq $extText) ('the MODULE + EXTENSION-SOURCE bootstrap providers are byte-identical (mirror parity). If this FAILS, re-sync: ' +
    'Copy-Item scripts/internal/specrew-bootstrap-provider.ps1 over extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1 - ' +
    'a change to one copy that is not mirrored to the other ships a stale provider downstream (the iter-6 send-back).')

# The deployed copy must carry the iter-7 behavior, not the iter-4 stub (a sanity check on top of identity).
Assert-True ($extText -match 'Write-SpecrewLaunchContractArtifact') 'extension-source provider carries the contract-writer (FR-023, not the iter-4 stub)'
Assert-True ($extText -match 'BEGIN SPECREW LAUNCH CONTRACT') 'extension-source provider inlines the contract (FR-002 read-and-follow, T044)'

Write-Host "`n=== ProviderMirrorParity.Tests.ps1: module + extension-source providers in sync ===" -ForegroundColor Green

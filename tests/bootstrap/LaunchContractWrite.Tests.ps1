$ErrorActionPreference = 'Stop'

# F-174 iteration 006 (T036). Unit PLUMBING floor for Write-SpecrewLaunchContractArtifact (FR-023): the
# hook writes the SAME launch contract `specrew start` does - via the SHARED Get-StartPrompt generator -
# to .specrew/last-start-prompt.md, and ensures boundary_enforcement in start-context.json, PRESERVE-
# MERGING any existing block. This is the DEV-TREE plumbing assertion; T038 is the DEPLOYED round-trip
# (evidence_locus: deployed). The generator deps set `Set-StrictMode -Version Latest` at file scope -
# contained to THIS test so the classification tests (SessionBootstrapManager.Tests.ps1) stay clean.

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
. "$repoRoot/scripts/internal/bootstrap/SessionStateAccessor.ps1"
. "$repoRoot/scripts/internal/bootstrap/SessionBootstrapManager.ps1"
. "$repoRoot/scripts/internal/launch-contract.ps1"
. "$repoRoot/scripts/internal/coordinator-resume.ps1"
# iter-7 T043: the hook now applies the SAME coordinator-surgery step `specrew start` does (carrying the
# user-profile/expertise adaptation + coordinator framing) - dot-source its deps so the floor exercises it.
. "$repoRoot/scripts/internal/coordinator-prompt-surgery.ps1"
. "$repoRoot/scripts/internal/user-profile.ps1"
. "$repoRoot/extensions/specrew-speckit/scripts/shared-governance.ps1"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# The invariant launch-contract markers (the same set the T035a characterization test pins).
$contractMarkers = @(
    '## Lifecycle Quick Reference',
    'Phase agents and the artifacts they produce',
    'before-implement',
    'HUMAN APPROVAL GATE',
    'Governance scripts',
    'Boundary authorization',
    'boundary_enforcement.policy_classes'
)

$root = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t036-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root -Force | Out-Null
try {
    # 1. Fresh project, NO anchor -> contract written with EVERY invariant marker; boundary_enforcement init.
    $promptPath = Write-SpecrewLaunchContractArtifact -ProjectRoot $root -Mode 'full' -SessionState $null
    Assert-True (Test-Path -LiteralPath $promptPath) 'last-start-prompt.md written (no-anchor path)'
    $contract = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
    foreach ($m in $contractMarkers) { Assert-True ($contract -like "*$m*") "contract carries invariant marker: $m" }

    $ctxPath = Join-Path $root '.specrew/start-context.json'
    Assert-True (Test-Path -LiteralPath $ctxPath) 'start-context.json written'
    $ctx = Get-Content -LiteralPath $ctxPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-True ($null -ne $ctx.boundary_enforcement) 'boundary_enforcement initialized on disk'
    Assert-True ($null -ne $ctx.boundary_enforcement.policy_classes) 'boundary_enforcement.policy_classes present'

    # 2. PRESERVE-MERGE: a sentinel on the existing boundary_enforcement survives a SECOND write (never re-init).
    $ctxObj = Get-Content -LiteralPath $ctxPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
    $ctxObj['boundary_enforcement']['last_authorized_boundary'] = 'plan'
    ($ctxObj | ConvertTo-Json -Depth 24) | Set-Content -LiteralPath $ctxPath -Encoding UTF8
    Write-SpecrewLaunchContractArtifact -ProjectRoot $root -Mode 'welcome-back' -SessionState $null | Out-Null
    $ctx2 = Get-Content -LiteralPath $ctxPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-True ($ctx2.boundary_enforcement.last_authorized_boundary -eq 'plan') 'existing boundary_enforcement preserved (not re-initialized) on a second write'

    # 3. With a REAL Get-SpecrewSessionAnchor-shaped SessionState (field names `boundary`/`iteration`,
    #    NO `task_id`) -> the hook maps it to the generator's shape and writes WITHOUT throwing under
    #    StrictMode-Latest, and the resolved feature directory surfaces in the contract. This is the exact
    #    shape mismatch that, unmapped, throws on three fields -> provider fail-open -> silent no-contract.
    $anchor = [pscustomobject]@{ active = $true; feature_ref = 'feat-x'; feature_path = (Join-Path $root 'specs/feat-x'); boundary = 'plan'; iteration = '001'; auth_commit_hash = 'x'; recorded_at = 't' }
    Write-SpecrewLaunchContractArtifact -ProjectRoot $root -Mode 'welcome-back' -SessionState $anchor | Out-Null
    $contract3 = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
    Assert-True (($contract3 -like '*specs/feat-x*') -or ($contract3 -like '*specs\feat-x*')) 'real-anchor shape maps cleanly: feature path surfaces in the contract, no StrictMode throw'

    Write-Host "`n=== LaunchContractWrite.Tests.ps1: all assertions passed ===" -ForegroundColor Green
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}

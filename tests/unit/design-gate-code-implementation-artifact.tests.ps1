[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Fix 4 (iter-007 real-host dogfood) / alonf/specrew#2904 — design-context integrity.
#
# The HOLLOW-COMPLETION bug: a host (Copilot, EnglishIntake) marked the code-implementation lens
# `moved_on: true` / human-confirmed in lens-applicability.json WITHOUT ever writing the lens ARTIFACT
# (implementation-rules.yml) — and the specify-boundary gate trusted the checkbox and authorized. The lens
# COMPLETION signal was decoupled from the lens ARTIFACT: a code-writing lens could self-certify done having
# produced nothing. This pins the fix: Test-SpecrewLensWorkshopRecords now ASSERTS the artifact's PRESENCE
# (not its schema — that is the lens's own Test-SpecrewImplementationRulesManifest + Proposal-196 provenance,
# a coupled follow-up), SCOPED to code-implementation (the only lens with a required on-disk manifest) and
# gated on moved_on truthy (so it is grandfather-safe like the rest of the SC-021 floor).
#
# Test shape (advisor-guided, mirrors the i011 SC-026 proof): the pass/fail/grandfather/scoping cases run
# against the FLOOR function directly (a full-entry pass would need product-domain-gate setup that invites
# false reds); ONE fail-case runs through the REAL Invoke-SpecrewSpecifyBoundaryLensGate entry to prove the
# floor is wired into the gate. The PASS manifest is placed via Get-SpecrewCodeManifestPath -FeatureDir, so a
# drift of the gate's hardcoded 'implementation-rules.yml' literal away from the helper's contract breaks the
# pass case (gate-literal == helper-contract, pinned — the Fix-1 conformance philosophy on the one hardcode).

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { Write-Fail $Message } }

# The gate is self-sufficient (the existing design-gate test dot-sources only this). code-implementation-lens.ps1
# is dot-sourced HERE for Get-SpecrewCodeManifestPath — the test has no load-chain constraint (the gate does,
# which is exactly why the gate resolves the path inline).
. (Join-Path $PSScriptRoot '..\..\scripts\internal\design-analysis-gate.ps1')
. (Join-Path $PSScriptRoot '..\..\scripts\internal\code-implementation-lens.ps1')

# A unique marker that isolates the #2904 manifest-presence error from every other floor error.
$marker = '#2904'

function New-LensArtifact {
    param([Parameter(Mandatory = $true)][string]$FeatureDir, [Parameter(Mandatory = $true)][string]$Json)
    $null = New-Item -ItemType Directory -Path $FeatureDir -Force
    $path = Join-Path $FeatureDir 'lens-applicability.json'
    [System.IO.File]::WriteAllText($path, $Json, [System.Text.UTF8Encoding]::new($false))
    return $path
}

$sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-2904-" + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $sandbox -Force
try {
    # A COMPLETE code-implementation workshop record (agenda + decision + depth + moved_on:true), so the ONLY
    # thing the floor can fault is the missing manifest — isolating the #2904 check.
    $completeCodeLens = '{"schema":"v2","workshop_intake":true,"selected":["code-implementation"],"workshop":{"code-implementation":{"agenda":["reference-by-id vs embed"],"decision":"reference-by-id manifest + baseline/overlay","depth":"full","moved_on":true}}}'

    # --- (a) FAIL: code-implementation moved_on:true, complete record, NO manifest -> the floor faults #2904. ---
    $aDir = Join-Path $sandbox 'a-no-manifest'
    $aArtifact = New-LensArtifact -FeatureDir $aDir -Json $completeCodeLens
    $aErrors = @(Test-SpecrewLensWorkshopRecords -ArtifactPath $aArtifact)
    Assert-True (@($aErrors | Where-Object { $_ -match $marker }).Count -eq 1) "(a) a moved_on:true code-implementation lens with NO implementation-rules.yml FAILS the floor (#2904)"
    Assert-True (@($aErrors | Where-Object { $_ -match 'code-implementation' -and $_ -match 'implementation-rules\.yml' }).Count -ge 1) "(a) the #2904 error names the lens and the expected manifest"
    Write-Pass '(a) hollow code-implementation completion (no manifest) is rejected by the floor'

    # --- (b) PASS: the SAME artifact + the manifest placed via the helper contract -> NO #2904 error. ---
    $bDir = Join-Path $sandbox 'b-with-manifest'
    $bArtifact = New-LensArtifact -FeatureDir $bDir -Json $completeCodeLens
    # Place the manifest at the HELPER's path (Get-SpecrewCodeManifestPath), NOT a hand-typed literal: this is
    # what pins gate-literal == helper-contract. If the gate's inline 'implementation-rules.yml' ever drifts
    # from the helper, this case fails. Existence is all the gate checks; content is irrelevant to it.
    $bManifest = Get-SpecrewCodeManifestPath -FeatureDir $bDir
    [System.IO.File]::WriteAllText($bManifest, "schema_version: 1`n", [System.Text.UTF8Encoding]::new($false))
    $bErrors = @(Test-SpecrewLensWorkshopRecords -ArtifactPath $bArtifact)
    Assert-True (@($bErrors | Where-Object { $_ -match $marker }).Count -eq 0) "(b) the SAME lens PASSES once implementation-rules.yml exists at the helper path (gate-literal == helper-contract)"
    Write-Pass '(b) a present manifest clears the #2904 floor (and pins the gate literal to the helper)'

    # --- (c) GRANDFATHER: no workshop_intake marker -> the whole floor no-ops, so #2904 cannot fire. ---
    $cDir = Join-Path $sandbox 'c-grandfather'
    $cArtifact = New-LensArtifact -FeatureDir $cDir -Json '{"schema":"v2","selected":["code-implementation"],"workshop":{"code-implementation":{"agenda":["q"],"decision":"d","depth":"full","moved_on":true}}}'
    $cErrors = @(Test-SpecrewLensWorkshopRecords -ArtifactPath $cArtifact)
    Assert-True ($cErrors.Count -eq 0) "(c) a pre-A4 artifact (no workshop_intake) no-ops entirely -> #2904 never fires (grandfather-safe)"
    Write-Pass '(c) grandfather-safe: no workshop_intake -> the artifact-presence check is dormant'

    # --- (d) SCOPING: a NON-code-implementation lens (architecture-core) moved_on:true with no manifest is
    #         UNAFFECTED — the manifest requirement is scoped to code-implementation alone. ---
    $dDir = Join-Path $sandbox 'd-other-lens'
    $dArtifact = New-LensArtifact -FeatureDir $dDir -Json '{"schema":"v2","workshop_intake":true,"selected":["architecture-core"],"workshop":{"architecture-core":{"agenda":["q"],"decision":"modular monolith","depth":"expert-terse","moved_on":true}}}'
    $dErrors = @(Test-SpecrewLensWorkshopRecords -ArtifactPath $dArtifact)
    Assert-True ($dErrors.Count -eq 0) "(d) a complete NON-code-implementation lens with no manifest PASSES (the #2904 check is scoped to code-implementation)"
    Write-Pass '(d) scoping: only code-implementation demands an on-disk artifact'

    # --- (e) GATING on moved_on: code-implementation NOT moved on (moved_on:false) faults the EXISTING SC-021
    #         'moved_on' incompleteness, but NOT the #2904 manifest error — the artifact is demanded only of a
    #         lens that CLAIMS done. (When the lens isn't moved on, "no manifest yet" is expected, not a fault.) ---
    $eDir = Join-Path $sandbox 'e-not-moved-on'
    $eArtifact = New-LensArtifact -FeatureDir $eDir -Json '{"schema":"v2","workshop_intake":true,"selected":["code-implementation"],"workshop":{"code-implementation":{"agenda":["q"],"decision":"d","depth":"full","moved_on":false}}}'
    $eErrors = @(Test-SpecrewLensWorkshopRecords -ArtifactPath $eArtifact)
    Assert-True (@($eErrors | Where-Object { $_ -match 'moved_on' }).Count -ge 1) "(e) moved_on:false still faults the existing SC-021 incompleteness"
    Assert-True (@($eErrors | Where-Object { $_ -match $marker }).Count -eq 0) "(e) but the #2904 manifest error does NOT fire when the lens is not moved on (gated on moved_on truthy)"
    Write-Pass '(e) gating: the artifact is demanded only of a lens that claims moved_on'

    # --- (B) WIRING through the REAL gate entry (i011 SC-026 pattern): a substantive feature in a lens-catalog
    #         project, code-implementation moved_on:true, NO manifest -> Invoke-SpecrewSpecifyBoundaryLensGate
    #         THROWS, proving the floor is enforced at the specify boundary (not merely a unit-level function). ---
    $specifyRoot = Join-Path $sandbox 'wiring-root'
    $mapDir = Join-Path $specifyRoot 'extensions\specrew-speckit\knowledge\design-lenses'
    $featDir = Join-Path $specifyRoot 'specs\001-test-feature'
    $null = New-Item -ItemType Directory -Path $mapDir -Force
    $null = New-Item -ItemType Directory -Path $featDir -Force
    [System.IO.File]::WriteAllText((Join-Path $mapDir 'applicability-map.json'), '{"always_on":["architecture-core"],"questions":[]}', [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $featDir 'spec.md'), "# Spec`nThis governance lifecycle feature changes boundary enforcement and validation.", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $featDir 'lens-applicability.json'), $completeCodeLens, [System.Text.UTF8Encoding]::new($false))

    $wiringBlocked = $false
    try { Invoke-SpecrewSpecifyBoundaryLensGate -ProjectRoot $specifyRoot -FeatureRef '001-test-feature' | Out-Null }
    catch { $wiringBlocked = ($_.Exception.Message -match $marker -and $_.Exception.Message -match 'code-implementation') }
    Assert-True $wiringBlocked '(B) sync-specify is BLOCKED through the REAL gate entry when code-implementation is moved_on with no manifest (#2904, names the lens)'
    Write-Pass '(B) the #2904 floor is wired into Invoke-SpecrewSpecifyBoundaryLensGate (fails through the real entry)'

    # --- (B2) the SAME real entry PASSES once the manifest exists (the manifest is what unblocks the gate;
    #          no product-domain lens in the map, so the entry passes cleanly — mirrors the existing FR-027 case). ---
    $b2Manifest = Get-SpecrewCodeManifestPath -FeatureDir $featDir
    [System.IO.File]::WriteAllText($b2Manifest, "schema_version: 1`n", [System.Text.UTF8Encoding]::new($false))
    $b2Ok = Invoke-SpecrewSpecifyBoundaryLensGate -ProjectRoot $specifyRoot -FeatureRef '001-test-feature'
    Assert-True ($null -ne $b2Ok -and $b2Ok.Valid -eq $true) '(B2) the real gate PASSES once implementation-rules.yml is persisted (the manifest is what unblocks it)'
    Write-Pass '(B2) persisting the manifest unblocks the real specify gate'
}
finally { Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "`n=== design-gate-code-implementation-artifact.tests.ps1: all assertions passed ===" -ForegroundColor Green
